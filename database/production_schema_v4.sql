-- ═══════════════════════════════════════════════════════════
-- HUSTLR — PRODUCTION SCHEMA v4 (Enterprise Insurance Grade)
-- Addresses ALL critical gaps: Relational integrity, temporal modeling, audit trails
-- ═══════════════════════════════════════════════════════════

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ═══════════════════════════════════════════════════════════
-- SECTION 1 — ENUMS (Performance & Type Safety)
-- ═══════════════════════════════════════════════════════════

CREATE TYPE claim_status_enum AS ENUM ('PENDING','APPROVED','FLAGGED','REJECTED','SETTLED','PAYOUT_FAILED');
CREATE TYPE policy_status_enum AS ENUM ('active','expired','cancelled','suspended','renewed');
CREATE TYPE plan_tier_enum AS ENUM ('basic','standard','full','elite');
CREATE TYPE trust_tier_enum AS ENUM ('PLATINUM','GOLD','SILVER','BRONZE','AT_RISK');
CREATE TYPE rider_type_enum AS ENUM ('cyclone_cover','internet_blackout','curfew_strike','accident_blockspot','traffic_congestion','election_day');
CREATE TYPE rider_status_enum AS ENUM ('active','cancelled');
CREATE TYPE transaction_type_enum AS ENUM ('credit','debit');
CREATE TYPE transaction_category_enum AS ENUM ('premium','payout_tranche1','payout_tranche2','cashback','withdrawal','refund','other');
CREATE TYPE fraud_status_enum AS ENUM ('CLEAN','REVIEW','FLAGGED','REJECTED');
CREATE TYPE kyc_status_enum AS ENUM ('pending','submitted','verified','rejected');
CREATE TYPE shift_status_enum AS ENUM ('OFFLINE','ACTIVE','PAUSED');
CREATE TYPE cron_status_enum AS ENUM ('success','failed','partial','running');

-- ═══════════════════════════════════════════════════════════
-- SECTION 2 — CORE IDENTITY & AUTH
-- ═══════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS users (
  id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  name                TEXT        NOT NULL,
  phone               TEXT        UNIQUE NOT NULL,
  zone                TEXT        NOT NULL,
  city                TEXT        NOT NULL,
  platform            TEXT        NOT NULL DEFAULT 'Zepto',
  iss_score           INTEGER     DEFAULT NULL,
  shift_start         TIME        DEFAULT '08:00',
  shift_end           TIME        DEFAULT '22:00',
  shift_status        shift_status_enum NOT NULL DEFAULT 'OFFLINE',
  last_seen_at        TIMESTAMPTZ DEFAULT NULL,
  paused_at           TIMESTAMPTZ DEFAULT NULL,
  days_active         INTEGER     DEFAULT 0,
  onboarding_complete BOOLEAN     DEFAULT FALSE,
  fcm_token           TEXT        DEFAULT NULL,
  kyc_status          kyc_status_enum NOT NULL DEFAULT 'pending',
  kyc_verified_at     TIMESTAMPTZ DEFAULT NULL,
  referral_code       TEXT        UNIQUE DEFAULT NULL,
  referred_by         UUID        REFERENCES users(id) ON DELETE SET NULL,
  trust_score         INTEGER     NOT NULL DEFAULT 100 CHECK (trust_score BETWEEN 0 AND 1000),
  trust_tier          trust_tier_enum NOT NULL DEFAULT 'SILVER',
  clean_weeks         INTEGER     DEFAULT 0,
  cashback_earned     INTEGER     DEFAULT 0,
  cashback_pending    INTEGER     DEFAULT 0,
  created_at          TIMESTAMPTZ DEFAULT NOW(),
  updated_at          TIMESTAMPTZ DEFAULT NOW()
);

-- Trust tier auto-calculation trigger
CREATE OR REPLACE FUNCTION update_trust_tier()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.trust_score >= 90 THEN NEW.trust_tier := 'PLATINUM';
  ELSIF NEW.trust_score >= 75 THEN NEW.trust_tier := 'GOLD';
  ELSIF NEW.trust_score >= 60 THEN NEW.trust_tier := 'SILVER';
  ELSIF NEW.trust_score >= 50 THEN NEW.trust_tier := 'BRONZE';
  ELSE NEW.trust_tier := 'AT_RISK';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_update_trust_tier
  BEFORE INSERT OR UPDATE OF trust_score ON users
  FOR EACH ROW EXECUTE FUNCTION update_trust_tier();

