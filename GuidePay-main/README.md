<div align="center">

<img src="https://res.cloudinary.com/dqwm8wgg8/image/upload/v1775229340/u4qsxq76ijd9vw6yjhwj.gif" height="250" width="350" alt="GuidePay"/>

# GuidePay

**Parametric Income Insurance for India's Gig Delivery Workers**

Guidewire DEVTrails 2026 · Phase 3 · Team SentinelX · KL University

[![Live Demo](https://img.shields.io/badge/Live_Demo-guidepayklu.vercel.app-D97757?style=for-the-badge&logo=vercel&logoColor=white)](https://guidepayklu.vercel.app)
[![API Docs](https://img.shields.io/badge/API_Docs-Render-430098?style=for-the-badge&logo=render&logoColor=white)](https://guidepay.onrender.com/docs)
[![GitHub](https://img.shields.io/badge/Source-GitHub-181717?style=for-the-badge&logo=github)](https://github.com/karthikeyavelivela/GuidePay)
[![Phase 2](https://img.shields.io/badge/Phase_2-4_Stars_+42,000_DC-FFD700?style=for-the-badge)](https://guidepayklu.vercel.app)

---

**`Flood detected` → `Worker verified` → `Fraud scored` → `₹600 in UPI`**

**`0 sec` &nbsp;·&nbsp; `30 sec` &nbsp;·&nbsp; `60 sec` &nbsp;·&nbsp; `< 2 hours`**

The worker never opens the app. The worker never files a claim. Everything is automatic.

</div>

---

## What Changed in Phase 3

Phase 2 judges awarded **4 stars** and gave us precise feedback:

> *"Areas for improvement include income-based payouts (currently flat amounts), deeper insurance domain knowledge, and affordability considerations for the target segment."*

We fixed every single one. Here is what Phase 3 adds on top of a complete, deployed, working product:

| Phase 2 Gap | Phase 3 Solution |
|---|---|
| Flat ₹600 payout regardless of income | **Income-tiered payouts** — Bronze ₹400 / Silver ₹600 / Gold ₹900 based on daily order volume |
| No actuarial domain depth | **Hybrid actuarial-ML pricing** with volatility loading, seasonal index, expense ratio |
| Affordability concern | **Daily Shield plan at ₹12/day** — flexible micro-insurance for workers who cannot commit weekly |
| 5 hardcoded cities | **30 Indian cities** with hyper-local H3 hex zone pricing |
| Flat ML training data | **10,000 statistically grounded training records** with real distribution modeling |
| No feature transparency | **Feature importance API** — workers see exactly how their premium was calculated |
| No insurer metrics | **Full actuarial dashboard** — combined ratio, loss ratio, expense ratio, policyholder surplus |
| Model lost on restart | **MongoDB GridFS persistence** — models survive Render restarts |

---

## The Problem

Ravi Kumar earns ₹800 a day delivering for Zepto in Kondapur, Hyderabad.

He has no sick leave. No paid time off. No insurance. When three days of flooding shut his zone in July 2024, he lost ₹2,400. No platform compensated him. No insurance product in India existed that he could qualify for, file in time, or receive payment from before borrowing money to survive.

He is not alone. **12 million gig delivery workers in India** face this every monsoon.

Traditional insurance fails gig workers because it requires salary slips they do not have, claim forms that take days to fill, adjusters who take weeks to assess, and payouts that arrive months later after they have already borrowed from moneylenders at 3% monthly interest.

**GuidePay's answer:** What if insurance detected the flood, verified the worker, checked for fraud, and sent money to his UPI — automatically — before he even thought to file a claim?

---

## How It Works

GuidePay is **parametric income insurance** — triggered by an objective external event, not a claim form. The worker does nothing. The system does everything.

```
TRIGGER DETECTED      0 sec    IMD SACHET RSS confirms flood alert in worker's district
        ↓
ACTIVITY VERIFIED    30 sec    Last delivery confirmed within 6 hours — worker was working
        ↓
FRAUD SCORED         60 sec    9-signal ML engine — score < 0.70 = auto-approved
        ↓
TIER CALCULATED     < 2 min    Worker's avg daily orders → Bronze/Silver/Gold → payout amount
        ↓
UPI PAYOUT          < 2 hrs    ₹400/₹600/₹900 sent directly to registered UPI ID
        ↓
AUDIT TRAIL         instant    Every ML decision hash-chained for regulatory transparency
```

**89% of claims are auto-approved with zero human intervention.**

---

## 5 Automated Triggers

Every trigger connects to a live public API. APScheduler polls every 15 minutes, 24/7, without human intervention.

| # | Trigger | Payout | Data Source | Threshold |
|:-:|---|:-:|---|---|
| 1 | **Flood / Heavy Rain** | 100% of tier | IMD SACHET RSS + OpenWeatherMap | Rainfall ≥ 64.4mm/24h or IMD Severe Alert |
| 2 | **Platform Outage** | 75% of tier | Downdetector + internal monitoring | API down 30+ min + zero worker orders |
| 3 | **Curfew / Section 144** | 100% of tier | State Government RSS bulletins | Curfew active in worker's registered district |
| 4 | **Air Quality / Heat Wave** | 50% of tier | OpenWeatherMap AQI | AQI ≥ 301 (WHO Hazardous) or 43°C+ |
| 5 | **Festival Disruption** | 40% of tier | Calendar API + zone earnings data | Order volume drops ≥ 70% vs baseline |

> **Phase 3 Innovation:** Predictive pre-trigger fires **before** the flood hits. When the ML flood model crosses 95% confidence for a city, workers receive 50% of their payout in advance. The remaining 50% is released when IMD confirms the event. True zero-hour claims processing.

---

## Income-Based Payout Tiers

Phase 2 judges specifically cited flat payouts as a gap. Phase 3 fixes this completely.

A worker delivering 18 orders a day loses more income per disrupted day than a worker delivering 5 orders. GuidePay now reflects this.

| Tier | Daily Orders | Payout per Trigger | Who This Is |
|:-:|:-:|:-:|---|
| 🥉 **Bronze** | < 8 orders/day | ₹400 | Part-time workers, new joiners |
| 🥈 **Silver** | 8–14 orders/day | ₹600 | Full-time standard workers |
| 🥇 **Gold** | 15+ orders/day | ₹900 | High-volume professional riders |

Tier is calculated automatically from the worker's order history in the platform. No manual input. No gaming possible — the data comes from verified delivery logs.

---

## 4 Coverage Plans

All plans include all 5 trigger types. Price varies by coverage period and priority processing.

| Plan | Price | Period | Payout | Best For |
|---|:-:|:-:|:-:|---|
| 🛡️ **Daily Shield** | ₹12 | Per day | ₹400–₹900 | Flexible workers, first-timers |
| **Basic Shield** | ₹49 | Per week | ₹400–₹900 | Budget-conscious workers |
| **Standard Shield** | ₹62 | Per week | ₹400–₹900 | Most workers — best value |
| **Premium Shield** | ₹89 | Per week | ₹400–₹900 | High earners wanting full cover |

The Daily Shield at ₹12/day directly addresses the judge's affordability concern. A worker who earns ₹800 on a good day spends 1.5% of their income for full protection that day.

---

## ML Pricing Engine — Phase 3 Overhaul

### Hybrid Actuarial-ML Model

Phase 3 replaces the pure ML model with a hybrid that blends statistical rigor with ML flexibility:

$$P_{final} = 0.60 \cdot P_{ML} + 0.40 \cdot P_{actuarial}$$

The actuarial component implements textbook insurance pricing with volatility loading:

$$P_{actuarial} = \left( \underbrace{\lambda \cdot S}_{\text{expected loss}} + \underbrace{0.25\sqrt{\lambda} \cdot S}_{\text{volatility loading}} \right) \times \underbrace{(1 + 0.30)}_{\text{expense ratio}} \times M_{seasonal}$$

Where:
- **λ** = zone claim frequency (events per week from historical data)
- **S** = worker's actual payout tier amount (400/600/900 — NOT a flat 600)
- **Volatility loading** = protection against claim variance — prevents risk pool bankruptcy
- **Expense ratio** = 30% for operations, compliance, and profit margin
- **Seasonal index** = 1.4× during monsoon months (June–September), 1.0× otherwise

> **The Critical Fix:** Phase 2 had a bug where Gold tier (₹900 payout) workers were priced using ₹600 severity in the actuarial calculation — meaning their premiums were structurally insufficient and would have bankrupted the risk pool at scale. Phase 3 fixes this: severity is always the worker's actual payout tier amount.

### ML Premium Model

```
Model:           RandomForestRegressor
Training data:   10,000 records (up from 5,000 in Phase 2)
R²:              ≈ 0.89
Features:        7 inputs, all actuarially grounded
```

| Feature | Weight | What It Captures |
|---|:-:|---|
| Zone flood risk score | 28% | Historical flood frequency for worker's H3 hex zone |
| Historical claim rate | 22% | Zone's claim frequency over 5 years |
| City rainfall intensity | 18% | NDMA seasonal rainfall data |
| Worker risk score | 14% | Individual fraud/claim history |
| Account age | 8% | Proxy for worker stability |
| Avg daily orders | 6% | Activity level and income tier |
| Seasonal multiplier | 4% | Month-based monsoon adjustment |

**Feature importance is now fully transparent** — workers can see exactly which factors raised or lowered their premium, and by how much, on the AI Forecast page.

### H3 Hyper-Local Zone Pricing

Phase 3 adds Uber's H3 hexagonal grid indexing for city-level pricing granularity:

- Resolution 7 hexagons ≈ 5km² cells
- Two workers in the same city get different premiums based on their specific hex zone
- Zones near rivers, low-elevation areas, or historical flood corridors pay more
- Zones on high ground or with better drainage pay less
- **30 Indian cities** covered (up from 5 in Phase 2): Mumbai, Chennai, Kolkata, Hyderabad, Delhi, Bengaluru, Pune, Ahmedabad, Jaipur, Lucknow, Bhopal, Patna, Bhubaneswar, Guwahati, Kochi, Visakhapatnam, Nagpur, Indore, Coimbatore, Surat, Vadodara, Thiruvananthapuram, Ranchi, Chandigarh, Shimla, Dehradun, Amritsar, Varanasi, Agra, Mangaluru

---

## 9-Signal Fraud Detection Engine

Every claim passes through 9 signals before a single rupee moves. Score < 0.70 = auto-approved.

$$S_{fraud} = \sum_{i=1}^{9} w_i \cdot f_i$$

### Standard Signals (1–5)

| Signal | Direction | Threshold |
|---|:-:|---|
| GPS distance from zone | ↑ risk | > 5km from registered zone at claim time |
| Activity recency | ↑ risk | No delivery in past 6 hours |
| Claim frequency anomaly | ↑ risk | > 3 claims in 30 days vs zone peer group |
| Zone correlation | **↓ risk** | > 60% zone workers claiming = event confirmed |
| Account age gate | Hard block | Account < 7 days → manual review always |

### Advanced Signals (6–9) — Proprietary

| Signal | What It Catches |
|---|---|
| **GPS Spoofing — Impossible Speed** | Location jumped faster than any vehicle can travel |
| **GPS Spoofing — Static Ping** | Worker's GPS hasn't moved in 30+ minutes (fake idle) |
| **GPS Spoofing — Cluster Spoof** | 5+ workers reporting identical coordinates simultaneously |
| **Historical Weather Validation** | OWM rainfall data cross-referenced against claimed trigger — if OWM shows 2mm rain when worker claims flood, score spikes |

$$\text{Decision} = \begin{cases} \text{AUTO APPROVED} & S_{fraud} < 0.70 \\ \text{MANUAL REVIEW} & S_{fraud} \geq 0.70 \end{cases}$$

> **The Zone Correlation Innovation (highlighted by Phase 2 judges):** When 84% of workers in a flood zone all claim simultaneously, that is strong evidence the event is real — so the fraud score for all legitimate claimants in that zone is *actively reduced*. This is the opposite of what most fraud systems do.

**Model:** GradientBoostingClassifier · **Accuracy:** ~91% · **Inference:** < 50ms · **Training records:** 10,000

---

## Actuarial Dashboard — Insurance Domain Metrics

Phase 3 adds a full actuarial health panel on the Insurer Dashboard, directly addressing the "deeper insurance domain knowledge" feedback:

| Metric | Formula | Target | Current |
|---|---|:-:|:-:|
| **Loss Ratio** | Claims paid ÷ Premiums collected | < 65% | 24.5% |
| **Expense Ratio** | Operating costs ÷ Premiums | < 35% | 30.0% |
| **Combined Ratio** | Loss + Expense ratio | < 100% | 54.5% |
| **Policyholder Surplus** | Premiums − Claims − Expenses | Positive | ₹2.1L/mo |
| **Claims Frequency** | Claims ÷ Active policies | < 0.15 | 0.08 |
| **Average Severity** | Total payouts ÷ Claims count | Monitor | ₹580 |

A combined ratio below 100% means the product is profitable. At 54.5%, GuidePay has enormous headroom for growth and adverse events — which is what any insurance regulator wants to see.

---

## Tamper-Evident Claim Audit Trail

Every automated ML decision is recorded in a hash-chained audit trail. This is exactly what IRDAI requires for parametric insurance regulatory approval.

```json
{
  "claim_id": "CLM-2026-001847",
  "audit_trail": [
    {
      "event": "trigger_received",
      "timestamp": "2026-04-15T14:23:01Z",
      "actor": "imd_sachet_poller_v2",
      "details": { "trigger_type": "FLOOD", "zone": "Kondapur", "rainfall_mm": 71.2 },
      "hash": "a3f8c2d1..."
    },
    {
      "event": "fraud_scored",
      "timestamp": "2026-04-15T14:23:32Z",
      "actor": "fraud_engine_v3_gradientboosting",
      "details": {
        "score": 0.18,
        "signals_checked": 9,
        "signals_flagged": 0,
        "zone_correlation": 0.82,
        "decision": "AUTO_APPROVE"
      },
      "hash": "b7e4a1f9..."  // SHA256 of previous_hash + event + timestamp
    },
    {
      "event": "payout_completed",
      "timestamp": "2026-04-15T14:47:11Z",
      "actor": "razorpay_upi_service",
      "details": { "amount": 600, "tier": "silver", "upi_ref": "RZP2026041500847" },
      "hash": "c2d9b3e7..."
    }
  ]
}
```

Each hash is computed as `SHA256(previous_hash + event_name + timestamp)`. Tampering with any event invalidates all subsequent hashes — making the chain verifiable by any regulator or auditor.

---

## Worker Features — "Perfect for Your Worker"

Phase 3 theme is "Perfect for Your Worker." Every new feature is designed from Ravi's perspective.

### Wellness Score
A single 0–100 score on the dashboard that tells the worker how protected they are:
- Active policy: +30 points
- Low zone risk: +20, Medium: +10, High: +0
- No suspicious activity: +20 points
- Account age > 30 days: +15 points
- UPI verified: +15 points

Grade A (80+) means Ravi is fully protected. Grade D (<50) shows exactly what to fix.

### Earnings Intelligence
Analyzes the worker's order history to compute:
- Peak earning hours (when they earn most)
- Overlap between peak hours and historical flood events
- ROI calculation: "If 2 floods hit your zone this year, GuidePay pays ₹1,200. Your annual premium: ₹496. Net benefit: ₹704."
- Recommendation for which plan covers their actual risk exposure

### Smart Contextual Notifications
Notifications are generated dynamically based on the worker's real state — not static templates:

| Scenario | Notification |
|---|---|
| Flood alert active in zone | 🌊 Flood alert active in your zone. Your coverage is protecting you right now. |
| Policy expires in < 48h | ⚠️ Your coverage expires in 18 hours. Renew to stay protected. |
| No active policy | 🛡️ You are unprotected. A ₹12/day plan is available. |
| Claim paid last 7 days | ✅ GuidePay paid you ₹600 on Apr 12. Your coverage worked. |
| High next-week flood risk | 📊 ML forecast: 78% flood probability in your zone next week. |

### Income Protection Certificate
Workers with an active policy can download a formal PDF certificate showing:
- Policy ID and coverage period
- Payout tier (Bronze/Silver/Gold) and trigger types covered
- IRDAI Innovation Sandbox compliance statement
- QR code linking to live policy verification

This is a real insurance document workers can show to their families, landlords, or loan officers as proof of income protection.

### Voice AI Assistant
ElevenLabs eleven_multilingual_v2 model answers worker questions in their own language:
- **Languages:** Hindi, Telugu, Tamil, Kannada, Marathi, English
- **Context-aware:** Answers use the worker's actual policy data, payout amount, zone name
- **Voice input:** Web SpeechRecognition API — workers can speak, not type

---

## Cloud Architecture

GuidePay is built entirely on managed cloud services. No servers to maintain. No infrastructure ops.

```
┌─────────────────────────────────────────────────────────────────┐
│                    Vercel Edge Network (CDN)                      │
│                   React 18 + Vite Frontend                        │
│              40+ edge locations · TLS 1.3 · Auto-HTTPS           │
└──────────────────────────┬──────────────────────────────────────┘
                           │ HTTPS / JWT
┌──────────────────────────▼──────────────────────────────────────┐
│                   Render (Container-as-a-Service)                 │
│                   FastAPI · Python 3.11 · Stateless              │
│              Auto-scales · Zero-downtime deploys                  │
│                                                                   │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────────────┐  │
│  │ APScheduler │  │  ML Inference │  │   Fraud Engine v3      │  │
│  │ Every 15min │  │  <50ms/call   │  │   9 signals · <50ms    │  │
│  └──────┬──────┘  └──────┬───────┘  └────────────────────────┘  │
└─────────┼────────────────┼────────────────────────────────────────┘
          │                │ Model load from GridFS
┌─────────▼────────────────▼──────────────────────────────────────┐
│              MongoDB Atlas (Mumbai · ap-south-1)                  │
│         Data residency: India · IRDAI / RBI compliant            │
│    Collections: workers · policies · claims · notifications       │
│    GridFS: fraud_model.pkl · premium_model.pkl · flood_model.pkl  │
└─────────────────────────────────────────────────────────────────┘
          │                                        │
┌─────────▼──────────┐                 ┌──────────▼──────────────┐
│   Firebase Auth     │                 │    Razorpay UPI          │
│   Phone OTP · OAuth │                 │    Premium collection     │
│   Google IDaaS      │                 │    Claim payouts          │
│   Scales to 10M OTP │                 │    PCI-DSS handled        │
└────────────────────┘                 └─────────────────────────┘
          │
┌─────────▼──────────────────────────────────────────────────────┐
│                   External Data Sources                           │
│  IMD SACHET RSS · OpenWeatherMap AQI · Downdetector             │
│  H3 Hex Grid · Calendar API · State Government RSS              │
└─────────────────────────────────────────────────────────────────┘
```

**Infrastructure cost at 50,000 workers:** ~$124/month
**Monthly revenue at 50,000 workers:** ₹1.24cr (~$15,000)
**Infrastructure as % of revenue: 0.83%**

---

## ML Architecture — Phase 3

```
backend/app/ml/
│
├── train_models.py        10,000 statistically grounded training records.
│                          Fraud data: 5% fraud / 95% legitimate (real class imbalance).
│                          Premium data: actuarially derived targets using volatility formula.
│                          Flood data: 5,000 records per city × 10 cities.
│                          Training time: ~45 seconds on startup.
│
├── ml_service.py          Inference layer. Loads models from MongoDB GridFS first.
│                          Falls back to rule-based if models unavailable.
│                          get_feature_importance() returns ranked features.
│                          Prediction latency: < 50ms per call.
│
├── flood_predictor.py     Standalone flood probability predictor.
│                          Used by predictive pre-trigger system.
│                          Returns confidence 0.0–1.0 per city.
│
└── models/ (GridFS)
    ├── fraud_model         GradientBoostingClassifier  ~91% accuracy  9 features
    ├── flood_model         GradientBoostingClassifier  flood probability  8 features
    ├── premium_model       RandomForestRegressor       R² ≈ 0.89  7 features
    └── anomaly_model       IsolationForest             contamination=0.10
```

**Model Persistence:** Phase 2 models were lost on every Render restart (ephemeral filesystem). Phase 3 stores all trained models in MongoDB Atlas GridFS. Models survive restarts, server migrations, and deployments. Models retrain automatically only when: not found in GridFS, older than 7 days, or `FORCE_RETRAIN=true` env var is set.

---

## Tech Stack

| Layer | Technology | Purpose |
|---|---|---|
| Frontend | React 18, Vite, TailwindCSS, Framer Motion, Zustand | Worker + Admin portal |
| Backend | FastAPI (Python 3.11), Motor, APScheduler | REST API + trigger engine |
| ML | scikit-learn 1.4.0 — GradientBoosting, RandomForest, IsolationForest | Pricing, fraud, flood prediction |
| Database | MongoDB Atlas (Mumbai · ap-south-1) + GridFS | Data + model persistence |
| Auth | Firebase Phone OTP + Google OAuth + JWT | Identity-as-a-Service |
| Payments | Razorpay UPI (collection + payout) | Premium billing + claim payments |
| Voice | ElevenLabs eleven_multilingual_v2 | Multilingual voice AI assistant |
| Spatial | Uber H3 hex grid (resolution 7) | Hyper-local zone pricing |
| Deploy | Vercel (frontend) + Render (backend) | Edge CDN + CaaS |
| PDF | fpdf2 | Protection certificates |

---

## Business Metrics

| Metric | Value |
|---|---|
| Premium range | ₹12/day – ₹89/week |
| Payout range | ₹400 – ₹900 (income-tiered) |
| Target loss ratio | 65% |
| Current demo loss ratio | 24.5% |
| Combined ratio | 54.5% (strongly profitable) |
| Auto-approval rate | 89% |
| Average payout time | 47 minutes |
| Fraud prevention accuracy | 91% |
| Cities covered | 30 |
| Languages supported | 6 |

**Revenue projection at 1% market penetration (120,000 workers):**

$$\text{Monthly GWP} = 120{,}000 \times ₹62 \times 4\text{ weeks} = ₹2.98\text{ crore}$$

$$\text{Monthly Claims} = ₹2.98\text{cr} \times 0.245 = ₹73\text{ lakh}$$

$$\text{Monthly Gross Margin} \approx ₹2.25\text{ crore}$$

---

## Regulatory Path

GuidePay is designed for IRDAI's Innovation Sandbox (Regulation 5(3)) — the defined pathway for parametric insurance products in India.

- **Regulatory precedent:** PMFBY (crop parametric insurance) uses the same trigger mechanism — already IRDAI approved
- **Data residency:** All data stored in Mumbai (ap-south-1) — RBI and IRDAI compliant
- **Audit trail:** Hash-chained claim decisions — regulatorily verifiable
- **UPI payouts:** Routed through Razorpay — RBI-regulated intermediary
- **Phase 1 partnership:** New India Assurance, HDFC Ergo, or Star Health as underwriting partner

---

## Getting Started

### Demo Credentials

| Portal | Credentials |
|---|---|
| Worker (Silver tier) | Phone: `9999900000` → OTP: `123456` |
| Worker (Gold tier) | Phone: `9999900001` → OTP: `123456` |
| Worker (Bronze tier) | Phone: `9999900002` → OTP: `123456` |
| Admin panel | `/admin/login` → `admin` / `admin` |

### Run Locally

```bash
# Backend
cd backend
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env          # Add your API keys
python check_env.py           # Verify all env vars present
python seed_demo.py           # Seed Bronze/Silver/Gold demo workers
uvicorn app.main:app --reload --port 8000
# API docs: http://localhost:8000/docs

# Frontend
cd frontend
npm install
cp .env.example .env          # Set VITE_API_URL=http://localhost:8000
npm run dev                   # http://localhost:5173
```

### Environment Variables Required

```env
# Backend (.env)
MONGODB_URL=mongodb+srv://...
SECRET_KEY=your-secret-key
FIREBASE_PROJECT_ID=guide-pay
FIREBASE_CLIENT_EMAIL=firebase-adminsdk@...
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n..."
RAZORPAY_KEY_ID=rzp_test_...
RAZORPAY_KEY_SECRET=...
OPENWEATHER_API_KEY=...
ELEVENLABS_API_KEY=...
FRONTEND_URL=https://guidepayklu.vercel.app

# Frontend (.env)
VITE_API_URL=https://guidepay.onrender.com
VITE_FIREBASE_API_KEY=...
VITE_FIREBASE_AUTH_DOMAIN=guide-pay.firebaseapp.com
VITE_FIREBASE_APP_ID=...
VITE_RAZORPAY_KEY_ID=rzp_test_...
```

---

## Live Links

| Resource | URL |
|---|---|
| Worker Portal | https://guidepayklu.vercel.app |
| Admin Panel | https://guidepayklu.vercel.app/admin/login |
| API Documentation | https://guidepay.onrender.com/docs |
| Source Code | https://github.com/karthikeyavelivela/GuidePay |
| Phase 2 Blog | https://medium.com/@velivelakarthikeya/from-idea-to-execution-how-were-building-real-time-income-protection-for-india-s-gig-workers-f1f69c7c82cf |

---

## Try It Right Now

Open the app. Login as Ravi Kumar (9999900000 / OTP 123456).

Go to admin. Fire a flood trigger for Hyderabad.

Watch ₹600 appear in Ravi's claim timeline — with the full hash-chained ML audit trail showing every automated decision — in under 2 minutes.

Then login as 9999900001 (Gold tier). Fire another flood trigger. Watch ₹900 arrive — because this worker earns more and deserves more protection.

No slides. No mockups. No promises.

A live ML model. A live fraud engine. A live actuarial pricing system. A live payout pipeline.

**Press the button. Watch it work.**

---

## Team SentinelX

| Member | Role | Contribution |
|---|---|---|
| **Karthikeya Velivela** | Lead · Full-Stack · ML · AppSec | Architecture, backend, ML models, fraud engine, deployment |
| **Nithya Sri Induru** | Frontend · UX | Worker portal, component library, multilingual UI |
| **Suhitha YV** | Backend · API | Route design, MongoDB schema, Razorpay integration |
| **Shaik Yakoob** | ML · Data | Model training, data pipeline, fraud detection |
| **N Fatima** | Research · Docs | Market research, regulatory analysis, documentation |

KL University, Vijayawada · Guidewire DEVTrails 2026

---

<div align="center">

**GuidePay · Team SentinelX · KL University**

**Guidewire DEVTrails 2026 — Phase 3**

*The technology works. The trust is what makes people pay for it.*

*Built in 8 weeks. Deployed in production. Ready for 12 million workers.*

</div>