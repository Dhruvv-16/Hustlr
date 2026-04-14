import os
from datetime import datetime
import logging

logger = logging.getLogger(__name__)


async def create_payout(worker: dict, claim: dict, db) -> dict:
    """
    Mock payout for competition demo.
    Generates a simulated payout ID and marks claim as PAID.
    """
    upi_id = worker.get("upi_id", "worker@upi")
    payout_id = f"MOCK_GP_{str(claim['_id'])[:8].upper()}"

    logger.info(
        f"[MOCK PAYOUT] \u20b9{claim['amount']} "
        f"to {upi_id} — ID: {payout_id}"
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
            "total_payouts": claim["amount"],
        }}
    )

    return {"payout_id": payout_id, "status": "processed"}
