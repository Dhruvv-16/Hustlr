const express = require('express');
const { supabase } = require('../config/supabase');
const { PLAN_CONFIG } = require('../config/constants');
const mlService = require('../services/ml_service');
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

    // Guard: mock IDs (offline onboarding) are not valid UUIDs — skip DB and return empty
    const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (!UUID_RE.test(user_id)) {
      return res.status(400).json({ error: 'Invalid user_id — please re-register with a live backend connection.' });
    }

    // Fetch user to get zone, iss_score, and active_days for loading
    const { data: user, error: userError } = await supabase
      .from('users')
      .select('zone, iss_score, active_days_last_30')
      .eq('id', user_id)
      .single();
    if (userError) throw userError;

    // Calculate premium via Python ML service
    const premiumResult = await mlService.getPremium({
      plan_tier,
      zone: user.zone,
      iss_score: 50,
      previous_premium: 0
    });

    const finalPremium = premiumResult.final_premium || 49;

    // Deactivate any existing active policy for this user first
    await supabase
      .from('policies')
      .update({ status: 'cancelled' })
      .eq('user_id', user_id)
      .eq('status', 'active');

    const { data: policy, error: policyError } = await supabase
      .from('policies')
      .insert([{
        user_id,
        plan_tier,
        base_premium:     premiumResult.base_premium || 49,
        zone_adjustment:  premiumResult.zone_adjustment || 0,
        iss_adjustment:   0,
        weekly_premium:   finalPremium,
        max_weekly_payout: PLAN_CONFIG[plan_tier]?.max_payout || 150,
        status: 'active'
      }])
      .select()
      .single();
    if (policyError) throw policyError;

    // Deduct the final premium from the user's wallet
    await supabase
      .from('wallet_transactions')
      .insert([{
        user_id,
        amount: finalPremium,
        type: 'debit',
        description: `Premium for ${plan_tier} Shield`,
        reference: `policy_${policy.id}`,
      }]);

    console.log(`[Policy] Created policy ${policy.id}. Premium calculated via Python AI: ₹${finalPremium}`);

    res.json({
      policy,
      premium_breakdown: {
        base_premium: premiumResult.base_premium || 49,
        zone_adjustment: premiumResult.zone_adjustment || 0,
        iss_adjustment: 0,
        monsoon_surcharge_pct: 0,
        monsoon_surcharge: 0,
        forward_risk_pct: 0,
        forward_risk_surcharge: 0,
        final_with_surcharge: finalPremium,
      },
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.get('/:user_id', async (req, res) => {
  try {
    const { user_id } = req.params;
    const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (!UUID_RE.test(user_id)) return res.status(200).json({ policy: null, history: [] });
    const { data: policy, error } = await supabase
      .from('policies')
      .select('*')
      .eq('user_id', user_id)
      .eq('status', 'active')
      .maybeSingle();
    if (error) throw error;
    const { data: history, error: historyError } = await supabase
      .from('policies')
      .select('*')
      .eq('user_id', user_id)
      .order('created_at', { ascending: false });
    if (historyError) throw historyError;
    res.json({ policy, history: history || [] });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.patch('/:id/upgrade', async (req, res) => {
  try {
    const { id } = req.params;
    const { new_plan_tier, risk_score = 0.5 } = req.body;

    const { data: existingPolicy, error: policyFetchError } = await supabase
      .from('policies')
      .select('user_id')
      .eq('id', id)
      .single();
    if (policyFetchError) throw policyFetchError;

    const { data: user, error: userError } = await supabase
      .from('users')
      .select('zone, iss_score')
      .eq('id', existingPolicy.user_id)
      .single();
    if (userError) throw userError;

    const premiumResult = await mlService.getPremium({
      plan_tier: new_plan_tier,
      zone: user.zone,
      iss_score: 50,
      previous_premium: existingPolicy.weekly_premium || 0
    });

    const { data: updated_policy, error: updateError } = await supabase
      .from('policies')
      .update({
        plan_tier: new_plan_tier,
        base_premium: premiumResult.base_premium || 49,
        zone_adjustment: premiumResult.zone_adjustment || 0,
        iss_adjustment: 0,
        weekly_premium: premiumResult.final_premium,
        max_weekly_payout: PLAN_CONFIG[new_plan_tier]?.max_payout || 150
      })
      .eq('id', id)
      .select()
      .single();

    if (updateError) throw updateError;

    res.json({ 
      updated_policy, 
      premium_breakdown: {
        base_premium: premiumResult.base_premium || 49,
        zone_adjustment: premiumResult.zone_adjustment || 0,
        iss_adjustment: 0,
        final_premium: premiumResult.final_premium,
        monsoon_surcharge_pct: 0,
        monsoon_surcharge: 0,
        forward_risk_pct: 0,
        forward_risk_surcharge: 0,
        final_with_surcharge: premiumResult.final_premium,
      } 
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
