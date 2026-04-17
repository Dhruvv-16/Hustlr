-- ═════════════════════════════════════════════════════════════
-- HUSTLER — PRE-MIGRATION VALIDATION SCRIPT
-- Run this BEFORE applying the improved schema to identify data issues
-- ═════════════════════════════════════════════════════════════

-- 1. Check for existing constraint violations
SELECT '=== ACTUARIAL VIOLATIONS ===' as check_type;
SELECT 
    'Active policies past coverage_end' as issue,
    COUNT(*) as count,
    STRING_AGG(id::TEXT, ', ') as policy_ids
FROM policies 
WHERE status = 'active' AND coverage_end < CURRENT_DATE;

SELECT 
    'Riders in policies table (legacy data)' as issue,
    COUNT(*) as count
FROM policies 
WHERE riders IS NOT NULL AND jsonb_array_length(riders::jsonb) > 0;

-- 2. Financial math violations
SELECT '=== FINANCIAL VIOLATIONS ===' as check_type;
SELECT 
    'Claims with tranche math errors' as issue,
    COUNT(*) as count,
    STRING_AGG(id::TEXT, ', ') as claim_ids
FROM claims 
WHERE tranche1 + tranche2 != gross_payout;

SELECT 
    'Claims exceeding policy limits' as issue,
    COUNT(*) as count,
    STRING_AGG(claims.id::TEXT, ', ') as claim_ids
FROM claims 
JOIN policies ON claims.policy_id = policies.id 
WHERE claims.gross_payout > policies.max_weekly_payout;

SELECT 
    'Wallet transaction sign violations' as issue,
    COUNT(*) as count,
    STRING_AGG(id::TEXT, ', ') as transaction_ids
FROM wallet_transactions 
WHERE (type = 'credit' AND amount < 0) OR (type = 'debit' AND amount > 0);

-- 3. Trust score consistency
SELECT '=== TRUST SCORE VIOLATIONS ===' as check_type;
SELECT 
    'Trust score/tier mismatches' as issue,
    COUNT(*) as count,
    STRING_AGG(id::TEXT, ', ') as user_ids
FROM users 
WHERE 
    (trust_score >= 90 AND trust_tier != 'PLATINUM') OR
    (trust_score >= 75 AND trust_score < 90 AND trust_tier != 'GOLD') OR
    (trust_score >= 60 AND trust_score < 75 AND trust_tier != 'SILVER') OR
    (trust_score >= 50 AND trust_score < 60 AND trust_tier != 'BRONZE') OR
    (trust_score < 50 AND trust_tier != 'AT_RISK');

-- 4. Data quality issues
SELECT '=== DATA QUALITY VIOLATIONS ===' as check_type;
SELECT 
    'Null critical fields' as issue,
    COUNT(*) as count
FROM claims 
WHERE user_id IS NULL OR trigger_type IS NULL OR zone IS NULL;

SELECT 
    'Future timestamps' as issue,
    COUNT(*) as count
FROM claims 
WHERE created_at > NOW();

SELECT 
    'Negative durations' as issue,
    COUNT(*) as count
FROM shift_gaps 
WHERE gap_end IS NOT NULL AND gap_end < gap_start;

-- 5. Performance impact assessment
SELECT '=== PERFORMANCE ASSESSMENT ===' as check_type;
SELECT 
    'Shift telemetry rows' as table_name,
    COUNT(*) as row_count,
    ROUND(COUNT(*) / 1000000.0, 2) as millions_of_rows
FROM shift_telemetry;

SELECT 
    'Claims table size' as table_name,
    COUNT(*) as row_count,
    ROUND(COUNT(*) / 1000000.0, 2) as millions_of_rows
FROM claims;

SELECT 
    'Wallet transactions' as table_name,
    COUNT(*) as row_count,
    ROUND(COUNT(*) / 1000000.0, 2) as millions_of_rows
FROM wallet_transactions;

-- 6. Index effectiveness
SELECT '=== INDEX EFFECTIVENESS ===' as check_type;
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes 
WHERE schemaname = 'public' 
ORDER BY idx_scan DESC, idx_tup_read DESC 
LIMIT 10;

-- 7. Summary report
SELECT '=== VALIDATION SUMMARY ===' as check_type;
SELECT 
    'Total Issues Found' as metric,
    (SELECT COUNT(*) FROM policies WHERE status = 'active' AND coverage_end < CURRENT_DATE) +
    (SELECT COUNT(*) FROM claims WHERE tranche1 + tranche2 != gross_payout) +
    (SELECT COUNT(*) FROM users WHERE 
        (trust_score >= 90 AND trust_tier != 'PLATINUM') OR
        (trust_score >= 75 AND trust_score < 90 AND trust_tier != 'GOLD') OR
        (trust_score >= 60 AND trust_score < 75 AND trust_tier != 'SILVER') OR
        (trust_score < 50 AND trust_tier != 'AT_RISK')
    ) as value
UNION ALL
SELECT 
    'Data Quality Score' as metric,
    ROUND(
        (1.0 - 
        (SELECT COUNT(*) FROM claims WHERE user_id IS NULL OR trigger_type IS NULL) / 
        NULLIF((SELECT COUNT(*) FROM claims), 0)
        ) * 100, 2
    ) as value
UNION ALL
SELECT 
    'Migration Risk' as metric,
    CASE 
        WHEN (SELECT COUNT(*) FROM policies WHERE status = 'active' AND coverage_end < CURRENT_DATE) > 0 THEN 'HIGH'
        WHEN (SELECT COUNT(*) FROM claims WHERE tranche1 + tranche2 != gross_payout) > 0 THEN 'HIGH'
        WHEN (SELECT COUNT(*) FROM users WHERE 
            (trust_score >= 90 AND trust_tier != 'PLATINUM') OR
            (trust_score >= 75 AND trust_score < 90 AND trust_tier != 'GOLD') OR
            (trust_score >= 60 AND trust_score < 75 AND trust_tier != 'SILVER') OR
            (trust_score < 50 AND trust_tier != 'AT_RISK')
        ) > 0 THEN 'MEDIUM'
        ELSE 'LOW'
    END as value;
