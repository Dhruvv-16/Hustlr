-- ═══════════════════════════════════════════════════════════════
-- Run FIRST in Supabase SQL Editor
-- Patch notes:
--   • disruption_trigger_enum renamed to match Flutter's actual keys
--   • shift_telemetry data migrated to partitioned table
--   • wallet_balances upsert guard added
-- ═══════════════════════════════════════════════════════════════

BEGIN;

-- ── 1. STRICT TYPING: DISRUPTION EVENTS ENUM ───────────────────
-- IMPORTANT: enum values MUST match the Flutter app's trigger_type strings.
-- Flutter sends: rain_heavy, rain_moderate, rain_light, heat_severe,
--   heat_stress, aqi_hazardous, aqi_very_unhealthy, platform_outage,
--   dark_store_closure, bandh_strike, internet_blackout.
-- New enum therefore preserves those names, not the alternate wordforms.

CREATE TYPE disruption_trigger_enum AS ENUM (
  'rain_heavy', 'rain_moderate', 'rain_light',
  'heat_severe', 'heat_stress',
  'aqi_hazardous', 'aqi_very_unhealthy',
  'platform_outage', 'dark_store_closure',
  'bandh_strike', 'internet_blackout',
  'traffic_congestion', 'cyclone_landfall'
);

-- Normalise any stale legacy values before casting
UPDATE disruption_events SET trigger_type = 'rain_heavy'        WHERE trigger_type = 'heavy_rain';
UPDATE disruption_events SET trigger_type = 'rain_heavy'        WHERE trigger_type = 'extreme_rain';
UPDATE disruption_events SET trigger_type = 'heat_severe'       WHERE trigger_type = 'heatwave';
UPDATE disruption_events SET trigger_type = 'aqi_hazardous'     WHERE trigger_type IN ('severe_aqi', 'severe_pollution');
UPDATE disruption_events SET trigger_type = 'internet_blackout' WHERE trigger_type = 'internet_blackout';
UPDATE disruption_events SET trigger_type = 'bandh_strike'      WHERE trigger_type = 'bandh_strike';

ALTER TABLE disruption_events
  ALTER COLUMN trigger_type TYPE disruption_trigger_enum
  USING trigger_type::disruption_trigger_enum;


-- ── 2. FINANCIAL SAFETY: IDEMPOTENCY & HARD BALANCE LOCKING ────

-- A. Idempotency keys (prevents double billing / double payouts on retries)
ALTER TABLE wallet_transactions ADD COLUMN IF NOT EXISTS idempotency_key TEXT UNIQUE;
ALTER TABLE claims              ADD COLUMN IF NOT EXISTS idempotency_key TEXT UNIQUE;

-- B. Hard balance ledger table
CREATE TABLE IF NOT EXISTS wallet_balances (
  user_id      UUID    PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  balance      INTEGER NOT NULL DEFAULT 0,
  last_updated TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT chk_positive_balance CHECK (balance >= 0)
);

-- Seed existing users with 0 balance (real balance is in wallet_transactions)
INSERT INTO wallet_balances (user_id, balance)
SELECT id, 0 FROM users
ON CONFLICT DO NOTHING;

-- C. Row-level lock trigger — uses UPSERT guard so new users never error
CREATE OR REPLACE FUNCTION process_wallet_transaction()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  -- Ensure row exists before locking (handles brand-new users)
  INSERT INTO wallet_balances (user_id, balance)
  VALUES (NEW.user_id, 0)
  ON CONFLICT (user_id) DO NOTHING;

  -- Atomic row-level lock — prevents race conditions
  PERFORM * FROM wallet_balances WHERE user_id = NEW.user_id FOR UPDATE;

  IF NEW.type = 'credit' THEN
    UPDATE wallet_balances
      SET balance = balance + NEW.amount, last_updated = NOW()
      WHERE user_id = NEW.user_id;
  ELSE
    -- chk_positive_balance will reject if result < 0
    UPDATE wallet_balances
      SET balance = balance - NEW.amount, last_updated = NOW()
      WHERE user_id = NEW.user_id;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_wallet_transaction_lock ON wallet_transactions;
