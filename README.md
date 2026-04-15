<div align="center">
  <h1>⚡ Hustlr</h1>
  <h3>Real-Time Income Protection Engine for India's Gig Delivery Workers</h3>

  <a href="https://youtu.be/nD2snI4Tnu8?si=eS5sztT0aibvxodI">
    <img src="https://img.shields.io/badge/Phase_1_Demo_Video-FF0000?style=for-the-badge&logo=youtube&logoColor=white" alt="Phase 1 Video"/>
  </a>
  &nbsp;
  <a href="YOUR_PHASE2_VIDEO_LINK_HERE">
    <img src="https://img.shields.io/badge/Phase_2_Demo_Video-FF0000?style=for-the-badge&logo=youtube&logoColor=white" alt="Phase 2 Video"/>
  </a>
  &nbsp;
  <a href="YOUR_PHASE3_VIDEO_LINK_HERE">
    <img src="https://img.shields.io/badge/Phase_3_Demo_Video-FF0000?style=for-the-badge&logo=youtube&logoColor=white" alt="Phase 3 Video"/>
  </a>
  &nbsp;
  <a href="https://github.com/Dhruvv-16/Hustlr">
    <img src="https://img.shields.io/badge/GitHub_Repository-181717?style=for-the-badge&logo=github&logoColor=white" alt="GitHub Repo"/>
  </a>
  <br><br>
  <strong>🏆 Guidewire DEVTrails 2026 — Phase 3 Submission</strong><br>
  <strong>👥 Team:</strong> Code Crafters &nbsp;|&nbsp; <strong>🎯 Persona:</strong> Q-Commerce Delivery Partners (Zepto)
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
26. [Parametric Trigger Decision Flow](#-parametric-trigger-decision-flow)
27. [Fraud Detection Decision Flow](#-fraud-detection-decision-flow)
28. [System Reliability — Fallback Hierarchy](#-system-reliability--fallback-hierarchy)
29. [Platform Decision — Mobile App (Flutter)](#️-platform-decision--mobile-app-flutter)
30. [Tech Stack](#️-tech-stack)
31. [Phase 2: Backend Micro-Services Architecture](#-phase-2-backend-micro-services-architecture)
32. [Phase 2: Database Architecture — Supabase Triggers](#-phase-2-database-architecture--supabase-triggers)
33. [Phase 2: Registration & Onboarding Flow](#-phase-2-registration--onboarding-flow)
34. [Phase 2: Insurance Policy Management](#-phase-2-insurance-policy-management)
35. [Phase 2: Dynamic Premium Calculation](#-phase-2-dynamic-premium-calculation)
36. [Phase 2: Claims Management](#-phase-2-claims-management)
37. [Phase 2: Payout Dispatch](#-phase-2-payout-dispatch)
38. [Phase 2: Economic Circuit Breaker](#-phase-2-economic-circuit-breaker)
39. [MVP Scope — Phase 1 ✅, Phase 2 ✅ & Phase 3 ✅](#-mvp-scope--phase-1--phase-2--phase-3-)
40. [Cost Efficiency](#-cost-efficiency)
41. [6-Week Plan](#-6-week-plan)
42. [Business Viability & Financial Model](#-business-viability--financial-model)
43. [IRDAI Compliance](#-irdai-compliance)
44. [Team](#-team)
45. [Phase 2 Deliverables](#-phase-2-deliverables)

---

## 🧭 TL;DR

**Who:** Q-commerce delivery riders (Zepto) — 2–3 km radius, one dark store, zero income safety net.

**Problem:** One flooded street eliminates their entire working zone. No insurance product covers this. 80+ disruption days a year go uncompensated.

**What Hustlr does:** Monitors 9 real-time disruption triggers. When one fires and the rider is on shift — a fixed payout hits their UPI automatically. No claim filed. No adjuster. Under 2 minutes.

**How it's built:** Flutter app · Node.js + Supabase backend · 7 AI/ML models · 7-layer fraud engine · Zone depth scoring · Regional behavioral intelligence · Full Guidewire integration (PolicyCenter + ClaimCenter + BillingCenter) · BLoC state management · Modular micro-services backend.

**Numbers:** ₹29–₹109/week · ₹150/day payout cap · 55–65% projected loss ratio · ₹0 infrastructure cost · 10,000-worker Chennai pilot · 5 live automated triggers · 70/30 tranche payout · 4-tier Data Trust Engine · BCR Circuit Breaker.

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

<p align="center">
  <img src="https://github.com/user-attachments/assets/289c1d4b-ce38-4355-81ce-223381723260" width="900" alt="Hustlr — How It Works"/>
</p>

```
1. Rain detected in Karthik's zone    →  IMD + OpenWeatherMap confirm threshold
2. Data Trust Engine validates         →  Combined source trust 0.85 — exceeds 0.75 threshold
3. Shift window check passes           →  disruption falls within Karthik's working hours
4. Zone depth score calculated         →  confirms Karthik was genuinely deep in zone, not at boundary
5. Device integrity verified           →  Play Integrity API confirms no GPS spoofing app active
6. Fraud check in < 2 seconds          →  FRS score computed across 7 independent signal layers
7. Circuit Breaker confirms pool OK    →  BCR at 44% — well below 85% ceiling
8. 70% tranche credited same day       →  ₹105 to UPI instantly for urgent expenses
9. 30% safety tranche Sunday night     →  ₹45 after full-week fraud pattern review
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
| **Distribution — Phase 1** | Direct B2C — Hustlr mobile app via WhatsApp groups + referral |
| **Distribution — Phase 2** | B2B2C — Zepto platform integration + insurer white-label |

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

### B2B2C Distribution Channel (Phase 2)
After proving the model B2C, Hustlr embeds directly inside the Zepto partner app as a white-label insurance feature. Zepto pays a per-worker monthly licensing fee. The insurer underwrites the risk. Guidewire collects a technology licensing fee from the insurer.

**Why platforms pay for this:**
- Reduces worker churn during bad weather
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
  Device integrity: Play Integrity API — PASS
  Fixed rate:       ₹50/hr (Heavy Rain, Standard Shield)

  Payout = ₹50 × 3 = ₹150  →  auto-disbursed to UPI Sunday night
```

**Why weekly settlement, not instant:** Claims log throughout the week. Settlement runs every Sunday at 11 PM. The fraud engine evaluates the **complete week's pattern** before any money moves. A worker who triggers 3 events in one week activates the claim velocity signal before any payout releases. Weekly settlement also perfectly matches Zepto's weekly partner payment cycle.

**Why 60–70% income replacement, not 100%:** Parametric insurance by design does not fully replace income — this is basis risk, and it is intentional. Paying ₹50/hr (67% replacement) means honest workers are protected without the product becoming a profit opportunity. Full replacement creates moral hazard. The 60–70% band is the industry standard for parametric income protection.

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

Elite Shield workers receive compound trigger payouts when two disruptions occur simultaneously.

| Compound Combination | Logic | Payout % of Daily Cap |
|---|---|---|
| Rain (severe) + Platform Downtime | Both active simultaneously in zone | 100% |
| Rain (any) + Traffic Standstill | Both active in zone simultaneously | 70% |
| Extreme Heat + High AQI | Both above threshold simultaneously | 55% |
| Cyclone Watch + Rain | Advisory active + rainfall >30mm/hr | 85% |
| Dark Store Closed + Rain | Both conditions confirmed | 100% |
| Curfew + Platform Outage | Both active during shift window | 100% |

**Business logic:** When two disruptions overlap, income loss is multiplicative — not additive. Rain alone reduces deliveries by 70%. Rain plus platform downtime reduces deliveries by 100%. Elite Shield pays a compound bonus reflecting the true income impact.

**Claim-Free Cashback (Elite Shield):**
Workers on Elite Shield who complete 4 consecutive weeks without a payout receive 10% of their premiums from those 4 weeks returned as wallet credit. This solves adverse selection — rewarding workers who stay insured during calm periods builds a healthier premium pool. The cashback costs the insurer approximately ₹43 per qualifying period.

---

## 🛡️ Anti-Gaming Rules

- **Minimum duration:** 45 continuous minutes above threshold before trigger activates
- **Cooling period:** Same disruption type cannot trigger again in same zone within 24 hours
- **Shift intersection:** Disruption must overlap worker's registered shift by minimum 2 hours
- **One event per week per type** for Basic and Standard Shield plans
- **Pro-rata for mid-week activation:** Worker activating on Thursday receives payout weighted by days active
- **Post-purchase coverage only:** Disruptions beginning before policy activation are never covered

### Threshold Obfuscation + Dynamic Micro-Variation

**Exact trigger thresholds are never published.** Workers see only ranges — never specific millimetre values.

The actual trigger threshold varies by ±3mm (rain) or ±0.5°C (heat) each week using a seeded random value known only to the system. Workers can never predict the exact number for the current week.

**Why this matters for Chennai specifically:** Research into Chennai delivery worker behavior reveals workers are highly financially sophisticated and actively probe incentive systems. The Rapido/cab driver pattern of gaming platform incentives is directly applicable to insurance threshold gaming. Workers in organized groups can identify precise thresholds through repeated testing and share them via WhatsApp. Threshold micro-variation makes this strategy unreliable.

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

**Fraud resistance:** Faking connectivity loss requires active data transmission to submit the claim — which is self-contradictory. This makes the internet blackout trigger one of Hustlr's most inherently fraud-resistant signals.

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

**City-specific corridor baselines ✅ (Phase 2 live — all 4 cities):**

| City | High-Risk Corridor | Baseline | Trigger Threshold |
|---|---|---|---|
| Chennai | GST Road, Anna Salai | 18–22 km/h | < 11–13 km/h |
| Bengaluru | Electronic City Flyover, ORR | 15–20 km/h | < 9–12 km/h |
| Mumbai | Eastern Express Highway, WEH | 20–25 km/h | < 12–15 km/h |
| Delhi | NH48, Gurugram corridor | 22–28 km/h | < 13–17 km/h |

---

## 📋 Real Scenario Simulations

### Scenario A — Chennai November Rain (Fully Automated — Phase 2)

```
Date:         November 12, 2025 · Location: Adyar, Chennai
IMD data:     72mm rainfall — threshold crossed for 3 hours
Data Trust:   IMD (Tier 1, 0.92) + OpenWeatherMap (Tier 2, 0.78)
              Combined trust: 0.85 — EXCEEDS 0.75 threshold  →  VALID
Shift window: 11 AM–2 PM within Karthik's 8 AM–10 PM  →  PASS
Zone depth:   Karthik's GPS shows 0.84 — core zone  →  PASS
Fraud score:  FRS = 14/100 — CLEAN  →  AUTO-APPROVE
Circuit BCR:  Pool at 44% — well within 85% ceiling  →  CIRCUIT CLOSED

Payout = ₹50/hr × 3 hrs = ₹150

Timeline:
  11:00 AM  →  IMD threshold crossed
  11:02 AM  →  Data Trust Engine: combined 0.85 — PASS
  11:02 AM  →  Zone depth: 0.84 — PASS
  11:02 AM  →  Fraud engine: FRS = 14 — CLEAN
  11:02 AM  →  Circuit Breaker: BCR 44% — CLOSED
  11:02 AM  →  Claim logged PENDING — Karthik notified: "Rain disruption detected"
  Sunday    →  70% tranche (₹105) released to Karthik's UPI
  Tuesday   →  30% safety tranche (₹45) released after review window
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
   Activate Standard Shield now — ₹49/week."

One tap — policy activated. Coverage starts Monday.
```

### Scenario C — Predictive Activation (Wednesday Nudge)

```
Wednesday evening — Hustlr's 72-hour forecast runs.
OpenWeather shows: 78% probability of IMD Very Heavy Rain
in Adyar zone on Friday 2 PM–6 PM.

Karthik receives push notification:
  "Heavy rain expected Friday in your zone.
   Activate ₹49 Standard Shield now to protect ₹600+ earnings."

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

**Layer 0 — Device Integrity Check (runs before any GPS is trusted):**

Every claim is rejected before processing if the device fails integrity checks. A GPS spoofing app requires developer mode or root access — catching this at the device layer blocks the entire attack vector before a single GPS coordinate is evaluated.

```
Check 1 — Play Integrity API (Google)
  Verifies app has not been tampered with
  Confirms device is not rooted or jailbroken
  Confirms developer mode is OFF
  Returns: MEETS_DEVICE_INTEGRITY / FAILS_DEVICE_INTEGRITY

Check 2 — Mock Location Detection
  Android exposes isMockLocation flag in location data
  If true → GPS coordinates are software-generated, not physical
  Result: claim auto-rejected, worker notified

Check 3 — Developer Mode Check
  If USB debugging enabled → adds +20 to fraud score

Rule: Any claim from a device failing Play Integrity API
      is auto-rejected before fraud scoring begins.
```

**Why this matters:** Every GPS spoofing app on Android requires mock location permissions (developer mode) or root access. Layer 0 eliminates 90%+ of spoofing attempts before any other signal is evaluated — the lowest-cost, highest-impact fraud prevention step in the entire system.

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
Before any payout, Hustlr independently queries Brave Search and NewsAPI for verified public crisis reports specific to the claimed zone and time. Absence of public corroboration is a scored fraud signal. A syndicate cannot fabricate official IMD alerts or government advisories.

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
| Geographic Clustering (DBSCAN) | Claims in implausibly tight boundary | Ring from one Telegram group |
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

### Network Drop Signal Recognition — Honest Worker Protection Flow

When a worker's GPS signal is lost during a disruption event, Hustlr does not automatically reject their claim. It runs a specific verification flow to distinguish a genuine stranded worker from a fraudster at home.

```mermaid
flowchart TD
    ND1[GPS Signal Lost During Disruption] --> ND2{Wi-Fi SSID Check}
    ND2 -- Home SSID detected --> ND3[Worker at home\nClaim rejected]
    ND2 -- Unknown SSID or no Wi-Fi --> ND4{Cell Tower Check}
    ND4 -- Tower in disruption zone --> ND5[Worker physically in zone\nClaim approved with delay note]
    ND4 -- Tower outside zone --> ND6{Platform Activity Check}
    ND6 -- Zero orders in window --> ND7[Signal ambiguous\nFlag for soft review\nDo NOT auto-reject]
    ND6 -- Orders found --> ND8[Worker was active\nClaim rejected]
    ND5 --> ND9[Payout Released\nWorker notified: verification complete]
    ND7 --> ND10[30-min grace window\nRe-check all signals\nWorker notified: verifying automatically]
```

**The 30-minute grace window:** GPS loss alone never causes auto-rejection. The system always checks two independent alternative signals before making any determination. A worker stranded in a flood zone with no connectivity is exactly the worker Hustlr exists to protect.

---

## 📍 Zone Depth Scoring — Anti-Boundary Gaming

**The problem with binary zone membership:** Workers can game a hard boundary by standing 50 metres inside it during a disruption. A financially sophisticated Chennai worker will learn where the boundary is and exploit it.

**Hustlr's solution — Continuous Zone Depth Score:**

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

A worker who runs to the zone edge the moment rain starts has a depth score near zero — payout multiplier of 0.0. A worker who spent their entire shift delivering deep inside the zone has a depth score of 0.84 — full payout. There is no single coordinate to stand on.

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

**Phase 2 ✅:** ISS rule engine live. XGBoost upgrade planned for Phase 3 when real worker data accumulates.

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

Seven-layer stacked scoring using the weighted ensemble FPS architecture. Runs in < 2 seconds. Isolation Forest feature vector:

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

**Phase 1 ✅:** spaCy keyword scoring. Dual confirmation required.

**Phase 2 ✅:** LLM preprocessing for unstructured government advisories now live. The LLM touches preprocessing only — every YES/NO payout decision remains deterministic and auditable.

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

Research into Chennai delivery worker behavior — through Reddit (r/Chennai, r/india), delivery partner forums, Twitter/X, and YouTube delivery partner vlogs — reveals a consistent pattern: Chennai gig workers are financially sophisticated and actively probe platform incentive systems. The Rapido/cab driver behavior of understanding surge mechanics and finding system edges is directly applicable to parametric insurance.

**What the research identified:**

1. Workers share threshold information in WhatsApp groups within hours of discovery
2. Delivery partner communities in Chennai are highly organized
3. Financial incentive awareness is high — workers track per-order rates, surge timing, and bonus structures precisely
4. Collective action is common — Chennai workers have organized successful platform negotiations previously

### Regional Behavior Risk Index

| City | Behavioral Risk Index | Key Characteristic |
|---|---|---|
| Chennai | 0.65 | High financial literacy, organized communities, incentive-aware |
| Bengaluru | 0.55 | Tech-adjacent workforce, individual optimization focus |
| Mumbai | 0.50 | Volume-focused, less community coordination |
| Delhi | 0.45 | Diverse worker base, lower coordination density |
| Tier 2 cities | 0.30 | Lower financial literacy, less organized |

**How this index is used:**
- Adjusts fraud signal weights regionally
- Informs the threshold micro-variation range
- Calibrates zone depth scoring multiplier curve
- NOT used to deny individual claims — portfolio-level actuarial input only

**The ethical boundary:** Regional behavioral intelligence adjusts system-level thresholds and fraud weights. It never denies an individual worker's claim based on their city alone.

---

## 🚀 Innovation Differentiators

### 1. Shadow Policy — Uninsured Worker Conversion

Workers who have not purchased insurance are tracked in a **shadow policy mode**. After 2 weeks, the app displays:
> *"You would have received ₹680 in payouts this fortnight if you were insured. Rain disruption Oct 12 → ₹450. Platform downtime Oct 08 → ₹230."*

Acquisition cost for a worker who converts via shadow policy = ₹0.

### 2. Predictive Insurance Activation

Every Wednesday evening, Hustlr runs a 72-hour disruption forecast. If probability exceeds 60%, workers receive:
> *"Heavy rain expected Friday 2–6 PM in your Adyar zone. Activate Standard Shield now to protect up to ₹600 of Friday earnings."*

Workers activate before the disruption — not after. A 65% loss ratio on a ₹49 premium is ₹17 profit per worker per week.

### 3. Play Integrity API as Layer 0

Catching GPS spoofing at the device level before any GPS data is processed. Every spoofing app requires developer mode or root — Hustlr blocks this at the entry point, eliminating 90%+ of spoofing attempts before fraud scoring begins.

### 4. Zone Depth Scoring

Replaces binary zone membership with continuous presence scoring. No other team will implement this.

### 5. Regional Behavioral Intelligence

Chennai-specific fraud calibration based on gig worker community research. The system gets harder to game over time as the NLP scanner detects new exploitation patterns weekly.

### 6. Internet Blackout as First-Class Trigger

For Q-commerce workers who cannot operate without connectivity, an internet blackout is as income-destroying as rain. No parametric insurance product in India currently covers this.

### 7. Insurer Profitability Simulator

> *"If a Cyclone Michaung-level event hits Chennai today, what is total payout exposure across all active policies?"*

Exactly the kind of enterprise risk tool Guidewire builds for large insurers — packaged inside Hustlr.

### 8. Data Trust Engine — Multi-Source Credibility Scoring *(Phase 2)*

Rather than trusting any single data source, every disruption event is graded against a **4-tier Trust Matrix** (Tier 1: Govt/Official 0.90–1.00 → Tier 4: Device Sensors 0.20–0.30). Sources are cross-referenced, and their combined trust must exceed **0.75** to trigger a payout. GPS alone — structurally capped at 0.20–0.30 — can never trigger a payout on its own. This eliminates an entire class of fraud attacks at the data-source level.

### 9. Economic Circuit Breaker — Pool Insolvency Prevention *(Phase 2)*

A real-time **Burning Cost Rate (BCR)** monitor tracks the live ratio of claims paid vs premiums collected. Hard limits: 50 auto-approved claims per zone per hour, 85% BCR ceiling. If the pool approaches insolvency during a catastrophic week, new enrollments are automatically halted for that city — protecting existing policyholders without any manual intervention. The circuit breaker transforms a passive premium pool into an actively self-defending financial instrument.

### 10. 70/30 Tranche Payout Architecture *(Phase 2)*

Payouts are split at disbursement: **70% sent immediately** (covers food, petrol, rent — the urgent expenses a stranded worker has that day) and **30% held until Sunday settlement** (gives the fraud engine a full-week pattern review before the final tranche releases). Workers receive money the same day their disruption occurs while the system retains the ability to claw back the safety tranche on late-detected fraud. No other Indian parametric product uses tranche-based disbursement.

### 11. API Resilience Wrapper — Zero-Downtime Trigger Engine *(Phase 2)*

The `api_wrapper.js` resilience layer means Hustlr never stops monitoring even when upstream APIs fail. Any API that fails 3 consecutive polls is automatically marked `DEGRADED` — the system switches to verified cached data for 5 minutes then retries. Workers are never disadvantaged because OpenWeatherMap had a bad hour. The system's trigger accuracy is structurally independent of any single API provider's uptime.

---

## 💰 Weekly Premium Tiers

| Plan | Weekly Premium | Covers | Expected Weekly Payout | Target Loss Ratio | Best For |
|---|---|---|---|---|---|
| **Basic Shield** | ₹29/wk | Rain + extreme heat | ~₹19 | 0.65 | Low-risk zones, new workers |
| **Standard Shield** ⭐ | ₹49/wk | Rain, heat, pollution, app downtime | ~₹32 | 0.65 | Most city delivery workers |
| **Full Shield** | ₹79/wk | All types incl. bandh + internet blackout | ~₹53 | 0.67 | Flood-zone workers |
| **Elite Shield** 🔥 | ₹109/wk | All types + compound triggers + 10% cashback | ~₹60 | 0.55 | High-traffic zone workers |

### Premium Bounds — Actuarial Guardrails

Regardless of AI risk score output, weekly premiums are hard-capped:

| Bound | Multiplier | Example (Standard Shield ₹49 base) |
|---|---|---|
| Maximum | 2.0× base tier rate | ₹98/week |
| Minimum | 0.7× base tier rate | ₹34/week |

**Why bounds exist:** Without a ceiling, a Velachery worker during a cyclone forecast week could receive an unbounded premium — making the product unaffordable exactly when they need it most. The 2× ceiling ensures accessibility during high-risk periods. The 0.7× floor ensures the insurer never writes coverage below the actuarial minimum needed to sustain the pool. The ±20% week-over-week change cap prevents premium shock — even if ISS drops sharply in one week, the worker's rate cannot spike more than 20% from the previous week.

### Income Add-Ons

| Add-On | Weekly Cost | Covers |
|---|---|---|
| Curfew & Strike | +₹15/wk | Bandh, curfew, Section 144 |
| Election Day | +₹20/wk | Polling day restricted movement |
| App Downtime | +₹12/wk | Platform outage via order failure rate |
| Cyclone | +₹25/wk | Extreme rain + cyclone alerts |
| Internet Blackout ✅ | +₹18/wk | Zone-level connectivity outage |
| Accident Blockspot ✅ | +₹15/wk | Road blocked on hotspot corridors |
| Heavy Traffic Congestion ✅ | +₹15/wk | Speed ≥ 40% below baseline for ≥ 45 min |

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

```mermaid
flowchart TD
    A([Worker opens Hustlr]) --> B[OTP login\nsingle device lock]
    B --> C[Onboarding\nplatform + zone + avg income]
    C --> D[ISS calculated\ncity risk profile applied]
    D --> E[Weekly policy created\nvia PolicyCenter]
    E --> F[Weekly premium deducted\nvia BillingCenter]
    F --> G{Monitoring loops\nevery 15 minutes}

    G --> H[Weather API]
    G --> I[Platform order failure rate]
    G --> J[NLP scraper]
    G --> K[Ookla + TRAI internet signals]
    G --> L[Traffic API + news corroboration]

    H --> M{Data Trust Engine\ncombined score > 0.75?}
    I --> M
    J --> M
    K --> M
    L --> M

    M -->|FAIL| G
    M -->|PASS| N{Threshold + shift\nwindow check}
    N -->|FAIL| G
    N -->|PASS| O[Zone depth score calculated]

    O --> P[FPS computed across\n7 layers in under 2 seconds]

    P -->|GREEN| Q{Circuit Breaker\nBCR < 85%?}
    P -->|YELLOW| Q
    P -->|RED| R[Manual review\nprovisional 100-300 credit]

    Q -->|OPEN — pool critical| S[Enrollment halted\nExisting policies protected]
    Q -->|CLOSED — pool healthy| T[70% immediate tranche\nreleased to worker UPI]

    T --> U[Sunday 11 PM\nweekly settlement batch]
    R --> U
    U --> V[30% safety tranche released\nFull payout complete Monday]
    V --> W[Shadow policy tracks\nuninsured workers]
    W --> X[Wednesday forecast\npredictive nudge sent]
    X --> G
```

---

## 📡 Parametric Trigger Decision Flow

```mermaid
flowchart TD
    T1[Real-time data received\nevery 15 minutes] --> T2{Data Trust Engine\ncombined source trust > 0.75?}
    T2 -- Trust insufficient --> T3[Log reading\ncontinue monitoring]
    T2 -- Trust confirmed --> T4{Threshold\nbreached?}
    T4 -- No --> T3
    T4 -- Yes --> T5{Minimum 45-minute\nduration confirmed?}
    T5 -- No --> T3
    T5 -- Yes --> T6{Shift window\noverlap check}
    T6 -- Outside shift --> T7[No payout\ndisruption outside work hours]
    T6 -- Within shift --> T8[Layer 0: Play Integrity\ndevice check]
    T8 -- Device fails --> T9[Auto-reject\nworker notified]
    T8 -- Device passes --> T10[Zone depth score\ncalculated]
    T10 -->|Score below 0.20| T11[No payout\nboundary gaming detected]
    T10 -->|Score above 0.20| T12[FPS fraud scoring\nacross 7 layers]
    T12 -->|GREEN / YELLOW| T13{Circuit Breaker\nBCR < 85%?}
    T12 -->|RED| T14[Manual review queue\nprovisional credit released]
    T13 -- OPEN pool critical --> T15[Enrollment halted\nExisting policies protected]
    T13 -- CLOSED pool healthy --> T16[70% immediate tranche\nworker notified]
    T16 --> T17[Sunday settlement\n30% safety tranche released]
    T14 --> T17
```

---

## 🛡️ Fraud Detection Decision Flow

```mermaid
flowchart TD
    F1[Claim initiated] --> F2[Layer 0: Device Integrity\nPlay Integrity API + mock location check]
    F2 -- Fails --> F3[Auto-reject]
    F2 -- Passes --> F4[Layer 1: Individual signals\nGPS jitter + IP + Wi-Fi + accelerometer\nbarometer + battery + fingerprint]
    F4 --> F5[Layer 2: Behavioral baseline\nPersonal activity graph comparison]
    F5 --> F6[Layer 3: News corroboration\nBrave Search + NewsAPI 0.25 weight]
    F6 --> F7[Layer 4: Behavioral fingerprinting\nclaim latency + orders during disruption\nlongitudinal frequency]
    F7 --> F8[Layer 5: Ring detection\nPoisson test + DBSCAN clustering\ndevice fingerprint similarity]
    F8 --> F9[Layer 6: Internet blackout\nself-validation check]
    F9 --> F10{Weighted ensemble FPS\n5 category scores}
    F10 -->|0.0-0.30 GREEN| F11[Auto-approve\npayout within 2 minutes]
    F10 -->|0.31-0.60 YELLOW| F12[Soft hold\nprovisional credit + 2hr verification]
    F10 -->|0.61+ RED| F13[Human review\nprovisional 100-300 released\nauto-explanation sent to worker]
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

The anti-spoofing engine requires direct native access to: cell tower IDs, Wi-Fi SSID fingerprints, GPS jitter readings, accelerometer, battery state, barometric pressure, signal strength, and Play Integrity API. PWAs cannot reliably access all of these on Android. Flutter provides full native sensor access plus a single codebase for both Android (worker app) and web (insurer admin dashboard).

Background GPS tracking via `flutter_background_geolocation` runs continuously during shifts — even when the phone screen is off — providing the continuous location data that zone depth scoring requires.

---

## 🛠️ Tech Stack

**Frontend**

| Component | Technology |
|---|---|
| Framework | Flutter (Dart) |
| State Management | flutter_bloc + Provider (UserBloc, PolicyBloc, ClaimsBloc) |
| Background Location | flutter_background_geolocation |
| Local Storage | Hive (offline-first) |
| Payments (mock) | Instamojo test mode + Razorpay Flutter SDK |
| Notifications | Firebase Cloud Messaging + Twilio SMS fallback |
| Device Integrity | Play Integrity API |

**Backend**

| Component | Technology |
|---|---|
| API Server | Node.js + Express |
| Database | Supabase (PostgreSQL + PostGIS) |
| Auth | Supabase Auth (OTP via phone) |
| Hosting | Render (free tier) |
| Trigger Polling | Node-cron (every 15 min) |
| NLP Scraper | Python + spaCy + LLM preprocessing via FastAPI microservice |
| Data Trust Engine | `data_trust.js` — 4-tier cross-source credibility scoring |
| Fraud Engine | `fraud_engine.js` — Abuse Score 0–100 + auto-decision router |
| Circuit Breaker | `circuit_breaker.js` — BCR monitoring + zone rate limits |
| Payout Dispatch | `payout_service.js` + `instamojo_payout.js` — 70/30 tranche |
| API Resilience | `api_wrapper.js` — 3-strike degraded mode + 5-min cache fallback |
| DB Triggers | `triggers.sql` — pool sync, financial auto-compute, baseline generation |

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
| Play Integrity API | Device integrity verification | Free (Google) |
| Zepto | Order failure rate + status | Mock Phase 1 |
| Razorpay | UPI payout simulation | Test mode |

---

---

## 🏗 Phase 2: Backend Micro-Services Architecture

The core intelligence lives in `hustlr-backend/src/services/`. Each service is an independent module responsible for a single domain — designed so individual actuaries and adjusters can be upgraded, swapped, or scaled without touching adjacent systems.

### A. Data Sources — Real-Time Disruption Monitoring

The backend polls external APIs every 15 minutes to track ground-truth disruptions.

| Service | File | What It Does |
|---|---|---|
| Weather | `weather_service.js` | OpenWeatherMap — monitors rainfall (>64.5 mm/hr Heavy Rain, >115.6 mm/hr Cyclonic) and Heat Waves (>43°C) |
| AQI | `aqi_service.js` | AQICN/WAQI — flags Severe Pollution events (AQI ≥ 200) |
| Traffic | `traffic_service.js` | Google Maps — monitors road-speed gridlock vs historical baseline |
| Cell Tower + News | `cell_tower_service.js` + `news_service.js` | Additional corroboration sources cross-referencing active disruptions |
| API Wrapper | `api_wrapper.js` | **Resilience layer** — if any upstream API fails 3 consecutive polls, marks it `DEGRADED` and falls back to cached data for exactly 5 minutes before retry |

### B. The Data Trust Engine (`data_trust.js`)

GPS and device accelerometers are trivially spoofable. Hustlr grades every incoming data point on a **Trust Matrix** before any payout decision is made.

| Tier | Source Examples | Trust Range |
|---|---|---|
| **Tier 1 — Govt/Official** | IMD advisories, NDMA alerts | 0.90 – 1.00 |
| **Tier 2 — Third-Party Verified** | OpenWeatherMap, AQICN, Platform logs, News | 0.70 – 0.85 |
| **Tier 3 — Community Reports** | Crowd-sourced connectivity reports | 0.40 – 0.65 |
| **Tier 4 — Device Sensors** | GPS coordinates, Accelerometers | 0.20 – 0.30 |

**Trust Rule:** A single source is insufficient. Sources are cross-referenced and their combined trust score must mathematically exceed **0.75** to be considered valid for payout triggering. GPS alone — Tier 4 at 0.20–0.30 — is structurally incapable of triggering a claim on its own.

### C. The Fraud Engine (`fraud_engine.js`)

To operate profitably with zero human claims adjusters, claims must self-regulate against bad actors. The fraud engine calculates an **Abuse Score (0–100)** per claim from worker history and live signal analysis.

**Red Flags That Increase the Abuse Score:**

| Signal | Score Added |
|---|---|
| Account age < 14 days | +20 |
| Claim velocity spike — 50+ claims from one zone in 10 min | +25 |
| User location/zone mismatch | +25 |
| Claiming outside declared shift window (8 AM – 10 PM) | +20 |
| Device in developer mode / mock location detected | Auto-reject (Layer 0) |

**Auto-Decision Router:**

| Score | Outcome |
|---|---|
| **< 30 — Clean** | Payout instantly auto-approved |
| **30–60 — Soft Hold** | Payout delayed 2 hours; amount restricted to 70% tranche only |
| **> 60 — Flagged** | Sent immediately to manual admin review queue |

### D. The Economic Circuit Breaker (`circuit_breaker.js`)

A liquidity failsafe protecting the premium pool against insolvency during mass-disruption events (e.g., Cyclone Michaung week).

The circuit breaker tracks the **Burning Cost Rate (BCR)** — the live ratio of `Claims Paid ÷ Premiums Collected`.

**Hardcoded Limits:**

| Parameter | Limit |
|---|---|
| Maximum auto-approved claims | 50 per hour per zone |
| Maximum pool BCR | 85% |

If the BCR breaches 85%, the system **automatically halts all new policy enrollments** for that city. Existing policies continue to be honoured. No new exposure is written until the pool recovers — preventing insolvency while protecting active workers already covered.

### E. Payout Dispatch (`payout_service.js` + `instamojo_payout.js`)

Once a claim clears fraud scoring and the circuit breaker allows it:

**Tranche Architecture:**
- **70% Immediate Tranche** — transferred to the worker's linked UPI/account instantly to cover urgent expenses (food, petrol)
- **30% Safety Tranche** — held and released at end of week after the full week's claim pattern review

**Failure Resilience:**
- Transfer retried up to **3 times** before issuing a fatal `PAYOUT_FAILED` state written to Supabase
- Every failure state generates an admin notification and a worker-facing message explaining the delay

---

## 🗄 Phase 2: Database Architecture — Supabase Triggers

Rather than burdening the Node.js application layer with synchronisation logic, Hustlr delegates critical financial state management to the PostgreSQL database itself via `triggers.sql`.

| Trigger | Event | What It Does |
|---|---|---|
| **Metadata Sync** | Any row update | Always stamps `updated_at` — ensures audit trail integrity |
| **Pool Synchronisation** | Policy status change | Auto-increments/decrements `active_policies` count in `risk_pools` table — pool health stays current without an API call |
| **Financial Auto-Compute** | Claim status → `SETTLED` | Triggers compute and write `total_claims_paid` and recalculate `loss_ratio` directly in the DB — no application-layer race condition possible |
| **Baseline Generation** | New user created | Auto-creates a `fraud_baselines` entry and generates a formatted short `referral_code` — zero-touch new-user provisioning |

**Why DB-level triggers:** Application-layer synchronisation introduces race conditions under concurrent claims (e.g., cyclone week with 1,000 simultaneous payouts). PostgreSQL triggers execute atomically within the same transaction — the pool balance and loss ratio are always consistent without locking.

---

## 👤 Phase 2: Registration & Onboarding Flow

Optimised for a delivery worker completing registration at a red light on a ₹10,000 Android phone. Target: full onboarding under 90 seconds.

```
Step 1 — Phone OTP Login
  Single device lock enforced at registration.
  One account per verified phone number.

Step 2 — Platform Selection
  Worker selects: Zepto / Swiggy / Zomato / Amazon / Other
  Platform exclusivity compliance confirmed.

Step 3 — Zone Declaration
  Worker selects their primary dark store / delivery zone.
  PostGIS records the zone centroid for depth scoring.

Step 4 — Income Baseline
  Worker self-declares average weekly income (₹ range picker).
  Used to calibrate ISS score and payout rate.

Step 5 — ISS Score Calculated
  Rule engine runs in < 1 second.
  Tier recommendation displayed: "Based on your zone, Standard Shield is best for you."

Step 6 — Plan Selection
  Worker sees all four tiers + relevant add-on toggles.
  Pricing shown weekly — no monthly confusion.

Step 7 — Weekly Policy Created
  PolicyCenter API called.
  BillingCenter schedules first weekly deduction.
  Worker receives confirmation push notification.
```

**Onboarding anti-fraud controls active from Step 1:**
- 14-day new-account heightened scrutiny flag set automatically
- Referral chain depth recorded for ring-detection baseline
- Device hardware fingerprint captured and stored

---

## 📋 Phase 2: Insurance Policy Management

### Policy Lifecycle

```
Monday 12:01 AM  →  New weekly policy created via PolicyCenter
Monday  (debit)  →  BillingCenter executes weekly premium deduction
Throughout week  →  Policy status: ACTIVE — triggers monitored
Sunday 11 PM     →  Weekly settlement batch — claims evaluated
Sunday 11:30 PM  →  ISS score refreshed for next week
Monday 12:01 AM  →  New policy issued for next week (loop continues)
```

### Plan Tiers — Active in Phase 2

| Plan | Weekly Premium | Core Coverage | Add-Ons Available |
|---|---|---|---|
| **Basic Shield** | ₹29/wk | Rain + extreme heat | Cyclone, App Downtime |
| **Standard Shield** ⭐ | ₹49/wk | Rain, heat, pollution, app downtime | Curfew/Strike, Cyclone, Internet Blackout |
| **Full Shield** | ₹79/wk | All types incl. bandh + internet blackout | Accident Blockspot, Heavy Traffic |
| **Elite Shield** 🔥 | ₹109/wk | All types + compound triggers + 10% cashback | All add-ons bundled |

### Policy Add-Ons — Phase 2 Live

| Add-On | Weekly Cost | Status |
|---|---|---|
| Curfew & Strike | +₹15/wk | ✅ Live |
| App Downtime | +₹12/wk | ✅ Live |
| Cyclone | +₹25/wk | ✅ Live |
| Election Day | +₹20/wk | ✅ Live |
| Internet Blackout | +₹18/wk | ✅ Live — Phase 2 |
| Accident Blockspot | +₹15/wk | ✅ Live — Phase 2 |
| Heavy Traffic Congestion | +₹15/wk | ✅ Live — Phase 2 |

---

## 💰 Phase 2: Dynamic Premium Calculation

Hustlr uses a **fixed-tier + ISS-influenced onboarding recommendation** model — not a week-to-week dynamic repricing model. This is a deliberate design decision.

**Why fixed tiers (not dynamic repricing):**

Workers on ₹500–600/week incomes cannot budget around a price that shifts each Sunday. A cyclone week where a premium jumps from ₹87 to ₹121 would cause workers to cancel coverage exactly when they need it most — defeating the product's purpose. Fixed tiers with a transparent price a worker can rely on week-to-week are non-negotiable for this persona.

**How the ISS score still drives dynamic intelligence:**

```
ISS 0–29   →  Recommend Elite Shield  (₹109/wk)
ISS 30–49  →  Recommend Full Shield   (₹79/wk)
ISS 50–69  →  Recommend Standard Shield (₹49/wk)
ISS 70–100 →  Recommend Basic Shield  (₹29/wk)
```

The ISS score influences which tier a worker is recommended at onboarding — and re-evaluated weekly to detect if their risk profile has changed enough to suggest a tier upgrade or downgrade. The worker decides whether to act on the recommendation. Their price does not change without their explicit action.

**Premium Guardrails:**

| Bound | Multiplier | Example (Standard Shield base) |
|---|---|---|
| Maximum premium | 2.0× base rate | ₹98/week |
| Minimum premium | 0.7× base rate | ₹34/week |
| Week-over-week ISS change cap | ±20% recommendation shift | Prevents shock re-recommendations |

---

## 🔄 Phase 2: Claims Management

### Automated Claims (Zero Worker Action Required)

For all parametric triggers (weather, AQI, bandh, internet blackout, platform outage), claims are initiated server-side — the worker never files anything.

```
1. Cron job fires every 15 minutes
2. Data trust engine validates source credibility (combined trust > 0.75)
3. Threshold + shift window check passes
4. Zone depth score calculated via PostGIS
5. Fraud engine scores the claim (Abuse Score 0–100)
6. Circuit breaker confirms pool BCR is within limits
7. Claim written to Supabase with status PENDING
8. Worker receives push notification: "Rain disruption detected in your zone. Claim queued for Sunday settlement."
9. Sunday 11 PM: settlement batch runs, payout dispatched
```

**3–5 Automated Triggers Built (Phase 2):**

| # | Trigger | API Source | Threshold |
|---|---|---|---|
| 1 | Heavy Rain | OpenWeatherMap + IMD | ≥ 64.5 mm/hr |
| 2 | Extreme Rain / Cyclone | OpenWeatherMap + IMD | ≥ 115.6 mm/hr |
| 3 | Platform App Outage | Mock Zepto API (order failure rate) | Order failure > 60% |
| 4 | Internet Zone Blackout | Ookla Speed Map + TRAI Registry | < 10% connectivity for ≥ 30 min |
| 5 | Bandh / Curfew / Strike | NewsAPI + NLP scraper | NLP confidence ≥ 0.6 + platform OFFLINE |

### Manual Claims — Worker-Initiated (Assisted Flow)

For accident blockspots and road closures where automated APIs cannot confirm the disruption with sufficient confidence, workers use the **"Report a Disruption"** button on the Claims screen.

```
Step 1 — Select Disruption Type
  🚧  Road Blocked / Accident
  🏪  Dark Store / Hub Closed
  🌐  Internet Outage (zone-level)
  📦  Other Delivery Blockage

Step 2 — Evidence Capture (EXIF-stamped, live camera only — no gallery uploads)
  Road Blocked   →  1 photo (GPS-stamped at capture via mandatory AI reticle overlay)
  Hub Closed     →  1 photo + Zepto screenshot (zero orders)
  Internet       →  App auto-reads signal strength — no photo required
  Other          →  1 photo + description (max 100 chars)

Step 3 — Submit + Track
  Claim ID issued immediately
  Status screen: SUBMITTED → UNDER REVIEW → APPROVED/REJECTED
  4-hour SLA for manual reviews
  One-tap appeal within 4 hours if rejected
```

**Manual claim anti-fraud controls:**
- Live capture enforced — `manual_claim_camera_screen.dart` mandates the AI reticle overlay, blocking gallery uploads entirely
- EXIF timestamp + GPS coordinates validated against the declared zone
- Cross-checked against Traffic API gridlock data + NewsAPI corroboration
- Duplicate submission prevention — same zone + same disruption type within 24 hours blocked

### Seamless UX Principle

The best claim process is the one the worker never has to think about. For the 5 automated triggers, the worker does nothing — they receive a push notification and money appears on Sunday. The manual flow exists only as a fallback for the edge cases automated APIs cannot catch. SLA: 4 hours.

---

## 💸 Phase 2: Payout Dispatch

Once a claim clears fraud scoring and the circuit breaker, the payout is executed via `instamojo_payout.js` (mock/test mode):

```
Claim APPROVED
  → 70% Immediate Tranche  →  worker's UPI (instant)
  → 30% Safety Tranche     →  held until Sunday 11 PM weekly batch

Retry Logic:
  Attempt 1 → 2 → 3 → PAYOUT_FAILED (written to DB, admin alerted, worker notified)

Worker notification:
  "₹105 credited to your UPI (Karthik). ₹45 will follow Sunday night."
```

**Why split tranches:** The 70% immediate transfer covers the worker's urgent expenses — food, petrol, rent — on the day of disruption. The 30% safety hold gives the fraud engine a review window to catch late-detected anomalies before the full balance is released. Workers are told about both tranches at policy activation — no surprises.

---

## ⚡ Phase 2: Economic Circuit Breaker

The circuit breaker is a financial failsafe that protects the liquidity pool during mass-disruption weeks.

```python
# Pseudocode — circuit_breaker.js
def check_pool_health(city_zone):
    claims_paid_this_week = get_claims_paid(city_zone)
    premiums_collected = get_premiums_collected(city_zone)
    BCR = claims_paid_this_week / premiums_collected

    if claims_in_last_hour(city_zone) > 50:
        HALT new enrollments — "Rate limit exceeded"
        return CIRCUIT_OPEN

    if BCR > 0.85:
        HALT new enrollments for city — "Pool health critical"
        NOTIFY admin + reinsurance trigger evaluation
        return CIRCUIT_OPEN

    return CIRCUIT_CLOSED  # Normal operation
```

| BCR Level | System State | Action |
|---|---|---|
| < 65% | Healthy | Normal operations |
| 65–85% | Elevated | Admin warning, no change |
| > 85% | Critical | New enrollments halted for that city |
| > 400% pool (4× weekly total) | Catastrophic | Reinsurance clause activated |

---

## 🧪 MVP Scope — Phase 1 ✅, Phase 2 ✅ & Phase 3 ✅

### Phase 1 Complete ✅

- Rain trigger via live OpenWeatherMap + IMD with shift window check
- Zone depth scoring (3-ring model with payout multiplier)
- Fixed hourly payout (₹40–₹65/hr) with ₹150/day + ₹500/week caps
- Play Integrity API + mock location detection (Layer 0)
- NLP scraper for bandh detection (mock news feed)
- ISS scoring (rule engine) with named real datasets
- ISS-based onboarding tier recommendation
- Shadow policy tracking for uninsured workers
- Predictive 72-hour forecast nudge system
- Internet blackout trigger architecture
- Accident blockspot trigger with tap-to-confirm flow
- 7-layer weighted ensemble FPS fraud engine
- Regional behavioral intelligence layer (Chennai calibration)
- Threshold obfuscation + dynamic micro-variation
- Compound trigger logic for Elite Shield
- Claim-free cashback mechanic design
- News corroboration as scored fraud layer (0.25 FPS weight)
- Zone context override during declared emergencies
- Network drop grace period flow for honest workers
- Premium bounds (2× max, 0.7× min)
- Auto-explanation with named signals for every rejection
- Manual claim submission flow
- Guidewire ClaimCenter payload structure
- Insurer profitability simulator design
- UPI payout via Razorpay test mode

### Phase 2 Complete ✅

- Full Flutter app — all screens + manual claim camera flow (EXIF + AI reticle)
- BLoC state management (UserBloc, PolicyBloc, ClaimsBloc)
- Registration + KYC onboarding flow (< 90 seconds)
- Weekly policy creation via PolicyCenter API
- Insurance policy management (active, expired, history screens)
- Dynamic premium recommendation engine (ISS-driven tier suggestion)
- Premium guardrails (2× ceiling, 0.7× floor, ±20% ISS shift cap)
- 5 automated parametric triggers live (rain, cyclone, platform outage, internet blackout, bandh)
- Claims management — automated + manual fallback
- Manual claim camera screen with AI reticle (live capture enforced)
- Manual evidence submission flow
- Claims status tracking (SUBMITTED → UNDER REVIEW → APPROVED/REJECTED)
- Data Trust Engine (4-tier cross-source validation, >0.75 threshold)
- Fraud Engine with Abuse Score auto-router (< 30 auto-approve, 30–60 soft hold, > 60 flagged)
- Economic Circuit Breaker (BCR monitoring + 50 claims/hr zone cap)
- 70/30 tranche payout dispatch (Instamojo test mode)
- Supabase DB triggers (metadata sync, pool sync, financial auto-compute, baseline generation)
- API resilience wrapper (3-strike degraded mode + 5-minute fallback cache)
- Internet Blackout add-on live
- Accident Blockspot add-on live
- Heavy Traffic Congestion add-on live
- Wallet screen — financial ledger (payouts vs premiums)
- Dashboard — real-time disruption status, active policy card, ISS score

### Phase 3 Complete ✅

- Razorpay Sandbox Integration for premium payments and simulated UPI claim payouts
- Gemini/ML Kit Face Liveness Verification for rigorous KYC biometric anti-spoofing
- Complete Python Real-time ML Integration via isolated Render proxy endpoints
- Hardened ML backend infrastructure (Python 3.12 pinned + XGBoost native wheels)
- Multi-Language Runtime Translation (DynamicTranslator) supporting Hindi and Tamil formats
- Single-Session Security to prevent worker credential sharing/farming logic
- AI models embedded directly into Dashboard & Claims UX securely
- Upgraded ML timeout handling (30-second resilience threshold)

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
| Play Integrity API | ₹0 (Google free tier) |

**Total infrastructure: ₹0/month.**

---

## 📅 6-Week Plan

### ✅ Phase 1 (Weeks 1–2) — Current
- [x] Shift window eligibility architecture
- [x] Fixed hourly payout model with daily + weekly caps
- [x] Premium bounds (2× max, 0.7× min)
- [x] ISS scoring (rule engine) with named real datasets
- [x] ISS-based onboarding tier recommendation
- [x] Zone depth scoring (3-ring model + payout multiplier)
- [x] Shadow policy tracking for uninsured workers
- [x] Predictive 72-hour forecast nudge system
- [x] Regional behavioral intelligence layer (Chennai)
- [x] Threshold obfuscation + dynamic micro-variation
- [x] Compound triggers for Elite Shield
- [x] Claim-free cashback mechanic
- [x] Play Integrity API + mock location detection (Layer 0)
- [x] Weighted ensemble FPS architecture (7 layers)
- [x] GPS jitter analysis signal
- [x] Barometer / altitude mismatch signal
- [x] Device hardware fingerprint + install timestamp clustering
- [x] Orders-during-disruption auto-reject rule
- [x] Longitudinal claim frequency monitoring
- [x] News corroboration as scored fraud layer (0.25 weight)
- [x] Zone context override during declared emergencies
- [x] Network drop grace period flow
- [x] Poisson distribution ring detection (DBSCAN)
- [x] NLP scraper + LLM preprocessing architecture
- [x] Internet blackout trigger architecture
- [x] Accident blockspot trigger + Chennai hotspot map
- [x] Heavy traffic congestion trigger with baseline model
- [x] Transparent auto-explanation + one-tap appeal
- [x] Manual claim submission flow
- [x] Guidewire integration mapped (all three APIs)
- [x] B2C-first go-to-market + B2B2C Phase 2 design
- [x] Insurer profitability simulator design
- [x] Flutter scaffold + Supabase schema
- [x] Phase 1 demo video

### ✅ Phase 2 (Weeks 3–4) — Complete
- [x] Full Flutter app — all screens + manual claim flow
- [x] BLoC state management (UserBloc, PolicyBloc, ClaimsBloc)
- [x] Registration + onboarding flow (OTP → zone → ISS → plan selection)
- [x] Insurance policy management (create, view, history)
- [x] Dynamic premium recommendation (ISS-driven tier suggestion)
- [x] Weather + NLP trigger cron live
- [x] Order failure rate trigger live (mock Zepto API)
- [x] Internet blackout trigger live (Ookla + TRAI)
- [x] Bandh/curfew trigger live (NewsAPI + NLP)
- [x] Zone depth scoring live (PostGIS)
- [x] Play Integrity API live integration
- [x] Data Trust Engine live (4-tier source validation)
- [x] Fraud Engine — Abuse Score + auto-decision router
- [x] Economic Circuit Breaker (BCR monitoring + zone rate limits)
- [x] 70/30 payout tranche dispatch (Instamojo test mode)
- [x] Supabase DB triggers (pool sync, financial auto-compute, baseline generation)
- [x] API resilience wrapper (3-strike degraded mode + 5-min cache fallback)
- [x] Manual claim camera screen (AI reticle + live-capture enforcement)
- [x] Manual evidence submission + status tracking
- [x] Internet Blackout add-on live
- [x] Accident Blockspot add-on live
- [x] Heavy Traffic Congestion add-on live
- [x] Wallet screen — payout/premium ledger
- [x] Shadow policy calculation live
- [x] Predictive nudge notification live
- [x] Regional intelligence weekly scan live
- [x] Auto-explanation generation for all rejections
- [x] City risk profiles: Chennai + Mumbai + Bengaluru + Kolkata

### ✅ Phase 3 (Weeks 5–6) — Complete
- [x] Razorpay Sandbox Integration for simulated premium/payouts
- [x] Gemini/ML Kit Face Liveness Verification for KYC onboarding
- [x] Python ML integrated directly into Flutter Dashboard (XGBoost/Isolation Forest)
- [x] Single-Session Account Protection to block credential sharing
- [x] DynamicTranslator (i18n) for Hindi and Tamil runtime support
- [x] ML Render deployment hardened (Python 3.12 pinned + XGBoost wheels + PyTorch CPU optimized)
- [x] Secured proxy timeouts configured (30-second resilience threshold)
- [x] Isolation Forest fraud model + Poisson timing test
- [x] LLM news preprocessing pipeline
- [x] Facebook Prophet forecasting model
- [x] Final 5-min demo video + pitch deck

---

## 📊 Business Viability & Financial Model

### Go-To-Market Strategy — B2C First, B2B2C Second

Hustlr launches **direct to consumer** — not as enterprise infrastructure from day one.

**Phase 1 — B2C Direct (Months 0–12):**
```
Target:      10,000 Zepto workers in Chennai
Acquisition: WhatsApp delivery partner groups +
             referral program (₹50 wallet credit per referral)
Revenue:     ₹49 avg weekly premium × 10,000 workers
             = ₹4.9 lakhs/week
Goal:        Prove loss ratio stays below 65%
             Prove fraud rate stays below 5%
             Accumulate 12 months of real claims data
```

**Phase 2 — B2B2C Platform Sales (Months 12+):**
```
Pitch to Zepto:
  "10,000 of your delivery partners already use this.
   Loss ratio: 61%. Fraud rate: 3.2%.
   License it and offer it natively inside your app."

Pitch to ICICI Lombard / HDFC ERGO:
  "12 months of parametric claims data for Q-commerce
   workers in Chennai. Proven insurable at 61% loss ratio.
   License our engine."
```

### Premium Structure

| Parameter | Value | Rationale |
|---|---|---|
| Premium frequency | Weekly deduction | Matches gig worker pay cycle |
| ISS score update | Weekly (every Sunday night) | Reflects latest risk signals before Monday policy |
| Premium recalculation | Weekly (every Monday) | New PolicyCenter policy each week using latest ISS |
| Week-over-week change cap | ±20% maximum | Protects workers from shock spikes — ₹49 can only move to ₹39–₹59 in one week |
| Plan tier stability | Fixed per season | Worker knows which plan tier they're on |
| Payout type | Fixed amounts per trigger type | Parametric simplicity |

### Pool Protection Architecture

| Control | Parameter | Purpose |
|---|---|---|
| Weekly payout cap | 65% of pool | Target loss ratio — actual claims paid out |
| Reserve fund | 15% of pool | Claims overflow buffer + cyclone week protection |
| Hustlr technology fee | 8% of pool | Trigger engine + fraud detection + Flutter app |
| Insurer underwriting margin | 7% of pool | ICICI Lombard / HDFC ERGO profit |
| Reinsurance premium | 2% of pool | Catastrophic event transfer (>4× weekly pool) |
| Guidewire licensing | 3% of pool | PolicyCenter + ClaimCenter + BillingCenter |
| Daily worker cap | ₹150/day | Per-worker exposure limit |
| Weekly worker cap | ₹500/week | Cyclone week protection |
| Geographic concentration | Hard 25% cap per city | Correlated loss prevention |

**At 10,000 workers × ₹49 avg premium = ₹4,90,000/week pool:**

| Allocation | % | Weekly (₹) |
|---|---|---|
| Claims paid out | 65% | ₹3,18,500 |
| Reserve fund | 15% | ₹73,500 |
| Hustlr technology fee | 8% | ₹39,200 |
| Insurer underwriting margin | 7% | ₹34,300 |
| Reinsurance premium | 2% | ₹9,800 |
| Guidewire licensing | 3% | ₹14,700 |
| **Total** | **100%** | **₹4,90,000** |

**Why this works:** Every rupee is accounted for. Guidewire can see their licensing fee explicitly. The insurer sees their margin. Hustlr's technology fee is sustainable at scale. The reserve accumulates weekly as a catastrophic buffer — a Cyclone Michaung-level event triggering the reinsurance clause transfers excess loss beyond 4× pool (₹19,60,000) to the licensed insurer's reinsurance arrangement.

### Projected Financials — Chennai Pilot (10,000 Workers)

| Metric | Value |
|---|---|
| Target workers | 10,000 |
| Average weekly premium (blended) | ₹49 |
| Weekly premium pool | ₹4,90,000 |
| Claims paid out (65%) | ₹3,18,500 |
| Reserve fund (15%) | ₹73,500 |
| Hustlr technology fee (8%) | ₹39,200 |
| Insurer underwriting margin (7%) | ₹34,300 |
| Reinsurance premium (2%) | ₹9,800 |
| Guidewire licensing (3%) | ₹14,700 |
| Loss ratio target | < 0.65 |
| Estimated real loss ratio | ~55–62% |
| Reinsurance trigger | ₹19,60,000 (4× pool) |
| Automated claims cost | ₹0 |
| Manual claims cost | ~₹200 per event |
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

## 🎬 Phase 2 Deliverables

<div align="center">
  <a href="https://youtu.be/nD2snI4Tnu8?si=eS5sztT0aibvxodI">
    <img src="https://img.shields.io/badge/Phase_1_Demo_Video-282828?style=flat-square&logo=youtube&logoColor=white" alt="Phase 1 Video"/>
  </a>
  &nbsp;&nbsp;
  <a href="YOUR_PHASE2_VIDEO_LINK_HERE">
    <img src="https://img.shields.io/badge/Phase_2_Demo_Video-FF0000?style=flat-square&logo=youtube&logoColor=white" alt="Phase 2 Video"/>
  </a>
  &nbsp;&nbsp;
  <a href="https://github.com/Dhruvv-16/Hustlr">
    <img src="https://img.shields.io/badge/GitHub_Repo-181717?style=flat-square&logo=github&logoColor=white" alt="GitHub"/>
  </a>
</div>

### What the Phase 2 Demo Video Demonstrates

The 2-minute demo walkthrough covers all four Phase 2 required deliverables:

**1. Registration Process**
- OTP login → platform selection → zone declaration → income baseline → ISS calculation → plan recommendation → policy activation. Full flow under 90 seconds.

**2. Insurance Policy Management**
- Active policy card on dashboard. Policy details screen (tier, add-ons, coverage window). Policy history. Plan upgrade flow (Basic → Standard).

**3. Dynamic Premium Calculation**
- ISS score displayed at onboarding. Tier recommendation shown with reasoning. Add-on toggles with live weekly total update. Premium guardrails in action (2× ceiling, 0.7× floor).

**4. Claims Management**
- Automated trigger demonstration: a simulated rain event fires, claim queued automatically, worker notified with zero action required.
- Manual claim demonstration: worker taps "Report a Disruption" → selects Road Blocked → opens camera with AI reticle overlay → submits evidence → claim ID issued → status tracking screen.
- Fraud engine Abuse Score calculated live. Circuit breaker BCR shown in admin view.
- Payout dispatch: 70% tranche confirmed to mock UPI, 30% tranche scheduled.

### Executable Source Code

All source code submitted in the GitHub repository covers:

| Module | Location |
|---|---|
| Flutter app (all screens) | `lib/features/` |
| Auth + Onboarding | `lib/features/auth/` |
| Dashboard | `lib/features/dashboard/` |
| Policy Management | `lib/features/policy/` |
| Claims (automated + manual) | `lib/features/claims/` |
| Wallet + Ledger | `lib/features/wallet/` |
| BLoC State Management | `lib/blocs/` |
| Backend Micro-Services | `hustlr-backend/src/services/` |
| Data Trust Engine | `hustlr-backend/src/services/data_trust.js` |
| Fraud Engine | `hustlr-backend/src/services/fraud_engine.js` |
| Circuit Breaker | `hustlr-backend/src/services/circuit_breaker.js` |
| Payout Dispatch | `hustlr-backend/src/services/payout_service.js` |
| Supabase DB Triggers | `hustlr-backend/db/triggers.sql` |
| API Resilience Wrapper | `hustlr-backend/src/services/api_wrapper.js` |

---

*Hustlr — Because every minute you can't deliver is a minute your income disappears.*
