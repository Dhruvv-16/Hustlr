require('dotenv').config();
const express = require('express');
const cors = require('cors');

const authRoutes = require('./routes/auth.routes');
const workerRoutes = require('./routes/worker.routes');
const policyRoutes = require('./routes/policy.routes');
const claimsRoutes = require('./routes/claims.routes');
const walletRoutes = require('./routes/wallet.routes');
const disruptionRoutes = require('./routes/disruption.routes');
const guidewireRoutes = require('./routes/guidewire.routes');
const citiesRoutes = require('./routes/cities.routes');
const integrityRoutes = require('./routes/integrity.routes');
const mlService = require('./services/ml_service');
const { startDisruptionCron, getDisruptionCronStatus } = require('./services/disruption_cron');
const { startRegionalWeeklyCron, getRegionalCronStatus } = require('./services/regional_weekly_cron');

const app = express();

// Browser clients (e.g. Flutter web on Vercel): set CORS_ORIGIN=https://app.vercel.app (comma-separated for several).
if (process.env.CORS_ORIGIN && process.env.CORS_ORIGIN.trim() && process.env.CORS_ORIGIN.trim() !== '*') {
  const origins = process.env.CORS_ORIGIN.split(',').map((s) => s.trim()).filter(Boolean);
  app.use(
    cors({
      origin: origins.length === 1 ? origins[0] : origins,
      credentials: true,
    }),
  );
} else {
  app.use(cors());
}
app.use(express.json());

// Mount routes
app.use('/auth', authRoutes);
app.use('/workers', workerRoutes);
app.use('/policies', policyRoutes);
app.use('/claims', claimsRoutes);
app.use('/wallet', walletRoutes);
app.use('/disruptions', disruptionRoutes);
app.use('/guidewire', guidewireRoutes);
app.use('/cities', citiesRoutes);
app.use('/integrity', integrityRoutes);

// Health check (root)
app.get('/', (req, res) => {
  res.json({ status: 'ok', service: 'hustlr-backend' });
});

// Dedicated health endpoint pinged by the Flutter app
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    service: 'hustlr-backend',
    timestamp: new Date().toISOString(),
    uptime_seconds: Math.floor(process.uptime()),
  });
});

// Per-service health — real-time state from the api_wrapper circuit breaker
// plus env-key presence checks for APIs that aren't self-reporting.
app.get('/health/services', async (req, res) => {
  const { getAPIHealth } = require('./services/api_wrapper');
  const liveHealth = getAPIHealth(); // { weather, aqi, news, platform, internet, cell_tower, traffic }

  function toStatus(name) {
    const s = liveHealth[name];
    if (!s) return 'unknown';
    if (s.healthy && s.failures === 0) return 'ok';
    if (!s.healthy) return 'degraded';
    return 'ok'; // failures > 0 but still healthy = recovering
  }

  function envPresent(key) {
    return process.env[key] ? 'ok' : 'missing_key';
  }

  const { isMaxMindConfigured } = require('./services/maxmind_service');

  function maxmindEnvStatus() {
    if (isMaxMindConfigured()) return 'ok';
    const a = !!(process.env.MAXMIND_ACCOUNT_ID || '').trim();
    const b = !!(process.env.MAXMIND_LICENSE_KEY || '').trim();
    if (!a && !b) return 'missing_key';
    return 'partial_key';
  }

  const ooklaKey = (process.env.OOKLA_API_KEY || '').trim();
  const ooklaEnabled =
    process.env.USE_OOKLA_INTERNET === 'true' && ooklaKey.length > 0;
  let ooklaInternetStatus = 'inferred_only';
  if (ooklaEnabled) ooklaInternetStatus = 'enterprise_live';
  else if (ooklaKey.length > 0) {
    ooklaInternetStatus = 'key_present_opt_in_disabled';
  }

  const {
    isConfigured: playIntegrityConfigured,
    isSimulatedMode,
  } = require('./services/play_integrity_service');
  let playIntegrityStatus = 'not_configured';
  if (process.env.PLAY_INTEGRITY_BYPASS_DEV === 'true') playIntegrityStatus = 'dev_bypass';
  else if (isSimulatedMode()) playIntegrityStatus = 'simulated';
  else if (playIntegrityConfigured()) playIntegrityStatus = 'configured';

  res.json({
    // Core
    supabase:   envPresent('SUPABASE_URL'),
    // Weather & Environment
    weather:    toStatus('weather'),
    aqi:        toStatus('aqi'),
    traffic:    toStatus('traffic'),
    // Intelligence
    news:       toStatus('news'),
    cell_tower: toStatus('cell_tower'),
    opencellid: process.env.OPENCELLID_API_KEY ? 'ok' : 'ok', // Safely hardcoded in cell_tower_service.js
    maxmind:    maxmindEnvStatus(),
    ookla_internet: ooklaInternetStatus,
    // Payments & Notifications
    instamojo:  envPresent('INSTAMOJO_API_KEY'),
    razorpay:   envPresent('RAZORPAY_KEY_ID'),
    guidewire:       process.env.ENABLE_GUIDEWIRE_ROUTES === 'true' ? 'enabled' : 'off',
    play_integrity:  playIntegrityStatus,
    firebase:   envPresent('FIREBASE_SERVER_KEY'),
    ml_service: (await mlService.isMlOnline()) ? 'ok' : 'offline',
    // Failure counts for detail
    _failures: Object.fromEntries(
      Object.entries(liveHealth).map(([k, v]) => [k, v.failures])
    ),
  });
});

app.get('/health/cron', (req, res) => {
  res.json({
    ...getDisruptionCronStatus(),
    regional_weekly: getRegionalCronStatus(),
  });
});


const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`hustlr-backend listening on port ${PORT}`);
  startDisruptionCron();
  startRegionalWeeklyCron();
});
