import feedparser
import httpx
import asyncio
import re
import hashlib
from pymongo.errors import DuplicateKeyError
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from datetime import datetime, timedelta
from app.config import settings
from app.database import get_db
from app.services.payout_audit_service import append_payout_audit
import logging

logger = logging.getLogger(__name__)
scheduler = AsyncIOScheduler()


def _escape_regex(value: str) -> str:
    return re.escape((value or "").strip())


def _build_event_hash(alert: dict) -> str:
    parts = [
        (alert.get("city") or "").strip().lower(),
        (alert.get("zone") or "").strip().lower(),
        (alert.get("type") or "").strip().upper(),
        (alert.get("severity") or "").strip().upper(),
        (alert.get("source") or "").strip().upper(),
        str(alert.get("published") or "")[:13],
    ]
    return hashlib.sha256("|".join(parts).encode("utf-8")).hexdigest()


async def _get_active_policies_by_worker(db, worker_ids: list[str]) -> dict[str, dict]:
    if not worker_ids:
        return {}
    policies = await db.policies.find({
        "worker_id": {"$in": worker_ids},
        "status": "ACTIVE",
    }).to_list(len(worker_ids))
    return {policy["worker_id"]: policy for policy in policies}


async def _calculate_remaining_weekly_coverage(db, policy: dict) -> float:
    reserved_statuses = ["PENDING", "VERIFYING", "AUTO_APPROVED", "MANUAL_REVIEW", "PAID"]
    rows = await db.claims.aggregate([
        {"$match": {
            "policy_id": str(policy["_id"]),
            "created_at": {
                "$gte": policy["week_start"],
                "$lte": policy["week_end"],
            },
            "status": {"$in": reserved_statuses},
        }},
        {"$group": {"_id": None, "total": {"$sum": "$amount"}}},
    ]).to_list(1)
    used = float(rows[0]["total"]) if rows else 0.0
    return round(max(0.0, float(policy.get("coverage_cap", 600.0)) - used), 2)

# Known flood-prone cities with coordinates
MONITORED_ZONES = [
    {
        "city": "Hyderabad",
        "zone": "kondapur-hyderabad",
        "lat": 17.4401,
        "lng": 78.3489,
        "imd_district": "Hyderabad",
        "state": "Telangana"
    },
    {
        "city": "Mumbai",
        "zone": "kurla-mumbai",
        "lat": 19.0728,
        "lng": 72.8826,
        "imd_district": "Mumbai",
        "state": "Maharashtra"
    },
    {
        "city": "Chennai",
        "zone": "tnagar-chennai",
        "lat": 13.0418,
        "lng": 80.2341,
        "imd_district": "Chennai",
        "state": "Tamil Nadu"
    },
    {
        "city": "Bengaluru",
        "zone": "koramangala-bengaluru",
        "lat": 12.9352,
        "lng": 77.6245,
        "imd_district": "Bangalore",
        "state": "Karnataka"
    },
    {
        "city": "Delhi",
        "zone": "dwarka-delhi",
        "lat": 28.5921,
        "lng": 77.0460,
        "imd_district": "Delhi",
        "state": "Delhi"
    },
]


async def fetch_imd_alerts() -> list:
    """
    Fetch flood and weather alerts from IMD SACHET RSS.
    Returns list of active alerts from real feed only.
    """
    alerts = []
    try:
        rss_urls = [
            "https://sachet.ndma.gov.in/cap_public_website/FeedPage",
            "https://mausam.imd.gov.in/imd_latest/contents/warning.php",
        ]

        async with httpx.AsyncClient(timeout=10.0) as client:
            for url in rss_urls:
                try:
                    response = await client.get(url)
                    if response.status_code == 200:
                        feed = feedparser.parse(response.text)
                        for entry in feed.entries:
                            alert = parse_imd_entry(entry)
                            if alert:
                                alerts.append(alert)
                except Exception as e:
                    logger.warning(f"IMD feed {url} failed: {e}")

    except Exception as e:
        logger.error(f"IMD fetch error: {e}")

    return alerts


