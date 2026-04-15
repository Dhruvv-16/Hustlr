-- ─────────────────────────────────────────────
-- HUSTLR — Production-Ready Schema
-- Guidewire DEVTrails 2026 — Phase 2 + 3
-- Run this in your Supabase SQL Editor (Settings → SQL Editor)
-- ─────────────────────────────────────────────

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";


-- ─────────────────────────────────────────────
-- USERS
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name                  TEXT NOT NULL,
  phone                 TEXT UNIQUE NOT NULL,
  zone                  TEXT NOT NULL,
  city                  TEXT NOT NULL,
  platform              TEXT NOT NULL DEFAULT 'Zepto',
  iss_score             INTEGER DEFAULT NULL,
  zone_depth_score      FLOAT DEFAULT NULL,
  shift_start           TIME DEFAULT '08:00',
  shift_end             TIME DEFAULT '22:00',
  days_active           INTEGER DEFAULT 0,
  onboarding_complete   BOOLEAN DEFAULT FALSE,
  fcm_token             TEXT DEFAULT NULL,
  created_at            TIMESTAMPTZ DEFAULT NOW(),
  updated_at            TIMESTAMPTZ DEFAULT NOW()
);

-- ─────────────────────────────────────────────
-- RISK POOLS
-- Separate pool per city + risk type
-- Delhi → AQI pool, Mumbai → Rain pool etc.
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS risk_pools (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  city              TEXT NOT NULL,
  risk_type         TEXT NOT NULL,
  pool_name         TEXT NOT NULL,
  total_premium     INTEGER DEFAULT 0,
  total_claims_paid INTEGER DEFAULT 0,
  reserve_fund      INTEGER DEFAULT 0,
  loss_ratio        FLOAT DEFAULT 0,
  active_policies   INTEGER DEFAULT 0,
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  updated_at        TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (city, risk_type)
);

-- Seed standard pools
INSERT INTO risk_pools (city, risk_type, pool_name) VALUES
  ('Chennai',   'rain',     'Chennai Rain Pool'),
  ('Chennai',   'aqi',      'Chennai AQI Pool'),
  ('Chennai',   'platform', 'Chennai Platform Pool'),
  ('Mumbai',    'rain',     'Mumbai Rain Pool'),
  ('Delhi',     'aqi',      'Delhi AQI Pool'),
  ('Bengaluru', 'platform', 'Bengaluru Platform Pool'),
  ('Hyderabad', 'rain',     'Hyderabad Rain Pool')
ON CONFLICT (city, risk_type) DO NOTHING;

-- ─────────────────────────────────────────────
-- POLICIES
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS policies (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  plan_tier         TEXT NOT NULL DEFAULT 'standard'
                    CHECK (plan_tier IN ('basic','standard','full','elite')),
  base_premium      INTEGER NOT NULL DEFAULT 49,
  zone_adjustment   INTEGER NOT NULL DEFAULT 0,
  iss_adjustment    INTEGER NOT NULL DEFAULT 0,
  weekly_premium    INTEGER NOT NULL DEFAULT 49,
  max_weekly_payout INTEGER NOT NULL DEFAULT 700,
  max_daily_payout  INTEGER NOT NULL DEFAULT 150,
  riders            TEXT[] DEFAULT '{}',
  status            TEXT NOT NULL DEFAULT 'active'
                    CHECK (status IN ('active','expired','cancelled')),
  coverage_start    DATE NOT NULL DEFAULT CURRENT_DATE,
  coverage_end      DATE NOT NULL DEFAULT CURRENT_DATE + INTERVAL '7 days',
  pool_id           UUID REFERENCES risk_pools(id),
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  updated_at        TIMESTAMPTZ DEFAULT NOW()
);

