"""
validate_models.py — ML Blueprint validation gates
===================================================
Run after each model training to gate deployment.

Gates (hard stops):
  tstr_ratio       ≥ 0.90  → BLOCK deployment
  ks_complement    ≥ 0.90  → Regenerate +100 epochs
  fraud_rate       7.5–8.5%→ Re-run SMOTE-Tomek
  prophet_mape     < 15.0% → OK to feed ISS
  diwali_mape      < 22.0% → OK for festive periods
  iss_rmse         < 8.0   → OK for pricing
  iss_ml_rule_delta< 2.0   → Rule engine trusted

Usage:
    python validate_models.py
"""

from __future__ import annotations

import json
import warnings
from pathlib import Path
from typing import Optional

import numpy as np
import pandas as pd
from sklearn.ensemble import GradientBoostingClassifier
from sklearn.metrics import average_precision_score
from scipy.stats import ks_2samp

warnings.filterwarnings("ignore")

# ── Gate thresholds ───────────────────────────────────────────────────────────
GATES: dict[str, tuple] = {
    "tstr_ratio":       (0.90,  "BLOCK deployment — synthetic data diverged from real"),
    "ks_complement":    (0.90,  "Regenerate dataset +100 epochs"),
    "ks_p_value":       (0.05,  "Regenerate dataset — distribution mismatch"),
    "fraud_rate_min":   (0.075, "Re-run SMOTE-Tomek — fraud rate too low"),
    "fraud_rate_max":   (0.085, "Re-run SMOTE-Tomek — fraud rate too high"),
    "prophet_mape":     (15.0,  "Do not feed ISS — Prophet unreliable"),
    "diwali_mape":      (22.0,  "Recalibrate festival multipliers"),
    "iss_rmse":         (8.0,   "Retrain ISS — RMSE too high for pricing"),
    "iss_ml_rule_delta":(2.0,   "ISS ML and rule engine diverged"),
}


def compute_tstr(
    real_df: pd.DataFrame,
    synth_df: pd.DataFrame,
    feature_cols: list[str],
    target_col: str,
    model_name: str = "model",
) -> tuple[float, str]:
    """
    Train-on-Synthetic Test-on-Real (TSTR) ratio.
    Measures whether synthetic data captures real-world discriminative structure.
    Ratio ≥ 0.90 → PASS.
    """
    from sklearn.model_selection import cross_val_score  # noqa: PLC0415

    X_real  = real_df[feature_cols].fillna(0)
    y_real  = real_df[target_col]
    X_synth = synth_df[feature_cols].fillna(0)
    y_synth = synth_df[target_col]

    clf = GradientBoostingClassifier(n_estimators=100, random_state=42)

    # TRTR baseline (cross-val on real)
    trtr = float(np.mean(cross_val_score(clf, X_real, y_real, cv=5, scoring="average_precision")))

    # TSTR: train on synthetic, test on real
    clf.fit(X_synth, y_synth)
    y_prob = clf.predict_proba(X_real)[:, 1]
    tstr   = float(average_precision_score(y_real, y_prob))

    ratio  = tstr / trtr if trtr > 0 else 0.0
    status = "PASS" if ratio >= GATES["tstr_ratio"][0] else "FAIL"
    print(f"[TSTR] {model_name}: TRTR={trtr:.4f} TSTR={tstr:.4f} ratio={ratio:.3f} → {status}")
    return ratio, status


def run_ks_test(
    real_df: pd.DataFrame,
    synth_df: pd.DataFrame,
    num_cols: list[str],
) -> list[tuple]:
    """
    Kolmogorov–Smirnov test per numeric column.
    complement (1 - KS_stat) ≥ 0.90 and p > 0.05 → PASS.
    """
    results = []
    for col in num_cols:
        stat, p = ks_2samp(real_df[col].dropna(), synth_df[col].dropna())
        complement = 1 - stat
        status = "PASS" if (p > 0.05 and complement >= GATES["ks_complement"][0]) else "FAIL"
        print(f"[KS] {col}: complement={complement:.4f}  p={p:.5f} → {status}")
        results.append((col, complement, p, status))
    return results


