/**
 * ml_service.js
 * Thin HTTP client for the Python FastAPI ML microservice.
 * Falls back gracefully to rule-based logic if the ML service is offline.
 */

const axios = require('axios');

const ML_URL = process.env.ML_SERVICE_URL || 'https://hustlr-2ppj.onrender.com';
const TIMEOUT = 5000; // 5s — never block a claim payout waiting for ML

let _mlOnline = false;
let _lastCheck = 0;

/** Ping the ML service and cache the result for 30s */
async function isMlOnline() {
  if (Date.now() - _lastCheck < 30_000) return _mlOnline;
  try {
    await axios.get(`${ML_URL}/health`, { timeout: 2000 });
    _mlOnline  = true;
  } catch {
    _mlOnline  = false;
  }
  _lastCheck = Date.now();
  return _mlOnline;
}

// ── ISS Score ────────────────────────────────────────────────────────────────
// ISS 0–39   → High risk  → Recommend Full Shield (₹79/wk)
// ISS 40–80  → Med risk   → Recommend Standard Shield (₹49/wk)
// ISS 81–100 → Low risk   → Recommend Basic Shield (₹35/wk)
async function getISSScore({
  zone_flood_risk = 0.5,
  avg_daily_income = 600,
  disruption_freq_12mo = 10,
  claims_history_penalty = 0,
  bandh_freq_zone = 4,
  platform_outage_per_mo = 2,
  coastal_zone = false,
  city = 'Chennai',
} = {}) {
  try {
    const { data } = await axios.post(`${ML_URL}/iss`, {
      zone_flood_risk, avg_daily_income, disruption_freq_12mo,
      claims_history_penalty, bandh_freq_zone, platform_outage_per_mo,
      coastal_zone, use_ml: true, city,
      use_weather_prior: process.env.USE_ISS_WEATHER_PRIOR === 'true',
    }, { timeout: TIMEOUT });
    return data;
  } catch {
    // Rule-based fallback
    let score = 100;
    score -= zone_flood_risk * 20;
    score -= Math.min(disruption_freq_12mo, 15);
    score += Math.min(avg_daily_income / 200, 10);
    score -= claims_history_penalty;
    const iss = Math.max(0, Math.min(100, Math.round(score)));

    // README-canonical thresholds: 0–39 = Full Shield, 40–80 = Standard Shield, 81–100 = Basic Shield
    const recommended_tier =
      iss <= 39 ? 'full' :
      iss <= 80 ? 'standard' :
      'basic';
    const recommended_tier_name =
      iss <= 39 ? 'Full Shield' :
      iss <= 80 ? 'Standard Shield' :
      'Basic Shield';

    return {
      iss_score: iss,
      risk_band: iss < 40 ? 'HIGH' : iss < 81 ? 'MEDIUM' : 'LOW',
      recommended_tier,
      recommended_tier_name,
      _source: 'rule_fallback',
    };
  }
}

// ── Fraud Score ──────────────────────────────────────────────────────────────
async function getFraudScore({
  zone_depth_score = 0.8,
  days_since_onboard = 90,
  simultaneous_zone_claims = 0,
  play_integrity_pass = true,
  is_mock_location = false,
  ndma_emergency_active = false,
  // device signals default to 0 (clean)
  gps_zone_mismatch = 0,
  wifi_home_ssid = 0,
  battery_charging = 0,
  accelerometer_idle = 0,
  platform_app_inactive = 0,
  ip_home_match = 0,
  claim_latency_under30s = 0,
  gps_jitter_too_perfect = 0,
  barometer_altitude_mismatch = 0,
  device_hardware_fingerprint_match = 0,
  app_install_timestamp_cluster = 0,
} = {}) {
  try {
    const { data } = await axios.post(`${ML_URL}/fraud`, {
      zone_depth_score, days_since_onboard, simultaneous_zone_claims,
      play_integrity_pass, is_mock_location, ndma_emergency_active,
      gps_zone_mismatch, wifi_home_ssid, battery_charging,
      accelerometer_idle, platform_app_inactive, ip_home_match,
      claim_latency_under30s, gps_jitter_too_perfect,
      barometer_altitude_mismatch, device_hardware_fingerprint_match,
      app_install_timestamp_cluster,
    }, { timeout: TIMEOUT });
    return data;
  } catch {
    // Simple fallback matching existing fraud_engine.js tiers
    const fps = days_since_onboard < 14 ? 0.4 : 0.1;
    const tier = fps < 0.31 ? 'GREEN' : fps < 0.61 ? 'YELLOW' : 'RED';
    return {
      fps_score: fps,
      fps_tier: tier,
      action: tier === 'GREEN' ? 'AUTO_APPROVE' : tier === 'YELLOW' ? 'SOFT_HOLD' : 'HUMAN_REVIEW',
      payout_multiplier: zone_depth_score > 0.6 ? 1.0 : 0.6,
      _source: 'rule_fallback',
    };
  }
}

// ── NLP Disruption Parse ──────────────────────────────────────────────────────
async function parseDisruption(text) {
  try {
    const { data } = await axios.post(`${ML_URL}/nlp`, { text }, { timeout: TIMEOUT });
    return data;
  } catch {
    return { trigger: 'normal', confidence: 0.0, fires: false, _source: 'rule_fallback' };
  }
}

