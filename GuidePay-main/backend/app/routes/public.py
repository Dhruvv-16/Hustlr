from fastapi import APIRouter
from app.core.constants import PLANS, PAYOUT_TIERS

router = APIRouter()

@router.get("/plans")
async def get_public_plans():
    """Serves standard pricing and constants for the frontend marketing/plans page without auth"""
    return {
        "plans": PLANS,
        "payout_tiers": PAYOUT_TIERS
    }