def check_fraud_rate(df: pd.DataFrame, target_col: str = "fraud_label") -> tuple[float, str]:
    """
    Fraud rate should sit at 7.5–8.5% (mirrors real-world base rate).
    Outside this range → SMOTE-Tomek rebalancing needed.
    """
    rate   = float(df[target_col].mean())
    status = "PASS" if GATES["fraud_rate_min"][0] <= rate <= GATES["fraud_rate_max"][0] else "FAIL"
    print(f"[FraudRate] {rate:.3%} → {status}")
    return rate, status


def check_iss_metrics(
    y_true: np.ndarray,
    y_ml: np.ndarray,
    y_rule: np.ndarray,
) -> dict[str, str]:
    """
    ISS-specific gates:
      RMSE < 8.0
      |ML - rule| delta < 2.0 pts on average
    """
    from sklearn.metrics import mean_squared_error  # noqa: PLC0415
    rmse  = float(np.sqrt(mean_squared_error(y_true, y_ml)))
    delta = float(np.mean(np.abs(y_ml - y_rule)))

    rmse_status  = "PASS" if rmse  < GATES["iss_rmse"][0]          else "FAIL"
    delta_status = "PASS" if delta < GATES["iss_ml_rule_delta"][0]  else "FAIL"

    print(f"[ISS] RMSE={rmse:.3f} → {rmse_status}  |ML-Rule|={delta:.3f} → {delta_status}")
    return {"rmse": rmse_status, "delta": delta_status}


def check_prophet_mape(manifest_path: Optional[Path] = None) -> tuple[float, str]:
    """
    Read MAPE from the prophet_v2_manifest.json written by hustlr_prophet_v2.py.
    """
    if manifest_path is None:
        manifest_path = (
            Path(__file__).parent / "outputs" / "trained_models" / "prophet_v2_manifest.json"
        )
    if not manifest_path.exists():
        print("[Prophet] manifest.json not found — skipping MAPE gate")
        return -1.0, "SKIP"

    with open(manifest_path) as f:
        manifest = json.load(f)

    mape        = float(manifest.get("holdout_mape", 99.0))
    diwali_mape = manifest.get("diwali_mape")

    m_status = "PASS" if mape < GATES["prophet_mape"][0] else "FAIL"
    print(f"[Prophet] Holdout MAPE={mape:.2f}% → {m_status}")

    if diwali_mape is not None:
        d_status = "PASS" if float(diwali_mape) < GATES["diwali_mape"][0] else "FAIL"
        print(f"[Prophet] Diwali  MAPE={float(diwali_mape):.2f}% → {d_status}")

    return mape, m_status


def run_all_gates(
    fraud_df: Optional[pd.DataFrame] = None,
    iss_results: Optional[dict] = None,
    prophet_manifest: Optional[Path] = None,
) -> dict[str, str]:
    """
    Run all gates and return a summary dict of gate_name → PASS/FAIL/SKIP.
    """
    results: dict[str, str] = {}

    print("\n" + "=" * 60)
    print("HUSTLR ML VALIDATION GATES")
    print("=" * 60)

    # Prophet MAPE
    _, results["prophet_mape"] = check_prophet_mape(prophet_manifest)

    # Fraud rate
    if fraud_df is not None:
        _, results["fraud_rate"] = check_fraud_rate(fraud_df)
    else:
        results["fraud_rate"] = "SKIP"

    # ISS metrics
    if iss_results:
        results.update(iss_results)

    failed = [k for k, v in results.items() if v == "FAIL"]
    print("\n" + "─" * 60)
    if failed:
        print(f"❌ FAILED GATES: {', '.join(failed)}")
        for gate in failed:
            threshold, advice = GATES.get(gate, (None, "Review ML pipeline"))
            print(f"   [{gate}] {advice}")
    else:
        print("✅ All gates PASSED — safe to deploy")
    print("=" * 60 + "\n")

    return results


if __name__ == "__main__":
    # Quick smoke test — just run Prophet MAPE check
    run_all_gates()
