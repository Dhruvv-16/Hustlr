const axios = require('axios');

const FIREBASE_SERVER_KEY = process.env.FIREBASE_SERVER_KEY;
const FCM_URL = 'https://fcm.googleapis.com/fcm/send';

/**
 * Send a push notification via Firebase Cloud Messaging (FCM).
 * Falls back to mock mode if no key is configured or the request fails.
 *
 * @param {string} deviceToken  - FCM device registration token
 * @param {string} title        - Notification title
 * @param {string} body         - Notification body
 * @param {object} [data]       - Optional key-value data payload
 */
async function sendPushNotification(deviceToken, title, body, data = {}) {
  if (!FIREBASE_SERVER_KEY) {
    console.warn('[FCM] FIREBASE_SERVER_KEY not set — skipping notification');
    return { source: 'mock', status: 'skipped', reason: 'no_key', timestamp: new Date().toISOString() };
  }

  try {
    const res = await axios.post(
      FCM_URL,
      {
        to: deviceToken,
        notification: { title, body },
        data,
        priority: 'high',
      },
      {
        headers: {
          Authorization: `key=${FIREBASE_SERVER_KEY}`,
          'Content-Type': 'application/json',
        },
        timeout: 5000,
      }
    );

    console.log(`[FCM] LIVE notification sent | title="${title}" | fcm_id=${res.data?.message_id ?? 'n/a'}`);
    return {
      source: 'live_fcm',
      status: 'sent',
      message_id: res.data?.message_id,
      timestamp: new Date().toISOString(),
    };
  } catch (e) {
    const errMsg = e.response?.data?.error || e.message;
    console.warn(`[FCM] failed: ${errMsg} — falling back to mock`);
    return {
      source: 'mock',
      status: 'simulated',
      error: errMsg,
      timestamp: new Date().toISOString(),
    };
  }
}

/**
 * Convenience: send a disruption alert to a worker's device.
 */
async function sendDisruptionAlert({ deviceToken, triggerType, zone, payoutAmount }) {
  const title = '⚡ Disruption Detected in Your Zone';
  const body = `${_label(triggerType)} in ${zone} — You may be eligible for ₹${payoutAmount} payout.`;
  return sendPushNotification(deviceToken, title, body, {
    type: 'disruption_alert',
    trigger_type: triggerType,
    zone,
    payout_amount: String(payoutAmount),
  });
}

/**
 * Convenience: notify worker that a claim payout was credited.
 */
async function sendPayoutCredited({ deviceToken, amount, claimId }) {
  const title = '💰 Payout Credited!';
  const body = `₹${amount} has been added to your Hustlr wallet for claim #${claimId}.`;
  return sendPushNotification(deviceToken, title, body, {
    type: 'payout_credited',
    claim_id: claimId,
    amount: String(amount),
  });
}

function _label(t) {
  const m = {
    rain_heavy: 'Heavy Rain',
    heat_severe: 'Extreme Heat',
    platform_outage: 'Platform Downtime',
    aqi_hazardous: 'Severe Pollution',
    bandh: 'Bandh/Curfew',
  };
  return m[t] ?? t;
}

/**
 * Predictive nudge from weather / cron (Phase 2).
 */
async function sendPredictiveNudge({ deviceToken, zone, nudge }) {
  if (!deviceToken || !nudge?.message) {
    return { source: 'skipped', reason: 'no_token_or_message' };
  }
  const title = nudge.urgency === 'HIGH' ? '⚠️ High rain risk in your zone' : '🌧️ Weather heads-up';
  const body = `${nudge.message} ${nudge.sub_message || ''}`.trim().slice(0, 180);
  return sendPushNotification(deviceToken, title, body, {
    type: 'predictive_nudge',
    zone: zone || '',
    urgency: nudge.urgency || 'MEDIUM',
    rain_chance: String(nudge.rain_chance ?? ''),
  });
}

module.exports = {
  sendPushNotification,
  sendDisruptionAlert,
  sendPayoutCredited,
  sendPredictiveNudge,
};
