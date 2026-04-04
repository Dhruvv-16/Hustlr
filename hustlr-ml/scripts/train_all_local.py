"""
Train all local models into repo_root/outputs/trained_models.
Run from anywhere: python hustlr-ml/scripts/train_all_local.py
"""

import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent.parent
SCRIPTS = Path(__file__).resolve().parent

STEPS = [
    "train_model1_iss.py",
    "train_model3_fraud.py",
    "train_model4_nlp.py",
    "train_model5_blackout.py",
    "train_model6_traffic.py",
    "train_model7_prophet.py",
]


def main() -> int:
    for name in STEPS:
        path = SCRIPTS / name
        print(f"\n=== {name} ===\n")
        r = subprocess.run([sys.executable, str(path)], cwd=str(REPO))
        if r.returncode != 0:
            print(f"FAILED: {name} (exit {r.returncode})", file=sys.stderr)
            return r.returncode
    print("\nAll training steps finished.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
