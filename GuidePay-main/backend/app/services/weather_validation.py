"""
Validate weather claims against historical data.
Prevents fake weather claims.

Data sources:
- OpenWeatherMap historical API
- IMD SACHET archive
- Internal trigger event database
"""
import httpx
import logging
import os
from datetime import datetime, timedelta
from typing import Optional

logger = logging.getLogger(__name__)

async def validate_weather_claim(
    zone_lat: float,
    zone_lng: float,
    claim_date: datetime,
    trigger_type: str,
    db,
    zone: str,
) -> dict:
    """
    Validate that a weather event actually occurred
    at the claimed location and time.

    Returns validation result with confidence score.
    """
    validations = {}
    confirmed_sources = 0
    total_sources = 0

    # Source 1: Check our own trigger event database
    # If IMD triggered an event for this zone/date,
    # the claim is legitimate
    event_window_start = claim_date - timedelta(
        hours=6
    )
    event_window_end = claim_date + timedelta(
        hours=6
    )

    db_event = await db.trigger_events.find_one({
        "zone": zone,
        "trigger_type": trigger_type,
        "started_at": {
            "$gte": event_window_start,
            "$lte": event_window_end,
        },
        "source": {
            "$in": [
                "IMD_SACHET",
                "OPENWEATHER",
                "ADMIN_SIMULATION"
            ]
        }
    })

    total_sources += 1
    if db_event:
        confirmed_sources += 1
        validations["internal_database"] = {
            "confirmed": True,
            "source": db_event.get("source"),
            "event_id": str(db_event.get("_id")),
            "severity": db_event.get("severity"),
        }
    else:
        validations["internal_database"] = {
            "confirmed": False,
            "note": "No matching trigger event found",
        }

    # Source 2: OpenWeatherMap historical data
    api_key = os.getenv("OPENWEATHER_API_KEY")
    if api_key:
        total_sources += 1
        owm_result = await check_owm_historical(
            zone_lat, zone_lng,
            claim_date, trigger_type, api_key
        )
        validations["openweathermap"] = owm_result
        if owm_result.get("confirmed"):
            confirmed_sources += 1

    # Source 3: Zone correlation
    # Were other workers in same zone also affected?
    total_sources += 1
    correlation = await check_zone_correlation(
        zone, trigger_type, claim_date, db
    )
    validations["zone_correlation"] = correlation
    if correlation.get("confirmed"):
        confirmed_sources += 1

    # Calculate confidence
    if total_sources == 0:
        confidence = 0.5
    else:
        confidence = confirmed_sources / total_sources

    # Decision
    if confidence >= 0.66:
        decision = "WEATHER_CONFIRMED"
        fraud_contribution = -0.20
    elif confidence >= 0.33:
        decision = "WEATHER_PARTIAL"
        fraud_contribution = 0.0
    else:
        decision = "WEATHER_UNCONFIRMED"
        fraud_contribution = 0.35

    return {
        "decision": decision,
        "confidence": round(confidence, 2),
        "confirmed_sources": confirmed_sources,
        "total_sources": total_sources,
        "validations": validations,
        "fraud_score_contribution":
            fraud_contribution,
    }

async def check_owm_historical(
    lat: float,
    lng: float,
    event_date: datetime,
    trigger_type: str,
    api_key: str,
) -> dict:
    """
    Check OpenWeatherMap for historical conditions.
    Free API supports up to 5 days history.
    """
    try:
        # Only check recent events (within 5 days)
        days_ago = (
            datetime.utcnow() - event_date
        ).days
        if days_ago > 5:
            return {
                "confirmed": None,
                "note": "Event too old for OWM history",
            }

        timestamp = int(event_date.timestamp())

        async with httpx.AsyncClient(
            timeout=8.0
        ) as client:
            res = await client.get(
                "https://api.openweathermap.org/data/2.5/onecall/timemachine",
                params={
                    "lat": lat,
                    "lon": lng,
                    "dt": timestamp,
                    "appid": api_key,
                    "units": "metric",
                }
            )

            if res.status_code != 200:
                return {
                    "confirmed": False,
                    "note": f"OWM API error {res.status_code}",
                }

            data = res.json()
            hourly = data.get("hourly", [])

            # Check conditions match trigger type
            for hour in hourly[:6]:
                weather = hour.get(
                    "weather", [{}]
                )[0]
                rain = hour.get("rain", {}).get(
                    "1h", 0
                )
                temp = hour.get("temp", 25)

                if trigger_type == "FLOOD":
                    if rain > 15:
                        return {
                            "confirmed": True,
                            "rainfall_mm": rain,
                            "weather_id": weather.get("id"),
                            "description": weather.get(
                                "description"
                            ),
                        }
                elif trigger_type == "HEAT_WAVE":
                    if temp > 40:
                        return {
                            "confirmed": True,
                            "temperature_c": temp,
                        }

            return {
                "confirmed": False,
                "note": "Weather conditions "
                        "not matching trigger type",
            }

    except Exception as e:
        logger.warning(
            f"OWM historical check failed: {e}"
        )
        return {
            "confirmed": None,
            "note": f"OWM check error: {str(e)}",
        }

async def check_zone_correlation(
    zone: str,
    trigger_type: str,
    claim_date: datetime,
    db,
) -> dict:
    """
    If multiple workers in same zone claimed
    the same trigger type on the same date,
    it confirms the event was real.
    """
    window_start = claim_date - timedelta(hours=4)
    window_end = claim_date + timedelta(hours=4)

    same_zone_claims = await db.claims.count_documents({
        "zone": zone,
        "trigger_type": trigger_type,
        "created_at": {
            "$gte": window_start,
            "$lte": window_end,
        },
        "status": {
            "$in": [
                "PAID", "AUTO_APPROVED",
                "MANUAL_REVIEW"
            ]
        }
    })

    confirmed = same_zone_claims >= 3

    return {
        "confirmed": confirmed,
        "same_zone_claims": same_zone_claims,
        "threshold": 3,
        "note": f"{same_zone_claims} workers "
                f"in zone claimed same event",
    }
