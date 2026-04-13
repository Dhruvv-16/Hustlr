"""
diagnose_all_models.py
======================
Evaluates ALL trained models with proper train/test splits and reports
precise metrics for each.

Models covered:
  Model 1  — ISS XGBoost Regressor
  Model 3  — Fraud Isolation Forest + XGBoost Classifier
  Model 4  — NLP Disruption Event Classifier
  Model 7  — Prophet Disruption Forecaster (per-zone backtesting)

Run from hustlr-ml/:
    python -X utf8 scripts/diagnose_all_models.py
"""

import warnings
warnings.filterwarnings("ignore")

import sys, os
os.environ.setdefault("PYTHONIOENCODING", "utf-8")

import joblib
import numpy as np
import pandas as pd
from pathlib import Path
from sklearn.metrics import (
    mean_absolute_error, r2_score,
    roc_auc_score, average_precision_score,
    classification_report, confusion_matrix,
)

from model_data_utils import (
    cap_group_rows,
    grouped_train_test_indices,
    month_groups,
    template_text_groups,
)

# ── Paths ──────────────────────────────────────────────────────────────────
ML_DIR      = Path(__file__).parent.parent
MODELS_DIR  = ML_DIR.parent / "outputs" / "trained_models"
DATA_DIR    = ML_DIR / "outputs" / "datasets"
RANDOM_STATE = 42

SEP = "=" * 70

def header(title):
    print(f"\n{SEP}")
    print(f"  {title}")
    print(SEP)

# ══════════════════════════════════════════════════════════════════════════════
# MODEL 1 — ISS XGBoost Regressor
# ══════════════════════════════════════════════════════════════════════════════
header("MODEL 1 — ISS XGBoost Regressor (worker_profiles.csv)")

ISS_FEATURES = joblib.load(MODELS_DIR / "model1_features.pkl")
iss_model    = joblib.load(MODELS_DIR / "model1_iss_xgboost.pkl")

df_iss = pd.read_csv(DATA_DIR / "worker_profiles.csv")
print(f"Dataset: {len(df_iss):,} rows | {df_iss['zone'].nunique()} zones")
print(f"Features: {ISS_FEATURES}")

X_iss = df_iss[ISS_FEATURES].astype(float).values
y_iss = df_iss["iss_score"].astype(float).clip(0, 100).values

iss_train_idx, iss_test_idx = grouped_train_test_indices(
    month_groups(df_iss["onboard_date"]),
    test_size=0.2,
    random_state=RANDOM_STATE,
)
X_tr, X_te = X_iss[iss_train_idx], X_iss[iss_test_idx]
y_tr, y_te = y_iss[iss_train_idx], y_iss[iss_test_idx]

pred_tr = np.clip(iss_model.predict(X_tr), 0, 100)
pred_te = np.clip(iss_model.predict(X_te), 0, 100)

mae_tr  = mean_absolute_error(y_tr, pred_tr)
mae_te  = mean_absolute_error(y_te, pred_te)
r2_tr   = r2_score(y_tr, pred_tr)
r2_te   = r2_score(y_te, pred_te)

print(f"\n{'Metric':<20} {'Train':>12} {'Test':>12}  {'Gap':>10}")
print("-" * 56)
print(f"{'MAE (points)':<20} {mae_tr:>12.3f} {mae_te:>12.3f}  {abs(mae_tr-mae_te):>10.3f}")
print(f"{'R-squared':<20} {r2_tr:>12.4f} {r2_te:>12.4f}  {abs(r2_tr-r2_te):>10.4f}")
print(f"{'Samples':<20} {len(X_tr):>12,} {len(X_te):>12,}")

# Score distribution
for split, preds, actuals in [("TRAIN", pred_tr, y_tr), ("TEST", pred_te, y_te)]:
    print(f"\n  {split} prediction distribution:")
    for lo, hi, label in [(0,30,"RED (<30)"), (30,50,"AMBER_LOW"), (50,70,"AMBER"), (70,100,"GREEN (>=70)")]:
        n = ((preds >= lo) & (preds < hi)).sum()
        print(f"    {label:<18}: predicted={n:>5}  actual={((actuals>=lo)&(actuals<hi)).sum():>5}")

if r2_te > 0.85:
    note = "Excellent — model captures ISS score variance well"
elif r2_te > 0.65:
    note = "Acceptable — some variance unaccounted for"
