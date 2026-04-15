import numpy as np
import pandas as pd
import joblib
from pathlib import Path
from xgboost import XGBClassifier
from sklearn.preprocessing import LabelEncoder
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score

PROJECT_ROOT = Path(__file__).parent.parent.parent
MODELS_DIR   = PROJECT_ROOT / "outputs" / "trained_models"
MODELS_DIR.mkdir(parents=True, exist_ok=True)

def train_traffic_model():
    print("Training Model 6 — Traffic / Accident Classifier")
    np.random.seed(42)
    N = 15_000

    hour       = np.random.randint(0, 24, N)
    is_peak    = np.isin(hour, [8, 9, 10, 17, 18, 19, 20]).astype(int)
    is_weekend = (np.random.randint(0, 7, N) >= 5).astype(int)
    month      = np.random.randint(1, 13, N)
    is_monsoon = np.isin(month, [10, 11, 12]).astype(int)

    baseline_speed = np.where(is_peak, np.random.uniform(15, 35, N), np.random.uniform(30, 60, N))
    accident_severity = np.random.choice([0, 1, 2], N, p=[0.70, 0.22, 0.08])
    current_speed = np.clip(baseline_speed - accident_severity * np.random.uniform(5, 25, N), 2, 80)
    
    speed_pct_drop = (baseline_speed - current_speed) / baseline_speed
    duration_min   = np.random.exponential(scale=25, size=N).clip(5, 180)

    news_confidence = np.where(accident_severity == 2, np.random.beta(6, 2, N), 
                      np.where(accident_severity == 1, np.random.beta(3, 4, N), np.random.beta(1, 6, N))).clip(0, 1)

    base_congestion = np.where(is_peak & ~is_weekend, 0.60, 0.25)
    congestion_prob = np.clip(base_congestion + np.random.normal(0, 0.12, N), 0, 1)

    classification = np.where(
        (congestion_prob > 0.80) & (accident_severity < 2), "NORMAL_CONGESTION",
        np.where((news_confidence >= 0.60) & (duration_min >= 30) & (accident_severity >= 1), "ACCIDENT_BLOCKSPOT", "INCONCLUSIVE")
    )

    traffic_df = pd.DataFrame({
        "hour": hour, "is_peak_hour": is_peak, "is_weekend": is_weekend, "month": month, "is_monsoon": is_monsoon,
        "baseline_speed_kmh": baseline_speed, "current_speed_kmh": current_speed, "speed_pct_drop": speed_pct_drop,
        "accident_duration_min": duration_min, "news_confidence": news_confidence, "congestion_probability": congestion_prob,
        "blockspot_label": classification,
    })

    TRAFFIC_FEAT = ["current_speed_kmh", "speed_pct_drop", "news_confidence", "accident_duration_min", "is_peak_hour", "is_weekend", "is_monsoon", "hour"]
    
    le = LabelEncoder()
    y = le.fit_transform(classification)
    X = traffic_df[TRAFFIC_FEAT].values

    X_tr, X_te, y_tr, y_te = train_test_split(X, y, test_size=0.2, stratify=y, random_state=42)

    xgb_traffic = XGBClassifier(
        n_estimators=200, 
        max_depth=3, 
        learning_rate=0.05, 
        subsample=0.75, 
        random_state=42,
        tree_method='hist',
        device='cuda',
        objective='multi:softprob',
        num_class=len(le.classes_)
    )
    xgb_traffic.fit(X_tr, y_tr)

    print(f"Test Accuracy (CUDA): {accuracy_score(y_te, xgb_traffic.predict(X_te)):.4f}")

    baseline_feat = ["is_peak_hour", "is_weekend", "hour", "is_monsoon"]
    y_base = (congestion_prob > 0.60).astype(int)
    X_base = traffic_df[baseline_feat].values
    X_tr_b, _, y_tr_b, _ = train_test_split(X_base, y_base, test_size=0.2, random_state=42)
    
    xgb_baseline = XGBClassifier(
        n_estimators=100, 
        max_depth=5, 
        random_state=42,
        tree_method='hist',
        device='cuda'
    )
    xgb_baseline.fit(X_tr_b, y_tr_b)

    xgb_traffic.save_model(MODELS_DIR / "model6_traffic_classifier.json")
    xgb_baseline.save_model(MODELS_DIR / "model6_congestion_baseline.json")
    joblib.dump(le, MODELS_DIR / "model6_label_encoder.pkl")
    joblib.dump(TRAFFIC_FEAT, MODELS_DIR / "model6_features.pkl")
    print("Saved traffic models successfully.")

if __name__ == "__main__":
    train_traffic_model()
