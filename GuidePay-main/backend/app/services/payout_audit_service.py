from datetime import datetime
from bson import ObjectId
import hashlib
import json

async def append_payout_audit(
    db,
    claim_id: str,
    step: str,
    status: str,
    message: str,
    meta: dict | None = None,
):
    if db is None:
        return None

    # Blockchain-style linking of audit events
    last_log = await db.payout_audit_logs.find_one(sort=[("created_at", -1)])
    previous_hash = last_log["hash"] if last_log and "hash" in last_log else "0000000000000000000000000000000000000000000000000000000000000000"

    current_id = str(ObjectId())
    
    payload = {
        "id": current_id,
        "claim_id": claim_id,
        "step": step,
        "status": status,
        "message": message,
        "meta": meta or {},
        "previous_hash": previous_hash,
    }
    
    payload_str = json.dumps(payload, sort_keys=True)
    current_hash = hashlib.sha256(payload_str.encode("utf-8")).hexdigest()

    entry = {
        "id": current_id,
        "step": step,
        "status": status,
        "message": message,
        "meta": meta or {},
        "created_at": datetime.utcnow(),
        "previous_hash": previous_hash,
        "hash": current_hash,
    }

    await db.claims.update_one(
        {"_id": claim_id},
        {
            "$push": {"payout_audit_log": entry},
            "$set": {"updated_at": datetime.utcnow()},
        },
    )
    
    await db.payout_audit_logs.insert_one(
        {
            "_id": current_id,
            "claim_id": claim_id,
            **entry,
        }
    )
    return entry