CREATE TABLE IF NOT EXISTS auth_sessions (
  id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  phone          TEXT        NOT NULL,
  token_hash     TEXT        NOT NULL UNIQUE,
  device_id      TEXT        DEFAULT NULL,
  device_label   TEXT        DEFAULT NULL,
  is_active      BOOLEAN     NOT NULL DEFAULT TRUE,
  revoked_reason TEXT        DEFAULT NULL,
  created_at     TIMESTAMPTZ DEFAULT NOW(),
  last_seen_at   TIMESTAMPTZ DEFAULT NOW(),
  revoked_at     TIMESTAMPTZ DEFAULT NULL,
  CONSTRAINT chk_session_timeout CHECK (last_seen_at > created_at - INTERVAL '24 hours')
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_auth_sessions_single_active 
  ON auth_sessions (user_id) WHERE is_active = TRUE;

-- ═══════════════════════════════════════════════════════════
-- SECTION 3 — INSURANCE LIFECYCLE (ACTUARIALLY SOUND)
-- ═══════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS risk_pools (
  id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  city                TEXT        NOT NULL,
  risk_type           TEXT        NOT NULL,
  pool_name           TEXT        NOT NULL,
  total_premium       INTEGER     NOT NULL DEFAULT 0,
  total_claims_paid   INTEGER     NOT NULL DEFAULT 0,
  reserve_fund        INTEGER     NOT NULL DEFAULT 0,
  loss_ratio          FLOAT       NOT NULL DEFAULT 0,
  active_policies     INTEGER     NOT NULL DEFAULT 0,
  enrollment_stopped  BOOLEAN     NOT NULL DEFAULT FALSE,
  created_at          TIMESTAMPTZ DEFAULT NOW(),
  updated_at          TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (city, risk_type)
);

CREATE TABLE IF NOT EXISTS policies (
  id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  plan_tier           plan_tier_enum NOT NULL DEFAULT 'standard',
  base_premium        INTEGER     NOT NULL DEFAULT 49,
  zone_adjustment     INTEGER     NOT NULL DEFAULT 0,
  iss_adjustment      INTEGER     NOT NULL DEFAULT 0,
  weekly_premium      INTEGER     NOT NULL DEFAULT 49,
  max_weekly_payout   INTEGER     NOT NULL DEFAULT 700,
  max_daily_payout    INTEGER     NOT NULL DEFAULT 150,
  status              policy_status_enum NOT NULL DEFAULT 'active',
  auto_renew          BOOLEAN     NOT NULL DEFAULT TRUE,
  
  -- ACTUARIAL FIX: Temporal modeling
  coverage_start      DATE        NOT NULL DEFAULT CURRENT_DATE,
  paid_until          DATE        NOT NULL DEFAULT CURRENT_DATE + INTERVAL '7 days',
  commitment_end      DATE        NOT NULL DEFAULT CURRENT_DATE + INTERVAL '13 weeks',
  renewal_date        DATE        DEFAULT NULL, -- Populated when renewed
  
  pool_id             UUID        REFERENCES risk_pools(id),
  created_at          TIMESTAMPTZ DEFAULT NOW(),
  updated_at          TIMESTAMPTZ DEFAULT NOW(),
  
  CONSTRAINT chk_policy_duration CHECK (commitment_end - coverage_start = INTERVAL '13 weeks'),
  CONSTRAINT chk_active_commitment CHECK (status != 'active' OR commitment_end >= CURRENT_DATE)
);

-- NEW: Riders Table (Relational Integrity)
CREATE TABLE IF NOT EXISTS riders (
  id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  policy_id           UUID        NOT NULL REFERENCES policies(id) ON DELETE CASCADE,
  rider_type          rider_type_enum NOT NULL,
  premium_per_week    INTEGER     NOT NULL DEFAULT 0,
  start_date          DATE        NOT NULL DEFAULT CURRENT_DATE,
  end_date            DATE        NOT NULL,
  blackout_end        TIMESTAMPTZ NOT NULL, -- 72h blackout for adverse selection
  status              rider_status_enum NOT NULL DEFAULT 'active',
  created_at          TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT chk_rider_dates CHECK (end_date > start_date)
);

-- Rider validation trigger
CREATE OR REPLACE FUNCTION validate_rider_dates()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  pol_commitment DATE;
BEGIN
  SELECT commitment_end INTO pol_commitment FROM policies WHERE id = NEW.policy_id;
  IF NEW.end_date != pol_commitment THEN
    RAISE EXCEPTION 'Rider end_date (%) must exactly match Policy commitment_end (%)', NEW.end_date, pol_commitment;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_validate_rider_dates
  BEFORE INSERT OR UPDATE ON riders
  FOR EACH ROW EXECUTE FUNCTION validate_rider_dates();

-- NEW: Renewal History (Audit Trail)
CREATE TABLE IF NOT EXISTS renewal_history (
  id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  policy_id           UUID        NOT NULL REFERENCES policies(id) ON DELETE CASCADE,
  old_commitment_end  DATE        NOT NULL,
  new_commitment_end  DATE        NOT NULL,
  weekly_premium      INTEGER     NOT NULL,
  renewed_at          TIMESTAMPTZ DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════
-- SECTION 4 — CLAIMS & FINANCIAL LEDGER
-- ═══════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS appeal_requests (
  id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  claim_id            UUID        NOT NULL,
  reason              TEXT        NOT NULL,
  evidence_urls       TEXT[]      DEFAULT '{}',
  status              TEXT        NOT NULL DEFAULT 'open' CHECK (status IN ('open','under_review','approved','rejected')),
  reviewed_by         TEXT        DEFAULT NULL,
  review_note         TEXT        DEFAULT NULL,
  opened_at           TIMESTAMPTZ DEFAULT NOW(),
  resolved_at         TIMESTAMPTZ DEFAULT NULL,
  UNIQUE (claim_id)
);

CREATE TABLE IF NOT EXISTS claims (
  id                    UUID      PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID      NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  policy_id             UUID      REFERENCES policies(id) ON DELETE RESTRICT, -- Prevent orphaned claims
  trigger_type          TEXT      NOT NULL,
  zone                  TEXT      NOT NULL,
  city                  TEXT      NOT NULL DEFAULT 'Chennai',
  severity              FLOAT     NOT NULL DEFAULT 1.0  CHECK (severity BETWEEN 0 AND 1),
  duration_hours        FLOAT     NOT NULL DEFAULT 3.0  CHECK (duration_hours > 0),
  
  -- FINTECH MATH CONSTRAINTS
  gross_payout          INTEGER   NOT NULL CHECK (gross_payout >= 0),
  tranche1              INTEGER   NOT NULL CHECK (tranche1 >= 0),
  tranche2              INTEGER   NOT NULL CHECK (tranche2 >= 0),
  CHECK (tranche1 + tranche2 = gross_payout), -- Prevent overpayment
  CHECK (gross_payout <= (SELECT max_weekly_payout FROM policies WHERE id = policy_id)), -- Policy limits
  
  fraud_score           INTEGER   NOT NULL DEFAULT 0 CHECK (fraud_score BETWEEN 0 AND 100),
  fraud_status          fraud_status_enum NOT NULL DEFAULT 'CLEAN',
  fps_signals           JSONB     DEFAULT '{}',
  zone_depth_score      FLOAT     DEFAULT NULL,
  shift_verified        BOOLEAN   DEFAULT TRUE,
  underwriting_passed   BOOLEAN   DEFAULT TRUE,
  status                claim_status_enum NOT NULL DEFAULT 'PENDING',
  tranche1_released_at  TIMESTAMPTZ DEFAULT NULL,
  tranche2_released_at  TIMESTAMPTZ DEFAULT NULL,
  settled_at            TIMESTAMPTZ DEFAULT NULL,
  payout_attempts       INTEGER   DEFAULT 0,
  payout_error          TEXT      DEFAULT NULL,
  payout_failed_at      TIMESTAMPTZ DEFAULT NULL,
  appeal_id             UUID        REFERENCES appeal_requests(id) ON DELETE SET NULL,
  created_at            TIMESTAMPTZ DEFAULT NOW(),
  updated_at            TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE appeal_requests ADD CONSTRAINT fk_appeals_claim FOREIGN KEY (claim_id) REFERENCES claims(id) ON DELETE CASCADE;

-- NEW: Wallet with Balance Snapshots
CREATE TABLE IF NOT EXISTS wallet_transactions (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  amount      INTEGER     NOT NULL,
  type        transaction_type_enum NOT NULL,
  category    transaction_category_enum NOT NULL DEFAULT 'other',
  reference   TEXT,
  description TEXT,
  claim_id    UUID        REFERENCES claims(id) ON DELETE SET NULL,
  upi_ref     TEXT        DEFAULT NULL,
  idempotency_key TEXT UNIQUE DEFAULT NULL, -- Prevent duplicate transactions
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  CHECK ((type = 'credit' AND amount >= 0) OR (type = 'debit' AND amount <= 0))
);

-- NEW: Balance snapshots for performance
CREATE TABLE IF NOT EXISTS wallet_balance_snapshots (
  id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  balance             INTEGER     NOT NULL,
  calculated_at        TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, calculated_at)
);

-- ═══════════════════════════════════════════════════════════
-- SECTION 5 — FRAUD & TELEMETRY (STRUCTURED LOGGING)
-- ═══════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS fraud_baselines (
  id                      UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id                 UUID    UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  avg_daily_deliveries    FLOAT   DEFAULT 0,
  typical_zones           TEXT[]  DEFAULT '{}',
  avg_shift_start_hour    INTEGER DEFAULT 8,
  avg_shift_end_hour      INTEGER DEFAULT 22,
  home_wifi_ssids         TEXT[]  DEFAULT '{}',
  typical_cell_towers     TEXT[]  DEFAULT '{}',
  weeks_active            INTEGER DEFAULT 0,
  claim_count_30d         INTEGER DEFAULT 0,
  last_updated            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS fraud_flags (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  worker_id   UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  claim_id    UUID        REFERENCES claims(id) ON DELETE SET NULL,
  reason      TEXT        NOT NULL,
  frs_score   INTEGER     NOT NULL DEFAULT 0,
  timestamp   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  resolved    BOOLEAN     DEFAULT FALSE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- NEW: Fraud Signal Logs (Structured)
CREATE TABLE IF NOT EXISTS fraud_signal_logs (
  id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  claim_id          UUID        NOT NULL REFERENCES claims(id) ON DELETE CASCADE,
  signal_name       TEXT        NOT NULL,
  signal_value      FLOAT       NOT NULL,
  weight            FLOAT       NOT NULL DEFAULT 1.0,
  contribution      INTEGER     NOT NULL DEFAULT 0,
  model_version     TEXT        DEFAULT 'v1.0',
  created_at        TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS device_fingerprint_events (
  id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  fingerprint_hash  TEXT        NOT NULL,
  zone              TEXT,
  created_at        TIMESTAMPTZ DEFAULT NOW()
);

-- PARTITIONED: Shift Telemetry (High-write table)
CREATE TABLE IF NOT EXISTS shift_telemetry (
  id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  worker_id         UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  lat               FLOAT8      NOT NULL,
  lng               FLOAT8      NOT NULL,
  accuracy          FLOAT4,
  timestamp         TIMESTAMPTZ NOT NULL,
  is_mock_location  BOOLEAN     DEFAULT FALSE,
  activity_type     TEXT,
  battery_level     FLOAT4,
  signal_strength   INTEGER,
  is_low_confidence BOOLEAN     DEFAULT FALSE,
  created_at        TIMESTAMPTZ DEFAULT NOW()
) PARTITION BY RANGE (created_at);

-- Create partitions (current month + 2 future months)
CREATE TABLE IF NOT EXISTS shift_telemetry_y2024m04 PARTITION OF shift_telemetry
    FOR VALUES FROM ('2024-04-01') TO ('2024-05-01');
CREATE TABLE IF NOT EXISTS shift_telemetry_y2024m05 PARTITION OF shift_telemetry
    FOR VALUES FROM ('2024-05-01') TO ('2024-06-01');
CREATE TABLE IF NOT EXISTS shift_telemetry_y2024m06 PARTITION OF shift_telemetry
    FOR VALUES FROM ('2024-06-01') TO ('2024-07-01');

-- NEW: Shift Summary (Aggregation)
CREATE TABLE IF NOT EXISTS shift_summary (
  id                    UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  worker_id             UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  week_start            DATE        NOT NULL,
  total_shift_seconds   FLOAT        DEFAULT 0,
  total_gap_seconds    FLOAT        DEFAULT 0,
  total_deliveries     INTEGER     DEFAULT 0,
  avg_signal_strength   FLOAT        DEFAULT 0,
  frs_penalties         INTEGER     DEFAULT 0,
  efficiency_score      FLOAT        DEFAULT 0,
  created_at            TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(worker_id, week_start)
);

CREATE TABLE IF NOT EXISTS shift_gaps (
  id                    UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  worker_id             UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  gap_start             TIMESTAMPTZ NOT NULL,
  gap_end               TIMESTAMPTZ,
  gap_duration_seconds  INTEGER,
  frs_penalty           INTEGER     DEFAULT 0,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

-- Gap penalty calculation trigger
CREATE OR REPLACE FUNCTION apply_frs_penalties()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  penalty INTEGER;
BEGIN
  -- Calculate penalty based on gap duration
  penalty := CASE 
    WHEN NEW.gap_duration_seconds > 3600 THEN 30  -- 1+ hour
    WHEN NEW.gap_duration_seconds > 1800 THEN 20  -- 30+ min
    WHEN NEW.gap_duration_seconds > 600 THEN 10   -- 10+ min
    ELSE 0
  END;
  
  -- Update user's trust score
  UPDATE users 
  SET trust_score = GREATEST(trust_score - penalty, 0)
  WHERE id = NEW.worker_id;
  
  -- Log the penalty
  INSERT INTO fraud_flags (worker_id, reason, frs_score, timestamp)
  VALUES (NEW.worker_id, 'shift_gap_penalty', penalty, NEW.gap_start);
  
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_apply_frs_penalties
  BEFORE INSERT OR UPDATE ON shift_gaps
  FOR EACH ROW EXECUTE FUNCTION apply_frs_penalties();

CREATE TABLE IF NOT EXISTS pending_frs_adjustments (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  worker_id   UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  adjustment  INTEGER     NOT NULL,
  reason      TEXT        NOT NULL,
  is_consumed BOOLEAN     DEFAULT FALSE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════
-- SECTION 6 — DISRUPTION & OPERATIONS
-- ═════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS disruption_events (
  id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  zone              TEXT        NOT NULL,
  city              TEXT        NOT NULL DEFAULT 'Chennai',
  trigger_type      TEXT        NOT NULL,
  severity          FLOAT       NOT NULL DEFAULT 1.0,
  rainfall_mm       FLOAT       DEFAULT 0,
  temperature_c     FLOAT       DEFAULT 0,
  aqi               INTEGER     DEFAULT 0,
  data_source       TEXT        DEFAULT 'live',
  started_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ended_at          TIMESTAMPTZ DEFAULT NULL,
  duration_hrs      FLOAT       DEFAULT NULL,
  payout_triggered  BOOLEAN     DEFAULT FALSE,
  created_at        TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS shadow_policies (
  id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  week_start          DATE        NOT NULL,
  simulated_payout    INTEGER     NOT NULL DEFAULT 0,
  disruption_events   JSONB       DEFAULT '[]',
  nudge_sent          BOOLEAN     DEFAULT FALSE,
  nudge_sent_at       TIMESTAMPTZ DEFAULT NULL,
  created_at          TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (user_id, week_start)
);

-- NEW: Work Advisor Logs
CREATE TABLE IF NOT EXISTS work_advisor_logs (
  id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  zone              TEXT        NOT NULL,
  plan_tier         plan_tier_enum NOT NULL,
  recommendation    TEXT        NOT NULL,
  confidence_score  FLOAT        DEFAULT 0,
  action_taken      TEXT        DEFAULT NULL,
  effectiveness_score INTEGER DEFAULT NULL,
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  sent_at           TIMESTAMPTZ DEFAULT NULL
);

-- ═══════════════════════════════════════════════════════════
-- SECTION 7 — FINANCIAL SETTLEMENTS & CASHBACK
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS pool_health (
  id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  week_start          DATE        NOT NULL,
  city                TEXT        NOT NULL,
  risk_type           TEXT        NOT NULL DEFAULT 'rain',
  premiums_collected  INTEGER     DEFAULT 0,
  claims_paid         INTEGER     DEFAULT 0,
  burning_cost_rate   FLOAT       DEFAULT 0,
  enrollment_stopped  BOOLEAN     DEFAULT FALSE,
  created_at          TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (week_start, city, risk_type)
);

CREATE TABLE IF NOT EXISTS circuit_breakers (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  zone            TEXT        NOT NULL,
  city            TEXT        NOT NULL DEFAULT 'Chennai',
  trigger_type    TEXT        NOT NULL,
  claims_count    INTEGER     DEFAULT 0,
  hourly_limit    INTEGER     DEFAULT 50,
  daily_limit     INTEGER     DEFAULT 500,
  bcr_at_trip     FLOAT       DEFAULT 0,
  tripped         BOOLEAN     DEFAULT FALSE,
  tripped_at      TIMESTAMPTZ DEFAULT NULL,
  reset_at        TIMESTAMPTZ DEFAULT NULL,
  reason          TEXT        DEFAULT NULL,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (zone, trigger_type)
);

CREATE TABLE IF NOT EXISTS weekly_settlements (
  id                    UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  week_start            DATE        NOT NULL,
  week_end              DATE        NOT NULL,
  city                  TEXT        NOT NULL,
  risk_type             TEXT        NOT NULL,
  total_premium         INTEGER     NOT NULL DEFAULT 0,
  total_claims_paid     INTEGER     NOT NULL DEFAULT 0,
  loss_ratio            FLOAT       NOT NULL DEFAULT 0,
  policies_count        INTEGER     NOT NULL DEFAULT 0,
  claims_count          INTEGER     NOT NULL DEFAULT 0,
  reserve_contribution  INTEGER     NOT NULL DEFAULT 0,
  reinsurance_triggered BOOLEAN     DEFAULT FALSE,
  settled_at            TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (week_start, city, risk_type)
);

-- NEW: Cashback Payouts Tracking
CREATE TABLE IF NOT EXISTS cashback_payouts (
  id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  amount              INTEGER     NOT NULL,
  period_start        DATE        NOT NULL,
  period_end          DATE        NOT NULL,
  calculated_at       TIMESTAMPTZ DEFAULT NOW(),
  paid_at             TIMESTAMPTZ DEFAULT NULL,
  status              TEXT        NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','paid','failed')),
  created_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS reinsurance_triggers (
  id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  settlement_id     UUID        NOT NULL REFERENCES weekly_settlements(id) ON DELETE CASCADE,
  city              TEXT        NOT NULL,
  risk_type         TEXT        NOT NULL,
  loss_ratio        FLOAT       NOT NULL,
  excess_claims     INTEGER     NOT NULL DEFAULT 0,
  reinsurer_name    TEXT        DEFAULT 'Munich Re',
  amount_recovered  INTEGER     DEFAULT 0,
  status            TEXT        NOT NULL DEFAULT 'filed' CHECK (status IN ('filed','processing','settled','rejected')),
  filed_at          TIMESTAMPTZ DEFAULT NOW(),
  settled_at        TIMESTAMPTZ DEFAULT NULL
);

-- ═════════════════════════════════════════════════════════════
-- SECTION 8 — TRUST, NOTIFICATIONS, ADMIN
-- ═════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS trust_events (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID        REFERENCES users(id) ON DELETE CASCADE,
  event_type    TEXT        NOT NULL,
  score_change  INTEGER     NOT NULL,
  new_score     INTEGER     NOT NULL,
  reason        TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS notifications (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title       TEXT        NOT NULL,
  body        TEXT        NOT NULL,
  type        TEXT        NOT NULL DEFAULT 'general'
              CHECK (type IN (
                'payout_credited','claim_update','policy_renewal',
                'shadow_nudge','fraud_alert','kyc_update','general'
              )),
  read        BOOLEAN     NOT NULL DEFAULT FALSE,
  action_url  TEXT        DEFAULT NULL,
  metadata    JSONB       DEFAULT '{}',
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS referrals (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  referrer_id     UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  referred_id     UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reward_amount   INTEGER     NOT NULL DEFAULT 50,
  reward_status   TEXT        NOT NULL DEFAULT 'pending'
                              CHECK (reward_status IN ('pending','paid','expired')),
  reward_paid_at  TIMESTAMPTZ DEFAULT NULL,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (referrer_id, referred_id)
);

-- NEW: Cron Execution Logs (MANDATORY for Ops)
CREATE TABLE IF NOT EXISTS cron_execution_logs (
  id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  job_name          TEXT        NOT NULL,
  status            cron_status_enum NOT NULL DEFAULT 'running',
  started_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at      TIMESTAMPTZ,
  records_processed INTEGER     DEFAULT 0,
  records_failed   INTEGER     DEFAULT 0,
  error_details     TEXT,
  job_duration_ms  INTEGER
);

CREATE TABLE IF NOT EXISTS admin_actions (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id    TEXT        NOT NULL,
  action_type TEXT        NOT NULL
              CHECK (action_type IN (
                'approve_claim','reject_claim','flag_claim',
                'adjust_pool','override_fraud','kyc_verify',
                'manual_payout','other'
              )),
  target_type TEXT        NOT NULL,
  target_id   UUID        NOT NULL,
  reason      TEXT        DEFAULT NULL,
  metadata    JSONB       DEFAULT '{}',
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS regional_intelligence_snapshots (
  id              UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  week_start      DATE    NOT NULL,
  city            TEXT    NOT NULL,
  risk_score      FLOAT   NOT NULL DEFAULT 0.5,
  rain_exposure   FLOAT   NOT NULL DEFAULT 0,
  aqi_stress      FLOAT   NOT NULL DEFAULT 0,
  platform_risk   FLOAT   NOT NULL DEFAULT 0,
  summary         TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (week_start, city)
);

-- ═══════════════════════════════════════════════════════════
-- SECTION 9 — INDEXES FOR SCALE
-- ═════════════════════════════════════════════════════════════

-- Core tables
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
CREATE INDEX IF NOT EXISTS idx_users_zone ON users(zone);
CREATE INDEX IF NOT EXISTS idx_users_city ON users(city);
CREATE INDEX IF NOT EXISTS idx_users_trust_score ON users(trust_score DESC);
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_ref_code ON users(referral_code) WHERE referral_code IS NOT NULL;

-- Policies and riders
CREATE INDEX IF NOT EXISTS idx_policies_user_id ON policies(user_id);
CREATE INDEX IF NOT EXISTS idx_policies_status ON policies(status);
CREATE INDEX IF NOT EXISTS idx_policies_commitment ON policies(commitment_end);
CREATE UNIQUE INDEX IF NOT EXISTS idx_active_policy ON policies(user_id) WHERE status = 'active';
CREATE INDEX IF NOT EXISTS idx_riders_policy ON riders(policy_id);
CREATE INDEX IF NOT EXISTS idx_riders_status ON riders(status);

-- Claims processing
CREATE INDEX IF NOT EXISTS idx_claims_user_id ON claims(user_id);
CREATE INDEX IF NOT EXISTS idx_claims_status ON claims(status);
CREATE INDEX IF NOT EXISTS idx_claims_created_at ON claims(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_claims_zone_ts ON claims(zone, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_claims_fraud_status ON claims(fraud_status);
CREATE INDEX IF NOT EXISTS idx_claims_policy_id ON claims(policy_id);
CREATE INDEX IF NOT EXISTS idx_claims_composite ON claims(policy_id, status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_claims_fps_signals ON claims USING gin(fps_signals jsonb_path_ops);

-- Wallet and balance
CREATE INDEX IF NOT EXISTS idx_wallet_user_id ON wallet_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_wallet_created_at ON wallet_transactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_wallet_category ON wallet_transactions(user_id, category);
CREATE INDEX IF NOT EXISTS idx_wallet_claim_id ON wallet_transactions(claim_id);
CREATE INDEX IF NOT EXISTS idx_wallet_idempotency ON wallet_transactions(idempotency_key);
CREATE INDEX IF NOT EXISTS idx_balance_snapshots_user ON wallet_balance_snapshots(user_id, calculated_at DESC);

-- Telemetry and fraud
CREATE INDEX IF NOT EXISTS idx_fraud_flags_worker ON fraud_flags(worker_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_fraud_signals_claim ON fraud_signal_logs(claim_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_dfe_hash_ts ON device_fingerprint_events(fingerprint_hash, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_dfe_zone_ts ON device_fingerprint_events(zone, created_at DESC) WHERE zone IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_telemetry_worker_ts ON shift_telemetry(worker_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_gaps_worker ON shift_gaps(worker_id, gap_start DESC);
CREATE INDEX IF NOT EXISTS idx_frs_adj_worker ON pending_frs_adjustments(worker_id) WHERE is_consumed = FALSE;
CREATE INDEX IF NOT EXISTS idx_trust_events_user ON trust_events(user_id, created_at DESC);

-- Operations
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON notifications(user_id, created_at DESC) WHERE read = FALSE;
CREATE INDEX IF NOT EXISTS idx_ref_referrer ON referrals(referrer_id);
CREATE INDEX IF NOT EXISTS idx_ref_referred ON referrals(referred_id);
CREATE INDEX IF NOT EXISTS idx_appeals_claim ON appeal_requests(claim_id);
CREATE INDEX IF NOT EXISTS idx_appeals_user ON appeal_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_admin_target ON admin_actions(target_id);
CREATE INDEX IF NOT EXISTS idx_cron_job_status ON cron_execution_logs(job_name, started_at DESC);

-- Settlements and pools
CREATE INDEX IF NOT EXISTS idx_pool_health_city ON pool_health(city, week_start DESC);
CREATE INDEX IF NOT EXISTS idx_cb_zone_type ON circuit_breakers(zone, trigger_type);
CREATE INDEX IF NOT EXISTS idx_weekly_settlements_date ON weekly_settlements(week_start DESC);
CREATE INDEX IF NOT EXISTS idx_reinsurance_settlement ON reinsurance_triggers(settlement_id);

-- Disruptions and work advisor
CREATE INDEX IF NOT EXISTS idx_disruptions_zone ON disruption_events(zone);
CREATE INDEX IF NOT EXISTS idx_disruptions_ts ON disruption_events(started_at DESC);
CREATE INDEX IF NOT EXISTS idx_disruptions_city ON disruption_events(city, started_at DESC);
CREATE INDEX IF NOT EXISTS idx_shadow_user ON shadow_policies(user_id);
CREATE INDEX IF NOT EXISTS idx_shadow_week ON shadow_policies(week_start);
CREATE INDEX IF NOT EXISTS idx_work_advisor_user ON work_advisor_logs(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_cashback_user ON cashback_payouts(user_id, created_at DESC);

-- ═══════════════════════════════════════════════════════════
-- SECTION 10 — TRIGGERS & AUTOMATION
-- ═════════════════════════════════════════════════════════════

-- Auto-generate referral_code
CREATE OR REPLACE FUNCTION generate_referral_code()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.referral_code IS NULL THEN
    NEW.referral_code := 'HUSTLR-' || upper(substring(gen_random_uuid()::text, 1, 5));
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_referral_code BEFORE INSERT ON users FOR EACH ROW EXECUTE FUNCTION generate_referral_code();

-- Auto-create fraud_baseline
CREATE OR REPLACE FUNCTION create_fraud_baseline()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO fraud_baselines (user_id, typical_zones, avg_shift_start_hour, avg_shift_end_hour) 
  VALUES (NEW.id, ARRAY[NEW.zone], 8, 22) 
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_fraud_baseline AFTER INSERT ON users FOR EACH ROW EXECUTE FUNCTION create_fraud_baseline();

-- Sync risk_pool on policy change
CREATE OR REPLACE FUNCTION sync_risk_pool()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'INSERT' AND NEW.status = 'active' AND NEW.pool_id IS NOT NULL THEN
    UPDATE risk_pools SET
      active_policies = active_policies + 1,
      total_premium   = total_premium   + NEW.weekly_premium,
      updated_at      = NOW()
    WHERE id = NEW.pool_id;
  END IF;

  IF TG_OP = 'UPDATE' AND NEW.pool_id IS NOT NULL THEN
    IF NEW.status IN ('expired','cancelled','renewed') AND OLD.status = 'active' THEN
      UPDATE risk_pools SET active_policies = GREATEST(active_policies - 1, 0), updated_at = NOW() WHERE id = NEW.pool_id;
    ELSIF NEW.status = 'active' AND OLD.status IN ('expired','cancelled','renewed') THEN
      UPDATE risk_pools SET active_policies = active_policies + 1, updated_at = NOW() WHERE id = NEW.pool_id;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_policy_pool_sync AFTER INSERT OR UPDATE ON policies FOR EACH ROW EXECUTE FUNCTION sync_risk_pool();

-- Update pool claims_paid when claim is APPROVED
CREATE OR REPLACE FUNCTION update_pool_on_claim_approved()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.status = 'APPROVED' AND OLD.status = 'PENDING' AND NEW.policy_id IS NOT NULL THEN
    UPDATE risk_pools rp SET
      total_claims_paid = total_claims_paid + NEW.gross_payout,
      loss_ratio = ROUND(
        CASE WHEN (total_premium + 0.0) > 0 THEN (total_claims_paid + NEW.gross_payout)::NUMERIC / total_premium::NUMERIC ELSE 0 END, 4
      ),
      updated_at = NOW()
    FROM policies p
    WHERE p.id = NEW.policy_id AND rp.id = p.pool_id;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_claim_pool_update AFTER UPDATE ON claims FOR EACH ROW EXECUTE FUNCTION update_pool_on_claim_approved();

-- Auto-compute disruption duration
CREATE OR REPLACE FUNCTION compute_disruption_duration()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.ended_at IS NOT NULL AND OLD.ended_at IS NULL THEN
    NEW.duration_hrs := EXTRACT(EPOCH FROM (NEW.ended_at - NEW.started_at)) / 3600.0;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_disruption_duration BEFORE UPDATE ON disruption_events FOR EACH ROW EXECUTE FUNCTION compute_disruption_duration();

-- Auto-update timestamp fields
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DO $$
DECLARE
  t TEXT;
  tables_with_ts TEXT[] := ARRAY['users','risk_pools','policies','claims','appeal_requests'];
BEGIN
  FOREACH t IN ARRAY tables_with_ts LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS trg_updated_at ON %I', t);
    EXECUTE format('CREATE TRIGGER trg_updated_at BEFORE UPDATE ON %I FOR EACH ROW EXECUTE FUNCTION update_updated_at()', t);
  END LOOP;
END $$;

-- ═══════════════════════════════════════════════════════════
-- SECTION 11: RLS POLICIES (PROPER SECURITY)
-- This section implements proper Row Level Security with user ownership, service roles, and admin restrictions

DO $$
DECLARE
  t TEXT;
  tables TEXT[] := ARRAY[
    'users','auth_sessions','risk_pools','policies','riders','claims','appeal_requests',
    'wallet_transactions','wallet_balance_snapshots','disruption_events','shadow_policies',
    'fraud_baselines','fraud_flags','fraud_signal_logs','device_fingerprint_events',
    'shift_telemetry','shift_gaps','shift_summary','pending_frs_adjustments',
    'trust_events','notifications','referrals','renewal_history','cashback_payouts',
    'pool_health','circuit_breakers','weekly_settlements','reinsurance_triggers',
    'work_advisor_logs','cron_execution_logs','admin_actions','regional_intelligence_snapshots'
  ];
BEGIN
  FOREACH t IN ARRAY tables LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
  END LOOP;
END $$;

-- Drop any existing allow_all policies
DO $$
DECLARE
  t TEXT;
  tables TEXT[] := ARRAY[
    'users','auth_sessions','risk_pools','policies','riders','claims','appeal_requests',
    'wallet_transactions','wallet_balance_snapshots','disruption_events','shadow_policies',
    'fraud_baselines','fraud_flags','fraud_signal_logs','device_fingerprint_events',
    'shift_telemetry','shift_gaps','shift_summary','pending_frs_adjustments',
    'trust_events','notifications','referrals','renewal_history','cashback_payouts',
    'pool_health','circuit_breakers','weekly_settlements','reinsurance_triggers',
    'work_advisor_logs','cron_execution_logs','admin_actions','regional_intelligence_snapshots'
  ];
BEGIN
  FOREACH t IN ARRAY tables LOOP
    EXECUTE format('DROP POLICY IF EXISTS "allow_all" ON %I', t);
  END LOOP;
END $$;

-- USER-OWNED DATA POLICIES
CREATE POLICY "users_read_own" ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "users_update_own" ON users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "users_insert_own" ON users FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "auth_sessions_user_access" ON auth_sessions FOR ALL 
USING (auth.uid() = user_id OR auth.jwt() ->> 'role' = 'service_role');

CREATE POLICY "policies_read_own" ON policies FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "policies_update_own" ON policies FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "claims_read_own" ON claims FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "claims_update_own" ON claims FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "riders_policy_access" ON riders FOR ALL 
USING (EXISTS (SELECT 1 FROM policies WHERE id = policy_id AND user_id = auth.uid()));

CREATE POLICY "wallet_transactions_read_own" ON wallet_transactions FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "wallet_transactions_insert_own" ON wallet_transactions FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "wallet_balance_snapshots_read_own" ON wallet_balance_snapshots FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "appeal_requests_user_access" ON appeal_requests FOR ALL 
USING (user_id = auth.uid() OR EXISTS (SELECT 1 FROM claims WHERE id = claim_id AND user_id = auth.uid()));

CREATE POLICY "notifications_user_access" ON notifications FOR ALL 
USING (user_id = auth.uid());

CREATE POLICY "referrals_user_access" ON referrals FOR SELECT 
USING (referrer_id = auth.uid() OR referred_id = auth.uid());

CREATE POLICY "renewal_history_user_access" ON renewal_history FOR SELECT 
USING (EXISTS (SELECT 1 FROM policies WHERE id = policy_id AND user_id = auth.uid()));

CREATE POLICY "cashback_payouts_user_access" ON cashback_payouts FOR SELECT 
USING (user_id = auth.uid());

CREATE POLICY "work_advisor_logs_user_access" ON work_advisor_logs FOR SELECT 
USING (user_id = auth.uid());

-- SERVICE ROLE POLICIES (Backend Access)
CREATE POLICY "users_service_access" ON users FOR ALL 
USING (auth.jwt() ->> 'role' = 'service_role');

CREATE POLICY "policies_service_access" ON policies FOR ALL 
USING (auth.jwt() ->> 'role' = 'service_role');

CREATE POLICY "claims_service_access" ON claims FOR ALL 
USING (auth.jwt() ->> 'role' = 'service_role');

CREATE POLICY "riders_service_access" ON riders FOR ALL 
USING (auth.jwt() ->> 'role' = 'service_role');

CREATE POLICY "wallet_transactions_service_access" ON wallet_transactions FOR ALL 
USING (auth.jwt() ->> 'role' = 'service_role');

CREATE POLICY "fraud_baselines_service_access" ON fraud_baselines FOR ALL 
USING (auth.jwt() ->> 'role' = 'service_role');

CREATE POLICY "fraud_flags_service_access" ON fraud_flags FOR ALL 
USING (auth.jwt() ->> 'role' = 'service_role');

CREATE POLICY "fraud_signal_logs_service_access" ON fraud_signal_logs FOR ALL 
USING (auth.jwt() ->> 'role' = 'service_role');

CREATE POLICY "shift_telemetry_service_access" ON shift_telemetry FOR ALL 
USING (auth.jwt() ->> 'role' = 'service_role');

CREATE POLICY "shift_gaps_service_access" ON shift_gaps FOR ALL 
USING (auth.jwt() ->> 'role' = 'service_role');

CREATE POLICY "shift_summary_service_access" ON shift_summary FOR ALL 
USING (auth.jwt() ->> 'role' = 'service_role');

CREATE POLICY "trust_events_service_access" ON trust_events FOR ALL 
USING (auth.jwt() ->> 'role' = 'service_role');

CREATE POLICY "notifications_service_access" ON notifications FOR ALL 
USING (auth.jwt() ->> 'role' = 'service_role');

CREATE POLICY "referrals_service_access" ON referrals FOR ALL 
USING (auth.jwt() ->> 'role' = 'service_role');

-- PUBLIC READ POLICIES (Non-sensitive data)
CREATE POLICY "risk_pools_public_read" ON risk_pools FOR SELECT USING (true);
CREATE POLICY "disruption_events_public_read" ON disruption_events FOR SELECT USING (true);
CREATE POLICY "pool_health_public_read" ON pool_health FOR SELECT USING (true);
CREATE POLICY "circuit_breakers_public_read" ON circuit_breakers FOR SELECT USING (true);
CREATE POLICY "weekly_settlements_public_read" ON weekly_settlements FOR SELECT USING (true);
CREATE POLICY "regional_intelligence_snapshots_public_read" ON regional_intelligence_snapshots FOR SELECT USING (true);

-- SERVICE ROLE POLICIES FOR PUBLIC TABLES
CREATE POLICY "risk_pools_service_access" ON risk_pools FOR ALL 
USING (auth.jwt() ->> 'role' = 'service_role');

CREATE POLICY "disruption_events_service_access" ON disruption_events FOR ALL 
USING (auth.jwt() ->> 'role' = 'service_role');

CREATE POLICY "pool_health_service_access" ON pool_health FOR ALL 
USING (auth.jwt() ->> 'role' = 'service_role');

CREATE POLICY "circuit_breakers_service_access" ON circuit_breakers FOR ALL 
USING (auth.jwt() ->> 'role' = 'service_role');

CREATE POLICY "weekly_settlements_service_access" ON weekly_settlements FOR ALL 
USING (auth.jwt() ->> 'role' = 'service_role');

CREATE POLICY "reinsurance_triggers_service_access" ON reinsurance_triggers FOR ALL 
USING (auth.jwt() ->> 'role' = 'service_role');

CREATE POLICY "shadow_policies_service_access" ON shadow_policies FOR ALL 
USING (auth.jwt() ->> 'role' = 'service_role');

CREATE POLICY "device_fingerprint_events_service_access" ON device_fingerprint_events FOR ALL 
USING (auth.jwt() ->> 'role' = 'service_role');

CREATE POLICY "pending_frs_adjustments_service_access" ON pending_frs_adjustments FOR ALL 
USING (auth.jwt() ->> 'role' = 'service_role');

-- ADMIN-ONLY POLICIES (Sensitive Operations)
CREATE POLICY "admin_actions_admin_only" ON admin_actions FOR ALL 
USING (auth.jwt() ->> 'role' = 'service_role');

CREATE POLICY "cron_execution_logs_admin_only" ON cron_execution_logs FOR ALL 
USING (auth.jwt() ->> 'role' = 'service_role');
