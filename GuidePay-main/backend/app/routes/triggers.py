from fastapi import APIRouter, Depends, Query, HTTPException
from app.database import get_db
from app.routes.auth import get_current_worker
from app.utils.formatters import serialize_doc
from datetime import datetime, timedelta
import logging
from app.core.constants import PAYOUT_TIERS

router = APIRouter()
logger = logging.getLogger(__name__)

@router.get("/active")
async def get_active_triggers(
    current_worker=Depends(get_current_worker),
    db=Depends(get_db)
):
    """Returns all currently active trigger events with monitoring metadata."""
    triggers = await db.trigger_events.find({
        "status": "ACTIVE",
    }).sort("started_at", -1).to_list(10)

    return {
        "triggers": [serialize_doc(t) for t in triggers],
        "count": len(triggers),
        "last_checked": datetime.utcnow().isoformat(),
        "next_check_minutes": 15,
        "monitoring_sources": [
            "IMD SACHET RSS",
            "OpenWeatherMap",
            "Downdetector",
            "Govt Feeds",
            "Calendar Engine",
        ],
    }

@router.get("/my-zone")
async def get_my_zone_triggers(
    current_worker=Depends(get_current_worker),
    db=Depends(get_db)
):
    """Get trigger events for worker's zone"""
    zone = current_worker.get("zone", "")

    triggers = await db.trigger_events.find({
        "zone": zone,
        "status": "ACTIVE"
    }).sort("started_at", -1).to_list(10)

    return {
        "zone": zone,
        "triggers": [serialize_doc(t) for t in triggers],
        "total": len(triggers)
    }

@router.get("/types")
async def get_trigger_types():
    """Returns all 5 trigger types with payout rules."""
    return {
        "triggers": [
            {
                "id": "FLOOD",
                "name": "IMD Flood Alert",
                "icon": "🌧️",
                "payout_percentage": 1.0,
                "payout_cap": PAYOUT_TIERS["silver"]["payout_inr"],
                "description": "Red/Orange flood alert from IMD SACHET",
                "api_source": "IMD SACHET RSS",
                "api_url": "https://sachet.ndma.gov.in/cap_public_website/FeedPage",
                "free": True,
                "active": True,
            },
            {
                "id": "OUTAGE",
                "name": "Platform Outage",
                "icon": "⚡",
                "payout_percentage": 0.75,
                "payout_cap": PAYOUT_TIERS["silver"]["payout_inr"] * 0.75,
                "description": "Zepto/Swiggy/Blinkit down 2+ hours",
                "api_source": "Downdetector + Status Pages",
                "free": True,
                "active": True,
            },
            {
                "id": "CURFEW",
                "name": "Government Curfew",
                "icon": "🚨",
                "payout_percentage": 1.0,
                "payout_cap": PAYOUT_TIERS["silver"]["payout_inr"],
                "description": "Section 144 or curfew order issued",
                "api_source": "State Govt RSS + News APIs",
                "free": True,
                "active": True,
            },
            {
                "id": "AIR_QUALITY",
                "name": "Air Quality Alert",
                "icon": "😷",
                "payout_percentage": 0.50,
                "payout_cap": PAYOUT_TIERS["silver"]["payout_inr"] * 0.5,
                "description": "AQI Very Poor (4/5) or Heat Wave 43°C+",
                "api_source": "OpenWeatherMap AQI",
                "free": True,
                "active": True,
            },
            {
                "id": "FESTIVAL_DISRUPTION",
                "name": "Festival Disruption",
                "icon": "🎊",
                "payout_percentage": 0.40,
                "payout_cap": PAYOUT_TIERS["silver"]["payout_inr"] * 0.4,
                "description": "Major festival causing 40%+ delivery drop",
                "api_source": "Internal Calendar Engine",
                "free": True,
                "active": True,
            },
        ],
        "total": 5,
        "coverage_cap": PAYOUT_TIERS["silver"]["payout_inr"],
        "note": "All triggers verified via multiple independent sources before payout",
    }

@router.get("/{trigger_id}")
async def get_trigger_detail(
    trigger_id: str,
    current_worker=Depends(get_current_worker),
    db=Depends(get_db)
):
    """Get trigger event detail"""
    trigger = await db.trigger_events.find_one({"_id": trigger_id})
    if not trigger:
        raise HTTPException(status_code=404, detail="Trigger not found")

    return serialize_doc(trigger)
