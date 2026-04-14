# Payout percentages by trigger type
PAYOUT_PERCENTAGES = {
    "FLOOD": 1.0,
    "OUTAGE": 0.75,
    "CURFEW": 1.0,
}

# Coverage cap (weekly max payout per worker)
COVERAGE_CAP = 600.0

# Fraud score threshold for auto-approval
FRAUD_AUTO_APPROVE_THRESHOLD = 0.70

# Zone radius for GPS check (km)
GPS_ZONE_RADIUS_KM = 5.0
GPS_WARN_RADIUS_KM = 10.0

# Claim frequency thresholds
CLAIM_FREQ_MULTIPLIER = 2.5  # x zone average before flagging

# Activity check thresholds (minutes)
ACTIVITY_WARN_MINUTES = 240   # 4 hours
ACTIVITY_FAIL_MINUTES = 360   # 6 hours

# Account age threshold for new account flag (days)
NEW_ACCOUNT_DAYS = 7

# Trigger event expiry
TRIGGER_EXPIRY_HOURS = 24

# Supported cities
SUPPORTED_CITIES = [
    "Hyderabad",
    "Mumbai",
    "Chennai",
    "Bengaluru",
    "Delhi",
]

# Plan pricing
PLAN_PRICING = {
    "basic": 49.0,
    "standard": 58.0,
    "premium": 69.0,
}

# High-impact delivery disruption calendar
# Disruption level: 0.0 = no impact, 1.0 = complete stop
DISRUPTION_CALENDAR = {
    "01-26": {
        "name": "Republic Day",
        "disruption_level": 0.55,
        "description": "Road closures near parade routes. Platform orders drop 40-60% in affected areas.",
        "cities": ["Delhi", "Mumbai", "Chennai"],
    },
    "03-20": {
        "name": "Holi",
        "disruption_level": 0.70,
        "description": "Major disruption nationwide. Platform apps slow. Workers face safety concerns.",
        "cities": None,  # All cities
    },
    "03-31": {
        "name": "Eid ul-Fitr",
        "disruption_level": 0.45,
        "description": "High demand in some areas, road congestion and closures in others.",
        "cities": None,
    },
    "08-15": {
        "name": "Independence Day",
        "disruption_level": 0.50,
        "description": "Security restrictions near government buildings. Major road closures.",
        "cities": ["Delhi", "Mumbai", "Chennai", "Hyderabad"],
    },
    "10-29": {
        "name": "Diwali",
        "disruption_level": 0.65,
        "description": "Air quality restrictions. Platform delivery volumes drop 50%. Worker safety concerns.",
        "cities": None,
    },
    "09-13": {
        "name": "Ganesh Chaturthi",
        "disruption_level": 0.60,
        "description": "Processions block major roads for up to 10 days. Platform SLAs severely impacted.",
        "cities": ["Mumbai", "Hyderabad", "Chennai"],
    },
}

# Payout percentages for all 5 trigger types
TRIGGER_PAYOUTS = {
    "FLOOD": 1.00,               # 100% — total work stoppage
    "OUTAGE": 0.75,              # 75% — partial work possible
    "CURFEW": 1.00,              # 100% — cannot work legally
    "AIR_QUALITY": 0.50,         # 50% — health risk, reduced orders
    "HEAT_WAVE": 0.50,           # 50% — platform slowdown
    "FESTIVAL_DISRUPTION": 0.40, # 40% — partial disruption
}
