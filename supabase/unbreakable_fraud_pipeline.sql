-- Fix Fraud Score Race Condition: The Unbreakable Pipeline
-- This migration establishes true TOCTOU-safe claim insertion.

-- Ensure idempotency tracking column exists
ALTER TABLE claims ADD COLUMN IF NOT EXISTS idempotency_key TEXT UNIQUE;

CREATE OR REPLACE FUNCTION submit_claim_atomic(
  p_idempotency_key TEXT,
  p_user_id TEXT,
  p_trigger_type TEXT,
  p_zone TEXT,
  p_city TEXT,
  p_severity FLOAT,
  p_duration_hours FLOAT,
  p_gross_payout INTEGER,
  p_tranche1 INTEGER,
  p_tranche2 INTEGER,
  p_fraud_score INTEGER,
  p_fraud_status TEXT,
  p_fps_signals JSONB,
  p_limit INTEGER
) RETURNS TABLE (
  success BOOLEAN, 
  claim_id TEXT, 
  current_count INTEGER, 
  error_code TEXT
) AS $$
DECLARE
  v_count INTEGER;
  v_lock_id BIGINT;
  v_claim_id TEXT;
BEGIN
  -- 1. Idempotency Check (Fast fail before locking)
  IF EXISTS (SELECT 1 FROM claims WHERE idempotency_key = p_idempotency_key) THEN
    RETURN QUERY SELECT FALSE, NULL::TEXT, 0, 'DUPLICATE_REQUEST';
    RETURN;
  END IF;

  -- 2. Deterministic Zone Lock
  v_lock_id := hashtext('circuit_breaker_' || p_zone)::bigint;
  PERFORM pg_advisory_xact_lock(v_lock_id);

  -- 3. Check Circuit Breaker Limits (Under Lock)
  SELECT COUNT(*) INTO v_count
  FROM claims
  WHERE zone = p_zone 
    AND created_at > NOW() - INTERVAL '1 hour';

  IF v_count >= p_limit THEN
    -- Optional: Log the tripped breaker here
    INSERT INTO circuit_breakers (zone, city, trigger_type, claims_count, tripped, tripped_at)
    VALUES (p_zone, p_city, p_trigger_type, v_count, TRUE, NOW())
    ON CONFLICT (zone, trigger_type) 
    DO UPDATE SET tripped = TRUE, tripped_at = NOW(), claims_count = v_count;

    RETURN QUERY SELECT FALSE, NULL::TEXT, v_count, 'CIRCUIT_BREAKER_TRIPPED';
    RETURN;
  END IF;

  -- 4. Insert the Claim (Still under Lock)
  INSERT INTO claims (
    idempotency_key, user_id, trigger_type, zone, city, 
    severity, duration_hours, gross_payout, tranche1, tranche2, 
    fraud_score, fraud_status, fps_signals, status
  ) VALUES (
    p_idempotency_key, cast(p_user_id as UUID), p_trigger_type, p_zone, p_city, 
    p_severity, p_duration_hours, p_gross_payout, p_tranche1, p_tranche2, 
    p_fraud_score, p_fraud_status, p_fps_signals,
    'PENDING' -- The background queues approve it a few moments later if CLEAN
  ) RETURNING id::TEXT INTO v_claim_id;

  -- 5. Success
  RETURN QUERY SELECT TRUE, v_claim_id, v_count + 1, 'SUCCESS';
END;
$$ LANGUAGE plpgsql;
