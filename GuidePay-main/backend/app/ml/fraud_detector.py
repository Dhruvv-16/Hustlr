import numpy as np
from typing import Dict, List
import logging

logger = logging.getLogger(__name__)


def extract_features(worker: dict, claim_history: list) -> np.ndarray:
    """Extract ML features from worker and claim history"""
    from datetime import datetime

    now = datetime.utcnow()
    created_at = worker.get("created_at", now)
    account_age_days = max((now - created_at).days, 0)

    recent_claims = len([
        c for c in claim_history
        if c.get("status") not in ["REJECTED"]
    ])

    avg_fraud_score = 0.0
    if claim_history:
        scores = [c.get("fraud_score", 0.5) for c in claim_history]
        avg_fraud_score = sum(scores) / len(scores)

    platform_count = len(worker.get("platforms", []))
    has_upi = 1 if worker.get("upi_id") else 0
    risk_score = worker.get("risk_score", 0.75)

    return np.array([
        account_age_days / 365,   # normalized account age
        recent_claims,             # recent claim count
        avg_fraud_score,           # average fraud score
        platform_count / 6,       # normalized platform count
        has_upi,                   # UPI linked flag
        risk_score,                # worker risk score
    ])


def rule_based_fraud_score(features: np.ndarray) -> float:
    """
    Lightweight rule-based fraud scorer.
    Returns 0.0 (clean) to 1.0 (fraud).
    """
    weights = np.array([
        -0.20,  # account age (older = less fraud)
        0.25,   # recent claims (more = more suspicious)
        0.30,   # avg fraud score
        -0.10,  # platform diversity (more = less fraud)
        -0.05,  # UPI linked
        -0.10,  # risk score (higher score = less fraud)
    ])

    score = float(np.dot(features, weights) + 0.5)
    return round(max(0.0, min(1.0, score)), 3)