-- ─────────────────────────────────────────────
-- CLAIMS
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS claims (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  policy_id           UUID REFERENCES policies(id) ON DELETE SET NULL,
  trigger_type        TEXT NOT NULL,
  zone                TEXT NOT NULL,
  city                TEXT NOT NULL DEFAULT 'Chennai',
  severity            FLOAT NOT NULL DEFAULT 1.0
                      CHECK (severity >= 0 AND severity <= 1),
  duration_hours      FLOAT NOT NULL DEFAULT 3.0
                      CHECK (duration_hours > 0),
  gross_payout        INTEGER NOT NULL CHECK (gross_payout >= 0),
  tranche1            INTEGER NOT NULL CHECK (tranche1 >= 0),
  tranche2            INTEGER NOT NULL CHECK (tranche2 >= 0),
  fraud_score         INTEGER NOT NULL DEFAULT 0
                      CHECK (fraud_score >= 0 AND fraud_score <= 100),
  fraud_status        TEXT NOT NULL DEFAULT 'CLEAN'
                      CHECK (fraud_status IN ('CLEAN','REVIEW','FLAGGED','REJECTED')),
  fps_signals         JSONB DEFAULT '{}',
  zone_depth_score    FLOAT DEFAULT NULL,
  shift_verified      BOOLEAN DEFAULT TRUE,
  underwriting_passed BOOLEAN DEFAULT TRUE,
  status              TEXT NOT NULL DEFAULT 'PENDING'
                      CHECK (status IN ('PENDING','APPROVED','FLAGGED','REJECTED','SETTLED')),
  tranche1_released_at TIMESTAMPTZ DEFAULT NULL,
  tranche2_released_at TIMESTAMPTZ DEFAULT NULL,
  settled_at           TIMESTAMPTZ DEFAULT NULL,
  created_at           TIMESTAMPTZ DEFAULT NOW(),
  updated_at           TIMESTAMPTZ DEFAULT NOW()
);

