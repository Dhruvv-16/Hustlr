"""
Train ISS regressor — feature order must match hustlr-backend/ml_service/main.py /iss ML branch.
"""

import joblib
from pathlib import Path

import numpy as np
import pandas as pd
from sklearn.metrics import mean_absolute_error
from sklearn.model_selection import train_test_split
from xgboost import XGBRegressor

PROJECT_ROOT = Path(__file__).parent.parent.parent
MODELS_DIR = PROJECT_ROOT / "outputs" / "trained_models"
DATASETS_DIR = PROJECT_ROOT / "hustlr-ml" / "outputs" / "datasets"
WORKER_CSV = DATASETS_DIR / "worker_profiles.csv"

# Same order as main.py calculate_iss X row (after flood blending, training uses zone_flood_risk proxy).
ISS_FEATURE_NAMES = [
    "zone_flood_risk",
    "avg_daily_income",
    "disruption_freq_12mo",
    "claims_history_penalty",
    "bandh_freq_zone",
    "platform_outage_per_mo",
    "coastal_zone",
]


def train_iss_model():
    MODELS_DIR.mkdir(parents=True, exist_ok=True)
    print("Training Model 1 — ISS (XGBoost regressor)")

    if not WORKER_CSV.is_file():
        raise FileNotFoundError(f"Missing dataset: {WORKER_CSV}")

    df = pd.read_csv(WORKER_CSV)
    for c in ISS_FEATURE_NAMES:
        if c not in df.columns:
            raise ValueError(f"worker_profiles.csv missing column: {c}")
    if "iss_score" not in df.columns:
        raise ValueError("worker_profiles.csv missing iss_score target column")

    X = df[ISS_FEATURE_NAMES].astype(float).values
    y = df["iss_score"].astype(float).clip(0, 100).values

    X_tr, X_te, y_tr, y_te = train_test_split(X, y, test_size=0.2, random_state=42)

    model = XGBRegressor(
        n_estimators=300,
        max_depth=4,
        learning_rate=0.06,
        subsample=0.85,
        random_state=42,
        tree_method="hist",
        n_jobs=-1,
        device="cpu",
    )
    model.fit(X_tr, y_tr)
    pred = np.clip(model.predict(X_te), 0, 100)
    print(f"Test MAE (ISS): {mean_absolute_error(y_te, pred):.3f}")
    print(f"Workers: {len(df)} | Chennai zones: {df['zone'].nunique()}")

    joblib.dump(model, MODELS_DIR / "model1_iss_xgboost.pkl")
    joblib.dump(ISS_FEATURE_NAMES, MODELS_DIR / "model1_features.pkl")
    print(f"Saved {MODELS_DIR / 'model1_iss_xgboost.pkl'}")


if __name__ == "__main__":
    train_iss_model()
