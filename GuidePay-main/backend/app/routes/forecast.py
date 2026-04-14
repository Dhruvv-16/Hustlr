from fastapi import APIRouter, Depends, Query
from app.database import get_db
from app.routes.auth import get_current_worker
from app.services.premium_service import ZONE_RISK
from app.ml.ml_service import predict_flood_probability
from app.utils.formatters import serialize_doc
from datetime import datetime, timedelta
import logging

router = APIRouter()
logger = logging.getLogger(__name__)


@router.get("/zones")
async def get_zone_forecast(
    current_worker=Depends(get_current_worker),
    db=Depends(get_db)
):
    """Get AI flood forecast for all monitored zones"""
    forecasts = []

    for zone_key, zone_data in ZONE_RISK.items():
        prediction = predict_flood_probability(zone=zone_key)

        workers_count = await db.workers.count_documents({
            "zone": zone_key, "is_active": True
        })

        active_trigger = await db.trigger_events.find_one({
            "zone": zone_key,
            "status": "ACTIVE",
            "started_at": {
                "$gte": datetime.utcnow() - timedelta(hours=24)
            }
        })

        forecasts.append({
            "zone": zone_key,
            "city": zone_data["city"],
            "lat": zone_data["lat"],
            "lng": zone_data["lng"],
            "flood_probability_24h": prediction["probability"],
            "risk_level": prediction["risk_level"],
            "rainfall_forecast_mm": prediction["rainfall_mm"],
            "workers_in_zone": workers_count,
            "active_trigger": active_trigger is not None,
            "inputs": prediction["inputs"],
        })

    return {
        "forecasts": forecasts,
        "generated_at": datetime.utcnow().isoformat(),
        "next_update_minutes": 15,
    }


@router.get("/zone-intel/{zone}")
async def get_zone_intel(
    zone: str,
    current_worker=Depends(get_current_worker),
    db=Depends(get_db)
):
    """
    Zone Safety Intel — detailed intelligence for a specific delivery zone.
    Returns flood risk, elevation, historical events, active triggers, and safety score.
    """
    zone_data = ZONE_RISK.get(zone)
    if not zone_data:
        return {"error": "Zone not monitored", "zone": zone}

    # Get flood prediction
    prediction = predict_flood_probability(zone=zone)

    # Workers in zone
    workers_count = await db.workers.count_documents({
        "zone": zone, "is_active": True
    })

    # Active triggers in zone
    active_triggers = await db.trigger_events.find({
        "zone": zone,
        "status": "ACTIVE",
    }).to_list(10)

    # Recent claims in zone (last 30 days)
    thirty_days_ago = datetime.utcnow() - timedelta(days=30)
    recent_claims = await db.claims.count_documents({
        "created_at": {"$gte": thirty_days_ago},
        "status": "PAID",
    })

    # Historical trigger events in this zone
    historical_triggers = await db.trigger_events.count_documents({
        "zone": zone,
    })

    # Total payout exposure in this zone
    exposure_pipeline = [
        {"$match": {"zone": zone, "status": "ACTIVE"}},
        {"$group": {"_id": None, "total": {"$sum": "$total_exposure"}}}
    ]
    exposure_result = await db.trigger_events.aggregate(exposure_pipeline).to_list(1)
    total_exposure = exposure_result[0]["total"] if exposure_result else 0

    # Safety score (inverse of flood risk, weighted)
    flood_risk = zone_data.get("flood", 0.5)
    outage_risk = zone_data.get("outage", 0.3)
    curfew_risk = zone_data.get("curfew", 0.2)
    safety_score = round(
        max(0, min(100, (1 - (flood_risk * 0.5 + outage_risk * 0.3 + curfew_risk * 0.2)) * 100)),
        1
    )

    # Safety recommendations
    recommendations = []
    if flood_risk > 0.6:
        recommendations.append({
            "type": "warning",
            "title": "High Flood Risk Zone",
            "description": "This zone has significant flood history. Ensure you have an active policy before monsoon season."
        })
    if outage_risk > 0.4:
        recommendations.append({
            "type": "info",
            "title": "Platform Outage Prone",
            "description": "Delivery apps in this area have experienced outages. GuidePay covers income loss during outages."
        })
    if prediction["probability"] > 0.7:
        recommendations.append({
            "type": "urgent",
            "title": "Elevated Risk Today",
            "description": f"AI predicts {round(prediction['probability'] * 100)}% flood probability in the next 24 hours. Stay alert."
        })
    if len(recommendations) == 0:
        recommendations.append({
            "type": "success",
            "title": "Zone is Currently Safe",
            "description": "No elevated risks detected. Continue your deliveries with confidence."
        })

    return {
        "zone": zone,
        "city": zone_data["city"],
        "lat": zone_data["lat"],
        "lng": zone_data["lng"],
        "flood_risk": flood_risk,
        "outage_risk": outage_risk,
        "curfew_risk": curfew_risk,
        "safety_score": safety_score,
        "prediction": prediction,
        "workers_in_zone": workers_count,
        "active_triggers": [serialize_doc(t) for t in active_triggers],
        "recent_claims_30d": recent_claims,
        "historical_trigger_events": historical_triggers,
        "total_exposure": total_exposure,
        "recommendations": recommendations,
        "generated_at": datetime.utcnow().isoformat(),
    }


@router.get("/my-zone")
async def get_my_zone_forecast(
    current_worker=Depends(get_current_worker),
    db=Depends(get_db)
):
    """Get forecast specifically for worker's zone"""
    zone = current_worker.get("zone", "")
    city = current_worker.get("city", "")

    zone_data = ZONE_RISK.get(zone)
    if not zone_data:
        return {"forecast": None, "message": "Zone not monitored"}

    prediction = predict_flood_probability(zone=zone)

    active_triggers = await db.trigger_events.find({
        "zone": zone,
        "status": "ACTIVE",
    }).to_list(5)

    return {
        "zone": zone,
        "city": city,
        "prediction": prediction,
        "active_triggers": [serialize_doc(t) for t in active_triggers],
        "auto_cover_extended": prediction["probability"] > 0.7,
    }
