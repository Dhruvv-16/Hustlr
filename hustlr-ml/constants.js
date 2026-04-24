// SHIELDGIG REFINED MODEL - Income Stabilization Layer
// Clean, sustainable, explainable parametric insurance

const PLAN_CONFIG = {
    'Basic': {
        weekly_premium: 60,      // 1.5% of weekly income
        weekly_cap: 400,        // 6.7× weekly premium
        daily_cap: 150,         // 19% of daily income
        target_loss_ratio: 0.50,
        covered_triggers: ['heavy_rain', 'extreme_heat'],
        coverage_percentage: 60
    },
    'Standard': {
        weekly_premium: 90,      // 2.2% of weekly income
        weekly_cap: 800,         // 8.9× weekly premium
        daily_cap: 160,         // 20% of daily income (WhatsApp insight)
        target_loss_ratio: 0.60,
        covered_triggers: ['heavy_rain', 'extreme_heat', 'severe_aqi', 'platform_outage'],
        coverage_percentage: 80
    },
    'Full': {
        weekly_premium: 120,     // 3.0% of weekly income
        weekly_cap: 1500,        // 12.5× weekly premium
        daily_cap: 200,         // 25% of daily income (WhatsApp insight)
        target_loss_ratio: 0.65,
        covered_triggers: ['all_triggers'],
        coverage_percentage: 100
    }
};

// UNIFIED PAYOUT FORMULA: event_payout = weekly_cap × severity_factor × duration_factor × zone_multiplier
const TRIGGER_THRESHOLDS = {
    heavy_rain: 64.5,      // mm/24hr (IMD official)
    very_heavy_rain: 115.5, // mm/24hr (IMD official) - used for severity calculation
    extreme_rain: 204.5,    // mm/24hr (IMD official)
    extreme_heat: 43,       // Celsius (heat wave threshold)
    severe_aqi: 200,        // AQI value (hazardous level)
    platform_outage: 2     // hours minimum duration
};

// SEVERITY REFERENCES (for severity_factor calculation)
const SEVERITY_REFERENCES = {
    heavy_rain: 64.5,      // IMD threshold
    very_heavy_rain: 115.5, // Reference for severity calculation (WhatsApp insight)
    extreme_rain: 204.5     // IMD threshold
};

// EXPECTED DURATIONS (for duration_factor calculation)
const EXPECTED_DURATIONS = {
    heavy_rain: 3,      // hours
    very_heavy_rain: 5, // hours
    extreme_rain: 8,    // hours
    extreme_heat: 4,    // hours
    severe_aqi: 6,      // hours
    platform_outage: 2  // hours
};

// ZONE DEPTH MULTIPLIERS (strongest feature - flood depth mapping)
const ZONE_MULTIPLIERS = {
    '0-0.2': 0,      // No flooding
    '0.2-0.4': 0.3,  // Light flooding
    '0.4-0.6': 0.6,  // Moderate flooding
    '0.6-0.8': 0.85, // Heavy flooding
    '0.8-1.0': 1.0   // Severe flooding
};

// FRAUD DETECTION SCORING (0-100)
const FRAUD_SCORING = {
    location_consistency: 40,  // GPS continuity and zone consistency
    activity_score: 30,        // Work hours and delivery patterns
    behavior_pattern: 30       // Historical claim patterns and velocity
};

// FRAUD PAYOUT ADJUSTMENT
const FRAUD_ADJUSTMENT = {
    '0-30': { multiplier: 1.0, action: 'full_payout' },
    '30-60': { multiplier: 0.7, action: '70_percent' },
    '60-80': { multiplier: 0.4, action: '40_percent' },
    '80-100': { multiplier: 0.0, action: 'hold_payout' }
};

// SYSTEM CAPS (catastrophe protection)
const SYSTEM_CAPS = {
    reinsurance_trigger: 4.0,  // 4× weekly pool
    scaling_method: 'proportional',  // Scale all payouts proportionally
    max_pool_exposure: 0.25   // 25% of total pool per event
};

// INCOME CONSTRAINTS (affordability validation)
const INCOME_CONSTRAINTS = {
    daily_income: 800,        // Average gig worker daily income
    weekly_income: 4000,       // Average weekly income
    max_premium_ratio: 0.03,   // Max 3% of weekly income
    daily_cap_percentage: 0.25 // 25% of daily income for daily caps
};

// PAYOUT RELEASE SCHEDULE (fraud prevention)
const PAYOUT_RELEASE = {
    immediate_percentage: 0.7,  // 70% within minutes
    review_percentage: 0.3,     // 30% Sunday after review
    min_active_days: 7,        // 7 days platform activity required
    weekly_fraud_review: true   // Weekly pattern analysis
};

// EVENT RULES (non-negotiable)
const EVENT_RULES = {
    one_trigger_per_24h: true,     // Only highest severity trigger per 24h
    same_trigger_cooldown: 24,     // 24h cooldown for same trigger
    work_hours_overlap: true,      // Event must overlap active work hours
    max_events_per_week: 5         // Maximum 5 events per week
};

// REAL CHENNAI DATA REFERENCES
const CHENNAI_DATA = {
    rainfall_years: 122,           // 1901-2023 authentic data
    heavy_rain_days_annual: 1278,   // 6.0% of days
    very_heavy_rain_days: 379,      // 1.8% of days
    disruption_probability: 0.078,     // 7.8% annual chance
    economic_validation: true,        // Real wage data integration
    user_research_validated: true      // WhatsApp group insights
};

module.exports = {
    PLAN_CONFIG,
    TRIGGER_THRESHOLDS,
    SEVERITY_REFERENCES,
    EXPECTED_DURATIONS,
    ZONE_MULTIPLIERS,
    FRAUD_SCORING,
    FRAUD_ADJUSTMENT,
    SYSTEM_CAPS,
    INCOME_CONSTRAINTS,
    PAYOUT_RELEASE,
    EVENT_RULES,
    CHENNAI_DATA
};
