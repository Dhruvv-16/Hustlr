const cron = require('node-cron');
const { supabase } = require('../config/supabase');
const { listCityRiskProfiles } = require('./city_risk_service');

let lastWeeklyRunAt = null;
let lastWeeklyError = null;

function mondayWeekStart(d = new Date()) {
  const x = new Date(d);
  const day = x.getUTCDay();
  const diff = (day + 6) % 7;
  x.setUTCDate(x.getUTCDate() - diff);
  x.setUTCHours(0, 0, 0, 0);
  return x.toISOString().slice(0, 10);
}

async function runRegionalWeeklyScan() {
  if (process.env.DISABLE_REGIONAL_WEEKLY_CRON === 'true') {
    return;
  }
  if (!process.env.SUPABASE_URL || !process.env.SUPABASE_SERVICE_KEY) {
    console.warn('[RegionalCron] skipped — no Supabase');
    return;
  }

  const weekStart = mondayWeekStart();
  const profiles = listCityRiskProfiles();

  for (const p of profiles) {
    const riskScore =
      0.35 * p.flood_rain_index +
      0.2 * p.heat_index +
      0.2 * p.aqi_index +
      0.15 * p.platform_index +
      0.1 * p.bandh_index;

    const row = {
      week_start: weekStart,
      city: p.city,
      risk_score: Math.round(riskScore * 1000) / 1000,
      rain_exposure: p.flood_rain_index,
      aqi_stress: p.aqi_index,
      platform_risk: p.platform_index,
      summary: p.summary,
    };

    const { error } = await supabase
      .from('regional_intelligence_snapshots')
      .upsert(row, { onConflict: 'week_start,city' });

    if (error) {
      console.warn('[RegionalCron] upsert failed', p.city, error.message);
    }
  }

  lastWeeklyRunAt = new Date().toISOString();
  lastWeeklyError = null;
  console.log(`[RegionalCron] weekly scan done week=${weekStart} cities=${profiles.length}`);
}

function startRegionalWeeklyCron() {
  if (process.env.DISABLE_REGIONAL_WEEKLY_CRON === 'true') {
    console.log('[RegionalCron] disabled');
    return;
  }
  // Monday 06:30 UTC (~noon IST winter)
  const schedule = process.env.REGIONAL_CRON_SCHEDULE || '30 6 * * 1';
  cron.schedule(schedule, () => {
    runRegionalWeeklyScan().catch((e) => {
      lastWeeklyError = e.message;
      console.error('[RegionalCron] failed:', e.message);
    });
  });
  console.log(`[RegionalCron] scheduled ${schedule}`);

  if (process.env.RUN_REGIONAL_CRON_ON_BOOT === 'true') {
    runRegionalWeeklyScan().catch((e) => console.error('[RegionalCron] boot:', e.message));
  }
}

function getRegionalCronStatus() {
  return {
    last_run_at: lastWeeklyRunAt,
    last_error: lastWeeklyError,
    schedule: process.env.REGIONAL_CRON_SCHEDULE || '30 6 * * 1',
  };
}

module.exports = {
  startRegionalWeeklyCron,
  runRegionalWeeklyScan,
  getRegionalCronStatus,
};
