const express = require('express');
const router = express.Router();

const { fetchDisruptionBundle, getAQILevel } = require('../services/disruption_snapshot');
const { getAPIHealth } = require('../services/api_wrapper');
const mlService = require('../services/ml_service');
const { attachWorkAdvisor } = require('../services/work_advisor_service');

// Literal paths must be registered before `/:zone` so "forecast" is not treated as a zone name.

// ─── GET /disruptions/forecast/:zone ──────────────────
router.get('/forecast/:zone', async (req, res) => {
  const { zone } = req.params;
  try {
    const forecast = await mlService.getForecast(zone);
    return res.json(forecast);
  } catch (e) {
    return res.status(500).json({ zone, forecast: [], error: e.message });
  }
});

// ─── Health check ─────────────────────────────
router.get('/health/apis', async (req, res) => {
  return res.json({
    api_health: getAPIHealth(),
    checked_at: new Date().toISOString(),
  });
});

// ─── Debug routes ─────────────────────────────
router.get('/weather/current', async (req, res) => {
  const { getCurrentWeather } = require('../services/weather_service');
  const data = await getCurrentWeather();
  return res.json(data);
});

router.get('/aqi/current', async (req, res) => {
  const { getCurrentAQI } = require('../services/aqi_service');
  const data = await getCurrentAQI();
  return res.json(data);
});

router.get('/news/check', async (req, res) => {
  const { checkBandhNLP } = require('../services/news_service');
  const zone = req.query.zone;
  const data = await checkBandhNLP(zone);
  return res.json(data);
});

// ─── GET /disruptions/:zone ───────────────────
router.get('/:zone', async (req, res) => {
  const { zone } = req.params;

  try {
    const body = await fetchDisruptionBundle(zone, { useCache: true });
    let issOpt;
    if (req.query.iss != null && req.query.iss !== '') {
      const n = parseInt(String(req.query.iss), 10);
      if (Number.isFinite(n)) issOpt = n;
    }
    body.work_advisor = await attachWorkAdvisor(zone, body, { iss_score: issOpt });
    return res.json(body);
  } catch (e) {
    console.error('[Disruptions] Critical error:', e.message);
    return res.status(500).json({
      zone,
      active: false,
      disruptions: [],
      error: 'Disruption service error',
    });
  }
});

module.exports = router;
module.exports.getAQILevel = getAQILevel;
