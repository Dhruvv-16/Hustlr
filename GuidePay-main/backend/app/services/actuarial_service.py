from datetime import datetime, timedelta


DEFAULT_TRIGGER_PAYOUT = {
    "FLOOD": 600.0,
    "OUTAGE": 450.0,
    "CURFEW": 600.0,
    "AIR_QUALITY": 300.0,
    "HEAT_WAVE": 300.0,
    "FESTIVAL_DISRUPTION": 240.0,
}


async def actuarial_summary(db) -> dict:
    total_premiums = await _sum_collection(db.payments, {})
    total_payouts = await _sum_collection(db.claims, {"status": "PAID"}, field="amount")
    active_exposure = await _sum_collection(
        db.trigger_events,
        {"status": "ACTIVE"},
        field="total_exposure",
    )
    return {
        "total_premiums": total_premiums,
        "total_payouts": total_payouts,
        "loss_ratio": round(total_payouts / total_premiums, 4) if total_premiums else 0.0,
        "active_exposure": active_exposure,
        "generated_at": datetime.utcnow(),
    }


async def city_exposure(db) -> dict:
    worker_pipeline = [
        {"$match": {"is_active": True}},
        {"$group": {"_id": "$city", "workers": {"$sum": 1}}},
    ]
    trigger_pipeline = [
        {"$group": {
            "_id": {"city": "$city", "trigger_type": "$trigger_type"},
            "events": {"$sum": 1},
            "total_exposure": {"$sum": "$total_exposure"},
        }},
    ]

    workers = await db.workers.aggregate(worker_pipeline).to_list(100)
    triggers = await db.trigger_events.aggregate(trigger_pipeline).to_list(100)

    by_city: dict[str, dict] = {}
    for row in workers:
        city = row["_id"] or "Unknown"
        by_city[city] = {
            "city": city,
            "workers": row["workers"],
            "triggers": [],
            "total_exposure": 0.0,
        }

    for row in triggers:
        city = row["_id"].get("city") or "Unknown"
        by_city.setdefault(city, {
            "city": city,
            "workers": 0,
            "triggers": [],
            "total_exposure": 0.0,
        })
        trigger_row = {
            "trigger_type": row["_id"].get("trigger_type"),
            "events": row["events"],
            "total_exposure": round(row["total_exposure"], 2),
        }
        by_city[city]["triggers"].append(trigger_row)
        by_city[city]["total_exposure"] += row["total_exposure"]

    cities = sorted(by_city.values(), key=lambda item: item["total_exposure"], reverse=True)
    return {
        "cities": [
            {**city, "total_exposure": round(city["total_exposure"], 2)}
            for city in cities
        ],
        "generated_at": datetime.utcnow(),
    }


async def reserve_summary(db) -> dict:
    summary = await actuarial_summary(db)
    reserve_required = round(summary["active_exposure"] * 1.15, 2)
    reserve_gap = round(max(0.0, reserve_required - summary["total_premiums"]), 2)
    return {
        **summary,
        "reserve_required": reserve_required,
        "current_buffer": round(summary["total_premiums"] - summary["total_payouts"], 2),
        "reserve_gap": reserve_gap,
    }


async def premium_payout_trend(db, days: int = 30) -> list:
    since = datetime.utcnow() - timedelta(days=days)
    premiums = await db.payments.aggregate([
        {"$match": {"created_at": {"$gte": since}}},
        {"$group": {
            "_id": {"$dateToString": {"format": "%Y-%m-%d", "date": "$created_at"}},
            "premiums": {"$sum": "$amount"},
        }},
        {"$sort": {"_id": 1}},
    ]).to_list(days)
    payouts = await db.claims.aggregate([
        {"$match": {"status": "PAID", "paid_at": {"$gte": since}}},
        {"$group": {
            "_id": {"$dateToString": {"format": "%Y-%m-%d", "date": "$paid_at"}},
            "payouts": {"$sum": "$amount"},
        }},
        {"$sort": {"_id": 1}},
    ]).to_list(days)

    payout_map = {row["_id"]: row["payouts"] for row in payouts}
    trend = []
    for row in premiums:
        trend.append({
            "date": row["_id"],
            "premiums": round(row["premiums"], 2),
            "payouts": round(payout_map.get(row["_id"], 0.0), 2),
        })
    return trend


def simulate_scenario(
    city: str,
    trigger_type: str,
    num_workers: int,
    days: int,
    payout_amount: float,
    weekly_premium: float = 58.0,
) -> dict:
    total_premium_collected = round(num_workers * weekly_premium * max(days / 7, 1), 2)
    payout_expected = round(num_workers * payout_amount, 2)
    loss_ratio = round(payout_expected / total_premium_collected, 4) if total_premium_collected else 0.0
    reserve_requirement = round(payout_expected * 1.15, 2)
    risk_level = (
        "LOW" if loss_ratio < 0.65 else
        "MEDIUM" if loss_ratio <= 0.85 else
        "HIGH"
    )
    return {
        "city": city,
        "trigger_type": trigger_type,
        "num_workers": num_workers,
        "days": days,
        "payout_amount": payout_amount,
        "premium_collected": total_premium_collected,
        "payout_expected": payout_expected,
        "loss_ratio": loss_ratio,
        "reserve_requirement": reserve_requirement,
        "risk_level": risk_level,
    }


def stress_test_scenarios() -> list:
    return [
        simulate_scenario("Mumbai", "FLOOD", 120, 7, DEFAULT_TRIGGER_PAYOUT["FLOOD"]),
        simulate_scenario("Hyderabad", "MULTI_TRIGGER_WEEK", 90, 7, 1050.0),
        simulate_scenario("Multi-city", "CASCADE_EVENT", 240, 3, 600.0),
    ]


async def _sum_collection(collection, query: dict, field: str = "amount") -> float:
    rows = await collection.aggregate([
        {"$match": query},
        {"$group": {"_id": None, "total": {"$sum": f"${field}"}}},
    ]).to_list(1)
    return round(rows[0]["total"], 2) if rows else 0.0
