-- ═══════════════════════════════════════════════════════════
-- HUSTLR — PRODUCTION MIGRATION SCRIPT
-- Execute AFTER validation script passes all checks
-- ═════════════════════════════════════════════════════════════

BEGIN;

-- ═════════════════════════════════════════════════════════════
-- STEP 1: Add missing columns to existing tables
-- ═══════════════════════════════════════════════════════════════

-- Add actuarial columns to policies table
ALTER TABLE policies 
ADD COLUMN IF NOT EXISTS paid_until DATE DEFAULT CURRENT_DATE + INTERVAL '7 days',
ADD COLUMN IF NOT EXISTS commitment_end DATE DEFAULT CURRENT_DATE + INTERVAL '13 weeks';

-- Add trust score bounds to users table
ALTER TABLE users 
ADD CONSTRAINT IF NOT EXISTS chk_trust_score_range 
CHECK (trust_score BETWEEN 0 AND 1000);

-- Add session timeout constraint
ALTER TABLE auth_sessions 
ADD CONSTRAINT IF NOT EXISTS chk_session_timeout 
CHECK (last_seen_at > created_at - INTERVAL '24 hours');

-- ═════════════════════════════════════════════════════════════
-- STEP 2: Create new tables
-- ═══════════════════════════════════════════════════════════════

-- Riders table for proper add-on lifecycle
CREATE TABLE IF NOT EXISTS riders (
  id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  policy_id           UUID        NOT NULL REFERENCES policies(id) ON DELETE CASCADE,
  rider_type          TEXT        NOT NULL CHECK (rider_type IN (
    'cyclone_cover','internet_blackout','curfew_strike',
    'accident_blockspot','traffic_congestion','election_day'
  )),
  premium_per_week    INTEGER     NOT NULL DEFAULT 0,
  start_date          DATE        NOT NULL DEFAULT CURRENT_DATE,
  end_date            DATE        NOT NULL,
  blackout_end        TIMESTAMPTZ NOT NULL,
  status              TEXT        NOT NULL DEFAULT 'active' CHECK (status IN ('active','cancelled')),
  created_at          TIMESTAMPTZ DEFAULT NOW(),
  CHECK (end_date > start_date)
);

-- Renewal history for audit trail
CREATE TABLE IF NOT EXISTS renewal_history (
  id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  policy_id           UUID        NOT NULL REFERENCES policies(id) ON DELETE CASCADE,
  old_commitment_end  DATE        NOT NULL,
  new_commitment_end  DATE        NOT NULL,
  weekly_premium      INTEGER     NOT NULL,
  renewed_at          TIMESTAMPTZ DEFAULT NOW()
);

-- Shift summary for telemetry aggregation
CREATE TABLE IF NOT EXISTS shift_summary (
  id                    UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  worker_id             UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  week_start            DATE        NOT NULL,
  total_hours           FLOAT        DEFAULT 0,
  total_gaps            INTEGER     DEFAULT 0,
  total_frs_penalty     INTEGER     DEFAULT 0,
  created_at            TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(worker_id, week_start)
);

-- Cron execution logs for operational visibility
CREATE TABLE IF NOT EXISTS cron_execution_logs (
  id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  job_name          TEXT        NOT NULL,
  status            TEXT        NOT NULL CHECK (status IN ('running','success','failed')),
  started_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at      TIMESTAMPTZ,
  records_processed INTEGER     DEFAULT 0,
  error_details     TEXT
);

