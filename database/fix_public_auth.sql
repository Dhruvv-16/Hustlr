-- ============================================================
-- FIX PUBLIC AUTHENTICATION - RESTRICT ACCESS
-- Run this in Supabase SQL Editor
-- ============================================================

-- 1. REMOVE DANGEROUS PUBLIC POLICIES
DROP POLICY IF EXISTS "allow_all" ON users;
DROP POLICY IF EXISTS "allow_all" ON policies;
DROP POLICY IF EXISTS "allow_all" ON claims;
DROP POLICY IF EXISTS "allow_all" ON wallet_transactions;
DROP POLICY IF EXISTS "allow_all" ON disruption_events;
DROP POLICY IF EXISTS "allow_all" ON shadow_policies;
DROP POLICY IF EXISTS "allow_all" ON fraud_baselines;
DROP POLICY IF EXISTS "allow_all" ON weekly_settlements;
DROP POLICY IF EXISTS "allow_all" ON risk_pools;

-- 2. SECURE POLICIES - AUTHENTICATED USERS ONLY
CREATE POLICY "users_read_own" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "users_update_own" ON users
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "policies_read_own" ON policies
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "claims_read_own" ON claims
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "wallet_read_own" ON wallet_transactions
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "disruptions_read_all" ON disruption_events
  FOR SELECT USING (true); -- Public disruption data is OK

-- 3. ALLOW SERVICE ROLE ACCESS (for backend APIs)
CREATE POLICY "service_access" ON users
  FOR ALL USING (
    auth.jwt() ->> 'role' = 'service' OR 
    auth.uid() = id
  );

CREATE POLICY "service_access_policies" ON policies
  FOR ALL USING (
    auth.jwt() ->> 'role' = 'service' OR 
    user_id = auth.uid()
  );

-- 4. VERIFY FIX
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