else:
    note = "WARNING: poor fit — check feature alignment"
print(f"\n  Verdict: {note}")

# ══════════════════════════════════════════════════════════════════════════════
# MODEL 3 — Fraud Detection (Isolation Forest + XGBoost Classifier)
# ══════════════════════════════════════════════════════════════════════════════
header("MODEL 3 — Fraud Detection (claims_fraud.csv)")

IF_FEATURES = joblib.load(MODELS_DIR / "model3_features.pkl")
iso_model   = joblib.load(MODELS_DIR / "model3_isolation_forest.pkl")
scaler      = joblib.load(MODELS_DIR / "model3_scaler.pkl")

from xgboost import XGBClassifier
xgb_fraud = XGBClassifier()
xgb_fraud.load_model(MODELS_DIR / "model3_fraud_classifier.json")

df_fraud = pd.read_csv(DATA_DIR / "claims_fraud.csv")
print(f"Dataset: {len(df_fraud):,} rows | fraud rate: {df_fraud['is_fraud'].mean():.3f} | {df_fraud['zone'].nunique()} zones")

X_f  = df_fraud[IF_FEATURES].astype(float).values
y_f  = df_fraud["is_fraud"].astype(int).values

fraud_train_idx, fraud_test_idx = grouped_train_test_indices(
    df_fraud["worker_id"].astype(str),
    test_size=0.2,
    random_state=RANDOM_STATE,
)
X_ftr, X_fte = X_f[fraud_train_idx], X_f[fraud_test_idx]
y_ftr, y_fte = y_f[fraud_train_idx], y_f[fraud_test_idx]

X_ftr_s = scaler.transform(X_ftr)
X_fte_s = scaler.transform(X_fte)

# -- XGBoost Classifier (supervised)
prob_tr = xgb_fraud.predict_proba(X_ftr_s)[:, 1]
prob_te = xgb_fraud.predict_proba(X_fte_s)[:, 1]

auc_tr = roc_auc_score(y_ftr, prob_tr)
auc_te = roc_auc_score(y_fte, prob_te)
ap_tr  = average_precision_score(y_ftr, prob_tr)
ap_te  = average_precision_score(y_fte, prob_te)

# Use 0.5 threshold for classification
pred_tr_xgb = (prob_tr >= 0.5).astype(int)
pred_te_xgb = (prob_te >= 0.5).astype(int)

cm_tr = confusion_matrix(y_ftr, pred_tr_xgb)
cm_te = confusion_matrix(y_fte, pred_te_xgb)

def cm_stats(cm):
    tn, fp, fn, tp = cm.ravel()
    rec = tp/(tp+fn) if (tp+fn) > 0 else 0
    prec = tp/(tp+fp) if (tp+fp) > 0 else 0
    f1 = 2*rec*prec/(rec+prec) if (rec+prec) > 0 else 0
    return tn, fp, fn, tp, rec, prec, f1

tn_tr, fp_tr, fn_tr, tp_tr, rec_tr, prec_tr, f1_tr = cm_stats(cm_tr)
tn_te, fp_te, fn_te, tp_te, rec_te, prec_te, f1_te = cm_stats(cm_te)

print(f"\n  XGBoost Fraud Classifier:")
print(f"  {'Metric':<22} {'Train':>10} {'Test':>10}  {'Gap':>8}")
print("  " + "-" * 52)
print(f"  {'ROC-AUC':<22} {auc_tr:>10.4f} {auc_te:>10.4f}  {abs(auc_tr-auc_te):>8.4f}")
print(f"  {'PR-AUC':<22} {ap_tr:>10.4f} {ap_te:>10.4f}  {abs(ap_tr-ap_te):>8.4f}")
print(f"  {'Recall (fraud)':<22} {rec_tr:>10.1%} {rec_te:>10.1%}")
print(f"  {'Precision (fraud)':<22} {prec_tr:>10.1%} {prec_te:>10.1%}")
print(f"  {'F1 (fraud)':<22} {f1_tr:>10.4f} {f1_te:>10.4f}")
print(f"  {'TN/FP/FN/TP (train)':<22} {tn_tr}/{fp_tr}/{fn_tr}/{tp_tr}")
print(f"  {'TN/FP/FN/TP (test)':<22}            {tn_te}/{fp_te}/{fn_te}/{tp_te}")

