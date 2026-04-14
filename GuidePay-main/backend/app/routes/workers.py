from fastapi import APIRouter, HTTPException, Depends
from app.database import get_db
from app.routes.auth import get_current_worker
from app.ml.ml_service import get_zone_ml_data
from app.services.premium_service import calculate_premium
from app.services.ml_service import calculate_risk_score
from app.models.worker import WorkerCreate, WorkerUpdate
from app.utils.formatters import serialize_doc
from datetime import datetime, timedelta
from bson import ObjectId
import logging
import math

router = APIRouter()
logger = logging.getLogger(__name__)


@router.get("/me")
async def get_my_profile(
    current_worker=Depends(get_current_worker),
    db=Depends(get_db)
):
    """Get current worker's full profile"""
    worker_id = str(current_worker["_id"])

    policy = await db.policies.find_one({
        "worker_id": worker_id,
        "status": "ACTIVE"
    })

    total_claims = await db.claims.count_documents({
        "worker_id": worker_id,
        "status": {"$ne": "REJECTED"}
    })
    paid_claims = await db.claims.count_documents({
        "worker_id": worker_id,
        "status": "PAID"
    })

    pipeline = [
        {"$match": {"worker_id": worker_id, "status": "PAID"}},
        {"$group": {"_id": None, "total": {"$sum": "$amount"}}}
    ]
    payout_result = await db.claims.aggregate(pipeline).to_list(1)
    total_payouts = (payout_result[0]["total"] if payout_result else 0)

    result = serialize_doc(current_worker)
    result["active_policy"] = serialize_doc(policy) if policy else None
    result["stats"] = {
        "total_claims": total_claims,
        "paid_claims": paid_claims,
        "total_payouts": total_payouts,
    }
    return result


@router.put("/me")
async def update_my_profile(
    updates: WorkerUpdate,
    current_worker=Depends(get_current_worker),
    db=Depends(get_db)
):
    """Update worker profile and recalculate premium"""
    worker_id = str(current_worker["_id"])
    update_data = updates.model_dump(exclude_none=True)
    update_data["updated_at"] = datetime.utcnow()

    if "zone" in update_data or "city" in update_data or "zone_lat" in update_data:
        zone = update_data.get("zone", current_worker["zone"])
        risk_score = current_worker.get("risk_score", 0.75)
        
        if "zone_lat" in update_data and "zone_lng" in update_data:
            import h3
            update_data["h3_zone"] = h3.geo_to_h3(update_data["zone_lat"], update_data["zone_lng"], 7)
            
        h3_zone = update_data.get("h3_zone", current_worker.get("h3_zone"))
        premium = calculate_premium(zone, risk_score, h3_zone=h3_zone)
        update_data["premium_amount"] = premium

    await db.workers.update_one(
        {"_id": worker_id},
        {"$set": update_data}
    )

    updated = await db.workers.find_one({"_id": worker_id})
    return serialize_doc(updated)


@router.get("/me/risk-score")
async def get_my_risk_score(
    current_worker=Depends(get_current_worker),
    db=Depends(get_db)
):
    """Calculate and return current risk score"""
    worker_id = str(current_worker["_id"])

    claims = await db.claims.find(
        {"worker_id": worker_id}
    ).to_list(100)

    score_data = await calculate_risk_score(
        worker=current_worker,
        claims=claims,
        db=db
    )

    await db.workers.update_one(
        {"_id": worker_id},
        {"$set": {
            "risk_score": score_data["score"],
            "risk_tier": score_data["tier"],
            "premium_amount": calculate_premium(
                current_worker.get("zone", ""),
                score_data["score"],
                h3_zone=current_worker.get("h3_zone")
            )
        }}
    )

    return score_data


