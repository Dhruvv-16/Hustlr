<div align="center">
  <h1>⚡ Hustlr</h1>
  <h3>Real-Time Income Protection Engine for India's Gig Delivery Workers</h3>

  <a href="https://youtu.be/nD2snI4Tnu8?si=eS5sztT0aibvxodI">
    <img src="https://img.shields.io/badge/Phase_1_Demo_Video-FF0000?style=for-the-badge&logo=youtube&logoColor=white" alt="Phase 1 Video"/>
  </a>
  &nbsp;
  <a href="https://youtu.be/uEdGR915H-w">
    <img src="https://img.shields.io/badge/Phase_2_Demo_Video-FF0000?style=for-the-badge&logo=youtube&logoColor=white" alt="Phase 2 Video"/>
  </a>
  &nbsp;
  <a href="https://github.com/Dhruvv-16/Hustlr">
    <img src="https://img.shields.io/badge/GitHub_Repository-181717?style=for-the-badge&logo=github&logoColor=white" alt="GitHub Repo"/>
  </a>
  <br><br>
  <strong>🏆 Guidewire DEVTrails 2026 — Phase 2 Submission</strong><br>
  <strong>👥 Team:</strong> Code Crafters &nbsp;|&nbsp; <strong>🎯 Persona:</strong> Q-Commerce Delivery Partners (Zepto)
</div>

---

## 🎬 Judge's Quick-Start Demo Guide

> **This section is for hackathon judges.** Follow this exact flow to experience the full Hustlr demo in under 3 minutes.

### Step 1 — Install the App

```bash
# Option A: Install the pre-built APK (Android only — recommended for full demo)
# Download Hustlr-demo.apk from the Releases tab
# On your Android device: Settings → Security → Allow unknown sources → Install

# Option B: Build from source
git clone https://github.com/Dhruvv-16/Hustlr
cd Hustlr
flutter pub get
flutter run                    # connect Android device first
flutter run -d chrome          # Web browser (sensor features limited)
```

### Step 2 — Onboard as a Delivery Partner

1. Open the app → tap **"Get Started"** on the welcome screen
2. Enter any name (e.g. `Karthik Shetty`) — it will be auto-capitalised
3. Enter any 10-digit phone number
4. Select **Zone** — pick any available Chennai zone (e.g. `Anna Nagar`)
5. Select **Platform** → `Zepto`
6. On the plan selection screen → choose **Standard Shield — ₹49/week**
7. Dashboard loads with your active policy card showing `Standard Shield · ₹49/week`

> ℹ️ The wallet starts at **₹0**. The ₹49 premium deduction is visible in "Recent Activity" below the balance.

### Step 3 — Trigger a Live Disruption (Demo Mode)

> ⚡ **This is the core demo flow — shows the full parametric insurance pipeline end-to-end.**

1. On the **Dashboard**, tap your **profile avatar** (top-right, green-bordered circle)
2. On the Profile screen, scroll down to find **"Demo Controls"** → tap it
3. A bottom sheet appears with 3 trigger buttons:

| Button | What it simulates | Payout amount |
|--------|-------------------|---------------|
| 🌧️ **Trigger Rain Disruption** | IMD confirms 67mm rainfall in your zone | ₹120 |
| 📵 **Trigger Platform Downtime** | Zepto order failure rate exceeds 60% | ₹140 |
| 🌡️ **Trigger Extreme Heat** | IMD confirms 43°C sustained in zone | ₹130 |

4. Tap **"Trigger Rain Disruption"** — a snackbar confirms the detection
5. Navigate to **Claims** tab → see a new claim card marked `PENDING`
6. Watch it auto-update to `APPROVED` after ~3 seconds ✅
7. Navigate to **Wallet** tab → balance now shows the payout credited
8. Tap **"Withdraw to UPI"** → enter `demo@ybl` → tap **"Initiate Transfer →"**
9. See the 2-second processing animation, then the **Transfer Initiated!** success screen

> ✅ **The demo state persists.** Trigger multiple events, switch screens, close and reopen the app — the claims and wallet balance will still be there. Use **Reset Demo** to start fresh.

### Step 4 — Explore the App Screens

| Screen | What you'll see |
|--------|----------------|
| **Dashboard** | Active plan card (Standard Shield · ₹49), zone disruption alerts, rain prediction nudge |
| **Claims** | All triggered parametric claims with PENDING → APPROVED status, full audit trail |
| **Wallet** | Payout balance, Smart Savings metric, UPI withdrawal flow, transaction history |
| **Policy** | Plan comparison (Basic → Full Shield), shadow policy feature, premium breakdown |
| **My Protection Analytics** | Disruption bar chart (Mon–Sun), payout history, active plan summary |
| **Support → Live Support** | AI chat — responds to 11 insurance topics with Hustlr-specific answers |
| **Support → FAQs** | Parametric insurance explained in worker-friendly language |

### Step 5 — Live Support Chat Demo

| Chip | Question sent | AI response covers |
|------|--------------|-------------------|
| 🧾 Check my claim | "What is the status of my claim?" | Auto-processing, no filing needed, 2hr payout |
| 💧 Rain payout | "How does the rain payout work?" | IMD 64.5mm threshold, 70/30 tranche split |
| 📍 My zone | "Tell me about my zone coverage." | Zone-specific IMD/CPCB sensor validation |
| ₹ My premium | "Why is my premium ₹49?" | Subsidised entry pricing, actuarial basis |
| 💰 Withdraw | "How do I withdraw my payout balance to UPI?" | Razorpay UPI, 2hr settlement |
| 🛡️ Upgrade plan | "What does Full Shield cover?" | All 9 triggers + compound acceleration |

---

## ✅ Phase 2 Highlights — What's Live

| Area | What's Implemented |
|------|--------------------|
| **Parametric Engine** | 5 automated triggers live (Rain, Heat, AQI, Platform Downtime, Bandh) — real IMD/CPCB/NewsAPI data |
| **Mobile App** | Flutter app with full onboarding, dashboard, claims, wallet/UPI withdrawal, policy management, live support chat |
| **Backend** | Node.js + Supabase — policy creation, premium billing, payout dispatch, circuit breaker, fraud scoring |
| **ML Models** | ISS risk scoring, NLP disruption scraper, fraud detection (7-layer), zone depth scoring, connectivity anomaly detection |
| **Demo Mode** | Offline parametric trigger simulation with persistent claim + wallet state across restarts |
| **Live Support** | AI chat agent responding to 11 insurance topics with Hustlr-specific parametric answers |
| **Guidewire Integration** | PolicyCenter + ClaimCenter + BillingCenter API integration scaffolded and documented |

