# 🛡️ SurakshaAI — Income Shield for Gig Workers

> **Guidewire DEVTrails 2026 | Unicorn Chase**
> AI-Powered Parametric Insurance for India's Food Delivery Partners

[![Phase](https://img.shields.io/badge/Phase-1%20%7C%20Ideation%20%26%20Foundation-blue?style=for-the-badge)](/)
[![Persona](https://img.shields.io/badge/Persona-Food%20Delivery%20(Swiggy%2FZomato)-orange?style=for-the-badge)](/)
[![Coverage](https://img.shields.io/badge/Coverage-Income%20Loss%20Only-green?style=for-the-badge)](/)
[![Pricing](https://img.shields.io/badge/Pricing-Weekly%20Model-purple?style=for-the-badge)](/)

---

## 📋 Table of Contents

1. [Problem Statement](#-problem-statement)
2. [Our Solution](#-our-solution)
3. [Persona & Scenario Analysis](#-persona--scenario-analysis)
4. [System Workflow](#-system-workflow)
5. [User Flow Diagram](#-user-flow-diagram)
6. [Weekly Premium Model](#-weekly-premium-model)
7. [Parametric Triggers](#-parametric-triggers)
8. [AI/ML Integration Plan](#-aiml-integration-plan)
9. [Fraud Detection Architecture](#-fraud-detection-architecture)
10. [Adversarial Defense & Anti-Spoofing Strategy](#-adversarial-defense--anti-spoofing-strategy)
11. [Platform Justification](#-platform-justification-web--mobile)
12. [Tech Stack](#-tech-stack)
13. [Development Plan](#-development-plan)
14. [Business Model](#-business-model)
15. [Scope Boundaries](#-scope-boundaries)

---

## 🎯 Problem Statement

India has **11+ million gig delivery workers** across platforms like Swiggy, Zomato, Zepto, Amazon, and Dunzo. These workers are the backbone of India's fast-paced digital economy. However, they face a unique and unaddressed financial vulnerability:

**External disruptions beyond their control cause 20–30% monthly income loss.**

| Disruption | Frequency | Income Impact |
|---|---|---|
| Heavy Rainfall (>35mm/hr) | 45–60 days/year in metro cities | ₹400–900/day lost |
| Extreme Heat (>42°C) | 30–50 days/year | ₹200–500/day lost |
| High AQI Pollution (>300) | 60+ days/year in Delhi/NCR | ₹300–700/day lost |
| Unplanned Curfews / Bandhs | 5–15 events/year | ₹800–1200/event lost |
| Delivery App Downtime | Sporadic | ₹200–600/event lost |

**The core gap:**
- ❌ No income protection mechanism exists for gig workers
- ❌ Traditional insurance doesn't cover parametric income events
- ❌ No automated, zero-touch claims experience
- ❌ No predictive risk awareness or alerts

---

## 💡 Our Solution

**SurakshaAI** is an AI-powered parametric insurance platform that:

- 🔮 **Predicts** income disruption risks before they occur using real-time + historical data
- 📋 **Prices** weekly insurance premiums dynamically based on each worker's unique risk profile
- 📡 **Monitors** real-time environmental and civic conditions (weather, AQI, curfews)
- ⚡ **Triggers** claims automatically — zero manual effort from the worker
- 💸 **Pays out** instantly to the worker's linked UPI/wallet upon verified disruption

> We insure **income lost** — not vehicles, health, or accidents. Pure income protection, nothing else.

---

## 👤 Persona & Scenario Analysis

### Primary Persona: Food Delivery Partner (Swiggy / Zomato)

```
Name:         Rajan Kumar
Age:          26
Location:     Bengaluru (Koramangala Zone)
Platform:     Swiggy (Full-time)
Working Hours: 10:00 AM – 10:00 PM (12 hrs/day)
Avg. Daily Income: ₹700 – ₹1,100
Weekly Income: ₹4,900 – ₹7,700
Vehicle:      2-Wheeler (Petrol)
Tech Comfort: Uses smartphone apps daily; prefers simple UI; speaks Kannada/Hindi
```

### Real-World Persona Scenarios

#### Scenario 1: Heavy Rainfall Event 🌧️
> *"It's a Tuesday evening in July. A Red Alert has been issued — rainfall of 80mm/hr is hitting Bengaluru. Rajan can't safely ride. Orders dry up. He loses 6 hours of income = ₹420–660."*

**SurakshaAI Response:**
1. IMD weather API detects rainfall exceeding 35mm/hr threshold in Rajan's pin zone
2. Rajan receives push alert: *"Heavy rain detected in your zone. Your coverage is active."*
3. GPS inactivity for >2 hours during the event is confirmed
4. Claim auto-triggered → ₹350 payout credited to Rajan's Paytm wallet within 4 minutes
5. No form. No call. No wait.

---

#### Scenario 2: Severe AQI Pollution 🌫️
> *"It's November in Delhi. AQI hits 380 (Hazardous). GRAP Stage-3 restrictions are enforced — outdoor activity is officially discouraged. Rajan-equivalent worker Arjun in Delhi can't operate."*

**SurakshaAI Response:**
1. AQI API detects AQI > 300 in worker's operational zone for >4 continuous hours
2. Cross-checks delivery platform activity data (low-order volume confirms disruption)
3. Claim triggered → Income replacement payout issued

---

#### Scenario 3: Unplanned Bandh / Local Curfew 🚫
> *"A sudden city-wide bandh is declared at 6 AM. By 8 AM, roads are blocked. Rajan loses his peak morning hours."*

**SurakshaAI Response:**
1. Civic disruption feed detects bandh/curfew in worker's city
2. Combined with GPS inactivity, claim is initiated automatically
3. Worker notified, payout sent

---

## 🔁 System Workflow

### End-to-End Platform Flow

```mermaid
flowchart TD
    A([🚴 Gig Worker Opens App]) --> B[Onboarding\nName · Location · Platform · Work Hours\nAvg Weekly Income]
    B --> C{First Time\nUser?}
    C -- Yes --> D[Create Risk Profile\nZone · Historical Data · Income Tier]
    C -- No --> E[Load Existing Profile]
    D --> F
    E --> F[AI Risk Assessment Engine]

    F --> G[Pull Real-Time Data\nWeather API · AQI API\nCivic Alerts · Historical Disruptions]
    G --> H[Generate Risk Score\n0 to 100]

    H --> I{Risk Level?}
    I -- Low 0-33 --> J[Weekly Premium\n₹20/week]
    I -- Medium 34-66 --> K[Weekly Premium\n₹40/week]
    I -- High 67-100 --> L[Weekly Premium\n₹60/week]

    J --> M[Policy Created\nCoverage Confirmed]
    K --> M
    L --> M

    M --> N[Worker Dashboard\nActive Coverage · Risk Alerts · Wallet]

    N --> O{Disruption\nDetected?}
    O -- No --> P[Continuous Real-Time Monitoring\nEvery 15 Minutes]
    P --> O
    O -- Yes --> Q[Validate Event\nThreshold Check · GPS Activity Check\nDuplicate Check · Trust Score]

    Q --> R{Fraud\nSuspected?}
    R -- Yes --> S[🚨 Flag for Manual Review\nWorker Notified]
    R -- No --> T[Auto-Trigger Claim\nNo Worker Action Needed]

    T --> U[Calculate Payout\nBased on Income Tier + Hours Lost]
    U --> V[Instant Payout\nUPI / Paytm / Wallet]
    V --> W[Worker Notified ✅\nClaim Summary Sent]
    W --> N
```

---

### Weekly Policy Lifecycle

```mermaid
sequenceDiagram
    participant W as 👤 Worker
    participant App as 📱 SurakshaAI App
    participant AI as 🤖 AI Risk Engine
    participant Monitor as 📡 Monitoring Engine
    participant Fraud as 🛡️ Fraud Detection
    participant Pay as 💸 Payout Engine
    participant ExtAPI as 🌐 External APIs

    W->>App: Completes Onboarding
    App->>AI: Send Profile (zone, hours, income)
    AI->>ExtAPI: Fetch weather history, AQI trends, civic data
    ExtAPI-->>AI: Historical + real-time data
    AI-->>App: Risk Score + Recommended Premium
    App-->>W: Shows weekly premium quote

    W->>App: Confirms & Pays Premium
    App-->>W: Policy Activated (weekly coverage starts)

    loop Every 15 Minutes
        Monitor->>ExtAPI: Poll weather, AQI, civic feeds
        ExtAPI-->>Monitor: Current conditions
        Monitor->>Monitor: Check thresholds for worker's zone
    end

    ExtAPI-->>Monitor: Rainfall = 80mm/hr [THRESHOLD BREACHED]
    Monitor->>Fraud: Validate claim — check GPS, activity, duplicate
    Fraud-->>Monitor: Trust Score = 92 [VALID]
    Monitor->>Pay: Trigger payout for Worker ID #XYZ
    Pay-->>W: ₹350 credited to Paytm ⚡
    App-->>W: Push Notification — "Claim approved & paid!"
```

---

## 🗺️ User Flow Diagram

### Worker App — Complete User Journey

```mermaid
flowchart LR
    subgraph ONBOARDING["📋 ONBOARDING"]
        direction TB
        O1[Launch App] --> O2[Mobile OTP Login]
        O2 --> O3[Enter Name · City · Pin Code]
        O3 --> O4[Select Platform\nSwiggy / Zomato]
        O4 --> O5[Set Work Hours\nStart & End Time]
        O5 --> O6[Enter Avg Weekly Income\n₹ range]
        O6 --> O7[Grant GPS Permission]
    end

    subgraph RISK["🤖 RISK ASSESSMENT"]
        direction TB
        R1[AI Analyses Profile] --> R2[Fetch Zone Data\nWeather · AQI · Civic History]
        R2 --> R3[Compute Risk Score]
        R3 --> R4[Generate Weekly Premium\n₹20 / ₹40 / ₹60]
    end

    subgraph POLICY["📋 POLICY"]
        direction TB
        P1[View Premium Quote] --> P2[Select Coverage Period\n1 Week / 1 Month]
        P2 --> P3[Pay via UPI / Paytm / Card]
        P3 --> P4[Policy Active ✅]
    end

    subgraph DASHBOARD["📊 DASHBOARD"]
        direction TB
        D1[Home Screen] --> D2[Coverage Status\n🟢 Active]
        D1 --> D3[Risk Alert Banner\n⚠️ Rain tomorrow]
        D1 --> D4[Weekly Earnings\nProtected]
        D1 --> D5[Wallet Balance]
        D1 --> D6[Claims History]
    end

    subgraph CLAIM["⚡ AUTO-CLAIM"]
        direction TB
        C1[Disruption Detected\nBy System] --> C2[GPS Inactivity Confirmed]
        C2 --> C3[Fraud Check Passed]
        C3 --> C4[Payout Calculated]
        C4 --> C5[₹ Credited Instantly]
        C5 --> C6[Push Notification Sent]
    end

    ONBOARDING --> RISK --> POLICY --> DASHBOARD
    DASHBOARD --> CLAIM
    CLAIM --> DASHBOARD
```

---

### Admin Dashboard — Insurer Flow

```mermaid
flowchart TD
    Admin([🛠️ Admin Login]) --> AdminDash[Admin Dashboard]

    AdminDash --> A1[📊 Claims Overview\nTotal · Active · Paid · Rejected]
    AdminDash --> A2[🗺️ Risk Heatmap\nCity-wise disruption density]
    AdminDash --> A3[💰 Financial Metrics\nLoss Ratio · Premium Collected · Payouts]
    AdminDash --> A4[🚨 Fraud Alerts\nFlagged claims for manual review]
    AdminDash --> A5[👥 User Trust Scores\nPer-worker fraud risk rating]
    AdminDash --> A6[📅 Predictive Analytics\nNext-week risk forecast]

    A4 --> A4a{Review Claim}
    A4a -- Approve --> A4b[Release Payout]
    A4a -- Reject --> A4c[Notify Worker with Reason]
```

---

## 💰 Weekly Premium Model

### How Pricing Works

Our pricing is **dynamic and hyperlocal**, recalculated every Monday for the upcoming week.

```
Weekly Premium = Base Rate × Zone Risk Multiplier × Income Tier Multiplier × Seasonality Factor
```

| Variable | Description | Example Values |
|---|---|---|
| Base Rate | Minimum weekly floor | ₹20 |
| Zone Risk Multiplier | Based on historical disruption frequency in pin code | 1.0x – 2.5x |
| Income Tier Multiplier | Higher earners pay slightly more (more to protect) | 0.9x – 1.4x |
| Seasonality Factor | Monsoon, winter smog season | 1.0x – 1.8x |

### Premium Tiers

| Risk Level | Risk Score | Weekly Premium | Weekly Coverage Cap |
|---|---|---|---|
| 🟢 Low | 0 – 33 | ₹20 | ₹600 (max payout/week) |
| 🟡 Medium | 34 – 66 | ₹40 | ₹1,200 (max payout/week) |
| 🔴 High | 67 – 100 | ₹60 | ₹2,000 (max payout/week) |

### Premium Pricing Flow

```mermaid
flowchart LR
    A[Worker Profile\nZone · Income · Hours] --> B[Historical Data\nDisruption frequency\nin zone - past 52 weeks]
    B --> C[Real-Time Data\nWeather forecast\nAQI trend next 7 days]
    C --> D[AI Pricing Model\nWeighted risk score]
    D --> E{Risk Score}
    E -- 0–33 --> F[₹20/week\n🟢 Low Risk]
    E -- 34–66 --> G[₹40/week\n🟡 Medium Risk]
    E -- 67–100 --> H[₹60/week\n🔴 High Risk]
    F --> I[Policy Issued\nCoverage Active for 7 Days]
    G --> I
    H --> I
```

---

## 📡 Parametric Triggers

Triggers are **objective, measurable thresholds** — not subjective assessments. When a threshold is breached AND the worker's GPS confirms inactivity, a claim is auto-initiated.

### Trigger Matrix

| Trigger Type | Data Source | Threshold | Validation | Payout % of Daily Income |
|---|---|---|---|---|
| Heavy Rainfall | OpenWeatherMap API | > 35mm/hr for 2+ hrs | GPS inactivity + order drop | 60% |
| Extreme Heat | OpenWeatherMap API | > 43°C sustained 3+ hrs | GPS inactivity | 40% |
| Severe AQI | AQICN / IQAir API | AQI > 300 for 4+ hrs | GPS inactivity + order volume drop | 50% |
| Flood / Waterlogging | IMD Alert Feed | Red/Orange alert issued | GPS inactivity | 70% |
| Civic Bandh / Curfew | Govt. Alert Feed (mock) | Official bandh declared | GPS inactivity | 80% |

### Trigger Decision Logic

```mermaid
flowchart TD
    T1[Real-Time Data Received] --> T2{Threshold\nBreached?}
    T2 -- No --> T3[Log Reading\nContinue Monitoring]
    T2 -- Yes --> T4[Check Worker GPS\nIs worker inactive in affected zone?]

    T4 -- Worker Active --> T5[No Claim\nWorker is working normally]
    T4 -- Worker Inactive --> T6[Check Claim History\nDuplicate claim in same window?]

    T6 -- Duplicate Found --> T7[🚨 Flag as Duplicate\nNo Payout]
    T6 -- No Duplicate --> T8[Run Fraud Score Check]

    T8 -- Trust Score < 50 --> T9[🚨 Flag for Manual Review]
    T8 -- Trust Score ≥ 50 --> T10[✅ Auto-Approve Claim]

    T10 --> T11[Calculate Payout\nHours lost × Income rate\nCapped by weekly maximum]
    T11 --> T12[Initiate UPI / Wallet Transfer]
    T12 --> T13[Send Push Notification to Worker]
```

---

## 🤖 AI/ML Integration Plan

### 1. Risk Scoring Model (Premium Calculation)

**Algorithm:** Gradient Boosted Decision Tree (XGBoost or LightGBM)

**Input Features:**
- Worker's pin code zone (encoded)
- Historical disruption frequency in zone (past 52 weeks)
- Average disruption duration in zone
- Worker's typical working hours (shift overlap with disruption windows)
- Platform (Swiggy/Zomato — proxy for order density)
- Seasonal factor (month of year)
- Rolling 7-day weather forecast risk score

**Output:** Risk Score (0–100) → Maps to ₹20 / ₹40 / ₹60 weekly premium

**Training Data:** We bootstrap using mock historical data generated from IMD open datasets, CPCB AQI records, and synthetic disruption logs for Bengaluru, Mumbai, Delhi, Chennai, Hyderabad.

---

### 2. Claim Validation Model (Fraud Detection)

**Algorithm:** Isolation Forest for anomaly detection + Rule-based override layer

**Checks performed:**
- GPS location at time of disruption (was worker in affected zone?)
- GPS movement pattern (stationary = likely not working)
- Historical claim frequency for this worker
- Platform order volume in zone (external signal — via mock)
- Time-of-day patterns (does worker normally work in this window?)

**Output:** Trust Score (0–100). Claims with Trust Score ≥ 50 auto-approve.

---

### 3. Predictive Alert Engine

**Purpose:** Notify workers 12–24 hours before a likely disruption.

**Logic:**
- Pull 7-day weather forecast for worker's zone
- If forecast meets trigger threshold with >60% confidence → send alert
- Worker can choose to activate premium coverage before the event

**Example alert:** *"⚠️ High rainfall forecast tomorrow (8 AM–2 PM) in Koramangala. Your ₹40 coverage is active and will trigger automatically if rain exceeds thresholds."*

---

### AI Integration Architecture

```mermaid
flowchart TD
    subgraph DATA_SOURCES["📥 Data Sources"]
        DS1[OpenWeatherMap API]
        DS2[AQICN / IQAir API]
        DS3[IMD Alert Feed]
        DS4[Civic Alert Feed Mock]
        DS5[GPS Location Stream]
        DS6[Historical Disruption DB]
    end

    subgraph AI_ENGINE["🤖 AI Engine"]
        AE1[Feature Engineering\nPipeline]
        AE2[Risk Scoring Model\nXGBoost]
        AE3[Fraud Detection Model\nIsolation Forest]
        AE4[Alert Prediction\nForecast Engine]
    end

    subgraph OUTPUTS["📤 Outputs"]
        O1[Weekly Premium\n₹20 / ₹40 / ₹60]
        O2[Trust Score\nPer claim]
        O3[Predictive Alert\n24hr early warning]
    end

    DATA_SOURCES --> AE1
    AE1 --> AE2 --> O1
    AE1 --> AE3 --> O2
    AE1 --> AE4 --> O3
```

---

## 🛡️ Fraud Detection Architecture

Fraud in parametric insurance is uniquely dangerous because payouts are automatic. Our multi-layer fraud detection catches bad actors before a single rupee is wrongly paid.

### Fraud Scenarios We Address

| Fraud Type | Description | Detection Method |
|---|---|---|
| GPS Spoofing | Worker fakes location to appear in disruption zone | GPS velocity check, device sensor cross-check |
| Fake Inactivity | Worker is active but claims inactivity | Order activity cross-check via mock platform API |
| Duplicate Claims | Same disruption event claimed multiple times | Claim deduplication by event window + worker ID |
| Collusion Ring | Multiple workers in same area mass-claiming identical events | Cluster anomaly detection on concurrent claims |
| Profile Fraud | Fake income declaration to inflate payout | Income declared vs. platform earnings cross-check |

### Trust Score Calculation

```
Trust Score = w1(GPS_Valid) + w2(Activity_Consistent) + w3(History_Clean) + w4(Pattern_Normal) + w5(Income_Verified)
```

Each component scored 0–20, summed to 0–100.

### Fraud Decision Flow

```mermaid
flowchart TD
    FC1[Claim Initiated] --> FC2[Layer 1: Rule-Based Checks\nDuplicate? · Window valid? · Zone match?]
    FC2 -- Fail --> FC3[🚨 Auto-Reject\nNotify Worker with Reason]
    FC2 -- Pass --> FC4[Layer 2: GPS Validation\nLocation in disruption zone?\nVelocity plausible?]
    FC4 -- Suspicious --> FC5[🚨 Flag for Manual Review]
    FC4 -- Valid --> FC6[Layer 3: Activity Check\nOrders placed? Platform activity? Movement?]
    FC6 -- Active --> FC7[🚨 Reject — Worker Was Active]
    FC6 -- Inactive --> FC8[Layer 4: ML Anomaly Score\nIsolation Forest]
    FC8 -- Anomalous --> FC5
    FC8 -- Normal --> FC9[✅ Claim Approved\nTrust Score Assigned]
    FC9 --> FC10[Payout Triggered]
```

---

## 🛡️ Adversarial Defense & Anti-Spoofing Strategy

> **⚠️ CRITICAL THREAT ALERT (March 19, 2026)**
> A sophisticated syndicate of 500+ delivery workers in a tier-1 city has exploited beta parametric insurance platforms using advanced GPS-spoofing applications. They organize via Telegram groups to fake locations in severe weather zones, triggering mass false payouts and draining liquidity pools. **SurakshaAI is the next target. Simple GPS verification is officially obsolete.**

This section documents our multi-layered adversarial defense strategy — built to survive in a hostile environment where organized fraud rings actively probe for weaknesses.

---

### 🎯 The Core Problem: Why GPS Alone Fails

Basic GPS coordinate verification is fundamentally broken against modern spoofing tools:

| Attack Vector | How It Works | Why Basic GPS Fails |
|---|---|---|
| **GPS Spoofing Apps** | Fake GPS location apps (mock location enabled) place worker anywhere in the world | System only sees coordinates, not how they were obtained |
| **Telegram Coordination** | Syndicate leaders broadcast: *"Spoof to Koramangala, claim now!"* | Individual claim checks pass; mass timing is the tell |
| **VPN + GPS Combo** | Spoofs GPS location while routing IP through VPN in target zone | IP geolocation confirms spoofed zone |
| **Simulated Inactivity** | Bad actor spoofs location AND keeps phone completely idle | Stationary behavior matches genuine workers stuck at home |

**Our Response:** We never trust a single data source. Every claim is validated against 7+ independent signals before a rupee is paid.

---

### 🧠 1. AI/ML Architecture: Genuine Worker vs. Spoofer Differentiation

Our fraud detection doesn't look at GPS coordinates — it looks at **behavioral fingerprints** that are impossible to fake without being physically present.

#### Multi-Signal Trust Score (0–100)

```
Final Trust Score = f(Sensor_Consistency, Behavioral_Anomaly, Social_Graph, Platform_Activity, Historical_Pattern)
```

| Signal | Data Source | Weight | What It Detects |
|---|---|---|---|
| **Sensor Fusion Check** | Accelerometer + Gyroscope + Barometer | 25% | Spoofed GPS vs. real device motion |
| **Cell Tower Clustering** | Nearby cell tower IDs (not just lat/lon) | 20% | Worker in zone physically (not just GPS) |
| **Platform Order Activity** | Mock Swiggy/Zomato API (order history) | 20% | Was worker receiving/accepting orders? |
| **Velocity Anomaly** | GPS change rate over time | 15% | Impossible travel speeds (spoofing glitch) |
| **Wi-Fi SSID Fingerprint** | Nearby Wi-Fi network names | 10% | Home Wi-Fi vs. different zone's Wi-Fi |
| **Timezone Consistency** | Device local time vs. claimed zone | 5% | Worker in different timezone than zone |
| **Historical Deviation** | Claim pattern vs. past 12 weeks | 5% | Sudden behavioral change (syndicate join) |

#### Sensor Fusion: The Anti-Spoofing Key

Genuine phones produce **correlated sensor data**:

```
Physical GPS Movement → Accelerometer registers acceleration/deceleration
                    → Gyroscope registers direction changes  
                    → Barometer registers altitude shifts (floors, flyovers)
                    → All signals MUST correlate within physics constraints
```

**Spoofed locations produce:**
- GPS coordinates teleport (no intermediate positions)
- Accelerometer shows stationary (no motion detected)
- Gyroscope shows no movement
- **→ Mismatch flagged: TRIPLET_CONTRADICTION**

```mermaid
flowchart TD
    SG1[GPS Coordinates\nReported: Koramangala] --> SG2{Sensor Fusion Check}
    
    SG2 --> A[Accelerometer:\nMotion Detected?]
    SG2 --> B[Gyroscope:\nDirection Change?]
    SG2 --> C[Barometer:\nAltitude Change?]
    
    A --> D{Signals\nCorrelated?}
    B --> D
    C --> D
    
    D -- Yes --> E[✅ Device Physically\nMoving in Zone]
    D -- No --> F[🚨 TRIPLET_CONTRADICTION\nGPS Spoofing Detected]
    
    E --> G{All Other\nSignals Pass?}
    F --> H[🚨 Flag for Manual Review\nAuto-Reject Payout]
    
    G -- Yes --> I[✅ Genuine Worker\nConfirmed]
    G -- No --> H
```

---

### 🔍 2. Coordinated Fraud Ring Detection: Beyond Individual Claims

When 500 workers claim simultaneously from the "same zone," that's not a weather event — that's a syndicate. Our system detects coordinated attacks using **graph analysis and temporal clustering**.

#### Data Points Analyzed for Ring Detection

| Category | Data Point | Purpose |
|---|---|---|
| **Temporal** | Claim timestamp distribution | All claims within 5-minute window = coordinated attack |
| **Spatial** | GPS coordinate clustering | Claims from exact same lat/lon (bot-generated) |
| **Device** | Device ID patterns | 50 workers on same device manufacturer+model bought same week |
| **Network** | IP address clustering | 100 workers sharing same IP (VPN exit node) |
| **Behavioral** | Silent for weeks → sudden activity | Syndicate recruits new members, activates them |
| **Social** | Contact graph (if permissions granted) | Workers in same WhatsApp/Telegram group = syndicate |
| **Financial** | Payout withdrawal timing | All withdraw within 60 seconds of payout |
| **Onboarding** | Registration velocity | 200 workers sign up in same hour from same pin code |

#### Ring Detection Algorithm: DBSCAN + Isolation Forest

```python
# Pseudocode for Coordinated Fraud Detection
anomaly_features = [
    claim.timestamp,
    gps.latitude,
    gps.longitude,
    device_id,
    ip_address,
    accelerometer_variance,
    cell_tower_hash,
    historical_claim_count
]

isolation_forest_score = isolation_forest.predict(anomaly_features)
cluster_density = dbscan.fit_predict(spatial_temporal_claims)

if isolation_forest_score < -0.5 AND cluster_density > 0.7:
    FLAG_COORDINATED_FRAUD_RING()
    AUTO_REJECT_ALL_CLAIMS_IN_CLUSTER()
    NOTIFY_ADMIN_DASHBOARD()
```

#### Ring Detection Flow

```mermaid
flowchart TD
    RD1[New Claims Batch\nReceived] --> RD2[Temporal Clustering\nClaims within 5-min window?]
    
    RD2 -- Yes --> RD3{Spatial Clustering\nClaims from same\nlat/lon ±10m?}
    RD2 -- No --> RD4[Individual Claim Processing]
    
    RD3 -- Yes --> RD5[🚨 SUSPICIOUS CLUSTER\nHigh Coordination Score]
    RD3 -- No --> RD6[Check Individual\nTrust Scores]
    
    RD5 --> RD7{Network/Device\nClustering Detected?}
    RD7 -- Yes --> RD8[🚨 CONFIRMED SYNDICATE\nBlock All Claims\nAlert Admin Immediately]
    RD7 -- No --> RD9[⚠️ Flag for Review\nClaims Under Scrutiny]
    
    RD6 --> RD10{Trust Score\n≥ 70?}
    RD6 --> RD11[⚠️ Medium Trust Claims\nAdded to Review Queue]
    
    RD10 -- Yes --> RD12[✅ Individual Claims\nApproved + Monitored]
    RD10 -- No --> RD11
    
    RD9 --> RD13[Manual Review Panel\nCross-checks all signals]
    RD13 --> RD14{Override?\nEvidence of Genuine?}
    RD14 -- Yes --> RD12
    RD14 -- No --> RD15[🚨 Confirmed Syndicate\nClaims Rejected + Banned]
```

---

### ⚖️ 3. UX Balance: Fair Treatment for Genuine Workers

The biggest risk of aggressive fraud detection: **penalizing honest workers** who have genuine network drops, phone battery issues, or are just in areas with poor connectivity. We handle this with a **"Presumption of Innocence" tiered system**.

#### Claim States and Worker Experience

| Status | Meaning | Worker Experience |
|---|---|---|
| 🟢 **Auto-Approved** | Trust Score ≥ 70, all signals green | Instant payout, ₹ credited in <5 min |
| 🟡 **Under Review** | Trust Score 40–69, some signals unclear | "Your claim is being verified. No action needed." |
| 🔴 **Flagged** | Trust Score < 40 OR ring detected | "We've detected unusual activity. Our team will review within 24 hours." |
| ✅ **Escalated (False Positive)** | Honest worker wrongly flagged | "Our team verified your claim. ₹ credited. Sorry for the delay!" |

#### Honest Worker Protection Mechanisms

**1. Grace Period for Sensor Discrepancies**
- If accelerometer contradicts GPS due to phone dying mid-journey → 30-minute grace window
- Worker notified: *"Phone inactivity detected. If you experienced a network issue, no action needed — we'll verify automatically."*

**2. Contextual Claim Review**
- Rainy season: Lower threshold for approval (more likely to be genuine)
- Rare event (once per year): More leniency than repeated claims
- First-time claimant: Presumption of genuine unless strong evidence

**3. Appeal Mechanism**
- Flagged workers can submit: *"I was genuinely in the zone — my phone died / network dropped"*
- System accepts: battery charging history, carrier outage reports, witness verification
- 95% of legitimate appeals resolved within 4 hours

**4. "Network Drop" Signal Recognition**
```mermaid
flowchart TD
    ND1[GPS Signal Lost\n>15 Minutes] --> ND2{Wi-Fi Connected\nat Last Known Location?}
    
    ND2 -- Yes --> ND3[✅ Worker at Home\nWi-Fi matches home network SSID]
    ND2 -- No --> ND4{Cell Tower Connection\nat Disruption Time?}
    
    ND4 -- Yes --> ND5[✅ Worker in Zone\nCell tower in affected area]
    ND4 -- No --> ND6[Check Platform\nActivity at Time?]
    
    ND6 -- No Orders --> ND7[⚠️ Unclear\nFlag for Review\nDo NOT Auto-Reject]
    ND6 -- Orders Found --> ND8[🚨 Worker Active\nReject Claim]
    
    ND3 --> ND9[✅ Claim Approved\nNetwork drop confirmed]
    ND5 --> ND9
```

---

### 🛡️ Defense-in-Depth: 6-Layer Architecture

Our anti-spoofing strategy is not a single checkpoint — it's a series of overlapping defenses where each layer compensates for the weaknesses of others.

```mermaid
flowchart TD
    subgraph LAYER1["Layer 1: Device Integrity"]
        D1["Root/Jailbreak Detection"]
        D2["Spoofing App Detection<br/>(Play Integrity API)"]
        D3["Developer Mode Check"]
    end
    
    subgraph LAYER2["Layer 2: GPS Validation"]
        D4["Multi-constellation<br/>GPS + GLONASS + Galileo"]
        D5["Accuracy Confidence<br/>Score (<10m required)"]
        D6["Altitude Cross-check<br/>(with terrain database)"]
    end
    
    subgraph LAYER3["Layer 3: Sensor Fusion"]
        D7["Accelerometer<br/>Motion Correlation"]
        D8["Gyroscope<br/>Direction Correlation"]
        D9["Barometer<br/>Altitude Correlation"]
    end
    
    subgraph LAYER4["Layer 4: Contextual Signals"]
        D10["Cell Tower<br/>Clustering"]
        D11["Wi-Fi SSID<br/>Fingerprint"]
        D12["Platform Order<br/>Activity"]
    end
    
    subgraph LAYER5["Layer 5: Behavioral Analysis"]
        D13["Historical Pattern<br/>Deviation"]
        D14["Velocity<br/>Anomaly"]
        D15["Timezone<br/>Consistency"]
    end
    
    subgraph LAYER6["Layer 6: Ring Detection"]
        D16["Temporal<br/>Clustering"]
        D17["Spatial<br/>Clustering"]
        D18["Network/Device<br/>Correlation"]
    end
    
    LAYER1 --> LAYER2 --> LAYER3 --> LAYER4 --> LAYER5 --> LAYER6
    
    LAYER1 -.->|Fail at any layer| R1["🚨 Flagged<br/>For Review"]
    LAYER2 -.-> R1
    LAYER3 -.-> R1
    LAYER4 -.-> R1
    LAYER5 -.-> R1
    LAYER6 -.-> R1
    
    LAYER6 -.->|Pass all layers| R2["✅ Auto-Approve<br/>Payout Released"]
```

---

### 📊 Threat Response Playbook

| Scenario | Detection Method | Response | Honest Worker Impact |
|---|---|---|---|
| **500 workers claim simultaneously** | Temporal clustering + ring detection | All claims held, batch reviewed, syndicate identified | Genuine workers notified within 2 hours, payouts released |
| **Individual GPS spoofing** | Sensor fusion contradiction | Trust score drops below 50, claim flagged | Worker notified, appeal option available |
| **Fake inactivity (worker active on delivery)** | Platform order API cross-check | Claim rejected, trust score permanently lowered | Appeal shows genuine situation → partial payout |
| **Phone battery died mid-shift** | Battery charging event + cell tower last-seen | Grace period applied, claim approved | No action needed, automatic verification |
| **Network drop in affected zone** | Wi-Fi SSID + cell tower confirmation | Claim approved with delay message | "Verification complete, ₹ credited" |

---

### 🚨 Red Lines: Zero-Tolerance Policies

To protect the liquidity pool and honest workers:

1. **First Offense (Individual):** Trust score reset to 0, claim rejected, 30-day cooldown
2. **First Offense (Ring):** All ring members permanently banned, admin notification
3. **Second Offense:** Blacklist device + phone number across platform
4. **Whistleblower Reward:** Workers who report syndicate activity earn ₹500 bounty

---

### 🔮 Why We're Smarter Than the Syndicates

| Syndicate Tactic | Our Counter |
|---|---|
| Spoof GPS to "rain zone" | Sensor fusion detects no motion |
| Keep phone completely idle | Cell tower + Wi-Fi fingerprint shows wrong location |
| Claim in coordinated burst | Temporal + spatial clustering flags entire batch |
| Use VPN to mask IP | IP geolocation checked against GPS zone |
| All claim same payout amount | Payout variance analysis detects bot behavior |
| Stay silent for weeks, then activate | Historical pattern deviation alerts |

**Bottom Line:** Spoofing GPS is easy. Spoofing 7 independent, physics-constrained signals simultaneously — while coordinating with 499 others without triggering temporal alerts — is economically impractical.

Our system raises the cost of fraud far above the payout value, making exploitation unprofitable.

---

## 📱 Platform Justification: Web + Mobile

### Primary: Mobile App (React Native)

**Why mobile-first for workers:**
- Gig workers access everything on their phone — Swiggy app, Google Maps, UPI all mobile
- GPS permissions required for location-based validation → mobile native
- Push notifications for real-time disruption alerts → essential for zero-touch UX
- Low-end Android device support is critical (₹8,000–₹15,000 phones)
- Offline-first design: basic dashboard functions work without internet

### Secondary: Web Dashboard (React.js)

**Why web for admin/insurer:**
- Insurers and admin review complex analytics, heatmaps, and fraud alerts on desktop
- No installation friction for business stakeholders
- Better for detailed data tables, export, and reporting

---

## 🧱 Tech Stack

### Frontend

| Layer | Technology | Reason |
|---|---|---|
| Mobile App | React Native (Expo) | Cross-platform iOS + Android; fast dev cycles |
| Web Admin Dashboard | React.js + TailwindCSS | Component-based, fast, responsive |
| Maps & Heatmap | Leaflet.js / React-Leaflet | Open-source, lightweight |
| Charts | Recharts / Chart.js | Clean insurance analytics visuals |

### Backend

| Layer | Technology | Reason |
|---|---|---|
| API Server | Node.js + Express | Fast prototyping, wide ecosystem |
| Auth | JWT + OTP (Firebase/MSG91) | Secure, mobile-native OTP login |
| Background Jobs | Bull (Redis-backed) | Async claim processing, monitoring triggers |
| Cron / Scheduler | Node-cron | Weekly premium triggers, monitoring loops |

### AI / ML

| Component | Technology | Reason |
|---|---|---|
| Risk Scoring | Python (scikit-learn / XGBoost) | Industry-standard ML; fast inference |
| Fraud Detection | Python (Isolation Forest) | Unsupervised anomaly detection |
| Model Serving | FastAPI microservice | Lightweight, easy REST API for ML models |
| Data Pipeline | Pandas + NumPy | Data preprocessing |

### Database

| Layer | Technology | Reason |
|---|---|---|
| Primary DB | MongoDB (Atlas Free Tier) | Flexible schema for insurance policies, claims |
| Cache | Redis (Upstash Free Tier) | Session cache, rate limiting, job queues |

### External APIs

| API | Purpose | Tier |
|---|---|---|
| OpenWeatherMap | Real-time + forecast weather | Free tier (1,000 calls/day) |
| AQICN | Real-time AQI data | Free tier |
| IMD Open Data | Official Indian weather alerts | Free / Public |
| Mock Civic API | Curfew / bandh events | Mocked JSON server |
| Mock Payment | UPI / Paytm payout simulation | Razorpay Test Mode |
| Mock Platform API | Swiggy/Zomato order volume | Mocked JSON server |

---

## 📅 Development Plan

```mermaid
gantt
    title SurakshaAI — 6-Week Development Roadmap
    dateFormat  YYYY-MM-DD
    section Phase 1 — Ideation
    Problem Research & Persona Definition     :done, p1a, 2026-03-04, 4d
    System Architecture Design               :done, p1b, 2026-03-08, 4d
    Tech Stack Finalization                  :done, p1c, 2026-03-12, 3d
    README & Idea Document                   :done, p1d, 2026-03-15, 5d
    2-Minute Pitch Video                     :active, p1e, 2026-03-18, 2d

    section Phase 2 — Automation
    Project Scaffolding & DB Setup           :p2a, 2026-03-21, 3d
    Worker Onboarding & Auth Module          :p2b, 2026-03-24, 4d
    AI Risk Engine (MVP)                     :p2c, 2026-03-26, 5d
    Dynamic Premium Calculation              :p2d, 2026-03-28, 4d
    Policy Management Module                 :p2e, 2026-04-01, 3d
    Claims Management (Basic)               :p2f, 2026-04-02, 2d

    section Phase 3 — Scale
    Advanced Fraud Detection                 :p3a, 2026-04-05, 5d
    Instant Payout Simulation                :p3b, 2026-04-07, 4d
    Worker Dashboard (Complete)              :p3c, 2026-04-09, 4d
    Admin Dashboard & Heatmap                :p3d, 2026-04-11, 4d
    Final Demo Video + Pitch Deck            :p3e, 2026-04-14, 3d
```

### Phase 1 Deliverables (Current) ✅

- [x] Persona research and scenario analysis
- [x] System architecture design
- [x] AI/ML integration plan
- [x] Premium model definition
- [x] Parametric trigger matrix
- [x] Tech stack selection
- [x] README (this document)
- [ ] GitHub repository setup
- [ ] 2-minute strategy video

### Phase 2 Deliverables (March 21 – April 4)

- [ ] Worker registration + OTP login
- [ ] AI risk scoring service (FastAPI)
- [ ] Dynamic weekly premium calculation
- [ ] Policy creation flow
- [ ] Real-time monitoring engine (3–5 API triggers)
- [ ] Basic claims management
- [ ] 2-minute demo video

### Phase 3 Deliverables (April 5 – 17)

- [ ] Advanced multi-layer fraud detection
- [ ] Instant payout simulation (Razorpay test mode)
- [ ] Worker dashboard (complete)
- [ ] Admin/insurer dashboard with analytics
- [ ] Predictive alert engine
- [ ] 5-minute final demo video
- [ ] Final pitch deck (PDF)

---

## 💼 Business Model

### Revenue Streams

| Source | Model | Est. Monthly Revenue (at 10,000 users) |
|---|---|---|
| Weekly Premiums | ₹20–₹60/worker/week | ₹8L – ₹24L/month |
| Platform Partnerships | B2B licensing to Swiggy/Zomato | Custom pricing |
| Data Insights (Anonymised) | Sell disruption risk maps to logistics companies | ₹2L–₹5L/month |

### Unit Economics (Per Worker / Month)

```
Average Premium Collected  :  ₹160/month (₹40/week × 4)
Average Claim Payout       :  ₹90/month  (estimated 1.8 events/month)
Gross Margin per Worker    :  ₹70/month
Loss Ratio Target          :  55–60%
```

### Sustainability Check

- A consistent 3-star rating in DEVTrails earns DC 82,000 — covering the DC 75,000 burn
- Our target: 4–5 star ratings through strong AI innovation and polished UX
- Community activities (blogs, peer help) to generate supplementary DC income

---

## 🚧 Scope Boundaries

### ✅ What We Cover (Income Loss Only)

- Income lost due to rainfall-triggered inability to work
- Income lost due to extreme heat (unsafe outdoor conditions)
- Income lost due to hazardous AQI / GRAP restrictions
- Income lost due to civic disruptions (curfews, bandhs, zone closures)
- Income lost due to flooding / waterlogging in operational zone

### ❌ What We Explicitly Exclude (Per Problem Statement Rules)

- ❌ Vehicle repair costs
- ❌ Health insurance / medical bills
- ❌ Accident coverage
- ❌ Life insurance
- ❌ Personal property damage
- ❌ Platform-level disputes (e.g., account suspension by Swiggy)

---

## 🚀 Future Scope

- **Multi-platform expansion:** Zepto, Amazon, Dunzo, Porter
- **Real UPI integration:** Live payouts via Razorpay/PhonePe APIs
- **Advanced ML:** Deep learning models with satellite imagery for flood detection
- **BNPL Premiums:** "Pay Premium from Payout" model for zero upfront cost
- **Expansion verticals:** Auto rickshaw drivers, construction daily wage workers

---

## 👨‍💻 Team

| Role | Member |
|---|---|
| Team Lead | [Pranav Verma] |
| Full-Stack / AI Engineer | [Sourav Kumar] |
| Backend | [Garv Raj] |
| Frontend | [Ameya Gupta] |
| UI/UX + Research | [Lasya Priya] |

**Repository:** [GitHub Link (https://github.com/itzsouravkumar/SurakshaAI)]

**Demo Video:** [YouTube/Drive Link — to be added]

---



> *"SurakshaAI isn't just insurance. It's a financial safety net that thinks ahead, acts instantly, and never asks the worker to do more than their job."*

---

*Built for Guidewire DEVTrails 2026 | Unicorn Chase | Phase 1 Submission*
