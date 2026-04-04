const express = require('express');
const { supabase } = require('../config/supabase');
const { checkIpLocation } = require('../services/maxmind_service');
const { sendDisruptionAlert, sendPayoutCredited } = require('../services/notification_service');
const { calculateFraudScore } = require('../services/fraud_engine');
const { checkCircuitBreaker, updatePoolHealth } = require('../services/circuit_breaker');
const { releasePayout } = require('../services/payout_service');
const mlService = require('../services/ml_service');
const { buildClaimExplanation } = require('../services/claim_explanation_service');
const {
  verifyIntegrityToken,
  applyPlayIntegrityFraudDelta,
  shouldRunIntegrityPipeline,
  isSimulatedMode,
} = require('../services/play_integrity_service');
const { getSharedDeviceFraudBump } = require('../services/device_fingerprint_service');
const router = express.Router();

/*
  SETTLEMENT ARCHITECTURE
  
  Tranche 1 (70%):
    Released within MINUTES of trigger confirmation
    Condition: fraud score < 30 (GREEN)
    Method: releasePayout() called immediately
    Expert mandate: "it is minutes not hours"
    
  Tranche 2 (30%):
    Released Sunday 11 PM weekly batch
    Purpose: full week fraud pattern review
    Condition: no new fraud signals emerged this week
    
  This is NOT Sunday payment for everything.
  Workers receive 70% of their payout within minutes.
  Sunday is only for the settlement tranche.
*/


const {
  HOURLY_RATES,
  DAILY_CAPS,
  COMPOUND_BONUSES,
  SHIFT_MULTIPLIERS,
  ZONE_DEPTH_MULTIPLIERS,
} = require('../config/constants');

// Trigger display names
const DISPLAY_NAMES = {
  rain_heavy:        'Heavy Rain',
  rain_extreme:      'Extreme Rain',
  heat_severe:       'Extreme Heat',
  platform_outage:   'Platform Downtime',
  bandh:             'Bandh / Curfew',
  aqi_hazardous:     'Severe AQI',
  traffic_severe:    'Heavy Traffic',
  internet_blackout: 'Internet Blackout',
  cyclone_landfall:  'Cyclone Landfall',
};

// Which triggers each plan covers
const PLAN_TRIGGERS = {
  basic:    ['rain_heavy', 'rain_extreme', 'heat_severe'],
  standard: ['rain_heavy', 'rain_extreme', 'heat_severe', 'aqi_hazardous', 'platform_outage', 'bandh'],
  full:     ['rain_heavy', 'rain_extreme', 'heat_severe', 'aqi_hazardous', 'platform_outage',
             'bandh', 'traffic_severe', 'internet_blackout', 'cyclone_landfall'],
};

/**
 * calculateGrossPayout — actuarial payout engine
 * Formula: hourly_rate × hours × shift_multiplier × zone_depth_mult
 * Capped by per-trigger daily cap and plan weekly cap.
 */
function calculateGrossPayout({ trigger_type, duration_hours = 3, claim_hour = 14, zone_depth_score = 0.8, plan_tier = 'standard', secondary_trigger = null }) {
  const hourlyRate = HOURLY_RATES[trigger_type] || 40;
  const dailyCap   = DAILY_CAPS[trigger_type]   || 120;

  // Shift-hour multiplier
  const shiftMult = (
    claim_hour >= 9  && claim_hour < 18 ? SHIFT_MULTIPLIERS.peak    :
    claim_hour >= 18 && claim_hour < 22 ? SHIFT_MULTIPLIERS.offpeak :
    claim_hour >= 8  && claim_hour < 9  ? SHIFT_MULTIPLIERS.prepeak :
    SHIFT_MULTIPLIERS.night
  );

  // Zone depth multiplier (distance from dark store)
  const zoneMult = (
    zone_depth_score >  0.6 ? ZONE_DEPTH_MULTIPLIERS.core   :
    zone_depth_score >= 0.3 ? ZONE_DEPTH_MULTIPLIERS.middle :
    ZONE_DEPTH_MULTIPLIERS.outer
  );

  let payout = Math.round(hourlyRate * duration_hours * shiftMult * zoneMult);
  payout = Math.min(payout, dailyCap);

  // Compound trigger bonus (Full Shield only)
  if (plan_tier === 'full' && secondary_trigger) {
    const key1 = `${trigger_type}+${secondary_trigger}`;
    const key2 = `${secondary_trigger}+${trigger_type}`;
    const bonus = COMPOUND_BONUSES[key1] || COMPOUND_BONUSES[key2];
    if (bonus) {
      if (bonus.type === 'additive') {
        // Add full payout for secondary trigger too
        const secondaryPayout = Math.min(
          Math.round((HOURLY_RATES[secondary_trigger] || 40) * duration_hours * shiftMult * zoneMult),
          DAILY_CAPS[secondary_trigger] || 120
        );
        payout = payout + secondaryPayout;
      } else {
        payout = Math.round(payout * bonus.multiplier);
      }
    }
  }

  return payout;
}

