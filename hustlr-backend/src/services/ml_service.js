const axios = require('axios');

const ML_URL = process.env.ML_SERVICE_URL;
const TIMEOUT = 4000;

// ── Fraud Scoring ──────────────────────────────────────────

async function getFraudScore(data) {
  if (!ML_URL) {
    console.warn('[ML] ML_SERVICE_URL not set — using local fallback');
    return _localFraudFallback(data);
  }

  try {
    const res = await axios.post(`${ML_URL}/fraud-score`, {
      worker_id:       data.worker_id   || 'unknown',
      zone_id:         data.zone_id     || 'adyar',
      claim_timestamp: new Date().toISOString(),
      feature_vector: {
        // Node.js native fields
        zone_match:            data.zone_match       ?? 0.85,
        gps_jitter:            data.gps_jitter       ?? 0.10,
        accelerometer_match:   data.accel_match      ?? 0.90,
        wifi_home_ssid:        data.wifi_home        ?? false,
        days_since_onboarding: data.days_active      ?? 30,
        // Extended fields when available
        claim_latency_seconds:              data.latency_seconds      ?? 120,
        simultaneous_zone_claims:           data.zone_claim_count     ?? 1,
        zone_depth_score:                   data.depth_score          ?? 0.75,
        is_mock_location_ever:              data.is_mock_location     ?? false,
        orders_completed_during_disruption: data.orders_during        ?? 0,
        device_shared_with_n_accounts:      data.device_share_count   ?? 1,
      },
    }, { timeout: TIMEOUT });

    // Map Python response to Node.js expected shape
    const d = res.data;
    const rawScore = d.anomaly_score ?? 0;
    const fps = Math.round(rawScore * 100);

    return {
      fraud_score:    fps,
      status:         fps >= 80 ? 'FLAGGED' : fps >= 50 ? 'REVIEW' : 'CLEAN',
      action:         fps >= 80 ? 'HUMAN_REVIEW' : fps >= 50 ? 'SOFT_HOLD' : 'AUTO_APPROVE',
      top_features:   d.top_features   || [],
      poisson_p_value: d.poisson_p_value ?? null,
      model_used:     d.model_version  || 'isolation_forest_v3',
      source:         'ml_service',
    };

  } catch (e) {
    console.error('[ML] /fraud-score failed:', e.message, '— using fallback');
    return _localFraudFallback(data);
  }
}

// ── ISS Score ──────────────────────────────────────────────

async function getISSScore(data) {
  if (!ML_URL) return _localISSFallback(data);

  try {
    const res = await axios.post(`${ML_URL}/iss`, {
      zone_flood_risk:        data.zone_flood_risk       ?? 0.60,
      avg_daily_income:       data.avg_daily_income      ?? 600,
      disruption_freq_12mo:   data.disruption_freq       ?? 8,
      platform_tenure_weeks:  data.tenure_weeks          ?? 4,
      city:                   data.city                  ?? 'Chennai',
    }, { timeout: TIMEOUT });

    return {
      iss_score:    res.data.iss_score,
      tier:         res.data.tier,
      recommendation: res.data.recommendation,
      model_used:   res.data.model_used,
      source:       'ml_service',
    };

  } catch (e) {
    console.error('[ML] /iss failed:', e.message, '— using fallback');
    return _localISSFallback(data);
  }
}

// ── Premium Calculation ────────────────────────────────────

async function getPremium(data) {
  if (!ML_URL) return _localPremiumFallback(data);

  try {
    const res = await axios.post(`${ML_URL}/premium`, {
      plan_tier:         data.plan_tier         ?? 'standard',
      zone:              data.zone              ?? 'Adyar Dark Store Zone',
      iss_score:         data.iss_score         ?? 62,
      previous_premium:  data.previous_premium  ?? 0,
    }, { timeout: TIMEOUT });

    return {
      plan_tier:       res.data.plan_tier,
      base_premium:    res.data.base_premium,
      zone_adjustment: res.data.zone_adjustment,
      final_premium:   res.data.final_premium,
      note:            res.data.note,
      source:          'ml_service',
    };

  } catch (e) {
    console.error('[ML] /premium failed:', e.message, '— using fallback');
    return _localPremiumFallback(data);
  }
}

// ── Forecast ───────────────────────────────────────────────

