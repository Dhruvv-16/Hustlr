"""
Train fraud stack from claims_fraud.csv (zone-level Chennai claims ledger).
No synthetic RNG rows — labels and telemetry come from the dataset.
"""

import joblib
from pathlib import Path

import numpy as np
import pandas as pd
from sklearn.ensemble import IsolationForest
from sklearn.metrics import roc_auc_score
from sklearn.preprocessing import StandardScaler
from xgboost import XGBClassifier

from model_data_utils import grouped_train_test_indices

PROJECT_ROOT = Path(__file__).parent.parent.parent
MODELS_DIR = PROJECT_ROOT / "outputs" / "trained_models"
CLAIMS_CSV = PROJECT_ROOT / "hustlr-ml" / "outputs" / "datasets" / "claims_fraud.csv"

IF_FEATURES = [
    "gps_zone_mismatch",
    "wifi_home_ssid",
    "battery_charging",
    "accelerometer_idle",
    "platform_app_inactive",
    "ip_home_match",
    "claim_latency_under30s",
    "gps_jitter_perfect",
    "barometer_mismatch",
    "hw_fingerprint_match",
    "app_install_cluster",
    "days_since_onboard",
    "zone_depth_score",
    "has_real_disruption",
    "simultaneous_zone_claims",
    "iss_score",
]


def train_fraud_model():
    MODELS_DIR.mkdir(parents=True, exist_ok=True)
    print("Training Model 3 — Fraud (from claims_fraud.csv)")

    if not CLAIMS_CSV.is_file():
        raise FileNotFoundError(f"Missing dataset: {CLAIMS_CSV}")

    df = pd.read_csv(CLAIMS_CSV)
    for c in IF_FEATURES + ["is_fraud"]:
        if c not in df.columns:
            raise ValueError(f"claims_fraud.csv missing column: {c}")

    X = df[IF_FEATURES].astype(float).values
    y = df["is_fraud"].astype(int).values

    if "worker_id" in df.columns:
        train_idx, test_idx = grouped_train_test_indices(
            df["worker_id"].astype(str),
            test_size=0.2,
            random_state=42,
        )
    else:
        raise ValueError("claims_fraud.csv must include worker_id for leakage-safe splitting")

    X_tr, X_te = X[train_idx], X[test_idx]
    y_tr, y_te = y[train_idx], y[test_idx]

    scaler = StandardScaler()
    X_tr_s = scaler.fit_transform(X_tr)
    X_te_s = scaler.transform(X_te)

    fraud_rate = float(np.mean(y_tr))
    contamination = float(np.clip(max(fraud_rate, 0.02), 0.02, 0.2))

    iso = IsolationForest(
        n_estimators=200,
        contamination=contamination,
        max_features=0.75,
        random_state=42,
    )
    iso.fit(X_tr_s)

    xgb_clf = XGBClassifier(
        n_estimators=200,
        max_depth=3,
        learning_rate=0.05,
        subsample=0.7,
        random_state=42,
        tree_method="hist",
        n_jobs=-1,
        device="cpu",
    )
    xgb_clf.fit(X_tr_s, y_tr)

    train_auc = roc_auc_score(y_tr, xgb_clf.predict_proba(X_tr_s)[:, 1])
    test_auc = roc_auc_score(y_te, xgb_clf.predict_proba(X_te_s)[:, 1])
    print(f"Train AUC: {train_auc:.4f}")
    print(f"Test AUC:  {test_auc:.4f}")
    print(
        f"Rows: {len(df)} | workers: {df['worker_id'].nunique()} | "
        f"zones: {df['zone'].nunique()} | fraud rate: {fraud_rate:.3f}"
    )

    joblib.dump(iso, MODELS_DIR / "model3_isolation_forest.pkl")
    xgb_clf.save_model(MODELS_DIR / "model3_fraud_classifier.json")
    joblib.dump(scaler, MODELS_DIR / "model3_scaler.pkl")
    joblib.dump(IF_FEATURES, MODELS_DIR / "model3_features.pkl")
    print("Saved fraud models successfully.")


if __name__ == "__main__":
    train_fraud_model()
