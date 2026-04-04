const axios = require('axios');

/**
 * Build a Guidewire ClaimCenter–style payload stub for reinsurance / carrier integration demos.
 * @param {object} claim — row from `claims` with nested `users` if joined
 */
function buildClaimPayload(claim) {
  const user = claim.users || {};
  return {
    integration: 'guidewire_claim_center_stub',
    version: '1.0',
    claim: {
      external_id: claim.id,
      loss_type: claim.trigger_type,
      loss_location: {
        zone: claim.zone,
        city: claim.city || 'Chennai',
      },
      severity: claim.severity,
      duration_hours: claim.duration_hours,
      amounts: {
        gross_payout_paise: claim.gross_payout,
        tranche1_paise: claim.tranche1,
        tranche2_paise: claim.tranche2,
      },
      fraud: {
        score: claim.fraud_score,
        status: claim.fraud_status,
      },
      policy_id: claim.policy_id,
      created_at: claim.created_at,
    },
    claimant: {
      user_id: claim.user_id,
      name: user.name,
      phone: user.phone,
      zone: user.zone,
    },
    meta: {
      generated_at: new Date().toISOString(),
    },
  };
}

/**
 * Optional forward to GUIDEWIRE_WEBHOOK_URL (POST JSON). Disabled if URL unset.
 */
async function forwardToGuidewire(payload) {
  const url = process.env.GUIDEWIRE_WEBHOOK_URL;
  if (!url) {
    return { sent: false, reason: 'GUIDEWIRE_WEBHOOK_URL not set' };
  }
  const secret = process.env.GUIDEWIRE_WEBHOOK_SECRET;
  const headers = { 'Content-Type': 'application/json' };
  if (secret) headers['X-Integration-Secret'] = secret;

  const res = await axios.post(url, payload, {
    headers,
    timeout: 15000,
    validateStatus: () => true,
  });
  return {
    sent: true,
    status: res.status,
    ok: res.status >= 200 && res.status < 300,
  };
}

module.exports = { buildClaimPayload, forwardToGuidewire };
