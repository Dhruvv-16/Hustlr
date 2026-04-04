-- ======================
-- TRIGGER 1 — Auto update updated_at
-- ======================

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS users_updated_at ON users;
CREATE TRIGGER users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS policies_updated_at ON policies;
CREATE TRIGGER policies_updated_at
  BEFORE UPDATE ON policies
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ======================
-- TRIGGER 2 — Sync risk pool when policy changes
-- ======================

CREATE OR REPLACE FUNCTION sync_risk_pool()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE risk_pools
    SET 
      active_policies  = active_policies + 1,
      total_premium    = total_premium + NEW.weekly_premium,
      updated_at       = NOW()
    WHERE city = (
      SELECT city FROM users WHERE id = NEW.user_id
    );
  END IF;
  
  IF TG_OP = 'UPDATE' AND NEW.status = 'expired' 
     AND OLD.status = 'active' THEN
    UPDATE risk_pools
    SET 
      active_policies = GREATEST(active_policies - 1, 0),
      updated_at      = NOW()
    WHERE city = (
      SELECT city FROM users WHERE id = NEW.user_id
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS policy_pool_sync ON policies;
CREATE TRIGGER policy_pool_sync
  AFTER INSERT OR UPDATE ON policies
  FOR EACH ROW EXECUTE FUNCTION sync_risk_pool();

-- ======================
-- TRIGGER 3 — Auto compute loss ratio when claim settles
-- ======================

CREATE OR REPLACE FUNCTION update_pool_on_claim()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'APPROVED' AND OLD.status = 'PENDING' THEN
    UPDATE risk_pools rp
    SET
      total_claims_paid = total_claims_paid + NEW.tranche1,
      loss_ratio = CASE 
        WHEN total_premium > 0 
        THEN ROUND(
          (total_claims_paid + NEW.tranche1)::NUMERIC 
          / total_premium::NUMERIC, 4
        )
        ELSE 0 
      END,
      updated_at = NOW()
    FROM users u
    WHERE u.id = NEW.user_id
    AND rp.city = u.city;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS claim_pool_update ON claims;
CREATE TRIGGER claim_pool_update
  AFTER UPDATE ON claims
  FOR EACH ROW EXECUTE FUNCTION update_pool_on_claim();

-- ======================
-- TRIGGER 4 — Auto create fraud baseline for new user
-- ======================

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

DROP TRIGGER IF EXISTS user_fraud_baseline ON users;
CREATE TRIGGER user_fraud_baseline
  AFTER INSERT ON users
  FOR EACH ROW EXECUTE FUNCTION create_fraud_baseline();

-- ======================
-- TRIGGER 5 — Auto close disruption event when ended
-- ======================

CREATE OR REPLACE FUNCTION compute_disruption_duration()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.ended_at IS NOT NULL AND OLD.ended_at IS NULL THEN
    NEW.duration_hrs = EXTRACT(
      EPOCH FROM (NEW.ended_at - NEW.started_at)
    ) / 3600.0;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS disruption_duration ON disruption_events;
CREATE TRIGGER disruption_duration
  BEFORE UPDATE ON disruption_events
  FOR EACH ROW EXECUTE FUNCTION compute_disruption_duration();

-- ======================
-- TRIGGER 6 — Auto-generate referral_code on user insert
-- ======================

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

DROP TRIGGER IF EXISTS trg_generate_referral_code ON users;
CREATE TRIGGER trg_generate_referral_code
  BEFORE INSERT ON users
  FOR EACH ROW EXECUTE FUNCTION generate_referral_code();
