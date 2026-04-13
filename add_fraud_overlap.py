import pandas as pd
import numpy as np
from pathlib import Path

csv_path = Path("hustlr-ml/outputs/datasets/claims_fraud.csv")
df = pd.read_csv(csv_path)

print(f"Modifying {len(df)} rows to introduce realistic noise...")

# 1. Type 1: GPS Spoofer overlap
# Some legitimate workers have good GPS (gps_jitter_perfect is high)
# Some fraudsters fail to spoof perfectly (gps_jitter_perfect is low)
df['gps_jitter_perfect'] = df['gps_jitter_perfect'].astype(float)
df['zone_depth_score'] = df['zone_depth_score'].astype(float)
df['claim_latency_under30s'] = df['claim_latency_under30s'].astype(float)
df['hw_fingerprint_match'] = df['hw_fingerprint_match'].astype(float)

mask_clean = df['is_fraud'] == 0
mask_fraud = df['is_fraud'] == 1

n_clean = mask_clean.sum()
n_fraud = mask_fraud.sum()

rng = np.random.default_rng(42)

# Fraudsters (spoofers) typically have 1.0 jitter_perfect. 30% look normal (exponential distribution).
fraud_jitter = np.where(
    rng.random(n_fraud) < 0.70,
    np.ones(n_fraud),  # Perfect 1.0 for spoofers
    np.clip(rng.exponential(scale=0.3, size=n_fraud), 0, 1)  # Messy (0-0.5 mostly)
)
df.loc[mask_fraud, 'gps_jitter_perfect'] = fraud_jitter

# Clean workers typically have high jitter, but 10% happen to have perfectly clean connections (false positives)
clean_jitter = np.where(
    rng.random(n_clean) < 0.10,
    np.ones(n_clean),  # Genuine but looks like spoofer
    np.clip(rng.uniform(0.0, 0.4, n_clean), 0, 1)  # Genuine messy connection
)
df.loc[mask_clean, 'gps_jitter_perfect'] = clean_jitter

# 2. Add realistic timing noise (Simultaneous Claims overlaps)
# Fraudsters doing ring fraud don't all click instantaneously
df.loc[mask_fraud, 'claim_latency_under30s'] = np.where(
    rng.random(n_fraud) < 0.60,
    np.ones(n_fraud),          # Fast rings
    rng.choice([0, 1], n_fraud, p=[0.8, 0.2])  # Slow rings who took time
)

# 3. Add generic ambiguity to Zone Depth (fraudsters might accidentally be deep in the zone)
df.loc[mask_fraud, 'zone_depth_score'] = np.where(
    rng.random(n_fraud) < 0.20,
    np.clip(rng.uniform(0.7, 1.0, n_fraud), 0, 1), # Actually inside the zone!
    np.clip(rng.uniform(0.0, 0.4, n_fraud), 0, 1)  # Obviously outside
)

# Clean workers who are just on the border edges
df.loc[mask_clean, 'zone_depth_score'] = np.where(
    rng.random(n_clean) < 0.15,
    np.clip(rng.uniform(0.0, 0.3, n_clean), 0, 1), # Clean but on edge
    np.clip(rng.uniform(0.5, 1.0, n_clean), 0, 1)  # Clean deep inside
)

# 4. Device Sharing Ambiguity
# Fraudsters using sybils
df.loc[mask_fraud, 'hw_fingerprint_match'] = np.where(
    rng.random(n_fraud) < 0.50,
    0, # Used other phones
    1  # Same phone
)
# Clean workers giving phones to friends
df.loc[mask_clean, 'hw_fingerprint_match'] = np.where(
    rng.random(n_clean) < 0.05,
    1, # Suspicious
    0
)

# 5. Overwriting some rows to be exactly confusing
# Make 150 normal rows look exactly like fraud, and 150 fraud rows look exactly like normal
confuse_clean_idx = df[mask_clean].sample(250).index
confuse_fraud_idx = df[mask_fraud].sample(150).index

# Clean looking like fraud
df.loc[confuse_clean_idx, 'gps_jitter_perfect'] = 1
df.loc[confuse_clean_idx, 'claim_latency_under30s'] = 1
df.loc[confuse_clean_idx, 'hw_fingerprint_match'] = 1

# Fraud looking like clean
df.loc[confuse_fraud_idx, 'gps_jitter_perfect'] = 0.1
df.loc[confuse_fraud_idx, 'claim_latency_under30s'] = 0
df.loc[confuse_fraud_idx, 'hw_fingerprint_match'] = 0
df.loc[confuse_fraud_idx, 'zone_depth_score'] = 0.9

df.to_csv(csv_path, index=False)
print("Noise injection complete.")