def parse_imd_entry(entry) -> dict:
    """Parse an IMD RSS entry into structured alert"""
    try:
        title = entry.get("title", "").lower()
        summary = entry.get("summary", "").lower()

        flood_keywords = [
            "flood", "heavy rain", "red alert",
            "orange alert", "cyclone", "storm"
        ]

        is_flood_alert = any(
            kw in title or kw in summary
            for kw in flood_keywords
        )

        if not is_flood_alert:
            return None

        if "red alert" in title or "red alert" in summary:
            severity = "RED"
        elif "orange alert" in title or "orange" in summary:
            severity = "ORANGE"
        else:
            severity = "YELLOW"

        for zone in MONITORED_ZONES:
            if (zone["city"].lower() in title or
                    zone["city"].lower() in summary or
                    zone["state"].lower() in title):
                return {
                    "city": zone["city"],
                    "zone": zone["zone"],
                    "lat": zone["lat"],
                    "lng": zone["lng"],
                    "severity": severity,
                    "type": "FLOOD",
                    "source": "IMD_SACHET",
                    "title": entry.get("title", ""),
                    "description": entry.get("summary", ""),
                    "published": entry.get("published", ""),
                }
        return None
    except Exception:
        return None


async def check_platform_outages() -> list:
    """
    Check platform outage status via Downdetector scraping.
    Returns confirmed outages only — no simulated data.
    """
    from app.services.downdetector_service import get_all_platform_statuses

    outages = []
    try:
        statuses = await get_all_platform_statuses()
        for status in statuses:
            if status.get("status") == "outage":
                # Map platform to city/zone
                platform_zone_map = {
                    "zepto": {"city": "Mumbai", "zone": "kurla-mumbai",
                               "lat": 19.0728, "lng": 72.8826},
                    "swiggy": {"city": "Bengaluru", "zone": "koramangala-bengaluru",
                                "lat": 12.9352, "lng": 77.6245},
                    "blinkit": {"city": "Delhi", "zone": "dwarka-delhi",
                                 "lat": 28.5921, "lng": 77.0460},
                    "zomato": {"city": "Hyderabad", "zone": "kondapur-hyderabad",
                                "lat": 17.4401, "lng": 78.3489},
                }
                zone_info = platform_zone_map.get(status["platform"])
                if zone_info:
                    outages.append({
                        "platform": status["platform"],
                        "city": zone_info["city"],
                        "zone": zone_info["zone"],
                        "lat": zone_info["lat"],
                        "lng": zone_info["lng"],
                        "severity": "OUTAGE",
                        "type": "OUTAGE",
                        "source": "DOWNDETECTOR",
                        "report_count": status.get("report_count", 0),
                    })
    except Exception as e:
        logger.warning(f"Platform outage check failed: {e}")

    return outages


async def process_trigger_events(alerts: list, db) -> list:
    """
    Process detected alerts into trigger events.
    Find affected workers and create claims.
    """
    created_events = []

    for alert in alerts:
        event_hash = _build_event_hash(alert)
        existing = await db.trigger_events.find_one({"event_hash": event_hash})

        if existing:
            created_events.append(existing)
            continue  # Skip duplicate

        city_pattern = _escape_regex(alert.get("city", ""))
        zone_pattern = _escape_regex(alert.get("zone", ""))
        worker_query = {
            "is_active": True,
            "$or": [
                {"zone": alert["zone"]},
                {"city": {"$regex": f"^{city_pattern}$", "$options": "i"}},
                {"city": {"$regex": city_pattern, "$options": "i"}},
                {"zone": {"$regex": zone_pattern, "$options": "i"}},
            ],
        }
        workers_in_zone = await db.workers.find(worker_query).to_list(1000)
        worker_ids = [str(worker["_id"]) for worker in workers_in_zone]
        active_policies = await _get_active_policies_by_worker(db, worker_ids)
        active_worker_ids = list(active_policies.keys())

        payout_pct = {
            "FLOOD": 1.0,
            "PREDICTIVE_FLOOD": 0.50,
            "OUTAGE": 0.75,
            "CURFEW": 1.0,
            "AIR_QUALITY": 0.50,
            "HEAT_WAVE": 0.50,
            "FESTIVAL_DISRUPTION": 0.40,
        }.get(alert["type"], 1.0)

        total_exposure = 0.0
        for policy in active_policies.values():
            total_exposure += float(policy.get("coverage_cap", 600.0)) * payout_pct

        from bson import ObjectId
        event_doc = {
            "_id": str(ObjectId()),
            "trigger_type": alert["type"],
            "city": alert["city"],
            "zone": alert["zone"],
            "lat": alert.get("lat", 0),
            "lng": alert.get("lng", 0),
            "severity": alert.get("severity", "ORANGE"),
            "source": alert.get("source", "IMD_SACHET"),
            "event_hash": event_hash,
            "source_data": alert,
            "status": "ACTIVE",
            "payout_percentage": payout_pct,
            "affected_workers": len(active_worker_ids),
            "total_exposure": total_exposure,
            "total_workers_in_zone": len(workers_in_zone),
            "claims_count": 0,
            "confirmation_status": "PENDING",
            "started_at": datetime.utcnow(),
            "expires_at": datetime.utcnow() + timedelta(hours=24),
        }

        try:
            await db.trigger_events.insert_one(event_doc)
        except DuplicateKeyError:
            existing = await db.trigger_events.find_one({"event_hash": event_hash})
            if existing:
                created_events.append(existing)
                continue
            raise
        logger.info(
            f"Trigger matched {len(workers_in_zone)} workers "
            f"and {len(active_worker_ids)} active policies "
            f"for {alert['type']} in {alert['city']}"
        )

        for worker in workers_in_zone:
            if str(worker["_id"]) in active_worker_ids:
                await create_automatic_claim(
                    worker=worker,
                    trigger_event=event_doc,
                    db=db,
                    policy=active_policies[str(worker["_id"])],
                )

        created_events.append(event_doc)
        logger.info(
            f"Trigger event created: {alert['type']} "
            f"in {alert['city']} — "
            f"{len(active_worker_ids)} workers affected"
        )

    return created_events