-- ─────────────────────────────────────────────
-- WALLET TRANSACTIONS
-- No separate wallets table
-- Balance calculated from transaction sum
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS wallet_transactions (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  amount      INTEGER NOT NULL,
  type        TEXT NOT NULL CHECK (type IN ('credit','debit')),
  category    TEXT NOT NULL DEFAULT 'other'
              CHECK (category IN (
                'premium','payout_tranche1','payout_tranche2',
                'cashback','withdrawal','refund','other'
              )),
  reference   TEXT,
  description TEXT,
  claim_id    UUID REFERENCES claims(id) ON DELETE SET NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ─────────────────────────────────────────────
-- DISRUPTION EVENTS
-- Logged when real API triggers fire
-- Also used for shadow policy calculations
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS disruption_events (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  zone          TEXT NOT NULL,
  city          TEXT NOT NULL DEFAULT 'Chennai',
  trigger_type  TEXT NOT NULL,
  severity      FLOAT NOT NULL DEFAULT 1.0,
  rainfall_mm   FLOAT DEFAULT 0,
  temperature_c FLOAT DEFAULT 0,
  aqi           INTEGER DEFAULT 0,
  data_source   TEXT DEFAULT 'live',
  started_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ended_at      TIMESTAMPTZ DEFAULT NULL,
  duration_hrs  FLOAT DEFAULT NULL,
  payout_triggered BOOLEAN DEFAULT FALSE,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ─────────────────────────────────────────────
-- SHADOW POLICIES
-- Tracks what uninsured workers would have received
-- Used for the "You missed ₹680" conversion nudge
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS shadow_policies (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  week_start          DATE NOT NULL,
  simulated_payout    INTEGER NOT NULL DEFAULT 0,
  disruption_events   JSONB DEFAULT '[]',
  nudge_sent          BOOLEAN DEFAULT FALSE,
  nudge_sent_at       TIMESTAMPTZ DEFAULT NULL,
  created_at          TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (user_id, week_start)
);

-- ─────────────────────────────────────────────
-- FRAUD BASELINES
-- Built over first 2 weeks of worker activity
-- Used by fraud detection engine
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS fraud_baselines (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  avg_daily_deliveries  FLOAT DEFAULT 0,
  typical_zones         TEXT[] DEFAULT '{}',
  avg_shift_start_hour  INTEGER DEFAULT 8,
  avg_shift_end_hour    INTEGER DEFAULT 22,
  home_wifi_ssids       TEXT[] DEFAULT '{}',
  typical_cell_towers   TEXT[] DEFAULT '{}',
  weeks_active          INTEGER DEFAULT 0,
  claim_count_30d       INTEGER DEFAULT 0,
  last_updated          TIMESTAMPTZ DEFAULT NOW()
);

-- ─────────────────────────────────────────────
-- WEEKLY SETTLEMENTS
-- Records each Sunday night settlement run
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS weekly_settlements (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  week_start            DATE NOT NULL,
  week_end              DATE NOT NULL,
  city                  TEXT NOT NULL,
  risk_type             TEXT NOT NULL,
  total_premium         INTEGER NOT NULL DEFAULT 0,
  total_claims_paid     INTEGER NOT NULL DEFAULT 0,
  loss_ratio            FLOAT NOT NULL DEFAULT 0,
  policies_count        INTEGER NOT NULL DEFAULT 0,
  claims_count          INTEGER NOT NULL DEFAULT 0,
  reserve_contribution  INTEGER NOT NULL DEFAULT 0,
  reinsurance_triggered BOOLEAN DEFAULT FALSE,
  settled_at            TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (week_start, city, risk_type)
);

-- ─────────────────────────────────────────────
-- INDEXES — for query performance
-- ─────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_users_phone
  ON users(phone);

CREATE INDEX IF NOT EXISTS idx_users_zone
  ON users(zone);

CREATE INDEX IF NOT EXISTS idx_policies_user_id
  ON policies(user_id);

CREATE INDEX IF NOT EXISTS idx_policies_status
  ON policies(status);

CREATE INDEX IF NOT EXISTS idx_claims_user_id
  ON claims(user_id);

CREATE INDEX IF NOT EXISTS idx_claims_status
  ON claims(status);

CREATE INDEX IF NOT EXISTS idx_claims_created_at
  ON claims(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_wallet_user_id
  ON wallet_transactions(user_id);

CREATE INDEX IF NOT EXISTS idx_wallet_created_at
  ON wallet_transactions(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_disruptions_zone
  ON disruption_events(zone);

CREATE INDEX IF NOT EXISTS idx_disruptions_started_at
  ON disruption_events(started_at DESC);

CREATE INDEX IF NOT EXISTS idx_shadow_user_id
  ON shadow_policies(user_id);

-- ─────────────────────────────────────────────
-- ROW LEVEL SECURITY
-- ─────────────────────────────────────────────
ALTER TABLE users               ENABLE ROW LEVEL SECURITY;
ALTER TABLE risk_pools          ENABLE ROW LEVEL SECURITY;
ALTER TABLE policies            ENABLE ROW LEVEL SECURITY;
ALTER TABLE claims              ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallet_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE disruption_events   ENABLE ROW LEVEL SECURITY;
ALTER TABLE shadow_policies     ENABLE ROW LEVEL SECURITY;
ALTER TABLE fraud_baselines     ENABLE ROW LEVEL SECURITY;
ALTER TABLE weekly_settlements  ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "allow_all" ON users;
DROP POLICY IF EXISTS "allow_all" ON risk_pools;
DROP POLICY IF EXISTS "allow_all" ON policies;
DROP POLICY IF EXISTS "allow_all" ON claims;
DROP POLICY IF EXISTS "allow_all" ON wallet_transactions;
DROP POLICY IF EXISTS "allow_all" ON disruption_events;
DROP POLICY IF EXISTS "allow_all" ON shadow_policies;
DROP POLICY IF EXISTS "allow_all" ON fraud_baselines;
DROP POLICY IF EXISTS "allow_all" ON weekly_settlements;

CREATE POLICY "allow_all" ON users               FOR ALL USING (true);
CREATE POLICY "allow_all" ON risk_pools          FOR ALL USING (true);
CREATE POLICY "allow_all" ON policies            FOR ALL USING (true);
CREATE POLICY "allow_all" ON claims              FOR ALL USING (true);
CREATE POLICY "allow_all" ON wallet_transactions FOR ALL USING (true);
CREATE POLICY "allow_all" ON disruption_events   FOR ALL USING (true);
CREATE POLICY "allow_all" ON shadow_policies     FOR ALL USING (true);
CREATE POLICY "allow_all" ON fraud_baselines     FOR ALL USING (true);
CREATE POLICY "allow_all" ON weekly_settlements  FOR ALL USING (true);

-- ─────────────────────────────────────────────
-- VERIFY (Phase 2)
-- ─────────────────────────────────────────────
SELECT table_name,
       (SELECT count(*)
        FROM information_schema.columns
        WHERE table_name = t.table_name
        AND table_schema = 'public') AS column_count
FROM information_schema.tables t
WHERE table_schema = 'public'
ORDER BY table_name;


-- ═════════════════════════════════════════════
-- PHASE 3 — Forward-Looking Additions
-- Run after Phase 2 schema is live
-- ═════════════════════════════════════════════

-- ─────────────────────────────────────────────
-- PHASE 3: ALTER EXISTING TABLES
-- Safe to run — all new columns are nullable
-- or have defaults, so no backfill needed
-- ─────────────────────────────────────────────

-- Users: referral system + KYC gating
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS referral_code   TEXT UNIQUE DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS referred_by     UUID REFERENCES users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS kyc_status      TEXT NOT NULL DEFAULT 'pending'
                                           CHECK (kyc_status IN ('pending','submitted','verified','rejected')),
  ADD COLUMN IF NOT EXISTS kyc_verified_at TIMESTAMPTZ DEFAULT NULL;

-- Policies: auto-renewal flag
ALTER TABLE policies
  ADD COLUMN IF NOT EXISTS auto_renew BOOLEAN NOT NULL DEFAULT TRUE;

-- Claims: link to appeal if one is filed
ALTER TABLE claims
  ADD COLUMN IF NOT EXISTS appeal_id UUID DEFAULT NULL;

-- Wallet: UPI/Instamojo payout reference
ALTER TABLE wallet_transactions
  ADD COLUMN IF NOT EXISTS upi_ref TEXT DEFAULT NULL;

-- ─────────────────────────────────────────────
-- PHASE 3: NEW TABLES
-- ─────────────────────────────────────────────

-- NOTIFICATIONS
-- Persistent inbox — supplements FCM fire-and-forget
CREATE TABLE IF NOT EXISTS notifications (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title       TEXT NOT NULL,
  body        TEXT NOT NULL,
  type        TEXT NOT NULL DEFAULT 'general'
              CHECK (type IN (
                'payout_credited','claim_update','policy_renewal',
                'shadow_nudge','fraud_alert','kyc_update','general'
              )),
  read        BOOLEAN NOT NULL DEFAULT FALSE,
  action_url  TEXT DEFAULT NULL,
  metadata    JSONB DEFAULT '{}',
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- REFERRALS
-- Track who referred whom + reward state
CREATE TABLE IF NOT EXISTS referrals (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  referrer_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  referred_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reward_amount   INTEGER NOT NULL DEFAULT 50,
  reward_status   TEXT NOT NULL DEFAULT 'pending'
                  CHECK (reward_status IN ('pending','paid','expired')),
  reward_paid_at  TIMESTAMPTZ DEFAULT NULL,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (referrer_id, referred_id)
);

-- REINSURANCE TRIGGERS
-- Detailed log whenever a weekly settlement trips reinsurance
CREATE TABLE IF NOT EXISTS reinsurance_triggers (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  settlement_id     UUID NOT NULL REFERENCES weekly_settlements(id) ON DELETE CASCADE,
  city              TEXT NOT NULL,
  risk_type         TEXT NOT NULL,
  loss_ratio        FLOAT NOT NULL,
  excess_claims     INTEGER NOT NULL DEFAULT 0,
  reinsurer_name    TEXT DEFAULT 'Munich Re',
  amount_recovered  INTEGER DEFAULT 0,
  status            TEXT NOT NULL DEFAULT 'filed'
                    CHECK (status IN ('filed','processing','settled','rejected')),
  filed_at          TIMESTAMPTZ DEFAULT NOW(),
  settled_at        TIMESTAMPTZ DEFAULT NULL
);

-- ADMIN ACTIONS
-- Audit log for every manual action taken in the admin dashboard
CREATE TABLE IF NOT EXISTS admin_actions (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id    TEXT NOT NULL,
  action_type TEXT NOT NULL
              CHECK (action_type IN (
                'approve_claim','reject_claim','flag_claim',
                'adjust_pool','override_fraud','kyc_verify',
                'manual_payout','other'
              )),
  target_type TEXT NOT NULL,
  target_id   UUID NOT NULL,
  reason      TEXT DEFAULT NULL,
  metadata    JSONB DEFAULT '{}',
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- APPEAL REQUESTS
-- Worker appeals for REJECTED or FLAGGED claims
CREATE TABLE IF NOT EXISTS appeal_requests (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  claim_id      UUID NOT NULL REFERENCES claims(id) ON DELETE CASCADE,
  reason        TEXT NOT NULL,
  evidence_urls TEXT[] DEFAULT '{}',
  status        TEXT NOT NULL DEFAULT 'open'
                CHECK (status IN ('open','under_review','approved','rejected')),
  reviewed_by   TEXT DEFAULT NULL,
  review_note   TEXT DEFAULT NULL,
  opened_at     TIMESTAMPTZ DEFAULT NOW(),
  resolved_at   TIMESTAMPTZ DEFAULT NULL,
  UNIQUE (claim_id)
);

-- Back-fill: link claims → appeal_requests foreign key now that table exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'fk_claims_appeal'
    AND   table_name      = 'claims'
  ) THEN
    ALTER TABLE claims
      ADD CONSTRAINT fk_claims_appeal
      FOREIGN KEY (appeal_id) REFERENCES appeal_requests(id) ON DELETE SET NULL
      NOT VALID;
  END IF;
END $$;

-- ─────────────────────────────────────────────
-- PHASE 3: INDEXES
-- ─────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_notifications_user_id
  ON notifications(user_id);

CREATE INDEX IF NOT EXISTS idx_notifications_read
  ON notifications(user_id, read);

CREATE INDEX IF NOT EXISTS idx_referrals_referrer
  ON referrals(referrer_id);

CREATE INDEX IF NOT EXISTS idx_referrals_referred
  ON referrals(referred_id);

CREATE INDEX IF NOT EXISTS idx_appeals_claim_id
  ON appeal_requests(claim_id);

CREATE INDEX IF NOT EXISTS idx_admin_actions_target
  ON admin_actions(target_id);

CREATE UNIQUE INDEX IF NOT EXISTS idx_users_referral_code
  ON users(referral_code)
  WHERE referral_code IS NOT NULL;

-- ─────────────────────────────────────────────
-- PHASE 3: ROW LEVEL SECURITY
-- ─────────────────────────────────────────────
ALTER TABLE notifications       ENABLE ROW LEVEL SECURITY;
ALTER TABLE referrals           ENABLE ROW LEVEL SECURITY;
ALTER TABLE reinsurance_triggers ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_actions       ENABLE ROW LEVEL SECURITY;
ALTER TABLE appeal_requests     ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "allow_all" ON notifications;
DROP POLICY IF EXISTS "allow_all" ON referrals;
DROP POLICY IF EXISTS "allow_all" ON reinsurance_triggers;
DROP POLICY IF EXISTS "allow_all" ON admin_actions;
DROP POLICY IF EXISTS "allow_all" ON appeal_requests;

CREATE POLICY "allow_all" ON notifications        FOR ALL USING (true);
CREATE POLICY "allow_all" ON referrals            FOR ALL USING (true);
CREATE POLICY "allow_all" ON reinsurance_triggers FOR ALL USING (true);
CREATE POLICY "allow_all" ON admin_actions        FOR ALL USING (true);
CREATE POLICY "allow_all" ON appeal_requests      FOR ALL USING (true);

-- ─────────────────────────────────────────────
-- VERIFY (Phase 3 — final)
-- ─────────────────────────────────────────────
SELECT table_name,
       (SELECT count(*)
        FROM information_schema.columns
        WHERE table_name = t.table_name
        AND table_schema = 'public') AS column_count
FROM information_schema.tables t
WHERE table_schema = 'public'
ORDER BY table_name;


-- ═════════════════════════════════════════════
-- PHASE 4 — Circuit Breaker & Pool Health
-- ═════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS circuit_breakers (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  zone          TEXT NOT NULL,
  city          TEXT NOT NULL,
  trigger_type  TEXT NOT NULL,
  claims_count  INTEGER DEFAULT 0,
  hourly_limit  INTEGER DEFAULT 50,
  daily_limit   INTEGER DEFAULT 500,
  tripped       BOOLEAN DEFAULT FALSE,
  tripped_at    TIMESTAMPTZ DEFAULT NULL,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(zone, trigger_type)
);

CREATE TABLE IF NOT EXISTS pool_health (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  week_start          DATE NOT NULL,
  city                TEXT NOT NULL,
  premiums_collected  INTEGER DEFAULT 0,
  claims_paid         INTEGER DEFAULT 0,
  burning_cost_rate   FLOAT DEFAULT 0,
  enrollment_stopped  BOOLEAN DEFAULT FALSE,
  created_at          TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE claims 
  ADD COLUMN IF NOT EXISTS payout_attempts  INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS payout_error     TEXT DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS payout_failed_at TIMESTAMPTZ DEFAULT NULL;

