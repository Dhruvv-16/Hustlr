from fastapi import APIRouter, Depends, HTTPException

from app.database import get_db
from app.routes.auth import get_current_worker
from app.services.notification_service import (
    list_worker_notifications,
    unread_notification_count,
)
from app.utils.formatters import serialize_doc

router = APIRouter()


def _ensure_db(db):
    if db is None:
        raise HTTPException(status_code=503, detail="Database unavailable")
    return db


@router.get("/me")
async def get_my_notifications(
    current_worker=Depends(get_current_worker),
    db=Depends(get_db),
):
    db = _ensure_db(db)
    worker_id = str(current_worker["_id"])
    items = await list_worker_notifications(db, worker_id, limit=50)
    unread = await unread_notification_count(db, worker_id)
    return {
        "notifications": [serialize_doc(item) for item in items],
        "unread_count": unread,
    }


@router.patch("/me/{notification_id}/read")
async def mark_notification_read(
    notification_id: str,
    current_worker=Depends(get_current_worker),
    db=Depends(get_db),
):
    db = _ensure_db(db)
    worker_id = str(current_worker["_id"])
    result = await db.notifications.update_one(
        {"_id": notification_id, "worker_id": worker_id},
        {"$set": {"read": True}},
    )
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="Notification not found")
    return {"success": True, "notification_id": notification_id}


@router.patch("/me/read-all")
async def mark_all_notifications_read(
    current_worker=Depends(get_current_worker),
    db=Depends(get_db),
):
    db = _ensure_db(db)
    worker_id = str(current_worker["_id"])
    await db.notifications.update_many(
        {"worker_id": worker_id, "read": False},
        {"$set": {"read": True}},
    )
    return {"success": True}
