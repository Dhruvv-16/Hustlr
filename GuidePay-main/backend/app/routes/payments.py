import razorpay
import hmac
import hashlib
from fastapi import APIRouter, HTTPException, Depends, Request
from pydantic import BaseModel
from app.config import settings
from app.database import get_db
from datetime import datetime, timedelta
from bson import ObjectId
import logging

router = APIRouter()
logger = logging.getLogger(__name__)

PLAN_CONFIG = {
    "basic": {
        "name": "Basic",
        "price": 49.0,
        "coverage": 600,
    },
    "standard": {
        "name": "Standard",
        "price": 58.0,
        "coverage": 600,
    },
    "premium": {
        "name": "Premium",
        "price": 69.0,
        "coverage": 600,
    },
}

def get_razorpay_client():
    return razorpay.Client(
        auth=(
            settings.razorpay_key_id,
            settings.razorpay_key_secret
        )
    )

class CreateOrderRequest(BaseModel):
    plan_id: str

class VerifyPaymentRequest(BaseModel):
    razorpay_order_id: str
    razorpay_payment_id: str
    razorpay_signature: str
    plan_id: str

class PayoutRequest(BaseModel):
    claim_id: str
    upi_id: str

@router.post("/create-order")
async def create_payment_order(
    request: CreateOrderRequest,
    db=Depends(get_db)
):
    """Create Razorpay order for policy payment"""
    plan = PLAN_CONFIG.get(request.plan_id)
    if not plan:
        raise HTTPException(400, "Invalid plan")

    mock_mode = getattr(
        settings, 'razorpay_mock_mode', 'true'
    ).lower() == 'true'

    if mock_mode:
        import uuid
        order_id = f"order_MOCK_{uuid.uuid4().hex[:16]}"
        return {
            "order_id": order_id,
            "amount": int(plan["price"] * 100),
            "currency": "INR",
            "key": settings.razorpay_key_id,
            "mock": True,
        }

    try:
        client = get_razorpay_client()
        order = client.order.create({
            "amount": int(plan["price"] * 100),
            "currency": "INR",
            "notes": {
                "plan_id": request.plan_id,
                "product": "GuidePay Insurance",
            }
        })

        return {
            "order_id": order["id"],
            "amount": plan["price"],
            "currency": "INR",
            "key": settings.razorpay_key_id,
            "mock": False,
        }
    except Exception as e:
        logger.error(f"Razorpay order error: {e}")
        raise HTTPException(
            500, "Payment initialization failed"
        )

@router.post("/verify")
async def verify_payment(
    request: VerifyPaymentRequest,
    db=Depends(get_db)
):
    """Verify payment and activate policy"""
    # Verify signature (skip for mock)
    is_mock = request.razorpay_payment_id.startswith(
        "MOCK_"
    ) or request.razorpay_order_id.startswith(
        "order_MOCK_"
    )

    if not is_mock:
        try:
            signature_data = (
                f"{request.razorpay_order_id}"
                f"|{request.razorpay_payment_id}"
            )
            expected_sig = hmac.new(
                settings.razorpay_key_secret.encode(),
                signature_data.encode(),
                hashlib.sha256
            ).hexdigest()

            if expected_sig != request.razorpay_signature:
                raise HTTPException(
                    400, "Invalid payment signature"
                )
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Signature error: {e}")
            raise HTTPException(
                400, "Payment verification failed"
            )

    plan = PLAN_CONFIG.get(request.plan_id)
    if not plan:
        raise HTTPException(400, "Invalid plan")

    now = datetime.utcnow()
    policy_id = str(ObjectId())

    policy_doc = {
        "_id": policy_id,
        "plan_id": request.plan_id,
        "plan_name": plan["name"],
        "weekly_premium": plan["price"],
        "coverage_cap": float(plan["coverage"]),
        "status": "ACTIVE",
        "payment_id": request.razorpay_payment_id,
        "order_id": request.razorpay_order_id,
        "week_start": now,
        "week_end": now + timedelta(days=7),
        "auto_renew": True,
        "created_at": now,
    }

    await db.policies.insert_one(policy_doc)

    payment_doc = {
        "_id": str(ObjectId()),
        "policy_id": policy_id,
        "razorpay_payment_id": request.razorpay_payment_id,
        "razorpay_order_id": request.razorpay_order_id,
        "amount": plan["price"],
        "currency": "INR",
        "status": "captured",
        "created_at": now,
    }
    await db.payments.insert_one(payment_doc)

    return {
        "success": True,
        "policy": {
            "id": policy_id,
            "plan_id": request.plan_id,
            "plan_name": plan["name"],
            "weekly_premium": plan["price"],
            "coverage_cap": plan["coverage"],
            "status": "ACTIVE",
            "payment_id": request.razorpay_payment_id,
            "week_start": now.isoformat(),
            "week_end": (now + timedelta(days=7)).isoformat(),
        },
        "payment_id": request.razorpay_payment_id,
        "receipt": {
            "receipt_id": f"GP-{request.razorpay_payment_id[-8:].upper()}",
            "amount": plan["price"],
            "plan": plan["name"],
            "timestamp": now.isoformat(),
        }
    }

@router.post("/simulate-payout")
async def simulate_claim_payout(
    request: PayoutRequest,
    db=Depends(get_db)
):
    """
    Simulate instant UPI payout for a claim.
    Shows worker the exact payout flow.
    """
    claim = await db.claims.find_one({
        "_id": request.claim_id,
    })

    if not claim:
        raise HTTPException(404, "Claim not found")

    if claim.get("status") == "PAID":
        raise HTTPException(400, "Claim already paid")

    now = datetime.utcnow()

    import uuid
    payout_id = f"pout_TEST_{uuid.uuid4().hex[:12]}"
    transaction_id = f"IMPS{uuid.uuid4().hex[:15].upper()}"

    await db.claims.update_one(
        {"_id": request.claim_id},
        {"$set": {
            "status": "PAID",
            "paid_at": now,
            "razorpay_payout_id": payout_id,
            "upi_transaction_id": transaction_id,
            "upi_id": request.upi_id,
            "payout_mode": "UPI",
            "updated_at": now,
        }}
    )

    amount = claim.get("amount", 600)

    return {
        "success": True,
        "payout": {
            "payout_id": payout_id,
            "transaction_id": transaction_id,
            "upi_id": request.upi_id,
            "amount": amount,
            "currency": "INR",
            "mode": "UPI",
            "status": "PROCESSED",
            "processed_at": now.isoformat(),
            "expected_credit": "Instant",
        },
        "receipt": {
            "receipt_id": f"GP-PAY-{payout_id[-8:].upper()}",
            "claim_id": request.claim_id,
            "amount": amount,
            "upi_id": request.upi_id,
            "transaction_id": transaction_id,
            "timestamp": now.isoformat(),
            "message": f"₹{amount} credited to {request.upi_id}",
        }
    }
