"""
GuidePay — Single source of truth for all pricing and payout constants.
All other files must import from here. Never hardcode these values elsewhere.
"""

# ── PLANS ──────────────────────────────────────────────
PLANS = {
    "daily": {
        "name": "Daily Shield",
        "price_inr": 12,
        "coverage_hours": 24,
        "display_price": "₹12/day",
        "badge": "MOST AFFORDABLE",
    },
    "basic": {
        "name": "Basic Shield",
        "price_inr": 49,
        "coverage_hours": 168,  # 7 days
        "display_price": "₹49/week",
        "badge": None,
    },
    "standard": {
        "name": "Standard Shield",
        "price_inr": 62,
        "coverage_hours": 168,
        "display_price": "₹62/week",
        "badge": "MOST POPULAR",
    },
    "premium": {
        "name": "Premium Shield",
        "price_inr": 89,
        "coverage_hours": 168,
        "display_price": "₹89/week",
        "badge": "FULL PROTECTION",
    },
}

# ── PAYOUT TIERS ───────────────────────────────────────
PAYOUT_TIERS = {
    "bronze": {
        "label": "Bronze",
        "min_orders_per_day": 0,
        "max_orders_per_day": 7,
        "payout_inr": 400,
        "color": "#CD7F32",
    },
    "silver": {
        "label": "Silver",
        "min_orders_per_day": 8,
        "max_orders_per_day": 14,
        "payout_inr": 600,
        "color": "#A8A9AD",
    },
    "gold": {
        "label": "Gold",
        "min_orders_per_day": 15,
        "max_orders_per_day": 999,
        "payout_inr": 900,
        "color": "#FFD700",
    },
}

# ── ACTUARIAL CONSTANTS ────────────────────────────────
EXPENSE_LOADING_RATIO = 0.30       # 30% of risk premium for ops + profit
VOLATILITY_LOADING_FACTOR = 0.25   # 25% of sqrt(frequency) * severity
MONSOON_MONTHS = [6, 7, 8, 9]      # June–September
MONSOON_MULTIPLIER = 1.4
OFF_SEASON_MULTIPLIER = 1.0
MIN_WEEKLY_PREMIUM = 35
MAX_WEEKLY_PREMIUM = 150
ML_WEIGHT = 0.6                    # 60% ML in hybrid model
ACTUARIAL_WEIGHT = 0.4             # 40% actuarial in hybrid model

# ── FRAUD THRESHOLDS ───────────────────────────────────
AUTO_APPROVE_THRESHOLD = 0.70
NEW_ACCOUNT_GATE_DAYS = 7
ACTIVITY_RECENCY_HOURS = 6
CLUSTER_SPOOF_MIN_WORKERS = 5
IMPOSSIBLE_SPEED_KMH = 120

# ── TRIGGER THRESHOLDS ─────────────────────────────────
FLOOD_RAINFALL_MM_24H = 64.4
AQI_HAZARDOUS_THRESHOLD = 301
PLATFORM_OUTAGE_MINUTES = 30
EARNINGS_DROP_THRESHOLD = 0.70     # 70% drop triggers festival disruption