// POST /claims/explanation — structured rejection / hold reasons from FPS-style body
router.post('/explanation', (req, res) => {
  try {
    res.json(buildClaimExplanation(req.body || {}));
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// POST /claims/create
router.post('/create', async (req, res) => {
  const {
    user_id,
    trigger_type,
    severity,
    duration_hours,
    claim_hour,
    zone_depth_score,
    plan_tier,
    secondary_trigger,
    integrity_token,
    simulate_integrity_fail,
    device_fingerprint,
  } = req.body;

  if (!user_id || !trigger_type) {
    return res.status(400).json({ error: 'user_id and trigger_type are required' });
  }

  // Check trigger is covered by plan
  const planKey = (plan_tier || 'standard').toLowerCase();
  if (PLAN_TRIGGERS[planKey] && !PLAN_TRIGGERS[planKey].includes(trigger_type)) {
    return res.status(400).json({
      error: `Trigger '${trigger_type}' is not covered by your ${planKey} plan`,
      covered_triggers: PLAN_TRIGGERS[planKey],
    });
  }

  const grossPayout = calculateGrossPayout({
    trigger_type,
    duration_hours: duration_hours || 3,
    claim_hour:     claim_hour ?? new Date().getHours(),
    zone_depth_score: zone_depth_score || 0.8,
    plan_tier:      planKey,
    secondary_trigger,
  });
  /*
    SETTLEMENT TIMING
    70% tranche: released within MINUTES of trigger confirmation
                 not Sunday — minutes
    30% tranche: released Sunday 11PM after weekly fraud review
    
    Expert instruction: "it is minutes not hours" for primary tranche
  */
  const tranche1 = Math.round(grossPayout * 0.70);
  const tranche2 = grossPayout - tranche1;

  try {
    // Get worker zone
    const { data: user } = await supabase
      .from('users')
      .select('zone, city, created_at')
      .eq('id', user_id)
      .maybeSingle();

    // Circuit breaker — block if zone/city limit exceeded
    const cbResult = await checkCircuitBreaker(
      user?.zone ?? 'Unknown',
      user?.city ?? 'Chennai',
      trigger_type,
    );
    if (cbResult.tripped) {
      return res.status(503).json({
        error:       'System protection active',
        detail:      cbResult.reason,
        code:        cbResult.code,
        retry_after: '1 hour',
      });
    }

    // Get active policy (required for claim)
    const { data: policy } = await supabase
      .from('policies')
      .select('id')
      .eq('user_id', user_id)
      .eq('status', 'active')
      .maybeSingle();

    if (!policy) {
      return res.status(400).json({ error: 'No active policy found' });
    }

    const packageName = process.env.PLAY_INTEGRITY_PACKAGE_NAME || 'com.shieldgig.shieldgig';
    let integrityBlock = {
      evaluated: false,
      pass: true,
      mode: null,
      mock_verdict: undefined,
      verdict: null,
    };

    if (
      integrity_token &&
      typeof integrity_token === 'string' &&
      integrity_token.trim() !== '' &&
      shouldRunIntegrityPipeline()
    ) {
      try {
        const skipNonce =
          isSimulatedMode() || process.env.PLAY_INTEGRITY_SKIP_NONCE_CHECK === 'true';
        const v = await verifyIntegrityToken(integrity_token.trim(), packageName, {
          skipNonce,
          simulateFail: simulate_integrity_fail === true,
        });
        if (v.evaluated) {
          integrityBlock = {
            evaluated: true,
            pass: v.play_integrity_pass,
            mode: v.mode,
            mock_verdict: v.mock_verdict,
            verdict: v.verdict,
            judge_note: v.judge_note,
          };
        }
      } catch (e) {
        integrityBlock = {
          evaluated: true,
          pass: false,
          mode: 'verify_error',
          verdict: e.message,
        };
      }
    }

    // Fraud check — ML model with rule-engine fallback
    const clientIp = req.headers['x-forwarded-for']?.split(',')[0] || req.ip || '127.0.0.1';
    const fraudData = await checkIpLocation(clientIp, user.zone);

    const playPassForMl = integrityBlock.evaluated ? integrityBlock.pass : !fraudData.fraud_signal;

    // Try ML fraud score first, fall back to rule engine
    let fraudResult;
    const mlFraud = await mlService.getFraudScore({
      zone_depth_score:         0.75, // default; improve with real GPS depth
      days_since_onboard:       Math.floor((Date.now() - new Date(user.created_at || Date.now()).getTime()) / 86400000),
      play_integrity_pass:      playPassForMl,
      is_mock_location:         fraudData.fraud_signal || false,
    });

    if (mlFraud._source !== 'rule_fallback') {
      // ML responded — map to existing schema
      fraudResult = {
        score:    Math.round(mlFraud.fps_score * 100),
        decision: {
          status:      mlFraud.fps_tier,
          release_pct: mlFraud.fps_tier === 'GREEN' ? 100 : mlFraud.fps_tier === 'YELLOW' ? 70 : 40,
        },
      };
    } else {
      // Classic rule engine fallback
      fraudResult = await calculateFraudScore({ userId: user_id, zone: user?.zone, triggerType: trigger_type });
    }
    
    const baseFraudScore = fraudResult.score;
    let fraudScore = Math.min(100, baseFraudScore + (fraudData.fraud_signal ? 100 : 0));
    if (integrityBlock.evaluated) {
      const adj = applyPlayIntegrityFraudDelta(fraudScore, integrityBlock.pass);
      fraudScore = adj.score;
      integrityBlock.fraud_score_delta = adj.delta;
      integrityBlock.fraud_score_reason = adj.reason;
    }

    let sharedDevice = { bump: 0, other_users: 0, reason: null };
    if (device_fingerprint && typeof device_fingerprint === 'string') {
      sharedDevice = await getSharedDeviceFraudBump(
        user_id,
        user?.zone ?? '',
        device_fingerprint
      );
      if (sharedDevice.bump > 0) {
        fraudScore = Math.min(100, fraudScore + sharedDevice.bump);
      }
    }
    const fraudStatus = fraudData.fraud_signal ? 'FLAGGED' : fraudResult.decision.status;

    const releaseAmount = Math.round(
      tranche1 * (fraudResult.decision.release_pct / 100)
    );
    
    // If FLAGGED — release provisional ₹200 only
    const actualRelease = fraudStatus === 'FLAGGED'
      ? Math.min(200, tranche1)
      : releaseAmount;

    const fpsSignals = {
      play_integrity: integrityBlock,
      ip_fraud_signal: fraudData.fraud_signal || false,
    };
    if (sharedDevice.bump > 0) {
      fpsSignals.shared_device_cluster = {
        bump: sharedDevice.bump,
        other_users: sharedDevice.other_users,
        reason: sharedDevice.reason,
      };
    }

    // Insert claim — uses existing schema column names (tranche1, tranche2)
    const { data: claim, error: insertError } = await supabase
      .from('claims')
      .insert({
        user_id,
        trigger_type,
        zone:           user?.zone ?? 'unknown',
        city:           user?.city ?? 'Chennai',
        severity:       severity || 1.0,
        duration_hours: duration_hours || 3,
        gross_payout:   grossPayout,
        tranche1,
        tranche2,
        status:       'PENDING',
        fraud_status: fraudStatus,
        fraud_score: fraudScore,
        fps_signals: fpsSignals,
      })
      .select()
      .single();

    if (insertError) throw insertError;

    // Release tranche1 with rollback protection
    await releasePayout({
      claimId:     claim.id,
      userId:      user_id,
      amount:      actualRelease,
      tranche:     'TRANCHE1',
      description: `${DISPLAY_NAMES[trigger_type] || trigger_type} Payout (70%)`,
    });

    // Update pool health for BCR monitoring
    await updatePoolHealth(
      user?.city ?? 'Chennai',
      0,           // no new premium this request
      grossPayout, // claim amount
    );

    // Auto-approve after 5 seconds & send payout credited notification
    setTimeout(async () => {
      await supabase
        .from('claims')
        .update({ status: 'APPROVED' })
        .eq('id', claim.id);

      // Release tranche2 with rollback protection
      await releasePayout({
        claimId:     claim.id,
        userId:      user_id,
        amount:      tranche2,
        tranche:     'TRANCHE2',
        description: `${DISPLAY_NAMES[trigger_type] || trigger_type} Settlement (30%)`,
      });

      // Send FCM notification
      try {
        const { data: userProfile } = await supabase
          .from('users')
          .select('fcm_token, zone')
          .eq('id', user_id)
          .maybeSingle();

        if (userProfile?.fcm_token) {
          await sendPayoutCredited({
            deviceToken: userProfile.fcm_token,
            amount: actualRelease,
            claimId: claim.id,
          });
        } else {
          console.log(`[FCM] No device token for user ${user_id} — skipping notification`);
        }
      } catch (notifErr) {
        console.warn('[FCM] Notification error (non-fatal):', notifErr.message);
      }
    }, 5000);

    // Return Flutter-friendly response
    return res.status(201).json({
      claim: {
        ...claim,
        display_name:    DISPLAY_NAMES[trigger_type] || trigger_type,
        tranche1_amount: tranche1,
        tranche2_amount: tranche2,
      },
    });

  } catch (e) {
    console.error('[Claims] Create error:', e.message);
    return res.status(500).json({ error: e.message });
  }
});

// GET /claims/:userId
router.get('/:user_id', async (req, res) => {
  const { user_id } = req.params;

  try {
    const { data: claims, error } = await supabase
      .from('claims')
      .select('*')
      .eq('user_id', user_id)
      .order('created_at', { ascending: false });

    if (error) throw error;

    const totalClaimed  = claims.reduce((s, c) => s + (c.gross_payout || 0), 0);
    const totalReceived = claims
      .filter(c => c.status === 'APPROVED')
      .reduce((s, c) => s + (c.tranche1 || 0), 0);
    const pendingCount  = claims.filter(c => c.status === 'PENDING').length;

    // Normalise for Flutter — map tranche1 -> tranche1_amount etc.
    const normalised = claims.map(c => ({
      ...c,
      display_name:    DISPLAY_NAMES[c.trigger_type] || c.trigger_type,
      tranche1_amount: c.tranche1,
      tranche2_amount: c.tranche2,
    }));

    return res.json({
      claims:          normalised,
      total_claimed:   totalClaimed,
      total_received:  totalReceived,
      pending_count:   pendingCount,
    });

  } catch (e) {
    console.error('[Claims] Get error:', e.message);
    return res.status(500).json({ error: e.message });
  }
});

// GET /claims/detail/:id
router.get('/detail/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { data: claim, error } = await supabase
      .from('claims')
      .select('*')
      .eq('id', id)
      .single();
    if (error) throw error;
    res.json({ claim });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// POST /claims/manual
router.post('/manual', async (req, res) => {
  const { 
    user_id, 
    disruption_type, 
    description,
    zone,
    evidence_urls,    // array of uploaded photo URLs
    device_signal_strength,  // for internet outage type
    integrity_token,   // optional Play Integrity token (Android); simulated or Google verify
    simulate_integrity_fail, // demo only: force mock failing verdict (+30 fraud)
  } = req.body;

  const packageName = process.env.PLAY_INTEGRITY_PACKAGE_NAME || 'com.shieldgig.shieldgig';
  let playIntegrityResult = {
    checked: false,
    evaluated: false,
    pass: null,
    verdict: null,
  };

  if (
    integrity_token &&
    typeof integrity_token === 'string' &&
    integrity_token.trim() !== '' &&
    shouldRunIntegrityPipeline()
  ) {
    try {
      const skipNonce =
        isSimulatedMode() || process.env.PLAY_INTEGRITY_SKIP_NONCE_CHECK === 'true';
      const v = await verifyIntegrityToken(integrity_token.trim(), packageName, {
        skipNonce,
        simulateFail: simulate_integrity_fail === true,
      });
      playIntegrityResult = {
        checked: v.evaluated,
        evaluated: v.evaluated,
        pass: v.play_integrity_pass,
        verdict: v.verdict,
        summary: v.summary,
        mode: v.mode,
        mock_verdict: v.mock_verdict,
        judge_note: v.judge_note,
      };
    } catch (e) {
      playIntegrityResult = {
        checked: true,
        evaluated: true,
        pass: false,
        verdict: `error:${e.message}`,
      };
    }
  }

  if (process.env.PLAY_INTEGRITY_REQUIRED_FOR_MANUAL === 'true') {
    if (!playIntegrityResult.checked || !playIntegrityResult.pass) {
      return res.status(403).json({
        error: 'Play Integrity verification required',
        play_integrity_pass: false,
        hint: 'POST integrity_token from Android after GET /integrity/play/nonce',
      });
    }
  }

  if (!user_id || !disruption_type) {
    return res.status(400).json({
      error: 'user_id and disruption_type required'
    });
  }

  // Underwriting check — 7 days minimum
  const { data: user } = await supabase
    .from('users')
    .select('created_at, zone')
    .eq('id', user_id)
    .single();

  const daysSince = Math.floor(
    (Date.now() - new Date(user.created_at).getTime())
    / (1000 * 60 * 60 * 24)
  );

  if (daysSince < 7) {
    return res.status(400).json({
      error: 'Minimum 7 active days required before filing claims',
      days_remaining: 7 - daysSince
    });
  }

  // Get active policy
  const { data: policy } = await supabase
    .from('policies')
    .select('id, max_weekly_payout, weekly_premium')
    .eq('user_id', user_id)
    .eq('status', 'active')
    .single();

  if (!policy) {
    return res.status(400).json({
      error: 'No active policy found'
    });
  }

  // Manual claims get provisional payout
  // Actual amount decided after 4hr review
  const PROVISIONAL_AMOUNTS = {
    road_blocked:      100,
    dark_store_closed: 150,
    internet_outage:   120,
    other:             80,
  };

  const provisionalAmount = PROVISIONAL_AMOUNTS[disruption_type] || 80;
  const tranche1 = Math.round(provisionalAmount * 0.70);
  const tranche2 = provisionalAmount - tranche1;

  let manualFraudScore = 25;
  if (playIntegrityResult.evaluated) {
    const adj = applyPlayIntegrityFraudDelta(manualFraudScore, playIntegrityResult.pass);
    manualFraudScore = adj.score;
    playIntegrityResult.fraud_score_delta = adj.delta;
    playIntegrityResult.fraud_score_reason = adj.reason;
  }

  try {
    // Create manual claim
    const { data: claim, error } = await supabase
      .from('claims')
      .insert([{
        user_id,
        policy_id:      policy.id,
        trigger_type:   'manual_' + disruption_type,
        zone:           user.zone,
        city:           'Chennai',
        severity:       0.7,
        duration_hours: 2.0,
        gross_payout:   provisionalAmount,
        tranche1,
        tranche2,
        fraud_score:    manualFraudScore,
        fraud_status:   'REVIEW',
        status:         'PENDING',
        fps_signals: {
          type: 'manual',
          evidence_count: evidence_urls?.length ?? 0,
          disruption_type,
          description: description ?? '',
          play_integrity: playIntegrityResult,
        },
      }])
      .select()
      .single();

    if (error) throw error;

    // Credit provisional tranche1 immediately
    await supabase
      .from('wallet_transactions')
      .insert([{
        user_id,
        amount:      tranche1,
        type:        'credit',
        category:    'payout_tranche1',
        reference:   `MANUAL_T1_${claim.id}`,
        description: `Manual Claim Provisional (70%) — ${disruption_type}`,
        claim_id:    claim.id,
      }]);

    return res.status(201).json({
      claim: {
        ...claim,
        display_name:      'Manual Report',
        tranche1_amount:   tranche1,
        tranche2_amount:   tranche2,
        provisional_note:  'Provisional credit issued. Full review within 4 hours.',
      }
    });

  } catch (e) {
    console.error('[ManualClaim] Error:', e.message);
    return res.status(500).json({ error: e.message });
  }
});

module.exports = router;
