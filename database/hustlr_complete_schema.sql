-- ============================================================
-- HUSTLR — Complete Production Schema (1100+ lines)
-- Guidewire DEVTrails 2026 — Phase 2 + 3 + 4 + Complete Features
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
  referral_code         TEXT UNIQUE DEFAULT NULL,
  referred_by           UUID REFERENCES users(id) ON DELETE SET NULL,
  kyc_status           TEXT NOT NULL DEFAULT 'pending'
                        CHECK (kyc_status IN ('pending','submitted','verified','rejected')),
  kyc_verified_at       TIMESTAMPTZ DEFAULT NULL,
  trust_score           INTEGER DEFAULT 100,
  trust_tier            TEXT DEFAULT 'SILVER',
  clean_weeks           INTEGER DEFAULT 0,
  cashback_earned        INTEGER DEFAULT 0,
  cashback_pending       INTEGER DEFAULT 0,
  last_seen_at          TIMESTAMPTZ DEFAULT NULL,
  paused_at             TIMESTAMPTZ DEFAULT NULL,
  shift_status          TEXT DEFAULT 'OFFLINE',
  created_at            TIMESTAMPTZ DEFAULT NOW(),
  updated_at            TIMESTAMPTZ DEFAULT NOW()
);

-- RISK POOLS
CREATE TABLE IF NOT EXISTS risk_pools (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  city              TEXT NOT NULL,
  risk_type         TEXT NOT NULL,
  pool_name         TEXT NOT NULL,
  total_premium     FLOAT DEFAULT 0,
  total_claims_paid FLOAT DEFAULT 0,
  loss_ratio        FLOAT DEFAULT 0,
  reserve_fund      INTEGER DEFAULT 0,
  active_policies   INTEGER DEFAULT 0,
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
  auto_renew        BOOLEAN NOT NULL DEFAULT TRUE,
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
  appeal_id           UUID DEFAULT NULL,
  payout_attempts      INTEGER DEFAULT 0,
  payout_error         TEXT DEFAULT NULL,
  payout_failed_at    TIMESTAMPTZ DEFAULT NULL,
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
  upi_ref     TEXT DEFAULT NULL,
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

-- SHADOW POLICIES
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

-- FRAUD BASELINES
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

-- WEEKLY SETTLEMENTS
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

-- REINSURANCE TRIGGERS
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
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_name = 'claims'
      AND constraint_name = 'fk_claims_appeal'
  ) THEN
    ALTER TABLE claims
      ADD CONSTRAINT fk_claims_appeal
      FOREIGN KEY (appeal_id) REFERENCES appeal_requests(id) ON DELETE SET NULL;
  END IF;
END $$;

-- ============================================================
-- PHASE 4 EXTENSIONS
-- ============================================================

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
  reason        TEXT DEFAULT NULL,
  bcr_at_trip   FLOAT DEFAULT 0,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(zone, trigger_type)
);

-- POOL HEALTH
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

-- DEVICE FINGERPRINT EVENTS
CREATE TABLE IF NOT EXISTS device_fingerprint_events (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id            UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  fingerprint_hash   TEXT NOT NULL,
  zone               TEXT,
  created_at         TIMESTAMPTZ DEFAULT NOW()
);

-- SHIFT TELEMETRY
CREATE TABLE IF NOT EXISTS shift_telemetry (
  id                  UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  worker_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  lat                 FLOAT8 NOT NULL,
  lng                 FLOAT8 NOT NULL,
  accuracy            FLOAT4,
  timestamp           TIMESTAMPTZ NOT NULL,
  is_mock_location    BOOLEAN DEFAULT FALSE,
  activity_type       TEXT,
  battery_level       FLOAT4,
  signal_strength     INT,
  is_low_confidence   BOOLEAN DEFAULT FALSE,
  created_at          TIMESTAMPTZ DEFAULT NOW()
);

