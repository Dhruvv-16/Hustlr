-- CRITICAL DEPLOYMENT BLOCKER FIXES
-- Execute these fixes immediately before deployment

-- 1. Fix Quarterly Policy Duration Constraint
-- The constraint was referencing non-existent coverage_end column
ALTER TABLE policies DROP CONSTRAINT IF EXISTS chk_policy_duration;
ALTER TABLE policies ADD CONSTRAINT chk_policy_duration 
CHECK (commitment_end - coverage_start = INTERVAL '13 weeks');

-- 2. Add Missing Database Indexes for Performance
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_wallet_transactions_user_created 
ON wallet_transactions(user_id, created_at DESC);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_claims_user_created 
ON claims(user_id, created_at DESC);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_policies_user_status 
ON policies(user_id, status);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_shift_telemetry_worker_timestamp 
ON shift_telemetry(worker_id, timestamp DESC);

-- 3. Fix Orphaned Tables - Either Implement or Remove
-- Option A: Implement pending_frs_adjustments usage
CREATE OR REPLACE FUNCTION apply_pending_frs_adjustments()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  adj RECORD;
BEGIN
  -- Apply any pending FRS adjustments when user score changes
  FOR adj IN 
    SELECT * FROM pending_frs_adjustments 
    WHERE worker_id = NEW.id AND is_consumed = FALSE
  LOOP
    UPDATE users 
    SET trust_score = GREATEST(trust_score + adj.adjustment, 0),
        trust_tier = CASE 
          WHEN trust_score >= 90 THEN 'PLATINUM'
          WHEN trust_score >= 75 THEN 'GOLD'
          WHEN trust_score >= 60 THEN 'SILVER'
          WHEN trust_score >= 50 THEN 'BRONZE'
          ELSE 'AT_RISK'
        END
    WHERE id = NEW.id;
    
    UPDATE pending_frs_adjustments 
    SET is_consumed = TRUE 
    WHERE id = adj.id;
  END LOOP;
  
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_apply_frs_adjustments
  AFTER UPDATE OF trust_score ON users
  FOR EACH ROW EXECUTE FUNCTION apply_pending_frs_adjustments();

-- 4. Add Missing Foreign Key Constraints
ALTER TABLE trust_events 
ADD CONSTRAINT fk_trust_events_user 
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- 5. Fix Notifications Table - Add Sender Information
ALTER TABLE notifications 
ADD COLUMN sender_id UUID REFERENCES users(id) ON DELETE SET NULL,
ADD COLUMN sender_type TEXT DEFAULT 'system' CHECK (sender_type IN ('system','admin','service'));

-- 6. Add Device Fingerprint Unique Constraint
ALTER TABLE device_fingerprint_events 
ADD CONSTRAINT uniq_device_fingerprint 
UNIQUE (fingerprint_hash, user_id, created_at);

-- 7. Fix Policy Created_at Default
ALTER TABLE policies 
ALTER COLUMN created_at SET DEFAULT NOW();

-- 8. Add Missing Database Constraints for Financial Safety
ALTER TABLE claims 
ADD CONSTRAINT chk_claim_payout_limits 
CHECK (gross_payout <= (SELECT max_weekly_payout FROM policies WHERE id = policy_id));

-- 9. Add Shift Telemetry Retention Policy
CREATE OR REPLACE FUNCTION cleanup_old_telemetry()
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  -- Delete GPS telemetry older than 90 days (GDPR compliance)
  DELETE FROM shift_telemetry 
  WHERE created_at < NOW() - INTERVAL '90 days';
  
  -- Delete old device fingerprint events
  DELETE FROM device_fingerprint_events 
  WHERE created_at < NOW() - INTERVAL '90 days';
  
  -- Delete old fraud signal logs
  DELETE FROM fraud_signal_logs 
  WHERE created_at < NOW() - INTERVAL '180 days';
END;
$$;

-- Schedule cleanup job (run daily at 2 AM)
SELECT cron.schedule('cleanup-job', '0 2 * * *', 'SELECT cleanup_old_telemetry();');

-- 10. Add Zone Depth Score Calculation Function
CREATE OR REPLACE FUNCTION calculate_zone_depth_score(p_zone TEXT, p_lat FLOAT, p_lng FLOAT)
RETURNS FLOAT LANGUAGE plpgsql AS $$
DECLARE
  zone_center RECORD;
  distance_km FLOAT;
  depth_score FLOAT;
