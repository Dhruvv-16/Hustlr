from pydantic import BaseModel, Field
from typing import Optional, List, Dict
from datetime import datetime
from enum import Enum


class ClaimStatus(str, Enum):
    pending = "PENDING"
    verifying = "VERIFYING"
    auto_approved = "AUTO_APPROVED"
    manual_review = "MANUAL_REVIEW"
    paid = "PAID"
    rejected = "REJECTED"


class TriggerType(str, Enum):
    flood = "FLOOD"
    outage = "OUTAGE"
    curfew = "CURFEW"


class ClaimInDB(BaseModel):
    id: Optional[str] = Field(alias="_id")
    worker_id: str
    policy_id: str
    trigger_event_id: str
    trigger_type: TriggerType
    amount: float
    status: ClaimStatus = ClaimStatus.pending

    # Fraud detection results
    fraud_score: float = 0.0
    fraud_flags: List[str] = []
    fraud_checks: Dict = {}

    # Verification
    activity_verified: bool = False
    last_order_age_minutes: Optional[float] = None
    gps_distance_km: Optional[float] = None

    # Zone correlation
    zone_correlation_ratio: Optional[float] = None
    zone_worker_count: int = 0
    zone_claim_count: int = 0

    # Payment
    razorpay_payout_id: Optional[str] = None
    payout_status: str = "NOT_STARTED"
    payout_audit_log: List[Dict] = []
    payout_attempts: int = 0
    policy_week_remaining_after_claim: Optional[float] = None
    paid_at: Optional[datetime] = None

    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        populate_by_name = True
