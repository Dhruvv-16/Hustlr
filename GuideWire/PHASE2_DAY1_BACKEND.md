# HUSTLR — DAY 1: FASTAPI BACKEND
## Build this before touching the Flutter app again
## A running backend changes judge perception completely
## Dhruv's task

---

## SETUP

```bash
mkdir hustlr-backend
cd hustlr-backend
pip install fastapi uvicorn pydantic
uvicorn main:app --reload
```

Create main.py with these 4 endpoints.
All logic is rule-based — no ML needed yet.
Deploy to Render free tier when done.

---

## ENDPOINT 1 — /detect-disruption

```python
from fastapi import FastAPI
from pydantic import BaseModel
from datetime import datetime

app = FastAPI()

class DisruptionRequest(BaseModel):
    zone: str          # e.g. "adyar_chennai"
    timestamp: str     # ISO format
    rainfall_mm: float = 0.0
    temp_celsius: float = 0.0
    aqi: int = 0
    platform_failure_rate: float = 0.0
    internet_speed_mbps: float = 50.0
    traffic_speed_kmh: float = 20.0
    traffic_baseline_kmh: float = 20.0

@app.post("/detect-disruption")
def detect_disruption(req: DisruptionRequest):
    triggers = []

    if req.rainfall_mm >= 64.5:
        triggers.append({
            "trigger": "heavy_rain",
            "severity": min(req.rainfall_mm / 115.6, 1.0),
            "rate_per_hr": 65 if req.rainfall_mm >= 115.6 else 50,
            "threshold": 64.5,
            "source": "IMD + OpenWeatherMap"
        })

    if req.temp_celsius >= 43.0:
        triggers.append({
            "trigger": "heat_wave",
            "severity": min((req.temp_celsius - 43) / 5, 1.0),
            "rate_per_hr": 40,
            "threshold": 43.0,
            "source": "IMD"
        })

    if req.aqi >= 200:
        triggers.append({
            "trigger": "severe_pollution",
            "severity": min(req.aqi / 400, 1.0),
            "rate_per_hr": 40,
            "threshold": 200,
            "source": "AQICN / WAQI"
        })

    if req.platform_failure_rate >= 0.60:
        triggers.append({
            "trigger": "platform_outage",
            "severity": req.platform_failure_rate,
            "rate_per_hr": 50,
            "threshold": 0.60,
            "source": "Zepto order failure rate"
        })

    if req.internet_speed_mbps < 2.0:
        triggers.append({
            "trigger": "internet_blackout",
            "severity": 1 - (req.internet_speed_mbps / 2.0),
            "rate_per_hr": 50,
            "threshold": 2.0,
            "source": "Ookla + TRAI"
        })

    speed_drop = (req.traffic_baseline_kmh - req.traffic_speed_kmh) / req.traffic_baseline_kmh
    if speed_drop >= 0.40:
        triggers.append({
            "trigger": "heavy_traffic",
            "severity": min(speed_drop, 1.0),
            "rate_per_hr": 40,
            "threshold": "40% below baseline",
            "source": "Google Maps Traffic API"
        })

    return {
        "zone": req.zone,
        "timestamp": req.timestamp,
        "triggers_fired": len(triggers),
        "triggers": triggers,
        "payout_eligible": len(triggers) > 0
    }
```

---

## ENDPOINT 2 — /fraud-score

```python
class FraudRequest(BaseModel):
    worker_id: str
    gps_zone_match: bool = True
    wifi_home_ssid: bool = False
    battery_charging: bool = False
    accelerometer_idle: bool = False
    platform_app_active: bool = True
    ip_geo_home_match: bool = False
    claim_latency_seconds: int = 120
    gps_jitter_perfect: bool = False
    device_rooted: bool = False
    mock_location_on: bool = False
    orders_during_disruption: int = 0
    days_since_onboarding: int = 30

@app.post("/fraud-score")
def fraud_score(req: FraudRequest):
    score = 0

    # Layer 0 — device integrity (auto reject)
    if req.device_rooted or req.mock_location_on:
        return {
            "worker_id": req.worker_id,
            "fps_score": 100,
            "status": "AUTO_REJECTED",
            "reason": "Device integrity check failed — rooted or mock location active",
            "payout_action": "BLOCKED",
            "layers_checked": ["Layer 0: Device Integrity"]
        }

    # Layer 1 — individual signals
    if not req.gps_zone_match:      score += 25
    if req.wifi_home_ssid:          score += 20
    if req.battery_charging:        score += 15
    if req.accelerometer_idle:      score += 10
    if not req.platform_app_active: score += 15
    if req.ip_geo_home_match:       score += 20
    if req.claim_latency_seconds < 30: score += 10
    if req.gps_jitter_perfect:      score += 15

    # Layer 4 — orders during disruption
    if req.orders_during_disruption > 0:
        return {
            "worker_id": req.worker_id,
            "fps_score": 100,
            "status": "AUTO_REJECTED",
            "reason": f"Worker completed {req.orders_during_disruption} orders during claimed disruption",
            "payout_action": "BLOCKED",
            "layers_checked": ["Layer 4: Behavioral Fingerprinting"]
        }

    # New worker penalty
    if req.days_since_onboarding < 14:
        score += 10

    # Cap at 100
    score = min(score, 100)

    if score <= 30:
        status = "GREEN"
        action = "AUTO_APPROVE — 70% released immediately, 30% Sunday settlement"
    elif score <= 60:
        status = "YELLOW"
        action = "SOFT_HOLD — provisional credit + 2hr verification"
    else:
        status = "RED"
        action = "HUMAN_REVIEW — provisional ₹100-300 credit released immediately"

    return {
        "worker_id": req.worker_id,
        "fps_score": score,
        "status": status,
        "payout_action": action,
        "layers_checked": [
            "Layer 0: Device Integrity ✅",
            "Layer 1: Individual Signals",
            "Layer 4: Behavioral Fingerprinting"
        ]
    }
```

