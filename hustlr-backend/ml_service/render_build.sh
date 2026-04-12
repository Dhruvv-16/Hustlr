#!/bin/bash
# render_build.sh — Hustlr ML service build script
# ==================================================
# Fixes Prophet FAILURE 2: Stan binary must be compiled at build time.
# Render ephemeral filesystem means Stan compiles fresh each deploy.
#
# Set in Render Dashboard:
#   Settings → Build Command → bash render_build.sh
#   Environment Variables:
#     STAN_BACKEND=CMDSTANPY
#     PROPHET_STAN_BACKEND=CMDSTANPY
#     CMDSTAN=/opt/render/.cmdstan

set -e

echo "=== Hustlr ML Build ==="
echo "Python: $(python --version)"

pip install --upgrade pip
pip install -r requirements.txt

echo "=== Pre-compiling Stan model (Prophet FAILURE 2 fix) ==="
python -c "
from prophet import Prophet
import pandas as pd, numpy as np

# Minimal fit to force Stan binary compilation
df = pd.DataFrame({
    'ds': pd.date_range('2024-01-01', periods=30, freq='D'),
    'y': np.clip(np.random.default_rng(42).normal(200, 40, 30), 50, 500)
})
m = Prophet(mcmc_samples=0)
m.fit(df)
print('Stan model compiled successfully.')
"

echo "=== Build complete ==="