// ── Internet Blackout ────────────────────────────────────────────────────────
async function detectBlackout({ ookla_avg_speed, device_pct_weak, sustained_minutes, trai_match, zone }) {
  try {
    const { data } = await axios.post(`${ML_URL}/blackout`, {
      ookla_avg_speed, device_pct_weak, sustained_minutes, trai_match, zone,
    }, { timeout: TIMEOUT });
    return data;
  } catch {
    const sig1 = ookla_avg_speed < 2.0 && sustained_minutes >= 20;
    const sig2 = device_pct_weak >= 0.30;
    const sig3 = trai_match === true;
    
    // Dual-confirmation rule:
    // Signal 1 + Signal 2  -> AUTO_TRIGGER
    // Signal 3 alone       -> AUTO_TRIGGER
    const fired = sig3 || (sig1 && sig2);
    
    return {
      blackout_detected: fired,
      severity: fired ? 'MODERATE' : 'NONE',
      trigger_fires: fired,
      hourly_rate_inr: fired ? 45 : 0,  // ₹45/hr per actuarial model
      _source: 'rule_fallback',
    };
  }
}

// ── Traffic Classifier ───────────────────────────────────────────────────────
async function classifyTraffic({ zone, traffic_speed_kmh, baseline_speed_kmh, traffic_duration_min, news_confidence, time_of_day, is_weekend = false }) {
  try {
    const { data } = await axios.post(`${ML_URL}/traffic`, {
      zone, traffic_speed_kmh, baseline_speed_kmh,
      traffic_duration_min, news_confidence, time_of_day, is_weekend,
    }, { timeout: TIMEOUT });
    return data;
  } catch {
    const drop = (baseline_speed_kmh - traffic_speed_kmh) / baseline_speed_kmh;
    const heavy = drop >= 0.40 && traffic_duration_min >= 45;
    return {
      classification: heavy ? 'ACCIDENT_BLOCKSPOT' : 'INCONCLUSIVE',
      heavy_traffic_trigger: heavy,
      trigger_fires: heavy,
      hourly_rate_inr: heavy ? 30 : 0,  // ₹30/hr per actuarial model
      _source: 'rule_fallback',
    };
  }
}

// ── Work advisor (earning stability + shift windows) ────────────────────────
async function getWorkAdvisor(payload) {
  try {
    const { data } = await axios.post(`${ML_URL}/work-advisor`, payload, {
      timeout: TIMEOUT,
    });
    return { ...data, _source: 'ml_service' };
  } catch {
    const prior = 0.55;
    const esi = Math.max(
      35,
      Math.min(
        88,
        Math.round(100 - 28 * prior - (payload.active_disruption_count || 0) * 8),
      ),
    );
    return {
      earning_stability_index: esi,
      stability_band: esi >= 70 ? 'STABLE' : esi >= 48 ? 'ELEVATED' : 'STRESSED',
      stability_band_label:
        esi >= 70 ? 'Stable earnings outlook' : esi >= 48 ? 'Elevated disruption risk' : 'High disruption risk — protect income',
      headline:
        esi >= 70
          ? 'Your zone looks workable — keep usual shift patterns.'
          : 'Weather or demand may be uneven — plan shift blocks carefully.',
      recommended_shift_windows: [
        { label: 'Peak demand', hours: '8:00–11:00 & 17:00–21:00', rationale: 'Stack high-volume hours' },
      ],
      suggest_activate_coverage: esi < 55,
      coverage_nudge:
        esi < 55
          ? 'Disruption risk is elevated — consider keeping coverage active.'
          : 'Conditions are relatively calm.',
      _source: 'rule_fallback',
    };
  }
}

// ── Disruption Forecast ──────────────────────────────────────────────────────
async function getForecast(zone) {
  try {
    const { data } = await axios.get(`${ML_URL}/forecast/${encodeURIComponent(zone)}`, { timeout: TIMEOUT });
    return data;
  } catch {
    return { zone, forecast: [], _source: 'ml_offline' };
  }
}

// ── Payout Calculation ────────────────────────────────────────────────────────
async function calculatePayout({ trigger_type, disruption_hours, zone_depth_score, fps_tier, plan_tier, daily_payouts_this_week = 0, shift_overlap_hours = null }) {
  try {
    const { data } = await axios.post(`${ML_URL}/payout`, {
      trigger_type, disruption_hours, zone_depth_score,
      fps_tier, plan_tier, daily_payouts_this_week, shift_overlap_hours,
    }, { timeout: TIMEOUT });
    return data;
  } catch {
    // Fallback uses canonical HOURLY_RATES and plan-tier daily caps from constants.js
    // Trigger key names MUST match HOURLY_RATES keys exactly.
    const RATES = {
      rain_heavy:        40,  // ₹40/hr
      rain_extreme:      65,  // ₹65/hr
      heat_severe:       45,  // ₹45/hr
      aqi_hazardous:     35,  // ₹35/hr
      platform_outage:   50,  // ₹50/hr
      bandh:             55,  // ₹55/hr
      traffic_severe:    30,  // ₹30/hr
      internet_blackout: 45,  // ₹45/hr
      cyclone_landfall:  80,  // ₹80/hr (Full Shield only)
    };
    // Plan-tier daily hard caps (README canonical)
    const PLAN_DAILY_CAPS = { basic: 100, standard: 150, full: 250 };
    const rate       = RATES[trigger_type] || 40;
    const dailyCap   = PLAN_DAILY_CAPS[plan_tier] || 150;
    const payout     = Math.min(Math.round(rate * (disruption_hours || 3)), dailyCap);
    return { payout_inr: payout, approved: payout > 0, _source: 'rule_fallback' };
  }
}

module.exports = {
  isMlOnline,
  getISSScore,
  getFraudScore,
  parseDisruption,
  detectBlackout,
  classifyTraffic,
  getForecast,
  getWorkAdvisor,
  calculatePayout,
};
