"""
Smoke tests for the ML FastAPI app. Run from ml_service directory:
  python test_ml_api.py
Or:  python -m pytest test_ml_api.py -q  (if pytest installed)
"""

from __future__ import annotations

import os
import sys
import unittest
from pathlib import Path

# Ensure local main.py is importable when run as script
_ML_DIR = Path(__file__).resolve().parent
if str(_ML_DIR) not in sys.path:
    sys.path.insert(0, str(_ML_DIR))

os.chdir(_ML_DIR)

from fastapi.testclient import TestClient  # noqa: E402

from main import app  # noqa: E402


client = TestClient(app)


class TestMLAPI(unittest.TestCase):
    def test_health(self):
        r = client.get("/health")
        self.assertEqual(r.status_code, 200)
        data = r.json()
        self.assertIn("status", data)
        self.assertIn("models", data)
        self.assertEqual(data["status"], "ok", msg=data.get("models"))

    def test_iss(self):
        r = client.post(
            "/iss",
            json={
                "zone_flood_risk": 0.3,
                "avg_daily_income": 600,
                "disruption_freq_12mo": 10,
                "claims_history_penalty": 1,
                "use_ml": True,
            },
        )
        self.assertEqual(r.status_code, 200)
        self.assertIn("iss_score", r.json())

    def test_fraud(self):
        r = client.post(
            "/fraud",
            json={
                "gps_zone_mismatch": 0,
                "wifi_home_ssid": 0,
                "days_since_onboard": 120,
                "zone_depth_score": 0.75,
                "iss_score": 80,
            },
        )
        self.assertEqual(r.status_code, 200)
        j = r.json()
        self.assertIn("fps_score", j)
        self.assertIn("fps_tier", j)

    def test_nlp(self):
        r = client.post(
            "/nlp",
            json={"text": "IMD orange alert: heavy rain 68mm in Velachery Chennai."},
        )
        self.assertEqual(r.status_code, 200)
        self.assertIn("trigger", r.json())

    def test_blackout(self):
        r = client.post(
            "/blackout",
            json={
                "ookla_avg_speed": 25.0,
                "device_pct_weak": 0.1,
                "sustained_minutes": 5,
                "trai_match": False,
                "zone": "Adyar",
            },
        )
        self.assertEqual(r.status_code, 200)
        self.assertIn("blackout_detected", r.json())

    def test_traffic(self):
        r = client.post(
            "/traffic",
            json={
                "zone": "Adyar",
                "traffic_speed_kmh": 20,
                "baseline_speed_kmh": 40,
                "traffic_duration_min": 45,
                "news_confidence": 0.7,
                "time_of_day": 18,
                "is_weekend": False,
            },
        )
        self.assertEqual(r.status_code, 200)
        self.assertIn("classification", r.json())

    def test_forecast_adyar(self):
        r = client.get("/forecast/Adyar")
        self.assertEqual(r.status_code, 200)
        data = r.json()
        self.assertIn("forecast", data)
        self.assertEqual(len(data["forecast"]), 7)

    def test_forecast_velachery_prophet_zone(self):
        r = client.get("/forecast/Velachery")
        self.assertEqual(r.status_code, 200)
        data = r.json()
        self.assertEqual(len(data["forecast"]), 7)
        self.assertIn(data["forecast"][0]["source"], ("prophet_ml", "rule_based_fallback"))

    def test_work_advisor(self):
        r = client.post(
            "/work-advisor",
            json={"zone": "Adyar", "city": "Chennai", "iss_score": 72},
        )
        self.assertEqual(r.status_code, 200)
        self.assertIsInstance(r.json(), dict)


if __name__ == "__main__":
    unittest.main()
