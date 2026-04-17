-- ═══════════════════════════════════════════════════════════════
-- HUSTLR — FINAL CRITICAL REMEDIATION PATCH (PATCHED)
-- Run SECOND in Supabase SQL Editor (after enterprise_upgrade.sql)
-- Patches applied:
--   • UNIQUE INDEX partial predicate uses OR not IN (Postgres requirement)
--   • wallet trigger redefined with credit/debit logic
--   • policy_versions plan_tier stored as TEXT to survive enum migrations
-- ═══════════════════════════════════════════════════════════════

BEGIN;

-- ── 1. REMOVE PHANTOM 'ELITE' TIER ─────────────────────────────
-- Demote plan_tier to TEXT, swap enum, re-cast safely.

DROP TRIGGER IF EXISTS trg_log_policy_version ON policies;
ALTER TABLE policies      ALTER COLUMN plan_tier TYPE TEXT;
-- policy_versions already uses TEXT (from enterprise_upgrade.sql)

DROP TYPE IF EXISTS policy_tier_enum;
CREATE TYPE policy_tier_enum AS ENUM ('basic', 'standard', 'full');

ALTER TABLE policies DROP CONSTRAINT IF EXISTS policies_plan_tier_check;
ALTER TABLE policies ALTER COLUMN plan_tier DROP DEFAULT;

ALTER TABLE policies
  ALTER COLUMN plan_tier TYPE policy_tier_enum
  USING plan_tier::text::policy_tier_enum;

ALTER TABLE policies ALTER COLUMN plan_tier SET DEFAULT 'standard'::policy_tier_enum;

CREATE TRIGGER trg_log_policy_version
  AFTER INSERT OR UPDATE OF plan_tier, weekly_premium, zone_adjustment, iss_adjustment
  ON policies FOR EACH ROW EXECUTE FUNCTION log_policy_version();


-- ── 2. PREMIUM SAFETY CONSTRAINTS ──────────────────────────────
-- Fix any legacy ₹60 premiums (should be ₹49 standard)
UPDATE policies
  SET weekly_premium = 49, base_premium = 49
  WHERE plan_tier::TEXT = 'standard' AND weekly_premium = 60;

-- Fix legacy ₹29 premiums (should be ₹35 basic)
UPDATE policies
  SET weekly_premium = 35, base_premium = 35
  WHERE plan_tier::TEXT = 'basic' AND weekly_premium = 29;

ALTER TABLE policies DROP CONSTRAINT IF EXISTS chk_valid_premium;
ALTER TABLE policies ADD CONSTRAINT chk_valid_premium CHECK (
  (plan_tier::text = 'basic'    AND weekly_premium BETWEEN 30 AND 40)  OR
  (plan_tier::text = 'standard' AND weekly_premium BETWEEN 45 AND 55)  OR
  (plan_tier::text = 'full'     AND weekly_premium BETWEEN 70 AND 85)
);


-- ── 3. FIX WALLET SIGN CONVENTION ──────────────────────────────
-- Flutter app sends positive amounts for both credits and debits.
-- Direction determined by the 'type' column, NOT by sign.

ALTER TABLE wallet_transactions
  DROP CONSTRAINT IF EXISTS wallet_amount_sign_matches_type;

-- Convert any legacy negative values to absolute
UPDATE wallet_transactions SET amount = ABS(amount) WHERE amount < 0;

-- Enforce strictly non-negative amounts from here on
ALTER TABLE wallet_transactions
  ADD CONSTRAINT chk_wallet_amount_positive CHECK (amount >= 0);

-- Redefine trigger to use type-aware math (idempotent redefine)
CREATE OR REPLACE FUNCTION process_wallet_transaction()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO wallet_balances (user_id, balance)
  VALUES (NEW.user_id, 0)
  ON CONFLICT (user_id) DO NOTHING;

  PERFORM * FROM wallet_balances WHERE user_id = NEW.user_id FOR UPDATE;

  IF NEW.type = 'credit' THEN
    UPDATE wallet_balances
      SET balance = balance + NEW.amount, last_updated = NOW()
      WHERE user_id = NEW.user_id;
  ELSE
    -- chk_positive_balance rejects overdrafts atomically
    UPDATE wallet_balances
      SET balance = balance - NEW.amount, last_updated = NOW()
      WHERE user_id = NEW.user_id;
  END IF;

  RETURN NEW;
