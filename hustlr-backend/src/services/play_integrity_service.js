const crypto = require('crypto');
const { GoogleAuth } = require('google-auth-library');
const axios = require('axios');

const NONCE_TTL_MS = 5 * 60 * 1000;
const nonceStore = new Map();

function pruneNonces() {
  const now = Date.now();
  for (const [n, exp] of nonceStore) {
    if (exp < now) nonceStore.delete(n);
  }
}

/**
 * Issue a one-time nonce for Play Integrity (recommended by Google).
 */
function issueNonce() {
  pruneNonces();
  // Google expects a Base64-encoded nonce (standard base64 for broad client compatibility).
  const nonce = crypto.randomBytes(24).toString('base64');
  nonceStore.set(nonce, Date.now() + NONCE_TTL_MS);
  return { nonce, expires_in: Math.floor(NONCE_TTL_MS / 1000) };
}

/**
 * Validate and consume nonce (single use).
 */
function consumeNonce(nonce) {
  if (!nonce || typeof nonce !== 'string') return false;
  pruneNonces();
  const exp = nonceStore.get(nonce);
  if (!exp || exp < Date.now()) {
    nonceStore.delete(nonce);
    return false;
  }
  nonceStore.delete(nonce);
  return true;
}

function buildGoogleAuth() {
  const raw = process.env.PLAY_INTEGRITY_SERVICE_ACCOUNT_JSON;
  if (raw && raw.trim()) {
    return new GoogleAuth({
      credentials: JSON.parse(raw),
      scopes: ['https://www.googleapis.com/auth/playintegrity'],
    });
  }
  const keyFile = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  if (keyFile && keyFile.trim()) {
    return new GoogleAuth({
      keyFile,
      scopes: ['https://www.googleapis.com/auth/playintegrity'],
    });
  }
  return null;
}

/**
 * POST .../v1/{packageName}:decodeIntegrityToken
 */
async function decodeIntegrityToken(integrityToken, packageName) {
  const auth = buildGoogleAuth();
  if (!auth) {
    const err = new Error('missing_credentials');
    err.code = 'missing_credentials';
    throw err;
  }

  const client = await auth.getClient();
  const { token: accessToken } = await client.getAccessToken();
  if (!accessToken) {
    const err = new Error('no_access_token');
    err.code = 'no_access_token';
    throw err;
  }

  const url = `https://playintegrity.googleapis.com/v1/${encodeURIComponent(packageName)}:decodeIntegrityToken`;
  const response = await axios.post(
    url,
    { integrityToken },
    {
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      timeout: 20000,
      validateStatus: () => true,
    },
  );

  const data = response.data;
  if (response.status >= 400 || data.error) {
    const ge = data.error || { message: `HTTP ${response.status}` };
    const err = new Error(ge.message || 'play_integrity_api_error');
    err.code = 'google_api_error';
    err.details = ge;
    err.status = response.status;
    throw err;
  }

  return data;
}

/**
 * Map Google verdicts → pass/fail + summary for fraud / claims.
 */
function evaluateVerdicts(payloadExternal) {
  if (!payloadExternal) {
    return { pass: false, reason: 'empty_payload', summary: {} };
  }

  const app = payloadExternal.appIntegrity?.appRecognitionVerdict;
  const deviceList = payloadExternal.deviceIntegrity?.deviceRecognitionVerdict;
  const devices = Array.isArray(deviceList) ? deviceList : deviceList ? [deviceList] : [];

  const relaxedApp = process.env.PLAY_INTEGRITY_RELAXED_APP === 'true';
  const appOk =
    app === 'PLAY_RECOGNIZED' ||
    (relaxedApp && (app === 'UNRECOGNIZED_VERSION' || app === 'UNEVALUATED'));

  const deviceOk =
    devices.includes('MEETS_STRONG_INTEGRITY') ||
    devices.includes('MEETS_DEVICE_INTEGRITY');

  const relaxedDevice = process.env.PLAY_INTEGRITY_RELAXED_DEVICE === 'true';
  const pass = appOk && (deviceOk || relaxedDevice);

  return {
    pass,
    reason: pass
      ? 'ok'
      : !appOk
        ? `app_verdict:${app || 'missing'}`
        : `device_verdict:${devices.join(',') || 'missing'}`,
    summary: {
      app_recognition_verdict: app,
      device_recognition_verdict: devices,
      request_package_name: payloadExternal.requestDetails?.requestPackageName,
    },
  };
}

/**
 * Full verify: decode token, optionally enforce server-issued nonce.
 */
async function verifyIntegrityToken(integrityToken, packageName, { skipNonce = false } = {}) {
  const data = await decodeIntegrityToken(integrityToken, packageName);
  const ext = data.tokenPayloadExternal;
  const requestNonce = ext?.requestDetails?.nonce;

  let nonceOk = true;
  if (process.env.PLAY_INTEGRITY_SKIP_NONCE_CHECK !== 'true' && !skipNonce) {
    nonceOk = consumeNonce(requestNonce);
  }

  const verdict = evaluateVerdicts(ext);

  return {
    ok: verdict.pass && nonceOk,
    play_integrity_pass: verdict.pass && nonceOk,
    nonce_valid: nonceOk,
    verdict: verdict.reason,
    summary: verdict.summary,
    raw_request_details: ext?.requestDetails
      ? {
          request_package_name: ext.requestDetails.requestPackageName,
          timestamp_millis: ext.requestDetails.timestampMillis,
        }
      : undefined,
  };
}

function isConfigured() {
  return !!(
    (process.env.PLAY_INTEGRITY_SERVICE_ACCOUNT_JSON && process.env.PLAY_INTEGRITY_SERVICE_ACCOUNT_JSON.trim()) ||
    (process.env.GOOGLE_APPLICATION_CREDENTIALS && process.env.GOOGLE_APPLICATION_CREDENTIALS.trim())
  );
}

module.exports = {
  issueNonce,
  consumeNonce,
  decodeIntegrityToken,
  verifyIntegrityToken,
  evaluateVerdicts,
  isConfigured,
};