-- SHIFT GAPS
CREATE TABLE IF NOT EXISTS shift_gaps (
  id                    UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  worker_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  gap_start             TIMESTAMPTZ NOT NULL,
  gap_end               TIMESTAMPTZ,
  gap_duration_seconds  INT,
  frs_penalty           INT DEFAULT 0,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

-- FRAUD FLAGS
CREATE TABLE IF NOT EXISTS fraud_flags (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  worker_id   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  claim_id    UUID,
  reason      TEXT NOT NULL,
  frs_score   INT NOT NULL DEFAULT 0,
  timestamp   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  resolved    BOOLEAN DEFAULT FALSE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- PENDING FRS ADJUSTMENTS
CREATE TABLE IF NOT EXISTS pending_frs_adjustments (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  worker_id   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  adjustment  INT NOT NULL,
  reason      TEXT NOT NULL,
  is_consumed BOOLEAN DEFAULT FALSE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- TRUST EVENTS
CREATE TABLE IF NOT EXISTS trust_events (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        UUID REFERENCES users(id) ON DELETE CASCADE,
  event_type     TEXT NOT NULL,
  score_change   INTEGER NOT NULL,
  new_score      INTEGER NOT NULL,
  reason         TEXT,
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- H3 GEOSPATIAL FEATURES
-- ============================================================

-- ZONES H3
CREATE TABLE IF NOT EXISTS zones_h3 (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  zone_id TEXT UNIQUE NOT NULL,
  zone_name TEXT NOT NULL,
  city TEXT NOT NULL,
  h3_center VARCHAR(16) NOT NULL,
  h3_resolution INT DEFAULT 8,
  h3_hexes TEXT[] DEFAULT '{}',
  center_lat FLOAT NOT NULL,
  center_lng FLOAT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add H3 columns to existing tables
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS h3_location VARCHAR(16) DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS h3_resolution INT DEFAULT 8;

ALTER TABLE claims
  ADD COLUMN IF NOT EXISTS h3_location VARCHAR(16) DEFAULT NULL;

ALTER TABLE disruption_events
  ADD COLUMN IF NOT EXISTS h3_center VARCHAR(16) DEFAULT NULL;

-- ============================================================
-- REGIONAL INTELLIGENCE
-- ============================================================

CREATE TABLE IF NOT EXISTS regional_intelligence_snapshots (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  week_start   DATE NOT NULL,
  city         TEXT NOT NULL,
  risk_score   FLOAT NOT NULL DEFAULT 0.5,
  rain_exposure FLOAT NOT NULL DEFAULT 0,
  aqi_stress   FLOAT NOT NULL DEFAULT 0,
  platform_risk FLOAT NOT NULL DEFAULT 0,
  summary      TEXT,
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (week_start, city)
);

-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
CREATE INDEX IF NOT EXISTS idx_users_zone ON users(zone);
CREATE INDEX IF NOT EXISTS idx_users_h3_location ON users(h3_location);
CREATE INDEX IF NOT EXISTS idx_users_referral_code ON users(referral_code) WHERE referral_code IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_policies_user_id ON policies(user_id);
CREATE INDEX IF NOT EXISTS idx_policies_status ON policies(status);

CREATE INDEX IF NOT EXISTS idx_claims_user_id ON claims(user_id);
CREATE INDEX IF NOT EXISTS idx_claims_status ON claims(status);
CREATE INDEX IF NOT EXISTS idx_claims_created_at ON claims(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_claims_h3_location ON claims(h3_location);

CREATE INDEX IF NOT EXISTS idx_wallet_user_id ON wallet_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_wallet_created_at ON wallet_transactions(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_disruptions_zone ON disruption_events(zone);
CREATE INDEX IF NOT EXISTS idx_disruptions_started_at ON disruption_events(started_at DESC);
CREATE INDEX IF NOT EXISTS idx_disruptions_h3_center ON disruption_events(h3_center);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(user_id, read);

CREATE INDEX IF NOT EXISTS idx_referrals_referrer ON referrals(referrer_id);
CREATE INDEX IF NOT EXISTS idx_referrals_referred ON referrals(referred_id);

CREATE INDEX IF NOT EXISTS idx_shift_telemetry_worker_ts ON shift_telemetry(worker_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_shift_gaps_worker_date ON shift_gaps(worker_id, gap_start DESC);
CREATE INDEX IF NOT EXISTS idx_fraud_flags_worker ON fraud_flags(worker_id, timestamp DESC);

CREATE INDEX IF NOT EXISTS idx_dfe_hash_created ON device_fingerprint_events(fingerprint_hash, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_dfe_zone_created ON device_fingerprint_events(zone, created_at DESC) WHERE zone IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_zones_h3_center ON zones_h3(h3_center);
CREATE INDEX IF NOT EXISTS idx_zones_h3_city ON zones_h3(city);

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

-- Seed H3 zones for Chennai
INSERT INTO zones_h3 (zone_id, zone_name, city, h3_center, h3_resolution, center_lat, center_lng)
VALUES
  ('adyar', 'Adyar Dark Store Zone', 'Chennai', '8834e2a2a9fffff', 8, 13.0112, 80.2356),
  ('anna_nagar', 'Anna Nagar Dark Store Zone', 'Chennai', '8834e2a3c7fffff', 8, 13.0857, 80.2158),
  ('t_nagar', 'T Nagar Dark Store Zone', 'Chennai', '8834e2a2affffff', 8, 13.0417, 80.2353),
  ('velachery', 'Velachery Dark Store Zone', 'Chennai', '8834e2a287fffff', 8, 12.9817, 80.2182),
  ('korattur', 'Korattur Dark Store Zone', 'Chennai', '8834e2a4efffff', 8, 13.1379, 80.1850),
  ('tambaram', 'Tambaram Dark Store Zone', 'Chennai', '8834e2a197fffff', 8, 12.9249, 80.1502),
  ('porur', 'Porur Dark Store Zone', 'Chennai', '8834e2a2c7fffff', 8, 13.0347, 80.1625),
  ('chromepet', 'Chromepet Dark Store Zone', 'Chennai', '8834e2a1c7fffff', 8, 12.9504, 80.1399),
  ('sholinganallur', 'Sholinganallur Dark Store Zone', 'Chennai', '8834e2a267fffff', 8, 12.8944, 80.2235),
  ('guindy', 'Guindy Dark Store Zone', 'Chennai', '8834e2a2a7fffff', 8, 13.0107, 80.2128),
  ('perambur', 'Perambur Dark Store Zone', 'Chennai', '8834e2a5efffff', 8, 13.1167, 80.2333),
  ('royapettah', 'Royapettah Dark Store Zone', 'Chennai', '8834e2a2b7fffff', 8, 13.0567, 80.2708),
  ('mylapore', 'Mylapore Dark Store Zone', 'Chennai', '8834e2a2d7fffff', 8, 13.0333, 80.2667),
  ('triplicane', 'Triplicane Dark Store Zone', 'Chennai', '8834e2a2bfffff', 8, 13.0475, 80.2833),
  ('nungambakkam', 'Nungambakkam Dark Store Zone', 'Chennai', '8834e2a327fffff', 8, 13.0667, 80.2333)
ON CONFLICT (zone_id) DO NOTHING;

-- Seed H3 zones for Mumbai
INSERT INTO zones_h3 (zone_id, zone_name, city, h3_center, h3_resolution, center_lat, center_lng)
VALUES
  ('andheri', 'Andheri Dark Store Zone', 'Mumbai', '8834e6a2a7fffff', 8, 19.1196, 72.8466),
  ('bandra', 'Bandra Dark Store Zone', 'Mumbai', '8834e6a2c7fffff', 8, 19.0596, 72.8296),
  ('powai', 'Powai Dark Store Zone', 'Mumbai', '8834e6a327fffff', 8, 19.1196, 72.9086)
ON CONFLICT (zone_id) DO NOTHING;

-- Seed H3 zones for Bengaluru
INSERT INTO zones_h3 (zone_id, zone_name, city, h3_center, h3_resolution, center_lat, center_lng)
VALUES
  ('koramangala', 'Koramangala Dark Store Zone', 'Bengaluru', '8834e12a2a7fffff', 8, 12.9352, 77.6245),
  ('electronic_city', 'Electronic City Dark Store Zone', 'Bengaluru', '8834e12a1c7fffff', 8, 12.8440, 77.6757),
  ('indiranagar', 'Indiranagar Dark Store Zone', 'Bengaluru', '8834e12a2c7fffff', 8, 12.9740, 77.6408)
ON CONFLICT (zone_id) DO NOTHING;

-- Seed H3 zones for Delhi
INSERT INTO zones_h3 (zone_id, zone_name, city, h3_center, h3_resolution, center_lat, center_lng)
VALUES
  ('connaught_place', 'Connaught Place Dark Store Zone', 'Delhi', '8834e0a2a7fffff', 8, 28.6315, 77.2167),
  ('saket', 'Saket Dark Store Zone', 'Delhi', '8834e0a2a7fffff', 8, 28.5245, 77.2067),
  ('dwarka', 'Dwarka Dark Store Zone', 'Delhi', '8834e0a197fffff', 8, 28.5815, 77.0697)
ON CONFLICT (zone_id) DO NOTHING;

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

-- Enable RLS on all tables
ALTER TABLE users                         ENABLE ROW LEVEL SECURITY;
ALTER TABLE risk_pools                    ENABLE ROW LEVEL SECURITY;
ALTER TABLE policies                      ENABLE ROW LEVEL SECURITY;
ALTER TABLE claims                        ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallet_transactions             ENABLE ROW LEVEL SECURITY;
ALTER TABLE disruption_events              ENABLE ROW LEVEL SECURITY;
ALTER TABLE shadow_policies                ENABLE ROW LEVEL SECURITY;
ALTER TABLE fraud_baselines                ENABLE ROW LEVEL SECURITY;
ALTER TABLE weekly_settlements             ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE referrals                      ENABLE ROW LEVEL SECURITY;
ALTER TABLE reinsurance_triggers            ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_actions                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE appeal_requests                ENABLE ROW LEVEL SECURITY;
ALTER TABLE circuit_breakers               ENABLE ROW LEVEL SECURITY;
ALTER TABLE pool_health                    ENABLE ROW LEVEL SECURITY;
ALTER TABLE device_fingerprint_events       ENABLE ROW LEVEL SECURITY;
ALTER TABLE shift_telemetry                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE shift_gaps                     ENABLE ROW LEVEL SECURITY;
ALTER TABLE fraud_flags                    ENABLE ROW LEVEL SECURITY;
ALTER TABLE pending_frs_adjustments         ENABLE ROW LEVEL SECURITY;
ALTER TABLE trust_events                    ENABLE ROW LEVEL SECURITY;
ALTER TABLE zones_h3                       ENABLE ROW LEVEL SECURITY;
ALTER TABLE regional_intelligence_snapshots   ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- SECURE AUTHENTICATION POLICIES
-- ============================================================
DROP POLICY IF EXISTS "users_read_own" ON users;
DROP POLICY IF EXISTS "users_update_own" ON users;
DROP POLICY IF EXISTS "users_insert_own" ON users;
DROP POLICY IF EXISTS "policies_read_own" ON policies;
DROP POLICY IF EXISTS "policies_update_own" ON policies;
DROP POLICY IF EXISTS "claims_read_own" ON claims;
DROP POLICY IF EXISTS "claims_update_own" ON claims;
DROP POLICY IF EXISTS "wallet_read_own" ON wallet_transactions;
DROP POLICY IF EXISTS "wallet_insert_own" ON wallet_transactions;
DROP POLICY IF EXISTS "disruptions_public" ON disruption_events;
DROP POLICY IF EXISTS "risk_pools_public" ON risk_pools;
DROP POLICY IF EXISTS "zones_h3_public" ON zones_h3;
DROP POLICY IF EXISTS "circuit_breakers_public" ON circuit_breakers;
DROP POLICY IF EXISTS "notifications_read_own" ON notifications;
DROP POLICY IF EXISTS "notifications_insert_own" ON notifications;
DROP POLICY IF EXISTS "notifications_update_own" ON notifications;
DROP POLICY IF EXISTS "referrals_read_own" ON referrals;
DROP POLICY IF EXISTS "shift_telemetry_insert_own" ON shift_telemetry;
DROP POLICY IF EXISTS "shift_telemetry_read_own" ON shift_telemetry;
DROP POLICY IF EXISTS "shift_gaps_read_own" ON shift_gaps;
DROP POLICY IF EXISTS "fraud_flags_read_own" ON fraud_flags;
DROP POLICY IF EXISTS "service_access_users" ON users;
DROP POLICY IF EXISTS "service_access_policies" ON policies;
DROP POLICY IF EXISTS "service_access_claims" ON claims;
DROP POLICY IF EXISTS "service_access_wallet" ON wallet_transactions;
DROP POLICY IF EXISTS "service_access_notifications" ON notifications;

-- 1. SECURE USER ACCESS
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

-- 5. PUBLIC ACCESS WHERE APPROPRIATE
CREATE POLICY "disruptions_public" ON disruption_events
  FOR SELECT USING (true);

CREATE POLICY "risk_pools_public" ON risk_pools
  FOR SELECT USING (true);

CREATE POLICY "zones_h3_public" ON zones_h3
  FOR SELECT USING (true);

CREATE POLICY "circuit_breakers_public" ON circuit_breakers
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

-- 8. SECURE TELEMETRY ACCESS
CREATE POLICY "shift_telemetry_insert_own" ON shift_telemetry
  FOR INSERT WITH CHECK (worker_id = auth.uid());

CREATE POLICY "shift_telemetry_read_own" ON shift_telemetry
  FOR SELECT USING (worker_id = auth.uid());

CREATE POLICY "shift_gaps_read_own" ON shift_gaps
  FOR SELECT USING (worker_id = auth.uid());

CREATE POLICY "fraud_flags_read_own" ON fraud_flags
  FOR SELECT USING (worker_id = auth.uid());

-- 9. SERVICE ROLE ACCESS (for backend APIs)
CREATE POLICY "service_access_users" ON users
  FOR ALL USING (
    auth.jwt() ->> 'role' = 'service_role' OR 
    auth.uid() = id
  );

CREATE POLICY "service_access_policies" ON policies
  FOR ALL USING (
    auth.jwt() ->> 'role' = 'service_role' OR 
    user_id = auth.uid()
  );

CREATE POLICY "service_access_claims" ON claims
  FOR ALL USING (
    auth.jwt() ->> 'role' = 'service_role' OR 
    user_id = auth.uid()
  );

CREATE POLICY "service_access_wallet" ON wallet_transactions
  FOR ALL USING (
    auth.jwt() ->> 'role' = 'service_role' OR 
    user_id = auth.uid()
  );

CREATE POLICY "service_access_notifications" ON notifications
  FOR ALL USING (
    auth.jwt() ->> 'role' = 'service_role' OR 
    user_id = auth.uid()
  );

-- ============================================================
-- FUNCTIONS
-- ============================================================

-- H3 Zone Depth Function
CREATE OR REPLACE FUNCTION public.hustlr_zone_depth(
  worker_lat double precision,
  worker_lon double precision,
  hub_lat double precision DEFAULT 12.982,
  hub_lon double precision DEFAULT 80.243
)
RETURNS jsonb
LANGUAGE sql
STABLE
AS $$
  WITH km AS (
    SELECT (
      ST_Distance(
        ST_SetSRID(ST_MakePoint(worker_lon, worker_lat), 4326)::geography,
        ST_SetSRID(ST_MakePoint(hub_lon, hub_lat), 4326)::geography
      ) / 1000.0
    ) AS d
  )
  SELECT jsonb_build_object(
    'distance_km', round(d::numeric, 3),
    'zone_depth_score',
    CASE
      WHEN d <= 2  THEN 1.0
      WHEN d <= 5  THEN 0.85
      WHEN d <= 10 THEN 0.65
      ELSE GREATEST(0.35::double precision, 0.65 - 0.02 * (d - 10))
    END,
    'source', 'postgis'
  )
  FROM km;
$$;

-- Auto-update updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Risk pool sync function
CREATE OR REPLACE FUNCTION sync_risk_pool()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' AND NEW.pool_id IS NOT NULL THEN
    UPDATE risk_pools
    SET 
      active_policies  = active_policies + 1,
      total_premium    = total_premium + NEW.weekly_premium,
      updated_at       = NOW()
    WHERE id = NEW.pool_id;
  END IF;
  
  IF TG_OP = 'UPDATE' 
     AND NEW.status IN ('expired','cancelled')
     AND OLD.status = 'active'
     AND NEW.pool_id IS NOT NULL THEN
    UPDATE risk_pools
    SET 
      active_policies = GREATEST(active_policies - 1, 0),
      updated_at      = NOW()
    WHERE id = NEW.pool_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Fraud baseline creation function
CREATE OR REPLACE FUNCTION create_fraud_baseline()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO fraud_baselines (
    user_id,
    avg_daily_deliveries,
    typical_zones,
    avg_shift_start_hour,
    avg_shift_end_hour,
    weeks_active
  ) VALUES (
    NEW.id,
    0,
    ARRAY[NEW.zone],
    8,
    22,
    0
  ) ON CONFLICT (user_id) DO NOTHING;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Referral code generation function
CREATE OR REPLACE FUNCTION generate_referral_code()
RETURNS TRIGGER AS $$
DECLARE
  code TEXT;
BEGIN
  IF NEW.referral_code IS NULL THEN
    code := 'HUSTLR-' || upper(substring(gen_random_uuid()::text, 1, 5));
    NEW.referral_code = code;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- TRIGGERS
-- ============================================================
DROP TRIGGER IF EXISTS users_updated_at ON users;
DROP TRIGGER IF EXISTS policies_updated_at ON policies;
DROP TRIGGER IF EXISTS policy_pool_sync ON policies;
DROP TRIGGER IF EXISTS user_fraud_baseline ON users;
DROP TRIGGER IF EXISTS trg_generate_referral_code ON users;

-- Auto-update updated_at triggers
CREATE TRIGGER users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER policies_updated_at
  BEFORE UPDATE ON policies
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Risk pool sync trigger
CREATE TRIGGER policy_pool_sync
  AFTER INSERT OR UPDATE ON policies
  FOR EACH ROW EXECUTE FUNCTION sync_risk_pool();

-- Fraud baseline creation trigger
CREATE TRIGGER user_fraud_baseline
  AFTER INSERT ON users
  FOR EACH ROW EXECUTE FUNCTION create_fraud_baseline();

-- Referral code generation trigger
CREATE TRIGGER trg_generate_referral_code
  BEFORE INSERT ON users
  FOR EACH ROW EXECUTE FUNCTION generate_referral_code();

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
  AND table_name IN (
    'users','policies','claims','wallet_transactions','disruption_events',
    'notifications','referrals','risk_pools','circuit_breakers',
    'shadow_policies','fraud_baselines','weekly_settlements',
    'reinsurance_triggers','admin_actions','appeal_requests',
    'pool_health','device_fingerprint_events','shift_telemetry',
    'shift_gaps','fraud_flags','pending_frs_adjustments',
    'trust_events','zones_h3','regional_intelligence_snapshots'
  )
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

-- Test H3 function
SELECT hustlr_zone_depth(13.0112, 80.2356, 12.982, 80.243) AS test_zone_depth;
