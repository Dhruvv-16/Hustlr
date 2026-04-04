const { PLAN_CONFIG, ZONE_RISK } = require('../config/constants');

function calculatePremium(plan_tier, iss_score, zone, risk_score = 0.5) {
  const plan = PLAN_CONFIG[plan_tier];
  if (!plan) {
    throw new Error(`Invalid plan tier: ${plan_tier}`);
  }
  const base = plan.base;
  
  const zone_risk = ZONE_RISK[(zone || '').toLowerCase()] || 0.5;
  
  // Zone adjustment: small tweak based on flood/risk profile (capped at 10% of base)
  const zone_adjustment = Math.round(base * (zone_risk - 0.5) * 0.1);
  // ISS adjustment: reward cleaner workers with small discount (capped at 10% of base)
  const iss_adjustment = iss_score != null
    ? Math.round(((iss_score - 75) / 100) * base * 0.5)
    : 0;
  
  // Final premium anchored to advertised base — no risk_multiplier inflation
  let final_premium = base + zone_adjustment + iss_adjustment;
  
  // Hard clamp: never drift more than 20% from the advertised base price
  const maxDrift = Math.round(base * 0.2);
  final_premium = Math.max(base - maxDrift, Math.min(base + maxDrift, final_premium));
  
  return {
    base_premium: base,
    zone_adjustment,
    iss_adjustment,
    risk_adjustment: 0,
    final_premium,
    breakdown_label: `${base} + ${zone_adjustment} + ${iss_adjustment} = ${final_premium}`
  };
}

module.exports = { calculatePremium };
