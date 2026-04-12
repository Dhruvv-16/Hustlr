"""
main.py — FastAPI microservice for Hustlr Phase 3 ML Fraud Detection.

Run with:
    uvicorn main:app --reload

Endpoints:
    POST /fraud/score          — Isolation Forest anomaly scoring
    POST /fraud/ring-detect    — Poisson + DBSCAN ring detection
    GET  /fraud/model-health   — Model metadata and health

Integrates into the existing fraud_engine.js pipeline by appending one
HTTP call to /fraud/score whose isolation_forest_score feeds into the
zone_anomaly_score component (weight 0.15) of the FPS ensemble.
"""

from __future__ import annotations

import os
import time
from contextlib import asynccontextmanager
from datetime import datetime, timezone
from pathlib import Path
from typing import List, Optional

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from fraud_model import (
    ANOMALY_THRESHOLD,
    CONTAMINATION_RATE,
    TRAINING_SAMPLES,
    ClaimEvent,
    load_model,
    score_claim,
)
from ring_detector import (
    combined_ring_verdict,
    detect_gps_clusters,
    test_poisson_arrivals,
)

# ── Model bundle cache (loaded once at startup) ────────────────────────────
_MODEL_BUNDLE: dict | None = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Load the trained model bundle once at server startup."""
    global _MODEL_BUNDLE
    print("[Startup] Loading Isolation Forest model …")
    _MODEL_BUNDLE = load_model()
    print(f"[Startup] Model loaded — trained at {_MODEL_BUNDLE.get('trained_at', 'unknown')}")
    yield
    # (teardown — nothing to do)
    _MODEL_BUNDLE = None


app = FastAPI(
    title       = "Hustlr ML Fraud Detection",
    description = "Isolation Forest zone anomaly scoring + ring pattern detection",
    version     = "1.0.0",
    lifespan    = lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins  = ["*"],   # tighten in production
    allow_methods  = ["*"],
    allow_headers  = ["*"],
)


# ── Pydantic schemas ───────────────────────────────────────────────────────

class FeatureVector(BaseModel):
    claim_latency_seconds: float
    simultaneous_zone_claims: int
    account_age_days: int
    historical_clean_claim_ratio: float
    shift_gap_count_today: int
    device_shared_with_n_accounts: int
    zone_depth_score: float
    orders_completed_during_disruption: int
    is_mock_location_ever: bool

class ClaimScoreRequest(BaseModel):
    worker_id: str
    zone_id: str
    claim_timestamp: str
    feature_vector: FeatureVector

class ClaimScoreResponse(BaseModel):
    is_anomalous: bool
    anomaly_score: float
    top_features: list[str]
    poisson_p_value: float


class RingClaimPoint(BaseModel):
    timestamp: int   = Field(..., description="Unix epoch seconds")
    gps_lat:   float = Field(..., description="Latitude")
    gps_lng:   float = Field(..., description="Longitude")


class RingDetectRequest(BaseModel):
    zone_id: str                  = Field(..., description="Zone grid ID")
    claims:  List[RingClaimPoint] = Field(..., min_length=1)


class RingDetectResponse(BaseModel):
    zone_id:              str
    poisson_result:       dict
    dbscan_result:        dict
    combined_ring_flag:   bool
    recommended_action:   str = Field(..., description="auto_approve | soft_hold | human_review")
    latency_ms:           float


# ── Endpoints ─────────────────────────────────────────────────────────────

@app.post("/ml/fraud-score", response_model=ClaimScoreResponse, tags=["Fraud"])
async def fraud_score(req: ClaimScoreRequest):
    if _MODEL_BUNDLE is None:
        raise HTTPException(status_code=503, detail="Model not loaded — server starting up")

    from fraud_model import poisson_timing_test
    # 1. Fetch poisson p value simulated/real
    if len(req.claim_timestamp) > 10:
        try:
            from dateutil.parser import parse
            ts = parse(req.claim_timestamp)
        except:
            ts = datetime.now()
    else:
        ts = datetime.now()
        
    p_val = poisson_timing_test(req.worker_id, ts, req.zone_id)

    event = ClaimEvent(
        claim_latency_seconds=req.feature_vector.claim_latency_seconds,
        simultaneous_zone_claims=req.feature_vector.simultaneous_zone_claims,
        account_age_days=req.feature_vector.account_age_days,
        historical_clean_claim_ratio=req.feature_vector.historical_clean_claim_ratio,
        shift_gap_count_today=req.feature_vector.shift_gap_count_today,
        device_shared_with_n_accounts=req.feature_vector.device_shared_with_n_accounts,
        zone_depth_score=req.feature_vector.zone_depth_score,
        orders_completed_during_disruption=req.feature_vector.orders_completed_during_disruption,
        is_mock_location_ever=req.feature_vector.is_mock_location_ever,
        poisson_p_value=p_val
    )

    result = score_claim(event, _MODEL_BUNDLE)

    return ClaimScoreResponse(
        is_anomalous    = result["is_anomalous"],
        anomaly_score   = result["anomaly_score"],
        top_features    = result["top_features"],
        poisson_p_value = result["poisson_p_value"],
    )

# ── Prophet Actuarial Pricing ──

@app.get("/forecast/{zone_id}", tags=["Forecast"])
async def get_forecast(zone_id: str, days: int = 7):
    from prophet_service.prophet_model import generate_forecast
    try:
        return generate_forecast(zone_id, days)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/forecast/retrain", tags=["Forecast"])
async def retrain_forecast():
    from prophet_service.prophet_model import train_model
    try:
        train_model()
        return {"status": "ok", "message": "Prophet model retrained from IMD fallback Open-Meteo."}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/fraud/ring-detect", response_model=RingDetectResponse, tags=["Fraud"])
async def ring_detect(req: RingDetectRequest):
    """
    Detect coordinated ring-fraud patterns in a batch of zone claims.

    Runs two independent tests in parallel:

    1. **Poisson inter-arrival test** — checks whether filing timestamps
       follow the stochastic Poisson distribution of genuine disruptions.
       Rings fail this at p < 0.05.

    2. **DBSCAN geographic clustering** — finds workers claiming from the
       same GPS location (< 50m radius, ≥ 5 workers).

    The ``recommended_action`` is the combined verdict:
      - ``human_review``  — both tests positive (high confidence ring)
      - ``soft_hold``     — one test positive (investigate further)
      - ``auto_approve``  — both tests negative (no ring signal detected)
    """
    t0 = time.perf_counter()

    timestamps = [c.timestamp for c in req.claims]
    gps_coords = [(c.gps_lat, c.gps_lng) for c in req.claims]

    poisson_result = test_poisson_arrivals(timestamps)
    dbscan_result  = detect_gps_clusters(gps_coords)
    action         = combined_ring_verdict(poisson_result, dbscan_result)

    combined_flag = (
        poisson_result.get("is_coordinated_ring", False) or
        dbscan_result.get("ring_detected", False)
    )

    latency_ms = (time.perf_counter() - t0) * 1000.0

    return RingDetectResponse(
        zone_id            = req.zone_id,
        poisson_result     = poisson_result,
        dbscan_result      = dbscan_result,
        combined_ring_flag = combined_flag,
        recommended_action = action,
        latency_ms         = round(latency_ms, 3),
    )


@app.get("/fraud/model-health", tags=["Health"])
async def model_health():
    """
    Return model metadata, version, and health signals for the admin
    dashboard's Fraud Queue panel.
    """
    if _MODEL_BUNDLE is None:
        return {
            "status":         "starting",
            "model_loaded":   False,
        }

    model_path = Path(__file__).parent / "fraud_model.pkl"

    return {
        "status":              "ok",
        "model_loaded":        True,
        "model_version":       "isolation_forest_v1.0.0",
        "feature_version":     _MODEL_BUNDLE.get("feature_version", "1.0.0"),
        "training_samples":    _MODEL_BUNDLE.get("n_samples", TRAINING_SAMPLES),
        "contamination_rate":  _MODEL_BUNDLE.get("contamination", CONTAMINATION_RATE),
        "anomaly_threshold":   _MODEL_BUNDLE.get("threshold", ANOMALY_THRESHOLD),
        "trained_at":          _MODEL_BUNDLE.get("trained_at", "unknown"),
        "model_size_bytes":    model_path.stat().st_size if model_path.exists() else 0,
        "server_time_utc":     datetime.now(timezone.utc).isoformat(),
    }


@app.get("/", tags=["Health"])
async def root():
    return {
        "service":      "Hustlr ML Fraud Detection",
        "version":      "1.0.0",
        "docs":         "/docs",
        "model_health": "/fraud/model-health",
    }