# -- Isolation Forest (unsupervised — evaluate against labels for reference)
iso_scores_tr = -iso_model.decision_function(X_ftr_s)  # higher = more anomalous
iso_scores_te = -iso_model.decision_function(X_fte_s)

iso_auc_tr = roc_auc_score(y_ftr, iso_scores_tr)
iso_auc_te = roc_auc_score(y_fte, iso_scores_te)

print(f"\n  Isolation Forest (unsupervised — AUC only, no threshold required):")
print(f"  {'ROC-AUC train':<22}: {iso_auc_tr:.4f}")
print(f"  {'ROC-AUC test':<22}: {iso_auc_te:.4f}")
print(f"  {'Gap':<22}: {abs(iso_auc_tr-iso_auc_te):.4f}")

# ══════════════════════════════════════════════════════════════════════════════
# MODEL 4 — NLP Disruption Event Classifier
# ══════════════════════════════════════════════════════════════════════════════
header("MODEL 4 — NLP Disruption Classifier (nlp_disruption_events.csv)")

try:
    from xgboost import XGBClassifier as XGB4
    from sklearn.feature_extraction.text import TfidfVectorizer

    tfidf     = joblib.load(MODELS_DIR / "model4_tfidf.pkl")
    label_map = joblib.load(MODELS_DIR / "model4_label_map.pkl")
    nlp_clf   = XGB4()
    nlp_clf.load_model(MODELS_DIR / "model4_rf_nlp.json")

    df_nlp = pd.read_csv(DATA_DIR / "nlp_disruption_events.csv")
    text_col = "raw_text"
    label_col = "trigger_label"
    
    print(f"Dataset: {len(df_nlp):,} rows | {df_nlp[label_col].nunique()} classes")
    print(f"Classes: {sorted(df_nlp[label_col].unique())}")

    df_nlp = df_nlp.dropna(subset=[text_col, label_col])
    df_nlp[text_col] = df_nlp[text_col].astype(str).str.strip()
    df_nlp = df_nlp[df_nlp[text_col].str.len() > 0].copy()
    df_nlp["text_group"] = template_text_groups(df_nlp[text_col], df_nlp["zone"].dropna().unique())
    df_nlp = cap_group_rows(df_nlp, "text_group", max_rows_per_group=3, random_state=RANDOM_STATE)

    X_nlp = tfidf.transform(df_nlp[text_col])
    y_nlp = df_nlp[label_col].map(label_map).fillna(-1).astype(int)
    valid  = y_nlp >= 0
    X_nlp = X_nlp[valid.values]
    y_nlp = y_nlp[valid].values
    groups = df_nlp.loc[valid.values, "text_group"]
    nlp_train_idx, nlp_test_idx = grouped_train_test_indices(
        groups,
        test_size=0.2,
        random_state=RANDOM_STATE,
    )
    X_ntr, X_nte = X_nlp[nlp_train_idx], X_nlp[nlp_test_idx]
    y_ntr, y_nte = y_nlp[nlp_train_idx], y_nlp[nlp_test_idx]

    acc_tr = (nlp_clf.predict(X_ntr) == y_ntr).mean()
    acc_te = (nlp_clf.predict(X_nte) == y_nte).mean()

    print(f"\n  {'Metric':<22} {'Train':>10} {'Test':>10}  {'Gap':>8}")
    print("  " + "-" * 52)
    print(f"  {'Accuracy':<22} {acc_tr:>10.4f} {acc_te:>10.4f}  {abs(acc_tr-acc_te):>8.4f}")
    print(f"  {'Samples':<22} {X_ntr.shape[0]:>10,} {X_nte.shape[0]:>10,}")

    if abs(acc_tr - acc_te) > 0.08:
        print("  WARNING: Train-test gap > 8% — possible overfitting or class imbalance")
    else:
        print("  Generalisation: stable")

except Exception as e:
    print(f"  SKIP — {e}")

# ══════════════════════════════════════════════════════════════════════════════
# MODEL 7 — Prophet Forecaster (backtesting: hold out last 20% of time)
# ══════════════════════════════════════════════════════════════════════════════
header("MODEL 7 — Prophet Disruption Forecaster (prophet_training.csv)")
print("  Backtest: train on first 80% of timesteps, evaluate on last 20%")
print("  Metrics: MAE, MAPE, 80% Coverage Interval Hit Rate")