---

## ENDPOINT 3 — /calculate-payout

```python
class PayoutRequest(BaseModel):
    trigger_type: str
    duration_hours: float
    zone_depth_score: float    # 0.0–1.0
    fps_score: int
    plan: str                  # basic / standard / full / elite
    daily_cap: int = 150
    weekly_cap: int = 500
    hours_already_paid_today: float = 0.0

HOURLY_RATES = {
    "heavy_rain": 50,
    "extreme_rain": 65,
    "heat_wave": 40,
    "severe_pollution": 40,
    "platform_outage": 50,
    "bandh_strike": 50,
    "heavy_traffic": 40,
    "internet_blackout": 50,
}

ZONE_MULTIPLIERS = {
    (0.00, 0.20): 0.0,
    (0.21, 0.40): 0.30,
    (0.41, 0.60): 0.60,
    (0.61, 0.80): 0.85,
    (0.81, 1.00): 1.00,
}

def get_zone_multiplier(depth: float) -> float:
    for (low, high), mult in ZONE_MULTIPLIERS.items():
        if low <= depth <= high:
            return mult
    return 0.0

@app.post("/calculate-payout")
def calculate_payout(req: PayoutRequest):
    rate = HOURLY_RATES.get(req.trigger_type, 40)
    zone_mult = get_zone_multiplier(req.zone_depth_score)
    gross = rate * req.duration_hours * zone_mult

    # Apply daily cap
    already_paid = req.hours_already_paid_today * rate
    remaining_cap = req.daily_cap - already_paid
    gross = min(gross, remaining_cap)
    gross = round(gross)

    if gross <= 0:
        return {
            "gross_payout": 0,
            "reason": "Daily cap reached or zone depth too low",
            "zone_depth_score": req.zone_depth_score,
            "zone_multiplier": zone_mult
        }

    # FPS determines split
    if req.fps_score <= 30:
        instant = round(gross * 0.70)
        held = gross - instant
        release = "Sunday 11 PM settlement"
    elif req.fps_score <= 60:
        instant = round(gross * 0.40)
        held = gross - instant
        release = "After soft verification (2hrs)"
    else:
        instant = min(300, round(gross * 0.30))
        held = gross - instant
        release = "After human review"

    return {
        "trigger": req.trigger_type,
        "duration_hours": req.duration_hours,
        "hourly_rate": rate,
        "zone_depth_score": req.zone_depth_score,
        "zone_multiplier": zone_mult,
        "gross_payout": gross,
        "instant_release": instant,
        "held_amount": held,
        "held_release": release,
        "daily_cap": req.daily_cap,
        "fps_score": req.fps_score
    }
```

---

## ENDPOINT 4 — /calculate-premium

