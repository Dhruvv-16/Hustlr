const axios = require('axios');

const MAXMIND_ACCOUNT = process.env.MAXMIND_ACCOUNT_ID;
const MAXMIND_LICENSE = process.env.MAXMIND_LICENSE_KEY;

async function checkIpLocation(ipAddress, claimedZone) {
  try {
    const auth = Buffer.from(`${MAXMIND_ACCOUNT}:${MAXMIND_LICENSE}`).toString('base64');
    
    const res = await axios.get(`https://geolite.info/geoip/v2.1/city/${ipAddress}`, {
      headers: {
        Authorization: `Basic ${auth}`
      },
      timeout: 5000
    });
    
    const data = res.data;
    const ipLat = data.location?.latitude || 0;
    const ipLon = data.location?.longitude || 0;
    const ipCity = data.city?.names?.en || 'unknown';
    const isp = data.traits?.isp || 'unknown';
    
    const isHomeBroadband = data.traits?.connection_type === 'Cable/DSL';
    
    const claimedStr = (claimedZone || '').toLowerCase();
    const cityStr = ipCity.toLowerCase();
    const cityMatch = claimedStr.includes(cityStr);
                      
    console.log(`[MaxMind] LIVE | ip=${ipAddress} | city=${ipCity}`);
    
    return {
      source: 'live_maxmind',
      ip_city: ipCity,
      ip_lat: ipLat,
      ip_lon: ipLon,
      isp: isp,
      is_home_broadband: isHomeBroadband,
      city_matches_zone: cityMatch,
      fraud_signal: isHomeBroadband && !cityMatch,
      timestamp: new Date().toISOString()
    };
  } catch (e) {
    console.warn(`[MaxMind] failed: ${e.message} — using mock`);
    return {
      source: 'mock',
      ip_city: 'Chennai',
      ip_lat: 13.0067,
      ip_lon: 80.2574,
      isp: 'Airtel Mobile',
      is_home_broadband: false,
      city_matches_zone: true,
      fraud_signal: false,
      timestamp: new Date().toISOString()
    };
  }
}

module.exports = { checkIpLocation };
