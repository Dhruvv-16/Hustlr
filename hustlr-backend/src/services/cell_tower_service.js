// src/services/cell_tower_service.js
const axios = require('axios');
const { withFallback } = require('./api_wrapper');
const { FALLBACKS } = require('./fallback_service');

const CELL_API_KEY = process.env.CELL_LOCATION_API_KEY || 'pk.91ac11fadeafd226668b5b6eba0da147';

/**
 * Estimates the user's geographic location using cell tower data
 * Uses Unwired Labs / LocationAPI for real-time geolocation.
 * @param {Object} payload JSON object containing nearby cell tower information
 * @returns {Object} Estimated location or error
 */
async function estimateLocation(payload) {
  if (!payload || !payload.cells || !Array.isArray(payload.cells) || payload.cells.length === 0) {
    return { error: 'Insufficient cell data' };
  }

  // Pre-process cells to match standard LocationAPI payload format
  const formattedCells = payload.cells.map(c => ({
    lac: c.lac,
    cid: c.cellId || c.cid,
    psc: c.psc || 0,
    signal: c.signal
  }));

  const mnc = payload.cells[0].mnc;
  const mcc = payload.cells[0].mcc;

  return withFallback(
    'cell_tower',
    async () => {
      const url = 'https://us1.unwiredlabs.com/v2/process.php';
      const requestBody = {
        token: CELL_API_KEY,
        radio: payload.radio || 'lte', // default to lte
        mcc: mcc,
        mnc: mnc,
        cells: formattedCells,
        address: 0 // set to 0 to make it faster (no reverse geocoding needed)
      };

      const res = await axios.post(url, requestBody, {
        timeout: 5000,
        headers: { 'Content-Type': 'application/json' }
      });

      if (res.data.status !== 'ok' && res.data.status !== 'success') {
        throw new Error(`LocationAPI failed: ${res.data.message || res.data.status}`);
      }

      // Return final JSON following the rules structure
      return {
        lat: res.data.lat,
        lng: res.data.lon,
        accuracy: res.data.accuracy,
        source: 'live_cell_tower_api'
      };
    },
    FALLBACKS.cell_tower
  );
}

module.exports = { estimateLocation };
