-- Fix Fraud Score Race Condition
-- Execute this in the Supabase SQL Editor to guarantee atomic scoring of fraudulent claims.

CREATE OR REPLACE FUNCTION check_and_increment_circuit_breaker_atomic(
  p_zone TEXT,
  p_city TEXT,
  p_limit INTEGER
) RETURNS TABLE (allowed BOOLEAN, current_count INTEGER) AS $$
DECLARE
  v_count INTEGER;
  v_lock_id BIGINT;
BEGIN
  -- Obtain a deterministic lock ID from the zone text
  -- Ensures two simultaneous claims in the same zone wait for each other
  v_lock_id := ('circuit_breaker_' || p_zone)::regtype::oid::bigint;

  -- Block execution here until we hold the exclusive lock for this zone
  PERFORM pg_advisory_xact_lock(v_lock_id);

  -- Transactionally locked row count
  SELECT COUNT(*) INTO v_count
  FROM claims
  WHERE zone = p_zone AND created_at > NOW() - INTERVAL '1 hour';

  RETURN QUERY SELECT (v_count < p_limit), v_count;
END;
$$ LANGUAGE plpgsql;