---

## 🧭 TL;DR

**Who:** Q-commerce delivery riders (Zepto) — 2–3 km radius, one dark store, zero income safety net.

**Problem:** One flooded street eliminates their entire working zone. No insurance product covers this. 80+ disruption days a year go uncompensated.

**What Hustlr does:** Monitors 9 real-time disruption triggers. When one fires and the rider is on shift — a fixed payout hits their UPI automatically. No claim filed. No adjuster. Under 2 hours.

**How it's built:** Flutter app · Node.js + Supabase backend · 7 AI/ML models · 7-layer fraud engine · Zone depth scoring · Regional behavioral intelligence · Full Guidewire integration (PolicyCenter + ClaimCenter + BillingCenter) · BLoC state management · Modular micro-services backend.

**Numbers:** ₹35–₹79/week · Tier-locked caps · 6–7× consistent multiplier across all plans · ₹0 infrastructure cost · 10,000-worker Chennai pilot · 5 live automated triggers · 70/30 tranche payout · 4-tier Data Trust Engine · BCR Circuit Breaker · Hard MPL ceiling — zero exceptions.

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

Workers are registered on a **single primary platform only**, in compliance with Zepto's partner exclusivity agreement.

### Why Q-Commerce?

| Factor | Q-Commerce (Zepto) | Food (Zomato/Swiggy) | E-Commerce (Amazon/Flipkart) |
|--------|---------------------------|----------------------|------------------------------|
| Delivery frequency | 15–25 orders/day | 8–15 orders/day | 3–8 orders/day |
| Hyperlocal sensitivity | Extreme (dark store zones) | High | Moderate |
| Weather vulnerability | Critical (monsoon paralysis) | High | Low–Medium |
| Worker density per zone | Very high (cluster-based) | Medium | Spread out |
| Fraud surface area | High (zone-based clustering) | Medium | Low |

### Persona Profile: "Karthik, 24, Zepto Partner, Adyar Dark Store Zone, Chennai"

| Attribute | Value |
|---|---|
| Platform | Zepto (single platform — partner agreement compliant) |
| Weekly earnings | ₹4,200 (~₹600/day, ~₹60/hr over a 10-hr shift) |
| Shift window | 8 AM – 10 PM |
| Delivery radius | 2–3 km from Adyar dark store — zone loss = total income loss |
| Device | Android budget phone (~₹10,000) |
| Savings buffer | 2–3 days of income at most |
| Annual disruption exposure | ~80 rain days · loses ₹400–₹600 per heavy rain day |

---

## ⚡ How Hustlr Works — 15-Second View

```
1. Rain detected in Karthik's zone    →  IMD + OpenWeatherMap confirm threshold
2. Data Trust Engine validates         →  Combined source trust 0.85 — exceeds 0.75 threshold
3. Shift window check passes           →  disruption falls within Karthik's working hours
4. Zone depth score calculated         →  confirms Karthik was genuinely deep in zone, not at boundary
5. Device integrity verified           →  Play Integrity API confirms no GPS spoofing app active
6. Fraud check in < 2 seconds          →  FRS score computed across 7 independent signal layers
7. Circuit Breaker confirms pool OK    →  BCR at 44% — well below 85% ceiling
8. 70% tranche credited within 2 hrs  →  ₹84 to UPI for urgent expenses
9. 30% safety tranche Sunday night     →  ₹36 after full-week fraud pattern review
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
| Lost income during severe traffic congestion (Full Shield) | Events with no corroborating data source |

---

## 🏢 Insurance Partner Model

| Role | Entity |
|---|---|
| **Risk Underwriter** | Licensed insurer — ICICI Lombard / HDFC ERGO |
| **Trigger + Intelligence Engine** | Hustlr |
| **Policy Administration** | Guidewire PolicyCenter API |
| **Claims Automation** | Guidewire ClaimCenter API |
| **Premium Billing** | Guidewire BillingCenter API |
| **Distribution — Phase 1 (B2C)** | Direct — Hustlr mobile app via WhatsApp groups + referral |
| **Distribution — Phase 2 (B2B2C)** | Zepto platform integration + insurer white-label |

### Why B2C First

Hustlr launches **direct to workers**, not as enterprise infrastructure from day one. No insurer or platform will license an unproven parametric engine. Hustlr needs 6–12 months of real claims data — actual loss ratios, real fraud rates, genuine disruption patterns — before any B2B conversation is credible.

The B2C phase is not a pivot or a fallback. It is the **data acquisition strategy** that makes the B2B2C pitch possible. A demo with 10,000 workers, a 61% loss ratio, and a 3.2% fraud rate is worth 100× more than a slide deck to an insurer CTO.

---

## ⚙️ Guidewire Integration

### PolicyCenter
- Weekly policy creation every Monday via PolicyCenter API
- ISS score + city risk profile passed as risk attributes for premium computation
- Policy status synced back to Hustlr in real time

### ClaimCenter
- On parametric trigger: Hustlr pushes a structured, pre-validated claim payload
- Fraud Risk Score attached — ClaimCenter routes CLEAN to auto-approval, FLAGGED to human queue
- Zero-touch for weather/bandh/internet events. Structured review for manual claim types.

### BillingCenter
- Weekly premium deduction via BillingCenter direct debit scheduling
- Payout disbursement coordinated through BillingCenter's payment gateway
- Worker wallet reconciliation synced weekly

### Guidewire Marketplace
- Hustlr packaged as a Marketplace integration — any insurer on PolicyCenter/ClaimCenter can onboard Hustlr's parametric trigger engine as a configurable product extension

### B2B2C Distribution Channel (Phase 2+)
After proving the model B2C, Hustlr embeds directly inside the Zepto partner app. Zepto pays a per-worker monthly licensing fee. The insurer underwrites the risk. Guidewire collects a technology licensing fee from the insurer.

**Why platforms pay for this:** Reduces worker churn during bad weather · differentiates Zepto in recruiting · fulfills ESG mandate.

---

## 📊 Parametric Logic — Core Principle

Hustlr does **not** calculate actual income loss. No investigation needed for automated triggers.

- A measurable disruption index is monitored in real time
- When it crosses a threshold AND falls within the worker's shift window → payout fires
- Payout = fixed rate per trigger type × verified disruption hours, always capped by plan tier

```
Example:
  Trigger:          Heavy rain — IMD confirms 72mm, threshold 64.5mm crossed
  Duration:         3 hours above threshold
  Plan:             Standard Shield
  Fixed rate:       ₹40/hr

  Payout = ₹40 × 3 = ₹120  →  within Standard Shield ₹150 daily cap  →  APPROVED
  70% (₹84) credited within 2 hours. 30% (₹36) settled Sunday night.
