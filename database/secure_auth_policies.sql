-- ============================================================
-- SECURE AUTHENTICATION POLICIES
-- Add these to your schema AFTER the existing policies
-- ============================================================

-- 1. SECURE USER ACCESS (Users can only access their own data)
DROP POLICY IF EXISTS "allow_all" ON users;
CREATE POLICY "users_read_own" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "users_update_own" ON users
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "users_insert_own" ON users
  FOR INSERT WITH CHECK (auth.uid() = id);

-- 2. SECURE POLICY ACCESS
DROP POLICY IF EXISTS "allow_all" ON policies;
CREATE POLICY "policies_read_own" ON policies
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "policies_update_own" ON policies
  FOR UPDATE USING (user_id = auth.uid());

-- 3. SECURE CLAIMS ACCESS
DROP POLICY IF EXISTS "allow_all" ON claims;
CREATE POLICY "claims_read_own" ON claims
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "claims_update_own" ON claims
  FOR UPDATE USING (user_id = auth.uid());

-- 4. SECURE WALLET ACCESS
DROP POLICY IF EXISTS "allow_all" ON wallet_transactions;
CREATE POLICY "wallet_read_own" ON wallet_transactions
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "wallet_insert_own" ON wallet_transactions
  FOR INSERT WITH CHECK (user_id = auth.uid());

-- 5. KEEP DISRUPTION EVENTS PUBLIC (OK for public visibility)
DROP POLICY IF EXISTS "allow_all" ON disruption_events;
CREATE POLICY "disruptions_public" ON disruption_events
  FOR SELECT USING (true);

-- 6. SERVICE ROLE ACCESS (for backend APIs)
CREATE POLICY "service_access_users" ON users
  FOR ALL USING (
    auth.jwt() ->> 'role' = 'service' OR 
    auth.uid() = id
  );

CREATE POLICY "service_access_policies" ON policies
  FOR ALL USING (
    auth.jwt() ->> 'role' = 'service' OR 
    user_id = auth.uid()
  );

CREATE POLICY "service_access_claims" ON claims
  FOR ALL USING (
    auth.jwt() ->> 'role' = 'service' OR 
    user_id = auth.uid()
  );

-- 7. ADD SECURE POLICIES (run AFTER schema creation)
-- These should be added AFTER your main schema.sql completes

-- 1. SECURE USER ACCESS (Users can only access their own data)
DROP POLICY IF EXISTS "allow_all" ON users;
CREATE POLICY "users_read_own" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "users_update_own" ON users
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "users_insert_own" ON users
  FOR INSERT WITH CHECK (auth.uid() = id);

-- 2. SECURE POLICY ACCESS
DROP POLICY IF EXISTS "allow_all" ON policies;
CREATE POLICY "policies_read_own" ON policies
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "policies_update_own" ON policies
  FOR UPDATE USING (user_id = auth.uid());

-- 3. SECURE CLAIMS ACCESS
DROP POLICY IF EXISTS "allow_all" ON claims;
CREATE POLICY "claims_read_own" ON claims
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "claims_update_own" ON claims
  FOR UPDATE USING (user_id = auth.uid());

-- 4. SECURE WALLET ACCESS
DROP POLICY IF EXISTS "allow_all" ON wallet_transactions;
CREATE POLICY "wallet_read_own" ON wallet_transactions
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "wallet_insert_own" ON wallet_transactions
  FOR INSERT WITH CHECK (user_id = auth.uid());

-- 5. KEEP DISRUPTION EVENTS PUBLIC (OK for public visibility)
DROP POLICY IF EXISTS "allow_all" ON disruption_events;
CREATE POLICY "disruptions_public" ON disruption_events
  FOR SELECT USING (true);

-- 6. SERVICE ROLE ACCESS (for backend APIs)
CREATE POLICY "service_access_users" ON users
  FOR ALL USING (
    auth.jwt() ->> 'role' = 'service' OR 
    auth.uid() = id
  );

CREATE POLICY "service_access_policies" ON policies
  FOR ALL USING (
    auth.jwt() ->> 'role' = 'service' OR 
    user_id = auth.uid()
  );

CREATE POLICY "service_access_claims" ON claims
  FOR ALL USING (
    auth.jwt() ->> 'role' = 'service' OR 
    user_id = auth.uid()
  );

-- 7. VERIFY SECURE POLICIES
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
  AND policyname NOT LIKE '%allow_all%'
ORDER BY tablename, policyname;
