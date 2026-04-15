import numpy as np
import pandas as pd
import joblib
from pathlib import Path
from sklearn.ensemble import IsolationForest
from xgboost import XGBClassifier
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import roc_auc_score, accuracy_score, classification_report

PROJECT_ROOT = Path(__file__).parent.parent.parent
MODELS_DIR   = PROJECT_ROOT / "outputs" / "trained_models"
MODELS_DIR.mkdir(parents=True, exist_ok=True)

def train_fraud_model():
    print("Training Model 3 — Fraud Detection / Isolation Forest")
    np.random.seed(42)
    N = 20_000
    fraud_rate = 0.04
    is_fraud = (np.random.rand(N) < fraud_rate).astype(int)

    def noisy(val, noise=0.15): return np.clip(np.random.normal(val, noise), 0, 1)

    gps_zone_mismatch      = np.where(is_fraud==1, np.random.binomial(1, 0.62, N), np.random.binomial(1, 0.05, N))
    wifi_home_ssid         = np.where(is_fraud==1, np.random.binomial(1, 0.55, N), np.random.binomial(1, 0.06, N))
    battery_charging       = np.where(is_fraud==1, np.random.binomial(1, 0.48, N), np.random.binomial(1, 0.10, N))
    accelerometer_idle     = np.where(is_fraud==1, np.random.binomial(1, 0.75, N), np.random.binomial(1, 0.08, N))
    platform_app_inactive  = np.where(is_fraud==1, np.random.binomial(1, 0.65, N), np.random.binomial(1, 0.10, N))
    ip_home_match          = np.where(is_fraud==1, np.random.binomial(1, 0.58, N), np.random.binomial(1, 0.05, N))
    claim_latency_under30s = np.where(is_fraud==1, np.random.binomial(1, 0.72, N), np.random.binomial(1, 0.10, N))
    gps_jitter_perfect     = np.where(is_fraud==1, np.random.binomial(1, 0.45, N), np.random.binomial(1, 0.08, N))
    barometer_mismatch     = np.where(is_fraud==1, np.random.binomial(1, 0.40, N), np.random.binomial(1, 0.07, N))
    hw_fingerprint_match   = np.where(is_fraud==1, np.random.binomial(1, 0.38, N), np.random.binomial(1, 0.88, N))
    app_install_cluster    = np.where(is_fraud==1, np.random.binomial(1, 0.50, N), np.random.binomial(1, 0.08, N))

    days_since_onboard        = np.where(is_fraud==1, np.random.randint(0, 45, N), np.random.randint(30, 600, N))
    simultaneous_zone_claims  = np.where(is_fraud==1, np.random.poisson(8, N), np.random.poisson(1, N))
    zone_depth_score = np.where(is_fraud==1, np.random.uniform(0.1, 0.6, N), np.random.uniform(0.5, 1.0, N))
    
    has_real_disruption = np.random.binomial(1, 0.12, N)
    is_fraud = np.where((has_real_disruption == 1) & (is_fraud == 1), np.random.binomial(1, 0.3, N), is_fraud)
    
    iss_score = np.clip(np.random.uniform(30, 100, N) - is_fraud * 15, 0, 100)
    is_fraud_noisy = np.where(np.random.rand(N) < 0.02, 1 - is_fraud, is_fraud)

    IF_FEATURES = [
        "gps_zone_mismatch", "wifi_home_ssid", "battery_charging",
        "accelerometer_idle", "platform_app_inactive", "ip_home_match",
        "claim_latency_under30s", "gps_jitter_perfect", "barometer_mismatch",
        "hw_fingerprint_match", "app_install_cluster",
        "days_since_onboard", "zone_depth_score", "has_real_disruption",
        "simultaneous_zone_claims", "iss_score",
    ]

    df = pd.DataFrame(dict(zip(IF_FEATURES + ["is_fraud"], 
        [gps_zone_mismatch, wifi_home_ssid, battery_charging, accelerometer_idle, 
         platform_app_inactive, ip_home_match, claim_latency_under30s, gps_jitter_perfect, 
         barometer_mismatch, hw_fingerprint_match, app_install_cluster, days_since_onboard, 
         zone_depth_score, has_real_disruption, simultaneous_zone_claims, iss_score, is_fraud_noisy])))

    X, y = df[IF_FEATURES].values, df["is_fraud"].values
    split_idx = int(0.75 * N)
    X_tr, X_te, y_tr, y_te = X[:split_idx], X[split_idx:], y[:split_idx], y[split_idx:]

    scaler = StandardScaler()
    X_tr_s = scaler.fit_transform(X_tr)
    X_te_s = scaler.transform(X_te)

    iso = IsolationForest(n_estimators=200, contamination=0.04, max_features=0.75, random_state=42)
    iso.fit(X_tr_s)

    xgb_clf = XGBClassifier(
        n_estimators=200, 
        max_depth=3, 
        learning_rate=0.05, 
        subsample=0.7, 
        random_state=42,
        tree_method='hist',
        device='cuda'  # Enable lightning-fast GPU training
    )
    xgb_clf.fit(X_tr_s, y_tr)

    print(f"Test AUC (CUDA): {roc_auc_score(y_te, xgb_clf.predict_proba(X_te_s)[:, 1]):.4f}")
    
    joblib.dump(iso, MODELS_DIR / "model3_isolation_forest.pkl")
    # Save natively as xgboost json to ensure CUDA optimizations stay intact
    xgb_clf.save_model(MODELS_DIR / "model3_fraud_classifier.json")
    joblib.dump(scaler, MODELS_DIR / "model3_scaler.pkl")
    joblib.dump(IF_FEATURES, MODELS_DIR / "model3_features.pkl")
    print("Saved fraud models successfully.")

if __name__ == "__main__":
    train_fraud_model()
