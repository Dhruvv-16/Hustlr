ALTER TABLE users
  ADD COLUMN IF NOT EXISTS trust_score      INTEGER DEFAULT 100,
  ADD COLUMN IF NOT EXISTS trust_tier       TEXT DEFAULT 'SILVER',
  ADD COLUMN IF NOT EXISTS clean_weeks      INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS cashback_earned  INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS cashback_pending INTEGER DEFAULT 0;

CREATE TABLE IF NOT EXISTS trust_events (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        UUID REFERENCES users(id) ON DELETE CASCADE,
  event_type     TEXT NOT NULL,
  score_change   INTEGER NOT NULL,
  new_score      INTEGER NOT NULL,
  reason         TEXT,
  created_at     TIMESTAMPTZ DEFAULT NOW()
);
