import logging
from datetime import datetime
from bson import ObjectId

logger = logging.getLogger(__name__)


async def create_notification(
    db,
    worker_id: str,
    notif_type: str,
    title: str,
    body: str,
    link: str | None = None,
    meta: dict | None = None,
):
    """Persist a worker notification in MongoDB."""
    doc = {
        "_id": str(ObjectId()),
        "worker_id": worker_id,
        "type": notif_type,
        "title": title,
        "body": body,
        "link": link,
        "meta": meta or {},
        "read": False,
        "created_at": datetime.utcnow(),
    }
    await db.notifications.insert_one(doc)
    return doc


async def list_worker_notifications(db, worker_id: str, limit: int = 50):
    items = await db.notifications.find(
        {"worker_id": worker_id}
    ).sort("created_at", -1).limit(limit).to_list(limit)
    return items


async def unread_notification_count(db, worker_id: str) -> int:
    return await db.notifications.count_documents({
        "worker_id": worker_id,
        "read": False,
    })


async def send_claim_notification(worker: dict, claim: dict, status: str):
    """Send push notification for claim status update"""
    message = {
        "AUTO_APPROVED": f"✅ Your claim of ₹{claim['amount']} has been approved! Payment is being processed.",
        "PAID": f"💰 ₹{claim['amount']} has been credited to your UPI account.",
        "REJECTED": f"❌ Your claim could not be approved. Contact support for details.",
        "MANUAL_REVIEW": f"⏳ Your claim of ₹{claim['amount']} is under review.",
    }.get(status, "Your claim status has been updated.")

    if worker.get("_id"):
        await create_notification(
            db=claim.get("_db"),
            worker_id=str(worker["_id"]),
            notif_type="CLAIM",
            title=f"Claim status: {status.replace('_', ' ').title()}",
            body=message,
            link="/claims",
            meta={"claim_id": claim.get("_id"), "status": status},
        ) if claim.get("_db") is not None else None

    # In production, integrate Firebase Cloud Messaging here
    logger.info(
        f"NOTIFICATION to {worker.get('phone')}: {message}"
    )


async def send_trigger_alert(workers: list, trigger_event: dict):
    """Send push notification when a trigger event is detected"""
    city = trigger_event.get("city", "your city")
    trigger_type = trigger_event.get("trigger_type", "event")
    amount = trigger_event.get("total_exposure", 0) / max(len(workers), 1)

    message = (
        f"⚠️ {trigger_type} alert in {city}! "
        f"Your policy covers you for up to ₹{amount:.0f}. "
        f"Claim will be processed automatically."
    )

    logger.info(
        f"TRIGGER ALERT to {len(workers)} workers in {city}: {message}"
    )
