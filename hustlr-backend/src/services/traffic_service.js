// services/traffic_service.js
// Fetches route data via OpenRouteService Directions API (free, no billing needed).
// ORS provides distance + free-flow duration; a time-of-day congestion multiplier
// is applied to simulate realistic peak-hour traffic for Chennai/Bengaluru corridors.

const axios = require('axios');
const { withFallback } = require('./api_wrapper');
const { FALLBACKS } = require('./fallback_service');

const ORS_API_KEY = process.env.OPENROUTE_API_KEY;
const ORS_URL = 'https://api.openrouteservice.org/v2/directions/driving-car';

// ORS uses [longitude, latitude] (GeoJSON order — opposite of Google)
const CORRIDOR_BASELINES = {
  gst_road_chennai:          { baseline_kmh: 20, start: [80.1999, 12.9716], end: [80.1000, 12.9250] },
  anna_salai_chennai:        { baseline_kmh: 18, start: [80.2707, 13.0827], end: [80.2338, 13.0569] },
  omr_chennai:               { baseline_kmh: 35, start: [80.2181, 12.9716], end: [80.2270, 12.8406] },
  electronic_city_bengaluru: { baseline_kmh: 17, start: [77.6603, 12.8456], end: [77.5946, 12.9716] },
};

// Map Hustlr working zones -> nearest corridor
const ZONE_TO_CORRIDOR = {
  adyar_chennai:         'anna_salai_chennai',
  velachery_chennai:     'gst_road_chennai',
  tambaram_chennai:      'gst_road_chennai',
  omr_chennai:           'omr_chennai',
  koramangala_bengaluru: 'electronic_city_bengaluru',
};

// Time-of-day congestion multipliers for Chennai (1.0 = free flow)
// Higher multiplier = more congestion = slower effective speed
function getCongestionMultiplier() {
  const hour = new Date().getHours();
  if (hour >= 8  && hour <= 10) return 1.65; // Morning peak
  if (hour >= 11 && hour <= 13) return 1.25; // Mid-day
  if (hour >= 17 && hour <= 20) return 1.80; // Evening peak (worst)
  if (hour >= 21 || hour <= 6)  return 1.05; // Night (near free-flow)
  return 1.35;                                // Regular daytime
}

/**
 * Returns real-time traffic speed data for a Hustlr zone.
 * Uses ORS for route geometry + applies a Chennai-calibrated peak-hour multiplier.
 * @param {string} zone - Hustlr working zone key (e.g. "adyar_chennai")
 */
async function getTrafficSpeed(zone) {
  const corridorKey = ZONE_TO_CORRIDOR[zone] || 'gst_road_chennai';
  const corridor    = CORRIDOR_BASELINES[corridorKey];

  return withFallback(
    'traffic',
    async () => {
      const resp = await axios.post(
        ORS_URL,
        {
          coordinates: [corridor.start, corridor.end],
          instructions: false,
        },
        {
          headers: {
            Authorization: ORS_API_KEY,
            'Content-Type': 'application/json',
          },
          timeout: 8000,
        }
      );

      const summary      = resp.data.routes[0].summary;
      const distanceM    = summary.distance;           // metres
      const freeFlowSecs = summary.duration;           // seconds (no traffic)

      // Apply congestion multiplier to simulate real traffic delay
      const multiplier       = getCongestionMultiplier();
      const inTrafficSecs    = freeFlowSecs * multiplier;
      const currentSpeed     = (distanceM / inTrafficSecs) * 3.6; // km/h
      const speedDropPct     = (corridor.baseline_kmh - currentSpeed) / corridor.baseline_kmh;

      console.log(
        `[Traffic] ORS LIVE | zone=${zone} corridor=${corridorKey}` +
        ` speed=${currentSpeed.toFixed(1)}km/h drop=${(speedDropPct * 100).toFixed(1)}%` +
        ` multiplier=${multiplier}x`
      );

      return {
        source:             'live_openrouteservice',
        zone,
        corridor:           corridorKey,
        current_speed_kmh:  Math.round(currentSpeed * 10) / 10,
        baseline_speed_kmh: corridor.baseline_kmh,
        speed_drop_pct:     Math.round(speedDropPct * 1000) / 1000,
        congestion_level:   _congestionLevel(speedDropPct),
        congestion_multiplier: multiplier,
        distance_m:         Math.round(distanceM),
        free_flow_secs:     Math.round(freeFlowSecs),
        timestamp:          new Date().toISOString(),
      };
    },
    FALLBACKS.traffic
  );
}

