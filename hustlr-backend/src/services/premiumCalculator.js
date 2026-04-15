const { PLAN_CONFIG, TIER_FACTORS, WEEKLY_INCOME_ESTIMATE, PREMIUM_CAP_PERCENT, ZONE_RISK } = require('../config/constants');

function calculatePremium(plan_tier, iss_score, zone, risk_score = 0.5) {
  const plan = PLAN_CONFIG[plan_tier];
  if (!plan) {
    throw new Error(`Invalid plan tier: ${plan_tier}`);
  }
  const base = plan.base;
  
  const tier_factor = TIER_FACTORS[plan_tier];
  const zone_risk = ZONE_RISK[(zone || '').toLowerCase()] || 0.5;
  const risk_multiplier = 0.8 + (risk_score * 1.7);
  
  const zone_adjustment = Math.round(base * zone_risk * 0.2);
  // (75 - iss_score) / 100 * base * -1
  const iss_adjustment = Math.round(((75 - iss_score) / 100) * base * -1);
  
  const raw_premium = Math.round(base * risk_multiplier * tier_factor);
  let final_premium = raw_premium + zone_adjustment + iss_adjustment;
  
  const cap = Math.floor(WEEKLY_INCOME_ESTIMATE * PREMIUM_CAP_PERCENT);
  final_premium = Math.min(final_premium, cap);
  
  return {
    base_premium: base,
    zone_adjustment,
    iss_adjustment,
    risk_adjustment: Math.round(base * (risk_multiplier - 1)),
    final_premium,
    breakdown_label: `${base} + ${zone_adjustment} + ${iss_adjustment} = ${final_premium}`
  };
}

module.exports = { calculatePremium };
