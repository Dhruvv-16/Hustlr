import asyncio
import os
from datetime import datetime, timedelta

import motor.motor_asyncio
from bson import ObjectId
from dotenv import load_dotenv

load_dotenv()


WORKERS = [
    {
        "phone": "9999900000",
        "name": "Ravi Kumar",
        "city": "Hyderabad",
        "zone": "kondapur-hyderabad",
        "avg_orders_per_day": 11,
        "income_tier": "silver",
        "payout_amount": 600,
        "upi_id": "ravi@upi",
        "account_age_days": 180,
        "risk_score": 0.15,
        "created_at": datetime.utcnow() - timedelta(days=180),
    },
    {
        "phone": "9999900001",
        "name": "Meera Reddy",
        "city": "Mumbai",
        "zone": "kurla-mumbai",
        "avg_orders_per_day": 18,
        "income_tier": "gold",
        "payout_amount": 900,
        "upi_id": "meera@upi",
        "account_age_days": 240,
        "risk_score": 0.08,
        "created_at": datetime.utcnow() - timedelta(days=240),
    },
    {
        "phone": "9999900002",
        "name": "Suresh Das",
        "city": "Chennai",
        "zone": "tnagar-chennai",
        "avg_orders_per_day": 5,
        "income_tier": "bronze",
        "payout_amount": 400,
        "upi_id": "suresh@upi",
        "account_age_days": 30,
        "risk_score": 0.25,
        "created_at": datetime.utcnow() - timedelta(days=30),
    },
]


async def seed():
    mongodb_url = os.getenv("MONGODB_URL")
    if not mongodb_url:
        raise RuntimeError("MONGODB_URL is not set")

    client = motor.motor_asyncio.AsyncIOMotorClient(mongodb_url)
    db = client.guidepay
    now = datetime.utcnow()

    print("Cleaning up old test data...")
    phones_to_keep = [w["phone"] for w in WORKERS]
    
    # 1. Delete all trigger events to start fresh for demo
    await db.trigger_events.delete_many({})
    
    # 2. Delete test/dummy workers not in our core demo list
    await db.workers.delete_many({"phone": {"$nin": phones_to_keep}})
    
    # 3. Get remaining valid worker IDs
    valid_workers = await db.workers.find({}, {"_id": 1}).to_list(None)
    valid_ids = [str(w["_id"]) for w in valid_workers]
    
    # 4. Clean up orphaned claims, policies, and payments
    await db.claims.delete_many({"worker_id": {"$nin": valid_ids}})
    await db.policies.delete_many({"worker_id": {"$nin": valid_ids}})
    await db.payments.delete_many({"worker_id": {"$nin": valid_ids}})
    
    print("Cleanup complete. Seeding demo workers...")

    for worker in WORKERS:
        worker_doc = {
            "_id": worker["phone"],
            "firebase_uid": f"demo-{worker['phone']}",
            "name": worker["name"],
            "phone": worker["phone"],
            "email": f"{worker['phone']}@guidepay.demo",
            "city": worker["city"],
            "zone": worker["zone"],
            "upi_id": worker["upi_id"],
            "avg_orders_per_day": worker["avg_orders_per_day"],
            "avg_daily_orders": worker["avg_orders_per_day"],
            "avg_daily_income": worker["avg_orders_per_day"] * 80,
            "income_tier": worker["income_tier"],
            "payout_amount": worker["payout_amount"],
            "account_age_days": worker["account_age_days"],
            "risk_score": worker["risk_score"],
            "risk_tier": "LOW" if worker["risk_score"] <= 0.25 else "MEDIUM",
            "premium_amount": 62.0,
            "platforms": ["swiggy", "zepto"],
            "is_active": True,
            "created_at": worker["created_at"],
            "updated_at": now,
            "total_claims": 0,
            "total_payouts": 0.0,
        }

        existing = await db.workers.find_one({"phone": worker["phone"]})
        if existing:
            await db.workers.update_one({"phone": worker["phone"]}, {"$set": worker_doc})
            worker_id = existing["_id"]
            print(f"Updated: {worker['name']} ({worker['income_tier']} tier -> Rs{worker['payout_amount']})")
        else:
            await db.workers.insert_one(worker_doc)
            worker_id = worker_doc["_id"]
            print(f"Created: {worker['name']} ({worker['income_tier']} tier -> Rs{worker['payout_amount']})")

        policy_doc = {
            "_id": str(ObjectId()),
            "worker_id": str(worker_id),
            "plan_id": "standard",
            "plan_name": "Standard Shield",
            "plan_type": "standard",
            "weekly_premium": 62.0,
            "coverage_cap": float(worker["payout_amount"] * 4),
            "status": "ACTIVE",
            "auto_payout": True,
            "payout_tier": worker["income_tier"],
            "payment_id": f"pay_demo_{worker['phone'][-4:]}",
            "order_id": f"order_demo_{worker['phone'][-4:]}",
            "week_start": now - timedelta(days=1),
            "week_end": now + timedelta(days=6),
            "expires_at": now + timedelta(days=6),
            "created_at": now - timedelta(days=1),
            "updated_at": now,
        }

        await db.policies.delete_many({"worker_id": str(worker_id)})
        await db.payments.delete_many({"worker_id": str(worker_id)})
        await db.claims.delete_many({"worker_id": str(worker_id)})
        await db.policies.insert_one(policy_doc)
        await db.payments.insert_one(
            {
                "_id": str(ObjectId()),
                "worker_id": str(worker_id),
                "policy_id": policy_doc["_id"],
                "razorpay_payment_id": f"pay_seed_{worker['phone'][-4:]}",
                "razorpay_order_id": f"order_seed_{worker['phone'][-4:]}",
                "amount": 62.0,
                "currency": "INR",
                "status": "captured",
                "created_at": now - timedelta(days=1),
            }
        )

    print("\nDemo data seeded. Test:")
    print("  9999900000 -> Ravi -> Silver -> Rs600")
    print("  9999900001 -> Meera -> Gold -> Rs900")
    print("  9999900002 -> Suresh -> Bronze -> Rs400")

    client.close()


if __name__ == "__main__":
    asyncio.run(seed())
