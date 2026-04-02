-- schema.sql
-- Run this securely in your Supabase SQL Editor

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users Table
CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  phone text UNIQUE NOT NULL,
  zone text NOT NULL,
  city text NOT NULL,
  platform text NOT NULL,
  iss_score integer DEFAULT 75,
  created_at timestamptz DEFAULT now()
);

-- Policies Table
CREATE TABLE IF NOT EXISTS policies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  plan_tier text NOT NULL, -- basic, standard, full, elite
  base_premium integer NOT NULL,
  zone_adjustment integer DEFAULT 0,
  iss_adjustment integer DEFAULT 0,
  weekly_premium integer NOT NULL,
  max_weekly_payout integer NOT NULL,
  status text DEFAULT 'active',
  start_date date DEFAULT current_date,
  created_at timestamptz DEFAULT now()
);

-- Claims Table
CREATE TABLE IF NOT EXISTS claims (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  policy_id uuid REFERENCES policies(id),
  trigger_type text NOT NULL,
  zone text NOT NULL,
  severity float NOT NULL,
  duration_hours float NOT NULL,
  gross_payout integer NOT NULL,
  tranche1 integer NOT NULL,
  tranche2 integer NOT NULL,
  fraud_score integer DEFAULT 0,
  fraud_status text DEFAULT 'CLEAN',
  status text DEFAULT 'PENDING',
  created_at timestamptz DEFAULT now()
);

-- Wallet Transactions Table
CREATE TABLE IF NOT EXISTS wallet_transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  amount integer NOT NULL,
  type text NOT NULL, -- credit, debit
  reference text,
  description text,
  created_at timestamptz DEFAULT now()
);

-- Disruption Events Table
CREATE TABLE IF NOT EXISTS disruption_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  zone text NOT NULL,
  trigger_type text NOT NULL,
  severity float NOT NULL,
  rainfall_mm float DEFAULT 0,
  temperature_c float DEFAULT 0,
  aqi integer DEFAULT 0,
  started_at timestamptz NOT NULL,
  ended_at timestamptz,
  created_at timestamptz DEFAULT now()
);
