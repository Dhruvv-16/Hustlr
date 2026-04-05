const express = require('express');
const { supabase } = require('../config/supabase');
const { calculatePremium } = require('../services/premiumCalculator');
const { PLAN_CONFIG } = require('../config/constants');
const router = express.Router();
const { getShadowSummary } = require('../services/shadow_policy_service');

// GET /policies/shadow/:user_id — live shadow payout estimate from disruption_events
router.get('/shadow/:user_id', async (req, res) => {
  try {
    const days = Math.min(90, Math.max(1, parseInt(req.query.days || '14', 10)));
    const out = await getShadowSummary(req.params.user_id, days);
    if (out.error === 'User not found') return res.status(404).json(out);
    if (out.error) return res.status(400).json(out);
    res.json(out);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.post('/create', async (req, res) => {
  try {
    const { user_id, plan_tier } = req.body;
    
    // Fetch user to get zone, iss_score, and active_days for loading
    const { data: user, error: userError } = await supabase
      .from('users')
      .select('zone, iss_score, active_days_last_30')
      .eq('id', user_id)
      .single();
    if (userError) throw userError;

    // Calculate dynamic premium with monsoon surcharge + activity loading
    const breakdown = calculatePremium(plan_tier, user.iss_score, user.zone, {
      active_days_last_30: user.active_days_last_30 ?? 25,
    });

    // Deactivate any existing active policy for this user first
    await supabase
      .from('policies')
      .update({ status: 'cancelled' })
      .eq('user_id', user_id)
      .eq('status', 'active');

    // Insert the new policy
    const { data: policy, error: policyError } = await supabase
      .from('policies')
      .insert([{
        user_id,
        plan_tier,
        base_premium: breakdown.base_premium,
        zone_adjustment: breakdown.zone_adjustment,
        iss_adjustment: breakdown.iss_adjustment,
        weekly_premium: breakdown.final_premium,
        max_weekly_payout: PLAN_CONFIG[plan_tier].max_payout, 
        status: 'active'
      }])
      .select()
      .single();
    if (policyError) throw policyError;

    res.json({ policy, premium_breakdown: breakdown });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.get('/:user_id', async (req, res) => {
  try {
    const { user_id } = req.params;
    const { data: policy, error } = await supabase
      .from('policies')
      .select('*')
      .eq('user_id', user_id)
      .eq('status', 'active')
      .single();
    if (error) throw error;
    res.json({ policy });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.patch('/:id/upgrade', async (req, res) => {
  try {
    const { id } = req.params;
    const { new_plan_tier } = req.body;

    const { data: existingPolicy, error: policyFetchError } = await supabase
      .from('policies')
      .select('user_id')
      .eq('id', id)
      .single();
    if (policyFetchError) throw policyFetchError;

    const { data: user, error: userError } = await supabase
      .from('users')
      .select('zone, iss_score, active_days_last_30')
      .eq('id', existingPolicy.user_id)
      .single();
    if (userError) throw userError;

    const breakdown = calculatePremium(new_plan_tier, user.iss_score, user.zone, {
      active_days_last_30: user.active_days_last_30 ?? 25,
    });

    const { data: updated_policy, error: updateError } = await supabase
      .from('policies')
      .update({
        plan_tier: new_plan_tier,
        base_premium: breakdown.base_premium,
        zone_adjustment: breakdown.zone_adjustment,
        iss_adjustment: breakdown.iss_adjustment,
        weekly_premium: breakdown.final_premium,
        max_weekly_payout: PLAN_CONFIG[new_plan_tier].max_payout
      })
      .eq('id', id)
      .select()
      .single();

    if (updateError) throw updateError;
    
    res.json({ updated_policy, premium_breakdown: breakdown });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