CREATE TRIGGER trg_wallet_transaction_lock
  BEFORE INSERT ON wallet_transactions
  FOR EACH ROW EXECUTE FUNCTION process_wallet_transaction();


-- ── 3. AUDITABILITY: POLICY VERSIONING ─────────────────────────

CREATE TABLE IF NOT EXISTS policy_versions (
  id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  policy_id         UUID        NOT NULL REFERENCES policies(id) ON DELETE CASCADE,
  plan_tier         TEXT        NOT NULL,   -- TEXT to survive enum migrations
  weekly_premium    INTEGER     NOT NULL,
  max_weekly_payout INTEGER     NOT NULL,
  zone_adjustment   INTEGER     NOT NULL,
  iss_adjustment    INTEGER     NOT NULL,
  valid_from        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  valid_to          TIMESTAMPTZ,
  changed_by        TEXT        DEFAULT 'system'
);

CREATE INDEX IF NOT EXISTS idx_policy_versions_lookup
  ON policy_versions(policy_id, valid_to);

CREATE OR REPLACE FUNCTION log_policy_version()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  -- Close the previous open version snapshot
  UPDATE policy_versions
    SET valid_to = NOW()
    WHERE policy_id = NEW.id AND valid_to IS NULL;

  -- Record the new state
  INSERT INTO policy_versions (
    policy_id, plan_tier, weekly_premium, max_weekly_payout,
    zone_adjustment, iss_adjustment, valid_from
  ) VALUES (
    NEW.id, NEW.plan_tier::TEXT, NEW.weekly_premium, NEW.max_weekly_payout,
    NEW.zone_adjustment, NEW.iss_adjustment, NOW()
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_log_policy_version ON policies;
CREATE TRIGGER trg_log_policy_version
  AFTER INSERT OR UPDATE OF plan_tier, weekly_premium, zone_adjustment, iss_adjustment
  ON policies FOR EACH ROW EXECUTE FUNCTION log_policy_version();


-- ── 4. IRDAI COMPLIANCE: IMMUTABLE SHA-256 HASH CHAIN ──────────

ALTER TABLE claims
  ADD COLUMN IF NOT EXISTS previous_hash TEXT,
  ADD COLUMN IF NOT EXISTS record_hash   TEXT;

CREATE OR REPLACE FUNCTION generate_claim_hash()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  prev_hash TEXT;
  payload   TEXT;
BEGIN
  SELECT record_hash INTO prev_hash
    FROM claims
    ORDER BY created_at DESC
    LIMIT 1;

  NEW.previous_hash := COALESCE(prev_hash, 'GENESIS_BLOCK');
  
  -- ARMOR: Coalesce every field to empty string to prevent NULL propagation
  payload := COALESCE(NEW.id::TEXT, '') || COALESCE(NEW.user_id::TEXT, '')
          || COALESCE(NEW.gross_payout::TEXT, '') || COALESCE(NEW.status::TEXT, '')
          || NEW.previous_hash;

  NEW.record_hash := encode(digest(payload, 'sha256'), 'hex');
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_generate_claim_hash ON claims;
CREATE TRIGGER trg_generate_claim_hash
  BEFORE INSERT ON claims
  FOR EACH ROW EXECUTE FUNCTION generate_claim_hash();


-- ── 5. SCALABILITY: DECLARATIVE PARTITIONING ───────────────────
-- Renames the old monolithic table, rebuilds it as a partitioned parent,
-- migrates all existing data, then creates rolling month partitions.

-- A. Shift Telemetry
ALTER TABLE IF EXISTS shift_telemetry RENAME TO shift_telemetry_old;

CREATE TABLE shift_telemetry (
  id                UUID        DEFAULT gen_random_uuid(),
  worker_id         UUID        NOT NULL,
  lat               FLOAT8      NOT NULL,
  lng               FLOAT8      NOT NULL,
  accuracy          FLOAT4,
  timestamp         TIMESTAMPTZ NOT NULL,
  is_mock_location  BOOLEAN     DEFAULT FALSE,
  activity_type     TEXT,
  battery_level     FLOAT4,
  signal_strength   INTEGER,
  is_low_confidence BOOLEAN     DEFAULT FALSE,
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (id, created_at)
) PARTITION BY RANGE (created_at);

CREATE TABLE shift_telemetry_y2026m04 PARTITION OF shift_telemetry
  FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');

CREATE TABLE shift_telemetry_y2026m05 PARTITION OF shift_telemetry
  FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');

-- ARMOR: Catch-all bucket for future dates so GPS tracking never crashes
CREATE TABLE shift_telemetry_default PARTITION OF shift_telemetry DEFAULT;

-- Migrate existing rows (runs only once; old table kept as backup)
DO $$ BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'shift_telemetry_old') THEN
    INSERT INTO shift_telemetry
      SELECT * FROM shift_telemetry_old
      ON CONFLICT DO NOTHING;
  END IF;
