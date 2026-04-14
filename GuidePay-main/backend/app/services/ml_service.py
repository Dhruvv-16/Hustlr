from typing import Dict, List
from datetime import datetime, timedelta
import logging

logger = logging.getLogger(__name__)


async def calculate_risk_score(worker: dict, claims: list, db) -> Dict:
    """
    Calculate worker risk score 0.0 (high risk) - 1.0 (low risk).
    Higher score = more trustworthy = lower premium.
    """
    score = 0.75  # Default medium risk
    factors = {}

    # Factor 1: Account age (older = more trustworthy)
    created_at = worker.get("created_at", datetime.utcnow())
    age_days = (datetime.utcnow() - created_at).days

    if age_days >= 180:
        age_bonus = 0.10
    elif age_days >= 90:
        age_bonus = 0.05
    elif age_days >= 30:
        age_bonus = 0.02
    else:
        age_bonus = -0.05

    score += age_bonus
    factors["account_age_days"] = age_days
    factors["age_bonus"] = age_bonus

    # Factor 2: Claim history
    paid_claims = [c for c in claims if c.get("status") == "PAID"]
    rejected_claims = [c for c in claims if c.get("status") == "REJECTED"]

    if rejected_claims:
        rejection_penalty = min(len(rejected_claims) * 0.10, 0.30)
        score -= rejection_penalty
        factors["rejection_penalty"] = rejection_penalty
    else:
        factors["rejection_penalty"] = 0

    # Factor 3: Fraud score history
    avg_fraud = 0.0
    if claims:
        fraud_scores = [c.get("fraud_score", 0.5) for c in claims]
        avg_fraud = sum(fraud_scores) / len(fraud_scores)
        fraud_penalty = avg_fraud * 0.20
        score -= fraud_penalty
        factors["avg_fraud_score"] = avg_fraud
        factors["fraud_penalty"] = fraud_penalty

    # Factor 4: Platform diversity (more platforms = more stable)
    platforms = worker.get("platforms", [])
    if len(platforms) >= 3:
        score += 0.05
    elif len(platforms) == 1:
        score -= 0.03
    factors["platform_count"] = len(platforms)

    # Factor 5: UPI linked
    if worker.get("upi_id"):
        score += 0.02
        factors["upi_linked"] = True
    else:
        factors["upi_linked"] = False

    # Clamp
    final_score = round(max(0.0, min(1.0, score)), 3)

    if final_score >= 0.75:
        tier = "LOW"  # Low risk
    elif final_score >= 0.50:
        tier = "MEDIUM"
    else:
        tier = "HIGH"  # High risk

    return {
        "score": final_score,
        "tier": tier,
        "factors": factors,
        "total_claims": len(claims),
        "paid_claims": len(paid_claims),
        "rejected_claims": len(rejected_claims),
    }
