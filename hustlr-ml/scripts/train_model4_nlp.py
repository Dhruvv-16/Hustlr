"""
Train NLP classifier from nlp_disruption_events.csv (Chennai zones, dated feed text).
No hand-generated synthetic corpus — only rows from the dataset.
"""

import joblib
from pathlib import Path

import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics import accuracy_score
from sklearn.model_selection import train_test_split
from xgboost import XGBClassifier

PROJECT_ROOT = Path(__file__).parent.parent.parent
MODELS_DIR = PROJECT_ROOT / "outputs" / "trained_models"
NLP_CSV = PROJECT_ROOT / "hustlr-ml" / "outputs" / "datasets" / "nlp_disruption_events.csv"


def train_nlp_model():
    MODELS_DIR.mkdir(parents=True, exist_ok=True)
    print("Training Model 4 — NLP (from nlp_disruption_events.csv)")

    if not NLP_CSV.is_file():
        raise FileNotFoundError(f"Missing dataset: {NLP_CSV}")

    df = pd.read_csv(NLP_CSV)
    if "raw_text" not in df.columns or "trigger_label" not in df.columns:
        raise ValueError("nlp_disruption_events.csv needs raw_text and trigger_label")

    df = df.dropna(subset=["raw_text", "trigger_label"])
    df["raw_text"] = df["raw_text"].astype(str).str.strip()
    df = df[df["raw_text"].str.len() > 0]

    tfidf = TfidfVectorizer(
        max_features=4000,
        ngram_range=(1, 3),
        sublinear_tf=True,
        min_df=2,
        strip_accents="unicode",
        analyzer="word",
    )
    X = tfidf.fit_transform(df["raw_text"])
    labels = df["trigger_label"].astype(str)
    label_map = {lab: i for i, lab in enumerate(sorted(labels.unique()))}
    y_encoded = labels.map(label_map)

    # Stratify only if every class has enough samples
    counts = labels.value_counts()
    strat = y_encoded if counts.min() >= 5 else None
    X_tr, X_te, y_tr, y_te = train_test_split(
        X, y_encoded, test_size=0.2, random_state=42, stratify=strat
    )

    xgb_clf = XGBClassifier(
        n_estimators=300,
        learning_rate=0.05,
        max_depth=6,
        random_state=42,
        n_jobs=-1,
        tree_method="hist",
        device="cpu",
        objective="multi:softprob",
        num_class=len(label_map),
    )
    xgb_clf.fit(X_tr, y_tr)

    print(f"Test Accuracy: {accuracy_score(y_te, xgb_clf.predict(X_te)):.4f}")
    print(f"Rows: {len(df)} | zones: {df['zone'].nunique()} | labels: {list(label_map.keys())}")

    joblib.dump(label_map, MODELS_DIR / "model4_label_map.pkl")
    xgb_clf.save_model(MODELS_DIR / "model4_rf_nlp.json")
    joblib.dump(tfidf, MODELS_DIR / "model4_tfidf.pkl")
    print("Saved NLP model successfully.")


if __name__ == "__main__":
    train_nlp_model()