async def create_automatic_claim(worker: dict, trigger_event: dict, db, policy: dict | None = None):
    """Create and process a claim automatically"""
    from app.services.fraud_service import calculate_fraud_score
    from app.services.underwriting_service import evaluate_worker_eligibility
    from app.services.premium_service import calculate_payout_amount
    from bson import ObjectId

    worker_id = str(worker["_id"])

    policy = policy or await db.policies.find_one({
        "worker_id": worker_id,
        "status": "ACTIVE"
    })

    if not policy:
        return

    # --- Income-based dynamic payout ---
    daily_orders = float(
        worker.get(
            "avg_orders_per_day",
            worker.get("avg_daily_orders", worker.get("daily_orders", 8)),
        )
    )
    payout_info = calculate_payout_amount(daily_orders)
    income_payout = payout_info["payout_amount"]
    payout_tier = payout_info["payout_tier"]

    eligibility = await evaluate_worker_eligibility(worker, policy, trigger_event, db)
    remaining_coverage = await _calculate_remaining_weekly_coverage(db, policy)

    # Use income-based payout scaled by payout percentage, but cap at remaining coverage
    proposed_payout = round(
        income_payout * trigger_event["payout_percentage"],
        2,
    )
    payout_amount = round(min(proposed_payout, remaining_coverage), 2)

    fraud_result = await calculate_fraud_score(
        worker=worker,
        trigger_event=trigger_event,
        db=db
    )

    is_admin_simulation = (
        trigger_event.get("source") == "ADMIN_SIMULATION" or
        trigger_event.get("source_data", {}).get("source") == "ADMIN_SIMULATION"
    )

    if is_admin_simulation:
        status = "AUTO_APPROVED"
        fraud_result = {
            "score": 0.0,
            "flags": [],
            "checks": {
                "simulation": {"result": "BYPASS", "score": 0.0},
                "underwriting": {"result": "BYPASS", "score": 0.0},
            },
            "decision": "AUTO_APPROVED",
            "explanation": ["Admin simulation bypassed fraud checks"],
        }
    elif payout_amount <= 0:
        status = "REJECTED"
        fraud_result["flags"].append("WEEKLY_CAP_EXHAUSTED")
        fraud_result["checks"]["coverage_cap"] = {
            "result": "FAIL",
            "remaining": remaining_coverage,
            "score": 1.0,
        }
    elif not eligibility["eligible"]:
        status = "REJECTED"
        fraud_result["flags"].extend(eligibility["reasons"])
        fraud_result["checks"]["underwriting"] = {
            "result": "FAIL",
            "reasons": eligibility["reasons"],
            "score": 1.0,
        }
    elif fraud_result["decision"] == "REJECTED":
        status = "REJECTED"
    elif fraud_result["decision"] == "AUTO_APPROVED":
        status = "AUTO_APPROVED"
    else:
        status = "MANUAL_REVIEW"

    claim_doc = {
        "_id": str(ObjectId()),
        "worker_id": worker_id,
        "policy_id": str(policy["_id"]),
        "trigger_event_id": str(trigger_event["_id"]),
        "trigger_type": trigger_event["trigger_type"],
        "amount": payout_amount,
        "payout_amount": payout_amount,
        "payout_tier": payout_tier,
        "daily_orders_at_claim": daily_orders,
        "status": status,
        "fraud_score": fraud_result["score"],
        "fraud_flags": fraud_result["flags"],
        "fraud_checks": fraud_result["checks"],
        "activity_verified": fraud_result["checks"].get(
            "activity", {}
        ).get("result") == "PASS",
        "zone_correlation_ratio": trigger_event.get(
            "claims_count", 0
        ) / max(trigger_event.get("total_workers_in_zone", 1), 1),
        "payout_status": (
            "INITIATED"
            if status == "AUTO_APPROVED" and policy.get("auto_payout", False)
            else "NOT_STARTED"
        ),
        "payout_audit_log": [],
        "payout_attempts": 0,
        "policy_week_remaining_after_claim": round(max(0.0, remaining_coverage - payout_amount), 2),
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow(),
    }

    try:
        await db.claims.insert_one(claim_doc)
    except DuplicateKeyError:
        logger.info(
            f"Skipped duplicate claim for worker {worker_id} trigger {trigger_event['_id']}"
        )
        return

    await append_payout_audit(
        db=db,
        claim_id=claim_doc["_id"],
        step="TRIGGER_CONFIRMED",
        status="SUCCESS",
        message=f"{trigger_event['trigger_type']} trigger confirmed in {trigger_event['city']}",
        meta={"trigger_event_id": str(trigger_event["_id"])},
    )
    await append_payout_audit(
        db=db,
        claim_id=claim_doc["_id"],
        step="ELIGIBILITY_CHECK",
        status="SUCCESS" if eligibility["eligible"] or is_admin_simulation else "FAILED",
        message="Worker eligibility evaluated",
        meta=eligibility,
    )
    await append_payout_audit(
        db=db,
        claim_id=claim_doc["_id"],
        step="PAYOUT_CALCULATED",
        status="SUCCESS" if payout_amount > 0 else "FAILED",
        message=f"Payout calculated at Rs{payout_amount}",
        meta={
            "proposed_payout": proposed_payout,
            "remaining_coverage": remaining_coverage,
            "weekly_cap": float(policy.get("coverage_cap", 600.0)),
        },
    )
    logger.info(
        f"Claim created for worker {worker_id} "
        f"with status {status} and amount {payout_amount}"
    )

    await db.trigger_events.update_one(
        {"_id": str(trigger_event["_id"])},
        {"$inc": {"claims_count": 1}}
    )

    should_force_demo_payout = is_admin_simulation
    if status == "AUTO_APPROVED" and (policy.get("auto_payout", False) or should_force_demo_payout):
        await process_payout_transfer(claim=claim_doc, worker=worker, db=db)