-- Work advisor logs for nudge effectiveness
CREATE TABLE IF NOT EXISTS work_advisor_logs (
  id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  zone              TEXT        NOT NULL,
  plan_tier         TEXT        NOT NULL,
  recommendation    TEXT        NOT NULL,
  sent_at           TIMESTAMPTZ DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════════
-- STEP 3: Add critical constraints
-- ═══════════════════════════════════════════════════════════════

-- Policy duration constraint
ALTER TABLE policies 
ADD CONSTRAINT IF NOT EXISTS chk_policy_duration 
CHECK (coverage_end - coverage_start = INTERVAL '13 weeks');

-- Financial math constraints for claims
ALTER TABLE claims 
ADD CONSTRAINT IF NOT EXISTS chk_tranche_math 
CHECK (tranche1 + tranche2 = gross_payout),
ADD CONSTRAINT IF NOT EXISTS chk_max_payout 
CHECK (gross_payout <= (SELECT max_weekly_payout FROM policies WHERE id = policy_id));

-- Policy status consistency
ALTER TABLE policies 
ADD CONSTRAINT IF NOT EXISTS chk_active_commitment 
CHECK (status != 'active' OR commitment_end >= CURRENT_DATE);

-- ═══════════════════════════════════════════════════════════════
-- STEP 4: Create critical triggers
-- ═══════════════════════════════════════════════════════════════

-- Trust tier auto-calculation
CREATE OR REPLACE FUNCTION update_trust_tier()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.trust_score >= 90 THEN 
    NEW.trust_tier := 'PLATINUM';
  ELSIF NEW.trust_score >= 75 THEN 
    NEW.trust_tier := 'GOLD';
  ELSIF NEW.trust_score >= 60 THEN 
    NEW.trust_tier := 'SILVER';
  ELSIF NEW.trust_score >= 50 THEN 
    NEW.trust_tier := 'BRONZE';
  ELSE 
    NEW.trust_tier := 'AT_RISK';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_update_trust_tier ON users;
CREATE TRIGGER trg_update_trust_tier
  BEFORE INSERT OR UPDATE OF trust_score ON users
  FOR EACH ROW EXECUTE FUNCTION update_trust_tier();

-- Rider date validation
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

-- ═══════════════════════════════════════════════════════════════
-- STEP 5: Create performance indexes
-- ═══════════════════════════════════════════════════════════════

-- Claims processing optimization
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_claims_status_fraud_created 
ON claims (status, fraud_score, created_at DESC);

-- Trust score calculation optimization
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_trust_events_user_score_date 
ON trust_events (user_id, new_score, created_at DESC);

-- Wallet balance calculation optimization
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_wallet_user_type_created 
ON wallet_transactions (user_id, type, created_at DESC);

-- Telemetry aggregation optimization
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_telemetry_worker_timestamp_gap 
ON shift_telemetry (worker_id, timestamp DESC) 
WHERE timestamp > NOW() - INTERVAL '2 hours';

-- Active policy lookup optimization
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_policies_active_user 
ON policies (user_id, commitment_end) WHERE status = 'active';

-- ═════════════════════════════════════════════════════════════════
-- STEP 6: Migrate data from legacy structures
-- ═════════════════════════════════════════════════════════════════

-- Migrate legacy TEXT[] riders to new riders table (if any exist)
INSERT INTO riders (policy_id, rider_type, premium_per_week, start_date, end_date, status)
SELECT 
    p.id,
    unnest(p.riders) as rider_type,
    0 as premium_per_week,
    p.coverage_start,
    p.commitment_end,
    'active'
FROM policies p
WHERE p.riders IS NOT NULL AND jsonb_array_length(p.riders::jsonb) > 0
ON CONFLICT DO NOTHING;

-- Clear legacy riders array after migration
UPDATE policies 
SET riders = NULL 
WHERE riders IS NOT NULL AND jsonb_array_length(riders::jsonb) > 0;

-- ═══════════════════════════════════════════════════════════════
-- STEP 7: Enable RLS on new tables
-- ═════════════════════════════════════════════════════════════════

DO $$
DECLARE
  t TEXT;
  new_tables TEXT[] := ARRAY['riders','renewal_history','shift_summary','cron_execution_logs','work_advisor_logs'];
BEGIN
  FOREACH t IN ARRAY new_tables LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('DROP POLICY IF EXISTS "allow_all" ON %I', t);
    EXECUTE format('CREATE POLICY "allow_all" ON %I FOR ALL USING (true)', t);
  END LOOP;
END $$;

COMMIT;

-- ═════════════════════════════════════════════════════════════════
-- POST-MIGRATION VERIFICATION
-- ═════════════════════════════════════════════════════════════════

-- Verify all constraints are active
SELECT 
    constraint_name,
    table_name,
    check_clause
FROM information_schema.check_constraints 
WHERE constraint_schema = 'public' 
ORDER BY table_name, constraint_name;

-- Verify all triggers are active
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_timing,
    action_condition
FROM information_schema.triggers 
WHERE trigger_schema = 'public' 
ORDER BY event_object_table, trigger_name;

-- Verify new tables are created and have RLS
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('riders','renewal_history','shift_summary','cron_execution_logs','work_advisor_logs')
ORDER BY tablename;

-- Migration success summary
SELECT 'MIGRATION COMPLETE' as status,
       NOW() as completed_at,
       'All critical constraints, triggers, and tables deployed' as notes;
