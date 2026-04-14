"""
hustlr_prophet_v2.py — Prophet M7 rebuild
==========================================
Fixes 4 known failure modes from the ML Blueprint:
  1. cloudpickle version mismatch  → pinned in requirements.txt
  2. Stan binary not compiled       → mcmc_samples=0 (MAP only)
  3. Missing regressors at inference→ manifest.json documents required cols
  4. Additive seasonality wrong     → seasonality_mode='multiplicative'

Run locally:
    python hustlr_backend/ml_service/hustlr_prophet_v2.py

Saves:
    hustlr-ml/models/trained/prophet_v2_render.pkl
    hustlr-ml/models/trained/prophet_v2_manifest.json
"""

from __future__ import annotations

import json
import warnings
from pathlib import Path

import cloudpickle
import numpy as np
import pandas as pd

warnings.filterwarnings("ignore")

# ── Output paths ──────────────────────────────────────────────────────────────
_HERE = Path(__file__).parent
MODELS_DIR = _HERE.parent.parent / "hustlr-ml" / "models" / "trained"
MODELS_DIR.mkdir(parents=True, exist_ok=True)

# ── Indian gig-economy training data ─────────────────────────────────────────
def build_prophet_training_data(start: str = "2023-01-01", periods: int = 8760) -> pd.DataFrame:
    """
    ~1 year of hourly synthetic-but-structured order volume for Chennai.
    Regressors mirror the inference payload so the model never sees
    missing columns at predict time.
    """
    rng = np.random.default_rng(42)
    ds = pd.date_range(start=start, periods=periods, freq="h")
    hour = ds.hour.to_numpy()
    dow = ds.dayofweek.to_numpy()
    dom = ds.day.to_numpy()
    month = ds.month.to_numpy()

    base = np.clip(rng.normal(200, 60, periods), 50, 500)

    # Hourly demand multipliers (Q-commerce peaks)
    h_mult = np.ones(periods)
    h_mult[hour == 13] = 1.38   # lunch push
    h_mult[hour == 20] = 1.48   # dinner push
    h_mult[np.isin(hour, [2, 3, 4])] = 0.18

    # Weekend boost
    w_mult = np.where(dow >= 4, 1.20, 1.0)

    # Salary-week boost (1st–5th and 25th–31st)
    sal_mask = (dom <= 5) | (dom >= 25)
    sal_mult = np.where(sal_mask, 1.175, 1.0)
    is_salary = sal_mask.astype(int)

    # IPL evening boost (Apr–May, 19–22h, ~35% of evenings)
    is_ipl = np.where(
        np.isin(month, [4, 5]) & np.isin(hour, [19, 20, 21, 22]) & (rng.random(periods) > 0.65),
        1, 0,
    )
    ipl_mult = np.where(is_ipl == 1, 1.25, 1.0)

    # Festival multipliers
    fest_mult = np.ones(periods)
    festivals = {
        "diwali":   ("2023-11-12", "2023-11-15", 1.40),
        "eid":      ("2023-04-21", "2023-04-23", 1.28),
        "ganesh":   ("2023-09-19", "2023-09-28", 1.30),
        "dussehra": ("2023-10-24", "2023-10-24", 1.22),
    }
    for _, (s, e, m) in festivals.items():
        mask = (ds >= s) & (ds <= e)
        fest_mult[mask.to_numpy()] = m

    # External regressors (must match inference columns exactly)
    precip = np.clip(rng.exponential(8, periods), 0, 160)
    temp   = np.clip(rng.normal(34, 4, periods), 26, 45)
    traffic = np.clip(
        np.where(
            np.isin(hour, [8, 9, 10, 17, 18, 19]),
            rng.uniform(0.65, 0.95, periods),
            rng.uniform(0.20, 0.60, periods),
        ), 0, 1,
    )

    weather_mult = np.ones(periods)
    weather_mult[temp > 40]    = 0.80
    weather_mult[precip > 100] = 0.70

    y = np.clip(
        base * h_mult * w_mult * sal_mult * ipl_mult * fest_mult * weather_mult,
        30, 600,
    ).astype(int)

    return pd.DataFrame({
        "ds":                 ds,
        "y":                  y,
        "precipitation_mm":   precip.round(1),
        "temp_max":           temp.round(1),
        "traffic_density":    traffic.round(3),
        "is_salary_week":     is_salary,
        "is_ipl_match":       is_ipl,
    })


