from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from enum import Enum


class TriggerStatus(str, Enum):
    active = "ACTIVE"
    expired = "EXPIRED"
    cancelled = "CANCELLED"


class TriggerEventInDB(BaseModel):
    id: Optional[str] = Field(alias="_id")
    trigger_type: str  # FLOOD, OUTAGE, CURFEW
    city: str
    zone: str
    lat: float
    lng: float
    severity: str  # RED, ORANGE, YELLOW
    source: str  # IMD_SACHET, DOWNDETECTOR, ADMIN
    event_hash: Optional[str] = None
    source_data: dict = {}
    status: TriggerStatus = TriggerStatus.active

    # Coverage calculation
    payout_percentage: float  # 1.0, 0.75
    affected_workers: int = 0
    total_exposure: float = 0.0

    # Correlation tracking
    total_workers_in_zone: int = 0
    claims_count: int = 0
    confirmation_status: str = "PENDING"

    started_at: datetime = Field(default_factory=datetime.utcnow)
    expires_at: Optional[datetime] = None

    class Config:
        populate_by_name = True
