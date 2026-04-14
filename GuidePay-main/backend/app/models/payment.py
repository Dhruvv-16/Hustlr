from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class PaymentInDB(BaseModel):
    id: Optional[str] = Field(alias="_id")
    worker_id: str
    policy_id: str
    razorpay_payment_id: str
    razorpay_order_id: str
    amount: float
    currency: str = "INR"
    status: str = "captured"
    created_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        populate_by_name = True
