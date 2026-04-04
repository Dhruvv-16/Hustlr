"""
Train one Prophet model per zone in prophet_training.csv (full Chennai grid in datasets).
Output files: model7_prophet_{zone_slug}.pkl — slugs match GET /forecast/{zone} normalization in main.py.
"""

import joblib
from pathlib import Path

import numpy as np
import pandas as pd

PROJECT_ROOT = Path(__file__).parent.parent.parent
MODELS_DIR = PROJECT_ROOT / "outputs" / "trained_models"
PROPHET_CSV = PROJECT_ROOT / "hustlr-ml" / "outputs" / "datasets" / "prophet_training.csv"


def zone_file_slug(zone: str) -> str:
    return zone.strip().lower().replace(" ", "_").replace("-", "_")


def build_target(sub: pd.DataFrame) -> pd.Series:
    """Blend sparse binary disruption flags from the ledger (real columns, not RNG)."""
    y_raw = sub["y"].astype(float)
    heavy = sub["heavy_rain"].astype(float) if "heavy_rain" in sub.columns else 0.0
    extreme = sub["extreme_rain"].astype(float) if "extreme_rain" in sub.columns else 0.0
    bandh = sub["bandh_event"].astype(float) if "bandh_event" in sub.columns else 0.0
    roll = sub["rolling_7d"].astype(float) if "rolling_7d" in sub.columns else 0.0
    return np.clip(
        y_raw + 0.10 * heavy + 0.18 * extreme + 0.07 * bandh + 0.05 * roll,
        0.0,
        1.0,
    )


def train_prophet_all_zones():
    MODELS_DIR.mkdir(parents=True, exist_ok=True)

    if not PROPHET_CSV.is_file():
        raise FileNotFoundError(f"Missing dataset: {PROPHET_CSV}")

    try:
        from prophet import Prophet
    except ImportError as e:
        raise ImportError("Install prophet: pip install prophet") from e

    df = pd.read_csv(PROPHET_CSV)
    if "zone" not in df.columns or "ds" not in df.columns:
        raise ValueError("prophet_training.csv needs zone and ds columns")

    zones = sorted(df["zone"].astype(str).str.strip().unique())
    print(f"Training Model 7 — Prophet for {len(zones)} Chennai zones")

    for zone_name in zones:
        sub = df[df["zone"].astype(str).str.strip() == zone_name].copy()
        sub["ds"] = pd.to_datetime(sub["ds"])
        sub["y"] = build_target(sub)
        fit_df = sub[["ds", "y"]].sort_values("ds").drop_duplicates(subset=["ds"], keep="last")
        fit_df = fit_df.dropna()
        if len(fit_df) < 30:
            print(f"  skip {zone_name}: only {len(fit_df)} rows")
            continue

        m = Prophet(
            daily_seasonality=True,
            weekly_seasonality=True,
            yearly_seasonality=True,
            changepoint_prior_scale=0.05,
        )
        m.fit(fit_df)

        slug = zone_file_slug(zone_name)
        out = MODELS_DIR / f"model7_prophet_{slug}.pkl"
        joblib.dump(m, out)
        print(f"  saved {out.name} ({len(fit_df)} days)")

    print("Prophet training finished.")


if __name__ == "__main__":
    train_prophet_all_zones()