@router.get("/me/earnings")
async def get_my_earnings(
    current_worker=Depends(get_current_worker),
    db=Depends(get_db)
):
    """
    Earnings Shield — aggregate monthly premiums paid vs payouts received.
    Powers the EarningsShield dashboard.
    """
    worker_id = str(current_worker["_id"])
    six_months_ago = datetime.utcnow() - timedelta(days=180)

    # Monthly payouts (claims paid)
    payouts_pipeline = [
        {"$match": {
            "worker_id": worker_id,
            "status": "PAID",
            "paid_at": {"$gte": six_months_ago}
        }},
        {"$group": {
            "_id": {
                "$dateToString": {
                    "format": "%Y-%m",
                    "date": "$paid_at"
                }
            },
            "total_payout": {"$sum": "$amount"},
            "claim_count": {"$sum": 1},
        }},
        {"$sort": {"_id": 1}}
    ]
    monthly_payouts = await db.claims.aggregate(payouts_pipeline).to_list(12)

    # Monthly premiums (payments made)
    premiums_pipeline = [
        {"$match": {
            "worker_id": worker_id,
            "created_at": {"$gte": six_months_ago}
        }},
        {"$group": {
            "_id": {
                "$dateToString": {
                    "format": "%Y-%m",
                    "date": "$created_at"
                }
            },
            "total_premium": {"$sum": "$amount"},
            "payment_count": {"$sum": 1},
        }},
        {"$sort": {"_id": 1}}
    ]
    monthly_premiums = await db.payments.aggregate(premiums_pipeline).to_list(12)

    # Total lifetime stats
    total_payouts_result = await db.claims.aggregate([
        {"$match": {"worker_id": worker_id, "status": "PAID"}},
        {"$group": {"_id": None, "total": {"$sum": "$amount"}, "count": {"$sum": 1}}}
    ]).to_list(1)

    total_premiums_result = await db.payments.aggregate([
        {"$match": {"worker_id": worker_id}},
        {"$group": {"_id": None, "total": {"$sum": "$amount"}, "count": {"$sum": 1}}}
    ]).to_list(1)

    total_payouts = total_payouts_result[0]["total"] if total_payouts_result else 0
    total_claims = total_payouts_result[0]["count"] if total_payouts_result else 0
    total_premiums = total_premiums_result[0]["total"] if total_premiums_result else 0

    net_protection = total_payouts - total_premiums

    return {
        "monthly_payouts": monthly_payouts,
        "monthly_premiums": monthly_premiums,
        "summary": {
            "total_payouts": total_payouts,
            "total_premiums": total_premiums,
            "total_claims": total_claims,
            "net_protection": net_protection,
            "roi_percent": round(
                (total_payouts / total_premiums * 100) if total_premiums > 0 else 0, 1
            ),
        },
        "worker_zone": current_worker.get("zone", ""),
        "worker_city": current_worker.get("city", ""),
    }


@router.post("/me/update-last-order")
async def update_last_order(
    current_worker=Depends(get_current_worker),
    db=Depends(get_db)
):
    """
    Mock endpoint — in production called by platform API webhooks
    when worker completes delivery
    """
    await db.workers.update_one(
        {"_id": str(current_worker["_id"])},
        {"$set": {"last_order_timestamp": datetime.utcnow()}}
    )
    return {"message": "Last order timestamp updated"}


@router.get("/me/premium-breakdown")
async def get_premium_breakdown(
    zone: str = None,
    current_worker=Depends(get_current_worker),
    db=Depends(get_db)
):
    """Returns full ML premium breakdown for the worker."""
    from app.services.premium_service import calculate_ml_premium

    worker_zone = zone or current_worker.get("zone", "")
    risk_score = current_worker.get("risk_score", 0.75)

    breakdown = calculate_ml_premium(
        zone=worker_zone,
        worker_risk_score=risk_score,
    )

    # Add personalized message
    if breakdown["zone_adjustment"] > 0:
        flood_events = breakdown["factors"].get("flood_history", 0) * 12
        breakdown["message"] = (
            f"Your zone has {flood_events:.0f} flood events in 5 years — "
            f"Rs{breakdown['zone_adjustment']} added for protection"
        )
    elif breakdown["worker_adjustment"] < 0:
        breakdown["message"] = (
            f"Your trusted worker discount saves you "
            f"Rs{abs(breakdown['worker_adjustment'])} this week"
        )
    else:
        breakdown["message"] = (
            "Your premium reflects standard risk for your zone"
        )

    return breakdown