```

**Why weekly settlement for the 30% tranche:** The fraud engine evaluates the complete week's pattern before the final tranche releases. A worker who triggers 3 events in one week activates the claim velocity signal before the safety tranche moves. Weekly settlement also matches Zepto's weekly partner payment cycle.

**Why 60–70% income replacement, not 100%:** Parametric insurance by design does not fully replace income. Full replacement creates moral hazard. The 60–70% band is the industry standard.

---

## 🚨 Trigger Parameters

### Automated Parametric Triggers

| Trigger | Threshold | Data Source | Hourly Rate | Daily Cap | Min Plan | Freq/yr |
|---|---|---|---|---|---|---|
| Heavy Rain | 64.5–115mm/hr | IMD + OpenWeatherMap | ₹40/hr | ₹120 | All plans | 8× |
| Extreme Rain / Cyclone band | ≥ 115.6mm/hr | IMD + OpenWeatherMap | ₹65/hr | ₹200 | Standard+ | 2× |
| Heat Wave | ≥ 43°C · IMD forecast | IMD | ₹45/hr | ₹130 | All plans | 5× |
| Severe Pollution | AQI ≥ 200 | AQICN / WAQI | ₹35/hr | ₹100 | Standard+ | 3× |
| Platform App Outage | Order failure rate > 60% | Platform API | ₹50/hr | ₹140 | Standard+ | 6× |
| Bandh / Strike / Curfew | NLP confidence ≥ 0.6 + platform OFFLINE | NewsAPI + NLP | ₹55/hr | ₹150 | Standard+ | 3× |
| Heavy Traffic Congestion | Speed ≥ 40% below baseline, ≥ 45 min | Google Maps Traffic API | ₹30/hr | ₹80 | Full Shield | 10× |
| Internet Zone Blackout | Connectivity < 10% for ≥ 30 min | Ookla / TRAI | ₹45/hr | ₹110 | Standard+ | 2× |
| Cyclone Landfall | IMD Category 1–5 · Oct–Dec | IMD | ₹80/hr | ₹250 | **Full Shield only** | 0.4× |

> **The Min Plan column is canonical.** A Basic Shield worker experiencing a cyclone trigger receives only their plan's daily cap (₹100/day) — not the cyclone rate. **The product you are buying at each tier is the cap, not the trigger list.** Cyclone's ₹250/day rate and ₹80/hr rate are accessible only on Full Shield.

### Payout Caps Are Tier-Locked, Not Trigger-Locked

| Plan | Daily Cap | Weekly Cap | Cap Multiplier |
|---|---|---|---|
| Basic Shield | ₹100/day | ₹210/week | 6.0× premium |
| Standard Shield | ₹150/day | ₹340/week | 6.9× premium |
| Full Shield | ₹250/day | ₹500/week | 6.3× premium |

**Why consistent multipliers matter:** All three plans maintain a 6–7× premium-to-cap ratio. This ensures equal exposure per rupee of premium across tiers — the actuarial foundation of a sustainable pool. Previous structures (₹900 Full Shield cap = 11.4× multiplier) were fundamentally broken because the highest-paying plan also carried the highest risk per rupee. The corrected structure normalises this.

**Shift-time payout modifier:**

| Shift window | Rate modifier |
|---|---|
| Peak (9 AM – 6 PM) | 100% of hourly rate |
| Off-peak (6 PM – 10 PM) | 75% of hourly rate |
| Pre-peak (8 AM – 9 AM) | 50% of hourly rate |

### Manual Claim Triggers

| Trigger | What Worker Submits | Cross-Check Sources | SLA |
|---|---|---|---|
| Traffic Accident Blockspot | GPS screenshot + scene photo (EXIF-stamped) + earnings screenshot | Google Maps Traffic API + NewsAPI + order density | 4 hrs |
| Local Road Closure | Same as above | Municipal advisory feed + Maps | 4 hrs |
| Dark Store / Hub Shutdown | Photo of closed hub + Zepto screenshot | Platform API + NLP scraper | 4 hrs |

---

## ⚡ Compound Triggers — Full Shield

Full Shield workers receive compound trigger payouts when two disruptions occur simultaneously.

| Compound Combination | Multiplier | Rule |
|---|---|---|
| Rain + Platform Outage | 100% of both rates | Both triggers active simultaneously |
| Heatwave + AQI | 110% on higher rate | Co-occurring environmental peril |
| Cyclone + Bandh | 120% on cyclone rate | Civil + weather compound |
| Extreme Rain + Blackout | 130% on extreme rain rate | Catastrophic scenario |

### The Hard Ceiling Principle — Cap Acceleration, Not Cap Lifting

**The ₹500 weekly cap on Full Shield is an absolute hard ceiling. There are zero exceptions.**

Compound multipliers increase the **velocity** of the payout, not the limit. During severe compound events, the increased hourly rate allows the worker to max out their ₹500 cap faster — in fewer hours of disruption — providing immediate peak financial relief without breaking the pool's Maximum Probable Loss (MPL) constraints.

```
Example — Extreme Rain + Blackout (130% multiplier):

  Base Rate (Extreme Rain):      ₹65/hr
  Compound Rate (130%):          ₹84.5/hr

  Old model (cap lift — REMOVED):
    Worker gets ₹84.5/hr until ₹650. Actuary cannot bound MPL. ❌

  New model (cap acceleration):
    Worker gets ₹84.5/hr until ₹500. Cap reached in ~6 hours
    instead of ~8 hours. MPL is mathematically locked. ✅
