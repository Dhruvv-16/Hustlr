const express = require('express');
const router = express.Router();
const { supabase } = require('../services/supabase');
const { authMiddleware } = require('../middleware/auth');

// Admin middleware - only service role can access
const adminMiddleware = (req, res, next) => {
  const userRole = req.user?.role;
  if (userRole !== 'service_role') {
    return res.status(403).json({ error: 'Admin access required' });
  }
  next();
};

// Get fraud queue - all claims needing review
router.get('/fraud-queue', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const { page = 1, limit = 20, status = 'FLAGGED' } = req.query;
    
    const { data: claims, error } = await supabase
      .from('claims')
      .select(`
        *,
        user:users(id, name, phone, trust_score, trust_tier),
        policy:policies(id, plan_tier, weekly_premium),
        fraud_signal_logs(signal_name, signal_value, weight, contribution)
      `)
      .eq('fraud_status', status)
      .order('created_at', { ascending: false })
      .range((page - 1) * limit, page * limit - 1);

    if (error) throw error;

    const { count } = await supabase
      .from('claims')
      .select('id', { count: 'exact', head: true })
      .eq('fraud_status', status);

    res.json({
      claims,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: count,
        pages: Math.ceil(count / limit)
      }
    });
  } catch (error) {
    console.error('Error fetching fraud queue:', error);
    res.status(500).json({ error: 'Failed to fetch fraud queue' });
  }
});

// Update fraud status
router.put('/fraud/:claimId/status', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const { claimId } = req.params;
    const { status, adminNote } = req.body;

    // Validate status
    const validStatuses = ['CLEAN', 'REVIEW', 'FLAGGED', 'REJECTED'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ error: 'Invalid fraud status' });
    }

    const { data, error } = await supabase
      .from('claims')
      .update({ 
        fraud_status: status,
        updated_at: new Date().toISOString()
      })
      .eq('id', claimId)
      .select()
      .single();

    if (error) throw error;

    // Log admin action
    await supabase
      .from('admin_actions')
      .insert({
        admin_id: req.user.id,
        action_type: 'flag_claim',
        target_type: 'claim',
        target_id: claimId,
        reason: adminNote || `Fraud status updated to ${status}`,
        metadata: { old_status: data.fraud_status, new_status: status }
      });

    res.json({ success: true, claim: data });
  } catch (error) {
    console.error('Error updating fraud status:', error);
    res.status(500).json({ error: 'Failed to update fraud status' });
  }
});

// Get payout queue - claims approved but not paid
router.get('/payout-queue', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const { page = 1, limit = 20, status = 'APPROVED' } = req.query;
    
    const { data: claims, error } = await supabase
      .from('claims')
      .select(`
        *,
        user:users(id, name, phone, trust_score),
        policy:policies(id, plan_tier, max_weekly_payout),
        wallet_transactions(amount, type, category, created_at)
      `)
      .eq('status', status)
      .order('created_at', { ascending: false })
      .range((page - 1) * limit, page * limit - 1);

    if (error) throw error;

    const { count } = await supabase
      .from('claims')
      .select('id', { count: 'exact', head: true })
      .eq('status', status);

    res.json({
      claims,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: count,
        pages: Math.ceil(count / limit)
      }
    });
  } catch (error) {
    console.error('Error fetching payout queue:', error);
    res.status(500).json({ error: 'Failed to fetch payout queue' });
  }
});

// Process payout
router.post('/payout/:claimId/process', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const { claimId } = req.params;
    const { paymentMethod, upiRef } = req.body;

    // Get claim details
    const { data: claim, error: claimError } = await supabase
      .from('claims')
      .select('*, user_id, gross_payout, tranche1, tranche2')
      .eq('id', claimId)
      .single();

    if (claimError) throw claimError;

    if (claim.status !== 'APPROVED') {
      return res.status(400).json({ error: 'Claim not approved for payout' });
    }

    // Process in transaction
    const { data, error } = await supabase.rpc('process_claim_payout', {
      p_claim_id: claimId,
      p_payment_method: paymentMethod,
      p_upi_ref: upiRef
    });

    if (error) throw error;

    // Log admin action
    await supabase
      .from('admin_actions')
      .insert({
        admin_id: req.user.id,
        action_type: 'manual_payout',
        target_type: 'claim',
        target_id: claimId,
        reason: `Manual payout processed via ${paymentMethod}`,
        metadata: { amount: claim.gross_payout, upi_ref: upiRef }
      });

    res.json({ success: true, payout: data });
  } catch (error) {
    console.error('Error processing payout:', error);
    res.status(500).json({ error: 'Failed to process payout' });
  }
});