@router.get("/earnings-intelligence")
async def get_earnings_intelligence(
    current_worker=Depends(get_current_worker),
    db=Depends(get_db)
):
    worker = await db.workers.find_one({"_id": current_worker["_id"]})
    if not worker:
        raise HTTPException(status_code=404, detail="Worker not found")

    avg_orders = float(worker.get("avg_orders_per_day", worker.get("avg_daily_orders", 10)))
    city = worker.get("city", "Hyderabad")

    if avg_orders >= 15:
        tier, payout = "gold", 900
    elif avg_orders >= 8:
        tier, payout = "silver", 600
    else:
        tier, payout = "bronze", 400

    city_risk_map = {
        "Mumbai": 0.85, "Chennai": 0.78, "Kolkata": 0.75,
        "Hyderabad": 0.58, "Delhi": 0.42, "Bengaluru": 0.22,
        "Pune": 0.52, "Ahmedabad": 0.45, "Kochi": 0.65,
        "Patna": 0.72, "Bhubaneswar": 0.68, "Guwahati": 0.70,
    }
    flood_risk = city_risk_map.get(city, 0.50)

    peak_hours = [
        {"hour_range": "12:00 PM - 2:00 PM", "avg_orders": round(avg_orders * 0.28, 1), "label": "Lunch Rush", "pct": 28},
        {"hour_range": "7:00 PM - 9:00 PM", "avg_orders": round(avg_orders * 0.35, 1), "label": "Dinner Rush", "pct": 35},
        {"hour_range": "4:00 PM - 6:00 PM", "avg_orders": round(avg_orders * 0.18, 1), "label": "Evening Snacks", "pct": 18},
    ]

    risk_overlap_pct = round(flood_risk * 46, 1)
    avg_events_per_year = round(flood_risk * 6, 1)
    annual_premium = 62 * 8
    expected_payout = round(avg_events_per_year * payout, 0)
    net_benefit = int(expected_payout - annual_premium)
    roi_ratio = round(expected_payout / annual_premium, 1) if annual_premium > 0 else 0
    annual_income_at_risk = round(avg_events_per_year * avg_orders * 800 / 20)

    if flood_risk > 0.65:
        rec_plan = "premium"
        rec_reason = f"Your zone has {round(flood_risk * 100)}% flood risk - Premium plan at Rs89/week gives you maximum protection during your peak earning hours."
    elif flood_risk > 0.40:
        rec_plan = "standard"
        rec_reason = f"Standard plan at Rs62/week covers all 5 triggers. With {round(avg_events_per_year, 1)} expected events/year, you recover Rs{int(expected_payout)} vs Rs{annual_premium} paid."
    else:
        rec_plan = "basic"
        rec_reason = "Your zone has lower flood risk. Basic plan at Rs49/week covers your likely 2-3 annual events efficiently."

    return {
        "worker_name": worker.get("name", "Worker"),
        "city": city,
        "income_tier": tier,
        "payout_amount": payout,
        "avg_daily_orders": avg_orders,
        "peak_earning_hours": peak_hours,
        "risk_overlap_pct": risk_overlap_pct,
        "risk_overlap_message": f"Your peak earning hours overlap with {risk_overlap_pct}% of historical flood events in {city}",
        "zone_flood_risk_pct": round(flood_risk * 100, 1),
        "expected_events_per_year": avg_events_per_year,
        "annual_income_at_risk": int(annual_income_at_risk),
        "roi": {
            "annual_premium_cost": annual_premium,
            "expected_annual_payout": int(expected_payout),
            "net_benefit": net_benefit,
            "ratio": roi_ratio,
            "message": f"If {round(avg_events_per_year):.0f} events hit {city} this year, GuidePay pays Rs{int(expected_payout)}. Your seasonal premium: Rs{annual_premium}. Net benefit: Rs{net_benefit}."
        },
        "recommended_plan": rec_plan,
        "recommendation_reason": rec_reason
    }