END $$;

-- B. Fraud Signal Logs
ALTER TABLE IF EXISTS fraud_signal_logs RENAME TO fraud_signal_logs_old;

CREATE TABLE fraud_signal_logs (
  id                UUID        DEFAULT gen_random_uuid(),
  claim_id          UUID        NOT NULL,
  signal_name       TEXT        NOT NULL,
  signal_value      FLOAT       NOT NULL,
  weight_applied    FLOAT       NOT NULL,
  score_contribution INTEGER    NOT NULL,
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (id, created_at)
) PARTITION BY RANGE (created_at);

CREATE TABLE fraud_signal_logs_y2026m04 PARTITION OF fraud_signal_logs
  FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');

CREATE TABLE fraud_signal_logs_y2026m05 PARTITION OF fraud_signal_logs
  FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');

-- ARMOR: Catch-all bucket for unpartitioned future dates
CREATE TABLE fraud_signal_logs_default PARTITION OF fraud_signal_logs DEFAULT;

DO $$ BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'fraud_signal_logs_old') THEN
    INSERT INTO fraud_signal_logs
      SELECT * FROM fraud_signal_logs_old
      ON CONFLICT DO NOTHING;
  END IF;
END $$;


-- ── 6. WORK VERIFICATION LAYER ─────────────────────────────────

CREATE TABLE IF NOT EXISTS work_sessions (
  id                       UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  worker_id                UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  platform_shift_id        TEXT,
  started_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ended_at                 TIMESTAMPTZ,
  total_deliveries         INTEGER     DEFAULT 0,
  zone_coverage_percentage FLOAT       DEFAULT 1.0,
  is_verified              BOOLEAN     DEFAULT FALSE,
  created_at               TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_work_sessions_lookup
  ON work_sessions(worker_id, started_at DESC);


-- ── 7. DATA TRUST SCORING FOR PARAMETRIC TRIGGERS ──────────────

ALTER TABLE disruption_events
  ADD COLUMN IF NOT EXISTS data_trust_score FLOAT
    CHECK (data_trust_score BETWEEN 0 AND 1),
  ADD COLUMN IF NOT EXISTS source_weight FLOAT DEFAULT 1.0;

-- Hard minimum trust before payout can be triggered
ALTER TABLE disruption_events
  DROP CONSTRAINT IF EXISTS chk_minimum_trust;
ALTER TABLE disruption_events
  ADD CONSTRAINT chk_minimum_trust
    CHECK (payout_triggered = FALSE OR data_trust_score >= 0.75);


-- ── 8. RLS ─────────────────────────────────────────────────────
DO $$
DECLARE t TEXT;
DECLARE new_tables TEXT[] := ARRAY[
  'wallet_balances','policy_versions','work_sessions'
];
BEGIN
  FOREACH t IN ARRAY new_tables LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('DROP POLICY IF EXISTS "allow_all" ON %I', t);
    EXECUTE format('CREATE POLICY "allow_all" ON %I FOR ALL USING (true)', t);
  END LOOP;
END $$;

COMMIT;