BEGIN
  -- Get zone center coordinates (assuming zones table exists)
  SELECT lat, lng INTO zone_center 
  FROM zones 
  WHERE name = p_zone 
  LIMIT 1;
  
  IF NOT FOUND THEN
    RETURN 1.0; -- Default score if zone not found
  END IF;
  
  -- Calculate distance using PostGIS
  SELECT ST_Distance(
    ST_MakePoint(p_lng, p_lat)::geography,
    ST_MakePoint(zone_center.lng, zone_center.lat)::geography
  ) / 1000.0 INTO distance_km;
  
  -- Calculate depth score (closer to center = higher score)
  depth_score := CASE 
    WHEN distance_km <= 1.0 THEN 1.0
    WHEN distance_km <= 3.0 THEN 0.8
    WHEN distance_km <= 5.0 THEN 0.6
    WHEN distance_km <= 10.0 THEN 0.4
    ELSE 0.2
  END;
  
  RETURN depth_score;
END;
$$;

-- 11. Add Trust Score Calculation Function
CREATE OR REPLACE FUNCTION calculate_trust_score(p_user_id UUID)
RETURNS INTEGER LANGUAGE plpgsql AS $$
DECLARE
  base_score INTEGER := 100;
  clean_weeks INTEGER;
  fraud_penalties INTEGER;
  gap_penalties INTEGER;
  final_score INTEGER;
BEGIN
  -- Get user's clean weeks
  SELECT COALESCE(clean_weeks, 0) INTO clean_weeks 
  FROM users 
  WHERE id = p_user_id;
  
  -- Calculate fraud penalties
  SELECT COALESCE(SUM(frs_score), 0) INTO fraud_penalties
  FROM fraud_flags 
  WHERE worker_id = p_user_id 
    AND created_at >= NOW() - INTERVAL '90 days';
  
  -- Calculate gap penalties
  SELECT COALESCE(SUM(frs_penalty), 0) INTO gap_penalties
  FROM shift_gaps 
  WHERE worker_id = p_user_id 
    AND created_at >= NOW() - INTERVAL '90 days';
  
  -- Calculate final score
  final_score := GREATEST(
    base_score + (clean_weeks * 5) - fraud_penalties - gap_penalties,
    0
  );
  
  -- Cap at 1000
  final_score := LEAST(final_score, 1000);
  
  -- Update user's trust score
  UPDATE users 
  SET trust_score = final_score,
      trust_tier = CASE 
        WHEN final_score >= 900 THEN 'PLATINUM'
        WHEN final_score >= 750 THEN 'GOLD'
        WHEN final_score >= 600 THEN 'SILVER'
        WHEN final_score >= 500 THEN 'BRONZE'
        ELSE 'AT_RISK'
      END
  WHERE id = p_user_id;
  
  RETURN final_score;
END;
$$;

-- 12. Add Cashback Calculation Function
CREATE OR REPLACE FUNCTION calculate_cashback(p_user_id UUID, p_period_start DATE, p_period_end DATE)
RETURNS INTEGER LANGUAGE plpgsql AS $$
DECLARE
  total_premiums INTEGER := 0;
  total_claims INTEGER := 0;
  cashback_rate FLOAT := 0.1; -- 10% cashback
  cashback_amount INTEGER := 0;
BEGIN
  -- Calculate total premiums paid in period
  SELECT COALESCE(SUM(amount), 0) INTO total_premiums
  FROM wallet_transactions 
  WHERE user_id = p_user_id 
    AND category = 'premium'
    AND created_at >= p_period_start
    AND created_at <= p_period_end
    AND type = 'debit';
  
  -- Calculate total claims paid in period
  SELECT COALESCE(SUM(amount), 0) INTO total_claims
  FROM wallet_transactions 
  WHERE user_id = p_user_id 
    AND category IN ('payout_tranche1', 'payout_tranche2')
    AND created_at >= p_period_start
    AND created_at <= p_period_end
    AND type = 'credit';
  
  -- Calculate cashback (only if no claims in period)
  IF total_claims = 0 THEN
    cashback_amount := FLOOR(total_premiums * cashback_rate);
  END IF;
  
  RETURN cashback_amount;
