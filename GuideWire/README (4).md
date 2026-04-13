<div align="center">
  <h1>⚡ Hustlr</h1>
  <h3>Real-Time Income Protection Engine for India's Gig Delivery Workers</h3>

  <a href="https://youtu.be/nD2snI4Tnu8?si=eS5sztT0aibvxodI">
    <img src="https://img.shields.io/badge/Watch_Demo_Video-FF0000?style=for-the-badge&logo=youtube&logoColor=white" alt="Watch Video"/>
  </a>
  <br><br>
  <strong>🏆 Guidewire DEVTrails 2026 — Phase 1 Submission</strong><br>
  <strong>👥 Team:</strong> [Code Crackers] &nbsp;|&nbsp; <strong>🎯 Persona:</strong> Q-Commerce Delivery Partners (Zepto)
</div>

---

## 📋 Table of Contents

1. [TL;DR](#-tldr)
2. [The Problem](#-the-problem)
3. [What Hustlr Is](#-what-hustlr-is)
4. [Chosen Persona: Q-Commerce Delivery Partner](#-chosen-persona-q-commerce-delivery-partner)
5. [How Hustlr Works — 15-Second View](#-how-hustlr-works--15-second-view)
6. [What Hustlr Covers](#-what-hustlr-covers)
7. [Insurance Partner Model](#-insurance-partner-model)
8. [Guidewire Integration](#️-guidewire-integration)
9. [Parametric Logic — Core Principle](#-parametric-logic--core-principle)
10. [Trigger Parameters](#-trigger-parameters)
11. [Compound Triggers — Elite Shield](#-compound-triggers--elite-shield)
12. [Anti-Gaming Rules](#-anti-gaming-rules)
13. [Manual Claim Filing — UX Flow](#-manual-claim-filing--ux-flow)
14. [Internet Zone Blackout — Trigger Architecture](#-internet-zone-blackout--trigger-architecture)
15. [Accident Blockspot — Trigger Architecture](#-accident-blockspot--trigger-architecture)
16. [Heavy Traffic Congestion — Trigger Architecture](#-heavy-traffic-congestion--trigger-architecture)
17. [Real Scenario Simulations](#-real-scenario-simulations)
18. [Adversarial Defense & Anti-Spoofing Strategy](#️-adversarial-defense--anti-spoofing-strategy)
19. [Zone Depth Scoring — Anti-Boundary Gaming](#-zone-depth-scoring--anti-boundary-gaming)
20. [AI/ML Architecture](#-aiml-architecture)
21. [Regional Behavioral Intelligence Layer](#-regional-behavioral-intelligence-layer)
22. [Innovation Differentiators](#-innovation-differentiators)
23. [Weekly Premium Tiers](#-weekly-premium-tiers)
24. [City Risk Profiles](#️-city-risk-profiles)
25. [End-to-End Workflow](#-end-to-end-workflow-full)
26. [System Reliability — Fallback Hierarchy](#-system-reliability--fallback-hierarchy)
27. [Platform Decision — Mobile App (Flutter)](#️-platform-decision--mobile-app-flutter)
28. [Tech Stack](#️-tech-stack)
29. [MVP Scope — Phase 1](#-mvp-scope--phase-1)
30. [Cost Efficiency](#-cost-efficiency)
31. [6-Week Plan](#-6-week-plan)
32. [Business Viability & Financial Model](#-business-viability--financial-model)
33. [IRDAI Compliance](#-irdai-compliance)
34. [Team](#-team)
35. [Phase 1 Deliverables](#-phase-1-deliverables)

---

## 🧭 TL;DR

**Who:** Q-commerce delivery riders (Zepto) — 2–3 km radius, one dark store, zero income safety net.

**Problem:** One flooded street eliminates their entire working zone. No insurance product covers this. 80+ disruption days a year go uncompensated.

**What Hustlr does:** Monitors 9 real-time disruption triggers. When one fires and the rider is on shift — a fixed payout hits their UPI automatically. No claim filed. No adjuster. Under 2 minutes.

**How it's built:** Flutter app · Node.js + Supabase backend · 7 AI/ML models · 6-layer fraud engine · Zone depth scoring · Regional behavioral intelligence · Full Guidewire integration (PolicyCenter + ClaimCenter + BillingCenter).

**Numbers:** ₹29–₹109/week · ₹150/day payout cap · 55–65% projected loss ratio · ₹0 infrastructure cost · 10,000-worker Chennai pilot.

> *"When there's a curfew, I can't deliver. When the app crashes, I can't deliver. When a road accident blocks my route, I can't deliver. Those days, I earn zero rupees — but my rent doesn't know that."*
> — **Karthik, 24, Zepto Q-commerce delivery rider, Chennai**

---

## 🔴 The Problem

India has **7.7 million** gig delivery workers. Q-commerce riders — the people delivering groceries in 10 minutes for Zepto — face the sharpest version of this problem. They operate within a strict 2–3 km radius of a single dark store. They earn ₹4,000–₹6,000 per week with no paid leave, no sick days, and no safety net. One flooded street eliminates their entire working zone. A dark store going offline wipes out a full shift. Chennai alone sees **~80 rain days per year** — on each one, a rider loses ₹400–₹600. Cyclone Michaung wiped out 3–4 days of income per worker with zero recourse.

Every existing insurance product covers accidents, hospitalization, and death — events that happen rarely. Not one covers the income disruption that happens 80+ days a year.

Hustlr fixes the right problem.

---

## 💡 What Hustlr Is

Hustlr is **not an insurance company.** It is an **underwriting intelligence engine** that enables licensed insurers to profitably serve gig workers — a segment traditional insurance has never been able to reach.

---

## 👤 Chosen Persona: Q-Commerce Delivery Partner

**Persona:** A Zepto delivery partner operating in Chennai — Velachery, Adyar, or Tambaram dark store zones.

Workers are registered on a **single primary platform only**, in compliance with Zepto's partner exclusivity agreement. Insurance is priced based on that platform's activity data alone — keeping the model legally clean and operationally simple.

### Why Q-Commerce?

| Factor | Q-Commerce (Zepto) | Food (Zomato/Swiggy) | E-Commerce (Amazon/Flipkart) |
|--------|---------------------------|----------------------|------------------------------|
| Delivery frequency | 15–25 orders/day | 8–15 orders/day | 3–8 orders/day |
| Hyperlocal sensitivity | Extreme (dark store zones) | High | Moderate |
| Weather vulnerability | Critical (monsoon paralysis) | High | Low–Medium |
| Worker density per zone | Very high (cluster-based) | Medium | Spread out |
| Fraud surface area | High (zone-based clustering) | Medium | Low |

Q-commerce workers operate within **tight geographic zones** anchored to dark stores, making parametric triggers more precise (zone-level, not city-level), fraud detection more nuanced (cluster behaviour becomes a signal), and income modeling more predictable (orders/hour baselines are tight).

### Persona Profile: "Karthik, 24, Zepto Partner, Adyar Dark Store Zone, Chennai"

| Attribute | Value |
|---|---|
| Platform | Zepto (single platform — partner agreement compliant) |
| Weekly earnings | ₹4,200 (~₹600/day, ~₹60/hr over a 10-hr shift) |
| Shift window | 8 AM – 10 PM (derived from 30-day activity history) |
| Peak slots | Morning 8–11 AM · Evening 5–9 PM |
| Delivery radius | 2–3 km from Adyar dark store — zone loss = total income loss |
| Device | Android budget phone (~₹10,000) |
| Payments | UPI for all transactions |
| Savings buffer | 2–3 days of income at most |
| Financial obligations | Weekly rent + monthly family remittances |
| Annual disruption exposure | ~80 rain days · loses ₹400–₹600 per heavy rain day |

**Key disruptions Karthik faces:**

| Disruption | Frequency | Impact |
|---|---|---|
| Heavy monsoon rain | ~80 days/year | Zone completely unserviceable for 3–6 hours |
| Cyclone / extreme rain | 2–4 events/year | 3–4 days of income wiped out (Cyclone Michaung scale) |
| Platform app outage | ~2–3 times/month | Zero orders possible regardless of conditions |
| Bandh / curfew | ~8–10 days/year | Roads blocked, platform auto-pauses |
| Internet zone blackout | ~6–10 days/year | Entire operating environment goes dark |
| Accident blockspot | Weekly on GST Road / IT Corridor | 1–3 hour income gap per incident |

---

## ⚡ How Hustlr Works — 15-Second View

```
1. Rain detected in Karthik's zone    →  IMD + OpenWeatherMap confirm threshold
2. Shift window check passes          →  disruption falls within Karthik's working hours
3. Zone depth score calculated        →  confirms Karthik was genuinely deep in zone, not at boundary
4. Fraud check in < 2 seconds         →  FRS score computed across 6 independent signal layers
5. Fixed payout credited Sunday night →  ₹50/hr × verified disruption hours, capped at ₹150/day
```

No forms. No adjusters. No claim ever filed by the worker — for automated trigger events.

---

## ✅ What Hustlr Covers

| Covered | Not Covered |
|---------|-------------|
| Lost income during weather shutdowns (rain, cyclone, extreme heat, AQI) | Vehicle repairs or damage |
| Lost income during platform-declared outages | Medical or accident expenses |
| Lost income during civil disruptions (curfew, bandh, strike) | Personal illness or fatigue |
| Lost income during internet zone blackouts | Low-order days due to competition |
| Lost income due to accident blockspots on hotspot corridors | Income loss outside declared shift window |
| Lost income during severe traffic congestion (Full Shield / Elite Shield) | Events with no corroborating data source |

---

## 🏢 Insurance Partner Model

| Role | Entity |
|---|---|
| **Risk Underwriter** | Licensed insurer — ICICI Lombard / HDFC ERGO |
| **Trigger + Intelligence Engine** | Hustlr |
| **Policy Administration** | Guidewire PolicyCenter API |
| **Claims Automation** | Guidewire ClaimCenter API |
| **Premium Billing** | Guidewire BillingCenter API |
| **Distribution** | Zepto platform integration + B2B2C white-label |

---

## ⚙️ Guidewire Integration

### PolicyCenter
- Weekly policy creation every Monday via PolicyCenter API
- ISS score + city risk profile passed as risk attributes for premium computation
- Policy status synced back to Hustlr in real time

### ClaimCenter
- On parametric trigger: Hustlr pushes a structured, pre-validated claim payload
- Fraud Risk Score attached — ClaimCenter routes CLEAN to auto-approval, FLAGGED to human queue
- On manual claim: worker-submitted proof package routed directly to ClaimCenter review queue
- Zero-touch for weather/bandh/internet events. Structured review for manual claim types.

### BillingCenter
- Weekly premium deduction via BillingCenter direct debit scheduling
- Payout disbursement coordinated through BillingCenter's payment gateway
- Worker wallet reconciliation synced weekly

### Guidewire Marketplace
- Hustlr packaged as a Marketplace integration — any insurer on PolicyCenter/ClaimCenter can onboard Hustlr's parametric trigger engine as a configurable product extension
- This B2B positioning means Guidewire can license Hustlr's engine to any of their insurer clients without Hustlr needing to underwrite risk directly

### B2B2C Distribution Channel
Hustlr is designed to be embedded directly inside the Zepto partner app as a white-label insurance feature. Zepto pays a per-worker monthly licensing fee to offer income protection as a benefit. The insurer underwrites the risk. Guidewire collects a technology licensing fee from the insurer. This three-sided marketplace positions Hustlr as infrastructure — not a direct-to-consumer product — which is exactly the model Guidewire's enterprise clients understand and value.

**Why platforms pay for this:**
- Reduces worker churn during bad weather (workers stay on platform when protected)
- Differentiates Zepto in recruiting delivery partners from competitors
- Fulfills ESG mandate: "we protect our delivery partners"

---

## 📊 Parametric Logic — Core Principle

Hustlr does **not** calculate actual income loss. No investigation needed for automated triggers.

- A measurable disruption index is monitored in real time
- When it crosses a threshold AND falls within the worker's shift window → payout fires
- Payout = fixed rate per trigger type × verified disruption hours (capped at ₹150/day, ₹500/week)

```
Example:
  Trigger:          Heavy rain — IMD confirms 72mm, threshold 64.5mm crossed
  Duration:         3 hours above threshold
  Shift window:     Disruption 11 AM–2 PM within Karthik's 8 AM–10 PM  →  PASS
  Zone depth score: 0.84 — core zone confirmed  →  PASS
  Fixed rate:       ₹50/hr (Heavy Rain, Standard Shield)

  Payout = ₹50 × 3 = ₹150  →  auto-disbursed to UPI Sunday night
```

**Why weekly settlement, not instant:** Claims log throughout the week. Settlement runs every Sunday at 11 PM. This is intentional — the fraud engine evaluates the **complete week's pattern** before any money moves. A worker who triggers 3 events in one week activates the claim velocity signal before any payout releases. Weekly settlement also perfectly matches Zepto's weekly partner payment cycle, eliminating budget friction for workers.

**Why 60–70% income replacement, not 100%:** Parametric insurance by design does not fully replace income — this is basis risk, and it is intentional. A rider earns ~₹75/hr. Paying ₹50/hr (67% replacement) means honest workers are protected without the product becoming a profit opportunity. Full replacement creates moral hazard. The 60–70% band is the industry standard for parametric income protection.

---

## 🚨 Trigger Parameters

### Automated Parametric Triggers

| Trigger | Threshold | Data Source | Hourly Rate |
|---|---|---|---|
| Heavy Rain | ≥ 64.5mm / hr | IMD + OpenWeatherMap | ₹50/hr |
| Extreme Rain / Cyclone | ≥ 115.6mm / hr | IMD + OpenWeatherMap | ₹65/hr |
| Heat Wave | ≥ 43°C | IMD | ₹40/hr |
| Severe Pollution | AQI ≥ 200 | AQICN / WAQI | ₹40/hr |
| Platform App Outage | Order failure rate > 60% | Platform API + order failure rate | ₹50/hr |
| Bandh / Strike / Curfew | NLP confidence ≥ 0.6 + platform OFFLINE | NewsAPI + NLP scraper | ₹50/hr |
| Heavy Traffic Congestion | Speed ≥ 40% below historical baseline, sustained ≥ 45 min + order failure > 35% | Google Maps Traffic API + baseline model | ₹40/hr |
| Internet Zone Blackout | Connectivity < 10% in zone for ≥ 30 min | Ookla / TRAI + device signal reports | ₹50/hr |

**Payout cap:** ₹150/day · ₹500/week

### Manual Claim Triggers

| Trigger | What Worker Submits | Cross-Check Sources | SLA |
|---|---|---|---|
| Traffic Accident Blockspot | GPS screenshot + scene photo (EXIF-stamped) + platform earnings screenshot | Google Maps Traffic API + News API + order density | 4 hrs |
| Local Road Closure | Same as above | Municipal advisory feed + Maps | 4 hrs |
| Dark Store / Hub Shutdown | Photo of closed hub + Zepto screenshot | Platform API + NLP scraper | 4 hrs |

---

## ⚡ Compound Triggers — Elite Shield

Elite Shield workers receive compound trigger payouts when two disruptions occur simultaneously. The compound payout is higher than either individual trigger because income loss during overlapping disruptions is near-total.

| Compound Combination | Logic | Payout % of Daily Cap |
|---|---|---|
| Rain (severe) + Platform Downtime | Both active simultaneously in zone | 100% |
| Rain (any) + Traffic Standstill | Both active in zone simultaneously | 70% |
| Extreme Heat + High AQI | Both above threshold simultaneously | 55% |
| Cyclone Watch + Rain | Advisory active + rainfall >30mm/hr | 85% |
| Dark Store Closed + Rain | Both conditions confirmed | 100% |
| Curfew + Platform Outage | Both active during shift window | 100% |

**Business logic for compound triggers:** When two disruptions overlap, the worker's income loss is multiplicative — not additive. Rain alone reduces deliveries by 70%. Rain plus platform downtime reduces deliveries by 100%. Standard Shield pays for the worse of two events. Elite Shield pays a compound bonus that reflects the true income impact of simultaneous disruptions. This is also the insurance industry's standard approach to correlated risk events.

**Claim-Free Cashback (Elite Shield):**
Workers on Elite Shield who complete 4 consecutive weeks without a payout receive 10% of their premiums from those 4 weeks returned as wallet credit. This solves a critical insurance market problem — adverse selection, where only high-risk workers buy during high-risk weeks. By rewarding workers who stay insured during calm periods, Hustlr builds a healthier premium pool where low-risk premiums cross-subsidize high-risk payouts. The cashback costs the insurer approximately ₹43 per worker per qualifying period — a small price for 4 weeks of premium float.

---

## 🛡️ Anti-Gaming Rules

- **Minimum duration:** 45 continuous minutes above threshold before trigger activates — weather spikes do not qualify
- **Cooling period:** Same disruption type cannot trigger again in same zone within 24 hours
- **Shift intersection:** Disruption must overlap worker's registered shift by minimum 2 hours
- **One event per week per type** for Basic and Standard Shield plans
- **Pro-rata for mid-week activation:** Worker who activates policy on Thursday receives payout weighted by days active that week — eliminates last-minute purchase gaming
- **Post-purchase coverage only:** Disruptions that begin before policy activation are never covered — workers cannot buy insurance after seeing a weather forecast

### Threshold Obfuscation + Dynamic Micro-Variation

**Exact trigger thresholds are never published.** Workers see only ranges ("heavy rain triggers a payout") — never the specific millimetre values. This is deliberate.

Additionally, the actual trigger threshold varies by ±3mm (rain) or ±0.5°C (heat) each week using a seeded random value known only to the system. Workers can never predict the exact number for the current week.

**Why this matters for Chennai specifically:** Research into Chennai delivery worker behavior — through Reddit, delivery partner forums, and social platforms — reveals workers are highly financially sophisticated and actively probe incentive systems. The Rapido/cab driver pattern of gaming platform incentives is directly applicable to insurance threshold gaming. Workers in organized groups can identify precise thresholds through repeated testing and share them via WhatsApp. Threshold micro-variation makes this strategy unreliable — a threshold that triggered a payout last week may not trigger this week at the same rainfall level.

---

## 📱 Manual Claim Filing — UX Flow

Workers filing a manual claim tap **"Report a Disruption"** on the Claims screen. This opens a 3-step guided flow designed for one-thumb operation on a budget Android device.

**Step 1 — Select Disruption Type**
```
Worker sees:
  🚧  Road Blocked / Accident
  🏪  Dark Store / Hub Closed
  🌐  Internet Outage (zone-level)
  📦  Other Delivery Blockage
```

**Step 2 — Capture Evidence (in-app, EXIF-stamped)**
```
Disruption Type          What the app asks for
─────────────────────────────────────────────────────────────────
Road Blocked / Accident  1 photo (app GPS-stamps at capture)
Dark Store / Hub Closed  1 photo + Zepto screenshot (no orders)
Internet Outage          App auto-reads signal strength — no photo
Other                    1 photo + description (max 100 chars)
```

**Step 3 — Submission & Tracking**
```
Worker sees:
  "Claim submitted. We're checking 3 data sources."

Within 4 hours:
  → AUTO-APPROVED: "₹X credited to your wallet"
  → NEED MORE INFO: "Tap here to add one more photo"
  → DECLINED + EXPLANATION: "Here's why, and how to appeal"
```

---

## 🌐 Internet Zone Blackout — Trigger Architecture

India's gig workers are uniquely vulnerable to localized internet outages. A Zepto Q-commerce rider cannot accept orders, navigate, or scan QR codes during a connectivity blackout. One pincode blackout eliminates their entire working zone instantly.

```
Signal 1 — Ookla Real-Time Speed Map API
  Zone average download speed < 2 Mbps for 20 minutes  →  degraded flag

Signal 2 — Device crowd-reporting (passive)
  ≥ 30% of active Hustlr users in a pin-code report < 1 bar signal
  →  cluster anomaly flag

Signal 3 — TRAI outage registry
  Any registered outage for zone's ISP/tower operator  →  authoritative flag

Dual-confirmation rule:
  Signal 1 + Signal 2  →  AUTO_TRIGGER
  Signal 3 alone        →  AUTO_TRIGGER
  Signal 1 alone        →  HOLD for 20-minute reconfirmation window
```

**Fraud resistance:** A fraudster cannot fake a localized internet blackout — faking connectivity loss requires active data transmission to submit the claim, which is self-contradictory. This makes the internet blackout trigger one of Hustlr's most inherently fraud-resistant signals.

---

## 🚧 Accident Blockspot — Trigger Architecture

Chennai's road network has documented high-frequency accident corridors — Rajiv Gandhi Salai, GST Road, and Poonamallee High Road account for a disproportionate share of delivery-hour blockages.

```
Google Maps Traffic API:
  Route speed < 5 km/h on major corridor for ≥ 30 minutes  →  gridlock flag

Cross-checked against:
  NewsAPI / NLP scraper: "accident", "collision", "road blocked"
  in that zone within past 45 minutes  →  corroborated

Worker-assisted confirmation:
  Push: "Accident blocking detected on GST Road near you. Affected?"
  Worker: tap confirm + upload 1 photo

Hustlr cross-checks:
  →  Worker GPS on that corridor in last 30 min?
  →  Zero completed orders in that window?
  →  Is blockspot on Chennai Accident Hotspot Map?
```

**Chennai Accident Hotspot Map:**

| Tier | Corridors | Skepticism Weight |
|---|---|---|
| Tier 1 | GST Road, Rajiv Gandhi Salai, Poonamallee High Road | Low |
| Tier 2 | Anna Salai, Velachery Main Road, OMR | Medium |
| Tier 3 | Internal streets, zone-internal routes | High |

---

## 🚦 Heavy Traffic Congestion — Trigger Architecture

```
Step 1 — Build historical baseline per corridor per 30-min time slot:
  Google Maps Traffic API → rolling 90-day average speed

Step 2 — Detect abnormal deviation:
  Current speed < (baseline − 40%) sustained ≥ 45 minutes  →  severe flag

Step 3 — Platform order failure corroboration:
  Order failure rate in affected zone > 35%  →  confirmed

All three conditions must be met simultaneously → AUTO_TRIGGER
```

**City-specific corridor baselines (Phase 2):**

| City | High-Risk Corridor | Baseline | Trigger Threshold |
|---|---|---|---|
| Chennai | GST Road, Anna Salai | 18–22 km/h | < 11–13 km/h |
| Bengaluru | Electronic City Flyover, ORR | 15–20 km/h | < 9–12 km/h |
| Mumbai | Eastern Express Highway, WEH | 20–25 km/h | < 12–15 km/h |
| Delhi | NH48, Gurugram corridor | 22–28 km/h | < 13–17 km/h |

---

## 📋 Real Scenario Simulations

### Scenario A — Chennai November Rain (Automated)

```
Date:         November 12, 2025 · Location: Adyar, Chennai
IMD data:     72mm rainfall — threshold crossed for 3 hours
Shift window: 11 AM–2 PM within Karthik's 8 AM–10 PM  →  PASS
Zone depth:   Karthik's GPS shows 0.84 — core zone  →  PASS

Payout = ₹50/hr × 3 hrs = ₹150
Timeline:
  11:00 AM  →  IMD threshold crossed
  11:02 AM  →  Zone depth score: 0.84 — PASS
  11:02 AM  →  Fraud engine: FRS = 14/100 — CLEAN
  11:02 AM  →  Claim logged PENDING — Karthik notified
  Sunday    →  70% (₹105) released to wallet
  Tuesday   →  30% (₹45) released after review window
```

### Scenario B — Shadow Policy Activation

```
Karthik has no active policy this week.
Rain disruption hits Adyar zone Thursday.
System silently calculates: if Karthik had Standard Shield,
he would have received ₹150 in payout.

Accumulated over 2 weeks: ₹680 in missed payouts.

Wednesday notification:
  "You missed ₹680 in payouts this fortnight.
   Activate Standard Shield now — ₹72/week."

One tap — policy activated. Coverage starts Monday.
```

### Scenario C — Predictive Activation (Wednesday Nudge)

```
Wednesday evening — Hustlr's 72-hour forecast runs.
OpenWeather shows: 78% probability of IMD Very Heavy Rain
in Adyar zone on Friday 2 PM–6 PM.

Karthik receives push notification:
  "Heavy rain expected Friday in your zone.
   Activate ₹72 Standard Shield now to protect ₹600+ earnings."

Karthik taps → policy activated → Friday rain hits →
claim auto-triggered → ₹150 Sunday night.
The system predicted, nudged, protected, and paid —
all before the worker even thought about insurance.
```

### Scenario D — Platform App Outage (Automated via Order Failure Rate)

```
Zepto status page: "operational"
Hustlr detects: order_failure_rate = 78%  →  threshold 60% crossed

Order failure rate overrides status API — reflects ground reality.
Workers on Standard Shield receive auto-claim for outage duration.
```

### Scenario E — Internet Zone Blackout (Automated)

```
Date: February 8, 2026 — 7:00 PM · Location: Tambaram, Chennai

Signal 1 — Ookla: Tambaram avg speed 0.8 Mbps  →  degraded flag
Signal 2 — 34 of 89 active users report < 1 bar for 25 min  →  cluster flag
TRAI: BSNL tower outage logged for Tambaram 600045  →  authoritative flag

Dual confirmation → AUTO_TRIGGER
Payout = ₹50/hr × 2.5 hrs = ₹125
```

### Scenario F — Accident Blockspot (Assisted Manual)

```
GST Road near Perungudi — 8:30 PM
Google Maps: zone speed < 5 km/h for 45 min  →  gridlock
NewsAPI: "truck accident GST Road Perungudi" — confidence 0.79

Karthik taps confirm + uploads photo.
GPS match + zero orders + Tier 1 corridor confirmed.
Payout: ₹40 × 2 hrs = ₹80 — SLA: 4 hours
```

---

## 🛡️ Adversarial Defense & Anti-Spoofing Strategy

### The Threat

A coordinated syndicate of 500 workers organizes via Telegram. Using GPS spoofing apps, they fake their location inside a rain-alert zone while sitting at home, triggering mass false payouts.

### Why GPS Spoofing Fails Against Hustlr

Hustlr never trusts a single signal. Every payout requires **multi-stream coherence** across independent data channels that a spoofing app cannot simultaneously fake.

| Signal Layer | What It Measures | What Spoofing Looks Like |
|---|---|---|
| GPS coordinates | Claimed location | Too perfect — zero statistical jitter over 5-minute windows |
| Cell tower triangulation (OpenCelliD) | Tower the device is connected to | Home tower ID doesn't match flood zone |
| Wi-Fi fingerprint | SSIDs visible to device | Known home SSID present = flagged |
| IP geolocation (MaxMind) | ISP + approximate location | Home broadband IP ≠ claimed outdoor zone |
| Accelerometer / motion | Physical movement patterns | Stationary couch ≠ stranded outdoor worker |
| Battery charging state | Charging = plugged in at home | Charging during claimed outdoor disruption |
| Barometer / altitude | Device elevation | Ground-level flood claim from 12th floor |

### The Data — What Hustlr Analyzes

**Layer 1 — Individual Signal Checks:**

```python
SIGNAL_WEIGHTS = {
    'gps_zone_mismatch':                 25,
    'wifi_home_ssid_detected':           20,
    'battery_charging':                  15,
    'accelerometer_idle':                10,
    'platform_app_inactive':             15,
    'ip_geolocation_home_match':         20,
    'claim_latency_under_30s':           10,
    'gps_jitter_too_perfect':            15,
    'barometer_altitude_mismatch':       10,
    'device_hardware_fingerprint_match': 15,
    'app_install_timestamp_cluster':     10,
}
```

**Layer 2 — Behavioral Baseline:**
First 2 weeks build a Personal Activity Graph: home zone, normal work zones, typical hours, average motion. Claims from zones the worker has never worked in receive a behavioral penalty.

**Layer 3 — News Corroboration Score (0.25 weight in FPS):**
Before any payout, Hustlr independently queries Brave Search and NewsAPI for verified public crisis reports specific to the claimed zone and time. Absence of public corroboration is a scored fraud signal — not just a check. A syndicate cannot fabricate official IMD alerts or government advisories.

**Layer 4 — Behavioral Fingerprinting:**

| Signal | What It Detects |
|---|---|
| Claim-initiation latency | Claims filed < 30s after trigger = syndicate reflex |
| Orders completed during disruption | Worker completed a delivery during claimed window → auto-reject |
| Longitudinal claim frequency | Claiming every disruption with zero post-disruption activity across weeks |
| Onboarding recency | < 2 weeks tenure + max-value Week 1 claim → elevated scrutiny |

**Layer 5 — Coordinated Ring Detection:**

| Signal | Threshold | Indication |
|---|---|---|
| Claim Surge Velocity | 50+ claims from one zone in 10 minutes | Coordinated trigger |
| Geographic Clustering | Claims in implausibly tight boundary | Ring from one Telegram group |
| Device Fingerprint Similarity | Shared hardware ID / install timestamp | Same APK distributed in ring |

**Poisson Distribution Test:** Genuine disruptions spread claim filings over 20–40 minutes. Coordinated rings fire within seconds. Uniform filing at p < 0.05 = coordinated ring confirmed.

**Layer 6 — Internet Blackout Self-Validation:**
Active device-to-server communication during a claimed blackout invalidates the claim. The trigger fires server-side from Ookla + TRAI — not from device reporting.

### The Decision Engine — Weighted Ensemble FPS

```python
FPS = weighted_ensemble(
    location_authenticity_score   × 0.25,
    delivery_zone_match_score     × 0.20,
    news_corroboration_score      × 0.25,
    behavioral_fingerprint_score  × 0.15,
    zone_anomaly_score            × 0.15
)
```

| Tier | FPS Range | Action |
|---|---|---|
| GREEN | 0.0 – 0.30 | Auto-approve — payout within 2 minutes |
| YELLOW | 0.31 – 0.60 | Soft hold — "verifying, reply within 2 hours" |
| RED | 0.61 – 1.00 | Human review — provisional ₹100–300 credit released immediately |

### Zone Context Override During Declared Emergencies

When IMD or NDMA issues an official disaster advisory, all FPS thresholds in that zone are elevated by 15 points for the advisory duration. Genuine stranded workers in cyclone zones are not subjected to fraud scrutiny during the worst events.

### Protecting Honest Workers — Five Principles

**Principle 1:** Soft holds, not hard rejections. RED always receives provisional credit immediately.

**Principle 2:** Zone context override during officially declared emergencies.

**Principle 3:** Worker Trust Score (backend only) — 8+ weeks clean history reduces effective FPS by up to 15 points.

**Principle 4:** Transparent auto-explanation on every rejection naming which signals triggered the flag, plus one-tap appeal within 4 hours.

**Principle 5:** No permanent action without confirmed multi-signal fraud across multiple events.

---

## 📍 Zone Depth Scoring — Anti-Boundary Gaming

**The problem with binary zone membership:** If zone membership is a hard boundary (inside = eligible, outside = not), workers can game it by standing 50 metres inside the boundary during a disruption and claiming full payout. A financially sophisticated worker — exactly the Chennai delivery partner profile — will learn where the boundary is and exploit it.

**Hustlr's solution — Continuous Zone Depth Score:**

Instead of asking "is the worker inside Zone A?", Hustlr asks "how deeply inside Zone A was the worker, and for how long?"

```
Zone divided into 3 concentric rings around dark store:

  Outer ring    (0–500m inside boundary)    depth score: 0.00–0.20
  Middle ring   (500m–2km from boundary)    depth score: 0.21–0.60
  Core zone     (2km+ from any boundary)    depth score: 0.61–1.00

Worker's depth score = mean of all GPS pings during shift

Payout multiplier:
  Score 0.00–0.20  →  0.0   (no payout — boundary gaming detected)
  Score 0.21–0.40  →  0.30  (30% of calculated payout)
  Score 0.41–0.60  →  0.60  (60%)
  Score 0.61–0.80  →  0.85  (85%)
  Score 0.81–1.00  →  1.00  (full payout)

Additional rule: worker must have at least one GPS ping
in the core zone during the 4 hours before disruption trigger fired.
```

**Why this eliminates boundary gaming entirely:**
A worker who runs to the zone edge the moment rain starts has a depth score near zero — payout multiplier of 0.0. A worker who spent their entire shift delivering deep inside the zone has a depth score of 0.84 — full payout. There is no single coordinate to stand on. The entire week's GPS history determines the score. A fraudster would have to have genuinely worked deep in the zone for weeks to accumulate a score that pays out at full rate — at which point they are not a fraudster, they are a genuine worker.

**For Chennai specifically:** Zone depth scoring directly neutralizes the most likely local fraud pattern — a worker hearing about a rain trigger, driving quickly to the zone boundary, taking a GPS screenshot, and leaving. The depth model evaluates continuous presence throughout the shift, not a single location snapshot.

---

## 🤖 AI/ML Architecture

### Model 1 — Income Stability Score (ISS)

**Purpose:** Risk score 0–100 per worker, used to recommend the most appropriate weekly plan and calibrate premium pricing.

**Phase 1 — Rule Engine:**

```python
def calculate_iss(zone_flood_risk, avg_daily_income,
                  disruption_freq_12mo, claims_history_penalty):
    score = 100
    score -= zone_flood_risk * 20
    score -= min(disruption_freq_12mo, 15)
    score += min(avg_daily_income / 200, 10)
    score -= claims_history_penalty
    return max(0, min(100, score))
```

**Phase 2:** XGBoost upgrade when real worker data available.

**Real datasets used:**
- IMD District Rainfall 2015–2024 — imdpune.gov.in
- PLFS Gig Worker Earnings Survey 2023 — mospi.gov.in
- data.gov.in Pincode-Zone Directory

### Model 2 — ISS-Based Onboarding Tier Recommendation

```
ISS 0–29   →  Recommend Elite Shield (₹109/wk)
ISS 30–49  →  Recommend Full Shield (₹79/wk)
ISS 50–69  →  Recommend Standard Shield (₹49/wk)
ISS 70–100 →  Recommend Basic Shield (₹29/wk)

Add-on recommendations:
  Zone bandh frequency > 4/year   →  Curfew & Strike add-on
  Platform outage rate > 2/month  →  App Downtime add-on
  Coastal cyclone belt zone        →  Cyclone add-on
```

### Model 3 — Fraud Detection Engine (FRS)

Six-layer stacked scoring using the weighted ensemble FPS architecture. Runs in < 2 seconds. Isolation Forest feature vector:

```python
def build_claim_vector(claim_event):
    return [
        claim_event.zone_grid_id,
        claim_event.unix_timestamp % 86400,
        get_simultaneous_claims_in_zone(claim_event.zone_grid_id,
                                        claim_event.timestamp,
                                        window_minutes=15),
        claim_event.device_subnet_hash,
        claim_event.device_hardware_id_hash,
        claim_event.app_install_timestamp,
        claim_event.os_version_hash,
        days_since_onboarding(claim_event.worker_id),
        referral_chain_depth(claim_event.worker_id)
    ]
```

### Model 4 — NLP Disruption Scraper

**Phase 1:** spaCy keyword scoring. Dual confirmation required.

**Phase 2:** LLM preprocessing for unstructured government advisories.

```
INPUT:  "IMD issues red alert for Chennai district. Extremely heavy
         rainfall expected between 6 PM and midnight tonight."

OUTPUT: { "trigger": "extreme_rain", "zone": "Chennai",
          "confidence": 0.95, "window_start": "18:00",
          "window_end": "24:00", "date": "2026-03-20" }
```

### Model 5 — Internet Connectivity Anomaly Detector

```python
BLACKOUT_THRESHOLD = {
    'ookla_avg_speed_mbps':       2.0,
    'device_cluster_pct_weak':    0.30,
    'sustained_minutes':          20,
    'trai_registry_match':        True
}
```

### Model 6 — Accident Blockspot Classifier

```python
def classify_blockspot(zone, traffic_signal, news_signal, time_of_day):
    congestion_prob = congestion_baseline_model.predict(zone, time_of_day)
    if congestion_prob > 0.80:
        return "NORMAL_CONGESTION"
    if news_signal['confidence'] >= 0.65 and traffic_signal['duration_min'] >= 30:
        return "ACCIDENT_BLOCKSPOT"
    return "INCONCLUSIVE"
```

Sourced from NCRB Road Accident Statistics 2023 and Chennai Traffic Police data.

### Model 7 — Facebook Prophet Forecasting (Phase 3)

Forecasts 4-week disruption frequency per zone. Feeds insurer admin dashboard with capital reservation estimates. Trained on IMD District Rainfall 2015–2024 + Chennai bandh history from NLP archive.

---

## 🌏 Regional Behavioral Intelligence Layer

### The Chennai Insight

Research into Chennai delivery worker behavior — through Reddit (r/Chennai, r/india), delivery partner forums, Twitter/X, and YouTube delivery partner vlogs — reveals a consistent pattern: Chennai gig workers are financially sophisticated and actively probe platform incentive systems. The Rapido/cab driver behavior of negotiating fares outside the app, understanding surge mechanics, and finding system edges is directly applicable to parametric insurance.

This is not a criticism of workers — it is an actuarial observation. A worker who understands that crossing a threshold triggers a payment will, rationally, attempt to position themselves to qualify. This is human behavior, and insurance systems that ignore it get exploited.

**What the research identified:**

1. Workers share threshold information in WhatsApp groups within hours of discovery
2. Delivery partner communities in Chennai are highly organized (zone-specific, platform-specific groups)
3. Financial incentive awareness is high — workers track per-order rates, surge timing, and bonus structures precisely
4. Collective action is common — Chennai workers have organized successful platform negotiations previously

### Regional Behavior Risk Index

Each city receives a behavioral risk index based on organized gig worker community density, historical platform exploitation incidents, and financial literacy proxy measures:

| City | Behavioral Risk Index | Key Characteristic |
|---|---|---|
| Chennai | 0.65 | High financial literacy, organized communities, incentive-aware |
| Bengaluru | 0.55 | Tech-adjacent workforce, individual optimization focus |
| Mumbai | 0.50 | Volume-focused, less community coordination |
| Delhi | 0.45 | Diverse worker base, lower coordination density |
| Tier 2 cities | 0.30 | Lower financial literacy, less organized |

**How this index is used:**

- Adjusts fraud signal weights regionally — Chennai workers receive slightly higher scrutiny on threshold-adjacent claims
- Informs the threshold micro-variation range — higher behavioral risk index = wider variation band
- Calibrates the zone depth scoring multiplier curve — cities with higher gaming risk use steeper depth penalties for outer ring claims
- NOT used to deny individual claims — it is a portfolio-level actuarial input, not a per-worker judgment

**Ongoing data collection:** Hustlr's regional intelligence layer runs a weekly NLP scan of public delivery partner communities to detect emerging exploitation patterns. When a new gaming behavior is identified — for example, a forum post describing how to qualify for a trigger — the fraud model updates its regional weights within 24 hours. The system gets harder to game over time, not easier.

**The ethical boundary:** Regional behavioral intelligence adjusts system-level thresholds and fraud weights. It never denies an individual worker's claim based on their city alone. Individual fraud signals must still be present for a claim to be flagged.

---

## 🚀 Innovation Differentiators

### 1. Shadow Policy — Uninsured Worker Conversion

Workers who have not purchased insurance are tracked in a **shadow policy mode**. The system silently calculates what their payout would have been for every disruption event in their zone while they were uninsured.

After 2 weeks, the app displays:
> *"You would have received ₹680 in payouts this fortnight if you were insured. Here is the breakdown: Rain disruption Oct 12 → ₹450. Platform downtime Oct 08 → ₹230."*

A "Activate Standard Shield" button sits directly below this message.

**Why this is powerful:** Traditional insurance marketing tells people what might happen. Shadow policy shows people what already happened — to them, in their zone, during their shifts. It converts abstract risk into concrete missed money. Conversion rates for this mechanic in fintech (showing users their missed earnings/savings) consistently outperform standard marketing by 3–5x.

**Business value for insurer:** Acquisition cost for a worker who converts via shadow policy = ₹0. No agent commission. No advertisement. The worker's own missed payouts are the entire sales pitch.

### 2. Predictive Insurance Activation

Every Wednesday evening, Hustlr runs a 72-hour disruption forecast for every active zone:

1. Polls OpenWeather hourly forecast for rainfall probability
2. Calculates peak disruption probability window per zone
3. If probability exceeds 60%: sends targeted push notification

**Notification:**
> *"Heavy rain expected Friday 2–6 PM in your Adyar zone. Activate Standard Shield now to protect up to ₹600 of Friday earnings. ₹72/week."*

Workers activate before the disruption — not after it. This is proactive insurance.

**Why this matters for the insurer:** Adverse selection is the core problem in insurance — only sick people buy health insurance, only risky drivers buy comprehensive motor cover. Predictive activation partially solves adverse selection by expanding purchase to workers who might not have bought without the nudge. More importantly, it captures premiums during high-risk weeks — exactly when the insurer needs premium volume to offset expected payouts.

**The counterintuitive math:** An insurer might think nudging workers to buy before a known rain event is bad business — they will definitely claim. But the alternative is these workers buy nothing, earn nothing from the insurer, and the market goes unserved. A 65% loss ratio on a ₹72 premium is ₹25 profit per worker per week. Multiplied by 10,000 workers, that is ₹2.5 lakhs profit per week even on predictive-activated policies.

### 3. Zone Depth Scoring

Replaces binary zone membership with continuous presence scoring. Described in full detail in Section 19. No other team will implement this.

### 4. Regional Behavioral Intelligence

Chennai-specific fraud calibration based on gig worker community research. Described in full detail in Section 21.

### 5. Internet Blackout as First-Class Trigger

Most teams will model only weather. Hustlr treats internet zone blackouts as a named, parameterized disruption type with dual-source confirmation (Ookla + TRAI). For Q-commerce workers — who cannot operate without connectivity — this is as income-destroying as rain. No parametric insurance product in India currently covers this.

### 6. Accident Blockspot with Hotspot Map

A city-specific accident corridor database (Tier 1/2/3) that calibrates claim skepticism per road. Workers on Tier 1 corridors receive faster processing and lower skepticism weight. Workers claiming blockspots on roads that are not on Hustlr's hotspot map face higher scrutiny. This is real actuarial geography applied to parametric triggers.

### 7. Insurer Profitability Simulator

The admin dashboard includes a stress test tool:

> *"If a Cyclone Michaung-level event hits Chennai today, what is total payout exposure across all active policies?"*

Run the simulation — the system calculates expected total liability, remaining pool liquidity, reserve fund adequacy, and whether the reinsurance trigger would activate.

This is exactly the kind of enterprise risk management tool that Guidewire builds for large insurers. Packaging it inside Hustlr demonstrates that the team understands the insurer's operational needs, not just the worker's experience.

---

## 💰 Weekly Premium Tiers

| Plan | Weekly Premium | Covers | Expected Weekly Payout | Target Loss Ratio | Best For |
|---|---|---|---|---|---|
| **Basic Shield** | ₹29/wk | Rain + extreme heat | ~₹19 | 0.65 | Low-risk zones, new workers |
| **Standard Shield** ⭐ | ₹49/wk | Rain, heat, pollution, app downtime | ~₹32 | 0.65 | Most city delivery workers |
| **Full Shield** | ₹79/wk | All types incl. bandh + internet blackout | ~₹53 | 0.67 | Flood-zone workers |
| **Elite Shield** 🔥 | ₹109/wk | All types + compound triggers + 10% cashback | ~₹60 | 0.55 | High-traffic zone workers |

### Income Add-Ons

| Add-On | Weekly Cost | Covers |
|---|---|---|
| Curfew & Strike | +₹15/wk | Bandh, curfew, Section 144 |
| Election Day | +₹20/wk | Polling day restricted movement |
| App Downtime | +₹12/wk | Platform outage via order failure rate |
| Cyclone | +₹25/wk | Extreme rain + cyclone alerts |
| Internet Blackout *(Phase 2)* | +₹18/wk | Zone-level connectivity outage |
| Accident Blockspot *(Phase 2)* | +₹15/wk | Road blocked on hotspot corridors |
| Heavy Traffic Congestion *(Phase 2)* | +₹15/wk | Speed ≥ 40% below baseline for ≥ 45 min |

---

## 🏙️ City Risk Profiles

Each city gets a composite risk score from 8 local data points:

| Data Point | Source |
|---|---|
| 10-year IMD rainfall history | imdpune.gov.in |
| NDMA flood zone maps | ndma.gov.in |
| Bandh/strike frequency (NLP archive) | Hustlr NLP scraper |
| Platform order density | Platform API |
| Average disruption hours per event | IMD + historical |
| Internet outage frequency | TRAI + Ookla |
| Accident blockspot density | NCRB + Traffic Police |
| Peak traffic congestion frequency | Google Maps historical |

- **Chennai:** High flood + moderate bandh + high accident density (GST Road / IT Corridor) + high behavioral gaming risk
- **Kolkata:** Highest bandh score in India + moderate flood
- **Bengaluru:** Low bandh + high internet outage + high accident density (Electronic City flyover)
- **Mumbai:** Extreme monsoon + low bandh + high accident density (Eastern/Western Expressways)

---

## 🔄 End-to-End Workflow (Full)

```
Worker opens Hustlr
        ↓
OTP login (single device lock)
        ↓
Onboarding: platform + zone + avg income
        ↓
ISS calculated + city risk profile applied
        ↓
Weekly policy created via PolicyCenter
        ↓
Weekly premium deducted via BillingCenter
        ↓
Monitoring loops every 15 minutes:
  Weather API | Platform order failure rate
  NLP scraper | Ookla + TRAI internet signals
  Traffic API + news corroboration
        ↓
Threshold + shift window check
        ↓
Zone depth score calculated
        ↓
FPS computed across 6 layers < 2 seconds
        ↓
GREEN → 70% immediate / 30% after 48hr review
YELLOW → provisional credit + soft verification
RED → manual review + provisional ₹100-300 credit
        ↓
Sunday 11 PM — weekly settlement batch
        ↓
Full payout credited Monday 12 AM
        ↓
Shadow policy tracks uninsured workers
        ↓
Wednesday forecast → predictive nudge sent
        ↓
Next week cycle
```

---

## 📊 System Reliability — Fallback Hierarchy

| Signal Lost | Fallback |
|---|---|
| OpenWeatherMap unavailable | IMD station feed |
| IMD data delayed | Last confirmed reading + 30-min cache |
| Platform API unreachable | Order failure rate as primary signal |
| GPS signal lost | Last verified location within 15-min window |
| NLP scraper fails | Trigger held; manual admin review |
| Single-source trigger only | Held for admin confirmation |
| MaxMind IP API unavailable | Wi-Fi fingerprint weighted up |
| Ookla API unavailable | TRAI registry primary; device cluster secondary |
| Google Maps Traffic unavailable | Heavy Traffic trigger suspended |

---

## 🏗️ Platform Decision — Mobile App (Flutter)

Delivery workers do not use laptops. Every interaction happens on a ₹10,000 Android phone at a red light. Designed for one-thumb operation and 3-second tasks.

The anti-spoofing engine requires direct native access to: cell tower IDs, Wi-Fi SSID fingerprints, GPS jitter readings, accelerometer, battery state, barometric pressure, and signal strength. PWAs cannot reliably access all of these on Android. Flutter provides full native sensor access plus a single codebase for both Android (worker app) and web (insurer admin dashboard).

Background GPS tracking via `flutter_background_geolocation` runs continuously during shifts — even when the phone screen is off — providing the continuous location data that zone depth scoring requires.

---

## 🛠️ Tech Stack

**Frontend**

| Component | Technology |
|---|---|
| Framework | Flutter (Dart) |
| State Management | Riverpod |
| Background Location | flutter_background_geolocation |
| Local Storage | Hive (offline-first) |
| Payments (mock) | Razorpay Flutter SDK — test mode |
| Notifications | Firebase Cloud Messaging + Twilio SMS fallback |

**Backend**

| Component | Technology |
|---|---|
| API Server | Node.js + Express |
| Database | Supabase (PostgreSQL + PostGIS) |
| Auth | Supabase Auth (OTP via phone) |
| Hosting | Render (free tier) |
| Trigger Polling | Node-cron (every 15 min) |
| NLP Scraper | Python + spaCy via FastAPI microservice |

**AI/ML**

| Component | Technology |
|---|---|
| ISS Scoring (Phase 1) | Python rule engine via FastAPI |
| Fraud Detection | scikit-learn Isolation Forest + weighted ensemble FPS |
| Zone Depth Scoring | PostGIS geospatial distance calculation |
| Regional Intelligence | Python NLP pipeline (weekly scan) |
| Internet Anomaly | Statistical threshold engine |
| Accident Classifier | Congestion baseline + NLP corroboration |
| Disruption Forecasting | Facebook Prophet — Phase 3 |

**Guidewire**

| Integration | API |
|---|---|
| Policy lifecycle | PolicyCenter REST API |
| Claim creation + routing | ClaimCenter REST API |
| Premium billing + payout | BillingCenter REST API |
| Distribution packaging | Guidewire Marketplace |

**External APIs**

| API | Use | Cost |
|---|---|---|
| OpenWeatherMap | Rainfall real-time | Free |
| IMD Open Data | Authoritative thresholds + fallback | Free |
| AQICN / WAQI | AQI monitoring | Free |
| MaxMind GeoIP2 | IP geolocation + VPN detection | Free tier |
| OpenCelliD | Cell tower triangulation | Free tier |
| Ookla Speed Map API | Internet zone health | Free tier |
| TRAI Outage Registry | Authoritative ISP outage data | Free (gov) |
| Google Maps Traffic | Road speed monitoring | Pay-per-use |
| Brave Search + NewsAPI | Crisis event corroboration | Free tier |
| Zepto | Order failure rate + status | Mock Phase 1 |
| Razorpay | UPI payout simulation | Test mode |

---

## 🧪 MVP Scope — Phase 1

Phase 1 demonstrates the complete parametric loop:

- Rain trigger via live OpenWeatherMap + IMD with shift window check
- Zone depth scoring (3-ring model with payout multiplier)
- Fixed hourly payout (₹40–₹65/hr) with ₹150/day + ₹500/week caps
- NLP scraper for bandh detection (mock news feed)
- ISS scoring (rule engine) with named real datasets
- ISS-based onboarding tier recommendation
- Shadow policy tracking for uninsured workers
- Predictive 72-hour forecast nudge system
- Internet blackout trigger architecture
- Accident blockspot trigger with tap-to-confirm flow
- 6-layer weighted ensemble FPS fraud engine
- Regional behavioral intelligence layer (Chennai calibration)
- Threshold obfuscation + dynamic micro-variation
- Compound trigger logic for Elite Shield
- Claim-free cashback mechanic design
- News corroboration as scored fraud layer (0.25 FPS weight)
- Zone context override during declared emergencies
- Auto-explanation with named signals for every rejection
- Manual claim submission flow
- Guidewire ClaimCenter payload structure
- Insurer profitability simulator design
- UPI payout via Razorpay test mode

---

## 💸 Cost Efficiency

| Resource | Cost |
|---|---|
| OpenWeatherMap, IMD, AQICN | ₹0 |
| MaxMind GeoIP2 | ₹0 (free tier) |
| OpenCelliD | ₹0 (free tier) |
| Ookla Speed Map API | ₹0 (free tier) |
| TRAI Outage Registry | ₹0 (government open data) |
| Brave Search + NewsAPI | ₹0 (free tiers) |
| Supabase + Render | ₹0 (free tiers) |
| Razorpay test mode | ₹0 |

**Total infrastructure: ₹0/month.**

---

## 📅 6-Week Plan

### ✅ Phase 1 (Weeks 1–2) — Current
- [x] Shift window eligibility architecture
- [x] Fixed hourly payout model with daily + weekly caps
- [x] ISS scoring (rule engine) with named real datasets
- [x] ISS-based onboarding tier recommendation
- [x] Zone depth scoring (3-ring model + payout multiplier)
- [x] Shadow policy tracking for uninsured workers
- [x] Predictive 72-hour forecast nudge system
- [x] Regional behavioral intelligence layer (Chennai)
- [x] Threshold obfuscation + dynamic micro-variation
- [x] Compound triggers for Elite Shield
- [x] Claim-free cashback mechanic
- [x] Weighted ensemble FPS architecture (6 evidence categories)
- [x] GPS jitter analysis signal
- [x] Barometer / altitude mismatch signal
- [x] Device hardware fingerprint + install timestamp clustering
- [x] Orders-during-disruption auto-reject rule
- [x] Longitudinal claim frequency monitoring
- [x] News corroboration as scored fraud layer (0.25 weight)
- [x] Zone context override during declared emergencies
- [x] Poisson distribution ring detection
- [x] NLP scraper + LLM preprocessing architecture
- [x] Internet blackout trigger architecture
- [x] Accident blockspot trigger + Chennai hotspot map
- [x] Heavy traffic congestion trigger with baseline model
- [x] Transparent auto-explanation + one-tap appeal
- [x] Manual claim submission flow
- [x] Guidewire integration mapped (all three APIs)
- [x] B2B2C white-label distribution design
- [x] Insurer profitability simulator design
- [x] Flutter scaffold + Supabase schema
- [x] Phase 1 demo video

### Phase 2 (Weeks 3–4) — Automation & Protection
- [ ] Full Flutter app — all screens + manual claim flow
- [ ] Weather + NLP trigger cron live
- [ ] Order failure rate trigger live
- [ ] Internet blackout trigger live (Ookla + TRAI)
- [ ] Zone depth scoring live (PostGIS)
- [ ] Shadow policy calculation live
- [ ] Predictive nudge notification live
- [ ] Regional intelligence weekly scan live
- [ ] MaxMind + OpenCelliD + GPS jitter + barometer integration
- [ ] Hardware fingerprint + install timestamp clustering live
- [ ] Auto-explanation generation for all rejections
- [ ] Live ClaimCenter/PolicyCenter integration
- [ ] City risk profiles: Chennai + Mumbai + Bengaluru + Kolkata

### Phase 3 (Weeks 5–6) — Scale & Optimise
- [ ] Isolation Forest fraud model + Poisson timing test
- [ ] LLM news preprocessing pipeline
- [ ] Facebook Prophet forecasting model
- [ ] Insurer admin dashboard + profitability simulator
- [ ] Pool reserve monitor + reinsurance trigger
- [ ] Worker Trust Score accumulation logic
- [ ] Claim-free cashback automation
- [ ] Guidewire Marketplace packaging
- [ ] Final 5-min demo video + pitch deck

---

## 📊 Business Viability & Financial Model

### Premium Structure

| Parameter | Value | Rationale |
|---|---|---|
| Premium frequency | Weekly deduction | Matches gig worker pay cycle |
| Price stability | Fixed for 6-month season | Workers can budget reliably |
| Repricing cycle | Every 6 months | Adjusts for seasonal risk shifts |
| Payout type | Fixed amounts per trigger type | Parametric simplicity |

### Pool Protection Architecture

| Control | Parameter | Purpose |
|---|---|---|
| Weekly payout cap | 80% of available pool | 20% always liquid |
| Daily worker cap | ₹150/day | Per-worker exposure limit |
| Weekly worker cap | ₹500/week | Cyclone week protection |
| Reserve fund | 25% of all premiums | Claims overflow buffer |
| Geographic concentration | Hard 25% cap per city | Correlated loss prevention |
| Reinsurance trigger | Losses exceeding 4× weekly pool | Catastrophic transfer |

### Projected Financials — Chennai Pilot (10,000 Workers)

| Metric | Value |
|---|---|
| Target workers | 10,000 |
| Average weekly premium (blended) | ₹49 |
| Weekly premium pool | ₹4,90,000 |
| Weekly payout cap (80%) | ₹3,92,000 |
| Reserve fund accumulated/week | ₹1,22,500 |
| Loss ratio target | < 0.70 |
| Estimated real loss ratio | ~55–65% |
| Reinsurance trigger | ₹19,60,000 (4× pool) |
| Automated claims cost | ₹0 |
| Manual claims cost | ~₹200 (4-hr human review) |
| Shadow policy conversion cost | ₹0 (self-converting) |

---

## 🤝 IRDAI Compliance

- Technology partner model — not a licensed insurer
- Policy under partner insurer's IRDAI license
- Triggers rely on IMD — IRDAI-recognized data source
- Payout terms transparent at activation (parametric requirement)
- Microinsurance compliant: ₹29–₹109/week, simplified format
- Within IRDAI Regulatory Sandbox guidelines for parametric products (2019)

---

## 👥 Team

| Member | Role |
|---|---|
| Inesh Agarwal | Flutter Development |
| V Dhruv | Backend / API + Guidewire Integration |
| Prisha Agarwal | AI/ML + Fraud Engine + NLP + Prophet |
| Daksh Gupta | UI/UX Design |
| T Anil Kumar | Insurance Domain + City Risk Profiles + Pitch |

---

## 🎬 Phase 1 Deliverables

<div align="center">
  <a href="https://youtu.be/nD2snI4Tnu8?si=eS5sztT0aibvxodI">
    <img src="https://img.shields.io/badge/▶_2--Minute_Demo_Video-282828?style=flat-square&logo=youtube&logoColor=white" alt="Video"/>
  </a>
</div>

---

*Hustlr — Real-time income protection for the workers who keep our cities fed.*
