const { supabase } = require('../config/supabase');

const SIGNAL_WEIGHTS = {
  new_account:          20,
  claim_velocity_high:  25,
  zone_mismatch:        30,
  outside_shift_window: 15,
  duplicate_event:      50,
  mass_claim_spike:     35,
  first_week_max_claim: 20,
};

async function getWorkerHistory(userId) {
  const [userRes, claimsRes] = await Promise.all([
    supabase.from('users').select('*')
      .eq('id', userId).single(),
    supabase.from('claims').select('*')
      .eq('user_id', userId)
      .gte('created_at', new Date(
        Date.now() - 7 * 24 * 60 * 60 * 1000
      ).toISOString()),
  ]);
  return {
    user:              userRes.data,
    claims_this_week:  claimsRes.data?.length ?? 0,
  };
}

async function getZoneClaimCount(zone) {
  const oneHourAgo = new Date(
    Date.now() - 60 * 60 * 1000
  ).toISOString();
  
  const { count } = await supabase
    .from('claims')
    .select('*', { count: 'exact', head: true })
    .eq('zone', zone)
    .gte('created_at', oneHourAgo);
    
  return count ?? 0;
}

async function calculateFraudScore({
  userId,
  zone,
  triggerType,
}) {
  let score = 0;
  const signals = [];

  try {
    const { user, claims_this_week } = 
      await getWorkerHistory(userId);

    if (!user) return { score: 80, signals: ['user_not_found'], decision: getFraudDecision(80) };

    // Signal 1 — New account (< 14 days)
    const daysSinceJoining = Math.floor(
      (Date.now() - new Date(user.created_at)) 
      / (1000 * 60 * 60 * 24)
    );
    if (daysSinceJoining < 14) {
      score += SIGNAL_WEIGHTS.new_account;
      signals.push('new_account');
    }

    // Signal 2 — Claim velocity
    if (claims_this_week >= 3) {
      score += SIGNAL_WEIGHTS.claim_velocity_high;
      signals.push('claim_velocity_high');
    }

    // Signal 3 — Zone mismatch
    if (zone && user.zone && zone !== user.zone) {
      score += SIGNAL_WEIGHTS.zone_mismatch;
      signals.push('zone_mismatch');
    }

    // Signal 4 — Outside shift window (8AM-10PM)
    const hour = new Date().getHours();
    if (hour < 8 || hour > 22) {
      score += SIGNAL_WEIGHTS.outside_shift_window;
      signals.push('outside_shift_window');
    }

    // Signal 5 — First week max claim
    if (daysSinceJoining < 7 && claims_this_week >= 1) {
      score += SIGNAL_WEIGHTS.first_week_max_claim;
      signals.push('first_week_max_claim');
    }

    // Signal 6 — Mass claim spike in zone
    const zoneCount = await getZoneClaimCount(zone);
    if (zoneCount > 50) {
      score += SIGNAL_WEIGHTS.mass_claim_spike;
      signals.push('mass_claim_spike');
    }

  } catch (e) {
    console.error('[FraudEngine] Error:', e.message);
    score = 50; // conservative on error
  }

  const cappedScore = Math.min(score, 100);

  return {
    score:   cappedScore,
    signals,
    decision: getFraudDecision(cappedScore),
  };
}

function getFraudDecision(score) {
  if (score < 30) return {
    status: 'CLEAN',
    action: 'AUTO_APPROVE',
    release_pct: 70,
  };
  if (score < 60) return {
    status: 'REVIEW',
    action: 'SOFT_HOLD',
    release_pct: 40,
    hold_hrs: 2,
  };
  return {
    status:      'FLAGGED',
    action:      'HUMAN_REVIEW',
    release_pct: 0,
    provisional: 200,
  };
}

module.exports = { calculateFraudScore };