async def initiate_payout(claim: dict, worker: dict, db):
    """Mock payout for competition demo — no real bank transfer"""
    import os
    try:
        mock_mode = os.getenv("RAZORPAY_MOCK_MODE", "true") == "true"

        if mock_mode:
            payout_id = f"MOCK_GP_{str(claim['_id'])[:8].upper()}"
            logger.info(
                f"[MOCK PAYOUT] ₹{claim['amount']} "
                f"to {worker.get('upi_id', 'worker@upi')} "
                f"— ID: {payout_id}"
            )
            await db.claims.update_one(
                {"_id": str(claim["_id"])},
                {"$set": {
                    "status": "PAID",
                    "paid_at": datetime.utcnow(),
                    "razorpay_payout_id": payout_id,
                }}
            )
            await db.workers.update_one(
                {"_id": str(worker["_id"])},
                {"$inc": {
                    "total_claims": 1,
                    "total_payouts": claim["amount"]
                }}
            )
            logger.info(
                f"Payout credited for worker {worker.get('_id')} "
                f"claim {claim.get('_id')} amount {claim['amount']}"
            )
            return payout_id

    except Exception as e:
        logger.error(f"Payout failed for claim {claim['_id']}: {e}")


async def process_payout_transfer(claim: dict, worker: dict, db):
    """Hardened payout flow with state transitions and audit logging."""
    import os

    try:
        await append_payout_audit(
            db=db,
            claim_id=str(claim["_id"]),
            step="TRANSFER_INITIATED",
            status="PROCESSING",
            message="Payout transfer initiated",
            meta={"upi_id": worker.get("upi_id")},
        )
        await db.claims.update_one(
            {"_id": str(claim["_id"])},
            {
                "$set": {
                    "payout_status": "PROCESSING",
                    "updated_at": datetime.utcnow(),
                },
                "$inc": {"payout_attempts": 1},
            }
        )

        mock_mode = os.getenv("RAZORPAY_MOCK_MODE", "true") == "true"
        if not mock_mode:
            raise RuntimeError("Real payout provider not configured")

        payout_id = f"MOCK_GP_{str(claim['_id'])[:8].upper()}"
        await db.claims.update_one(
            {"_id": str(claim["_id"])},
            {"$set": {
                "status": "PAID",
                "paid_at": datetime.utcnow(),
                "razorpay_payout_id": payout_id,
                "payout_status": "SUCCESS",
                "updated_at": datetime.utcnow(),
            }}
        )
        await db.workers.update_one(
            {"_id": str(worker["_id"])},
            {"$inc": {
                "total_claims": 1,
                "total_payouts": claim["amount"],
            }}
        )
        await append_payout_audit(
            db=db,
            claim_id=str(claim["_id"]),
            step="PAYMENT_SUCCESS",
            status="SUCCESS",
            message=f"Mock payout succeeded with id {payout_id}",
            meta={"payout_id": payout_id, "amount": claim["amount"]},
        )
        return payout_id
    except Exception as exc:
        await db.claims.update_one(
            {"_id": str(claim["_id"])},
            {"$set": {
                "payout_status": "FAILED",
                "status": "AUTO_APPROVED",
                "updated_at": datetime.utcnow(),
            }}
        )
        await append_payout_audit(
            db=db,
            claim_id=str(claim["_id"]),
            step="PAYMENT_FAILED",
            status="FAILED",
            message=f"Payout failed: {exc}",
            meta={"error": str(exc)},
        )
        raise