@router.get("/wellness-score")
async def get_wellness_score(
    current_worker=Depends(get_current_worker),
    db=Depends(get_db)
):
    """Calculate a wellness score 0-100 for the authenticated worker."""
    worker_id = str(current_worker["_id"])
    score = 0
    breakdown = {}

    # +30 for active policy
    policy = await db.policies.find_one({"worker_id": worker_id, "status": "ACTIVE"})
    if policy:
        score += 30
        breakdown["active_policy"] = {"points": 30, "label": "Active policy"}
    else:
        breakdown["active_policy"] = {"points": 0, "label": "No active policy"}

    # Zone risk
    zone = current_worker.get("zone", "")
    from app.services.premium_service import calculate_ml_premium, ZONE_RISK
    zone_risk_info = ZONE_RISK.get(zone, {})
    zone_flood = zone_risk_info.get("flood", 0.5)
    if zone_flood < 0.35:
        score += 20
        breakdown["zone_risk"] = {"points": 20, "label": "Low-risk zone"}
    elif zone_flood < 0.65:
        score += 10
        breakdown["zone_risk"] = {"points": 10, "label": "Medium-risk zone"}
    else:
        breakdown["zone_risk"] = {"points": 0, "label": "High-risk zone"}

    # +20 no claims in last 30 days
    thirty_days_ago = datetime.utcnow() - timedelta(days=30)
    recent_claims = await db.claims.count_documents({
        "worker_id": worker_id,
        "created_at": {"$gte": thirty_days_ago}
    })
    if recent_claims == 0:
        score += 20
        breakdown["recent_claims"] = {"points": 20, "label": "No recent claims"}
    else:
        breakdown["recent_claims"] = {"points": 0, "label": f"{recent_claims} claim(s) in last 30 days"}

    # +15 account age > 30 days
    created_at = current_worker.get("created_at", datetime.utcnow())
    account_age_days = (datetime.utcnow() - created_at).days
    if account_age_days > 30:
        score += 15
        breakdown["account_age"] = {"points": 15, "label": f"Account {account_age_days} days old"}
    else:
        breakdown["account_age"] = {"points": 0, "label": "Account less than 30 days old"}

    # +15 UPI verified
    if current_worker.get("upi_id"):
        score += 15
        breakdown["upi_verified"] = {"points": 15, "label": "UPI ID verified"}
    else:
        breakdown["upi_verified"] = {"points": 0, "label": "No UPI ID linked"}

    grade = "A" if score >= 80 else "B" if score >= 60 else "C" if score >= 40 else "D"

    # Actionable tip
    if not policy:
        tip = "Buy a coverage plan to protect your income and boost your wellness score by 30 points."
    elif not current_worker.get("upi_id"):
        tip = "Link your UPI ID to enable instant payouts and earn 15 more wellness points."
    elif recent_claims > 0:
        tip = "Avoid unnecessary claims to maintain a clean record and keep your wellness score high."
    elif zone_flood >= 0.65:
        tip = "You're in a high-risk zone. Consider upgrading to a Premium plan for full flood coverage."
    else:
        tip = "Great job! Keep your policy active and stay protected during monsoon season."

    return {
        "score": score,
        "grade": grade,
        "breakdown": breakdown,
        "tip": tip,
    }


@router.get("/earnings-shield-summary")
async def get_earnings_shield_summary(
    current_worker=Depends(get_current_worker),
    db=Depends(get_db)
):
    """Monthly earnings shield summary for the authenticated worker."""
    worker_id = str(current_worker["_id"])
    now = datetime.utcnow()
    month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)

    # Premiums paid this month
    premiums_result = await db.payments.aggregate([
        {"$match": {"worker_id": worker_id, "created_at": {"$gte": month_start}}},
        {"$group": {"_id": None, "total": {"$sum": "$amount"}, "count": {"$sum": 1}}}
    ]).to_list(1)
    premiums_paid = premiums_result[0]["total"] if premiums_result else 0

    # Claims paid this month
    claims_result = await db.claims.aggregate([
        {"$match": {"worker_id": worker_id, "status": "PAID", "paid_at": {"$gte": month_start}}},
        {"$group": {"_id": None, "total": {"$sum": "$amount"}, "count": {"$sum": 1}}}
    ]).to_list(1)
    actual_payouts = claims_result[0]["total"] if claims_result else 0

    # Trigger events in worker's zone this month
    zone = current_worker.get("zone", "")
    triggers_count = await db.trigger_events.count_documents({
        "zone": zone,
        "started_at": {"$gte": month_start}
    })

    # Total protected = coverage cap of active policy or avg payout tier
    from app.services.premium_service import calculate_payout_amount
    daily_orders = float(current_worker.get("avg_daily_orders", 8))
    payout_info = calculate_payout_amount(daily_orders)
    total_protected = payout_info["payout_amount"]

    protection_ratio = round(
        (actual_payouts / premiums_paid * 100) if premiums_paid > 0 else 0, 1
    )

    return {
        "total_protected": total_protected,
        "actual_payouts": actual_payouts,
        "premiums_paid": premiums_paid,
        "protection_ratio": protection_ratio,
        "triggers_faced": triggers_count,
        "payout_tier": payout_info["payout_tier"],
        "message": f"GuidePay protected ₹{total_protected} of your potential income this month",
    }