try:
    df_pr = pd.read_csv(DATA_DIR / "prophet_training.csv")
    df_pr["ds"] = pd.to_datetime(df_pr["ds"])

    if "zone" in df_pr.columns and "city_type" not in df_pr.columns:
        df_pr["city_type"] = df_pr["zone"]
    elif "zone_id" in df_pr.columns and "city_type" not in df_pr.columns:
        df_pr["city_type"] = df_pr["zone_id"]

    # Evaluate on one representative zone slug per city_type
    CITY_SLUG_MAP = {
        "Chennai":   "chennai",
        "Mumbai":    "mumbai",
        "Bangalore": "bangalore",
        "Tier2":     "tier2",
        "Tier 1":    "chennai",
    }

    REGRESSORS = [c for c in ["festival_multiplier","precip_mm",
                               "temperature_c","traffic_index",
                               "salary_week_flag"] if c in df_pr.columns]

    print(f"\n  {'City':<16} {'Train rows':>10} {'Test rows':>10} {'MAE':>8} {'MAPE':>8} {'Coverage':>10}")
    print("  " + "-" * 70)

    for city_type in sorted(df_pr["city_type"].astype(str).unique()):
        slug = CITY_SLUG_MAP.get(city_type)
        pkl  = MODELS_DIR / f"model7_prophet_{slug}.pkl" if slug else None

        if not pkl or not pkl.exists():
            print(f"  {city_type:<16} -- no .pkl found, skipping")
            continue

        model = joblib.load(pkl)
        sub   = df_pr[df_pr["city_type"].astype(str) == city_type].copy()
        sub   = sub.rename(columns={"precip_mm": "precipitation_mm", "traffic_index": "traffic_profile_index"})
        
        agg_d = {"y": "mean"}
        # ensure regressors match training
        model_regs = ["festival_multiplier", "precipitation_mm", "temperature_c", "traffic_profile_index", "salary_week_flag"]
        for r in model_regs:
            if r in sub.columns:
                agg_d[r] = "mean"
                
        sub   = sub.groupby("ds").agg(agg_d).reset_index().dropna(subset=["y"])
        sub["y"] = np.log(sub["y"].clip(lower=0.1))

        if len(sub) < 50:
            print(f"  {city_type:<16} -- only {len(sub)} rows, skipping")
            continue

        split_idx = int(len(sub) * 0.8)
        test_df   = sub.iloc[split_idx:].copy()

        if len(test_df) < 5:
            print(f"  {city_type:<16} -- test split too small, skipping")
            continue

        try:
            forecast = model.predict(test_df)
            y_true   = test_df["y"].values
            y_pred   = forecast["yhat"].values
            y_lo     = forecast["yhat_lower"].values
            y_hi     = forecast["yhat_upper"].values

            mae      = mean_absolute_error(y_true, y_pred)
            mape     = np.mean(np.abs((y_true - y_pred) / (np.abs(y_true) + 1e-6))) * 100
            coverage = np.mean((y_true >= y_lo) & (y_true <= y_hi)) * 100

            print(f"  {city_type:<16} {split_idx:>10,} {len(test_df):>10,} {mae:>8.3f} {mape:>7.1f}% {coverage:>9.1f}%")

        except Exception as e:
            print(f"  {city_type:<16} -- predict failed: {e}")

    print("""
  Interpretation:
    MAE      — mean absolute error in log(disruption_units)
    MAPE     — mean absolute % error (< 20% good, < 10% excellent)
    Coverage — % of actuals within the 80% confidence interval
               (should be ~80-85% for a well-calibrated Prophet)""")

except Exception as e:
    print(f"  SKIP — {e}")

# ══════════════════════════════════════════════════════════════════════════════
# SUMMARY TABLE
# ══════════════════════════════════════════════════════════════════════════════
header("ALL MODELS — SUMMARY")
print(f"""
  Model  Name                       Key Train Metric    Key Test Metric
  ------+---------------------------+------------------+------------------
  M1     ISS XGBoost Regressor       R2 / MAE (points)   R2 / MAE (points)
  M3a    Fraud XGBoost Classifier     ROC-AUC + Recall    ROC-AUC + Recall
  M3b    Isolation Forest             ROC-AUC (ref)       ROC-AUC (ref)
  M4     NLP Disruption Classifier    Accuracy            Accuracy
  M7     Prophet Zone Forecaster      (temporal backtest) MAE + Coverage
""")
print("See individual sections above for exact numbers.\n")
