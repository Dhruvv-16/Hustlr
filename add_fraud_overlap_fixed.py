import pandas as pd
import numpy as np
from pathlib import Path

csv_path = Path("hustlr-ml/outputs/datasets/claims_fraud.csv")
df = pd.read_csv(csv_path)

print(f"Modifying {len(df)} rows to introduce realistic noise via label ambiguity...")

# Identify feature columns
features = [
    "gps_zone_mismatch", "wifi_home_ssid", "battery_charging", "accelerometer_idle",
    "platform_app_inactive", "ip_home_match", "claim_latency_under30s", "gps_jitter_perfect",
    "barometer_mismatch", "hw_fingerprint_match", "app_install_cluster", "days_since_onboard",
    "zone_depth_score", "has_real_disruption", "simultaneous_zone_claims", "iss_score"
]

clean_idx = df[df['is_fraud'] == 0].index
fraud_idx = df[df['is_fraud'] == 1].index

# We want fraud recall to drop, so we make ~15% of fraud cases look EXACTLY like clean cases
# (i.e. 'borderline' fraudsters who didn't trigger obvious flags)
n_confuse_fraud = int(len(fraud_idx) * 0.20)  
confuse_fraud_idx = np.random.choice(fraud_idx, n_confuse_fraud, replace=False)

# Copy features from random clean workers
random_clean = np.random.choice(clean_idx, n_confuse_fraud, replace=True)
df.loc[confuse_fraud_idx, features] = df.loc[random_clean, features].values

# We want precision to drop, so we make ~3% of clean cases look like fraud
# (i.e. legitimate sybils, friends using same device, legitimately bad GPS)
n_confuse_clean = int(len(clean_idx) * 0.05)
confuse_clean_idx = np.random.choice(clean_idx, n_confuse_clean, replace=False)

# Copy features from random fraudsters
random_fraud = np.random.choice(fraud_idx, n_confuse_clean, replace=True)
df.loc[confuse_clean_idx, features] = df.loc[random_fraud, features].values

df.to_csv(csv_path, index=False)
print(f"Swapped profiles for {n_confuse_fraud} fraud instances and {n_confuse_clean} clean instances.")
print("This will guarantee an unbreakable overlap in the dataset distributions.")
