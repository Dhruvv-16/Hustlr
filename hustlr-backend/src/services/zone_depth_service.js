/**
 * Zone depth vs dark-store hub: distance rings → underwriting-style score [0.35, 1.0].
 * Coordinates default to a Chennai dark-store–style anchor (override via env).
 */

const EARTH_KM = 6371;

function toRad(d) {
  return (d * Math.PI) / 180;
}

function haversineKm(lat1, lon1, lat2, lon2) {
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) *
      Math.cos(toRad(lat2)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return EARTH_KM * c;
}

function scoreFromDistanceKm(km) {
  if (km <= 2) return 1.0;
  if (km <= 5) return 0.85;
  if (km <= 10) return 0.65;
  const decay = 0.02 * (km - 10);
  return Math.max(0.35, 0.65 - decay);
}

function computeZoneDepth(lat, lon) {
  let hubLat = parseFloat(process.env.DARK_STORE_LAT || '12.982');
  let hubLon = parseFloat(process.env.DARK_STORE_LON || '80.243');
  if (!Number.isFinite(hubLat)) hubLat = 12.982;
  if (!Number.isFinite(hubLon)) hubLon = 80.243;
  const distance_km = haversineKm(lat, lon, hubLat, hubLon);
  const zone_depth_score = scoreFromDistanceKm(distance_km);
  return {
    distance_km: Math.round(distance_km * 1000) / 1000,
    zone_depth_score: Math.round(zone_depth_score * 1000) / 1000,
    hub: { lat: hubLat, lon: hubLon },
  };
}

module.exports = { computeZoneDepth, haversineKm };