```python
class PremiumRequest(BaseModel):
    zone_flood_risk: float     # 0.0–1.0
    avg_daily_income: float    # ₹
    disruption_freq_12mo: int  # number of disruption events last year
    claims_history_penalty: int = 0
    platform_outage_rate: float = 0.03
    behavioral_index: float = 0.50
    plan: str = "standard"     # basic / standard / full / elite
    previous_premium: float = 0.0  # for ±20% change cap

BASE_RATES = {
    "basic": 29,
    "standard": 49,
    "full": 79,
    "elite": 109
}

@app.post("/calculate-premium")
def calculate_premium(req: PremiumRequest):
    base = BASE_RATES.get(req.plan, 49)

    # ISS calculation
    iss = 100
    iss -= req.zone_flood_risk * 20
    iss -= min(req.disruption_freq_12mo, 15)
    iss += min(req.avg_daily_income / 200, 10)
    iss -= req.claims_history_penalty
    iss = max(0, min(100, round(iss)))

    # ISS-based adjustment
    if iss >= 70:
        iss_adjustment = -3
        iss_reason = "Low risk zone — discount applied"
    elif iss >= 50:
        iss_adjustment = 0
        iss_reason = "Standard risk — base rate"
    elif iss >= 30:
        iss_adjustment = +5
        iss_reason = "Moderate risk — surcharge applied"
    else:
        iss_adjustment = +10
        iss_reason = "High risk zone — surcharge applied"

    # Platform reliability adjustment
    if req.platform_outage_rate < 0.03:
        platform_adjustment = -3
        platform_reason = "Platform uptime > 97% — discount"
    elif req.platform_outage_rate < 0.05:
        platform_adjustment = 0
        platform_reason = "Platform uptime normal"
    else:
        platform_adjustment = +3
        platform_reason = "High outage rate — surcharge"

    # Clean history bonus
    clean_bonus = -req.claims_history_penalty if req.claims_history_penalty == 0 else 0
    clean_reason = "No claims this season ✅" if clean_bonus == 0 else "Claims history penalty applied"

    raw_premium = base + iss_adjustment + platform_adjustment + clean_bonus

    # Apply hard bounds (0.7× to 2.0× base)
    min_premium = round(base * 0.7)
    max_premium = round(base * 2.0)
    raw_premium = max(min_premium, min(max_premium, raw_premium))

    # Apply ±20% week-over-week change cap
    if req.previous_premium > 0:
        max_change = req.previous_premium * 0.20
        raw_premium = max(
            req.previous_premium - max_change,
            min(req.previous_premium + max_change, raw_premium)
        )

    final_premium = round(raw_premium)

    return {
        "plan": req.plan,
        "iss_score": iss,
        "breakdown": {
            "base_rate": base,
            "iss_adjustment": iss_adjustment,
            "iss_reason": iss_reason,
            "platform_adjustment": platform_adjustment,
            "platform_reason": platform_reason,
            "clean_history_bonus": clean_bonus,
            "clean_reason": clean_reason,
        },
        "final_premium": final_premium,
        "min_bound": min_premium,
        "max_bound": max_premium,
        "week_over_week_cap": "±20% applied" if req.previous_premium > 0 else "First week — no cap"
    }
```

---

## ENDPOINT 5 — /health (simple proof it's running)

```python
@app.get("/health")
def health():
    return {
        "status": "running",
        "project": "Hustlr",
        "team": "Code Crafters",
        "phase": 2,
        "endpoints": [
            "/detect-disruption",
            "/fraud-score",
            "/calculate-payout",
            "/calculate-premium"
        ]
    }
```

---

## DEPLOY TO RENDER

1. Push to GitHub repo (same Hustlr repo, in /backend folder)
2. Go to render.com → New Web Service
3. Connect repo → select /backend folder
4. Build command: `pip install -r requirements.txt`
5. Start command: `uvicorn main:app --host 0.0.0.0 --port $PORT`
6. Deploy → get public URL

requirements.txt:
```
fastapi
uvicorn
pydantic
```

---

## VERIFY — test with curl or Postman

```bash
# Test disruption detection
curl -X POST https://your-render-url.onrender.com/detect-disruption \
  -H "Content-Type: application/json" \
  -d '{"zone":"adyar_chennai","timestamp":"2026-03-27T11:00:00","rainfall_mm":72.0}'

# Expected: trigger fires with heavy_rain, rate ₹50/hr

# Test fraud score
curl -X POST https://your-render-url.onrender.com/fraud-score \
  -H "Content-Type: application/json" \
  -d '{"worker_id":"HS-9821","gps_zone_match":true,"claim_latency_seconds":120}'

# Expected: fps_score 0, GREEN, AUTO_APPROVE

# Test payout
curl -X POST https://your-render-url.onrender.com/calculate-payout \
  -H "Content-Type: application/json" \
  -d '{"trigger_type":"heavy_rain","duration_hours":3,"zone_depth_score":0.84,"fps_score":14,"plan":"standard"}'

# Expected: gross ₹150, instant ₹105, held ₹45

# Test premium
curl -X POST https://your-render-url.onrender.com/calculate-premium \
  -H "Content-Type: application/json" \
  -d '{"zone_flood_risk":0.62,"avg_daily_income":600,"disruption_freq_12mo":8,"plan":"standard"}'

# Expected: ISS 62, final premium ₹49
```

---

## DONE WHEN:

[ ] uvicorn main:app --reload runs locally with no errors
[ ] All 4 endpoints return correct JSON
[ ] Curl tests pass matching expected outputs above
[ ] Deployed to Render — public URL works
[ ] /health endpoint accessible from browser
[ ] Add Render URL to README as "Backend API"
