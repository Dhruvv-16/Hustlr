from __future__ import annotations

import math
from pathlib import Path

import numpy as np
import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[2]
DATASETS_DIR = PROJECT_ROOT / "hustlr-ml" / "outputs" / "datasets"
WORKER_CSV = DATASETS_DIR / "worker_profiles.csv"
CLAIMS_CSV = DATASETS_DIR / "claims_fraud.csv"
RANDOM_STATE = 42
REFERENCE_DATE = pd.Timestamp("2026-01-01")
EXTERNAL_DIR = PROJECT_ROOT / "hustlr-ml" / "outputs" / "external_data"


def _stable_uniform(ids: pd.Series, salt: str) -> np.ndarray:
    hashed = pd.util.hash_pandas_object(ids.astype(str) + salt, index=False).to_numpy(dtype="uint64")
    return (hashed % 1_000_003) / 1_000_003.0


def rebuild_worker_scores(df: pd.DataFrame) -> pd.DataFrame:
    out = df.copy()
    onboard = pd.to_datetime(out["onboard_date"], errors="coerce")
    tenure_months = ((REFERENCE_DATE - onboard).dt.days.fillna(180).clip(lower=30) / 30.4).to_numpy()

    u1 = _stable_uniform(out["worker_id"], ":latent1")
    u2 = _stable_uniform(out["worker_id"], ":latent2")
    worker_latent = (u1 - 0.5) * 10.0
    worker_noise = (u2 - 0.5) * 4.0

    zone_codes = out["zone"].astype("category").cat.codes.to_numpy()
    zone_wave = np.sin((zone_codes + 1) * 0.9) * 1.5
    seasonal_tenure = np.sin((tenure_months % 12) / 12.0 * 2 * math.pi) * 1.8

    env_term = load_city_environment_term()

    income_term = 12.5 * np.tanh((out["avg_daily_income"].to_numpy() - 575.0) / 210.0)
    flood_term = -24.0 * out["zone_flood_risk"].to_numpy()
    disruption_term = -12.0 * np.log1p(out["disruption_freq_12mo"].to_numpy()) / np.log(20)
    claims_term = -2.3 * np.power(out["claims_history_penalty"].to_numpy(), 0.98)
    bandh_term = -0.55 * out["bandh_freq_zone"].to_numpy()
    outage_term = -1.2 * out["platform_outage_per_mo"].to_numpy()
    coastal_term = -2.8 * out["coastal_zone"].astype(float).to_numpy()
    tenure_term = 7.2 * np.tanh((tenure_months - 18.0) / 18.0)

    nonlinear_bonus = np.where(
        (out["avg_daily_income"].to_numpy() > 700) & (out["claims_history_penalty"].to_numpy() <= 2),
        3.5,
        0.0,
    )
    fragility_penalty = np.where(
        (out["zone_flood_risk"].to_numpy() > 0.55) & (out["disruption_freq_12mo"].to_numpy() > 16),
        -5.0,
        0.0,
    )

    score = (
        66.0
        + income_term
        + flood_term
        + disruption_term
        + claims_term
        + bandh_term
        + outage_term
        + coastal_term
        + tenure_term
        + seasonal_tenure
        + zone_wave
        + env_term
        + worker_latent
        + worker_noise
        + nonlinear_bonus
        + fragility_penalty
    )
    score = np.clip(np.round(score), 18, 96).astype(int)

    out["iss_score"] = score
    out["recommended_tier"] = np.select(
        [score < 38, score < 62],
        ["Full Shield", "Standard Shield"],
        default="Basic Shield",
    )

    base_premium = np.select(
        [score < 38, score < 62],
        [79, 49],
        default=29,
    )
    premium_risk = np.where(out["zone_flood_risk"].to_numpy() > 0.45, 6, 0)
    premium_disruption = np.where(out["disruption_freq_12mo"].to_numpy() > 18, 4, 0)
    out["weekly_premium"] = (base_premium + premium_risk + premium_disruption).astype(int)
    return out


def load_city_environment_term() -> float:
    rain_path = EXTERNAL_DIR / "chennai_rainfall_1991_2023.csv"
    air_path = EXTERNAL_DIR / "chennai_openmeteo_air_quality_2024_2025.json"
    bonus = 0.0

    if rain_path.is_file():
        rain = pd.read_csv(rain_path)
        if {"District", "Rainfall"}.issubset(rain.columns):
            chennai = rain[rain["District"].astype(str).str.contains("chennai", case=False, na=False)]
            if not chennai.empty:
                mean_rain = float(pd.to_numeric(chennai["Rainfall"], errors="coerce").dropna().mean())
                bonus -= min(mean_rain / 25.0, 2.0)

    if air_path.is_file():
        try:
            air = pd.read_json(air_path)
        except ValueError:
            import json
            payload = json.loads(air_path.read_text(encoding="utf-8"))
            aqi = payload.get("hourly", {}).get("european_aqi", [])
            valid = [float(x) for x in aqi if x is not None]
            if valid:
                bonus -= min(np.mean(valid) / 120.0, 1.5)

    return bonus


def sync_claim_scores(worker_df: pd.DataFrame, claims_df: pd.DataFrame) -> pd.DataFrame:
    out = claims_df.copy()
    score_map = worker_df.set_index("worker_id")["iss_score"]
    out["iss_score"] = out["worker_id"].map(score_map).fillna(out["iss_score"]).astype(int)
    return out


def main() -> None:
    worker_df = pd.read_csv(WORKER_CSV)
    claims_df = pd.read_csv(CLAIMS_CSV)

    worker_new = rebuild_worker_scores(worker_df)
    claims_new = sync_claim_scores(worker_new, claims_df)

    worker_new.to_csv(WORKER_CSV, index=False)
    claims_new.to_csv(CLAIMS_CSV, index=False)

    print(f"Updated {WORKER_CSV}")
    print(
        "ISS summary:",
        {
            "mean": round(float(worker_new["iss_score"].mean()), 2),
            "std": round(float(worker_new["iss_score"].std()), 2),
            "min": int(worker_new["iss_score"].min()),
            "max": int(worker_new["iss_score"].max()),
        },
    )
    print(f"Synced ISS scores into {CLAIMS_CSV}")


if __name__ == "__main__":
    main()
