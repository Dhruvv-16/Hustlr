// services/aqi_service.js
// OWM Air Pollution API (free tier)
// Endpoint: api.openweathermap.org/data/2.5/air_pollution
// OWM AQI scale: 1=Good 2=Fair 3=Moderate 4=Poor 5=VeryPoor

const axios            = require('axios');
const { withFallback } = require('./api_wrapper');
const { FALLBACKS }    = require('./fallback_service');

const AQICN_KEY = process.env.AQICN_API_KEY;

const ZONE_COORDS = {
  'Adyar Dark Store Zone':        { lat: 13.0067, lon: 80.2574 },
  'default':                      { lat: 13.0827, lon: 80.2707 },
};

function getCoordsForZone(zone) {
  if (ZONE_COORDS[zone]) return ZONE_COORDS[zone];
  return ZONE_COORDS['default'];
}

async function getCurrentAQI(zone = 'Adyar Dark Store Zone') {
  const coords = getCoordsForZone(zone);

  return withFallback(
    'aqi',
    async () => {
      const url = `https://api.waqi.info/feed/geo:${coords.lat};${coords.lon}/`;
      const res = await axios.get(url, {
        timeout: 5000,
        params: {
          token: AQICN_KEY,
        },
      });

      if (res.data.status !== 'ok') {
        throw new Error(`AQICN API failed: ${res.data.data}`);
      }

      const d = res.data.data;
      const usAqi = typeof d.aqi === 'number' ? d.aqi : parseInt(d.aqi, 10);
      
      if (isNaN(usAqi)) {
        throw new Error('Invalid or missing AQI value from AQICN');
      }

      return {
        aqi:        usAqi,
        pm25:       d.iaqi?.pm25?.v ?? 0,
        pm10:       d.iaqi?.pm10?.v ?? 0,
        no2:        d.iaqi?.no2?.v ?? 0,
        o3:         d.iaqi?.o3?.v ?? 0,
        station:    d.city?.name ?? `AQICN (${coords.lat},${coords.lon})`,
        updated_at: d.time?.iso ?? new Date().toISOString(),
        _source:    'live_aqicn',
      };
    },
    FALLBACKS.aqi
  );
}

// AQI trigger check: US AQI >= 200 (Severe Pollution)
function assessAQIDisruption(aqi) {
  if (aqi.aqi >= 200) {
    return {
      trigger_type:  'severe_pollution',
      display_name:  'Severe Pollution',
      hourly_rate:   40,
      severity:      Math.min(aqi.aqi / 300, 1.0),
      current_value: `AQI ${aqi.aqi} (PM2.5: ${aqi.pm25}μg/m³)`,
      threshold:     'AQI 200',
      source:        aqi._source,
      active:        true,
    };
  }
  return null;
}

module.exports = { getCurrentAQI, assessAQIDisruption };