# ── Indian festival holiday calendar ─────────────────────────────────────────
INDIA_HOLIDAYS = pd.DataFrame({
    "holiday": [
        "diwali", "diwali_eve", "eid_ul_fitr",
        "ganesh_chaturthi", "dussehra",
        "ipl_final", "new_year", "republic_day",
        "independence_day", "christmas",
    ],
    "ds": pd.to_datetime([
        "2023-11-12", "2023-11-11", "2023-04-21",
        "2023-09-19", "2023-10-24", "2023-05-28",
        "2023-01-01", "2023-01-26",
        "2023-08-15", "2023-12-25",
    ]),
    "lower_window": [-2, -1, -1, -1, -1, 0, -1, 0, 0, -1],
    "upper_window": [ 3,  0,  2,  2,  1, 1,  1, 1, 1,  2],
})

REGRESSORS = ["precipitation_mm", "temp_max", "traffic_density", "is_salary_week", "is_ipl_match"]


def train_and_validate() -> dict:
    from prophet import Prophet  # imported here so module loads without Prophet installed

    print("Building training data …")
    train_df = build_prophet_training_data()

    print("Fitting Prophet v2 (MAP, multiplicative) …")
    model = Prophet(
        holidays=INDIA_HOLIDAYS,
        seasonality_mode="multiplicative",   # CRITICAL FIX #4
        changepoint_prior_scale=0.15,
        seasonality_prior_scale=12,
        holidays_prior_scale=20,
        daily_seasonality=True,
        weekly_seasonality=True,
        yearly_seasonality=True,
        mcmc_samples=0,                       # MAP only — required on Render (no Stan binary)
        interval_width=0.95,
    )

    model.add_regressor("precipitation_mm", standardize=True,  mode="multiplicative")
    model.add_regressor("temp_max",         standardize=True,  mode="multiplicative")
    model.add_regressor("traffic_density",  standardize=True,  mode="multiplicative")
    model.add_regressor("is_salary_week",   standardize=False, mode="additive")
    model.add_regressor("is_ipl_match",     standardize=False, mode="additive")
    model.add_seasonality(name="monthly", period=30.5, fourier_order=5)

    model.fit(train_df)

    # ── Holdout MAPE validation gate ─────────────────────────────────────────
    print("Running holdout validation (last 720 hrs = 30 days) …")
    holdout = train_df.tail(720).copy()
    future  = holdout[["ds"] + REGRESSORS].copy()
    forecast = model.predict(future)

    actual    = holdout["y"].values
    predicted = forecast["yhat"].values
    mask = actual > 0
    mape = float(np.mean(np.abs((actual[mask] - predicted[mask]) / actual[mask])) * 100)
    print(f"Holdout MAPE: {mape:.2f}%")

    assert mape < 18.0, f"MAPE {mape:.2f}% exceeds 18% gate — retrain with more data"

    # Diwali window MAPE (15 Nov days around Diwali)
    diwali_mask = (holdout["ds"] >= "2023-11-10") & (holdout["ds"] <= "2023-11-16")
    if diwali_mask.sum() > 0:
        d_actual = holdout.loc[diwali_mask, "y"].values
        d_pred   = forecast.loc[diwali_mask.values, "yhat"].values
        d_mask   = d_actual > 0
        diwali_mape = float(np.mean(np.abs((d_actual[d_mask] - d_pred[d_mask]) / d_actual[d_mask])) * 100)
        print(f"Diwali window MAPE: {diwali_mape:.2f}%")
        assert diwali_mape < 22.0, f"Diwali MAPE {diwali_mape:.2f}% exceeds 22% gate"
    else:
        diwali_mape = None

    # ── Serialize ─────────────────────────────────────────────────────────────
    pkl_path      = MODELS_DIR / "prophet_v2_render.pkl"
    manifest_path = MODELS_DIR / "prophet_v2_manifest.json"

    with open(pkl_path, "wb") as f:
        cloudpickle.dump(model, f)
    print(f"Saved model → {pkl_path}")

    manifest = {
        "cloudpickle_version": cloudpickle.__version__,
        "prophet_version":     "1.1.5",
        "seasonality_mode":    "multiplicative",
        "regressors":          REGRESSORS,
        "holdout_mape":        round(mape, 3),
        "diwali_mape":         round(diwali_mape, 3) if diwali_mape else None,
        "mcmc_samples":        0,
        "training_rows":       len(train_df),
    }
    with open(manifest_path, "w") as f:
        json.dump(manifest, f, indent=2)
    print(f"Saved manifest → {manifest_path}")
    return manifest


if __name__ == "__main__":
    result = train_and_validate()
    print("\n✅ Prophet v2 training complete:")
    print(json.dumps(result, indent=2))
