import os
import pandas as pd
import numpy as np
from datetime import timedelta, date

ZONES = ["Adyar", "Velachery", "Tambaram", "Anna Nagar", "T Nagar", "Perungudi"]
TRIGGERS = ["heavy_rain", "extreme_rain", "platform_outage", "bandh", "heatwave"]
START_DATE = date(2023, 1, 1)
END_DATE = date(2025, 12, 31)

def generate_data(random_state=42):
    np.random.seed(random_state)
    dates = pd.date_range(start=START_DATE, end=END_DATE, freq='D')
    
    rows = []
    
    # Pre-generate event probablities at the day level to correlate zones
    for dt in dates:
        month = dt.month
        is_monsoon = month in [10, 11, 12]
        
        # Heavy rain: baseline 12%, monsoon 32%
        prob_hr = 0.32 if is_monsoon else 0.12
        hr_event = np.random.rand() < prob_hr
        
        # Extreme rain: mostly Nov-Dec, ~2/year
        prob_er = 0.03 if month in [11, 12] else 0.001
        er_event = np.random.rand() < prob_er
        
        # Platform outage: random, ~6/year
        prob_po = 6 / 365
        po_event = np.random.rand() < prob_po
        
        # Bandh: random, lambda=0.25/month ~= 3/year
        prob_b = 3 / 365
        b_event = np.random.rand() < prob_b
        
        # Heatwave: Mar-Jun, ~5/year
        prob_hw = 5 / 122 if month in [3, 4, 5, 6] else 0.001
        hw_event = np.random.rand() < prob_hw
        
        for zone in ZONES:
            # Slight zone variations
            zone_hr_event = hr_event and np.random.rand() < 0.9
            zone_er_event = er_event and np.random.rand() < 0.95
            zone_po_event = po_event and np.random.rand() < 0.8
            zone_b_event = b_event and np.random.rand() < 0.85
            zone_hw_event = hw_event and np.random.rand() < 0.9
            
            for trig, occurs in [("heavy_rain", zone_hr_event), 
                                 ("extreme_rain", zone_er_event), 
                                 ("platform_outage", zone_po_event), 
                                 ("bandh", zone_b_event), 
                                 ("heatwave", zone_hw_event)]:
                
                disruption = 1 if occurs else 0
                hours = np.random.randint(2, 13) if occurs else 0
                rain_mm = 0
                if occurs and trig == "heavy_rain":
                    rain_mm = np.random.uniform(20, 60)
                elif occurs and trig == "extreme_rain":
                    rain_mm = np.random.uniform(60, 150)
                elif is_monsoon and trig in ["heavy_rain", "extreme_rain"]:
                    rain_mm = np.random.uniform(0, 10) # light trace rain if no trigger
                
                rows.append({
                    "ds": dt,
                    "zone": zone,
                    "trigger_type": trig,
                    "disruption_occurred": disruption,
                    "disruption_hours": hours,
                    "rain_mm": rain_mm
                })
                
    df = pd.DataFrame(rows)
    return df

if __name__ == "__main__":
    df = generate_data()
    df.to_csv("disruption_history.csv", index=False)
    print("Generated disruption_history.csv with", len(df), "records.")
