const express = require('express');
const router  = express.Router();

const {
  getCurrentWeather,
  get7DayForecast,
  assessDisruptions,
  buildPredictiveNudge,
} = require('../services/weather_service');

const { getCurrentAQI, assessAQIDisruption }
  = require('../services/aqi_service');

const { checkBandhNLP }
  = require('../services/news_service');

const {
  getPlatformStatus,
  detectPlatformTrigger,
  getInternetStatus,
  detectInternetTrigger,
} = require('../services/platform_service');

const { getAPIHealth } = require('../services/api_wrapper');

// ─── 10-minute shared cache ───────────────────
let cache = {};
const CACHE_MS = 10 * 60 * 1000;

async function getCached(key, fn) {
  const now = Date.now();
  if (cache[key] && (now - cache[key].ts) < CACHE_MS) {
    return cache[key].data;
  }
  const data   = await fn();
  cache[key]   = { data, ts: now };
  return data;
}

// ─── GET /disruptions/:zone ───────────────────
router.get('/:zone', async (req, res) => {
  const { zone } = req.params;

  try {
    // All APIs called in parallel — fastest possible response
    const [weather, forecast, aqi, news, platformStatus, internetStatus] =
      await Promise.all([
        getCached('weather',  () => getCurrentWeather(zone)),
        getCached('forecast', () => get7DayForecast(zone)),
        getCached('aqi',      () => getCurrentAQI(zone)),
        getCached('news',     () => checkBandhNLP(zone)),
        getPlatformStatus(zone),
        getInternetStatus(zone),
      ]);

    // Assess all disruption triggers
    const disruptions = assessDisruptions(weather);

    const aqiTrigger = assessAQIDisruption(aqi);
    if (aqiTrigger) disruptions.push(aqiTrigger);

    const platformTrigger = detectPlatformTrigger(platformStatus);
    if (platformTrigger) disruptions.push(platformTrigger);

    const internetTrigger = detectInternetTrigger(internetStatus);
    if (internetTrigger) disruptions.push(internetTrigger);

    // Bandh detection from news
    if (news.bandh_detected && news.confidence >= 0.6) {
      disruptions.push({
        trigger_type:  'bandh',
        display_name:  'Bandh / Shutdown',
        hourly_rate:   50,
        severity:      news.confidence,
        current_value: 'News confidence: ' + Math.round(news.confidence * 100) + '%',
        threshold:     '60% news confidence',
        payout_pct:    70,
        active:        true,
        source:        news.source ?? 'NewsAPI',
      });
    }

    const nudge = buildPredictiveNudge(forecast);

    // Data source transparency
    const data_sources = {
      weather:  weather._source  ?? 'live',
      aqi:      aqi._source      ?? 'live',
      news:     news.source      ?? 'live',
      platform: platformStatus._source ?? 'inferred',
      internet: internetStatus._source ?? 'inferred',
    };

    return res.json({
      zone,
      active:      disruptions.length > 0,
      disruptions,
      weather: {
        temp_celsius:   weather.temp_celsius,
        rainfall_mm_1h: weather.rainfall_mm_1h,
        condition:      weather.condition,
        humidity:       weather.humidity,
        local_time:     weather.local_time,
        is_day:         weather.is_day,
      },
      aqi: {
        current: aqi.aqi,
        pm25:    aqi.pm25,
        level:   getAQILevel(aqi.aqi),
        station: aqi.station,
      },
      platform: {
        status:        platformStatus.status,
        failure_rate:  platformStatus.order_failure_rate,
        orders_active: platformStatus.orders_last_hour,
        is_peak:       platformStatus.is_peak_hour,
      },
      news_alert: news.bandh_detected ? {
        detected:   true,
        confidence: news.confidence,
        headline:   news.matched_keywords.join(', ') || null,
      } : null,
      predictive_nudge: nudge,
      forecast,
      data_sources,
      checked_at: new Date().toISOString(),
    });

  } catch (e) {
    console.error('[Disruptions] Critical error:', e.message);
    return res.status(500).json({
      zone,
      active:      false,
      disruptions: [],
      error:       'Disruption service error',
    });
  }
});

// ─── Health check ─────────────────────────────
router.get('/health/apis', async (req, res) => {
  return res.json({
    api_health: getAPIHealth(),
    cache_keys: Object.keys(cache),
    checked_at: new Date().toISOString(),
  });
});

// ─── Debug routes ─────────────────────────────
router.get('/weather/current', async (req, res) => {
  const data = await getCurrentWeather();
  return res.json(data);
});

router.get('/aqi/current', async (req, res) => {
  const data = await getCurrentAQI();
  return res.json(data);
});

router.get('/news/check', async (req, res) => {
  const zone = req.query.zone;
  const data = await checkBandhNLP(zone);
  return res.json(data);
});

// ─── Helper ───────────────────────────────────
function getAQILevel(aqi) {
  if (aqi <= 50)  return 'Good';
  if (aqi <= 100) return 'Moderate';
  if (aqi <= 150) return 'Unhealthy for Sensitive Groups';
  if (aqi <= 200) return 'Unhealthy';
  if (aqi <= 300) return 'Very Unhealthy';
  return 'Hazardous';
}

module.exports = router;
