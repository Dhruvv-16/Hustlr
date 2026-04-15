/*
  ACTUARIAL PRICING MODEL — Updated from image-validated model
  Formula: Premium = (Trigger Probability × Avg Daily Income Lost × Exposed Days) ÷ Target BCR

  Basic Shield:    (0.18 × ₹420 × 1.4 days) ÷ 0.62 = ₹170 pure → 20% load → ₹35/wk
  Standard Shield: (0.27 × ₹420 × 1.8 days) ÷ 0.63 = ₹325 pure → 18% load → ₹59/wk
  Full Shield:     (0.35 × ₹420 × 2.1 days) ÷ 0.65 = ₹474 pure → 17% load → ₹79/wk

  Avg daily income used: ₹420 (validated Chennai gig worker data)
  Old ₹29/wk would have produced BCR ~0.83 → suspend-enrollment threshold.
*/
const PLAN_CONFIG = {
  basic:    {
    base: 35,
    max_payout: 400,         // weekly cap
    daily_cap: 120,          // max payout per day
    name: 'Basic Shield',
    target_bcr: 0.62,
    covered_triggers: ['rain_heavy', 'rain_extreme', 'heat_severe'],
  },
  standard: {
    base: 59,
    max_payout: 500,         // weekly cap
    daily_cap: 150,          // max payout per day
    name: 'Standard Shield',
    target_bcr: 0.63,
    covered_triggers: ['rain_heavy', 'rain_extreme', 'heat_severe', 'aqi_hazardous', 'platform_outage', 'bandh'],
  },
  full:     {
    base: 79,
    max_payout: 650,         // weekly cap
    daily_cap: 200,          // max payout per day
    name: 'Full Shield',
    target_bcr: 0.65,
    covered_triggers: 'all', // all 9 triggers + compound bonus
    compound_bonus: true,
  },
};

// TIER FACTORS for ISS multiplier (plan tier multiplier)
// Basic = 1.0×, Standard = 1.25×, Full = 1.5× (+ 1.2-1.3× on compound)

module.exports = {
  PLAN_CONFIG,

  // Tier factors for ISS-based premium multiplier
  TIER_FACTORS: { basic: 1.0, standard: 1.25, full: 1.5 },

  // ── Per-trigger hourly rates (from actuarial model image) ─────────────────
  // Payout = hourly_rate × disruption_hours (capped by daily_cap)
  HOURLY_RATES: {
    rain_heavy:        40,   // 64.5–115mm/hr · 8×/yr · Medium
    rain_extreme:      65,   // >115mm/hr cyclone band · 2×/yr · High
    heat_severe:       45,   // >43°C IMD forecast · 5×/yr · Medium
    aqi_hazardous:     35,   // >200 AQI AQICN/CPCB · 3×/yr · Low
    platform_outage:   50,   // >60% order failure rate · 6×/yr · Medium
    bandh:             55,   // NLP >0.6 NewsAPI · 3×/yr · Medium
    traffic_severe:    30,   // Speed 40% below baseline · 10×/yr · Low
    internet_blackout: 45,   // <10% connectivity 30min · 2×/yr · Medium
    cyclone_landfall:  80,   // IMD Cat 1-5 Oct-Dec · 0.4×/yr · Critical
  },

  // ── Per-trigger daily payout caps ────────────────────────────────────────
  DAILY_CAPS: {
    rain_heavy:        120,
    rain_extreme:      200,
    heat_severe:       130,
    aqi_hazardous:     100,
    platform_outage:   140,
    bandh:             150,
    traffic_severe:    80,
    internet_blackout: 110,   // 2-hour cap built in
    cyclone_landfall:  300,
  },

  // ── Trigger frequencies (events/year in Chennai) ─────────────────────────
  TRIGGER_FREQUENCY: {
    rain_heavy:        8,
    rain_extreme:      2,
    heat_severe:       5,
    aqi_hazardous:     3,
    platform_outage:   6,
    bandh:             3,
    traffic_severe:    10,
    internet_blackout: 2,
    cyclone_landfall:  0.4,
  },

  // ── Compound trigger bonuses (Full Shield only) ───────────────────────────
  COMPOUND_BONUSES: {
    'rain_heavy+platform_outage': { multiplier: 1.0, type: 'additive', note: '100% of both rates, no cap overlap' },
    'cyclone_landfall+bandh':     { multiplier: 1.2, type: 'multiplicative', note: '20% bonus on top cyclone cap' },
    'heat_severe+aqi_hazardous':  { multiplier: 1.1, type: 'multiplicative', note: '10% bonus on higher rate' },
    'rain_extreme+internet_blackout': { multiplier: 1.3, type: 'multiplicative', weekly_cap_override: 800, note: 'Catastrophic — weekly cap lifted to ₹800' },
  },

  // ── Shift-hour payout multipliers ────────────────────────────────────────
  SHIFT_MULTIPLIERS: {
    peak:     1.0,   // 9am–6pm  → 100% rate
    offpeak:  0.75,  // 6pm–10pm → 75%
    prepeak:  0.50,  // 8am–9am  → 50%
    night:    0.0,   // <8am, >10pm → 0% (not working)
  },

  // ── Zone depth multipliers (distance from dark store) ────────────────────
  ZONE_DEPTH_MULTIPLIERS: {
    core:   1.0,   // >2km from dark store → 85–100% cap
    middle: 0.70,  // 500m–2km → 60–80%
    outer:  0.30,  // 0–500m (close to dark store) → 30%
  },

  // ── Add-on pricing ────────────────────────────────────────────────────────
  ADDONS: {
    cyclone_cover:   { weekly: 20, note: 'Oct–Dec season only. 0.04×/yr, ₹300/day payout.' },
    curfew_strike:   { weekly: 12, note: 'NewsAPI NLP trigger. ~3 events/yr Chennai avg.' },
    election_day:    { weekly: 8,  note: 'Fixed event calendar. Low adverse selection risk.' },
    app_downtime:    { weekly: 10, note: 'Basic plan only. Already included in Standard+.' },
  },

  // ── Worker activity loading ───────────────────────────────────────────────
  ACTIVITY_LOADING: {
    above_20_days:   1.00,  // standard rate
    between_10_20:   1.08,  // +8% loading (less behavioral baseline)
    below_10_days:   null,  // declined — insufficient fraud baseline
  },

  // ── Monsoon season surcharge (Oct–Dec) ───────────────────────────────────
  MONSOON_SURCHARGE: 0.22,  // +22% premium Oct–Dec; BCR must remain ≤0.70

  // ── Systemic risk surcharge (3+ add-ons together) ────────────────────────
  ADDON_SYSTEMIC_SURCHARGE: 0.10,  // +10% when cyclone+bandh+blackout together

  // ── Reinsurance XL treaty trigger ────────────────────────────────────────
  REINSURANCE_TRIGGER: 4.0,  // 4× weekly pool → reinsurance treaty activated

  // ── Weekly income estimate (Chennai gig worker validated) ────────────────
  WEEKLY_INCOME_ESTIMATE: 2940,  // ₹420/day × 7 (used in actuarial formula)
  AVG_DAILY_INCOME: 420,
  PREMIUM_CAP_PERCENT: 0.03,

  // ── Zone flood risk (for ISS scoring) ────────────────────────────────────
  ZONE_RISK: {
    adyar: 0.72, korattur: 0.45, t_nagar: 0.68,
    anna_nagar: 0.41, velachery: 0.65, tambaram: 0.55,
    porur: 0.50, chromepet: 0.52, sholinganallur: 0.58, guindy: 0.48,
  },
};