END;
$$;

-- 13. Add Policy Renewal Function
CREATE OR REPLACE FUNCTION renew_policy(p_policy_id UUID)
RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
  old_policy RECORD;
  new_policy_id UUID;
  new_commitment_end DATE;
BEGIN
  -- Get old policy details
  SELECT * INTO old_policy 
  FROM policies 
  WHERE id = p_policy_id AND status = 'active';
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Policy not found or not active';
  END IF;
  
  -- Calculate new commitment end (13 weeks from renewal)
  new_commitment_end := CURRENT_DATE + INTERVAL '13 weeks';
  
  -- Create new policy record
  INSERT INTO policies (
    user_id, plan_tier, base_premium, zone_adjustment, iss_adjustment,
    weekly_premium, max_weekly_payout, max_daily_payout, status,
    auto_renew, coverage_start, paid_until, commitment_end, pool_id
  ) VALUES (
    old_policy.user_id, old_policy.plan_tier, old_policy.base_premium,
    old_policy.zone_adjustment, old_policy.iss_adjustment,
    old_policy.weekly_premium, old_policy.max_weekly_payout,
    old_policy.max_daily_payout, 'active', old_policy.auto_renew,
    CURRENT_DATE, CURRENT_DATE + INTERVAL '7 days', new_commitment_end,
    old_policy.pool_id
  ) RETURNING id INTO new_policy_id;
  
  -- Update old policy status
  UPDATE policies 
  SET status = 'renewed', renewal_date = CURRENT_DATE
  WHERE id = p_policy_id;
  
  -- Log renewal
  INSERT INTO renewal_history (policy_id, old_commitment_end, new_commitment_end, weekly_premium)
  VALUES (p_policy_id, old_policy.commitment_end, new_commitment_end, old_policy.weekly_premium);
  
  -- Update user trust score for renewal
  PERFORM calculate_trust_score(old_policy.user_id);
  
  RETURN new_policy_id;
END;
$$;

-- 14. Add Riders Tier-Lock Validation Function
CREATE OR REPLACE FUNCTION validate_rider_tier(p_policy_id UUID, p_rider_type rider_type_enum)
RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
  plan_tier plan_tier_enum;
BEGIN
  SELECT plan_tier INTO plan_tier 
  FROM policies 
  WHERE id = p_policy_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Policy not found';
  END IF;
  
  -- Cyclone & Traffic require Full Shield
  IF p_rider_type IN ('cyclone_cover', 'traffic_congestion') AND plan_tier != 'full' THEN
    RETURN FALSE;
  END IF;
  
  -- Internet, Curfew, Accident require Standard+
  IF p_rider_type IN ('internet_blackout', 'curfew_strike', 'accident_blockspot') 
     AND plan_tier NOT IN ('standard', 'full') THEN
    RETURN FALSE;
  END IF;
  
  -- Election day available for all tiers
  RETURN TRUE;
END;
$$;

-- 15. Add Circuit Breaker Check Function
CREATE OR REPLACE FUNCTION check_circuit_breaker(p_zone TEXT, p_trigger_type TEXT)
RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
  cb RECORD;
  claims_today INTEGER;
  claims_hour INTEGER;
BEGIN
  -- Get circuit breaker settings
  SELECT * INTO cb 
  FROM circuit_breakers 
  WHERE zone = p_zone AND trigger_type = p_trigger_type;
  
  IF NOT FOUND THEN
    RETURN TRUE; -- No circuit breaker, allow claim
  END IF;
  
  -- Check if already tripped
  IF cb.tripped AND cb.reset_at > NOW() THEN
    RETURN FALSE; -- Circuit breaker active, block claim
  END IF;
  
  -- Check daily limit
  SELECT COUNT(*) INTO claims_today
  FROM claims 
  WHERE zone = p_zone 
    AND trigger_type = p_trigger_type
    AND created_at >= CURRENT_DATE;
  
  IF claims_today >= cb.daily_limit THEN
    -- Trip circuit breaker
    UPDATE circuit_breakers 
    SET tripped = TRUE, tripped_at = NOW(), reset_at = NOW() + INTERVAL '24 hours'
    WHERE id = cb.id;
    RETURN FALSE;
  END IF;
  
  -- Check hourly limit
  SELECT COUNT(*) INTO claims_hour
  FROM claims 
  WHERE zone = p_zone 
    AND trigger_type = p_trigger_type
    AND created_at >= NOW() - INTERVAL '1 hour';
  
  IF claims_hour >= cb.hourly_limit THEN
    -- Trip circuit breaker
    UPDATE circuit_breakers 
    SET tripped = TRUE, tripped_at = NOW(), reset_at = NOW() + INTERVAL '1 hour'
    WHERE id = cb.id;
    RETURN FALSE;
  END IF;
  
  RETURN TRUE;
