module.exports = {
  BASE_PREMIUMS: { basic: 29, standard: 49, full: 79, elite: 109 },
  MAX_PAYOUTS: { basic: 400, standard: 700, full: 1200, elite: 2000 },
  TIER_FACTORS: { basic: 1.0, standard: 1.2, full: 1.5, elite: 1.8 },
  PAYOUT_PERCENTAGES: {
    rain_heavy: 0.85,
    rain_moderate: 0.60,
    rain_light: 0.30,
    heat_severe: 0.50,
    heat_stress: 0.25,
    aqi_hazardous: 0.70,
    aqi_very_unhealthy: 0.40,
    platform_outage: 0.80,
    dark_store_closure: 1.0
  },
  WEEKLY_INCOME_ESTIMATE: 5000,
  PREMIUM_CAP_PERCENT: 0.03,
  ZONE_RISK: {
    adyar: 0.72,
    korattur: 0.45,
    t_nagar: 0.68,
    anna_nagar: 0.41,
    velachery: 0.65,
    tambaram: 0.55
  }
};
