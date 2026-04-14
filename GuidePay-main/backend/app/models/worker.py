from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from enum import Enum


class Platform(str, Enum):
    zepto = "zepto"
    swiggy = "swiggy"
    blinkit = "blinkit"
    amazon = "amazon"
    zomato = "zomato"
    dunzo = "dunzo"


class RiskTier(str, Enum):
    low = "LOW"
    medium = "MEDIUM"
    high = "HIGH"


class WorkerCreate(BaseModel):
    firebase_uid: str
    name: str
    phone: str
    email: Optional[str] = None
    city: str
    zone: str
    zone_lat: float
    zone_lng: float
    platforms: List[Platform]
    avg_daily_income: Optional[float] = 800.0
    experience_months: Optional[int] = 6
    upi_id: Optional[str] = None
    dob: Optional[str] = None


class WorkerUpdate(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    city: Optional[str] = None
    zone: Optional[str] = None
    zone_lat: Optional[float] = None
    zone_lng: Optional[float] = None
    platforms: Optional[List[Platform]] = None
    upi_id: Optional[str] = None
    photo_url: Optional[str] = None


class WorkerInDB(BaseModel):
    id: Optional[str] = Field(alias="_id")
    firebase_uid: str
    name: str
    phone: str
    email: Optional[str] = None
    city: str
    zone: str
    zone_lat: float
    zone_lng: float
    platforms: List[str]
    avg_daily_income: float = 800.0
    experience_months: int = 6
    upi_id: Optional[str] = None
    photo_url: Optional[str] = None
    risk_score: float = 0.75
    risk_tier: str = "MEDIUM"
    premium_amount: float = 58.0
    is_active: bool = True
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    last_order_timestamp: Optional[datetime] = None
    total_claims: int = 0
    total_payouts: float = 0.0

    class Config:
        populate_by_name = True