// Get user trust scores
router.get('/trust-scores', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const { page = 1, limit = 50, tier, minScore, maxScore } = req.query;
    
    let query = supabase
      .from('users')
      .select(`
        id, name, phone, trust_score, trust_tier, clean_weeks,
        claims:claims(count),
        policies:policies(count)
      `)
      .order('trust_score', { ascending: false });

    // Apply filters
    if (tier) query = query.eq('trust_tier', tier);
    if (minScore) query = query.gte('trust_score', minScore);
    if (maxScore) query = query.lte('trust_score', maxScore);

    const { data: users, error } = await query
      .range((page - 1) * limit, page * limit - 1);

    if (error) throw error;

    res.json({
      users,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: users.length,
        pages: Math.ceil(users.length / limit)
      }
    });
  } catch (error) {
    console.error('Error fetching trust scores:', error);
    res.status(500).json({ error: 'Failed to fetch trust scores' });
  }
});

// Update user trust score
router.put('/trust/:userId/score', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const { userId } = req.params;
    const { score, reason } = req.body;

    if (score < 0 || score > 1000) {
      return res.status(400).json({ error: 'Score must be between 0 and 1000' });
    }

    const { data, error } = await supabase
      .from('users')
      .update({ 
        trust_score: score,
        updated_at: new Date().toISOString()
      })
      .eq('id', userId)
      .select()
      .single();

    if (error) throw error;

    // Log trust event
    await supabase
      .from('trust_events')
      .insert({
        user_id: userId,
        event_type: 'admin_adjustment',
        score_change: score - data.trust_score,
        new_score: score,
        reason: reason || 'Admin adjustment'
      });

    // Log admin action
    await supabase
      .from('admin_actions')
      .insert({
        admin_id: req.user.id,
        action_type: 'override_fraud',
        target_type: 'user',
        target_id: userId,
        reason: reason || 'Trust score manually adjusted',
        metadata: { old_score: data.trust_score, new_score: score }
      });

    res.json({ success: true, user: data });
  } catch (error) {
    console.error('Error updating trust score:', error);
    res.status(500).json({ error: 'Failed to update trust score' });
  }
});

// Get risk pool health
router.get('/risk-pools', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const { city, riskType } = req.query;
    
    let query = supabase
      .from('risk_pools')
      .select(`
        *,
        policies:policies(count),
        claims:claims(count),
        pool_health(week_start, premiums_collected, claims_paid, loss_ratio)
      `)
      .order('loss_ratio', { ascending: false });

    if (city) query = query.eq('city', city);
    if (riskType) query = query.eq('risk_type', riskType);

    const { data, error } = await query;

    if (error) throw error;

    res.json({ pools: data });
  } catch (error) {
    console.error('Error fetching risk pools:', error);
    res.status(500).json({ error: 'Failed to fetch risk pools' });
  }
});

// Adjust risk pool
router.put('/risk-pools/:poolId/adjust', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const { poolId } = req.params;
    const { adjustment, reason } = req.body;

    const { data, error } = await supabase
      .from('risk_pools')
      .update({ 
        reserve_fund: supabase.raw(`reserve_fund + ${adjustment}`),
        updated_at: new Date().toISOString()
      })
      .eq('id', poolId)
      .select()
      .single();

    if (error) throw error;

    // Log admin action
    await supabase
      .from('admin_actions')
      .insert({
        admin_id: req.user.id,
        action_type: 'adjust_pool',
        target_type: 'risk_pool',
        target_id: poolId,
        reason: reason || `Reserve fund adjusted by ${adjustment}`,
        metadata: { adjustment }
      });

    res.json({ success: true, pool: data });
  } catch (error) {
    console.error('Error adjusting risk pool:', error);
    res.status(500).json({ error: 'Failed to adjust risk pool' });
  }
});