END;
$$;

-- 16. Add Compound Trigger Multiplier Function
CREATE OR REPLACE FUNCTION calculate_compound_multiplier(p_plan_tier plan_tier_enum, p_severity FLOAT)
RETURNS FLOAT LANGUAGE plpgsql AS $$
DECLARE
  base_multiplier FLOAT := 1.0;
  compound_multiplier FLOAT := 1.0;
BEGIN
  -- Base multiplier by tier
  base_multiplier := CASE p_plan_tier
    WHEN 'basic' THEN 1.0
    WHEN 'standard' THEN 1.1
    WHEN 'full' THEN 1.2
    WHEN 'elite' THEN 1.3
    ELSE 1.0
  END;
  
  -- Compound multiplier for high severity (Full Shield only)
  IF p_plan_tier = 'full' AND p_severity >= 0.8 THEN
    compound_multiplier := 1.2 + (p_severity - 0.8) * 0.5; -- 1.2 to 1.3
  ELSIF p_plan_tier = 'elite' AND p_severity >= 0.7 THEN
    compound_multiplier := 1.3 + (p_severity - 0.7) * 0.5; -- 1.3 to 1.4
  END IF;
  
  RETURN base_multiplier * compound_multiplier;
END;
$$;

-- 17. Add Work Advisor Nudge Function
CREATE OR REPLACE FUNCTION generate_work_advice(p_zone TEXT, p_plan_tier plan_tier_enum)
RETURNS TABLE(recommendation TEXT, confidence_score FLOAT) LANGUAGE plpgsql AS $$
DECLARE
  disruption_count INTEGER;
  avg_severity FLOAT;
  recommendation_text TEXT;
  confidence FLOAT;
BEGIN
  -- Get recent disruption data for zone
  SELECT COUNT(*), AVG(severity) INTO disruption_count, avg_severity
  FROM disruption_events 
  WHERE zone = p_zone 
    AND started_at >= NOW() - INTERVAL '7 days';
  
  -- Generate recommendations based on data
  IF disruption_count >= 5 AND avg_severity >= 0.7 THEN
    recommendation_text := 'High disruption zone detected. Consider upgrading to Full Shield for better coverage.';
    confidence := 0.9;
  ELSIF disruption_count >= 3 THEN
    recommendation_text := 'Moderate disruption activity. Monitor weather forecasts before shifts.';
    confidence := 0.7;
  ELSIF p_plan_tier = 'basic' THEN
    recommendation_text := 'Basic plan provides limited coverage. Consider upgrading for comprehensive protection.';
    confidence := 0.6;
  ELSE
    recommendation_text := 'Current zone conditions are favorable for work.';
    confidence := 0.8;
  END IF;
  
  RETURN QUERY SELECT recommendation_text, confidence;
END;
$$;

-- Verification Queries
SELECT 'CRITICAL FIXES APPLIED' as status, NOW() as timestamp;

-- Verify constraints
SELECT constraint_name, table_name 
FROM information_schema.check_constraints 
WHERE constraint_schema = 'public' 
ORDER BY table_name, constraint_name;

-- Verify indexes
SELECT indexname, tablename 
FROM pg_indexes 
WHERE schemaname = 'public' 
  AND indexname LIKE 'idx_%'
ORDER BY tablename, indexname;

-- Verify functions
SELECT proname, prosrc 
FROM pg_proc 
WHERE proname IN (
  'calculate_trust_score', 'calculate_cashback', 'renew_policy',
  'validate_rider_tier', 'check_circuit_breaker', 'calculate_compound_multiplier',
  'generate_work_advice', 'cleanup_old_telemetry', 'calculate_zone_depth_score'
)
ORDER BY proname;
