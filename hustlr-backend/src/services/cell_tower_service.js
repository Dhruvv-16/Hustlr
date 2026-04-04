// src/services/cell_tower_service.js
// Location from cell towers: OpenCelliD (optional) → Unwired Labs / LocationAPI → fallback.

const axios = require('axios');
const { withFallback } = require('./api_wrapper');
const { FALLBACKS } = require('./fallback_service');

const UNWIRED_KEY = process.env.CELL_LOCATION_API_KEY || '';
const OPENCELLID_KEY = process.env.OPENCELLID_API_KEY || 'pk.28291702cc0fe8633be9310cafe2260b';

const OPENCELLID_URL = 'https://opencellid.org/cell/get';

/**
 * OpenCelliD — first cell only; free tier may require whitelisted key (see opencellid.org).
 * @see https://wiki.opencellid.org/wiki/API
 */
async function tryOpenCellId(payload) {
  if (!OPENCELLID_KEY) return null;

  const c = payload.cells[0];
  const cellid = c.cellId ?? c.cid ?? c.cellid;
  const lac = c.lac ?? c.tac;
  if (cellid == null || lac == null || c.mcc == null || c.mnc == null) {
    return null;
  }

  const params = {
    key: OPENCELLID_KEY,
    mcc: c.mcc,
    mnc: c.mnc,
    lac,
    cellid,
    format: 'json',
  };
  if (payload.radio) params.radio = String(payload.radio).toUpperCase();

  const res = await axios.get(OPENCELLID_URL, {
    params,
    timeout: 8000,
    validateStatus: () => true,
  });

  if (res.status !== 200 || !res.data) {
    return null;
  }

  const lat = res.data.lat;
  const lon = res.data.lon;
  if (lat == null || lon == null) {
    return null;
  }

  return {
    lat: Number(lat),
    lng: Number(lon),
    accuracy: res.data.range != null ? Number(res.data.range) : 1000,
    source: 'opencellid',
    samples: res.data.samples,
  };
}

/**
 * Estimates geographic location from nearby cell tower data.
 * Order: OpenCelliD (if OPENCELLID_API_KEY) → Unwired (if CELL_LOCATION_API_KEY) → api_wrapper fallback.
 */
async function estimateLocation(payload) {
  if (!payload || !payload.cells || !Array.isArray(payload.cells) || payload.cells.length === 0) {
    return { error: 'Insufficient cell data' };
  }

  try {
    const oc = await tryOpenCellId(payload);
    if (oc) return oc;
  } catch (e) {
    console.warn('[OpenCelliD]', e.message);
  }

  if (!UNWIRED_KEY) {
    return {
      ...FALLBACKS.cell_tower,
      _source: 'fallback_no_cell_api_keys',
      hint: 'Set OPENCELLID_API_KEY and/or CELL_LOCATION_API_KEY for live cell lookup',
    };
  }

  const formattedCells = payload.cells.map((c) => ({
    lac: c.lac,
    cid: c.cellId || c.cid,
    psc: c.psc || 0,
    signal: c.signal,
  }));

  const mnc = payload.cells[0].mnc;
  const mcc = payload.cells[0].mcc;

  return withFallback(
    'cell_tower',
    async () => {
      const url = 'https://us1.unwiredlabs.com/v2/process.php';
      const requestBody = {
        token: UNWIRED_KEY,
        radio: payload.radio || 'lte',
        mcc,
        mnc,
        cells: formattedCells,
        address: 0,
      };

      const res = await axios.post(url, requestBody, {
        timeout: 5000,
        headers: { 'Content-Type': 'application/json' },
      });

      if (res.data.status !== 'ok' && res.data.status !== 'success') {
        throw new Error(`LocationAPI failed: ${res.data.message || res.data.status}`);
      }

      return {
        lat: res.data.lat,
        lng: res.data.lon,
        accuracy: res.data.accuracy,
        source: 'live_cell_tower_api',
      };
    },
    FALLBACKS.cell_tower
  );
}

module.exports = { estimateLocation, tryOpenCellId };
