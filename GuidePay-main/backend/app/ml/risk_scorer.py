import numpy as np
from typing import Dict
import logging

logger = logging.getLogger(__name__)


def score_worker_risk(worker: dict, claims: list) -> Dict:
    """
    Calculate worker risk score using weighted features.
    Returns score 0.0-1.0 where higher = lower risk.
    """
    from datetime import datetime

    now = datetime.utcnow()

    # Feature 1: Account age
    created_at = worker.get("created_at", now)
    age_days = max((now - created_at).days, 0)
    age_score = min(age_days / 365, 1.0)  # normalize to 1 year

    # Feature 2: Claim approval rate
    total_claims = len(claims)
    paid_claims = len([c for c in claims if c.get("status") == "PAID"])
    rejected_claims = len([c for c in claims if c.get("status") == "REJECTED"])

    if total_claims > 0:
        approval_rate = paid_claims / total_claims
        rejection_penalty = rejected_claims / total_claims
    else:
        approval_rate = 0.5  # neutral for new users
        rejection_penalty = 0.0

    # Feature 3: Average fraud score (inverted — lower fraud = higher trust)
    if claims:
        avg_fraud = sum(c.get("fraud_score", 0.5) for c in claims) / len(claims)
        fraud_trust = 1.0 - avg_fraud
    else:
        fraud_trust = 0.75  # neutral

    # Feature 4: Platform diversity
    platform_count = len(worker.get("platforms", []))
    platform_score = min(platform_count / 3, 1.0)

    # Feature 5: Profile completeness
    completeness = 0.0
    if worker.get("upi_id"):
        completeness += 0.33
    if worker.get("email"):
        completeness += 0.33
    if worker.get("zone") and worker.get("city"):
        completeness += 0.34

    # Weighted combination
    final_score = (
        age_score * 0.20 +
        approval_rate * 0.25 +
        (1 - rejection_penalty) * 0.20 +
        fraud_trust * 0.20 +
        platform_score * 0.10 +
        completeness * 0.05
    )

    final_score = round(max(0.0, min(1.0, final_score)), 3)

    if final_score >= 0.75:
        tier = "LOW"
    elif final_score >= 0.50:
        tier = "MEDIUM"
    else:
        tier = "HIGH"

    return {
        "score": final_score,
        "tier": tier,
        "components": {
            "age_score": round(age_score, 3),
            "approval_rate": round(approval_rate, 3),
            "fraud_trust": round(fraud_trust, 3),
            "platform_score": round(platform_score, 3),
            "completeness": round(completeness, 3),
        }
    }