```

**Why this is better for workers:** "When the worst disasters hit, Hustlr pays you faster. You get your full ₹500 weekly safety net in just a few hours." The value proposition is speed of relief, not a higher ceiling.

**Why this is better for the insurer:** The absolute maximum exposure per Full Shield worker is strictly ₹500. No catastrophic event can push it higher. Reinsurers can price this as a hard MPL with zero ambiguity.

**Compound trigger access:** Full Shield only. Basic and Standard Shield pay for the worst single trigger only — not compound rates.

**Claim-Free Cashback (Full Shield):** Workers on Full Shield who complete 4 consecutive weeks without a payout receive 10% of premiums returned as wallet credit. BCR must remain healthy (below 0.70) for cashback to disburse.

---

## 🛡️ Anti-Gaming Rules

- **Minimum duration:** 45 continuous minutes above threshold before trigger activates
- **Cooling period:** Same disruption type cannot trigger again in same zone within 24 hours
- **Shift intersection:** Disruption must overlap worker's registered shift by minimum 2 hours
- **One event per week per type** for Basic and Standard Shield plans
- **Pro-rata for mid-week activation:** Worker activating Thursday receives payout weighted by days active
- **Post-purchase coverage only:** Disruptions beginning before policy activation are never covered
- **Quarterly commitment:** Plans and add-ons are quarterly (13-week) commitments, not weekly toggles

### Add-On Adverse Selection Controls

Add-ons are **quarterly commitments**, not weekly purchases. A worker adding Cyclone cover pays +₹20/week for the full 13-week quarter. Add-ons **cannot be activated** within:
- **72 hours** of an IMD orange or red alert for that trigger type
- **48 hours** of a known civil event (scheduled election, published bandh notice)

This eliminates the core adverse selection loop — workers must commit before they know a disruption is coming, not after.

**Add-on tier-locking:**

| Add-On | Minimum Plan Required |
|---|---|
| Election Day | All plans |
| App Downtime | Basic Shield (included in Standard+) |
| Internet Blackout | Standard Shield minimum |
| Curfew & Strike | Standard Shield minimum |
| Accident Blockspot | Standard Shield minimum |
| Heavy Traffic Congestion | Standard Shield minimum |
| Cyclone | **Full Shield only** |

Workers cannot purchase the Cyclone add-on on a Basic or Standard plan. Even if they could, the payout would be capped at their plan's weekly cap. The tier-lock exists for system integrity.

### Threshold Obfuscation + Dynamic Micro-Variation

Exact trigger thresholds are never published. The actual trigger threshold varies by ±3mm (rain) or ±0.5°C (heat) each week using a seeded random value known only to the system. Workers can never predict the exact threshold for their account that week.

---

## 📱 Manual Claim Filing — UX Flow

**Step 1 — Select Disruption Type**
```
🚧  Road Blocked / Accident
🏪  Dark Store / Hub Closed
🌐  Internet Outage (zone-level)
📦  Other Delivery Blockage
```

**Step 2 — Capture Evidence (EXIF-stamped, live camera only — no gallery uploads)**
```
Road Blocked   →  1 photo (GPS-stamped at capture)
Hub Closed     →  1 photo + Zepto screenshot (zero orders)
Internet       →  App auto-reads signal strength — no photo required
Other          →  1 photo + description (max 100 chars)
```

**Step 3 — Submission & Tracking**
```
Within 4 hours:
  → AUTO-APPROVED: "₹X credited to your wallet"
  → NEED MORE INFO: "Tap here to add one more photo"
  → DECLINED + EXPLANATION: "Here's why, and how to appeal"
```

---

## 🌐 Internet Zone Blackout — Trigger Architecture

```
Signal 1 — Ookla: Zone avg download speed < 2 Mbps for 20 min  →  degraded flag
Signal 2 — Device crowd-reporting: ≥ 30% of active users report < 1 bar  →  cluster flag
Signal 3 — TRAI outage registry: Any ISP/tower outage logged  →  authoritative flag

Dual-confirmation rule:
  Signal 1 + Signal 2  →  AUTO_TRIGGER
  Signal 3 alone        →  AUTO_TRIGGER
  Signal 1 alone        →  HOLD for 20-minute reconfirmation
```

**Fraud resistance:** Faking connectivity loss requires active data transmission — which is self-contradictory. This is one of Hustlr's most inherently fraud-resistant triggers.

---

## 🚧 Accident Blockspot — Trigger Architecture

```
Google Maps Traffic API:
  Route speed < 5 km/h on major corridor for ≥ 30 minutes  →  gridlock flag
  Cross-checked: NewsAPI NLP "accident", "collision", "road blocked" in zone
  Worker tap-to-confirm + 1 photo
  Hustlr cross-checks: GPS on corridor? Zero orders? Tier 1 hotspot?
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
Step 1 — Build historical baseline per corridor per 30-min time slot
Step 2 — Current speed < (baseline − 40%) sustained ≥ 45 min  →  severe flag
Step 3 — Order failure rate in affected zone > 35%  →  confirmed
All three conditions must be met simultaneously → AUTO_TRIGGER
```

---

## 📋 Real Scenario Simulations

### Scenario A — Chennai November Rain

```
IMD data:     72mm rainfall — threshold crossed for 3 hours
Plan:         Standard Shield
Payout:       ₹40/hr × 3 hrs = ₹120  (within ₹150 daily cap)

Timeline:
  11:00 AM  →  IMD threshold crossed, all checks pass
  11:02 AM  →  Claim logged PENDING — worker notified
  1:02 PM   →  70% tranche (₹84) released to UPI within 2-hour Guidewire mandate
  Sunday    →  30% safety tranche (₹36) released after full-week pattern review
```

### Scenario B — Shadow Policy Activation

```
Karthik has no active policy this week.
Rain disruption hits Adyar zone Thursday.
System silently calculates: if Karthik had Standard Shield → ₹120 payout.
Accumulated over 2 weeks: ₹680 in missed payouts.

Wednesday notification:
  "You missed ₹680 in payouts this fortnight.
   Activate Standard Shield now — ₹49/week.
   Coverage starts Monday — quarterly commitment."
```

### Scenario C — Predictive Activation

```
Karthik is already on Standard Shield.
Wednesday: 78% probability of IMD Very Heavy Rain Friday.
Notification:
  "Heavy rain expected Friday in your zone.
   You're covered — Standard Shield active.
   Estimated payout if threshold crossed: up to ₹150."

For uninsured workers:
  "Heavy rain expected Friday. Standard Shield would protect up to ₹150.
   Coverage starts next Monday — activate quarterly plan now."
Note: Uninsured workers cannot activate for Friday's event.
Quarterly commitment means coverage starts Monday.
```

### Scenario D — Platform App Outage

```
Zepto status page: "operational"
Hustlr detects: order_failure_rate = 78%  →  threshold 60% crossed
Workers on Standard Shield receive auto-claim for outage duration.
Order failure rate overrides status API — reflects ground reality.
```

### Scenario E — Cyclone (Full Shield — Cap Acceleration)

```
Cyclone + Blackout compound trigger fires.
130% multiplier on Extreme Rain rate: ₹65/hr × 1.30 = ₹84.5/hr

Without compound (base rate):  Worker reaches ₹500 cap in ~7.7 hours
With compound (130% rate):     Worker reaches ₹500 cap in ~5.9 hours

