const express = require('express');
const { supabase } = require('../config/supabase');
const { checkIpLocation } = require('../services/maxmind_service');
const { sendDisruptionAlert, sendPayoutCredited } = require('../services/notification_service');
const { initiateUpiPayout } = require('../services/instamojo_payout');
const router = express.Router();

const HOURLY_RATES = {
  rain_heavy:        50,
  rain_extreme:      65,
  extreme_heat:      40,
  platform_outage:   50,
  bandh:             50,
  aqi_severe:        40,
  traffic_severe:    40,
  internet_blackout: 50,
};

const DISPLAY_NAMES = {
  rain_heavy:        'Heavy Rain',
  rain_extreme:      'Extreme Rain',
  extreme_heat:      'Extreme Heat',
  platform_outage:   'Platform Downtime',
  bandh:             'Bandh / Curfew',
  aqi_severe:        'Severe Pollution',
  traffic_severe:    'Heavy Traffic',
  internet_blackout: 'Internet Blackout',
};

// POST /claims/create
router.post('/create', async (req, res) => {
  const { user_id, trigger_type, severity, duration_hours } = req.body;

  if (!user_id || !trigger_type) {
    return res.status(400).json({ error: 'user_id and trigger_type are required' });
  }

  const hourlyRate  = HOURLY_RATES[trigger_type] || 50;
  const grossPayout = Math.min(
    Math.round(hourlyRate * (duration_hours || 3) * (severity || 1.0)),
    150
  );
  const tranche1 = Math.round(grossPayout * 0.70);
  const tranche2 = grossPayout - tranche1;

  try {
    // Get worker zone
    const { data: user } = await supabase
      .from('users')
      .select('zone')
      .eq('id', user_id)
      .maybeSingle();

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

    // IP Geolocation Anti-Fraud Check
    const clientIp = req.headers['x-forwarded-for']?.split(',')[0] || req.ip || '127.0.0.1';
    const fraudData = await checkIpLocation(clientIp, user.zone);
    
    let fraudStatus = 'CLEAN';
    let fraudScore = 0;
    if (fraudData.fraud_signal) {
      fraudStatus = 'FLAGGED';
      fraudScore = 100;
    }

    // Insert claim — uses existing schema column names (tranche1, tranche2)
    const { data: claim, error: insertError } = await supabase
      .from('claims')
      .insert({
        user_id,
        trigger_type,
        severity: severity || 1.0,
        duration_hours: duration_hours || 3,
        gross_payout: grossPayout,
        tranche1,
        tranche2,
        status: 'PENDING',
        fraud_status: fraudStatus,
        fraud_score: fraudScore
      })
      .select()
      .single();

    if (insertError) throw insertError;

    // Insert wallet transaction
    const { error: walletError } = await supabase
      .from('wallet_transactions')
      .insert({
        user_id,
        type: 'CREDIT',
        amount: tranche1,
        description: `Advance payout for ${DISPLAY_NAMES[trigger_type] || trigger_type}`,
        status: 'COMPLETED'
      });

    if (walletError) throw walletError;

    // Auto-approve after 5 seconds, process payout, & send notification
    setTimeout(async () => {
      try {
        const { data: userProfile } = await supabase
          .from('users')
          .select('phone, fcm_token, zone')
          .eq('id', user_id)
          .maybeSingle();

        // Initiate physical payout through Instamojo
        if (userProfile?.phone) {
          const workerUpi = `${userProfile.phone}@ybl`;
          const amountPaise = tranche1 * 100;
          
          console.log(`[Claims] Initiating physical payout of INR ${tranche1} to ${workerUpi}`);
          const payoutResult = await initiateUpiPayout(
            workerUpi, 
            amountPaise, 
            `Payout for ${DISPLAY_NAMES[trigger_type] || trigger_type}`, 
            `CLM-${claim.id.substring(0, 8).toUpperCase()}`
          );
          
          // Log API id in reference column
          await supabase
            .from('wallet_transactions')
            .update({ reference: `payout_id:${payoutResult.payout_id}` })
            .eq('user_id', user_id)
            .eq('description', `Advance payout for ${DISPLAY_NAMES[trigger_type] || trigger_type}`)
            .order('created_at', { ascending: false })
            .limit(1);
        }

        await supabase
          .from('claims')
          .update({ status: 'APPROVED' })
          .eq('id', claim.id);

        if (userProfile?.fcm_token) {
          await sendPayoutCredited({
            deviceToken: userProfile.fcm_token,
            amount: tranche1,
            claimId: claim.id,
          });
        } else {
          console.log(`[FCM] No device token for user ${user_id} — skipping notification`);
        }
      } catch (err) {
        console.error('[Claims] async payout error:', err.message);
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

module.exports = router;
