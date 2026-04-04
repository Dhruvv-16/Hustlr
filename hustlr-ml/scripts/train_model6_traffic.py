"""
Train traffic classifier from traffic_accidents.csv (all Chennai zones × corridors).
Feature order matches hustlr-backend/ml_service/main.py classify_traffic (6 dims).
"""

import joblib
from pathlib import Path

import numpy as np
import pandas as pd
from sklearn.metrics import accuracy_score
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from xgboost import XGBClassifier

PROJECT_ROOT = Path(__file__).parent.parent.parent
MODELS_DIR = PROJECT_ROOT / "outputs" / "trained_models"
TRAFFIC_CSV = PROJECT_ROOT / "hustlr-ml" / "outputs" / "datasets" / "traffic_accidents.csv"

TRAFFIC_FEAT = [
    "congestion_probability",
    "speed_pct_drop",
    "accident_duration_min",
    "news_confidence",
    "is_peak_hour",
    "is_weekend",
]

BASELINE_FEAT = ["is_peak_hour", "is_weekend", "hour", "month"]


def train_traffic_model():
    MODELS_DIR.mkdir(parents=True, exist_ok=True)
    print("Training Model 6 — Traffic (from traffic_accidents.csv)")

    if not TRAFFIC_CSV.is_file():
        raise FileNotFoundError(f"Missing dataset: {TRAFFIC_CSV}")

    df = pd.read_csv(TRAFFIC_CSV)
    for c in TRAFFIC_FEAT + ["blockspot_classification", "hour", "date"]:
        if c not in df.columns:
            raise ValueError(f"traffic_accidents.csv missing column: {c}")

    dt = pd.to_datetime(df["date"], errors="coerce")
    df["month"] = dt.dt.month.fillna(6).astype(int)

    df = df.dropna(subset=TRAFFIC_FEAT + ["blockspot_classification"])
    df = df.reset_index(drop=True)

    max_rows = 120_000
    if len(df) > max_rows:
        # Evenly spaced indices across the timeline — real rows only, deterministic (no RNG).
        step = len(df) / max_rows
        take = (np.arange(max_rows, dtype=np.float64) * step).astype(np.int64)
        take = np.clip(take, 0, len(df) - 1)
        df_fit = df.iloc[take].reset_index(drop=True)
        print(f"Subsampled {max_rows} rows for training (of {len(df)}), evenly spaced by time order")
    else:
        df_fit = df

    X = df_fit[TRAFFIC_FEAT].astype(float).values
    le = LabelEncoder()
    y = le.fit_transform(df_fit["blockspot_classification"].astype(str))

    X_tr, X_te, y_tr, y_te = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )

    xgb_traffic = XGBClassifier(
        n_estimators=200,
        max_depth=4,
        learning_rate=0.06,
        subsample=0.8,
        random_state=42,
        tree_method="hist",
        n_jobs=-1,
        device="cpu",
        objective="multi:softprob",
        num_class=len(le.classes_),
    )
    xgb_traffic.fit(X_tr, y_tr)
    print(f"Test Accuracy: {accuracy_score(y_te, xgb_traffic.predict(X_te)):.4f}")
    print(f"Zones in source data: {df['zone'].nunique()}")

    X_base = df_fit[BASELINE_FEAT].astype(float).values
    y_base = (df_fit["congestion_probability"].astype(float) > 0.60).astype(int)
    X_tr_b, _, y_tr_b, _ = train_test_split(
        X_base, y_base, test_size=0.2, random_state=42
    )
    xgb_baseline = XGBClassifier(
        n_estimators=120,
        max_depth=5,
        random_state=42,
        tree_method="hist",
        n_jobs=-1,
        device="cpu",
    )
    xgb_baseline.fit(X_tr_b, y_tr_b)

    xgb_traffic.save_model(MODELS_DIR / "model6_traffic_classifier.json")
    xgb_baseline.save_model(MODELS_DIR / "model6_congestion_baseline.json")
    joblib.dump(le, MODELS_DIR / "model6_label_encoder.pkl")
    joblib.dump(TRAFFIC_FEAT, MODELS_DIR / "model6_features.pkl")
    print("Saved traffic models successfully.")


if __name__ == "__main__":
    train_traffic_model()