MPL per Full Shield worker: ₹500. Unchanged. Zero exceptions.
Worker receives full ₹500 faster — "Instant Relief" during worst events.
```

---

## 🛡️ Adversarial Defense & Anti-Spoofing Strategy

### Why GPS Spoofing Fails Against Hustlr

| Signal Layer | What It Measures | What Spoofing Looks Like |
|---|---|---|
| GPS coordinates | Claimed location | Too perfect — zero statistical jitter |
| Cell tower triangulation | Tower the device is connected to | Home tower ID doesn't match flood zone |
| Wi-Fi fingerprint | SSIDs visible to device | Known home SSID present = flagged |
| IP geolocation (MaxMind) | ISP + approximate location | Home broadband IP ≠ claimed outdoor zone |
| Accelerometer / motion | Physical movement patterns | Stationary couch ≠ stranded outdoor worker |
| Battery charging state | Charging = plugged in at home | Charging during claimed outdoor disruption |
| Barometer / altitude | Device elevation | Ground-level flood claim from 12th floor |

**Layer 0 — Device Integrity Check (before any GPS is trusted):**

```
Play Integrity API: device not rooted, developer mode OFF, app not tampered
isMockLocation flag: if true → GPS is software-generated → auto-reject
USB debugging enabled → +20 to fraud score

Rule: Any claim from a device failing Play Integrity API
      is auto-rejected before fraud scoring begins.
```

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

**Layers 2–6:** Behavioral baseline · News corroboration (0.25 weight) · Behavioral fingerprinting · Ring detection (Poisson + DBSCAN + Isolation Forest) · Internet blackout self-validation.

**FPS Decision Engine:**

| Tier | FPS Range | Action |
|---|---|---|
| GREEN | 0.0 – 0.30 | Auto-approve — payout within 2 hours |
| YELLOW | 0.31 – 0.60 | Soft hold — verifying, 2-hour window |
| RED | 0.61 – 1.00 | Human review — provisional ₹100–300 credit released immediately |

**Zone Context Override:** During officially declared IMD/NDMA disaster advisories, all FPS thresholds in that zone are elevated by 15 points. Genuine stranded workers in cyclone zones are not subjected to fraud scrutiny during the worst events.

---

## 📍 Zone Depth Scoring — Anti-Boundary Gaming

```
Zone divided into 3 concentric rings around dark store:

  Outer ring    (0–500m inside boundary)    depth score: 0.00–0.20
  Middle ring   (500m–2km from boundary)    depth score: 0.21–0.60
  Core zone     (2km+ from any boundary)    depth score: 0.61–1.00

Payout multiplier:
  Score 0.00–0.20  →  0.0   (no payout — boundary gaming detected)
  Score 0.21–0.40  →  0.30
  Score 0.41–0.60  →  0.60
  Score 0.61–0.80  →  0.85
  Score 0.81–1.00  →  1.00  (full payout)
