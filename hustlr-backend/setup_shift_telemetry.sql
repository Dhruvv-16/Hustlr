-- ============================================================
-- Hustlr Phase 3: Background Geolocation + Anti-Spoofing
-- Run this in Supabase SQL Editor after schema.sql
-- ============================================================

-- ─── shift_telemetry ──────────────────────────────────────────────────────────
-- Stores every GPS heartbeat ping from the Flutter app during an active shift.
-- POST /shift/heartbeat inserts one row per ping (~every 30 seconds).
CREATE TABLE IF NOT EXISTS shift_telemetry (
  id                  uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  worker_id           uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  lat                 float8 NOT NULL,
  lng                 float8 NOT NULL,
  accuracy            float4,          -- metres; readings > 50m marked low_confidence
  timestamp           timestamptz NOT NULL,
  is_mock_location    boolean DEFAULT false,  -- isMocked from Geolocator
  activity_type       text,            -- 'in_vehicle', 'on_foot', 'still', 'unknown'
  battery_level       float4,          -- 0.0–1.0
  signal_strength     int,             -- dBm (populated by backend from extras)
  is_low_confidence   boolean DEFAULT false,  -- accuracy > 50m
  created_at          timestamptz DEFAULT now()
);

-- Index for fast per-worker, per-date queries during claim validation
CREATE INDEX IF NOT EXISTS idx_shift_telemetry_worker_ts
  ON shift_telemetry (worker_id, timestamp DESC);

-- Enable Row Level Security
ALTER TABLE shift_telemetry ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Workers can insert their own telemetry"
  ON shift_telemetry FOR INSERT
  WITH CHECK (worker_id = auth.uid());
CREATE POLICY "Workers can read their own telemetry"
  ON shift_telemetry FOR SELECT
  USING (worker_id = auth.uid());

-- ─── shift_gaps ───────────────────────────────────────────────────────────────
-- Logged by the backend whenever GPS heartbeat drops for > 120 seconds.
-- Used in shift_window_intersection check to exclude unverified windows.
-- Gaps > 600s add +10 FRS, gaps > 1800s add +20 FRS.
CREATE TABLE IF NOT EXISTS shift_gaps (
  id                    uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  worker_id             uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  gap_start             timestamptz NOT NULL,
  gap_end               timestamptz,   -- null until GPS resumes
  gap_duration_seconds  int,           -- computed when gap_end is set
  frs_penalty           int DEFAULT 0, -- 0, 10, or 20 depending on duration
  created_at            timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_shift_gaps_worker_date
  ON shift_gaps (worker_id, gap_start DESC);

ALTER TABLE shift_gaps ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Workers can read their own gaps"
  ON shift_gaps FOR SELECT
  USING (worker_id = auth.uid());

-- ─── fraud_flags (extend if not exists) ───────────────────────────────────────
-- Auto-appended by the heartbeat endpoint when is_mock_location = true
CREATE TABLE IF NOT EXISTS fraud_flags (
  id          uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  worker_id   uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  claim_id    uuid,                    -- null if detected before claim is filed
  reason      text NOT NULL,           -- 'mock_location_detected', 'impossible_speed', etc.
  frs_score   int NOT NULL DEFAULT 0,  -- score contribution from this flag
  timestamp   timestamptz NOT NULL DEFAULT now(),
  resolved    boolean DEFAULT false,
  created_at  timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_fraud_flags_worker
  ON fraud_flags (worker_id, timestamp DESC);

ALTER TABLE fraud_flags ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Workers can read their own flags"
  ON fraud_flags FOR SELECT
  USING (worker_id = auth.uid());

-- ─── Auto-pause function (Supabase pg_cron or Edge Function trigger) ──────────
-- Runs every 30 seconds via pg_cron or a Supabase Edge Function.
-- If a worker's last heartbeat is > 120 seconds ago and shift is ACTIVE:
--   1. Open a new shift_gap row
--   2. Notify via pg_notify (Flutter/FCM picks this up)
CREATE OR REPLACE FUNCTION auto_pause_stale_shifts()
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
  stale RECORD;
BEGIN
  FOR stale IN
    SELECT DISTINCT ON (worker_id) worker_id, timestamp AS last_seen
    FROM shift_telemetry
    WHERE timestamp > now() - INTERVAL '10 minutes' -- only check recent workers
    ORDER BY worker_id, timestamp DESC
  LOOP
    IF (now() - stale.last_seen) > INTERVAL '120 seconds' THEN
      -- Open a gap if none is currently open for this worker
      INSERT INTO shift_gaps (worker_id, gap_start)
      SELECT stale.worker_id, stale.last_seen
      WHERE NOT EXISTS (
        SELECT 1 FROM shift_gaps
        WHERE worker_id = stale.worker_id AND gap_end IS NULL
      );
    END IF;
  END LOOP;
END;
$$;

-- ─── Resume gap function (called by heartbeat endpoint) ───────────────────────
CREATE OR REPLACE FUNCTION close_open_gap(p_worker_id uuid, p_resume_time timestamptz)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
  gap_sec int;
BEGIN
  SELECT EXTRACT(EPOCH FROM (p_resume_time - gap_start))::int
  INTO gap_sec
  FROM shift_gaps
  WHERE worker_id = p_worker_id AND gap_end IS NULL
  LIMIT 1;

  UPDATE shift_gaps
  SET
    gap_end = p_resume_time,
    gap_duration_seconds = gap_sec,
    frs_penalty = CASE
      WHEN gap_sec > 1800 THEN 20
      WHEN gap_sec > 600  THEN 10
      ELSE 0
    END
  WHERE worker_id = p_worker_id AND gap_end IS NULL;
END;
$$;

-- ─── Pending FRS Adjustments ──────────────────────────────────────────────────
-- Consumed by the fraud engine on the next claim submission
CREATE TABLE IF NOT EXISTS pending_frs_adjustments (
  id          uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  worker_id   uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  adjustment  int NOT NULL,
  reason      text NOT NULL,
  is_consumed boolean DEFAULT false,
  created_at  timestamptz DEFAULT now()
);

-- Note: Ensure `users` table acts equivalently to `workers` in your schema mapping:
ALTER TABLE users 
  ADD COLUMN IF NOT EXISTS last_seen_at timestamptz,
  ADD COLUMN IF NOT EXISTS paused_at timestamptz,
  ADD COLUMN IF NOT EXISTS shift_status text DEFAULT 'OFFLINE';