async def check_aqi_heatwave() -> list:
    """
    Check for extreme AQI or heat wave conditions.
    Uses OpenWeatherMap Air Pollution API (free tier).
    Triggers when AQI index >= 4 (Very Poor) or temperature >= 43 degrees C.
    """
    import os
    alerts = []
    AQI_THRESHOLD = 4   # Very Poor on 0-5 scale
    HEAT_THRESHOLD = 43  # Celsius

    api_key = os.getenv("OPENWEATHER_API_KEY")

    for zone in MONITORED_ZONES:
        try:
            if api_key:
                async with httpx.AsyncClient(timeout=8.0) as client:
                    # Air pollution check
                    aqi_res = await client.get(
                        "http://api.openweathermap.org/data/2.5/air_pollution",
                        params={
                            "lat": zone["lat"],
                            "lon": zone["lng"],
                            "appid": api_key,
                        }
                    )
                    if aqi_res.status_code == 200:
                        aqi_data = aqi_res.json()
                        aqi = aqi_data["list"][0]["main"]["aqi"]
                        if aqi >= AQI_THRESHOLD:
                            alerts.append({
                                "city": zone["city"],
                                "zone": zone["zone"],
                                "lat": zone["lat"],
                                "lng": zone["lng"],
                                "severity": "ORANGE",
                                "type": "AIR_QUALITY",
                                "source": "OPENWEATHER_AQI",
                                "aqi_index": aqi,
                                "title": f"Very Poor Air Quality — {zone['city']}",
                                "description": f"AQI index {aqi}/5 — delivery workers at health risk",
                                "published": datetime.utcnow().isoformat(),
                            })

                    # Heat wave check
                    weather_res = await client.get(
                        "https://api.openweathermap.org/data/2.5/weather",
                        params={
                            "lat": zone["lat"],
                            "lon": zone["lng"],
                            "appid": api_key,
                            "units": "metric",
                        }
                    )
                    if weather_res.status_code == 200:
                        w = weather_res.json()
                        temp = w["main"]["temp"]
                        if temp >= HEAT_THRESHOLD:
                            alerts.append({
                                "city": zone["city"],
                                "zone": zone["zone"],
                                "lat": zone["lat"],
                                "lng": zone["lng"],
                                "severity": "RED",
                                "type": "HEAT_WAVE",
                                "source": "OPENWEATHER_HEAT",
                                "temperature_c": temp,
                                "title": f"Heat Wave Alert — {zone['city']} {temp:.0f}C",
                                "description": f"Extreme heat {temp:.0f}C — platforms may pause operations",
                                "published": datetime.utcnow().isoformat(),
                            })
        except Exception as e:
            logger.warning(f"AQI check failed for {zone['city']}: {e}")

    return alerts


