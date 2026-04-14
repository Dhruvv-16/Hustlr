import math
from datetime import datetime

from app.core.constants import PAYOUT_TIERS
from app.ml.ml_service import predict_premium

ZONE_FEATURES = {
    "kondapur-hyderabad": {"flood_events_5yr": 7, "elevation_m": 505, "avg_rainfall_mm": 810},
    "kurla-mumbai": {"flood_events_5yr": 16, "elevation_m": 11, "avg_rainfall_mm": 2400},
    "koramangala-bengaluru": {"flood_events_5yr": 4, "elevation_m": 920, "avg_rainfall_mm": 900},
    "tnagar-chennai": {"flood_events_5yr": 10, "elevation_m": 6, "avg_rainfall_mm": 1400},
    "dwarka-delhi": {"flood_events_5yr": 2, "elevation_m": 216, "avg_rainfall_mm": 700},
}

ZONE_ML_DATA = {
    "kondapur-hyderabad": {
        "city": "Hyderabad",
        "lat": 17.4401,
        "lng": 78.3489,
        "platform_outage_freq": 0.40,
        "curfew_risk": 0.25,
    },
    "kurla-mumbai": {
        "city": "Mumbai",
        "lat": 19.0728,
        "lng": 72.8826,
        "platform_outage_freq": 0.45,
        "curfew_risk": 0.30,
    },
    "koramangala-bengaluru": {
        "city": "Bengaluru",
        "lat": 12.9352,
        "lng": 77.6245,
        "platform_outage_freq": 0.55,
        "curfew_risk": 0.20,
    },
    "tnagar-chennai": {
        "city": "Chennai",
        "lat": 13.0418,
        "lng": 80.2341,
        "platform_outage_freq": 0.35,
        "curfew_risk": 0.25,
    },
    "dwarka-delhi": {
        "city": "Delhi",
        "lat": 28.5921,
        "lng": 77.0460,
        "platform_outage_freq": 0.30,
        "curfew_risk": 0.65,
    },
}

for zone_key, zone_meta in ZONE_ML_DATA.items():
    zone_meta.update(ZONE_FEATURES[zone_key])

ZONE_RISK = {
    zone_key: {
        "city": zone_meta["city"],
        "lat": zone_meta["lat"],
        "lng": zone_meta["lng"],
        "flood": round(min(zone_meta["flood_events_5yr"] / 12, 1.0), 2),
        "outage": zone_meta["platform_outage_freq"],
        "curfew": zone_meta["curfew_risk"],
        "elevation_m": zone_meta["elevation_m"],
        "avg_rainfall_mm": zone_meta["avg_rainfall_mm"],
    }
    for zone_key, zone_meta in ZONE_ML_DATA.items()
}


def calculate_ml_premium(
    zone: str,
    worker_risk_score: float = 0.75,
    current_weather_risk: float = None,
) -> dict:
    breakdown = predict_premium(zone=zone, risk_score=worker_risk_score)
    zone_meta = ZONE_ML_DATA.get(zone, ZONE_ML_DATA["kondapur-hyderabad"])
    factors = breakdown.get("factors", {})

    zone_risk = round(
        factors.get("flood_history", 0) * 0.30
        + factors.get("waterlogging", 0) * 0.20
        + factors.get("elevation_risk", 0) * 0.15
        + factors.get("drainage_quality", 0) * 0.10
        + factors.get("monsoon_season", 0) * 0.15
        + zone_meta.get("platform_outage_freq", 0) * 0.05
        + zone_meta.get("curfew_risk", 0) * 0.05,
        3,
    )

    weather_adjustment = 0
    weather_label = None
    if current_weather_risk is not None:
        if current_weather_risk > 0.7:
            weather_adjustment = 4
            weather_label = "Active weather risk"
        elif current_weather_risk > 0.4:
            weather_adjustment = 2
            weather_label = "Elevated weather risk"

    return {
        **breakdown,
        "weather_adjustment": weather_adjustment,
        "zone_label": f"{zone_meta['city']} Risk Zone",
        "worker_label": (
            "Trusted Worker Discount"
            if worker_risk_score >= 0.80
            else "Good Track Record"
            if worker_risk_score >= 0.65
            else "Standard Rate"
            if worker_risk_score >= 0.50
            else "New Worker Rate"
        ),
        "weather_label": weather_label,
        "zone_risk_score": zone_risk,
        "worker_risk_score": round(worker_risk_score, 2),
        "city": zone_meta["city"],
        "vs_hyderabad": int(breakdown["final_premium"]) - 58,
        "savings_vs_max": 89 - int(breakdown["final_premium"]),
        "factors": {
            **factors,
            "platform_outage": round(zone_meta.get("platform_outage_freq", 0), 2),
            "curfew_risk": round(zone_meta.get("curfew_risk", 0), 2),
        },
    }


