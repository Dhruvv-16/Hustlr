from fastapi import APIRouter, Depends
from pydantic import BaseModel

from app.database import get_db
from app.services.actuarial_service import (
    actuarial_summary,
    city_exposure,
    premium_payout_trend,
    reserve_summary,
    simulate_scenario,
    stress_test_scenarios,
)
from app.utils.formatters import serialize_doc

router = APIRouter()


class ScenarioRequest(BaseModel):
    city: str
    trigger_type: str
    num_workers: int
    days: int = 7
    payout_amount: float = 600.0
    weekly_premium: float = 58.0


@router.get("/summary")
async def get_actuarial_summary(db=Depends(get_db)):
    summary = await actuarial_summary(db)
    summary["trend"] = await premium_payout_trend(db, days=30)
    summary["stress_tests"] = stress_test_scenarios()
    return serialize_doc(summary)


@router.post("/simulate")
async def simulate_actuarial_scenario(request: ScenarioRequest):
    return simulate_scenario(
        city=request.city,
        trigger_type=request.trigger_type,
        num_workers=request.num_workers,
        days=request.days,
        payout_amount=request.payout_amount,
        weekly_premium=request.weekly_premium,
    )


@router.get("/exposure")
async def get_city_exposure(db=Depends(get_db)):
    return serialize_doc(await city_exposure(db))


@router.get("/reserve")
async def get_reserve_summary(db=Depends(get_db)):
    reserve = await reserve_summary(db)
    reserve["stress_tests"] = stress_test_scenarios()
    return serialize_doc(reserve)
