-- RLS SECURITY TESTING SCRIPT
-- Test proper row-level security policies

-- Test 1: User can only access their own data
-- Set up test user context (simulate user with UUID)
-- This would be run with actual JWT token in production

-- Test user-owned data access
SELECT 'Testing user-owned data access' as test_case;

-- Users should only see their own profile
SELECT COUNT(*) as own_user_records 
FROM users 
WHERE id = auth.uid();

-- Policies should only show user's own policies
SELECT COUNT(*) as own_policy_records 
FROM policies 
WHERE user_id = auth.uid();

-- Claims should only show user's own claims
SELECT COUNT(*) as own_claim_records 
FROM claims 
WHERE user_id = auth.uid();

-- Wallet transactions should only show user's own transactions
SELECT COUNT(*) as own_wallet_records 
FROM wallet_transactions 
WHERE user_id = auth.uid();

-- Test 2: Service role can access all data
-- This would be run with service_role JWT

SELECT 'Testing service role access' as test_case;

-- Service role should see all users
SELECT COUNT(*) as total_users FROM users;

-- Service role should see all policies
SELECT COUNT(*) as total_policies FROM policies;

-- Service role should see all claims
SELECT COUNT(*) as total_claims FROM claims;

-- Test 3: Public data is accessible to all
SELECT 'Testing public data access' as test_case;

-- Risk pools should be publicly readable
SELECT COUNT(*) as risk_pool_count FROM risk_pools;

-- Disruption events should be publicly readable
SELECT COUNT(*) as disruption_count FROM disruption_events;

-- Pool health should be publicly readable
SELECT COUNT(*) as pool_health_count FROM pool_health;

-- Test 4: Cross-user data access is blocked
SELECT 'Testing cross-user access prevention' as test_case;

-- User should not be able to access another user's data
SELECT COUNT(*) as other_user_data 
FROM users 
WHERE id != auth.uid();

-- User should not be able to access other user's policies
SELECT COUNT(*) as other_policy_data 
FROM policies 
WHERE user_id != auth.uid();

-- Test 5: Related data access through relationships
SELECT 'Testing relationship-based access' as test_case;

-- User should access riders through their policies
SELECT COUNT(*) as accessible_riders
FROM riders r
JOIN policies p ON r.policy_id = p.id
WHERE p.user_id = auth.uid();

-- User should access appeals through their claims
SELECT COUNT(*) as accessible_appeals
FROM appeal_requests ar
JOIN claims c ON ar.claim_id = c.id
WHERE c.user_id = auth.uid();

-- Test 6: Admin-only tables are restricted
SELECT 'Testing admin-only restrictions' as test_case;

-- Regular users should not access admin actions
SELECT COUNT(*) as admin_action_access
FROM admin_actions;

-- Regular users should not access cron logs
SELECT COUNT(*) as cron_log_access
FROM cron_execution_logs;

-- Test 7: Service role override capabilities
SELECT 'Testing service role override' as test_case;

-- Service role should bypass user restrictions
SELECT COUNT(*) as service_full_access
FROM admin_actions;

-- Service role should access all telemetry
SELECT COUNT(*) as service_telemetry_access
FROM shift_telemetry;

-- Test 8: Policy inheritance and cascading access
SELECT 'Testing policy inheritance' as test_case;

-- Renewal history access through policy ownership
SELECT COUNT(*) as renewal_history_access
FROM renewal_history rh
JOIN policies p ON rh.policy_id = p.id
WHERE p.user_id = auth.uid();

-- Test 9: JWT role verification
SELECT 'Testing JWT role verification' as test_case;

-- Check current user role
SELECT auth.jwt() ->> 'role' as current_role;

-- Verify service role policies work
SELECT COUNT(*) as service_role_data
FROM users 
WHERE auth.jwt() ->> 'role' = 'service_role';

-- Test 10: Performance impact of RLS
SELECT 'Testing RLS performance impact' as test_case;

-- Time queries with RLS enabled
EXPLAIN ANALYZE SELECT * FROM users WHERE id = auth.uid();
EXPLAIN ANALYZE SELECT * FROM policies WHERE user_id = auth.uid();
EXPLAIN ANALYZE SELECT * FROM claims WHERE user_id = auth.uid();

-- Test 11: Edge cases and boundary conditions
SELECT 'Testing edge cases' as test_case;

-- NULL user ID handling
SELECT COUNT(*) as null_user_data
FROM users 
WHERE id IS NULL;

-- Empty result sets
SELECT COUNT(*) as empty_results
FROM policies 
WHERE user_id = '00000000-0000-0000-0000-000000000000';

-- Test 12: Security policy coverage
SELECT 'Testing security policy coverage' as test_case;

-- Verify all tables have RLS enabled
SELECT schemaname, tablename, rowsecurity
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN (
    'users','auth_sessions','risk_pools','policies','riders','claims','appeal_requests',
    'wallet_transactions','wallet_balance_snapshots','disruption_events','shadow_policies',
    'fraud_baselines','fraud_flags','fraud_signal_logs','device_fingerprint_events',
    'shift_telemetry','shift_gaps','shift_summary','pending_frs_adjustments',
    'trust_events','notifications','referrals','renewal_history','cashback_payouts',
    'pool_health','circuit_breakers','weekly_settlements','reinsurance_triggers',
    'work_advisor_logs','cron_execution_logs','admin_actions','regional_intelligence_snapshots'
  )
ORDER BY tablename;

-- Verify policies exist for each table
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