async def check_festival_disruption() -> list:
    """
    Check if today is a major Indian festival that causes significant delivery disruption.
    Uses a hardcoded calendar of high-impact events.
    """
    from app.utils.constants import DISRUPTION_CALENDAR

    today = datetime.utcnow()
    month = today.month
    day = today.day
    key = f"{str(month).zfill(2)}-{str(day).zfill(2)}"

    event = DISRUPTION_CALENDAR.get(key)
    if not event:
        return []

    if event["disruption_level"] < 0.40:
        return []

    alerts = []
    for zone in MONITORED_ZONES:
        # Only trigger for affected cities (None = all cities)
        if event.get("cities") and zone["city"] not in event["cities"]:
            continue

        alerts.append({
            "city": zone["city"],
            "zone": zone["zone"],
            "lat": zone["lat"],
            "lng": zone["lng"],
            "severity": "ORANGE",
            "type": "FESTIVAL_DISRUPTION",
            "source": "CALENDAR_ENGINE",
            "event_name": event["name"],
            "disruption_level": event["disruption_level"],
            "title": f"{event['name']} Disruption — {zone['city']}",
            "description": f"{event['name']}: {event['description']}",
            "published": datetime.utcnow().isoformat(),
        })

    return alerts


async def check_curfew_alerts() -> list:
    """
    Check for government-issued curfew orders.
    Mock implementation — in production: scrape state government feeds.
    """
    return []


async def check_predictive_triggers() -> list:
    """
    Evaluates ML flood probability for all zones.
    If probability > 85%, triggers a predictive ADVANCE_PAYOUT (50%) to workers.
    """
    from app.ml.ml_service import predict_flood_probability
    
    db = get_db()
    if db is None:
        return []
    
    alerts = []
    for zone in MONITORED_ZONES:
        try:
            forecast = predict_flood_probability(zone["zone"])
            if forecast["probability"] > 0.85:
                logger.info(f"PREDICTIVE TRIGGER: {zone['city']} flood probability {forecast['probability_percent']}%")
                alerts.append({
                    "city": zone["city"],
                    "zone": zone["zone"],
                    "lat": zone["lat"],
                    "lng": zone["lng"],
                    "severity": "RED",
                    "type": "PREDICTIVE_FLOOD",
                    "source": "ML_FORECAST",
                    "title": f"Predictive Flood Alert ({forecast['probability_percent']}%)",
                    "description": "ML model predicts severe flooding within 24h. Advance payout initiated.",
                    "published": datetime.utcnow().isoformat(),
                })
        except Exception as e:
            logger.warning(f"Predictive check failed for {zone['city']}: {e}")
            
    return alerts

async def run_trigger_check():
    """Main scheduled function — runs every 15 minutes. Checks all 5 trigger types + Predictive."""
    logger.info("Running trigger check (5 trigger types + predictive)...")

    db = get_db()
    if db is None:
        return

    flood_alerts = await fetch_imd_alerts()
    outage_alerts = await check_platform_outages()
    aqi_alerts = await check_aqi_heatwave()
    festival_alerts = await check_festival_disruption()
    curfew_alerts = await check_curfew_alerts()
    predictive_alerts = await check_predictive_triggers()

    all_alerts = (
        flood_alerts + outage_alerts +
        aqi_alerts + festival_alerts + curfew_alerts + predictive_alerts
    )

    if all_alerts:
        events = await process_trigger_events(all_alerts, db)
        logger.info(
            f"Processed {len(events)} new trigger events "
            f"from {len(all_alerts)} alerts across 6 sources"
        )

    return all_alerts

async def start_trigger_scheduler():
    """Start the background scheduler"""
    async def _clean_expired_policies():
        db = get_db()
        if db is None: return
        now = datetime.utcnow()
        cursor = db.policies.find({"status": "ACTIVE", "plan_type": "daily", "expires_at": {"$lt": now}})
        async for p in cursor:
            await db.policies.update_one({"_id": p["_id"]}, {"$set": {"status": "EXPIRED", "updated_at": now}})

    scheduler.add_job(
        run_trigger_check,
        "interval",
        minutes=settings.trigger_poll_interval_minutes,
        id="trigger_check",
        replace_existing=True,
    )
    scheduler.add_job(
        _clean_expired_policies,
        "interval",
        minutes=30,
        id="clean_policies",
        replace_existing=True,
    )
    scheduler.start()
    logger.info(
        f"Trigger scheduler started — "
        f"polling every {settings.trigger_poll_interval_minutes} minutes"
    )