/**
 * Converts traffic data into a Hustlr disruption trigger.
 * Returns null if traffic is Normal or Moderate.
 */
function detectTrafficTrigger(trafficData) {
  if (!trafficData || trafficData.congestion_level !== 'Severe') return null;

  return {
    trigger_type:  'traffic_severe',
    display_name:  'Severe Traffic Congestion',
    hourly_rate:   40,
    severity:      trafficData.speed_drop_pct,
    current_value: `${trafficData.current_speed_kmh} km/h`,
    threshold:     `< ${Math.round(trafficData.baseline_speed_kmh * 0.60)} km/h (>=40% speed drop)`,
    payout_pct:    70,
    active:        true,
    source:        trafficData.source,
  };
}

function _congestionLevel(dropPct) {
  if (dropPct < 0.15) return 'Normal';
  if (dropPct < 0.30) return 'Inconclusive_Mild';
  if (dropPct < 0.45) return 'Inconclusive_Moderate';
  return 'Severe';
}

// ── Blueprint additions: INCONCLUSIVE sub-bands ───────────────────────────────
/**
 * classifyTrafficIncident — splits old INCONCLUSIVE into two actionable bands.
 * Heavy rain amplifies effective speed drop by 35%.
 */
function classifyTrafficIncident(speedDropPct, weather, incidentType, corridor) {
  // Rain amplification: heavy rain makes congestion 35% worse
  const effectiveDrop = weather === 'heavy_rain'
    ? Math.min(speedDropPct * 1.35, 1.0)
    : speedDropPct;

  if (effectiveDrop < 0.15) {
    return { classification: 'NORMAL',                action: 'route_normally',      delayBuffer: 0 };
  } else if (effectiveDrop <= 0.30) {
    return { classification: 'INCONCLUSIVE_MILD',     action: 'route_with_buffer',   delayBuffer: 0.10 };
  } else if (effectiveDrop <= 0.45) {
    return { classification: 'INCONCLUSIVE_MODERATE', action: 'flag_for_sla_review', delayBuffer: 0.25 };
  } else {
    return { classification: 'ACCIDENT_BLACKSPOT',    action: 'check_reroute',       delayBuffer: null };
  }
}

/**
 * applyTTMCaps — Travel Time Multiplier hard caps.
 * Above 2.9 → trigger reroute instead of extending SLA.
 */
function applyTTMCaps(baseTTM, isPeakHour, isMonsoon) {
  let ttm = baseTTM;
  if (isPeakHour) ttm = Math.min(ttm, 2.5);
  if (isMonsoon)  ttm += 0.4;
  return Math.min(ttm, 2.9);  // Hard cap
}

// ── Chennai Metro Phase 2 construction zones (lack training data — apply caution buffer) ──
const METRO_CONSTRUCTION_ZONES = {
  OMR_Sholinganallur: { corridor: 'Corridor 3 — SRP Tools to Navalur', speedReductionFactor: 0.70, active: true },
  Velachery:          { corridor: 'Corridor 5 — near Velachery station', speedReductionFactor: 0.75, diversionActive: true, active: true },
  Perumbakkam:        { corridor: 'Phase 2 station — post-2023',         speedReductionFactor: 0.80, active: true },
};

function isMetroConstructionZone(locationName) {
  return METRO_CONSTRUCTION_ZONES[locationName] || null;
}

module.exports = {
  getTrafficSpeed,
  detectTrafficTrigger,
  classifyTrafficIncident,
  applyTTMCaps,
  isMetroConstructionZone,
  METRO_CONSTRUCTION_ZONES,
};
