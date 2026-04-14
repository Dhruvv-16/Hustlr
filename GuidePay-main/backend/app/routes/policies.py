import io
import logging
from datetime import datetime, timedelta

from bson import ObjectId
from bson.errors import InvalidId
from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import StreamingResponse
from fpdf import FPDF

from app.core.constants import PAYOUT_TIERS, PLANS
from app.database import get_db
from app.routes.auth import get_current_worker
from app.utils.formatters import serialize_doc

router = APIRouter()
logger = logging.getLogger(__name__)

DAILY_PLAN = {
    "id": "daily",
    "name": PLANS["daily"]["name"],
    "plan_type": "daily",
    "premium": PLANS["daily"]["price_inr"],
    "coverage_hours": PLANS["daily"]["coverage_hours"],
    "description": PLANS["daily"]["display_price"],
    "badge": PLANS["daily"]["badge"],
}


def _id_candidates(raw_id: str) -> list:
    candidates = [raw_id]
    try:
        candidates.append(ObjectId(raw_id))
    except (InvalidId, TypeError):
        pass
    return candidates


def check_daily_policy_expiry(policy: dict) -> bool:
    """Returns True if a daily policy is still valid."""
    if policy.get("plan_type") != "daily":
        return True
    expires_at = policy.get("expires_at")
    if not expires_at:
        return False
    return datetime.utcnow() < expires_at


@router.get("/my/active")
async def get_active_policy(
    current_worker=Depends(get_current_worker),
    db=Depends(get_db)
):
    """Get current worker's active policy."""
    worker_id = str(current_worker["_id"])
    policy = await db.policies.find_one({"worker_id": worker_id, "status": "ACTIVE"})

    if not policy:
        return {"policy": None, "message": "No active policy"}

    if policy.get("plan_type") == "daily" and not check_daily_policy_expiry(policy):
        return {"policy": None, "message": "Daily policy expired"}

    return serialize_doc(policy)


@router.get("/my")
async def get_my_policies(
    current_worker=Depends(get_current_worker),
    db=Depends(get_db)
):
    """Get all policies for current worker"""
    worker_id = str(current_worker["_id"])
    policies = await db.policies.find({"worker_id": worker_id}).sort("created_at", -1).to_list(50)
    return {"policies": [serialize_doc(p) for p in policies], "total": len(policies)}


@router.get("/{policy_id}")
async def get_policy(
    policy_id: str,
    current_worker=Depends(get_current_worker),
    db=Depends(get_db)
):
    """Get a specific policy"""
    worker_id = str(current_worker["_id"])
    policy = await db.policies.find_one({"_id": {"$in": _id_candidates(policy_id)}})
    if not policy:
        raise HTTPException(status_code=404, detail="Policy not found")

    if str(policy["worker_id"]) != worker_id:
        raise HTTPException(status_code=403, detail="Not authorized")

    return serialize_doc(policy)


