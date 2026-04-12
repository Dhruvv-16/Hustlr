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

    // Calculate dynamic premium with activity loading
    const breakdown = calculatePremium(plan_tier, user.iss_score, user.zone, {
      active_days_last_30: user.active_days_last_30 ?? 25,
    });

    // ── Dynamic Temporal Surcharging ──
    const now = new Date();
    const currentMonth = now.getMonth() + 1; // 1-12
    let monsoonSurchargePct = 0;
    
    if (currentMonth >= 6 && currentMonth <= 9) {
      monsoonSurchargePct = 0.15;
    } else if (currentMonth >= 10 && currentMonth <= 12) {
      monsoonSurchargePct = 0.22; // Cyclone season
    }

    // ── Forward-Risk Surcharge via Prophet ──
    let forwardRiskPct = 0;
    try {
      const ML_URL = process.env.ML_SERVICE_URL || 'http://127.0.0.1:8000';
      const zoneStr = user.zone || 'TN_CHENNAI';
      const forecastRes = await fetch(`${ML_URL}/forecast/${zoneStr}?days=7`, { signal: AbortSignal.timeout(3000) });
      
      if (forecastRes.ok) {
        const forecastData = await forecastRes.json();
        const highRisk = forecastData.forecasts?.some(f => (f.disruption_probability || 0) > 0.7);
        if (highRisk) {
          forwardRiskPct = 0.08;
          console.log(`[Policy] High risk weather forecast detected for ${zoneStr}. Applying +8% forward risk.`);
        }
      }
    } catch (_) {
      console.warn('[Policy] ML Forecast unavailable, defaulting to 0% forward risk.');
    }

    const baseForSurcharge = breakdown.final_premium;
    const monsoonAmount = Math.round(baseForSurcharge * monsoonSurchargePct);
    const forwardRiskAmount = Math.round(baseForSurcharge * forwardRiskPct);
    
    const finalPremiumWithSurcharge = baseForSurcharge + monsoonAmount + forwardRiskAmount;

    // Deactivate any existing active policy for this user first
    await supabase
      .from('policies')
      .update({ status: 'cancelled' })
      .eq('user_id', user_id)
      .eq('status', 'active');

    // Make sure 'surcharge_breakdown' exists or just put it in a known column if not.
    // For now we will insert the updated premium.
    const { data: policy, error: policyError } = await supabase
      .from('policies')
      .insert([{
        user_id,
        plan_tier,
        base_premium:     breakdown.base_premium,
        zone_adjustment:  breakdown.zone_adjustment,
        iss_adjustment:   breakdown.iss_adjustment,
        weekly_premium:   finalPremiumWithSurcharge,
        max_weekly_payout: PLAN_CONFIG[plan_tier].max_payout,
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
        amount: finalPremiumWithSurcharge,
        type: 'debit',
        description: `Premium for ${plan_tier} Shield`,
        reference: `policy_${policy.id}`,
      }]);

    // Log the surcharge breakdown explicitly
    console.log(`[Policy] Created policy ${policy.id} w/ Monsoon: ₹${monsoonAmount}, ForwardRisk: ₹${forwardRiskAmount}`);

    res.json({
      policy,
      premium_breakdown: {
        ...breakdown,
        monsoon_surcharge_pct: monsoonSurchargePct,
        monsoon_surcharge: monsoonAmount,
        forward_risk_pct: forwardRiskPct,
        forward_risk_surcharge: forwardRiskAmount,
        final_with_surcharge: finalPremiumWithSurcharge,
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
    if (!UUID_RE.test(user_id)) return res.status(200).json({ policy: null });
    const { data: policy, error } = await supabase
      .from('policies')
      .select('*')
      .eq('user_id', user_id)
      .eq('status', 'active')
      .maybeSingle();
    if (error) throw error;
    res.json({ policy });
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