END;
$$;


-- ── 4. PAYOUT REQUESTS TABLE ────────────────────────────────────
DO $$ BEGIN
  CREATE TYPE payout_status_enum AS ENUM ('pending', 'processing', 'completed', 'failed');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS payout_requests (
  id             UUID               PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        UUID               NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  amount         INTEGER            NOT NULL CHECK (amount > 0),
  method         TEXT               NOT NULL CHECK (method IN ('upi', 'bank_direct')),
  upi_id         TEXT               DEFAULT NULL,
  bank_account   TEXT               DEFAULT NULL,
  ifsc_code      TEXT               DEFAULT NULL,
  status         payout_status_enum NOT NULL DEFAULT 'pending',
  reference_id   TEXT               DEFAULT NULL,
  error_message  TEXT               DEFAULT NULL,
  attempts       INTEGER            NOT NULL DEFAULT 0,
  initiated_at   TIMESTAMPTZ        NOT NULL DEFAULT NOW(),
  completed_at   TIMESTAMPTZ        DEFAULT NULL
);

CREATE INDEX IF NOT EXISTS idx_payout_requests_user
  ON payout_requests(user_id, initiated_at DESC);

-- RLS
ALTER TABLE payout_requests ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "allow_all" ON payout_requests;
CREATE POLICY "allow_all" ON payout_requests FOR ALL USING (true);


-- ── 5. FIX ACTIVE POLICY RENEWAL BLOCKER ───────────────────────
-- CRITICAL: PostgreSQL does NOT support IN() in partial index predicates.
-- Must use explicit OR conditions.

DROP INDEX IF EXISTS idx_active_policy;
CREATE UNIQUE INDEX idx_active_policy ON policies(user_id)
  WHERE status = 'active' OR status = 'renewed';


-- ── 6. FIX VACUOUS SESSION TIMEOUT CONSTRAINT ──────────────────
ALTER TABLE auth_sessions DROP CONSTRAINT IF EXISTS chk_session_timeout;

-- Replace with an index for efficient cleanup queries
CREATE INDEX IF NOT EXISTS idx_auth_sessions_expiry
  ON auth_sessions(last_seen_at)
  WHERE is_active = TRUE;


-- ── 7. KATTANKULATHUR H3 ZONE + POSTGIS WRAPPER ────────────────
INSERT INTO zones_h3 (zone_id, zone_name, city, h3_center, h3_resolution, center_lat, center_lng)
VALUES (
  'kattankulathur',
  'Kattankulathur Dark Store Zone',
  'Chennai',
  '8834e2a117fffff',
  8,
  12.8185,
  80.0419   -- SRM University / Potheri corridor
)
ON CONFLICT (zone_id) DO NOTHING;

-- Dynamic hub centroid lookup by zone_id
CREATE OR REPLACE FUNCTION hustlr_zone_depth_by_name(
  worker_lat DOUBLE PRECISION,
  worker_lon DOUBLE PRECISION,
  zone_id_in TEXT
) RETURNS TABLE (
  distance_km       NUMERIC,
  zone_depth_score  NUMERIC,
  depth_multiplier  NUMERIC,
  source            TEXT
) LANGUAGE sql STABLE AS $$
  SELECT * FROM hustlr_zone_depth(
    worker_lat,
    worker_lon,
    (SELECT center_lat FROM zones_h3 WHERE zone_id = zone_id_in LIMIT 1),
    (SELECT center_lng FROM zones_h3 WHERE zone_id = zone_id_in LIMIT 1)
  );
$$;


-- ── 8. STRUCTURAL INTEGRITY FIXES ──────────────────────────────

-- Link pool_health directly to risk_pools
ALTER TABLE pool_health
  ADD COLUMN IF NOT EXISTS pool_id UUID REFERENCES risk_pools(id) ON DELETE CASCADE;

-- Remove silent global default on claims.city
ALTER TABLE claims ALTER COLUMN city DROP DEFAULT;

-- Fast inbox query index
CREATE INDEX IF NOT EXISTS idx_notif_inbox
  ON notifications(user_id, read, created_at DESC)
  WHERE read = FALSE;

-- Fast disruption recency index (was missing from original schema)
CREATE INDEX IF NOT EXISTS idx_disruptions_started_at
  ON disruption_events(started_at DESC);


COMMIT;
