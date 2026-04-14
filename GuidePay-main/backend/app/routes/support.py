from datetime import datetime
from typing import Literal, Optional

from bson import ObjectId
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel

from app.database import get_db
from app.routes.auth import get_current_worker
from app.services.notification_service import create_notification
from app.utils.formatters import serialize_doc

router = APIRouter()


class CreateSupportTicketRequest(BaseModel):
    category: str
    subject: str
    body: str


class SupportMessageRequest(BaseModel):
    text: str


class UpdateSupportStatusRequest(BaseModel):
    status: Literal["open", "pending", "resolved"]


def _ensure_db(db):
    if db is None:
        raise HTTPException(status_code=503, detail="Database unavailable")
    return db


async def _get_ticket_or_404(db, ticket_id: str):
    ticket = await db.support_tickets.find_one({"_id": ticket_id})
    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket not found")
    return ticket


@router.get("/my")
async def get_my_support_tickets(
    current_worker=Depends(get_current_worker),
    db=Depends(get_db),
):
    db = _ensure_db(db)
    worker_id = str(current_worker["_id"])
    tickets = await db.support_tickets.find(
        {"worker_id": worker_id}
    ).sort("updated_at", -1).to_list(100)
    return {"tickets": [serialize_doc(ticket) for ticket in tickets]}


@router.post("/my")
async def create_support_ticket(
    request: CreateSupportTicketRequest,
    current_worker=Depends(get_current_worker),
    db=Depends(get_db),
):
    db = _ensure_db(db)
    now = datetime.utcnow()
    worker_id = str(current_worker["_id"])
    worker_name = current_worker.get("name") or "Delivery Partner"

    first_message = {
        "id": str(ObjectId()),
        "from": "worker",
        "sender_name": worker_name,
        "text": request.body.strip(),
        "time": now,
    }
    ticket = {
        "_id": str(ObjectId()),
        "worker_id": worker_id,
        "worker_name": worker_name,
        "category": request.category.strip(),
        "subject": request.subject.strip(),
        "status": "open",
        "created_at": now,
        "updated_at": now,
        "last_message_at": now,
        "messages": [first_message],
    }

    await db.support_tickets.insert_one(ticket)
    await create_notification(
        db=db,
        worker_id=worker_id,
        notif_type="SUPPORT",
        title="Support ticket created",
        body=f'Your ticket "{ticket["subject"]}" was submitted successfully.',
        link="/support",
        meta={"ticket_id": ticket["_id"], "status": "open"},
    )
    return serialize_doc(ticket)


@router.get("/my/{ticket_id}")
async def get_my_support_ticket(
    ticket_id: str,
    current_worker=Depends(get_current_worker),
    db=Depends(get_db),
):
    db = _ensure_db(db)
    ticket = await _get_ticket_or_404(db, ticket_id)
    if ticket["worker_id"] != str(current_worker["_id"]):
        raise HTTPException(status_code=403, detail="Forbidden")
    return serialize_doc(ticket)


@router.post("/my/{ticket_id}/messages")
async def add_worker_support_message(
    ticket_id: str,
    request: SupportMessageRequest,
    current_worker=Depends(get_current_worker),
    db=Depends(get_db),
):
    db = _ensure_db(db)
    ticket = await _get_ticket_or_404(db, ticket_id)
    if ticket["worker_id"] != str(current_worker["_id"]):
        raise HTTPException(status_code=403, detail="Forbidden")

    message = {
        "id": str(ObjectId()),
        "from": "worker",
        "sender_name": current_worker.get("name") or "Delivery Partner",
        "text": request.text.strip(),
        "time": datetime.utcnow(),
    }
    await db.support_tickets.update_one(
        {"_id": ticket_id},
        {
            "$push": {"messages": message},
            "$set": {
                "status": "open",
                "updated_at": message["time"],
                "last_message_at": message["time"],
            },
        },
    )
    updated = await _get_ticket_or_404(db, ticket_id)
    return serialize_doc(updated)


@router.get("/admin/tickets")
async def get_admin_support_tickets(
    status: Optional[str] = Query(default="all"),
    db=Depends(get_db),
):
    db = _ensure_db(db)
    query = {}
    if status and status != "all":
        query["status"] = status
    tickets = await db.support_tickets.find(query).sort("updated_at", -1).to_list(200)
    return {"tickets": [serialize_doc(ticket) for ticket in tickets]}


@router.post("/admin/tickets/{ticket_id}/messages")
async def add_admin_support_message(
    ticket_id: str,
    request: SupportMessageRequest,
    db=Depends(get_db),
):
    db = _ensure_db(db)
    ticket = await _get_ticket_or_404(db, ticket_id)
    now = datetime.utcnow()
    message = {
        "id": str(ObjectId()),
        "from": "support",
        "sender_name": "GuidePay Support",
        "text": request.text.strip(),
        "time": now,
    }
    await db.support_tickets.update_one(
        {"_id": ticket_id},
        {
            "$push": {"messages": message},
            "$set": {"status": "pending", "updated_at": now, "last_message_at": now},
        },
    )
    await create_notification(
        db=db,
        worker_id=ticket["worker_id"],
        notif_type="SUPPORT",
        title="New support reply",
        body=request.text.strip()[:120],
        link="/support",
        meta={"ticket_id": ticket_id, "status": "pending"},
    )
    updated = await _get_ticket_or_404(db, ticket_id)
    return serialize_doc(updated)


@router.patch("/admin/tickets/{ticket_id}/status")
async def update_admin_support_status(
    ticket_id: str,
    request: UpdateSupportStatusRequest,
    db=Depends(get_db),
):
    db = _ensure_db(db)
    ticket = await _get_ticket_or_404(db, ticket_id)
    now = datetime.utcnow()
    await db.support_tickets.update_one(
        {"_id": ticket_id},
        {"$set": {"status": request.status, "updated_at": now}},
    )
    await create_notification(
        db=db,
        worker_id=ticket["worker_id"],
        notif_type="SUPPORT_STATUS",
        title="Support ticket updated",
        body=f'{ticket["subject"]} is now marked as {request.status}.',
        link="/support",
        meta={"ticket_id": ticket_id, "status": request.status},
    )
    updated = await _get_ticket_or_404(db, ticket_id)
    return serialize_doc(updated)
