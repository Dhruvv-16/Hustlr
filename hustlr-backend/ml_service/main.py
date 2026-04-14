"""
Hustlr ML Microservice — FastAPI
=================================
Serves all 7 trained models over HTTP.
Node.js backend calls this on localhost:8000.
"""

import sys
import math
import datetime as dt
import numpy as np
import joblib
import json
from functools import lru_cache
from pathlib import Path
from typing import Optional, List, Tuple, Dict, Any
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from industrial_logic import DataTrustEngine, EconomicCircuitBreaker
from ml_intelligence import (
    CHENNAI_NLP_RULE_ZONE_HINTS,
    CHENNAI_ZONES,
    EXTRA_KEYWORD_RULES,
    CITY_BEHAVIORAL_RISK,
    blend_iss_flood_risk,
    compute_work_route_advisory,
    extract_city_from_text,
    extract_date_nlp,
    extract_time_window_nlp,
    hourly_rate_lookup,
    seven_layer_fps,
    zone_actuarial_prior,
)

trust_engine = DataTrustEngine()
circuit_breaker = EconomicCircuitBreaker()

# ── Model paths ───────────────────────────────────────────────────────────────
# Training scripts (hustlr-ml/scripts/train_*.py) write XGBoost JSON + pickles to
# repo_root/outputs/trained_models. Alternate bundles may live under
# hustlr-ml/outputs/trained_models.
# On Render (rootDir = hustlr-backend/ml_service), models are copied into
# hustlr-backend/ml_service/outputs/trained_models so they travel with the service.
SERVICE_DIR = Path(__file__).resolve().parent
REPO_ROOT = SERVICE_DIR.parent.parent
MODELS_SEARCH_PATHS: List[Path] = [
    SERVICE_DIR / "outputs" / "trained_models",       # Render: models inside service rootDir
    REPO_ROOT / "outputs" / "trained_models",          # local monorepo dev
    REPO_ROOT / "hustlr-ml" / "outputs" / "trained_models",  # alternate dev path
]
EXTERNAL_DATA_DIR = REPO_ROOT / "hustlr-ml" / "outputs" / "external_data"

