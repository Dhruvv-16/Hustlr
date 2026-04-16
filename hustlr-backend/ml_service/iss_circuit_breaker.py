"""
iss_circuit_breaker.py — ISS M1 Prophet dependency guard
=========================================================
Implements the circuit breaker pattern from the ML Blueprint:

  CLOSED   → Prophet MAPE < 15%: ML pipeline active
  OPEN     → Prophet MAPE ≥ 15%: naive actuarial prior active
  HALF_OPEN→ Shadow mode: Prophet in validation before going CLOSED

Also provides:
  - ISS score guardrails (floor for experienced workers, ±5 cap)
  - get_iss_blend_ratio() for festive-period reweighting
"""
from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
from typing import Optional

import pandas as pd


class BreakerState(Enum):
    CLOSED    = "closed"     # Prophet active, MAPE < 15%
    OPEN      = "open"       # Naive prior active
    HALF_OPEN = "half_open"  # Shadow mode — validating


# Static zone-quarter priors — used when Prophet MAPE ≥ 15%
# Format: (city, quarter) → demand multiplier
STATIC_ZONE_PRIORS: dict[tuple[str, int], float] = {
    ("Chennai", 1): 0.95,   # Jan–Mar: moderate
    ("Chennai", 2): 1.05,   # Apr–Jun: IPL season
    ("Chennai", 3): 1.10,   # Jul–Sep: post-monsoon recovery
    ("Chennai", 4): 1.28,   # Oct–Dec: Diwali festive surge
    ("Mumbai",  1): 0.90,
    ("Mumbai",  2): 1.08,
    ("Mumbai",  3): 1.12,
    ("Mumbai",  4): 1.30,
    ("Bengaluru", 1): 0.92,
    ("Bengaluru", 2): 1.03,
    ("Bengaluru", 3): 1.06,
    ("Bengaluru", 4): 1.25,
}


@dataclass
class ProphetCircuitBreaker:
    state:          BreakerState = BreakerState.OPEN  # Start OPEN until MAPE validated
    mape_threshold: float        = 15.0
    current_mape:   float        = 32.0               # Prophet currently at ~60% reliability

    def get_m1_demand_prior(self, city: str, ts: pd.Timestamp) -> float:
        """Return demand multiplier for ISS calculation."""
        if self.state == BreakerState.CLOSED:
            return self._get_prophet_forecast(city, ts)
        return self._get_naive_prior(city, ts)

    def _get_naive_prior(self, city: str, ts: pd.Timestamp) -> float:
        quarter = (ts.month - 1) // 3 + 1
        base    = STATIC_ZONE_PRIORS.get((city, quarter), 1.0)

        # Salary-week boost
        if ts.day <= 5 or ts.day >= 25:
            base *= 1.175

        # IPL evening boost (Apr–May, 19–22h)
        if ts.month in (4, 5) and ts.hour in (19, 20, 21, 22):
            base *= 1.25

        return round(base, 4)

    def _get_prophet_forecast(self, city: str, ts: pd.Timestamp) -> float:  # noqa: ARG002
        """
        Placeholder — real implementation calls the Prophet /forecast/{zone}
        endpoint and normalises yhat to a 0.5–2.0 multiplier range.
        Falls back to naive prior if the endpoint is unreachable.
        """
        try:
            import requests  # noqa: PLC0415
            r = requests.get(
                f"http://localhost:{__import__('os').environ.get('PORT', 10000)}/forecast/{city.lower()}",
                timeout=2,
            )
            data = r.json()
            forecasts = data.get("forecast", [])
            if forecasts:
                avg_risk = sum(f["risk_score"] for f in forecasts[:7]) / 7
                return round(1.0 + avg_risk * 0.4, 4)  # scale 0–1 risk to 1.0–1.4 multiplier
        except Exception:
            pass
        return self._get_naive_prior(city, ts)

    def update_mape(self, new_mape: float) -> None:
        """Call this after each Prophet validation run."""
        self.current_mape = new_mape
        if new_mape < self.mape_threshold:
            self.state = BreakerState.CLOSED
            print(f"[CircuitBreaker] CLOSED — Prophet MAPE {new_mape:.1f}% < {self.mape_threshold}%")
        elif new_mape < self.mape_threshold * 1.2:
            self.state = BreakerState.HALF_OPEN
            print(f"[CircuitBreaker] HALF_OPEN — Prophet MAPE {new_mape:.1f}% (shadow validation)")
        else:
            self.state = BreakerState.OPEN
            print(f"[CircuitBreaker] OPEN — naive prior active (Prophet MAPE {new_mape:.1f}%)")


def get_iss_blend_ratio(prophet_mape: float) -> tuple[float, float]:
    """
    Returns (ml_weight, rule_weight).
    During festive periods Prophet underperforms badly — increase ML channel weight.
    """
    if prophet_mape > 20.0:
        return (0.80, 0.20)   # Festive: trust XGBoost ML more than rule engine
    return (0.70, 0.30)       # Normal: standard blend from blueprint


def apply_iss_guardrails(
    iss_score: float,
    weeks_history: int,
    completion_rate: float,
    prev_week_score: Optional[float] = None,
) -> float:
    """
    Prevents unjust disqualification of experienced workers.

    Rules:
      - Floor at 35 for workers with ≥26 weeks tenure and ≥85% completion
      - Weekly change capped at ±5 points
    """
    # Floor: protect veterans
    if weeks_history >= 26 and completion_rate >= 0.85:
        iss_score = max(iss_score, 35.0)

    # Cap weekly swing at ±5 points
    if prev_week_score is not None:
        iss_score = max(iss_score, prev_week_score - 5.0)
        iss_score = min(iss_score, prev_week_score + 5.0)

    return round(max(0.0, min(100.0, iss_score)), 2)


# Singleton — import and use in main.py ISS endpoint
prophet_breaker = ProphetCircuitBreaker()