@router.get("/{policy_id}/certificate")
async def download_certificate(
    policy_id: str,
    current_worker=Depends(get_current_worker),
    db=Depends(get_db)
):
    """Generate a downloadable PDF protection certificate for policy."""
    worker_id = str(current_worker["_id"])
    policy = await db.policies.find_one({"_id": {"$in": _id_candidates(policy_id)}})
    if not policy:
        raise HTTPException(status_code=404, detail="Policy not found")

    if str(policy["worker_id"]) != worker_id and current_worker.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Not authorized")

    worker = await db.workers.find_one({"_id": {"$in": _id_candidates(str(policy["worker_id"]))}})
    if not worker:
        worker = current_worker

    payout_tier = str(policy.get("payout_tier", "")).lower()
    if payout_tier not in PAYOUT_TIERS:
        avg_orders = float(worker.get("avg_orders_per_day", worker.get("avg_daily_orders", 10)))
        payout_tier = "gold" if avg_orders >= 15 else "silver" if avg_orders >= 8 else "bronze"
    payout_amount = PAYOUT_TIERS[payout_tier]["payout_inr"]

    created_at = policy.get("created_at") or policy.get("week_start") or datetime.utcnow()
    expires_at = policy.get("expires_at") or policy.get("week_end") or (created_at + timedelta(days=7))
    plan_type = policy.get("plan_type") or policy.get("plan_id", "standard")
    if plan_type not in PLANS:
        plan_type = "standard"

    triggers = [
        "Flood / Heavy Rain (IMD SACHET)",
        "Platform Outage (30+ minutes)",
        "Government Curfew / Section 144",
        "Air Quality Hazardous (AQI 301+)",
        "Festival Disruption (70%+ order drop)",
    ]

    pdf = FPDF()
    pdf.add_page()
    pdf.set_font("Arial", "B", 24)
    pdf.set_text_color(217, 119, 87)
    pdf.cell(0, 15, "GuidePay", new_x="LMARGIN", new_y="NEXT", align="C")

    pdf.set_font("Arial", "B", 14)
    pdf.set_text_color(0, 0, 0)
    pdf.cell(0, 10, "Income Protection Certificate", new_x="LMARGIN", new_y="NEXT", align="C")
    pdf.cell(0, 8, "IRDAI Innovation Sandbox Compliant", new_x="LMARGIN", new_y="NEXT", align="C")
    pdf.ln(10)

    pdf.set_font("Arial", "B", 12)
    pdf.cell(0, 8, "POLICYHOLDER DETAILS", new_x="LMARGIN", new_y="NEXT")
    pdf.set_font("Arial", "", 11)
    pdf.cell(0, 7, f"Name: {worker.get('name', 'Worker')}", new_x="LMARGIN", new_y="NEXT")
    pdf.cell(0, 7, f"City: {worker.get('city', 'India')}", new_x="LMARGIN", new_y="NEXT")
    pdf.cell(0, 7, f"Policy ID: {policy.get('_id', policy_id)}", new_x="LMARGIN", new_y="NEXT")
    pdf.cell(0, 7, f"UPI ID: {worker.get('upi_id', '****')}", new_x="LMARGIN", new_y="NEXT")
    pdf.ln(5)

    pdf.set_font("Arial", "B", 12)
    pdf.cell(0, 8, "COVERAGE DETAILS", new_x="LMARGIN", new_y="NEXT")
    pdf.set_font("Arial", "", 11)
    pdf.cell(0, 7, f"Plan: {PLANS[plan_type]['name']}", new_x="LMARGIN", new_y="NEXT")
    pdf.cell(0, 7, f"Payout Tier: {PAYOUT_TIERS[payout_tier]['label']}", new_x="LMARGIN", new_y="NEXT")
    pdf.cell(0, 7, f"Payout Amount: Rs {payout_amount} per trigger", new_x="LMARGIN", new_y="NEXT")
    pdf.cell(0, 7, f"Coverage From: {created_at}", new_x="LMARGIN", new_y="NEXT")
    pdf.cell(0, 7, f"Coverage Until: {expires_at}", new_x="LMARGIN", new_y="NEXT")
    pdf.ln(5)

    pdf.set_font("Arial", "B", 12)
    pdf.cell(0, 8, "COVERED EVENTS", new_x="LMARGIN", new_y="NEXT")
    pdf.set_font("Arial", "", 11)
    for trigger in triggers:
        pdf.cell(0, 7, f"- {trigger}", new_x="LMARGIN", new_y="NEXT")
    pdf.ln(5)

    pdf.set_font("Arial", "I", 9)
    pdf.multi_cell(
        0,
        5,
        "This certificate confirms active parametric income insurance coverage under GuidePay, "
        "operating under the IRDAI Innovation Sandbox framework. Payouts are triggered automatically "
        "by verified external data sources. No claim filing is required by the policyholder.",
    )

    pdf_bytes = bytes(pdf.output(dest="S"))
    return StreamingResponse(
        io.BytesIO(pdf_bytes),
        media_type="application/pdf",
        headers={"Content-Disposition": f'attachment; filename="GuidePay_Certificate_{policy_id}.pdf"'},
    )
