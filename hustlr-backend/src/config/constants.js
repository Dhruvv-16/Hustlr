/*
  ACTUARIAL PRICING MODEL — Subsidised Entry, Sustainable at Scale
  Guidewire formula: Trigger Probability × Avg Income Lost × Weekly Exposed Days ÷ Target BCR

  Basic Shield:    0.18 × ₹420 × 0.33d/wk ÷ 0.62 = ₹40 pure → 20% load → ₹35/wk  (27% subsidy)
  Standard Shield: 0.27 × ₹420 × 0.50d/wk ÷ 0.63 = ₹90 pure → 18% load → ₹49/wk  (54% subsidy)
  Full Shield:     0.35 × ₹420 × 0.65d/wk ÷ 0.65 = ₹147 pure → 17% load → ₹79/wk (54% subsidy)

  Cap discipline: All plans maintain 6–7× cap-to-premium ratio.
    Basic:    ₹210 ÷ ₹35 = 6.0×
    Standard: ₹340 ÷ ₹49 = 6.9×
    Full:     ₹500 ÷ ₹79 = 6.3×

  Previous ₹900 Full Shield cap produced 11.4× — unsustainably high, removed.
  Compound multipliers accelerate payout velocity, never the cap ceiling.
*/
const PLAN_CONFIG = {
  basic:    {
    base: 35,
    max_payout: 210,         // weekly cap ₹210/week (6.0× premium)
    daily_cap: 100,          // max payout per day ₹100/day
    name: 'Basic Shield',
    target_bcr: 0.62,
    multiplier: 6.0,
    covered_triggers: ['rain_heavy', 'heat_severe'],
  },
  standard: {
    base: 49,
    max_payout: 340,         // weekly cap ₹340/week (6.9× premium)
    daily_cap: 150,          // max payout per day ₹150/day
    name: 'Standard Shield',
    target_bcr: 0.63,
    multiplier: 6.9,
    covered_triggers: ['rain_heavy', 'rain_extreme', 'heat_severe', 'aqi_hazardous', 'platform_outage', 'bandh', 'internet_blackout'],
  },
  full:     {
    base: 79,
    max_payout: 500,         // weekly cap ₹500/week (6.3× premium) — HARD CEILING, zero exceptions
    daily_cap: 250,          // max payout per day ₹250/day
    name: 'Full Shield',
    target_bcr: 0.65,
    multiplier: 6.3,
    covered_triggers: 'all', // all 9 triggers + compound acceleration
    compound_bonus: true,    // compound = cap acceleration, NOT cap lifting
  },
};

// ── Add-on tier-lock requirements ────────────────────────────────────────────
// An add-on can only be purchased if the worker's BASE plan meets the minimum.
// This is enforced at policy creation AND at add-on purchase endpoints.
// Add-ons are QUARTERLY commitments — not weekly toggles.
const ADD_ON_TIER_REQUIREMENTS = {
  cyclone_cover:      'full',      // Cyclone: ₹80/hr, ₹250/day — Full Shield only (canonical)
  internet_blackout:  'standard',  // Blackout: ₹45/hr — Standard+ only
  curfew_strike:      'standard',  // Bandh/curfew: ₹55/hr — Standard+ only
  accident_blockspot: 'standard',  // Accident blockspot — Standard+ only
  traffic_congestion: 'full',      // Heavy traffic — Full Shield only (trigger itself is Full Shield)
  election_day:       'basic',     // Election day: available to all plans
  app_downtime:       'basic',     // App downtime: Basic only (already included in Standard+)
};

// Plan tier order for comparison (used in add-on eligibility checks)
const PLAN_TIER_RANK = { basic: 1, standard: 2, full: 3 };


// TIER FACTORS for ISS multiplier (plan tier multiplier)
// Basic = 1.0×, Standard = 1.25×, Full = 1.5× (+ 1.2-1.3× on compound)

module.exports = {
  PLAN_CONFIG,

  // Tier factors for ISS-based premium multiplier
  TIER_FACTORS: { basic: 1.0, standard: 1.0, full: 1.0 },

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

  // ── Per-trigger daily payout caps (trigger-level maximums) ─────────────────────
  // NOTE: Plan-level daily caps in PLAN_CONFIG always take precedence.
  // If trigger cap > plan daily cap → plan daily cap applies.
  // Cyclone ₹250/day is only achievable at Full Shield (₹250 plan daily_cap).
  DAILY_CAPS: {
    rain_heavy:        120,
    rain_extreme:      200,
    heat_severe:       130,
    aqi_hazardous:     100,
    platform_outage:   140,
    bandh:             150,
    traffic_severe:    80,
    internet_blackout: 110,   // 2-hour cap built in
    cyclone_landfall:  250,   // Full Shield only. Basic gets ₹100/day (plan cap wins).
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
  // RULE: Compound multipliers increase payout VELOCITY, not the cap ceiling.
  // The Full Shield ₹500/week cap is an ABSOLUTE hard ceiling. Zero exceptions.
  // 130% on Extreme Rain means worker hits ₹500 FASTER — in ~6hrs not ~8hrs.
  COMPOUND_BONUSES: {
    'rain_heavy+platform_outage': { multiplier: 1.0, type: 'additive',       note: '100% of both rates simultaneously' },
    'cyclone_landfall+bandh':     { multiplier: 1.2, type: 'multiplicative', note: '120% on cyclone rate — cap still ₹500' },
    'heat_severe+aqi_hazardous':  { multiplier: 1.1, type: 'multiplicative', note: '110% on higher rate — cap still ₹500' },
    'rain_extreme+internet_blackout': { multiplier: 1.3, type: 'multiplicative', note: 'Catastrophic — 130% accelerates to ₹500 cap faster. NO cap lift.' },
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
  // All add-ons are QUARTERLY commitments (13 weeks), not weekly toggles.
  // Cannot be activated within 72hrs of IMD alert or 48hrs of known civil event.
  ADDONS: {
    cyclone_cover:      { weekly: 20, min_plan: 'full',     note: 'Full Shield only. Oct–Dec season. ₹250/day cap. 0.4×/yr.' },
    curfew_strike:      { weekly: 12, min_plan: 'standard', note: 'Standard+ only. NewsAPI NLP. ~3 events/yr Chennai.' },
    internet_blackout:  { weekly: 18, min_plan: 'standard', note: 'Standard+ only. ₹45/hr. 2×/yr. Ookla+TRAI.' },
    accident_blockspot: { weekly: 15, min_plan: 'standard', note: 'Standard+ only. Tier 1/2/3 hotspot corridors.' },
    traffic_congestion: { weekly: 15, min_plan: 'full', note: 'Full Shield only. ₹30/hr. Speed 40% below baseline ≥45min.' },
    election_day:       { weekly: 8,  min_plan: 'basic',    note: 'All plans. Fixed calendar. Low adverse selection risk.' },
    app_downtime:       { weekly: 10, min_plan: 'basic',    note: 'Basic only. Platform outage >60%. Already in Standard+.' },
  },

  // ── Worker activity tier underwriting ─────────────────────────────────────
  // README canonical (min changed from 10 to 7 days per Guidewire mandate)
  ACTIVITY_LOADING: {
    above_20_days:    1.00,  // standard rate — full behavioral baseline
    between_7_20:     1.08,  // +8% loading — reduced behavioral baseline
    below_7_days:     null,  // DECLINED — per Guidewire minimum activity mandate
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