async function getForecast(zone) {
  if (!ML_URL) return null;

  const zoneKey = zone
    .toLowerCase()
    .replace(' dark store zone', '')
    .replace(/ /g, '_');

  try {
    const res = await axios.get(
      `${ML_URL}/forecast/${encodeURIComponent(zoneKey)}`,
      { timeout: 30000 }
    );
    return res.data;
  } catch (e) {
    console.error('[ML] /forecast failed:', e.message);
    return null;
  }
}

// ── Fallbacks ─────────────────────────────────────────────
// These are called when ML service is unreachable.
// They use deterministic logic — NOT random numbers.

function _localFraudFallback(data) {
  let score = 10;  // start clean

  if ((data.gps_jitter ?? 0.1) < 0.000001) score += 80;
  if ((data.days_active ?? 30) < 14)        score += 20;
  if ((data.wifi_home ?? false))             score += 20;
  if ((data.zone_claim_count ?? 1) > 50)    score += 35;

  const hour = new Date().getHours();
  if (hour < 8 || hour > 22) score += 15;

  score = Math.min(100, score);

  return {
    fraud_score: score,
    status:  score >= 80 ? 'FLAGGED' : score >= 50 ? 'REVIEW' : 'CLEAN',
    action:  score >= 80 ? 'HUMAN_REVIEW' : score >= 50 ? 'SOFT_HOLD' : 'AUTO_APPROVE',
    source:  'local_fallback',
    model_used: 'rule_engine_v2',
  };
}

function _localISSFallback(data) {
  let score = 100;
  score -= (data.zone_flood_risk ?? 0.6) * 20;
  score -= Math.min(data.disruption_freq ?? 8, 15);
  score += Math.min((data.avg_daily_income ?? 600) / 200, 10);
  score += Math.min((data.tenure_weeks ?? 4) / 10, 8);
  score = Math.max(0, Math.min(100, Math.round(score)));

  const tier = score >= 70 ? 'GREEN'
             : score >= 50 ? 'AMBER'
             : score >= 30 ? 'AMBER_LOW'
             : 'RED';

  return {
    iss_score:    score,
    tier,
    recommendation: score >= 70 ? 'basic' : score >= 40 ? 'standard' : 'full',
    model_used:   'rule_engine_local',
    source:       'local_fallback',
  };
}

function _localPremiumFallback(data) {
  const base = { basic: 35, standard: 49, full: 79 }[data.plan_tier] ?? 49;
  const zone_adj = {
    'Adyar Dark Store Zone': 5,
    'Velachery Dark Store Zone': 7,
    'Tambaram Dark Store Zone': 4,
  }[data.zone] ?? 0;

  return {
    plan_tier: data.plan_tier,
    base_premium: base,
    zone_adjustment: zone_adj,
    final_premium: Math.min(98, base + zone_adj),
    note: 'Fixed pricing — fallback calculation',
    source: 'local_fallback',
  };
}

// ── Health Check ───────────────────────────────────────────
async function isMlOnline() {
  if (!ML_URL) return false;
  try {
    const res = await axios.get(`${ML_URL}/health`, { timeout: 2000 });
    return res.data?.status === 'ok';
  } catch (e) {
    return false;
  }
}

// ── GNN Fraud Ring Detection ─────────────────────────────────
async function getGNNFraudRings(zoneId, workers, fraudThreshold = 0.7) {
  if (!ML_URL) {
    console.warn('[ML] ML_SERVICE_URL not set — GNN fraud detection unavailable');
    return { fraud_rings_detected: 0, rings: [], risk_level: 'LOW' };
  }

  try {
    const res = await axios.post(`${ML_URL}/fraud/gnn-ring-detect`, {
      zone_id: zoneId,
      workers: workers,
      fraud_threshold: fraudThreshold,
    }, { timeout: 10000 });

    return {
      zone_id: res.data.zone_id,
      total_workers: res.data.total_workers,
      fraud_rings_detected: res.data.fraud_rings_detected,
      rings: res.data.rings,
      risk_level: res.data.risk_level,
      latency_ms: res.data.latency_ms,
      source: 'ml_gnn_service',
    };
  } catch (e) {
    console.error('[ML] /fraud/gnn-ring-detect failed:', e.message);
    return { fraud_rings_detected: 0, rings: [], risk_level: 'LOW', error: e.message };
  }
}

module.exports = {
  getFraudScore,
  getISSScore,
  getPremium,
  getForecast,
  isMlOnline,
  getGNNFraudRings,
};