app = FastAPI(title="Hustlr ML Service", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Lazy model cache ──────────────────────────────────────────────────────────
_cache: dict = {}
_load_errors: dict = {}


def _resolve_model_path(name: str) -> Optional[Path]:
    for directory in MODELS_SEARCH_PATHS:
        candidate = directory / name
        if candidate.is_file():
            return candidate
    return None


def _load(name: str):
    if name in _cache:
        return _cache[name]
    path = _resolve_model_path(name)
    if path is None:
        searched = ", ".join(str(d) for d in MODELS_SEARCH_PATHS)
        _load_errors[name] = f"File not found: {name} (searched: {searched})"
        raise FileNotFoundError(f"Model not found: {name}")
    try:
        if path.suffix == ".json":
            from xgboost import XGBClassifier
            model = XGBClassifier()
            model.load_model(path)
            _cache[name] = model
        else:
            _cache[name] = joblib.load(path)
        return _cache[name]
    except Exception as e:
        _load_errors[name] = str(e)
        raise


# ─────────────────────────────────────────────────────────────────────────────
# HEALTH
# ─────────────────────────────────────────────────────────────────────────────
# Files required for each endpoint's ML branch (matches _load(...) usage).
# Note: /fraud uses XGBoost JSON + scaler + isolation forest (see compute_fraud).
# Note: /traffic loads classifier + label encoder only (no congestion_baseline).
MODEL_FILES = {
    "model1_iss":        ["model1_iss_xgboost.pkl", "model1_features.pkl"],
    "model3_fraud":      [
        "model3_fraud_classifier.json",
        "model3_scaler.pkl",
        "model3_isolation_forest.pkl",
        "model3_probability_calibrator.pkl",
        "model3_thresholds.pkl",
    ],
    "model4_nlp":        ["model4_rf_nlp.json", "model4_tfidf.pkl", "model4_label_map.pkl"],
    "model5_blackout":   ["model5_iso_connectivity.pkl", "model5_scaler.pkl", "model5_thresholds.pkl"],
    "model6_traffic":    ["model6_traffic_classifier.json", "model6_label_encoder.pkl"],
}

@app.get("/health")
def health():
    statuses = {}
    for model_group, files in MODEL_FILES.items():
        missing = [f for f in files if _resolve_model_path(f) is None]
        statuses[model_group] = "ok" if not missing else f"missing: {missing}"
    prophet_inventory = _load_prophet_inventory()
    prophet_models = []
    for directory in MODELS_SEARCH_PATHS:
        prophet_models.extend(directory.glob("model7_prophet_*.pkl"))
    statuses["model7_forecast"] = (
        "ok"
        if prophet_models
        else "missing: no model7_prophet_*.pkl files found"
    )
    overall = "ok" if all(v == "ok" for v in statuses.values()) else "degraded"
    return {
        "status": overall,
        "models": statuses,
        "prophet_zone_model_count": int(prophet_inventory.get("zone_model_count", 0)),
        "prophet_city_models": sorted((prophet_inventory.get("city_models") or {}).keys()),
        "models_search_paths": [str(p) for p in MODELS_SEARCH_PATHS],
    }


def _normalize_slug(value: str) -> str:
    return str(value or "").strip().lower().replace(" ", "_").replace("-", "_")


@lru_cache(maxsize=1)
def _load_prophet_inventory() -> Dict[str, Any]:
    inventory_path = _resolve_model_path("model7_prophet_inventory.json")
    inventory: Dict[str, Any] = {
        "city_models": {},
        "zone_to_city_type": {},
        "alias_map": {},
        "zone_model_count": 0,
    }
    if inventory_path is not None:
        try:
            inventory = json.loads(inventory_path.read_text(encoding="utf-8"))
        except Exception:
            pass
    if not inventory.get("zone_to_city_type"):
        dataset_path = REPO_ROOT / "hustlr-ml" / "outputs" / "datasets" / "prophet_training.csv"
        if dataset_path.is_file():
            try:
                import pandas as pd
                zone_map = {}
                for chunk in pd.read_csv(dataset_path, usecols=["zone_id", "city_type"], chunksize=250000):
                    for zone_id, city_type in chunk.dropna().drop_duplicates().itertuples(index=False):
                        zone_map[_normalize_slug(zone_id)] = str(city_type)
                inventory["zone_to_city_type"] = zone_map
                inventory["zone_model_count"] = len(zone_map)
            except Exception:
                pass
    inventory.setdefault("city_models", {})
    inventory.setdefault("zone_to_city_type", {})
    inventory.setdefault("alias_map", {})
    inventory["alias_map"].update({
        "chennai": "chennai",
        "mumbai": "mumbai",
        "bangalore": "bangalore",
        "bengaluru": "bangalore",
        "kolkata": "tier2",
        "tier2": "tier2",
    })
    inventory["zone_model_count"] = int(inventory.get("zone_model_count") or len(inventory["zone_to_city_type"]))
    return inventory


def _city_slug_for_zone_or_city(zone_or_city: str) -> str:
    zl = _normalize_slug(zone_or_city)
    if zl in {"mumbai", "bombay"} or any(x in zl for x in ["andheri", "bandra", "borivali", "chembur", "dadar", "ghatkopar", "parel", "powai", "thane", "vashi"]):
        return "mumbai"
    if zl in {"bengaluru", "bangalore", "blr"} or any(x in zl for x in ["koramangala", "whitefield", "indiranagar", "marathahalli", "electronic", "btm", "hsr", "jayanagar", "rajajinagar", "yelahanka"]):
        return "bangalore"
    if zl in {"kolkata", "calcutta"} or any(x in zl for x in ["salt_lake", "howrah", "garia", "new_town", "park_street", "tollygunge", "dum_dum", "behala", "sealdah", "esplanade"]):
        return "tier2"
    if zl.startswith("89") and zl in _load_prophet_inventory().get("zone_to_city_type", {}):
        city_type = str(_load_prophet_inventory()["zone_to_city_type"][zl]).strip().lower()
        return {
            "chennai": "chennai",
            "mumbai": "mumbai",
            "bangalore": "bangalore",
            "bengaluru": "bangalore",
            "tier2": "tier2",
        }.get(city_type, "chennai")
    return "chennai"


def _resolve_forecast_model_slug(zone_or_city: str) -> str:
    normalized = _normalize_slug(zone_or_city)
    inventory = _load_prophet_inventory()
    candidate_order = [
        normalized,
        inventory.get("alias_map", {}).get(normalized),
        _city_slug_for_zone_or_city(normalized),
    ]
    for candidate in candidate_order:
        if not candidate:
            continue
        if _resolve_model_path(f"model7_prophet_{candidate}.pkl") is not None:
            return str(candidate)
    return "chennai"


@lru_cache(maxsize=8)
def _load_city_air_profile(city_slug: str) -> Dict[str, Any]:
    air_path = EXTERNAL_DATA_DIR / f"{city_slug}_openmeteo_air_quality_2024_2025.json"
    default = {"by_hour": {}, "recent_avg": 70.0}
    if not air_path.is_file():
        return default
    try:
        payload = json.loads(air_path.read_text(encoding="utf-8"))
        hourly = payload.get("hourly", {})
        times = hourly.get("time", [])
        values = hourly.get("european_aqi", [])
        buckets: Dict[int, List[float]] = {}
        clean_vals: List[float] = []
        for ts, val in zip(times, values):
            if val is None:
                continue
            hour = int(str(ts)[11:13])
            fval = float(val)
            clean_vals.append(fval)
            buckets.setdefault(hour, []).append(fval)
        return {
            "by_hour": {hour: float(sum(vals) / len(vals)) for hour, vals in buckets.items()},
            "recent_avg": float(sum(clean_vals[-24:]) / max(1, len(clean_vals[-24:]))) if clean_vals else 70.0,
        }
    except Exception:
        return default


@lru_cache(maxsize=8)
def _load_city_weather_profile(city_slug: str) -> Dict[str, Any]:
    weather_path = EXTERNAL_DATA_DIR / f"{city_slug}_openmeteo_weather_2024_2025.json"
    default = {"temp_by_month": {}, "precip_by_month": {}, "recent_temp": 32.0, "recent_precip": 0.4}
    if not weather_path.is_file():
        return default
    try:
        payload = json.loads(weather_path.read_text(encoding="utf-8"))
        daily = payload.get("daily", {})
        times = daily.get("time", [])
        temps = daily.get("temperature_2m_mean", [])
        precs = daily.get("precipitation_sum", [])
        temp_buckets: Dict[int, List[float]] = {}
        precip_buckets: Dict[int, List[float]] = {}
        clean_temps: List[float] = []
        clean_precs: List[float] = []
        for ts, temp, precip in zip(times, temps, precs):
            month = int(str(ts)[5:7])
            if temp is not None:
                ftemp = float(temp)
                clean_temps.append(ftemp)
                temp_buckets.setdefault(month, []).append(ftemp)
            if precip is not None:
                fprec = float(precip)
                clean_precs.append(fprec)
                precip_buckets.setdefault(month, []).append(fprec)
        return {
            "temp_by_month": {month: float(sum(vals) / len(vals)) for month, vals in temp_buckets.items()},
            "precip_by_month": {month: float(sum(vals) / len(vals)) for month, vals in precip_buckets.items()},
            "recent_temp": float(sum(clean_temps[-14:]) / max(1, len(clean_temps[-14:]))) if clean_temps else 32.0,
            "recent_precip": float(sum(clean_precs[-14:]) / max(1, len(clean_precs[-14:]))) if clean_precs else 0.4,
        }
    except Exception:
        return default


def _build_forecast_future_frame(prophet_model, zone_or_city: str, horizon_hours: int) -> "pd.DataFrame":
    import pandas as pd

    city_slug = _city_slug_for_zone_or_city(zone_or_city)
    start = pd.Timestamp.now(tz="Asia/Kolkata").tz_localize(None).floor("h") + pd.Timedelta(hours=1)
    future = pd.DataFrame({"ds": pd.date_range(start=start, periods=horizon_hours, freq="h")})
    air_profile = _load_city_air_profile(city_slug)
    weather_profile = _load_city_weather_profile(city_slug)
    months = future["ds"].dt.month
    hours = future["ds"].dt.hour
    dom = future["ds"].dt.day

    future["festival_multiplier"] = 1.0
    future["precipitation_mm"] = months.map(weather_profile["precip_by_month"]).fillna(weather_profile["recent_precip"]).astype(float) / 24.0
    future["temperature_c"] = months.map(weather_profile["temp_by_month"]).fillna(weather_profile["recent_temp"]).astype(float)
    future["traffic_profile_index"] = np.select(
        [
            hours.isin([8, 9, 10, 17, 18, 19, 20]),
            hours.isin([0, 1, 2, 3, 4, 5]),
        ],
        [0.84, 0.24],
        default=0.52,
    )
    future["european_aqi"] = hours.map(air_profile["by_hour"]).fillna(air_profile["recent_avg"]).astype(float)
    future["salary_week_flag"] = np.where(
        (dom >= 1) & (dom <= 5),
        1,
        np.where((dom >= 25) | ((dom >= 7) & (dom <= 10)), 2, 0),
    )
    future["flood_event_flag"] = ((months.isin([10, 11])) & (future["precipitation_mm"] >= 1.0)).astype(int)
    future["ipl_event_flag"] = ((months.isin([3, 4, 5])) & (hours.isin([18, 19, 20, 21, 22]))).astype(int)
    future["festival_peak_flag"] = (
        ((months == 1) & (dom.isin([14, 15, 16])))
        | ((months == 10) & (dom >= 28))
        | ((months == 11) & (dom <= 2))
    ).astype(int)
    future.loc[future["festival_peak_flag"] == 1, "festival_multiplier"] = 1.18
    return future


# ─────────────────────────────────────────────────────────────────────────────
# MODEL 1 — ISS (Income Stability Score)
# ─────────────────────────────────────────────────────────────────────────────
class ISSRequest(BaseModel):
    zone_flood_risk: float          # 0.0–1.0
    avg_daily_income: float         # e.g. 600
    disruption_freq_12mo: int       # e.g. 18
    claims_history_penalty: int     # e.g. 2
    bandh_freq_zone: int = 4
    platform_outage_per_mo: int = 2
    coastal_zone: bool = False
    use_ml: bool = True
    city: str = "Chennai"
    use_weather_prior: bool = False  # Open-Meteo heavy-rain prior for city (optional)

@app.post("/iss")
def calculate_iss(req: ISSRequest):
    flood_eff, iss_meta = blend_iss_flood_risk(req.zone_flood_risk, req.city, req.use_weather_prior)
    # Rule engine (always — audit trail)
    score = 100
    score -= flood_eff * 20
    score -= min(req.disruption_freq_12mo, 15)
    score += min(req.avg_daily_income / 200, 10)
    score -= req.claims_history_penalty
    iss_rule = int(max(0, min(100, score)))

    iss_final = iss_rule
    iss_ml = None

    if req.use_ml:
        try:
            model = _load("model1_iss_xgboost.pkl")
            X = np.array([[
                flood_eff, req.avg_daily_income,
                req.disruption_freq_12mo, req.claims_history_penalty,
                req.bandh_freq_zone, req.platform_outage_per_mo,
                int(req.coastal_zone)
            ]])
            iss_ml = int(np.clip(model.predict(X)[0], 0, 100))
            iss_final = int(round(0.7 * iss_ml + 0.3 * iss_rule))
        except Exception as e:
            # Graceful fallback to rule engine
            iss_final = iss_rule

    risk_band = "HIGH" if iss_final < 50 else ("MEDIUM" if iss_final < 70 else "LOW")

    return {
        "iss_score":       iss_final,
        "iss_rule_engine": iss_rule,
        "iss_ml":          iss_ml,
        "risk_band":       risk_band,
        "recommended_tier": (
            "Full Shield"     if iss_final < 40 else
            "Standard Shield" if iss_final < 65 else
            "Basic Shield"
        ),
        "iss_enrichment":  iss_meta,
    }


# ─────────────────────────────────────────────────────────────────────────────
# WORK ROUTE / EARNING STABILITY ADVISOR (Guidewire-style preventive intelligence)
# ─────────────────────────────────────────────────────────────────────────────
class WorkAdvisorRequest(BaseModel):
    zone: str
    city: str = "Chennai"
    iss_score: Optional[int] = None
    tomorrow_rain_chance_pct: float = 0.0
    tomorrow_rain_mm: float = 0.0
    today_rain_mm_1h: float = 0.0
    aqi: int = 50
    ml_tomorrow_risk: Optional[float] = None
    active_disruption_count: int = 0


@app.post("/work-advisor")
def work_advisor(req: WorkAdvisorRequest):
    return compute_work_route_advisory(
        zone=req.zone,
        city=req.city,
        iss_score=req.iss_score,
        tomorrow_rain_chance_pct=req.tomorrow_rain_chance_pct,
        tomorrow_rain_mm=req.tomorrow_rain_mm,
        today_rain_mm_1h=req.today_rain_mm_1h,
        aqi=req.aqi,
        ml_tomorrow_risk=req.ml_tomorrow_risk,
        active_disruption_count=req.active_disruption_count,
    )


# ─────────────────────────────────────────────────────────────────────────────
# MODEL 3 — Fraud Risk Score (FPS)
# ─────────────────────────────────────────────────────────────────────────────
class FraudRequest(BaseModel):
    # Layer 1 device signals (0 or 1)
    gps_zone_mismatch: int = 0
    wifi_home_ssid: int = 0
    battery_charging: int = 0
    accelerometer_idle: int = 0
    platform_app_inactive: int = 0
    ip_home_match: int = 0
    claim_latency_under30s: int = 0
    gps_jitter_perfect: int = 0
    barometer_mismatch: int = 0
    hw_fingerprint_match: int = 0
    app_install_cluster: int = 0
    # Layer 2 behavioral
    days_since_onboard: int = 90
    referral_depth: int = 1
    simultaneous_zone_claims: int = 0
    # Layer 3 zone context
    zone_depth_score: float = 0.8
    iss_score: int = 75
    # Correlated with training feature `has_real_disruption` (e.g. IMD/NDMA event in window)
    has_real_disruption: int = 0
    # Cherry-pick: 7-layer ensemble (draft fraud engine)
    news_corroboration: float = Field(0.75, ge=0.0, le=1.0)
    platform_active_orders: int = 5
    is_shift_window: int = 1
    filing_delay_minutes: float = 25.0
    claim_city: str = "Chennai"
    ring_cluster_suspect: int = 0       # set by batch / DBSCAN pipeline
    coordinated_surge_suspect: int = 0  # set by batch / Poisson-style pipeline
    # Device integrity
    play_integrity_pass: bool = True
    is_mock_location: bool = False
    # Emergency override
    ndma_emergency_active: bool = False

SIGNAL_WEIGHTS = {
    "gps_zone_mismatch": 25, "wifi_home_ssid": 20, "battery_charging": 15,
    "accelerometer_idle": 10, "platform_app_inactive": 15, "ip_home_match": 20,
    "claim_latency_under30s": 10, "gps_jitter_perfect": 15, "barometer_mismatch": 10,
    "hw_fingerprint_match": 15, "app_install_cluster": 10,
}

# Must match hustlr-ml/scripts/train_model3_fraud.py IF_FEATURES order / length (16 dims).
_DEFAULT_FRAUD_ML_FEATURES = [
    "gps_zone_mismatch", "wifi_home_ssid", "battery_charging",
    "accelerometer_idle", "platform_app_inactive", "ip_home_match",
    "claim_latency_under30s", "gps_jitter_perfect", "barometer_mismatch",
    "hw_fingerprint_match", "app_install_cluster",
    "days_since_onboard", "zone_depth_score", "has_real_disruption",
    "simultaneous_zone_claims", "iss_score",
]


def _fraud_ml_feature_row(req: FraudRequest) -> np.ndarray:
    """Single sample (1, n_features) aligned with StandardScaler + XGB + IsolationForest training."""
    values = {
        "gps_zone_mismatch": req.gps_zone_mismatch,
        "wifi_home_ssid": req.wifi_home_ssid,
        "battery_charging": req.battery_charging,
        "accelerometer_idle": req.accelerometer_idle,
        "platform_app_inactive": req.platform_app_inactive,
        "ip_home_match": req.ip_home_match,
        "claim_latency_under30s": req.claim_latency_under30s,
        "gps_jitter_perfect": req.gps_jitter_perfect,
        "barometer_mismatch": req.barometer_mismatch,
        "hw_fingerprint_match": req.hw_fingerprint_match,
        "app_install_cluster": req.app_install_cluster,
        "days_since_onboard": req.days_since_onboard,
        "zone_depth_score": req.zone_depth_score,
        "has_real_disruption": req.has_real_disruption,
        "simultaneous_zone_claims": req.simultaneous_zone_claims,
        "iss_score": req.iss_score,
    }
    try:
        names = _load("model3_features.pkl")
        if hasattr(names, "tolist"):
            names = names.tolist()
        if isinstance(names, (list, tuple)) and len(names) == len(_DEFAULT_FRAUD_ML_FEATURES):
            order = [str(x) for x in names]
        else:
            order = _DEFAULT_FRAUD_ML_FEATURES
    except Exception:
        order = _DEFAULT_FRAUD_ML_FEATURES
    return np.array([[float(values[k]) for k in order]])


@app.post("/fraud")
def compute_fraud(req: FraudRequest):
    # Layer 0 — Play Integrity
    if not req.play_integrity_pass or req.is_mock_location:
        return {
            "fps_score": 1.0, "fps_tier": "RED", "action": "AUTO_REJECT",
            "reason": "PLAY_INTEGRITY_FAIL", "payout_multiplier": 0.0,
        }

    signals = {k: getattr(req, k) for k in SIGNAL_WEIGHTS}
    total_weight = sum(SIGNAL_WEIGHTS.values())
    raw_score = sum(signals[s] * SIGNAL_WEIGHTS[s] for s in signals)
    fps_device = max(0.0, min(1.0, raw_score / total_weight))

    city_br = CITY_BEHAVIORAL_RISK.get(req.claim_city.strip(), 0.65)
    l6_fallback = 0.25
    layer_breakdown: Dict[str, float] = {}

    def _layers(l6: float) -> Tuple[float, dict]:
        return seven_layer_fps(
            wifi_home_ssid=req.wifi_home_ssid,
            zone_depth_score=req.zone_depth_score,
            platform_active_orders=req.platform_active_orders,
            is_shift_window=req.is_shift_window,
            news_corroboration=req.news_corroboration,
            days_since_onboard=req.days_since_onboard,
            referral_depth=req.referral_depth,
            filing_delay_minutes=req.filing_delay_minutes,
            simultaneous_zone_claims=req.simultaneous_zone_claims,
            city_behavioral_risk=city_br,
            l6_isolation=l6,
            ring_cluster_suspect=req.ring_cluster_suspect,
            coordinated_surge_suspect=req.coordinated_surge_suspect,
        )

    # Blend device telemetry with 7-layer ensemble; IF + XGBoost refine same scaled vector
    try:
        X = _fraud_ml_feature_row(req)
        scaler = _load("model3_scaler.pkl")
        X_scaled = scaler.transform(X)
        iso = _load("model3_isolation_forest.pkl")
        l6 = 0.88 if iso.predict(X_scaled)[0] == -1 else 0.12
        fps_layers, layer_breakdown = _layers(l6)
        fps = min(1.0, 0.40 * fps_device + 0.60 * fps_layers)

        ml_boost = 0.0
        clf = _load("model3_fraud_classifier.json")
        raw_proba = float(clf.predict_proba(X_scaled)[0, 1])
        try:
            calibrator = _load("model3_probability_calibrator.pkl")
            proba_fraud = float(calibrator.predict_proba(np.array([[raw_proba]]))[0, 1])
        except Exception:
            proba_fraud = raw_proba
        try:
            ml_threshold = float(_load("model3_thresholds.pkl").get("threshold", 0.5))
        except Exception:
            ml_threshold = 0.5
        if proba_fraud > ml_threshold:
            denom = max(1e-6, 1.0 - ml_threshold)
            ml_boost += 0.12 * min(1.0, (proba_fraud - ml_threshold) / denom)

        fps = min(1.0, fps + min(ml_boost, 0.22))
    except Exception:
        fps_layers, layer_breakdown = _layers(l6_fallback)
        fps = min(1.0, 0.40 * fps_device + 0.60 * fps_layers)

    # NDMA emergency override
    if req.ndma_emergency_active:
        fps = max(0.0, fps - 0.15)

    # Contradictory telemetry — rare on honest devices; syndicates often stack flags incorrectly
    if req.ip_home_match == 1 and req.gps_zone_mismatch == 1:
        fps = min(1.0, fps + 0.07)
    if req.wifi_home_ssid == 1 and req.gps_jitter_perfect == 1:
        fps = min(1.0, fps + 0.05)

    # Tier decision
    if fps < 0.31:   tier, action = "GREEN",  "AUTO_APPROVE"
    elif fps < 0.61: tier, action = "YELLOW", "SOFT_HOLD"
    else:            tier, action = "RED",    "HUMAN_REVIEW"

    # Zone depth payout multiplier
    zd = req.zone_depth_score
    depth_mult = 0.0 if zd <= 0.20 else (0.30 if zd <= 0.40 else
                 0.60 if zd <= 0.60 else (0.85 if zd <= 0.80 else 1.00))

    return {
        "fps_score":          round(fps, 4),
        "fps_tier":           tier,
        "action":             action,
        "payout_multiplier":  depth_mult,
        "zone_depth_score":   req.zone_depth_score,
        "days_since_onboard": req.days_since_onboard,
        "signal_breakdown":   {s: signals[s] * SIGNAL_WEIGHTS[s] for s in signals},
        "fps_device_component": round(fps_device, 4),
        "fps_layer_breakdown": layer_breakdown,
    }


# ─────────────────────────────────────────────────────────────────────────────
# MODEL 4 — NLP Disruption Parser
# ─────────────────────────────────────────────────────────────────────────────
class NLPRequest(BaseModel):
    text: str
    require_dual_source: bool = True
    sources: dict = {}  # e.g. {"imd": 0.9, "openweather": 0.5}

KEYWORD_RULES_BASE: Dict[str, Dict[str, Any]] = {
    "rain_heavy":   {"keywords": ["heavy rain","heavy rainfall","orange alert","flooding","waterlogging","mm rainfall","imd alert","thunderstorm","64.5","downpour","intense rain"], "zone_keywords": ["chennai","velachery","adyar","tambaram","porur","anna nagar","t nagar","chromepet","guindy", "mumbai", "bengaluru", "kolkata", *CHENNAI_NLP_RULE_ZONE_HINTS], "hourly_rate_inr": 40},
    "rain_extreme": {"keywords": ["red alert","extremely heavy","cyclone","115mm","200mm","ndma","extreme precipitation","very heavy rainfall","cyclone watch","emergency advisory"], "zone_keywords": ["chennai","district","tamil nadu", "maharashtra", "karnataka", "west bengal", *CHENNAI_NLP_RULE_ZONE_HINTS], "hourly_rate_inr": 65},
    "bandh":        {"keywords": ["bandh","strike","section 144","curfew","shutdown","roads blocked","commercial halted","tamil nadu bandh","aiadmk","dmk","hartal","cpi"], "zone_keywords": ["chennai","tamil nadu","statewide", "mumbai", "bengaluru", "kolkata"], "hourly_rate_inr": 55},
    "heat_severe":  {"keywords": ["heat wave","heatwave","43°","44°","45°","extreme heat","imd red alert","temperature advisory"], "zone_keywords": ["chennai","tamil nadu", "mumbai", "delhi", "bengaluru"], "hourly_rate_inr": 45},
    "cyclone_landfall": {"keywords": ["cyclone landfall","imd category","landfall","cyclone track","very severe cyclonic storm"], "zone_keywords": ["chennai","tamil nadu coast", "odisha", "andhra"], "hourly_rate_inr": 80},
}
KEYWORD_RULES: Dict[str, Dict[str, Any]] = {**KEYWORD_RULES_BASE, **EXTRA_KEYWORD_RULES}

# Display names for lowercase CHENNAI_ZONES slugs in /nlp responses
_NLP_ZONE_DISPLAY: Dict[str, str] = {
    "omr": "OMR",
    "ecr": "ECR",
    "gst road": "GST Road",
    "iit madras": "IIT Madras",
}

@app.post("/nlp")
def parse_disruption(req: NLPRequest):
    # Industrial Data Trust Check
    if req.sources:
        is_trusted, trust_score = trust_engine.validate_disruption(req.sources)
        if not is_trusted:
            return {
                "trigger": "normal",
                "confidence": 0.0,
                "fires": False,
                "diagnostics": f"REJECTED: Data sources untrusted. Trust Score: {trust_score:.2f} (Required: 0.70)"
            }
    else:
        trust_score = 1.0 # Assume first-party standard if not passed

    text_lower = req.text.lower()
    best_trigger, best_score = "normal", 0.0

    for trigger, cfg in KEYWORD_RULES.items():
        kw_hits   = sum(1 for kw in cfg["keywords"]      if kw in text_lower)
        zone_hits = sum(1 for zk in cfg["zone_keywords"] if zk in text_lower)
        score = min(1.0, kw_hits / max(3, len(cfg["keywords"]) * 0.25) * 0.7
                    + (zone_hits / 2.0) * 0.3)
        if score > best_score:
            best_trigger, best_score = trigger, score

    rule_trigger, rule_score = best_trigger, best_score

    # Try XGBoost model — do not override a strong rule match (e.g. AQI vs misclassified rain)
    try:
        tfidf  = _load("model4_tfidf.pkl")
        xgb_clf = _load("model4_rf_nlp.json")
        label_map = _load("model4_label_map.pkl")
        rev_map = {v: k for k, v in label_map.items()}
        
        X_vec   = tfidf.transform([req.text])
        pred_idx = xgb_clf.predict(X_vec)[0]
        ml_pred  = rev_map.get(pred_idx, "normal")
        ml_proba = xgb_clf.predict_proba(X_vec).max()
        if ml_pred != "normal" and float(ml_proba) > 0.60:
            if rule_score < 0.58:
                best_trigger = ml_pred
                best_score = max(best_score, float(ml_proba) * 0.95)
            else:
                best_score = max(best_score, float(ml_proba) * 0.82)
        elif ml_pred == "normal" and float(ml_proba) > 0.80:
            if rule_score < 0.58:
                best_score = min(best_score, 0.40)
    except Exception:
        pass

    THRESHOLD = 0.60
    if best_score < THRESHOLD:
        return {"trigger": "normal", "confidence": 0.0, "fires": False}

    window_start, window_end = extract_time_window_nlp(req.text)
    advisory_date = extract_date_nlp(req.text)
    metro_city = extract_city_from_text(req.text)

    zone_detail = metro_city
    for z in CHENNAI_ZONES:
        if z in text_lower:
            zone_detail = _NLP_ZONE_DISPLAY.get(z, z.title())
            break

    fires_flag = best_score >= THRESHOLD
    if fires_flag and req.require_dual_source:
        dual_conf = best_score > 0.8
    else:
        dual_conf = True

    return {
        "trigger":       best_trigger,
        "zone":          zone_detail,
        "metro_city":    metro_city,
        "confidence":    round(best_score, 3),
        "data_trust_score": round(trust_score, 3),
        "window_start":  window_start,
        "window_end":    window_end,
        "advisory_date": advisory_date,
        "hourly_rate":   hourly_rate_lookup(best_trigger, KEYWORD_RULES),
        "fires":         fires_flag,
        "dual_confirmed": dual_conf
    }


# ─────────────────────────────────────────────────────────────────────────────
# MODEL 5 — Internet Blackout Detection
# ─────────────────────────────────────────────────────────────────────────────
class BlackoutRequest(BaseModel):
    ookla_avg_speed: float       # Mbps
    device_pct_weak: float       # 0.0–1.0
    sustained_minutes: int
    trai_match: bool
    zone: str = "Unknown"

@app.post("/blackout")
def detect_blackout(req: BlackoutRequest):
    threshold_fired = (
        req.ookla_avg_speed   < 2.0 and
        req.device_pct_weak  >= 0.30 and
        req.sustained_minutes >= 20  and
        req.trai_match        == True
    )
    severity = "NONE"
    if threshold_fired:
        if req.ookla_avg_speed < 0.5 and req.device_pct_weak > 0.7:
            severity = "CRITICAL"
        elif req.ookla_avg_speed < 1.0:
            severity = "SEVERE"
        else:
            severity = "MODERATE"

    # Try Isolation Forest anomaly model
    ml_anomaly = False
    try:
        iso    = _load("model5_iso_connectivity.pkl")
        scaler = _load("model5_scaler.pkl")
        X = np.array([[req.ookla_avg_speed, req.device_pct_weak, req.sustained_minutes]])
        X_scaled = scaler.transform(X)
        ml_anomaly = bool(iso.predict(X_scaled)[0] == -1)
        if ml_anomaly and not threshold_fired:
            threshold_fired = True
            severity = "MODERATE"
    except Exception:
        pass

    threshold_fired = bool(threshold_fired)
    return {
        "blackout_detected":  threshold_fired,
        "ml_anomaly_flag":    bool(ml_anomaly),
        "severity":           severity,
        "zone":               req.zone,
        "ookla_speed_mbps":   req.ookla_avg_speed,
        "device_pct_weak":    req.device_pct_weak,
        "sustained_minutes":  req.sustained_minutes,
        "trai_confirmed":     bool(req.trai_match),
        "trigger_fires":      threshold_fired,
        "hourly_rate_inr":    50 if threshold_fired else 0,
    }


# ─────────────────────────────────────────────────────────────────────────────
# MODEL 6 — Traffic / Accident Classifier
# ─────────────────────────────────────────────────────────────────────────────
class TrafficRequest(BaseModel):
    zone: str
    traffic_speed_kmh: float
    baseline_speed_kmh: float
    traffic_duration_min: int
    news_confidence: float
    time_of_day: int             # hour 0–23
    is_weekend: bool = False

@app.post("/traffic")
def classify_traffic(req: TrafficRequest):
    is_peak = req.time_of_day in [8, 9, 10, 17, 18, 19, 20]
    congestion_prob = 0.60 if (is_peak and not req.is_weekend) else 0.25
    speed_pct_drop  = (req.baseline_speed_kmh - req.traffic_speed_kmh) / max(req.baseline_speed_kmh, 1)

    # Try the trained traffic classifier
    classification = "INCONCLUSIVE"
    try:
        clf     = _load("model6_traffic_classifier.json")
        encoder = _load("model6_label_encoder.pkl")
        X = np.array([[congestion_prob, speed_pct_drop, req.traffic_duration_min,
                       req.news_confidence, int(is_peak), int(req.is_weekend)]])
        pred = clf.predict(X)[0]
        classification = str(encoder.inverse_transform([pred])[0]) if hasattr(encoder, 'inverse_transform') else str(pred)
    except Exception:
        # Rule-based fallback
        if congestion_prob > 0.80:
            classification = "NORMAL_CONGESTION"
        elif req.news_confidence >= 0.65 and req.traffic_duration_min >= 30:
            classification = "ACCIDENT_BLOCKSPOT"

    heavy_trigger = bool(speed_pct_drop >= 0.40 and req.traffic_duration_min >= 45)
    trigger_fires = bool(classification == "ACCIDENT_BLOCKSPOT" or heavy_trigger)

    return {
        "classification":          classification,
        "congestion_probability":  round(float(congestion_prob), 3),
        "speed_pct_drop":          round(float(speed_pct_drop), 3),
        "heavy_traffic_trigger":   heavy_trigger,
        "news_confidence":         req.news_confidence,
        "hourly_rate_inr":         30 if heavy_trigger else 0,  # ₹30/hr from actuarial model
        "daily_cap_inr":           80 if heavy_trigger else 0,
        "trigger_fires":           trigger_fires,
    }


# ─────────────────────────────────────────────────────────────────────────────
# MODEL 7 — Disruption Forecast (Prophet)
# ─────────────────────────────────────────────────────────────────────────────
@app.get("/forecast/{zone}")
def get_forecast(zone: str, horizon_hours: int = 24):
    horizon_hours = max(6, min(int(horizon_hours), 168))
    model_slug = _resolve_forecast_model_slug(zone)
    model_file = f"model7_prophet_{model_slug}.pkl"
    forecast_data = []

    try:
        prophet_model = _load(model_file)
        future = _build_forecast_future_frame(prophet_model, zone, horizon_hours)
        forecast = prophet_model.predict(future)
        for _, row in forecast.iterrows():
            # Log transform reverse (demand units)
            yhat = float(np.exp(row['yhat']))
            yhat_upper = float(np.exp(row['yhat_upper']))
            yhat_lower = float(np.exp(row['yhat_lower']))
            
            # Simple risk mapping for baseline
            # if yhat drops significantly below standard baseline it's high risk
            baseline_demand = 50.0 
            risk = 0.0
            sigma = (yhat_upper - yhat_lower) / (2 * 1.28)
            if sigma > 0:
                from scipy.stats import norm
                risk = norm.cdf(15.0, loc=yhat, scale=sigma)
            else:
                risk = 1.0 if yhat < 15.0 else 0.0
                
            risk = float(np.clip(risk, 0.0, 1.0))

            forecast_data.append({
                "timestamp":  row['ds'].strftime('%Y-%m-%dT%H:%M:%S'),
                "date":       row['ds'].strftime('%Y-%m-%d'),
                "risk_score": round(risk, 3),
                "predicted_demand": round(yhat, 2),
                "risk_level": "HIGH" if risk > 0.6 else ("MEDIUM" if risk > 0.3 else "LOW"),
                "source":     "prophet_ml",
            })
    except Exception as repr_err:
        # Deterministic prior + smooth weekly shape (no RNG — stable for a given zone/day index)
        city_slug = _city_slug_for_zone_or_city(zone)
        base_risk = float(zone_actuarial_prior(zone, city_slug.title()))
        for i in range(horizon_hours):
            point = dt.datetime.now() + dt.timedelta(hours=i + 1)
            phase = math.sin(2 * math.pi * ((i % 24) + 1) / 24.0)
            risk = float(np.clip(base_risk * (0.88 + 0.06 * phase), 0, 1))
            forecast_data.append({
                "timestamp":  point.strftime('%Y-%m-%dT%H:%M:%S'),
                "date":       point.strftime('%Y-%m-%d'),
                "risk_score": round(risk, 3),
                "risk_level": "HIGH" if risk > 0.6 else ("MEDIUM" if risk > 0.3 else "LOW"),
                "source":     "rule_based_fallback",
            })

    return {
        "zone":     zone,
        "model_slug": model_slug,
        "horizon_hours": horizon_hours,
        "forecast": forecast_data,
    }


def _recent_city_aqi_default(zone_or_city: str) -> float:
    slug = _city_slug_for_zone_or_city(zone_or_city)
    return float(_load_city_air_profile(slug).get("recent_avg", 70.0))


# ─────────────────────────────────────────────────────────────────────────────
# PAYOUT CALCULATOR
# ─────────────────────────────────────────────────────────────────────────────
class PayoutRequest(BaseModel):
    trigger_type: str
    disruption_hours: float
    zone_depth_score: float
    fps_tier: str
    plan_tier: str
    zone: str = "Unknown"
    daily_payouts_this_week: float = 0.0
    shift_overlap_hours: Optional[float] = None

# ── Actuarial rates from constants (mirrors hustlr-backend/src/config/constants.js) ──
HOURLY_RATES_INR = {
    "rain_heavy":        40,
    "rain_extreme":      65,
    "heat_severe":       45,
    "aqi_hazardous":     35,
    "platform_outage":   50,
    "bandh":             55,
    "traffic_severe":    30,
    "internet_blackout": 45,
    "cyclone_landfall":  80,
    # Legacy key aliases
    "heavy_rain": 40, "extreme_rain": 65, "heat_wave": 45,
    "aqi": 35, "app_outage": 50, "heavy_traffic": 30, "internet_blackout": 45,
}

DAILY_CAPS_INR = {
    "rain_heavy": 120, "rain_extreme": 200, "heat_severe": 130,
    "aqi_hazardous": 100, "platform_outage": 140, "bandh": 150,
    "traffic_severe": 80, "internet_blackout": 110, "cyclone_landfall": 300,
    # Legacy aliases
    "heavy_rain": 120, "extreme_rain": 200, "heat_wave": 130,
    "aqi": 100, "app_outage": 140, "heavy_traffic": 80,
}

WEEKLY_CAPS_INR = {
    "basic": 400, "standard": 500, "full": 650,
    "Basic Shield": 400, "Standard Shield": 500, "Full Shield": 650,
}

COMPOUND_BONUSES_PY = {
    frozenset(["rain_heavy",     "platform_outage"]): {"type": "additive",       "multiplier": 1.0},
    frozenset(["cyclone_landfall","bandh"]):           {"type": "multiplicative", "multiplier": 1.2},
    frozenset(["heat_severe",    "aqi_hazardous"]):    {"type": "multiplicative", "multiplier": 1.1},
    frozenset(["rain_extreme",   "internet_blackout"]):{"type": "multiplicative", "multiplier": 1.3, "weekly_cap_override": 800},
}

PLAN_TRIGGERS_PY = {
    "basic":    ["rain_heavy","rain_extreme","heat_severe"],
    "standard": ["rain_heavy","rain_extreme","heat_severe","aqi_hazardous","platform_outage","bandh"],
    "full":     ["rain_heavy","rain_extreme","heat_severe","aqi_hazardous","platform_outage",
                 "bandh","traffic_severe","internet_blackout","cyclone_landfall"],
    # Legacy
    "Basic Shield":    ["rain_heavy","heavy_rain","heat_wave","heat_severe","rain_extreme","extreme_rain"],
    "Standard Shield": ["rain_heavy","heavy_rain","heat_wave","heat_severe","aqi","aqi_hazardous","app_outage","platform_outage","rain_extreme","extreme_rain"],
    "Full Shield":     "all",
}

@app.post("/payout")
def calculate_payout(req: PayoutRequest):
    from datetime import datetime
    
    # Industrial Circuit Breaker Check
    can_proceed, breaker_reason = circuit_breaker.check_claim_limit(req.zone, datetime.now())
    if not can_proceed:
        return {"payout_inr": 0, "reason": breaker_reason, "approved": False}

    plan_key = req.plan_tier.lower().replace(" shield", "").strip()
    allowed  = PLAN_TRIGGERS_PY.get(req.plan_tier) or PLAN_TRIGGERS_PY.get(plan_key, [])
    if allowed != "all" and req.trigger_type not in allowed:
        return {"payout_inr": 0, "reason": "TRIGGER_NOT_IN_PLAN", "approved": False}

    if req.fps_tier == "RED":
        return {"payout_inr": 0, "reason": "HELD_FOR_HUMAN_REVIEW", "approved": False}

    hourly_rate = HOURLY_RATES_INR.get(req.trigger_type, 40)
    daily_cap   = DAILY_CAPS_INR.get(req.trigger_type, 120)
    weekly_cap  = WEEKLY_CAPS_INR.get(req.plan_tier) or WEEKLY_CAPS_INR.get(plan_key, 500)

    # Shift-hour multiplier
    claim_hour = getattr(req, 'claim_hour', 14) or 14
    shift_mult = (
        1.00 if 9  <= claim_hour < 18 else
        0.75 if 18 <= claim_hour < 22 else
        0.50 if 8  <= claim_hour < 9  else
        0.00
    )

    # Zone depth multiplier  
    zd = req.zone_depth_score
    depth_mult = (0.0 if zd <= 0.20 else 0.30 if zd <= 0.40 else
                  0.60 if zd <= 0.60 else 0.85 if zd <= 0.80 else 1.00)

    disruption_hours = req.disruption_hours
    if req.shift_overlap_hours is not None:
        disruption_hours = min(disruption_hours, req.shift_overlap_hours)

    raw_payout = hourly_rate * disruption_hours * shift_mult * depth_mult
    payout     = min(raw_payout, daily_cap)

    # Compound trigger bonus (Full Shield only)
    compound_applied = None
    secondary = getattr(req, 'secondary_trigger', None)
    if plan_key == "full" and secondary:
        key = frozenset([req.trigger_type, secondary])
        bonus = COMPOUND_BONUSES_PY.get(key)
        if bonus:
            if bonus["type"] == "additive":
                sec_rate = HOURLY_RATES_INR.get(secondary, 40)
                sec_cap  = DAILY_CAPS_INR.get(secondary, 120)
                sec_pay  = min(sec_rate * disruption_hours * shift_mult * depth_mult, sec_cap)
                payout   = payout + sec_pay
                if "weekly_cap_override" in bonus:
                    weekly_cap = bonus["weekly_cap_override"]
            else:
                payout = payout * bonus["multiplier"]
                if "weekly_cap_override" in bonus:
                    weekly_cap = bonus["weekly_cap_override"]
            compound_applied = f"{req.trigger_type}+{secondary} → {bonus['multiplier']}×"

    # Yellow tier: 70% payout (30% held until Sunday review)
    fps_mult = 0.70 if req.fps_tier == "YELLOW" else 1.00
    payout   = round(payout * fps_mult)

    # Apply weekly accumulated cap
    remaining_weekly = max(0, weekly_cap - req.daily_payouts_this_week)
    payout = round(min(payout, remaining_weekly), 2)
    
    # Increment Industrial Circuit Breaker Metrics
    if payout > 0:
        circuit_breaker.increment_claim(req.zone, datetime.now(), payout)

    return {
        "payout_inr":          payout,
        "hourly_rate":         hourly_rate,
        "disruption_hours":    disruption_hours,
        "shift_multiplier":    shift_mult,
        "depth_multiplier":    depth_mult,
        "fps_multiplier":      fps_mult,
        "daily_cap":           daily_cap,
        "weekly_cap":          weekly_cap,
        "zone_depth_score":    req.zone_depth_score,
        "fps_tier":            req.fps_tier,
        "compound_applied":    compound_applied,
        "approved":            payout > 0,
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=False)