```

A worker who runs to the zone edge the moment rain starts has a depth score near zero. There is no single coordinate to stand on.

---

## 🤖 AI/ML Architecture

### Model 1 — Income Stability Score (ISS)

ISS is never shown to workers. It drives tier recommendations only.

```
ISS 0–39   →  Recommend Full Shield (₹79/wk)
ISS 40–80  →  Recommend Standard Shield (₹49/wk)
ISS 81–100 →  Recommend Basic Shield (₹35/wk)
```

### Model 2 — Fraud Detection Engine (7 layers, < 2 seconds)
### Model 3 — NLP Disruption Scraper (LLM preprocessing only — decisions are deterministic)
### Model 4 — Internet Connectivity Anomaly Detector
### Model 5 — Accident Blockspot Classifier
### Model 6 — Zone Depth Scoring (PostGIS)
### Model 7 — Facebook Prophet Forecasting (Phase 3)

---

## 🌏 Regional Behavioral Intelligence Layer

| City | Behavioral Risk Index | Key Characteristic |
|---|---|---|
| Chennai | 0.65 | High financial literacy, organized communities, incentive-aware |
| Bengaluru | 0.55 | Tech-adjacent workforce, individual optimization |
| Mumbai | 0.50 | Volume-focused, less community coordination |
| Delhi | 0.45 | Diverse worker base, lower coordination density |

**Ethical boundary:** Regional intelligence adjusts system-level thresholds and fraud weights. It never denies an individual worker's claim based on their city alone.

---

## 🚀 Innovation Differentiators

1. **Shadow Policy** — Uninsured workers tracked silently. "You missed ₹680 last fortnight." Acquisition cost: ₹0.
2. **Predictive Nudge** — Wednesday 72-hour forecast. Covered workers notified they're protected; uninsured workers prompted for next quarter.
3. **Play Integrity API as Layer 0** — Blocks 90%+ of GPS spoofing at entry point.
4. **Zone Depth Scoring** — Continuous presence scoring replaces binary zone membership.
5. **Regional Behavioral Intelligence** — Chennai-specific fraud calibration.
6. **Internet Blackout as First-Class Trigger** — No other parametric product in India covers this.
7. **Insurer Profitability Simulator** — Real-time catastrophe exposure modelling for insurer admin.
8. **Data Trust Engine** — 4-tier credibility scoring. GPS alone (0.20–0.30) can never trigger a payout.
9. **Economic Circuit Breaker** — BCR monitor with automatic enrollment halt.
10. **70/30 Tranche Payout** — 70% within 2 hours. 30% held for full-week fraud review.
11. **API Resilience Wrapper** — 3-strike degraded mode + 5-min cache fallback.
12. **Quarterly Commitment Model** — Eliminates adverse selection. Workers commit for 13 weeks, not just rainy ones.
13. **Cap Acceleration (not Cap Lifting)** — Hard MPL ceiling enforced. Compound triggers increase payout speed, never the ceiling.

---

## 💰 Weekly Premium Tiers

### Pricing Philosophy — Subsidised Entry, Sustainable at Scale

Hustlr premiums are priced **30–55% below full actuarial cost**. This is a deliberate worker affordability decision, not a modelling error.

**Actuarial pure premiums (Guidewire formula: Trigger Probability × Avg Income Lost × Weekly Exposed Days ÷ Target BCR):**

> Note on "days exposed": The Guidewire formula uses **weekly** exposure days. At 80 rain days/year, weekly exposure = 80 ÷ 52 × disruption set fraction. This is the correct weekly basis — not monthly days, which would overstate exposure by 4.3×.

| Plan | Actuarial Calculation | Pure Premium | With Load | Charged | Subsidy |
|---|---|---|---|---|---|
| Basic Shield | 0.18 × ₹420 × 0.33d/wk ÷ 0.62 | ₹40.2/wk | ₹48/wk (20% load) | ₹35/wk | 27% below cost |
| Standard Shield | 0.27 × ₹420 × 0.50d/wk ÷ 0.63 | ₹90/wk | ₹106/wk (18% load) | ₹49/wk | 54% below cost |
| Full Shield | 0.35 × ₹420 × 0.65d/wk ÷ 0.65 | ₹147/wk | ₹172/wk (17% load) | ₹79/wk | 54% below cost |

**The subsidy is funded by three structural advantages:**
1. **B2B2C platform licensing revenue** — Zepto pays ₹150/worker/month in Phase 2 (equivalent to ₹37/week), closing most of the actuarial gap
2. **₹0 claims processing cost** vs ₹150–300 industry average
3. **Reinsurance absorption** of catastrophic tail events beyond 4× weekly pool

**The remaining gap (₹86 effective revenue vs ₹106 actuarial cost) is closed by structural risk reduction:**
- 6.0–6.9× cap discipline truncates extreme tail exposure (~18% reduction)
- 7-layer fraud engine reduces fraudulent leakage (~8–10% reduction based on 12-month Chennai IMD simulation)
- Zone depth scoring and shift filters eliminate boundary gaming

**BCR guardrails are maintained regardless of subsidised pricing.** The circuit breaker trips at 85% BCR regardless of what the actuarial premium would be.

### Plan Tiers

| Plan | Weekly Premium | Daily Cap | Weekly Cap | Core Coverage | Target BCR | Multiplier |
|---|---|---|---|---|---|---|
| **Basic Shield** | ₹35/wk | ₹100/day | ₹210/week | Rain + extreme heat | 0.62 | 6.0× |
| **Standard Shield** ⭐ | ₹49/wk | ₹150/day | ₹340/week | Rain, heat, AQI, outage, bandh | 0.63 | 6.9× |
| **Full Shield** 🔥 | ₹79/wk | ₹250/day | ₹500/week | All triggers + compound acceleration + 10% cashback | 0.65 | 6.3× |

### Premium Bounds — Actuarial Guardrails

| Bound | Multiplier | Example |
|---|---|---|
| Maximum premium | 2.0× base tier rate | ₹98/week (Standard) |
| Minimum premium | 0.7× base tier rate | ₹34/week (Standard) |
| Week-over-week change cap | ±20% max | ₹49 → ₹39–₹59 max |

**Loss ratio guardrails (automated):**
- BCR > 0.80 in any 4-week rolling window → premiums auto-increase 15% + new enrollments pause
- BCR < 0.45 → premiums decrease 10% (fairness obligation)

### Monsoon Season Surcharge

Chennai monsoon season (Oct–Dec) raises rain trigger probability from baseline 12% to 32%. Premiums auto-adjust upward ~22% for policies purchased Oct–Dec vs Jan–Mar.

### Worker Activity Tier Underwriting

| Activity level | Underwriting outcome |
|---|---|
| > 20 active days/month | Standard rate |
| 7–20 active days/month | +8% loading |
| < 7 active delivery days in past 30 days | Declined — per Guidewire minimum activity mandate |

### Add-Ons (Quarterly Commitments — Not Weekly Toggles)

| Add-On | Weekly Cost | Min Plan | Covers |
|---|---|---|---|
| Election Day | +₹8/wk | All plans | Polling day restricted movement |
| App Downtime | +₹10/wk | Basic only | Platform outage >60% failure (included in Standard+) |
| Internet Blackout | +₹18/wk | Standard+ | Zone-level connectivity outage |
| Curfew & Strike | +₹12/wk | Standard+ | Bandh, curfew, Section 144 |
| Accident Blockspot | +₹15/wk | Standard+ | Road blocked on hotspot corridors |
| Heavy Traffic Congestion | +₹15/wk | Standard+ | Speed ≥ 40% below baseline ≥ 45 min |
| Cyclone | +₹20/wk | **Full Shield only** | Cyclone Category 1–5 · Oct–Dec |

**Add-on combination risk:** When cyclone + bandh + blackout add-ons are purchased together, a 10% systemic risk surcharge applies. All three can trigger simultaneously in a disaster event — correlated peril risk is priced accordingly.

---

## 🛠️ Tech Stack

**Frontend:** Flutter (Dart) · flutter_bloc + Provider · flutter_background_geolocation · Hive · Razorpay Flutter SDK · Firebase Cloud Messaging · Play Integrity API

**Backend:** Node.js + Express · Supabase (PostgreSQL + PostGIS) · Supabase Auth · Render · Node-cron · Python spaCy + LLM preprocessing via FastAPI · `data_trust.js` · `fraud_engine.js` · `circuit_breaker.js` · `payout_service.js` · `api_wrapper.js` · `triggers.sql`

**AI/ML:** Python rule engine (ISS) · scikit-learn Isolation Forest (FRS) · PostGIS (zone depth) · Python NLP pipeline · Facebook Prophet (Phase 3)

**Guidewire:** PolicyCenter REST API · ClaimCenter REST API · BillingCenter REST API · Guidewire Marketplace

---

## 🏗 Phase 2: Backend Architecture

### Data Trust Engine (data_trust.js)

| Tier | Source Examples | Trust Range |
|---|---|---|
| Tier 1 — Govt/Official | IMD advisories, NDMA alerts | 0.90 – 1.00 |
| Tier 2 — Third-Party Verified | OpenWeatherMap, AQICN, Platform logs | 0.70 – 0.85 |
| Tier 3 — Community Reports | Crowd-sourced connectivity reports | 0.40 – 0.65 |
| Tier 4 — Device Sensors | GPS coordinates, Accelerometers | 0.20 – 0.30 |

Combined trust must exceed **0.75**. GPS alone (0.20–0.30) cannot trigger a payout.

### Economic Circuit Breaker (circuit_breaker.js)

| BCR Level | System State | Action |
|---|---|---|
| < 65% | Healthy | Normal operations |
| 65–75% | Monitoring | Admin alert only |
| 75–85% | Elevated | Payout rate throttling (soft control) |
| > 85% | Critical | New enrollments halted for that city |
| > 400% pool | Catastrophic | Reinsurance clause activated |

### Payout Dispatch

- **70% Immediate Tranche** — within 2 hours of claim approval (per Guidewire mandate: minutes, not hours)
- **30% Safety Tranche** — held until Sunday 11 PM weekly batch after full-week pattern review

---

## 🧪 MVP Scope — Phase 1 ✅ & Phase 2 ✅

### Phase 1 Complete ✅
Rain trigger · Zone depth scoring · Play Integrity API · NLP bandh detection · ISS scoring · Shadow policy · Predictive nudge · 7-layer FPS fraud engine · Regional behavioral intelligence · Threshold obfuscation · Compound trigger logic · Claim-free cashback design · Guidewire ClaimCenter payload · Manual claim flow · UPI payout

### Phase 2 Complete ✅
Full Flutter app · BLoC state management · Registration + onboarding (< 90 seconds) · Quarterly commitment model enforced · Add-on tier-locking enforced · Add-on 72hr/48hr blackout windows · 5 automated parametric triggers live · Data Trust Engine · Fraud Engine · Economic Circuit Breaker · 70/30 tranche payout (70% within 2 hours) · Supabase DB triggers · API resilience wrapper · Manual claim camera screen · Wallet screen · Shadow policy live · Predictive nudge live · Cap acceleration replacing cap lift

### Phase 3 (Weeks 5–6) — In Progress
- [ ] Isolation Forest fraud model + Poisson timing test
- [ ] Facebook Prophet forecasting model
- [ ] Insurer admin dashboard + profitability simulator
- [ ] Worker Trust Score accumulation logic
- [ ] Claim-free cashback automation
- [ ] Guidewire Marketplace packaging
- [ ] Final 5-min demo video + pitch deck

---

## 💸 Cost Efficiency

**Total infrastructure: ₹0/month** — OpenWeatherMap, IMD, AQICN, MaxMind, OpenCelliD, Ookla, TRAI, Brave Search, NewsAPI, Supabase, Render, Razorpay test mode, Play Integrity API — all on free tiers.

---

## 📊 Business Viability & Financial Model

### Core Principle

Hustlr is not priced as a traditional insurance product. It is a **subsidised parametric protection system** designed to acquire worker data first (B2C phase) and transition to profitability via platform integration (B2B2C phase). This distinction is critical to understanding the model.

### 1. Pricing Reality — Not Actuarially Fair (By Design)

| Plan | Actuarial Premium | Charged | Gap |
|---|---|---|---|
| Basic | ₹48/week | ₹35/week | -27% |
| Standard | ₹106/week | ₹49/week | -54% |
| Full | ₹172/week | ₹79/week | -54% |

This is not a modelling error. It is a deliberate constraint driven by the Guidewire affordability band (₹20–₹50 target range), worker willingness-to-pay ceiling, and the need for rapid adoption in the B2C phase.

### 2. What the Product Actually Sells

Hustlr does not sell trigger access. **It sells income protection capacity (caps).**

Even if a high-value trigger occurs, payout is always limited by plan cap. This prevents trigger exploitation and unbounded exposure.

### 3. Multiplier Discipline — Key Sustainability Mechanism

All plans maintain a 6–7× cap-to-premium ratio (Basic 6.0×, Standard 6.9×, Full 6.3×). Exposure per rupee of premium is consistent. Pool behavior is predictable. Previous structures (₹900 cap = 11.4× multiplier) were unsustainable because the highest-paying plan carried the highest risk per rupee.

### 4. Loss Ratio Reality

**Target BCR (designed):** 65%

**Modelled actual net BCR:** ~36–45% effective payout

This is not a contradiction — it is system design. The gap exists because:
- Fraud engine reduces false claims (~8–10%), based on 12-month simulation of 10,000 workers using Chennai IMD historical data
- Weekly caps truncate extreme tail payouts (~18% reduction from caps alone)
- Shift-time and zone depth filters reduce exposure
- Trigger overlap restrictions limit stacking

**65% is the ceiling the pool is designed to operate below. 36–45% is what the fraud engine and caps achieve in practice.**

At 36–45% effective loss ratio, the insurer retains a 20–25% underwriting margin after reinsurance and operational costs, **making this gig worker segment profitable for a carrier for the first time.**

### 5. Catastrophic Event Behavior

During events like cyclones, loss ratio can spike to 475%+. This is expected in parametric systems. Mitigation:
- Hard MPL cap (₹500 per Full Shield worker — zero exceptions)
- Reinsurance (mandatory — see below)
- Circuit breaker (active self-defense)
- Dynamic payout throttling when BCR > 75%

### 6. The Reinsurance Model

Hustlr does not independently procure reinsurance. Because we are integrated via the Guidewire Marketplace, **our parametric pool is bundled into the underwriter's (e.g., ICICI Lombard) existing catastrophe treaty.** The marginal exposure from a 10,000-worker pilot is negligible relative to the insurer's overall book.

Hustlr's framing: "We do not attempt to absorb catastrophic risk. We cap exposure at the worker level and transfer systemic risk to the insurer's reinsurance layer."

**Cyclone week stress test (10,000 workers, 80% affected):**

| Component | Amount |
|---|---|
| Total adjusted payout (post-caps, post-filters) | ₹24L |
| Weekly pool inflow (B2B2C) | ₹7L |
| Insurer retention (2–3× pool) | ₹15L |
| Reinsurance absorbs excess | ₹9L |
| Hustlr balance sheet exposure | ₹0 |

System survives with reinsurance. Without it — it does not. We do not hide this.

**3-bad-weeks simulation (worst-case month):**

| Week | Event | Adjusted Payout |
|---|---|---|
| Week 1 | Extreme rain 3–4 days | ₹24L |
| Week 2 | Cyclone tail + blackout | ₹27L |
| Week 3 | Heavy rain + outages (circuit breaker throttles) | ₹16L |
| Week 4 | Normal | ₹5L |
| **Total** | | **₹72L** |
| Monthly inflow | | ₹28L |
| Insurer retention (across 3 events) | | ₹30L |
| Reinsurer absorbs | | ₹14L |

The system survives because Hustlr does not retain balance sheet risk. Hustlr's position is unaffected in all scenarios.

### 7. Economic Circuit Breaker — Active Self-Defense

| BCR Level | Action |
|---|---|
| < 65% | Normal |
| 65–75% | Monitoring |
| 75–85% | Payout rate throttling (soft control) |
| > 85% | Enrollment freeze |
| Extreme | Reinsurance trigger |

The system actively prevents collapse, not just measures it.

### 8. B2C → B2B2C Transition Strategy

**Phase 1 — B2C (Months 0–12, Data Acquisition):**
- Direct worker onboarding in Chennai
- Operates as a controlled loss-leader funded by startup capital (B2C subsidy is customer acquisition cost, not insurance pool loss)
- Goal: 10,000 workers, real claims data, proven loss ratio <65%, proven fraud rate <5%

**Phase 2 — B2B2C Revenue Model (Months 12+):**

| Revenue Source | Calculation | Monthly | Annual |
|---|---|---|---|
| Worker Premiums | ₹50 blended × 10,000 workers | ₹21.6L | ₹2.6 Cr |
| Zepto Platform Licensing | ₹150/worker/month | ₹15.0L | ₹1.8 Cr |
| **Total Inflow** | | **₹36.6L** | **₹4.4 Cr** |

**Effective revenue per Standard Shield worker in B2B2C:**
- Worker premium: ₹49/week
- Zepto licensing equivalent: ₹37/week (₹150/month ÷ 4.33)
- **Combined: ₹86/week** vs actuarial ₹106/week
- Remaining ₹20 gap closed by structural risk reduction (caps, fraud, filters)

**Hustlr unit economics (MGA + SaaS layer):**
- 8% of insurance premium pool (insurance infrastructure fee)
- 100% of platform licensing revenue (SaaS, billed directly to Zepto — not part of insurance pool)

| Workers | Hustlr Monthly Revenue |
|---|---|
| 10,000 | ₹4.4L |
| 50,000 | ₹22L |
| 1,00,000 | ₹44L |
| 5,00,000 | ₹2.2 Cr |

This becomes a high-margin infrastructure business, not insurance.

**Why Zepto pays ₹150/month (the ROI case):**
- Replacing a delivery worker costs Zepto ~₹2,000 in onboarding and training
- If Hustlr extends average worker lifetime by just 1 month → **13× ROI on the ₹150 fee**
- Workers covered by Hustlr stay active during borderline weather (they know they're protected) — guaranteeing Zepto fleet uptime during high-demand monsoon hours
- ESG compliance and competitive hiring advantage

**If Zepto says no:** The model remains operational at reduced margins due to caps and circuit breakers. Full profitability requires B2B2C, but the system does not collapse without it in Phase 1.

### 9. Sustainability Conditions — Non-Negotiable

Hustlr is sustainable **only if all five conditions are simultaneously true:**

1. Caps remain strictly enforced (6–7× multiplier discipline)
2. Add-ons remain quarterly commitments with blackout windows
3. Reinsurance is bundled via insurer's existing catastrophe treaty
4. Circuit breaker actively regulates exposure (75–85–extreme tiers)
5. B2B2C transition occurs within 12 months of B2C launch

Remove any one → model requires restructuring. We do not hide this.

### 10. Pool Allocation — Target (B2C Phase)

At 10,000 workers × ₹49 avg premium = ₹4,90,000/week:

| Allocation | % | Weekly (₹) |
|---|---|---|
| Claims paid out (target BCR) | 65% | ₹3,18,500 |
| Reserve fund | 15% | ₹73,500 |
| Hustlr technology fee | 8% | ₹39,200 |
| Insurer underwriting margin | 7% | ₹34,300 |
| Reinsurance premium (pass-through to insurer treaty) | 2% | ₹9,800 |
| Guidewire licensing | 3% | ₹14,700 |
| **Total** | **100%** | **₹4,90,000** |

> **On 65% vs 36.7% claims:** The pool allocation shows 65% as the target BCR ceiling. The projected financials show 36.7% as the modelled actual net loss ratio after fraud controls reduce false claims by 8.8% and weekly caps reduce tail events by 3.2%. These are not contradictory: 65% is the maximum the pool is designed to sustain; 36.7% is what the system's controls achieve in practice.

### 11. Annual Projected Financials — Chennai Pilot

| Metric | Value |
|---|---|
| Annual premium pool | ₹2.4 Crore |
| Gross claims (before controls) | -₹1.2 Cr (48.7%) |
| Fraud prevention savings | +₹21.4L (8.8%) |
| Weekly cap savings | +₹7.8L (3.2%) |
| **Net claims paid** | **-₹89.7L (36.7% actual loss ratio)** |
| Operating costs | -₹61.1L (25.0%) |
| Reserve buffer | -₹19.6L (8.0%) |
| Reinsurance (pass-through) | -₹7.3L (3.0%) |
| Guidewire licensing | -₹7.3L (3.0%) |
| Insurer margin | -₹24.4L (10.0%) |
| **Net profit** | **+₹34.9L (14.3% margin)** |

### 12. 14-Day Monsoon Stress Test

```
10,000 workers × ₹120/day avg payout × 14 days = ₹1.68Cr total payout
Premium pool for that fortnight = ₹9.8L (2 weeks × ₹4.9L)
Deficit: ₹1.58 Crore