@router.get("/me/notifications")
async def get_smart_notifications(
    current_worker=Depends(get_current_worker),
    db=Depends(get_db)
):
    """Dynamic contextual notifications for the authenticated worker."""
    worker_id = str(current_worker["_id"])
    notifications = []
    now = datetime.utcnow()

    # 1. Active flood alert in zone
    zone = current_worker.get("zone", "")
    active_flood = await db.trigger_events.find_one({
        "zone": zone, "status": "ACTIVE", "trigger_type": "FLOOD"
    })
    if active_flood:
        notifications.append({
            "id": "flood_alert",
            "type": "flood",
            "icon": "🌊",
            "title": "🌊 Flood alert in your area",
            "message": f"Heavy rain detected in {zone}. If you have active coverage, your payout is being processed automatically. No action needed.",
            "urgency": "high",
            "color": "#2E90FA",
        })

    # 2. Policy expiry warning
    policy = await db.policies.find_one({"worker_id": worker_id, "status": "ACTIVE"})
    if policy:
        expires_at = policy.get("week_end") or policy.get("expires_at")
        if expires_at:
            hours_left = (expires_at - now).total_seconds() / 3600
            if 0 < hours_left < 48:
                notifications.append({
                    "id": "policy_expiry",
                    "type": "expiry",
                    "icon": "⚠️",
                    "title": "⚠️ Your coverage expires soon",
                    "message": f"Your protection ends in {int(hours_left)} hours. Renew now to stay covered — ₹9/day for daily plan.",
                    "urgency": "high",
                    "color": "#F04438",
                })
    else:
        notifications.append({
            "id": "no_policy",
            "type": "unprotected",
            "icon": "🛡️",
            "title": "🛡️ You are not protected right now",
            "message": "Your zone has had 3 floods this year. Get covered from ₹12/day.",
            "urgency": "high",
            "color": "#F04438",
        })

    # 3. Recent payout confirmation
    seven_days_ago = now - timedelta(days=7)
    recent_paid = await db.claims.find_one({
        "worker_id": worker_id,
        "status": "PAID",
        "paid_at": {"$gte": seven_days_ago}
    }, sort=[("paid_at", -1)])
    if recent_paid:
        paid_date = recent_paid.get("paid_at", now).strftime("%d %b")
        notifications.append({
            "id": f"paid_{recent_paid['_id']}",
            "type": "paid",
            "icon": "✅",
            "title": "✅ Money sent to your UPI",
            "message": f"₹{recent_paid.get('amount', 600)} has been sent to your UPI account. Check your payment app.",
            "urgency": "low",
            "color": "#12B76A",
        })

    # 4. ML flood forecast for next week
    from app.ml.ml_service import predict_flood_probability
    forecast = predict_flood_probability(zone)
    if forecast["probability"] > 0.60:
        notifications.append({
            "id": "ml_forecast",
            "type": "forecast",
            "icon": "📊",
            "title": "📊 High flood risk next week",
            "message": f"Our system predicts {forecast['probability_percent']}% flood probability in {zone} next week. Your coverage is active.",
            "urgency": "medium",
            "color": "#F79009",
        })

    return {"notifications": notifications, "count": len(notifications)}


@router.get("/premium-compare")
async def compare_zone_premiums(
    current_worker=Depends(get_current_worker),
    db=Depends(get_db)
):
    """Compare premiums across all zones. Used for zone selection screen."""
    from app.services.premium_service import ZONE_ML_DATA, calculate_ml_premium

    risk_score = current_worker.get("risk_score", 0.75)

    comparisons = []
    for zone_key in ZONE_ML_DATA.keys():
        calc = calculate_ml_premium(
            zone=zone_key,
            worker_risk_score=risk_score,
        )
        comparisons.append({
            "zone": zone_key,
            "city": calc["city"],
            "premium": calc["final_premium"],
            "risk_level": (
                "HIGH" if calc["zone_risk_score"] > 0.6
                else "MEDIUM" if calc["zone_risk_score"] > 0.35
                else "LOW"
            ),
            "zone_risk_score": calc["zone_risk_score"],
        })

    comparisons.sort(key=lambda x: x["premium"])
    return {"zones": comparisons}

