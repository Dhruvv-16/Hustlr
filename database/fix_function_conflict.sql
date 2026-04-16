-- ============================================================
-- FIX FUNCTION CONFLICT
-- Drop existing function before recreating
-- ============================================================

-- Drop the existing function first
DROP FUNCTION IF EXISTS public.hustlr_zone_depth(double precision, double precision, double precision, double precision);

-- Now recreate with correct signature
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

-- Test the function
SELECT hustlr_zone_depth(13.0112, 80.2356, 12.982, 80.243);
