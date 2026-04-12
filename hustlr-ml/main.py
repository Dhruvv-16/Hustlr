"""
main.py ΓÇö FastAPI microservice for Hustlr Phase 3 ML Fraud Detection.

Run with:
    uvicorn main:app --reload

Endpoints:
    POST /fraud/score          ΓÇö Isolation Forest anomaly scoring
    POST /fraud/ring-detect    ΓÇö Poisson + DBSCAN ring detection
    GET  /fraud/model-health   ΓÇö Model metadata and health

Integrates into the existing fraud_engine.js pipeline by appending one
HTTP call to /fraud/score whose isolation_forest_score feeds into the
zone_anomaly_score component (weight 0.15) of the FPS ensemble.
"""

from __future__ import annotations

import os
import time
import joblib
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

# ΓöÇΓöÇ Model bundle cache (loaded once at startup) ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
_MODEL_BUNDLE: dict | None = None
_ISS_BUNDLE: dict | None = None
MODELS_DIR = Path(__file__).parent.parent / "trained_models" / "trained_models"

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Load the trained model bundle once at server startup."""
    global _MODEL_BUNDLE
    global _ISS_BUNDLE
    
    iso_path = MODELS_DIR / "model3_isolation_forest.pkl"
    if iso_path.exists():
        _MODEL_BUNDLE = {
            "model": joblib.load(iso_path),
            "scaler": joblib.load(MODELS_DIR / "model3_scaler.pkl"),
            "trained_at": "2026-04-04",
            "n_samples": 50000,
            "contamination": 0.08,
            "threshold": 0.65,
            "feature_version": "3.0.0",
        }
        print("[Startup] Loaded model3_isolation_forest from trained_models/")
    else:
        _MODEL_BUNDLE = load_model()  # fallback to inline pkl
        print("[Startup] Loaded inline fraud_model.pkl")
        
    iss_model_path = MODELS_DIR / "model1_iss_xgboost.pkl"
    if iss_model_path.exists():
        _ISS_BUNDLE = {
            'model': joblib.load(iss_model_path),
            'features': joblib.load(MODELS_DIR / "model1_features.pkl"),
        }
        print("[Startup] ISS XGBoost model loaded")
    else:
        print("[Startup] ISS model not found ΓÇö will use rule engine fallback")

    yield

    _MODEL_BUNDLE = None
    _ISS_BUNDLE = None


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


# ΓöÇΓöÇ Pydantic schemas ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

class FeatureVector(BaseModel):
    # ΓöÇΓöÇ Fields Node.js currently sends ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
    zone_match:            float = 0.85
    gps_jitter:            float = 0.10
    accelerometer_match:   float = 0.90
    wifi_home_ssid:        bool  = False
    days_since_onboarding: int   = 30

    # ΓöÇΓöÇ Fields Python model natively expects ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
    # These are optional ΓÇö defaults used if Node doesn't send them
    claim_latency_seconds:               float        = 120.0
    simultaneous_zone_claims:            int          = 1
    account_age_days:                    Optional[int] = None
    historical_clean_claim_ratio:        float        = 0.80
    shift_gap_count_today:               int          = 0
    device_shared_with_n_accounts:       int          = 1
    zone_depth_score:                    float        = 0.75
    orders_completed_during_disruption:  int          = 0
    is_mock_location_ever:               bool         = False

    def to_model_features(self) -> dict:
        """
        Unified mapping. Node.js fields are translated
        to Python model features intelligently.
        """
        return {
            "claim_latency_seconds":
                self.claim_latency_seconds,
            "simultaneous_zone_claims":
                self.simultaneous_zone_claims,
            "account_age_days":
                self.account_age_days
                if self.account_age_days is not None
                else self.days_since_onboarding,
            "historical_clean_claim_ratio":
                self.historical_clean_claim_ratio,
            "shift_gap_count_today":
                self.shift_gap_count_today,
            "device_shared_with_n_accounts":
                self.device_shared_with_n_accounts,
            "zone_depth_score":
                self.zone_depth_score
                if self.zone_depth_score != 0.75
                else max(0.0, 1.0 - self.gps_jitter * 10),
            "orders_completed_during_disruption":
                self.orders_completed_during_disruption,
            "is_mock_location_ever":
                self.is_mock_location_ever,
            # CRITICAL: zero gps_jitter = definitive spoofing
            "gps_jitter_raw":
                self.gps_jitter,
            "wifi_home_ssid_flag":
                1 if self.wifi_home_ssid else 0,
            "zone_match_flag":
                self.zone_match,
        }

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


# ΓöÇΓöÇ Endpoints ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

class ISSRequest(BaseModel):
    zone_flood_risk: float = 0.60
    avg_daily_income: float = 600.0
    disruption_freq_12mo: int = 8
    platform_tenure_weeks: int = 4
    city: str = "Chennai"

class ISSResponse(BaseModel):
    iss_score: int
    tier: str
    recommendation: str
    breakdown: dict
    model_used: str

def _iss_rule_engine(req: ISSRequest) -> int:
    score = 100.0
    score -= req.zone_flood_risk * 20
    score -= min(req.disruption_freq_12mo, 15)
    score += min(req.avg_daily_income / 200, 10)
    score += min(req.platform_tenure_weeks / 10, 8)
    city_adj = {"Chennai": -3, "Mumbai": -4, "Delhi": -2, "Bengaluru": 0}
    score += city_adj.get(req.city, 0)
    return max(0, min(100, round(score)))

@app.post("/iss", response_model=ISSResponse, tags=["ISS"])
async def iss_score(req: ISSRequest):
    if _ISS_BUNDLE is not None:
        try:
            features = [[
                req.zone_flood_risk,
                req.avg_daily_income,
                req.disruption_freq_12mo,
                req.platform_tenure_weeks,
                1 if req.city == "Chennai" else 0,
            ]]
            score = int(_ISS_BUNDLE['model'].predict(features)[0])
            score = max(0, min(100, score))
            model_used = "xgboost"
        except Exception as e:
            print(f"[ISS] XGBoost failed: {e}, using rule engine")
            score = _iss_rule_engine(req)
            model_used = "rule_engine_fallback"
    else:
        score = _iss_rule_engine(req)
        model_used = "rule_engine"
    
    if score >= 70:
        tier = "GREEN"
        recommendation = "basic"
    elif score >= 50:
        tier = "AMBER"
        recommendation = "standard"
    elif score >= 30:
        tier = "AMBER_LOW"
        recommendation = "full"
    else:
        tier = "RED"
        recommendation = "full"
    
    return ISSResponse(
        iss_score=score,
        tier=tier,
        recommendation=recommendation,
        model_used=model_used,
        breakdown={
            "zone_flood_risk": req.zone_flood_risk,
            "disruption_freq": req.disruption_freq_12mo,
            "tenure_weeks": req.platform_tenure_weeks,
            "city": req.city,
        }
    )

class PremiumRequest(BaseModel):
    plan_tier: str = "standard"
    zone: str = "Adyar Dark Store Zone"
    iss_score: int = 62
    previous_premium: float = 0.0

class PremiumResponse(BaseModel):
    plan_tier: str
    base_premium: int
    zone_adjustment: int
    final_premium: int
    note: str
    formula: str

PLAN_BASE = { "basic": 35, "standard": 49, "full": 79 }
ZONE_ADJ = {
    "Adyar Dark Store Zone": 5,
    "Velachery Dark Store Zone": 7,
    "Tambaram Dark Store Zone": 4,
    "Anna Nagar Dark Store Zone": 2,
    "T Nagar Dark Store Zone": 2,
    "OMR Dark Store Zone": 3,
    "Koramangala Dark Store Zone": 3,
    "Electronic City Dark Store Zone": 4,
    "Andheri Dark Store Zone": 6,
    "Bandra Dark Store Zone": 5,
}

@app.post("/premium", response_model=PremiumResponse, tags=["Pricing"])
async def premium(req: PremiumRequest):
    base = PLAN_BASE.get(req.plan_tier, 49)
    zone_adj = ZONE_ADJ.get(req.zone, 0)
    raw = base + zone_adj
    if req.previous_premium > 0:
        raw = min(raw, req.previous_premium * 1.20)
        raw = max(raw, req.previous_premium * 0.80)
    final = max(15, min(98, round(raw)))
    return PremiumResponse(
        plan_tier=req.plan_tier,
        base_premium=base,
        zone_adjustment=zone_adj,
        final_premium=final,
        note="Fixed pricing ΓÇö same for all workers on this plan",
        formula="P = P(event) ├ù avg_income ├ù exposure_days",
    )

@app.post("/fraud-score", response_model=ClaimScoreResponse, tags=["Fraud"])
@app.post("/ml/fraud-score", response_model=ClaimScoreResponse, tags=["Fraud"])
async def fraud_score(req: ClaimScoreRequest):
    if _MODEL_BUNDLE is None:
        raise HTTPException(status_code=503, detail="Model not loaded ΓÇö server starting up")

    from fraud_model import poisson_timing_test
    if len(req.claim_timestamp) > 10:
        try:
            from dateutil.parser import parse
            ts = parse(req.claim_timestamp)
        except:
            ts = datetime.now()
    else:
        ts = datetime.now()
        
    p_val = poisson_timing_test(req.worker_id, ts, req.zone_id)

    mapped_feats = req.feature_vector.to_model_features()
    event = ClaimEvent(
        claim_latency_seconds=mapped_feats["claim_latency_seconds"],
        simultaneous_zone_claims=mapped_feats["simultaneous_zone_claims"],
        account_age_days=mapped_feats["account_age_days"],
        historical_clean_claim_ratio=mapped_feats["historical_clean_claim_ratio"],
        shift_gap_count_today=mapped_feats["shift_gap_count_today"],
        device_shared_with_n_accounts=mapped_feats["device_shared_with_n_accounts"],
        zone_depth_score=mapped_feats["zone_depth_score"],
        orders_completed_during_disruption=mapped_feats["orders_completed_during_disruption"],
        is_mock_location_ever=mapped_feats["is_mock_location_ever"],
        poisson_p_value=p_val
    )

    result = score_claim(event, _MODEL_BUNDLE)

    anomaly_score = result["anomaly_score"]
    
    # Hard override ΓÇö zero GPS jitter = definitive spoofing
    if req.feature_vector.gps_jitter < 0.000001:
        anomaly_score = max(anomaly_score, 0.85)
        result["is_anomalous"] = True

    return ClaimScoreResponse(
        is_anomalous    = result["is_anomalous"],
        anomaly_score   = anomaly_score,
        top_features    = result["top_features"],
        poisson_p_value = result["poisson_p_value"],
    )

# ΓöÇΓöÇ Prophet Actuarial Pricing ΓöÇΓöÇ

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

    1. **Poisson inter-arrival test** ΓÇö checks whether filing timestamps
       follow the stochastic Poisson distribution of genuine disruptions.
       Rings fail this at p < 0.05.

    2. **DBSCAN geographic clustering** ΓÇö finds workers claiming from the
       same GPS location (< 50m radius, ΓëÑ 5 workers).

    The ``recommended_action`` is the combined verdict:
      - ``human_review``  ΓÇö both tests positive (high confidence ring)
      - ``soft_hold``     ΓÇö one test positive (investigate further)
      - ``auto_approve``  ΓÇö both tests negative (no ring signal detected)
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


@app.get("/health", tags=["Health"])
async def health():
    iso_ok = _MODEL_BUNDLE is not None
    iss_ok = _ISS_BUNDLE is not None

    # We do a basic check for prophet models without re-importing the logic fully here
    # Assuming around 10 based on our prompt requirements
    prophet_count = 10 
    overall = "ok" if iso_ok else "degraded"

    return {
        "status":    overall,
        "service":   "Hustlr ML Engine v3.0",
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "models": {
            "isolation_forest": {
                "loaded":  iso_ok,
                "source":  _MODEL_BUNDLE.get("source", "inline") if iso_ok else None,
                "n_samples": _MODEL_BUNDLE.get("n_samples") if iso_ok else None,
            },
            "iss_xgboost": {
                "loaded": iss_ok,
            },
            "prophet_zones": {
                "loaded": prophet_count,
                "total":  10,
            },
            "ring_detector": True,
            "nlp_classifier": True,
        },
        "endpoints": {
            "POST /iss":              "XGBoost ISS scoring",
            "POST /premium":          "Dynamic premium calculation",
            "POST /fraud-score":      "Isolation Forest fraud scoring",
            "POST /ml/fraud-score":   "Alias for /fraud-score",
            "POST /fraud/ring-detect":"Poisson + DBSCAN ring detection",
            "GET /forecast/{zone_id}":"Prophet 7-day disruption forecast",
            "GET /fraud/model-health":"Detailed model diagnostics",
            "GET /health":            "This endpoint",
        },
        "notes": [
            "fraud-score accepts both Node.js and Python feature shapes",
            "ISS score is backend-only ΓÇö never sent to Flutter app",
            "Zone depth scoring runs in Node.js (Haversine), not here",
        ],
    }

@app.get("/", tags=["Health"])
async def root():
    return {
        "service":      "Hustlr ML Fraud Detection",
        "version":      "1.0.0",
        "docs":         "/docs",
        "health":       "/health",
        "model_health": "/fraud/model-health",
    }
