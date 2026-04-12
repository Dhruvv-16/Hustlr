const mlService = require('./ml_service');

async function scoreClaim(claimData) {
  const fraudResult = await mlService.getFraudScore({
    worker_id:       claimData.worker_id,
    zone_id:         claimData.zone_id?.toLowerCase().replace(/ /g, '_').replace(' dark store zone', '') || 'adyar',
    gps_jitter:      claimData.gps_jitter       ?? 0.10,
    zone_match:      claimData.zone_match       ?? 0.85,
    accel_match:     claimData.accelerometer_match ?? 0.90,
    wifi_home:       claimData.wifi_home        ?? false,
    days_active:     claimData.days_active      ?? 30,
    depth_score:     claimData.zone_depth_score ?? 0.75,
    is_mock_location: claimData.is_mock_location ?? false,
    latency_seconds: claimData.latency          ?? 120,
    zone_claim_count: claimData.zone_claim_count ?? 1,
  });
  
  return fraudResult;
}

module.exports = { scoreClaim };
