from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from enum import Enum


class PolicyStatus(str, Enum):
    active = "ACTIVE"
    paused = "PAUSED"
    cancelled = "CANCELLED"
    expired = "EXPIRED"


class PlanType(str, Enum):
    basic = "basic"
    standard = "standard"
    premium = "premium"


class PolicyCreate(BaseModel):
    worker_id: str
    plan_id: PlanType
    payment_id: str
    amount_paid: float


class PolicyInDB(BaseModel):
    id: Optional[str] = Field(alias="_id")
    worker_id: str
    plan_id: str
    plan_name: str
    weekly_premium: float
    coverage_cap: float = 600.0
    status: PolicyStatus = PolicyStatus.active
    payment_id: str
    week_start: datetime
    week_end: datetime
    auto_renew: bool = True
    created_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        populate_by_name = True