def get_zone_multiplier(zone: str) -> float:
    return calculate_ml_premium(zone)["zone_risk_score"] * 0.70 + 0.80


def get_worker_multiplier(risk_score: float) -> float:
    if risk_score >= 0.80:
        return 0.88
    if risk_score >= 0.65:
        return 0.94
    if risk_score >= 0.50:
        return 1.0
    return 1.10


def calculate_premium(zone: str, risk_score: float = 0.75, **_: dict) -> float:
    return float(calculate_ml_premium(zone, risk_score)["final_premium"])


def get_premium_breakdown(zone: str, risk_score: float = 0.75) -> dict:
    return calculate_ml_premium(zone, risk_score)


def calculate_payout_amount(worker_daily_orders: float, base_payout: int = 600) -> dict:
    """Return payout amount and tier based on worker's average daily orders."""
    if worker_daily_orders >= 15:
        return {"payout_amount": 900, "payout_tier": "Gold", "daily_orders": worker_daily_orders}
    if worker_daily_orders >= 8:
        return {"payout_amount": 600, "payout_tier": "Silver", "daily_orders": worker_daily_orders}
    return {"payout_amount": 400, "payout_tier": "Bronze", "daily_orders": worker_daily_orders}


def get_income_tier(daily_orders: float) -> str:
    if daily_orders >= 15:
        return "Gold"
    if daily_orders >= 8:
        return "Silver"
    return "Bronze"


def actuarial_premium_calculation(
    base_premium: float,
    zone_claim_frequency: float,
    zone_claim_severity: float,
    seasonal_index: float = 1.0,
) -> float:
    expected_loss = zone_claim_frequency * zone_claim_severity
    volatility_loading = 0.25 * math.sqrt(zone_claim_frequency) * zone_claim_severity
    risk_premium = expected_loss + volatility_loading
    expense_loading = risk_premium * 0.30
    final = (risk_premium + expense_loading) * seasonal_index
    return round(max(35.0, min(150.0, final)), 2)


def get_seasonal_index(month: int = None) -> float:
    """Return 1.4 during Indian monsoon months (Jun-Sep), else 1.0."""
    if month is None:
        month = datetime.utcnow().month
    return 1.4 if month in (6, 7, 8, 9) else 1.0


def get_payout_for_orders(avg_orders: float) -> int:
    if avg_orders >= 15:
        return PAYOUT_TIERS["gold"]["payout_inr"]
    if avg_orders >= 8:
        return PAYOUT_TIERS["silver"]["payout_inr"]
    return PAYOUT_TIERS["bronze"]["payout_inr"]


def calculate_hybrid_premium(
    city: str,
    worker_risk_score: float,
    account_age_days: int,
    avg_orders_per_day: float,
    month: int = None,
    plan_type: str = "standard",
) -> dict:
    """
    Blend ML premium (60%) with actuarial premium (40%).
    This is the primary premium model used by GuidePay.
    """
    ml_result = calculate_ml_premium(city, worker_risk_score)
    ml_premium = ml_result["final_premium"]

    zone_meta = ZONE_ML_DATA.get(city, ZONE_ML_DATA["kondapur-hyderabad"])
    flood_events = zone_meta.get("flood_events_5yr", 5)
    zone_claim_frequency = min(flood_events / 20.0, 0.80)
    seasonal_index = get_seasonal_index(month)
    worker_payout_amount = get_payout_for_orders(avg_orders_per_day)
    payout_tier = "gold" if avg_orders_per_day >= 15 else "silver" if avg_orders_per_day >= 8 else "bronze"

    actuarial_premium = actuarial_premium_calculation(
        ml_premium,
        zone_claim_frequency=zone_claim_frequency,
        zone_claim_severity=worker_payout_amount,
        seasonal_index=seasonal_index,
    )
    final_premium = round(0.6 * ml_premium + 0.4 * actuarial_premium, 2)
    final_premium = max(35.0, min(150.0, final_premium))

    return {
        "weekly_premium": final_premium,
        "final_premium": final_premium,
        "ml_premium": ml_premium,
        "actuarial_premium": actuarial_premium,
        "payout_tier": payout_tier,
        "payout_amount": worker_payout_amount,
        "zone": city,
        "blend": "60% ML + 40% Actuarial",
        "premium_blend": "60% ML + 40% Actuarial",
        "volatility_loading_applied": True,
        "zone_claim_frequency": round(zone_claim_frequency, 3),
        "zone_claim_severity": worker_payout_amount,
        "seasonal_index": seasonal_index,
        "account_age_days": account_age_days,
        "plan_type": plan_type,
        **ml_result,
    }
