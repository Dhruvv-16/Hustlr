from datetime import datetime, timedelta
from typing import Dict, List, Optional


async def calculate_fraud_score(
    worker: dict,
    trigger_event: dict,
    db,
    claim_gps_lat: Optional[float] = None,
    claim_gps_lng: Optional[float] = None,
) -> Dict:
    """
    Fraud scoring system with operational explanations.
    Score < 0.70 => auto approve
    Score >= 0.70 => manual review
    """
    score = 0.0
    flags: list[str] = []
    checks: dict = {}
    explanation: list[str] = []

    worker_id = str(worker["_id"])
    zone_lat = worker.get("zone_lat", 0)
    zone_lng = worker.get("zone_lng", 0)

    existing = await db.claims.find_one({
        "worker_id": worker_id,
        "trigger_event_id": str(trigger_event["_id"]),
        "status": {"$ne": "REJECTED"},
    })
    if existing:
        checks["duplicate"] = {"result": "FAIL", "score": 1.0}
        return {
            "score": 1.0,
            "flags": ["DUPLICATE_CLAIM"],
            "checks": checks,
            "decision": "REJECTED",
            "explanation": ["A claim already exists for this worker and trigger event."],
        }
    checks["duplicate"] = {"result": "PASS", "score": 0.0}

    if claim_gps_lat and claim_gps_lng:
        from app.utils.geo import haversine_distance

        distance = haversine_distance(claim_gps_lat, claim_gps_lng, zone_lat, zone_lng)
        if distance > 10:
            score += 0.30
            flags.append("GPS_FAR_FROM_ZONE")
            checks["gps"] = {"result": "FAIL", "distance_km": distance, "score": 0.30}
        elif distance > 5:
            score += 0.15
            checks["gps"] = {"result": "WARNING", "distance_km": distance, "score": 0.15}
        else:
            checks["gps"] = {"result": "PASS", "distance_km": distance, "score": 0.0}
    else:
        checks["gps"] = {"result": "NO_SIGNAL", "score": 0.0}

    last_order = worker.get("last_order_timestamp")
    if last_order:
        trigger_time = trigger_event.get("started_at", datetime.utcnow())
        age_minutes = (trigger_time - last_order).total_seconds() / 60
        if age_minutes > 360:
            score += 0.25
            flags.append("NO_RECENT_ACTIVITY")
            checks["activity"] = {"result": "FAIL", "age_minutes": age_minutes, "score": 0.25}
        elif age_minutes > 240:
            score += 0.12
            checks["activity"] = {"result": "WARNING", "age_minutes": age_minutes, "score": 0.12}
        else:
            checks["activity"] = {"result": "PASS", "age_minutes": age_minutes, "score": 0.0}
    else:
        score += 0.12
        flags.append("NO_ACTIVITY_SIGNAL")
        checks["activity"] = {"result": "WARNING", "score": 0.12}

    thirty_days_ago = datetime.utcnow() - timedelta(days=30)
    recent_claims = await db.claims.count_documents({
        "worker_id": worker_id,
        "created_at": {"$gte": thirty_days_ago},
        "status": {"$ne": "REJECTED"},
    })
    zone_avg_result = await db.claims.aggregate([
        {"$match": {
            "created_at": {"$gte": thirty_days_ago},
            "status": {"$ne": "REJECTED"},
        }},
        {"$group": {"_id": "$worker_id", "count": {"$sum": 1}}},
        {"$group": {"_id": None, "avg": {"$avg": "$count"}}},
    ]).to_list(1)
    zone_avg = zone_avg_result[0]["avg"] if zone_avg_result else 1.5
    if recent_claims > zone_avg * 2.5:
        score += 0.20
        flags.append("HIGH_CLAIM_FREQUENCY")
        checks["frequency"] = {
            "result": "FAIL",
            "recent_claims": recent_claims,
            "zone_avg": zone_avg,
            "score": 0.20,
        }
    else:
        checks["frequency"] = {"result": "PASS", "recent_claims": recent_claims, "score": 0.0}

    one_hour_ago = datetime.utcnow() - timedelta(hours=1)
    claims_last_hour = await db.claims.count_documents({
        "worker_id": worker_id,
        "created_at": {"$gte": one_hour_ago},
        "status": {"$ne": "REJECTED"},
    })
    if claims_last_hour > 2:
        score += 0.25
        flags.append("HIGH_CLAIM_VELOCITY")
        checks["velocity"] = {"result": "FAIL", "claims_last_hour": claims_last_hour, "score": 0.25}
    else:
        checks["velocity"] = {"result": "PASS", "claims_last_hour": claims_last_hour, "score": 0.0}

    total_workers = trigger_event.get("total_workers_in_zone", 1)
    claims_count = trigger_event.get("claims_count", 0)
    if total_workers > 0:
        ratio = claims_count / total_workers
        if ratio >= 0.60:
            score -= 0.20
            checks["correlation"] = {"result": "CONFIRMED", "ratio": ratio, "score": -0.20}
        elif ratio < 0.10 and claims_count < 3:
            score += 0.40
            flags.append("LOW_ZONE_CORRELATION")
            checks["correlation"] = {"result": "ANOMALY", "ratio": ratio, "score": 0.40}
        else:
            checks["correlation"] = {"result": "NORMAL", "ratio": ratio, "score": 0.0}

    worker_risk = worker.get("risk_score", 0.75)
    if worker_risk < 0.30:
        score += 0.20
        flags.append("HIGH_RISK_WORKER")
        checks["worker_risk"] = {"result": "FAIL", "risk_score": worker_risk, "score": 0.20}
    else:
        checks["worker_risk"] = {"result": "PASS", "risk_score": worker_risk, "score": 0.0}

    created_at = worker.get("created_at", datetime.utcnow())
    account_age_days = (datetime.utcnow() - created_at).days
    if account_age_days < 7:
        score += 0.15
        flags.append("NEW_ACCOUNT")
        checks["account_age"] = {"result": "WARNING", "age_days": account_age_days, "score": 0.15}
    else:
        checks["account_age"] = {"result": "PASS", "age_days": account_age_days, "score": 0.0}

    previous_claim = await db.claims.find_one(
        {"worker_id": worker_id, "status": {"$ne": "REJECTED"}},
        sort=[("created_at", -1)],
    )
    if previous_claim and previous_claim.get("gps_distance_km", 0) > 25:
        minutes_since_previous = max(
            (datetime.utcnow() - previous_claim.get("created_at", datetime.utcnow())).total_seconds() / 60,
            1,
        )
        if minutes_since_previous < 30:
            score += 0.20
            flags.append("IMPOSSIBLE_TRAVEL")
            checks["impossible_travel"] = {
                "result": "FAIL",
                "minutes_since_previous": round(minutes_since_previous, 1),
                "score": 0.20,
            }
        else:
            checks["impossible_travel"] = {
                "result": "PASS",
                "minutes_since_previous": round(minutes_since_previous, 1),
                "score": 0.0,
            }
    else:
        checks["impossible_travel"] = {"result": "NO_SIGNAL", "score": 0.0}

    if not worker.get("device_fingerprint_hash"):
        score += 0.05
        flags.append("DEVICE_FINGERPRINT_MISSING")
        checks["device_fingerprint"] = {"result": "WARNING", "score": 0.05}
    else:
        checks["device_fingerprint"] = {"result": "PASS", "score": 0.0}

    zone_history_mismatch = (
        worker.get("zone")
        and trigger_event.get("zone")
        and worker.get("zone") != trigger_event.get("zone")
    )
    if zone_history_mismatch:
        score += 0.10
        flags.append("ZONE_HISTORY_MISMATCH")
        checks["zone_history"] = {
            "result": "WARNING",
            "registered_zone": worker.get("zone"),
            "trigger_zone": trigger_event.get("zone"),
            "score": 0.10,
        }
    else:
        checks["zone_history"] = {"result": "PASS", "score": 0.0}

    # CHECK 8 — Advanced GPS Spoofing
    if claim_gps_lat and claim_gps_lng:
        from app.services.gps_fraud_service import (
            run_advanced_gps_checks
        )
        gps_result = await run_advanced_gps_checks(
            worker=worker,
            claim={},
            db=db,
            claim_lat=claim_gps_lat,
            claim_lng=claim_gps_lng,
        )
        checks["gps_spoofing"] = gps_result
        score += gps_result["gps_fraud_score"] * 0.5
        if gps_result["gps_spoofing_detected"]:
            flags.extend(gps_result["gps_flags"])

    # CHECK 9 — Historical Weather Validation
    from app.services.weather_validation import (
        validate_weather_claim
    )
    zone = worker.get("zone", "")
    zone_lat = worker.get("zone_lat", 0)
    zone_lng = worker.get("zone_lng", 0)
    trigger_type = trigger_event.get(
        "trigger_type", "FLOOD"
    )

    weather_result = await validate_weather_claim(
        zone_lat=zone_lat,
        zone_lng=zone_lng,
        claim_date=datetime.utcnow(),
        trigger_type=trigger_type,
        db=db,
        zone=zone,
    )
    checks["weather_validation"] = weather_result
    score += weather_result["fraud_score_contribution"]
    if weather_result["decision"] == "WEATHER_UNCONFIRMED":
        flags.append("WEATHER_NOT_CONFIRMED")

    final_score = round(max(0.0, min(1.0, score)), 3)
    decision = "AUTO_APPROVED" if final_score < 0.70 else "MANUAL_REVIEW"
    explanation.append(
        "No major fraud indicators were triggered."
        if not flags else
        f"Flags triggered: {', '.join(flags)}."
    )

    return {
        "score": final_score,
        "flags": flags,
        "checks": checks,
        "decision": decision,
        "explanation": explanation,
        "fraud_version": "v3_advanced",
    }