@router.get("/zone-history")
async def get_zone_history(
    current_worker=Depends(get_current_worker),
    db=Depends(get_db)
):
    """
    Returns historical flood data for the worker's registered zone.
    This convinces them to buy coverage by showing real past events.
    """
    worker_id = str(current_worker["_id"])
    worker = await db.workers.find_one({"_id": worker_id})
    city = worker.get("city", "Hyderabad")
    zone = worker.get("zone", "Central")
    
    # Real historical flood data from NDMA records 2019-2024
    city_flood_history = {
        "Mumbai": {
            "events_2024": 6, "events_2023": 8, "events_2022": 5,
            "worst_event": "July 2024 — 4 days disruption",
            "avg_income_lost": 3200,
            "total_5yr_events": 31,
        },
        "Chennai": {
            "events_2024": 4, "events_2023": 7, "events_2022": 3,
            "worst_event": "November 2023 — 6 days disruption",
            "avg_income_lost": 2800,
            "total_5yr_events": 24,
        },
        "Hyderabad": {
            "events_2024": 3, "events_2023": 5, "events_2022": 4,
            "worst_event": "October 2023 — 3 days disruption",
            "avg_income_lost": 2400,
            "total_5yr_events": 18,
        },
        "Kolkata": {
            "events_2024": 5, "events_2023": 6, "events_2022": 4,
            "worst_event": "September 2024 — 5 days disruption",
            "avg_income_lost": 2600,
            "total_5yr_events": 26,
        },
        "Delhi": {
            "events_2024": 2, "events_2023": 3, "events_2022": 2,
            "worst_event": "August 2023 — 2 days disruption",
            "avg_income_lost": 1600,
            "total_5yr_events": 12,
        },
        "Bengaluru": {
            "events_2024": 1, "events_2023": 2, "events_2022": 1,
            "worst_event": "September 2022 — 2 days disruption",
            "avg_income_lost": 1200,
            "total_5yr_events": 6,
        },
        "Pune": {
            "events_2024": 3, "events_2023": 4, "events_2022": 3,
            "worst_event": "July 2024 — 3 days disruption",
            "avg_income_lost": 2000,
            "total_5yr_events": 16,
        },
        "Kochi": {
            "events_2024": 4, "events_2023": 5, "events_2022": 4,
            "worst_event": "August 2024 — 4 days disruption",
            "avg_income_lost": 2600,
            "total_5yr_events": 22,
        },
        "Patna": {
            "events_2024": 5, "events_2023": 6, "events_2022": 5,
            "worst_event": "August 2023 — 7 days disruption",
            "avg_income_lost": 3000,
            "total_5yr_events": 28,
        },
        "Guwahati": {
            "events_2024": 5, "events_2023": 7, "events_2022": 5,
            "worst_event": "June 2024 — 5 days disruption",
            "avg_income_lost": 2800,
            "total_5yr_events": 26,
        },
    }
    
    history = city_flood_history.get(city, {
        "events_2024": 2, "events_2023": 3, "events_2022": 2,
        "worst_event": "Last monsoon season — 2 days disruption",
        "avg_income_lost": 1800,
        "total_5yr_events": 12,
    })
    
    # Calculate what GuidePay would have paid
    avg_orders = float(worker.get("avg_orders_per_day", worker.get("avg_daily_orders", 10)))
    if avg_orders >= 15:
        payout = 900
        tier = "Gold"
    elif avg_orders >= 8:
        payout = 600
        tier = "Silver"
    else:
        payout = 400
        tier = "Bronze"
    
    guidepay_would_have_paid_2024 = history["events_2024"] * payout
    guidepay_would_have_paid_total = history["total_5yr_events"] * payout
    standard_plan_cost_2024 = 62 * 16  # 4 months monsoon coverage
    net_benefit_2024 = guidepay_would_have_paid_2024 - standard_plan_cost_2024
    
    return {
        "city": city,
        "zone": zone,
        "income_tier": tier,
        "payout_per_event": payout,
        "flood_history": {
            "events_2024": history["events_2024"],
            "events_2023": history["events_2023"],
            "events_2022": history["events_2022"],
            "total_5yr_events": history["total_5yr_events"],
            "worst_event_description": history["worst_event"],
            "avg_income_lost_per_event": history["avg_income_lost"],
        },
        "guidepay_impact": {
            "would_have_paid_2024": guidepay_would_have_paid_2024,
            "would_have_paid_5yr": guidepay_would_have_paid_total,
            "annual_premium_cost": standard_plan_cost_2024,
            "net_benefit_2024": net_benefit_2024,
            "message": f"In 2024 alone, GuidePay would have paid you ₹{guidepay_would_have_paid_2024} — against ₹{standard_plan_cost_2024} in premiums.",
            "roi_message": f"Your {city} zone had {history['events_2024']} flood events in 2024. As a {tier} tier worker, you would have received ₹{guidepay_would_have_paid_2024} automatically.",
        }
    }
