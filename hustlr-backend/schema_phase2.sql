-- Phase 2 — Run in Supabase SQL Editor after schema.sql
-- PostGIS zone depth (matches Node haversine rings) + regional intelligence log

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

-- Device fingerprint samples for shared-device / ring-style fraud signals (Phase 2)
CREATE TABLE IF NOT EXISTS device_fingerprint_events (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id            UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  fingerprint_hash   TEXT NOT NULL,
  zone               TEXT,
  created_at         TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_dfe_hash_created
  ON device_fingerprint_events (fingerprint_hash, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_dfe_zone_created
  ON device_fingerprint_events (zone, created_at DESC)
  WHERE zone IS NOT NULL;
