-- ============================================================
-- HUSTLR — Production-Ready Schema with Secure Auth
-- Guidewire DEVTrails 2026 — Phase 2 + 3
-- Run this in your Supabase SQL Editor (Settings → SQL Editor)
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- ============================================================
-- CORE TABLES
-- ============================================================

-- USERS
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

-- RISK POOLS
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

-- POLICIES
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

-- CLAIMS
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

-- WALLET TRANSACTIONS
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

-- DISRUPTION EVENTS
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

-- ============================================================
-- PHASE 3 EXTENSIONS
-- ============================================================

-- NOTIFICATIONS
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

-- CIRCUIT BREAKERS
CREATE TABLE IF NOT EXISTS circuit_breakers (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  zone          TEXT NOT NULL,
  city          TEXT NOT NULL DEFAULT 'Chennai',
  trigger_type  TEXT NOT NULL,
  claims_count  INTEGER DEFAULT 0,
  hourly_limit  INTEGER DEFAULT 50,
  daily_limit   INTEGER DEFAULT 500,
  tripped       BOOLEAN DEFAULT FALSE,
  tripped_at    TIMESTAMPTZ DEFAULT NULL,
  reset_at      TIMESTAMPTZ DEFAULT NULL,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(zone, trigger_type)
);

-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
CREATE INDEX IF NOT EXISTS idx_users_zone ON users(zone);
CREATE INDEX IF NOT EXISTS idx_policies_user_id ON policies(user_id);
CREATE INDEX IF NOT EXISTS idx_policies_status ON policies(status);
CREATE INDEX IF NOT EXISTS idx_claims_user_id ON claims(user_id);
CREATE INDEX IF NOT EXISTS idx_claims_status ON claims(status);
CREATE INDEX IF NOT EXISTS idx_claims_created_at ON claims(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_wallet_user_id ON wallet_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_wallet_created_at ON wallet_transactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_disruptions_zone ON disruption_events(zone);
CREATE INDEX IF NOT EXISTS idx_disruptions_started_at ON disruption_events(started_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(user_id, read);

-- ============================================================
-- SEED DATA
-- ============================================================

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

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

-- Enable RLS on all tables
ALTER TABLE users               ENABLE ROW LEVEL SECURITY;
ALTER TABLE risk_pools          ENABLE ROW LEVEL SECURITY;
ALTER TABLE policies            ENABLE ROW LEVEL SECURITY;
ALTER TABLE claims              ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallet_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE disruption_events   ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications       ENABLE ROW LEVEL SECURITY;
ALTER TABLE referrals           ENABLE ROW LEVEL SECURITY;
ALTER TABLE circuit_breakers    ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- SECURE AUTHENTICATION POLICIES
-- ============================================================

-- 1. SECURE USER ACCESS (Users can only access their own data)
CREATE POLICY "users_read_own" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "users_update_own" ON users
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "users_insert_own" ON users
  FOR INSERT WITH CHECK (auth.uid() = id);

-- 2. SECURE POLICY ACCESS
CREATE POLICY "policies_read_own" ON policies
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "policies_update_own" ON policies
  FOR UPDATE USING (user_id = auth.uid());

-- 3. SECURE CLAIMS ACCESS
CREATE POLICY "claims_read_own" ON claims
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "claims_update_own" ON claims
  FOR UPDATE USING (user_id = auth.uid());

-- 4. SECURE WALLET ACCESS
CREATE POLICY "wallet_read_own" ON wallet_transactions
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "wallet_insert_own" ON wallet_transactions
  FOR INSERT WITH CHECK (user_id = auth.uid());

-- 5. KEEP DISRUPTION EVENTS PUBLIC (OK for public visibility)
CREATE POLICY "disruptions_public" ON disruption_events
  FOR SELECT USING (true);

-- 6. SECURE NOTIFICATIONS ACCESS
CREATE POLICY "notifications_read_own" ON notifications
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "notifications_insert_own" ON notifications
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "notifications_update_own" ON notifications
  FOR UPDATE USING (user_id = auth.uid());

-- 7. SECURE REFERRALS ACCESS
CREATE POLICY "referrals_read_own" ON referrals
  FOR SELECT USING (referrer_id = auth.uid() OR referred_id = auth.uid());

-- 8. SERVICE ROLE ACCESS (for backend APIs)
CREATE POLICY "service_access_users" ON users
  FOR ALL USING (
    auth.jwt() ->> 'role' = 'service' OR 
    auth.uid() = id
  );

CREATE POLICY "service_access_policies" ON policies
  FOR ALL USING (
    auth.jwt() ->> 'role' = 'service' OR 
    user_id = auth.uid()
  );

CREATE POLICY "service_access_claims" ON claims
  FOR ALL USING (
    auth.jwt() ->> 'role' = 'service' OR 
    user_id = auth.uid()
  );

CREATE POLICY "service_access_wallet" ON wallet_transactions
  FOR ALL USING (
    auth.jwt() ->> 'role' = 'service' OR 
    user_id = auth.uid()
  );

-- 9. PUBLIC ACCESS WHERE APPROPRIATE
CREATE POLICY "risk_pools_public" ON risk_pools
  FOR SELECT USING (true);

CREATE POLICY "circuit_breakers_public" ON circuit_breakers
  FOR SELECT USING (true);

-- ============================================================
-- TRIGGERS
-- ============================================================

-- Auto update updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER policies_updated_at
  BEFORE UPDATE ON policies
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- VERIFICATION
-- ============================================================

-- Check tables were created
SELECT table_name,
       (SELECT count(*)
        FROM information_schema.columns
        WHERE table_name = t.table_name
        AND table_schema = 'public') AS column_count
FROM information_schema.tables t
WHERE table_schema = 'public'
  AND table_name IN ('users','policies','claims','wallet_transactions','disruption_events','notifications','referrals','risk_pools','circuit_breakers')
ORDER BY table_name;

-- Check secure policies are active
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies 
WHERE schemaname = 'public'
  AND policyname NOT LIKE '%allow_all%'
ORDER BY tablename, policyname;