// Get circuit breakers
router.get('/circuit-breakers', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const { zone, status } = req.query;
    
    let query = supabase
      .from('circuit_breakers')
      .select('*')
      .order('bcr_at_trip', { ascending: false });

    if (zone) query = query.eq('zone', zone);
    if (status) query = query.eq('tripped', status === 'tripped');

    const { data, error } = await query;

    if (error) throw error;

    res.json({ circuit_breakers: data });
  } catch (error) {
    console.error('Error fetching circuit breakers:', error);
    res.status(500).json({ error: 'Failed to fetch circuit breakers' });
  }
});

// Reset circuit breaker
router.put('/circuit-breakers/:cbId/reset', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const { cbId } = req.params;
    const { reason } = req.body;

    const { data, error } = await supabase
      .from('circuit_breakers')
      .update({ 
        tripped: false,
        reset_at: new Date().toISOString(),
        reason: reason || 'Manual reset by admin'
      })
      .eq('id', cbId)
      .select()
      .single();

    if (error) throw error;

    // Log admin action
    await supabase
      .from('admin_actions')
      .insert({
        admin_id: req.user.id,
        action_type: 'other',
        target_type: 'circuit_breaker',
        target_id: cbId,
        reason: reason || 'Circuit breaker manually reset'
      });

    res.json({ success: true, circuit_breaker: data });
  } catch (error) {
    console.error('Error resetting circuit breaker:', error);
    res.status(500).json({ error: 'Failed to reset circuit breaker' });
  }
});

// Get admin action logs
router.get('/action-logs', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const { page = 1, limit = 50, actionType, targetId, startDate, endDate } = req.query;
    
    let query = supabase
      .from('admin_actions')
      .select('*')
      .order('created_at', { ascending: false });

    if (actionType) query = query.eq('action_type', actionType);
    if (targetId) query = query.eq('target_id', targetId);
    if (startDate) query = query.gte('created_at', startDate);
    if (endDate) query = query.lte('created_at', endDate);

    const { data, error } = await query
      .range((page - 1) * limit, page * limit - 1);

    if (error) throw error;

    res.json({
      actions: data,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: data.length,
        pages: Math.ceil(data.length / limit)
      }
    });
  } catch (error) {
    console.error('Error fetching admin action logs:', error);
    res.status(500).json({ error: 'Failed to fetch admin action logs' });
  }
});

// Get system health metrics
router.get('/system-health', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const metrics = {};

    // User metrics
    const { data: userStats } = await supabase
      .from('users')
      .select('trust_tier', { count: 'exact' });

    metrics.users_by_tier = userStats?.reduce((acc, user) => {
      acc[user.trust_tier] = (acc[user.trust_tier] || 0) + 1;
      return acc;
    }, {});

    // Claim metrics
    const { data: claimStats } = await supabase
      .from('claims')
      .select('status, fraud_status', { count: 'exact' });

    metrics.claims_by_status = claimStats?.reduce((acc, claim) => {
      acc[claim.status] = (acc[claim.status] || 0) + 1;
      return acc;
    }, {});

    metrics.claims_by_fraud_status = claimStats?.reduce((acc, claim) => {
      acc[claim.fraud_status] = (acc[claim.fraud_status] || 0) + 1;
      return acc;
    }, {});

    // Policy metrics
    const { data: policyStats } = await supabase
      .from('policies')
      .select('plan_tier, status', { count: 'exact' });

    metrics.policies_by_tier = policyStats?.reduce((acc, policy) => {
      acc[policy.plan_tier] = (acc[policy.plan_tier] || 0) + 1;
      return acc;
    }, {});

    metrics.policies_by_status = policyStats?.reduce((acc, policy) => {
      acc[policy.status] = (acc[policy.status] || 0) + 1;
      return acc;
    }, {});

    // Risk pool metrics
    const { data: poolStats } = await supabase
      .from('risk_pools')
      .select('city, loss_ratio, active_policies');

    metrics.risk_pools = poolStats;

    // Recent activity
    const { data: recentClaims } = await supabase
      .from('claims')
      .select('id, created_at, gross_payout, fraud_status')
      .order('created_at', { ascending: false })
      .limit(10);

    metrics.recent_claims = recentClaims;

    res.json({ metrics });
  } catch (error) {
    console.error('Error fetching system health:', error);
    res.status(500).json({ error: 'Failed to fetch system health' });
  }
});

module.exports = router;
