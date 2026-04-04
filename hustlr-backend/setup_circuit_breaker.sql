CREATE TABLE IF NOT EXISTS circuit_breakers (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  zone         TEXT NOT NULL,
  city         TEXT NOT NULL DEFAULT 'Chennai',
  trigger_type TEXT NOT NULL,
  claims_count INTEGER DEFAULT 0,
  bcr_at_trip  FLOAT DEFAULT 0,
  tripped      BOOLEAN DEFAULT FALSE,
  tripped_at   TIMESTAMPTZ DEFAULT NULL,
  reset_at     TIMESTAMPTZ DEFAULT NULL,
  reason       TEXT DEFAULT NULL,
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (zone, trigger_type)
);

ALTER TABLE circuit_breakers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "allow_all" ON circuit_breakers FOR ALL USING (true);

-- Ensure risk_pools exists for our new BCR tracking
CREATE TABLE IF NOT EXISTS risk_pools (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  city              TEXT NOT NULL UNIQUE,
  total_premium     FLOAT DEFAULT 0,
  total_claims_paid FLOAT DEFAULT 0,
  loss_ratio        FLOAT DEFAULT 0,
  updated_at        TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE risk_pools ENABLE ROW LEVEL SECURITY;
CREATE POLICY "allow_all" ON risk_pools FOR ALL USING (true);