Mitigation:
  Monsoon surcharge (22%) pre-funds ₹2.2L
  Reinsurance XL treaty at ₹50L deductible
  Residual reinsurance exposure: ₹1.36 Crore — standard catastrophe XL sizing
```

Reinsurance is structurally required and explicitly designed into the model. Hustlr is a technology layer above a licensed insurer's reinsurance arrangement — not a standalone risk carrier.

### 13. Final Positioning Statement

> "Hustlr is not an insurance company. It is a distribution and underwriting intelligence layer monetized via platform licensing. We do not eliminate risk — we structure it correctly. Caps are hard ceilings. Add-ons are quarterly commitments. Compound multipliers accelerate payouts, never the MPL. Catastrophic tail risk routes to the insurer's reinsurance layer. Hustlr retains zero balance sheet risk in all scenarios."

---

## 🤝 IRDAI Compliance

- Technology partner model — not a licensed insurer
- Policy under partner insurer's IRDAI license
- Triggers rely on IMD — IRDAI-recognized data source
- Payout terms transparent at activation (parametric requirement)
- Microinsurance compliant: ₹35–₹79/week, simplified format
- Within IRDAI Regulatory Sandbox guidelines for parametric products (2019)
- Minimum 7 active delivery days in past 30 days before first cover activates (per Guidewire mandate)

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
  <a href="https://youtu.be/uEdGR915H-w">
    <img src="https://img.shields.io/badge/Phase_2_Demo_Video-FF0000?style=flat-square&logo=youtube&logoColor=white" alt="Phase 2 Video"/>
  </a>
  &nbsp;&nbsp;
  <a href="https://github.com/Dhruvv-16/Hustlr">
    <img src="https://img.shields.io/badge/GitHub_Repo-181717?style=flat-square&logo=github&logoColor=white" alt="GitHub"/>
  </a>
</div>

---

*Hustlr — Because every minute you can't deliver is a minute your income disappears.*
