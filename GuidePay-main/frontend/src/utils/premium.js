const BASE = 49

const ZONES = {
  'kondapur-hyderabad': { flood: 0.85, curfew: 0.25, outage: 0.40 },
  'kurla-mumbai':       { flood: 0.80, curfew: 0.30, outage: 0.45 },
  'koramangala-bengaluru': { flood: 0.40, curfew: 0.20, outage: 0.55 },
}

export const getZoneMult = (zone) => {
  const r = ZONES[zone] || { flood: 0.5, curfew: 0.3, outage: 0.4 }
  return +(1 + (r.flood * 0.5) + (r.curfew * 0.3) + (r.outage * 0.2)).toFixed(2)
}

export const getWorkerMult = (score) =>
  score > 0.75 ? 0.85 : score >= 0.5 ? 1.00 : 1.15

export const calcPremium = (zone, score) =>
  Math.round(BASE * getZoneMult(zone) * getWorkerMult(score))

export const getBreakdown = (zone, score) => {
  const zm = getZoneMult(zone)
  const wm = getWorkerMult(score)
  return {
    base: BASE,
    zone: Math.round(BASE * (zm - 1)),
    worker: Math.round(BASE * zm * (wm - 1)),
    total: Math.round(BASE * zm * wm),
  }
}
