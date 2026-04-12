'use strict';
/**
 * fraud_engine.js — updated per ML Blueprint v1.0
 * ================================================
 * Changes from blueprint:
 *  - Decision threshold lowered 0.50 → 0.42 (FNR target <12%)
 *  - 3-tier alert zones: AUTO_APPROVE / MANUAL_REVIEW / AUTO_FLAG
 *  - Compound signal boost: velocityJump + accelMismatch ≥ 0.7
 *  - Network Trust Score: 4-component weighted ensemble
 *  - Conditional high-res telemetry snapshot (trust < 0.70 only)
 */

const mlService = require('./ml_service');

// ── Thresholds ────────────────────────────────────────────────────────────────
const FRAUD_THRESHOLDS = {
  AUTO_APPROVE:   0.42,   // was 0.30 — improves FNR from 18% → <12%
  MANUAL_REVIEW:  0.65,   // borderline band: human ops queue
  AUTO_FLAG:      0.65,   // auto-reject above this
};

// ── Network Trust Score weights (Arjun Iyer architecture) ────────────────────
const NETWORK_WEIGHTS = {
  timingAdvance:     0.30,
  cellIdConsistency: 0.30,
  rsrqJitter:        0.25,
  handoffPattern:    0.15,
};

/**
 * routeClaim — 3-tier routing replacing the old binary approve/reject.
 * @param {number} fraudScore 0–1
 * @returns {'AUTO_APPROVE'|'MANUAL_REVIEW'|'AUTO_FLAG'}
 */
function routeClaim(fraudScore) {
  if (fraudScore < FRAUD_THRESHOLDS.AUTO_APPROVE)  return 'AUTO_APPROVE';
  if (fraudScore < FRAUD_THRESHOLDS.MANUAL_REVIEW) return 'MANUAL_REVIEW';
  return 'AUTO_FLAG';
}

/**
 * applyCompoundSignalBoost — velocity jump + accelerometer mismatch together
 * is near-certain GPS spoofing (both required, not either).
 */
function applyCompoundSignalBoost(baseScore, velocityJump, accelMismatch) {
  if (velocityJump === true && accelMismatch >= 0.7) {
    return Math.min(baseScore + 0.25, 1.0);
  }
  return baseScore;
}

/**
 * computeNetworkTrustScore — 4-signal weighted ensemble.
 * Score < 0.70 → triggers conditional high-res telemetry snapshot.
 */
function computeNetworkTrustScore(networkSignals = {}) {
  const {
    timingAdvance     = 0.5,
    cellIdConsistency = 0.5,
    rsrqJitter        = 0.5,
    handoffPattern    = 0.5,
  } = networkSignals;

  const score = (
    timingAdvance     * NETWORK_WEIGHTS.timingAdvance     +
    cellIdConsistency * NETWORK_WEIGHTS.cellIdConsistency +
    rsrqJitter        * NETWORK_WEIGHTS.rsrqJitter        +
    handoffPattern    * NETWORK_WEIGHTS.handoffPattern
  );
  return Math.min(Math.max(score, 0), 1);
}

/**
 * collectTripTelemetry — privacy-preserving conditional snapshot.
 * High-res IMU / battery data only collected when trust < 0.70.
 */
async function collectTripTelemetry(tripId, networkSignals = {}) {
  const trustScore = computeNetworkTrustScore(networkSignals);

  const baseRecord = {
    tripIdHash:          _sha256Placeholder(tripId),
    networkTrustScore:   trustScore,
    velocityJumpFlag:    await _detectVelocityJump(tripId),
    timestamp:           new Date().toISOString(),
  };

  // Conditional high-res snapshot — ONLY when suspicious
  if (trustScore < 0.70) {
    return {
      ...baseRecord,
      imuAccelMismatch: await _getImuAccelDelta(tripId),
      batteryTempC:     await _getBatteryTemp(tripId),
      snapshotTrigger:  'trust_score_below_threshold',
    };
  }

  return baseRecord;
}

/**
 * scoreClaim — main entry point (backwards-compatible with existing callers).
 * Wraps mlService.getFraudScore and applies new routing + compound boosts.
 */
async function scoreClaim(claimData) {
  const fraudResult = await mlService.getFraudScore({
    worker_id:        claimData.worker_id,
    zone_id:          (claimData.zone_id || 'adyar')
                        .toLowerCase().replace(/ /g, '_')
                        .replace(' dark store zone', ''),
    gps_jitter:       claimData.gps_jitter             ?? 0.10,
    zone_match:       claimData.zone_match              ?? 0.85,
    accel_match:      claimData.accelerometer_match     ?? 0.90,
    wifi_home:        claimData.wifi_home               ?? false,
    days_active:      claimData.days_active             ?? 30,
    depth_score:      claimData.zone_depth_score        ?? 0.75,
    is_mock_location: claimData.is_mock_location        ?? false,
    latency_seconds:  claimData.latency                 ?? 120,
    zone_claim_count: claimData.zone_claim_count        ?? 1,
  });

  // Apply compound signal boost before routing
  let score = fraudResult?.fps_score ?? fraudResult?.anomaly_score ?? 0;
  score = applyCompoundSignalBoost(
    score,
    claimData.velocity_jump        ?? false,
    claimData.accelerometer_mismatch ?? 0,
  );

  return {
    ...fraudResult,
    fps_score:  score,
    action:     routeClaim(score),
    trust_tier: score < 0.42 ? 'GREEN' : score < 0.65 ? 'YELLOW' : 'RED',
  };
}

// ── Stubs for device telemetry helpers (implemented in device_fingerprint_service) ──
function _sha256Placeholder(str) { return `hash_${str}`; }
async function _detectVelocityJump(tripId) { return false; }       // noqa
async function _getImuAccelDelta(tripId)   { return null; }        // noqa
async function _getBatteryTemp(tripId)     { return null; }        // noqa

module.exports = {
  scoreClaim,
  routeClaim,
  applyCompoundSignalBoost,
  computeNetworkTrustScore,
  collectTripTelemetry,
  FRAUD_THRESHOLDS,
};
