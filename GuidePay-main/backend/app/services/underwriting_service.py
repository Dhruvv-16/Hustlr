from datetime import datetime, timedelta


async def evaluate_worker_eligibility(worker: dict, policy: dict, trigger_event: dict, db) -> dict:
    reasons = []

    created_at = worker.get("created_at", datetime.utcnow())
    active_days = max((datetime.utcnow() - created_at).days, 0)
    if active_days < 7:
        reasons.append("MIN_ACTIVE_DAYS_NOT_MET")

    platforms = worker.get("platforms", [])
    if len(platforms) == 0:
        reasons.append("PLATFORM_NOT_VERIFIED")

    worker_zone = (worker.get("zone") or "").strip().lower()
    trigger_zone = (trigger_event.get("zone") or "").strip().lower()
    worker_city = (worker.get("city") or "").strip().lower()
    trigger_city = (trigger_event.get("city") or "").strip().lower()
    if worker_zone != trigger_zone and worker_city != trigger_city:
        reasons.append("ZONE_NOT_ELIGIBLE")

    last_order = worker.get("last_order_timestamp")
    if not last_order or last_order < datetime.utcnow() - timedelta(days=14):
        reasons.append("INSUFFICIENT_RECENT_ACTIVITY")

    return {
        "eligible": len(reasons) == 0,
        "reasons": reasons,
        "checks": {
            "minimum_active_days": active_days >= 7,
            "platform_verified": len(platforms) > 0,
            "zone_eligible": worker_zone == trigger_zone or worker_city == trigger_city,
            "recent_activity": bool(last_order and last_order >= datetime.utcnow() - timedelta(days=14)),
        },
    }
