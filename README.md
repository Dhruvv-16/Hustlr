<div align="center">
  <h1>âš¡ Hustlr</h1>
  <h3>Real-Time Income Protection Engine for India's Gig Delivery Workers</h3>

  <a href="https://youtu.be/nD2snI4Tnu8?si=eS5sztT0aibvxodI">
    <img src="https://img.shields.io/badge/Phase_1_Demo_Video-FF0000?style=for-the-badge&logo=youtube&logoColor=white" alt="Phase 1 Video"/>
  </a>
  &nbsp;
  <a href="YOUR_PHASE2_VIDEO_LINK_HERE">
    <img src="https://img.shields.io/badge/Phase_2_Demo_Video-FF0000?style=for-the-badge&logo=youtube&logoColor=white" alt="Phase 2 Video"/>
  </a>
  &nbsp;
  <a href="https://github.com/Dhruvv-16/Hustlr">
    <img src="https://img.shields.io/badge/GitHub_Repository-181717?style=for-the-badge&logo=github&logoColor=white" alt="GitHub Repo"/>
  </a>
  &nbsp;
  <a href="https://hustlr-ad32.onrender.com/health">
    <img src="https://img.shields.io/badge/Live_API-00C853?style=for-the-badge&logo=render&logoColor=white" alt="Live API"/>
  </a>
  <br><br>
  <strong>ðŸ† Guidewire DEVTrails 2026 â€” Phase 2 Submission</strong><br>
  <strong>ðŸ‘¥ Team:</strong> Code Crafters &nbsp;|&nbsp; <strong>ðŸŽ¯ Persona:</strong> Q-Commerce Delivery Partners (Zepto)
</div>

---

## ðŸ“‹ Table of Contents

1. [Why We Built This](#-why-we-built-this)
2. [TL;DR](#-tldr)
3. [Worker Research â€” The Five Riders](#-worker-research--the-five-riders)
4. [The Problem](#-the-problem)
5. [What Hustlr Is](#-what-hustlr-is)
6. [Chosen Persona: Q-Commerce Delivery Partner](#-chosen-persona-q-commerce-delivery-partner)
7. [How Hustlr Works â€” 15-Second View](#-how-hustlr-works--15-second-view)
8. [What Hustlr Covers](#-what-hustlr-covers)
9. [Insurance Partner Model](#-insurance-partner-model)
10. [Guidewire Integration](#ï¸-guidewire-integration)
11. [Parametric Logic â€” Core Principle](#-parametric-logic--core-principle)
12. [Trigger Parameters](#-trigger-parameters)
13. [Compound Triggers â€” Full Shield](#-compound-triggers--full-shield)
14. [Anti-Gaming Rules](#-anti-gaming-rules)
15. [Manual Claim Filing â€” UX Flow](#-manual-claim-filing--ux-flow)
16. [Internet Zone Blackout â€” Trigger Architecture](#-internet-zone-blackout--trigger-architecture)
17. [Accident Blockspot â€” Trigger Architecture](#-accident-blockspot--trigger-architecture)
18. [Heavy Traffic Congestion â€” Trigger Architecture](#-heavy-traffic-congestion--trigger-architecture)
19. [Real Scenario Simulations](#-real-scenario-simulations)
20. [Adversarial Defense & Anti-Spoofing Strategy](#ï¸-adversarial-defense--anti-spoofing-strategy)
21. [Zone Depth Scoring â€” Anti-Boundary Gaming](#-zone-depth-scoring--anti-boundary-gaming)
22. [AI/ML Architecture](#-aiml-architecture)
23. [Regional Behavioral Intelligence Layer](#-regional-behavioral-intelligence-layer)
24. [Innovation Differentiators](#-innovation-differentiators)
25. [Weekly Premium Tiers](#-weekly-premium-tiers)
26. [City Risk Profiles](#ï¸-city-risk-profiles)
27. [End-to-End Workflow](#-end-to-end-workflow-full)
28. [Parametric Trigger Decision Flow](#-parametric-trigger-decision-flow)
29. [Fraud Detection Decision Flow](#-fraud-detection-decision-flow)
30. [System Reliability â€” Fallback Hierarchy](#-system-reliability--fallback-hierarchy)
31. [Platform Decision â€” Mobile App (Flutter)](#ï¸-platform-decision--mobile-app-flutter)
32. [Tech Stack](#ï¸-tech-stack)
33. [Phase 2 Deliverables & Status](#-6-week-plan)
34. [Judge's Testing Guide](#ï¸-judges-testing-guide)
35. [Business Viability & Financial Model](#-business-viability--financial-model)
36. [IRDAI Compliance](#-irdai-compliance)
37. [Team](#-team)

---

## â¤ï¸ Why We Built This

Chennai has 80+ rain days a year. During Cyclone Michaung in November 2023, we watched every Zepto rider we knew lose 3â€“4 days of income with zero recourse. The existing insurance market â€” accident policies, hospitalization cover â€” protects against events that happen once a decade. Not the disruptions that happen 80 times a year.

We are from Chennai. We know what it means when Velachery floods. After Michaung, the Adyar River overflowed and delivery partners couldn't work for 4 days straight â€” but their rent didn't care. We know workers chase Rapido surge rates the same way they would game any incentive system, because we have talked to them. That isn't fraud; that is rational behavior under financial pressure.

We built Hustlr around that reality, not around a generic gig worker persona built from a marketing report.

**The design decisions that reflect this:**

- We chose Zepto over Zomato because Q-commerce has *tighter* zone lock-in â€” a flooded street eliminates a Zepto rider's entire working zone, not just their efficiency. A Zomato rider has options; a Zepto rider does not.
- We chose zone depth scoring over binary inside/outside zones because we know workers will stand 50 metres inside a boundary during a disruption. That is not covered income loss.
- We chose Chennai as the primary city not because it's the obvious answer â€” it's because our interviews with five real riders gave us data that no other team will have.
- We set the premium cap at â‚¹79/week because one of our interviewees, Ravi, told us directly: *"More than â‚¹80 a week and I can't afford it â€” I'd cancel."*

This is not a generic insurtech product. This is a system designed around five real names, five real incomes, and 80 real disruption days a year.

---

## ðŸ§­ TL;DR

**Who:** Q-commerce delivery riders (Zepto) â€” 2â€“3 km radius, one dark store, zero income safety net.

**Problem:** One flooded street eliminates their entire working zone. No insurance product covers this. 80+ disruption days a year go uncompensated.

**What Hustlr does:** Monitors 9 real-time disruption triggers. When one fires and the rider is on shift â€” a fixed payout hits their UPI automatically. No claim filed. No adjuster. Under 2 minutes.

**How it's built:** Flutter app Â· Node.js + Supabase backend Â· 7 AI/ML models Â· 7-layer fraud engine Â· Zone depth scoring Â· Regional behavioral intelligence Â· Full Guidewire integration (PolicyCenter + ClaimCenter + BillingCenter).

**Numbers:** â‚¹29â€“â‚¹109/week Â· â‚¹150/day payout cap Â· 55â€“65% projected loss ratio Â· â‚¹0 infrastructure cost Â· 10,000-worker Chennai pilot.

> *"When there's a curfew, I can't deliver. When the app crashes, I can't deliver. When a road accident blocks my route, I can't deliver. Those days, I earn zero rupees â€” but my rent doesn't know that."*
> â€” **Karthik, 24, Zepto Q-commerce delivery rider, Chennai**

---

## ðŸ”´ The Problem

India has **7.7 million** gig delivery workers. Q-commerce riders â€” the people delivering groceries in 10 minutes for Zepto â€” face the sharpest version of this problem. They operate within a strict 2â€“3 km radius of a single dark store. They earn â‚¹4,000â€“â‚¹6,000 per week with no paid leave, no sick days, and no safety net. One flooded street eliminates their entire working zone. A dark store going offline wipes out a full shift. Chennai alone sees **~80 rain days per year** â€” on each one, a rider loses â‚¹400â€“â‚¹600. Cyclone Michaung wiped out 3â€“4 days of income per worker with zero recourse.

Every existing insurance product covers accidents, hospitalization, and death â€” events that happen rarely. Not one covers the income disruption that happens 80+ days a year.

Hustlr fixes the right problem.

---

## ðŸ‘· Worker Research â€” The Five Riders

Before writing a single line of code, we interviewed five Zepto delivery partners in Chennai. These are not personas â€” they are real workers with real numbers. Their data drove every actuarial decision in this system.

| Persona | Zone | Weekly Earnings | Biggest Fear | Key Quote |
|---|---|---|---|---|
| **Karthik, 24** | Adyar dark store | â‚¹4,200/wk | Zone flooding | *"When there's a curfew, I can't deliver. Those days, I earn zero â€” but my rent doesn't know that."* |
| **Ravi, 31** | Velachery dark store | â‚¹5,100/wk | Platform app crashes | *"More than â‚¹80 a week and I can't afford it. I'd just cancel."* |
| **Muthu, 28** | Tambaram dark store | â‚¹3,800/wk | Cyclone season | *"Michaung took 4 days from me. I had to borrow money for rice."* |
| **Santhosh, 26** | OMR corridor | â‚¹4,600/wk | GST Road accidents | *"One truck accident on GST Road blocks me for 2 hours. It happens every week."* |
| **Priya, 33** | T. Nagar dark store | â‚¹4,000/wk | Internet outages | *"When the zone goes dark I can't take orders. But I still paid for petrol to come in."* |

### What This Research Drove

| Research Finding | Design Decision |
|---|---|
| Ravi's â‚¹80 hard limit | Premium ceiling at â‚¹79/week for Full Shield |
| Karthik earns â‚¹600/day in peak shifts | Daily payout cap set at â‚¹150 (25% â€” moral hazard prevention) |
| Santhosh cited weekly GST Road blocks | Accident blockspot as first-class manual trigger; Chennai hotspot map seeded |
| Muthu lost 4 days to Michaung (no recourse) | Weekly payout cap at â‚¹500 â€” 4-day cyclone protection built in |
| Priya's internet outage cost her show-up fuel | Internet zone blackout as a covered trigger â€” not treated as platform failure |
| All five use UPI exclusively | No card/bank integration â€” all payouts to UPI wallet directly |
| All five operate on budget Android (~â‚¹10k) | Flutter UI designed for one-thumb operation; no complex flows |

> These interviews are not summarized from secondary research. We sat with these workers. The premium cap, the payout structure, the trigger list â€” every number in this system has a name behind it.

---

## ðŸ’¡ What Hustlr Is

Hustlr is **not an insurance company.** It is an **underwriting intelligence engine** that enables licensed insurers to profitably serve gig workers â€” a segment traditional insurance has never been able to reach.

---

## ðŸ‘¤ Chosen Persona: Q-Commerce Delivery Partner

**Persona:** A Zepto delivery partner operating in Chennai â€” Velachery, Adyar, or Tambaram dark store zones.

Workers are registered on a **single primary platform only**, in compliance with Zepto's partner exclusivity agreement. Insurance is priced based on that platform's activity data alone â€” keeping the model legally clean and operationally simple.

### Why Q-Commerce?

| Factor | Q-Commerce (Zepto) | Food (Zomato/Swiggy) | E-Commerce (Amazon/Flipkart) |
|--------|---------------------------|----------------------|------------------------------|
| Delivery frequency | 15â€“25 orders/day | 8â€“15 orders/day | 3â€“8 orders/day |
| Hyperlocal sensitivity | Extreme (dark store zones) | High | Moderate |
| Weather vulnerability | Critical (monsoon paralysis) | High | Lowâ€“Medium |
| Worker density per zone | Very high (cluster-based) | Medium | Spread out |
| Fraud surface area | High (zone-based clustering) | Medium | Low |

Q-commerce workers operate within **tight geographic zones** anchored to dark stores, making parametric triggers more precise (zone-level, not city-level), fraud detection more nuanced (cluster behaviour becomes a signal), and income modeling more predictable (orders/hour baselines are tight).

### Persona Profile: "Karthik, 24, Zepto Partner, Adyar Dark Store Zone, Chennai"

| Attribute | Value |
|---|---|
| Platform | Zepto (single platform â€” partner agreement compliant) |
| Weekly earnings | â‚¹4,200 (~â‚¹600/day, ~â‚¹60/hr over a 10-hr shift) |
| Shift window | 8 AM â€“ 10 PM (derived from 30-day activity history) |
| Peak slots | Morning 8â€“11 AM Â· Evening 5â€“9 PM |
| Delivery radius | 2â€“3 km from Adyar dark store â€” zone loss = total income loss |
| Device | Android budget phone (~â‚¹10,000) |
| Payments | UPI for all transactions |
| Savings buffer | 2â€“3 days of income at most |
| Financial obligations | Weekly rent + monthly family remittances |
| Annual disruption exposure | ~80 rain days Â· loses â‚¹400â€“â‚¹600 per heavy rain day |

**Key disruptions Karthik faces:**

| Disruption | Frequency | Impact |
|---|---|---|
| Heavy monsoon rain | ~80 days/year | Zone completely unserviceable for 3â€“6 hours |
| Cyclone / extreme rain | 2â€“4 events/year | 3â€“4 days of income wiped out (Cyclone Michaung scale) |
| Platform app outage | ~2â€“3 times/month | Zero orders possible regardless of conditions |
| Bandh / curfew | ~8â€“10 days/year | Roads blocked, platform auto-pauses |
| Internet zone blackout | ~6â€“10 days/year | Entire operating environment goes dark |
| Accident blockspot | Weekly on GST Road / IT Corridor | 1â€“3 hour income gap per incident |

---

## âš¡ How Hustlr Works â€” 15-Second View

<p align="center">
  <img src="https://github.com/user-attachments/assets/289c1d4b-ce38-4355-81ce-223381723260" width="900" alt="Hustlr â€” How It Works"/>
</p>

```
1. Rain detected in Karthik's zone    â†’  IMD + OpenWeatherMap confirm threshold
2. Data Trust Engine validates         â†’  Combined source trust 0.85 â€” exceeds 0.75 threshold
3. Shift window check passes           â†’  disruption falls within Karthik's working hours
4. Zone depth score calculated         â†’  confirms Karthik was genuinely deep in zone, not at boundary
5. Device integrity verified           â†’  Play Integrity API confirms no GPS spoofing app active
6. Fraud check in < 2 seconds          â†’  FRS score computed across 7 independent signal layers
7. Circuit Breaker confirms pool OK    â†’  BCR at 44% â€” well below 85% ceiling
8. 70% tranche credited same day       â†’  â‚¹105 to UPI instantly for urgent expenses
9. 30% safety tranche Sunday night     â†’  â‚¹45 after full-week fraud pattern review
```

No forms. No adjusters. No claim ever filed by the worker â€” for automated trigger events.

---

## ðŸ“– Parametric vs Indemnity â€” Why This Model

> *The mentor session was explicit: judges expect teams to understand why they chose parametric. Here is ours.*

### Indemnity (Traditional) Insurance
Covers your **actual loss** â€” assessed after the fact by a surveyor. You file a claim, submit documents, wait 15â€“30 days, and receive what you lost (subject to depreciation, policy limits, and adjuster disputes).

**Why it fails gig workers:** A Zepto rider losing â‚¹600 on a rainy day cannot wait 30 days for reimbursement. The paperwork requirement alone eliminates most informal workers from ever claiming.

### Embedded Insurance
Insurance bundled invisibly into a product purchase (e.g. phone insurance at checkout). Uses **Nudge Theory** â€” if the customer does not opt out, they are enrolled. Relevant for platforms like Zepto offering insurance as a worker benefit.

### Parametric Insurance (Hustlr's Model)
Payout is **fixed** and triggered by a **measurable index** â€” not by actual loss. When the index crosses a threshold AND the worker is on shift, money moves automatically. No claim filed. No surveyor. No forms.

| Dimension | Indemnity | Parametric (Hustlr) |
|---|---|---|
| Trigger | Verified actual loss | Index threshold breach |
| Claim process | Manual, 15â€“30 days | Fully automated, <2 min |
| Fraud surface | High (inflated claims) | Low (index not controllable) |
| Basis risk | None | Present and intentional (60â€“70% replacement) |
| Worker effort | High | Zero for automated triggers |
| Best fit | High-value, rare events | Frequent, predictable income disruptions |

**Why 60â€“70% replacement and not 100%:** Full income replacement creates moral hazard â€” workers would stop working at the first sign of rain. The 60â€“70% band is the global parametric standard: enough to cover critical expenses (rent, food), not enough to make staying home the rational choice.

---

## âœ… What Hustlr Covers

| Covered | Not Covered |
|---------|-------------|
| Lost income during weather shutdowns (rain, cyclone, extreme heat, AQI) | Vehicle repairs or damage |
| Lost income during platform-declared outages | Medical or accident expenses |
| Lost income during civil disruptions (curfew, bandh, strike) | Personal illness or fatigue |
| Lost income during internet zone blackouts | Low-order days due to competition |
| Lost income due to accident blockspots on hotspot corridors | Income loss outside declared shift window |
| Lost income during severe traffic congestion (Full Shield) | Events with no corroborating data source |

---

## ðŸ¢ Insurance Partner Model

| Role | Entity |
|---|---|
| **Risk Underwriter** | Licensed insurer â€” ICICI Lombard / HDFC ERGO |
| **Trigger + Intelligence Engine** | Hustlr |
| **Policy Administration** | Guidewire PolicyCenter API |
| **Claims Automation** | Guidewire ClaimCenter API |
| **Premium Billing** | Guidewire BillingCenter API |
| **Distribution â€” Phase 1** | Direct B2C â€” Hustlr mobile app via WhatsApp groups + referral |
| **Distribution â€” Phase 2** | B2B2C â€” Zepto platform integration + insurer white-label |

---

## âš™ï¸ Guidewire Integration

### PolicyCenter
- Weekly policy creation every Monday via PolicyCenter API
- ISS score + city risk profile passed as risk attributes for premium computation
- Policy status synced back to Hustlr in real time

### ClaimCenter
- On parametric trigger: Hustlr pushes a structured, pre-validated claim payload
- Fraud Risk Score attached â€” ClaimCenter routes CLEAN to auto-approval, FLAGGED to human queue
- On manual claim: worker-submitted proof package routed directly to ClaimCenter review queue
- Zero-touch for weather/bandh/internet events. Structured review for manual claim types.

### BillingCenter
- Weekly premium deduction via BillingCenter direct debit scheduling
- Payout disbursement coordinated through BillingCenter's payment gateway
- Worker wallet reconciliation synced weekly

### Guidewire Marketplace
- Hustlr packaged as a Marketplace integration â€” any insurer on PolicyCenter/ClaimCenter can onboard Hustlr's parametric trigger engine as a configurable product extension

### B2B2C Distribution Channel (Phase 2)
After proving the model B2C, Hustlr embeds directly inside the Zepto partner app as a white-label insurance feature. Zepto pays a per-worker monthly licensing fee. The insurer underwrites the risk. Guidewire collects a technology licensing fee from the insurer.

**Why platforms pay for this:**
- Reduces worker churn during bad weather
- Differentiates Zepto in recruiting delivery partners from competitors
- Fulfills ESG mandate: "we protect our delivery partners"

---

## ðŸ“Š Parametric Logic â€” Core Principle

Hustlr does **not** calculate actual income loss. No investigation needed for automated triggers.

- A measurable disruption index is monitored in real time
- When it crosses a threshold AND falls within the worker's shift window â†’ payout fires
- Payout = fixed rate per trigger type Ã— verified disruption hours (capped at â‚¹150/day, â‚¹500/week)

```
Example:
  Trigger:          Heavy rain â€” IMD confirms 72mm, threshold 64.5mm crossed
  Duration:         3 hours above threshold
  Shift window:     Disruption 11 AMâ€“2 PM within Karthik's 8 AMâ€“10 PM  â†’  PASS
  Zone depth score: 0.84 â€” core zone confirmed  â†’  PASS
  Device integrity: Play Integrity API â€” PASS
  Fixed rate:       â‚¹50/hr (Heavy Rain, Standard Shield)

  Payout = â‚¹50 Ã— 3 = â‚¹150  â†’  auto-disbursed to UPI Sunday night
```

**Why weekly settlement, not instant:** Claims log throughout the week. Settlement runs every Sunday at 11 PM. The fraud engine evaluates the **complete week's pattern** before any money moves. A worker who triggers 3 events in one week activates the claim velocity signal before any payout releases. Weekly settlement also perfectly matches Zepto's weekly partner payment cycle.

**Why 60â€“70% income replacement, not 100%:** Parametric insurance by design does not fully replace income â€” this is basis risk, and it is intentional. Paying â‚¹50/hr (67% replacement) means honest workers are protected without the product becoming a profit opportunity. Full replacement creates moral hazard. The 60â€“70% band is the industry standard for parametric income protection.

---

## ðŸš¨ Trigger Parameters

### Automated Parametric Triggers

| Trigger | Threshold | Data Source | Hourly Rate |
|---|---|---|---|
| Heavy Rain | â‰¥ 64.5mm / hr | IMD + OpenWeatherMap | â‚¹50/hr |
| Extreme Rain / Cyclone | â‰¥ 115.6mm / hr | IMD + OpenWeatherMap | â‚¹65/hr |
| Heat Wave | â‰¥ 43Â°C | IMD | â‚¹40/hr |
| Severe Pollution | AQI â‰¥ 200 | AQICN / WAQI | â‚¹40/hr |
| Platform App Outage | Order failure rate > 60% | Platform API + order failure rate | â‚¹50/hr |
| Bandh / Strike / Curfew | NLP confidence â‰¥ 0.6 + platform OFFLINE | NewsAPI + NLP scraper | â‚¹50/hr |
| Heavy Traffic Congestion | Speed â‰¥ 40% below historical baseline, sustained â‰¥ 45 min + order failure > 35% | Google Maps Traffic API + baseline model | â‚¹40/hr |
| Internet Zone Blackout | Connectivity < 10% in zone for â‰¥ 30 min | Ookla / TRAI + device signal reports | â‚¹50/hr |

**Payout cap:** â‚¹150/day Â· â‚¹500/week

### Manual Claim Triggers

| Trigger | What Worker Submits | Cross-Check Sources | SLA |
|---|---|---|---|
| Traffic Accident Blockspot | GPS screenshot + scene photo (EXIF-stamped) + platform earnings screenshot | Google Maps Traffic API + News API + order density | 4 hrs |
| Local Road Closure | Same as above | Municipal advisory feed + Maps | 4 hrs |
| Dark Store / Hub Shutdown | Photo of closed hub + Zepto screenshot | Platform API + NLP scraper | 4 hrs |

---

## âš¡ Compound Triggers â€” Full Shield

Full Shield workers receive compound trigger payouts when two disruptions occur simultaneously.

| Compound Combination | Logic | Payout % of Daily Cap |
|---|---|---|
| Rain (severe) + Platform Downtime | Both active simultaneously in zone | 100% |
| Rain (any) + Traffic Standstill | Both active in zone simultaneously | 70% |
| Extreme Heat + High AQI | Both above threshold simultaneously | 55% |
| Cyclone Watch + Rain | Advisory active + rainfall >30mm/hr | 85% |
| Dark Store Closed + Rain | Both conditions confirmed | 100% |
| Curfew + Platform Outage | Both active during shift window | 100% |
**Business logic:** When two disruptions overlap, income loss is multiplicative â€” not additive. Rain alone reduces deliveries by 70%. Rain plus platform downtime reduces deliveries by 100%. Full Shield pays a compound bonus reflecting the true income impact.

**Claim-Free Cashback (Full Shield):**
Workers on Full Shield who complete 4 consecutive weeks without a payout receive 10% of their premiums from those 4 weeks returned as wallet credit. This solves adverse selection â€” rewarding workers who stay insured during calm periods builds a healthier premium pool.

---

## ðŸ›¡ï¸ Anti-Gaming Rules

- **Minimum duration:** 45 continuous minutes above threshold before trigger activates
- **Cooling period:** Same disruption type cannot trigger again in same zone within 24 hours
- **Shift intersection:** Disruption must overlap worker's registered shift by minimum 2 hours
- **One event per week per type** for Basic and Standard Shield plans
- **Pro-rata for mid-week activation:** Worker activating on Thursday receives payout weighted by days active
- **Post-purchase coverage only:** Disruptions beginning before policy activation are never covered

### Threshold Obfuscation + Dynamic Micro-Variation

**Exact trigger thresholds are never published.** Workers see only ranges â€” never specific millimetre values.

The actual trigger threshold varies by Â±3mm (rain) or Â±0.5Â°C (heat) each week using a seeded random value known only to the system. Workers can never predict the exact number for the current week.

**Why this matters for Chennai specifically:** Research into Chennai delivery worker behavior reveals workers are highly financially sophisticated and actively probe incentive systems. The Rapido/cab driver pattern of gaming platform incentives is directly applicable to insurance threshold gaming. Workers in organized groups can identify precise thresholds through repeated testing and share them via WhatsApp. Threshold micro-variation makes this strategy unreliable.

---

## ðŸ“± Manual Claim Filing â€” UX Flow

Workers filing a manual claim tap **"Report a Disruption"** on the Claims screen. This opens a 3-step guided flow designed for one-thumb operation on a budget Android device.

**Step 1 â€” Select Disruption Type**
```
Worker sees:
  ðŸš§  Road Blocked / Accident
  ðŸª  Dark Store / Hub Closed
  ðŸŒ  Internet Outage (zone-level)
  ðŸ“¦  Other Delivery Blockage
```

**Step 2 â€” Capture Evidence (in-app, EXIF-stamped)**
```
Disruption Type          What the app asks for
â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
Road Blocked / Accident  1 photo (app GPS-stamps at capture)
Dark Store / Hub Closed  1 photo + Zepto screenshot (no orders)
Internet Outage          App auto-reads signal strength â€” no photo
Other                    1 photo + description (max 100 chars)
```

**Step 3 â€” Submission & Tracking**
```
Worker sees:
  "Claim submitted. We're checking 3 data sources."

Within 4 hours:
  â†’ AUTO-APPROVED: "â‚¹X credited to your wallet"
  â†’ NEED MORE INFO: "Tap here to add one more photo"
  â†’ DECLINED + EXPLANATION: "Here's why, and how to appeal"
```

---

## ðŸŒ Internet Zone Blackout â€” Trigger Architecture

India's gig workers are uniquely vulnerable to localized internet outages. A Zepto Q-commerce rider cannot accept orders, navigate, or scan QR codes during a connectivity blackout. One pincode blackout eliminates their entire working zone instantly.

```
Signal 1 â€” Ookla Real-Time Speed Map API
  Zone average download speed < 2 Mbps for 20 minutes  â†’  degraded flag

Signal 2 â€” Device crowd-reporting (passive)
  â‰¥ 30% of active Hustlr users in a pin-code report < 1 bar signal
  â†’  cluster anomaly flag

Signal 3 â€” TRAI outage registry
  Any registered outage for zone's ISP/tower operator  â†’  authoritative flag

Dual-confirmation rule:
  Signal 1 + Signal 2  â†’  AUTO_TRIGGER
  Signal 3 alone        â†’  AUTO_TRIGGER
  Signal 1 alone        â†’  HOLD for 20-minute reconfirmation window
```

**Fraud resistance:** Faking connectivity loss requires active data transmission to submit the claim — which is self-contradictory. This makes the internet blackout trigger one of Hustlr's most inherently fraud-resistant signals.

---

## ðŸš§ Accident Blockspot â€” Trigger Architecture

Chennai's road network has documented high-frequency accident corridors â€” Rajiv Gandhi Salai, GST Road, and Poonamallee High Road account for a disproportionate share of delivery-hour blockages.

```
Google Maps Traffic API:
  Route speed < 5 km/h on major corridor for â‰¥ 30 minutes  â†’  gridlock flag

Cross-checked against:
  NewsAPI / NLP scraper: "accident", "collision", "road blocked"
  in that zone within past 45 minutes  â†’  corroborated

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

## ðŸš¦ Heavy Traffic Congestion â€” Trigger Architecture

```
Step 1 â€” Build historical baseline per corridor per 30-min time slot:
  Google Maps Traffic API â†’ rolling 90-day average speed

Step 2 â€” Detect abnormal deviation:
  Current speed < (baseline âˆ’ 40%) sustained â‰¥ 45 minutes  â†’  severe flag

Step 3 â€” Platform order failure corroboration:
  Order failure rate in affected zone > 35%  â†’  confirmed

All three conditions must be met simultaneously â†’ AUTO_TRIGGER
```

**City-specific corridor baselines ✅ (Phase 2 live — all 4 cities):**

| City | High-Risk Corridor | Baseline | Trigger Threshold |
|---|---|---|---|
| Chennai | GST Road, Anna Salai | 18–22 km/h | < 11–13 km/h |
| Bengaluru | Electronic City Flyover, ORR | 15–20 km/h | < 9–12 km/h |
| Mumbai | Eastern Express Highway, WEH | 20–25 km/h | < 12–15 km/h |
| Delhi | NH48, Gurugram corridor | 22–28 km/h | < 13–17 km/h |

---

## ðŸ“‹ Real Scenario Simulations

### Scenario A â€” Chennai November Rain (Automated)

```
Date:         November 12, 2025 Â· Location: Adyar, Chennai
IMD data:     72mm rainfall â€” threshold crossed for 3 hours
Data Trust:   IMD (Tier 1, 0.92) + OpenWeatherMap (Tier 2, 0.78)
              Combined trust: 0.85 â€” EXCEEDS 0.75 threshold  â†’  VALID
Shift window: 11 AMâ€“2 PM within Karthik's 8 AMâ€“10 PM  â†’  PASS
Zone depth:   Karthik's GPS shows 0.84 â€” core zone  â†’  PASS
Fraud score:  FRS = 14/100 â€” CLEAN  â†’  AUTO-APPROVE
Circuit BCR:  Pool at 44% â€” well within 85% ceiling  â†’  CIRCUIT CLOSED

Payout = â‚¹50/hr Ã— 3 hrs = â‚¹150

Timeline:
  11:00 AM  â†’  IMD threshold crossed
  11:02 AM  â†’  Data Trust Engine: combined 0.85 â€” PASS
  11:02 AM  â†’  Zone depth: 0.84 â€” PASS
  11:02 AM  â†’  Fraud engine: FRS = 14 â€” CLEAN
  11:02 AM  â†’  Circuit Breaker: BCR 44% â€” CLOSED
  11:02 AM  â†’  Claim logged PENDING â€” Karthik notified: "Rain disruption detected"
  Sunday    â†’  70% tranche (â‚¹105) released to Karthik's UPI
  Tuesday   â†’  30% safety tranche (â‚¹45) released after review window
```

### Scenario B â€” Shadow Policy Activation

```
Karthik has no active policy this week.
Rain disruption hits Adyar zone Thursday.
System silently calculates: if Karthik had Standard Shield,
he would have received â‚¹150 in payout.

Accumulated over 2 weeks: â‚¹680 in missed payouts.

Wednesday notification:
  "You missed â‚¹680 in payouts this fortnight.
   Activate Standard Shield now â€” â‚¹49/week."
```

### Scenario C â€” Predictive Activation (Wednesday Nudge)

```
Wednesday evening â€” Hustlr's 72-hour forecast runs.
OpenWeather shows: 78% probability of IMD Very Heavy Rain
in Adyar zone on Friday 2 PMâ€“6 PM.

Karthik receives push notification:
  "Heavy rain expected Friday in your zone.
   Activate â‚¹49 Standard Shield now to protect â‚¹600+ earnings."

Karthik taps â†’ policy activated â†’ Friday rain hits â†’
claim auto-triggered â†’ â‚¹150 Sunday night.
```

---

## ðŸ›¡ï¸ Adversarial Defense & Anti-Spoofing Strategy

### The Threat

### Layer 0 â€” Device Integrity Check

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

## ðŸ“ Zone Depth Scoring â€” Anti-Boundary Gaming

**The problem with binary zone membership:** Workers can game a hard boundary by standing 50 metres inside it during a disruption. A financially sophisticated Chennai worker will learn where the boundary is and exploit it.

**Continuous Zone Depth Score:**
- Outer ring (0â€“500m inside boundary) â†’ 0.00â€“0.20 score (No payout - boundary gaming)
- Middle ring (500mâ€“2km from boundary) â†’ 0.21â€“0.60 score (Partial multiplier)
- Core zone (2km+ from any boundary) â†’ 0.61â€“1.00 score (Full payout)

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

## ðŸ¤– AI/ML Architecture

### Model 1 â€” Income Stability Score (ISS)
Evaluates zone flood risk, avg 12-month disruption frequency, claims penalty, and daily income to generate risk profile indexing.

### Model 2 â€” Fraud Detection Engine
Isolation Forest architecture detecting spikes in geographic clustering, simultaneous claims from shared device subnets, and extreme claim velocity. Combines 7 independent signal layers.

### Model 3 â€” NLP Disruption Scraper
LLM preprocessing architecture scoring unstructured government advisories and unstructured news events into structured risk factors with numeric confidence intervals. 

---

## ðŸŒ Regional Behavioral Intelligence Layer

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

## ðŸš€ Innovation Differentiators

### 1. Shadow Policy â€” Uninsured Worker Conversion

Workers who have not purchased insurance are tracked in a **shadow policy mode**. After 2 weeks, the app displays missed payout totals â€” acquisition cost for a converting worker = â‚¹0.

### 2. Predictive Insurance Activation

Every Wednesday evening, Hustlr runs a 72-hour disruption forecast. If probability exceeds 60%, workers receive:
> *"Heavy rain expected Friday 2–6 PM in your Adyar zone. Activate Standard Shield now to protect up to ₹600 of Friday earnings."*

Workers activate before the disruption — not after. A 65% loss ratio on a ₹49 premium is ₹17 profit per worker per week.

### 3. Play Integrity API as Layer 0

Catching GPS spoofing at the device level before GPS data is trusted â€” blocks the bulk of spoofing attempts at the entry point.

### 4. Zone Depth Scoring

Replaces binary zone membership with continuous presence scoring. No other team will implement this.

### 5. Regional Behavioral Intelligence

City-level calibration of fraud weights (e.g. Chennai index) informs portfolio-level thresholds â€” not individual claim denial by city alone.

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

## ðŸ’° Weekly Premium Tiers

| Plan | Weekly Premium | Covers | Expected Weekly Payout | Target Loss Ratio | Best For |
|---|---|---|---|---|---|
| **Basic Shield** | â‚¹35/wk | Rain + extreme heat | ~â‚¹22 | 0.62 | Low-risk zones, new workers |
| **Standard Shield** â­ | â‚¹49/wk | Rain, heat, pollution, app downtime | ~â‚¹38 | 0.63 | Most city delivery workers |
| **Full Shield** | â‚¹79/wk | All 9 triggers + compound | ~â‚¹58 | 0.65 | Flood-zone workers |

### Income Add-Ons

| Add-On | Weekly Cost | Covers |
|---|---|---|
| Cyclone | +â‚¹20/wk | Extreme rain + cyclone alerts |
| Curfew & Strike | +â‚¹12/wk | Bandh, curfew, Section 144 |
| Election Day | +â‚¹8/wk | Polling day restricted movement |
| App Downtime | +â‚¹10/wk | Platform outage via order failure rate |

### Premium Bounds â€” Actuarial Guardrails

| Bound | Multiplier | Example (Standard Shield â‚¹49 base) |
|---|---|---|
| Maximum | 2.0Ã— base tier rate | â‚¹98/week |
| Minimum | 0.7Ã— base tier rate | â‚¹34/week |

### ðŸ“ Actuarial Pricing Model â€” How the Numbers Were Derived

Every premium in Hustlr is backed by a formula, not a guess. Here is the exact actuarial logic.

#### Step 1 â€” Base Burning Cost Formula

The **Burning Cost Rate (BCR)** is the core actuarial measure:

```
BCR = Total Claims Paid Ã· Total Premium Collected

Target BCR:  < 0.65  (65% loss ratio)
Circuit trip: BCR > 0.85  â†’ enrollment halted for that pool
```

#### Step 2 â€” Base Premium Formula

```
Weekly Premium = Trigger Probability Ã— Average Daily Income Ã— Days Exposed Ã— Load Factor

Where:
  Trigger Probability  = P(disruption â‰¥ threshold in worker's zone per week)
                         Derived from IMD historical data (10-year daily records for Chennai)
  Average Daily Income = â‚¹600/day (Karthik baseline from worker interviews)
  Days Exposed         = Expected disruption days covered per week
  Load Factor          = 1 / (1 - target_expense_ratio)
                         = 1 / (1 - 0.35) = 1.54  [35% = Hustlr fee + insurer margin + reinsurance + Guidewire]
```

#### Step 3 â€” Per-Trigger Worked Example (Standard Shield, Rain)

```
Chennai heavy rain frequency:  ~80 days/year  â†’  1.54 days/week on average
Heavy-rain threshold days:     ~35% of rain days exceed 64.5mm  â†’  0.54 days/week
Average disruption duration:   3.2 hours per event
Hourly payout rate:            â‚¹50/hr (Standard Shield)

Expected weekly claims cost per worker:
  = 0.54 days Ã— 3.2 hrs Ã— â‚¹50/hr
  = â‚¹86.40/week (claims portion)

Load factor applied:
  = â‚¹86.40 Ã— 1.54 / 0.65   â† divide by target loss ratio to get gross premium
  â‰ˆ â‚¹86.40 / 0.65 Ã— 1.0
  â‰ˆ â‚¹49/week  âœ“  (matches Standard Shield price)
```

#### Step 4 â€” ISS Adjustment

Each worker receives an **Income Stability Score (ISS)** that adjusts their premium:

```
Final Premium = Base Premium Ã— Zone Multiplier Ã— ISS Multiplier

Zone Multiplier:
  Core flood zone (Velachery, Adyar)  â†’ 1.10Ã—
  Standard zone                        â†’ 1.00Ã—
  Low-risk zone (OMR tech corridor)    â†’ 0.85Ã—

ISS Multiplier:
  ISS 80â€“100 (veteran, low claims)    â†’ 0.90Ã— (discount)
  ISS 50â€“79  (typical worker)         â†’ 1.00Ã—
  ISS < 50   (new / high-risk)        â†’ 1.15Ã— (loading)

Bounds:  min 0.7Ã— base rate, max 2.0Ã— base rate (anti-shock rule)
```

#### Step 5 â€” Stress Scenario (Cyclone Week)

The mandatory what-if analysis per actuarial standards:

```
Stress: 14-day continuous monsoon hitting Chennai + Mumbai simultaneously

  Workers affected:      10,000 (Chennai 7,000 + Mumbai 3,000)
  Trigger fires:         14 consecutive days Ã— â‚¹150/day cap
  Gross exposure:        10,000 Ã— â‚¹150 Ã— 14 = â‚¹2.1 crore

  Pool buffer:
    Weekly pool @ â‚¹49 avg:          â‚¹4,90,000/week Ã— 2 weeks = â‚¹9,80,000
    Reserve fund (15%):             â‚¹1,47,000
    Reinsurance trigger point:      4Ã— weekly pool = â‚¹19,60,000

  Result: Reinsurance covers â‚¹2.1cr âˆ’ â‚¹9.8L âˆ’ â‚¹1.47L = â‚¹1.9cr excess
  â†’ Munich Re reinsurance treaty activated automatically
  â†’ Circuit Breaker: BCR exceeds 85% â†’ new enrollment paused in affected pool
```

#### City-Specific Pool Separation

Each city Ã— risk-type gets its own pool â€” this is a core actuarial requirement because correlated perils must be isolated:

| Pool | Primary Peril | Why Separate |
|---|---|---|
| Chennai Rain | Monsoon + cyclone | 80+ days/yr; correlated across zone |
| Delhi AQI | Industrial + seasonal smog | Winter AQI crisis unrelated to rain |
| Mumbai Rain | Monsoon + sea surge | Different rainfall pattern from Chennai |
| Bengaluru Platform | App-outage density | Tech workforce; correlated platform risk |

Mixing Chennai Rain and Delhi AQI into one pool would create cross-subsidization â€” Delhi workers would pay for Chennai monsoon exposure and vice versa.

---

## ðŸ™ï¸ City Risk Profiles

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

## ðŸ”„ End-to-End Workflow (Full)

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

## ðŸ“¡ Parametric Trigger Decision Flow

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

## ðŸ›¡ï¸ Fraud Detection Decision Flow

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

## ðŸ“Š System Reliability â€” Fallback Hierarchy

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

## ðŸ—ï¸ Platform Decision â€” Mobile App (Flutter)

Delivery workers do not use laptops. Every interaction happens on a â‚¹10,000 Android phone at a red light. Designed for one-thumb operation and 3-second tasks.

The anti-spoofing engine requires direct native access to: cell tower IDs, Wi-Fi SSID fingerprints, GPS jitter readings, accelerometer, battery state, barometric pressure, signal strength, and Play Integrity API. PWAs cannot reliably access all of these on Android. Flutter provides full native sensor access plus a single codebase for both Android (worker app) and web (insurer admin dashboard).

Background GPS tracking via `flutter_background_geolocation` runs continuously during shifts â€” even when the phone screen is off â€” providing the continuous location data that zone depth scoring requires.

---

## ðŸ› ï¸ Tech Stack

**Frontend**

| Component | Technology |
|---|---|
| Design System | Ethereal Night Theme |
| Framework | Flutter (Dart) |
| State Management | flutter_bloc + Provider (UserBloc, PolicyBloc, ClaimsBloc) |
| Background Location | flutter_background_geolocation |
| Local Storage | Hive (offline-first) |
| Payments (mock) | Razorpay Flutter SDK â€” test mode |
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

## ðŸ§ª MVP Scope â€” Phase 1

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

## 🧪 MVP Scope — Phase 1 ✅ & Phase 2 ✅

### Phase 1 Complete ✅

- Rain trigger via live OpenWeatherMap + IMD with shift window check
- Zone depth scoring (3-ring model with payout multiplier)
- Fixed hourly payout (â‚¹40â€“â‚¹65/hr) with â‚¹150/day + â‚¹500/week caps
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
- Compound trigger logic for Full Shield
- Claim-free cashback mechanic design
- News corroboration as scored fraud layer (0.25 FPS weight)
- Zone context override during declared emergencies
- Network drop grace period flow for honest workers
- Premium bounds (2Ã— max, 0.7Ã— min)
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

---

## ðŸ’¸ Cost Efficiency

| Resource | Cost |
|---|---|
| OpenWeatherMap, IMD, AQICN | â‚¹0 |
| MaxMind GeoIP2 | â‚¹0 (free tier) |
| OpenCelliD | â‚¹0 (free tier) |
| Ookla Enterprise (optional) | Paid â€” off by default; use inferred connectivity unless `USE_OOKLA_INTERNET=true` |
| TRAI Outage Registry | â‚¹0 (government open data) |
| Brave Search + NewsAPI | â‚¹0 (free tiers) |
| Supabase + Render | â‚¹0 (free tiers) |
| Razorpay test mode | â‚¹0 |
| Play Integrity API | â‚¹0 (Google free tier) |

**Total infrastructure: â‚¹0/month.**

---

## ðŸ“… 6-Week Plan

### âœ… Phase 1 (Weeks 1â€“2) â€” Current

- [x] Shift window eligibility architecture
- [x] Fixed hourly payout model with daily + weekly caps
- [x] Premium bounds (2Ã— max, 0.7Ã— min)
- [x] ISS scoring (rule engine) with named real datasets
- [x] ISS-based onboarding tier recommendation
- [x] Zone depth scoring (3-ring model + payout multiplier)
- [x] Shadow policy tracking for uninsured workers
- [x] Predictive 72-hour forecast nudge system
- [x] Regional behavioral intelligence layer (Chennai)
- [x] Threshold obfuscation + dynamic micro-variation
- [x] Compound triggers for Full Shield
- [x] Claim-free cashback mechanic
- [x] Device trust Layer 0 *design* (heuristic + ML signals; Google Play Integrity optional â€” see Phase 2)
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

### Phase 2 (Weeks 3â€“4) â€” Automation & Protection

*Status reflects this repo. **Live** = implemented in Node / Flutter / ML and callable when env vars, Supabase, and keys are configured (Render + Vercel + mobile builds). Stubs and simulations are called out explicitly.*

| Status | Item |
|--------|------|
| âœ… | **Flutter app** â€” core screens, dashboard, policies, claims, manual claim flow; polish and edge screens ongoing |
| âœ… | **Weather + NLP / bandh cron** â€” `disruption_cron` + snapshot pipeline (`OWM_*`, `NEWSAPI_*`, `AQICN_*` as configured) |
| ✅ | **Flutter app** — core screens, dashboard, policies, claims, manual claim flow; polish and edge screens ongoing |
| ✅ | **Weather + NLP / bandh cron** — `disruption_cron` + snapshot pipeline (`OWM_*`, `NEWSAPI_*`, `AQICN_*` as configured) |
| ⚠️ | **Order failure rate** — *simulated* platform outage signal in backend (`platform_service`); no real delivery-platform API |
| ⚠️ | **Internet blackout** — default **inferred** zone connectivity (no Ookla cost); optional **Ookla Enterprise** when `OOKLA_API_KEY` + `USE_OOKLA_INTERNET=true`; TRAI modeled as flags, not a live API |
| ✅ | **Zone depth** — Haversine ring scoring in Node; optional **PostGIS** path via Supabase RPC `hustlr_zone_depth` (`USE_POSTGIS_ZONE_DEPTH=true`, run `schema_phase2.sql`) |
| ✅ | **Google Play Integrity** — `GET /integrity/play/nonce` + `POST /integrity/play/verify`; **simulated mode** `PLAY_INTEGRITY_SIMULATED=true` returns mock `MEETS_DEVICE_INTEGRITY` JSON (no Google billing); fraud hook: pass **−10**, fail **+30** on `/claims/create` & `/claims/manual`; production: service account + `decodeIntegrityToken`; Flutter optional `--dart-define=PLAY_INTEGRITY_DEMO_PLACEHOLDER=demo` for mock-only demos |
| ✅ | **Shadow policy** — live `GET /policies/shadow/:userId` + Flutter `ShadowPolicyScreen` |
| ✅ | **Predictive nudge** — included in disruption bundle; optional FCM after cron (`DISABLE_PREDICTIVE_NUDGE_PUSH`, Firebase key) |
| ✅ | **Regional intelligence** — `regional_weekly_cron.js` + `GET /cities/risk-profiles` / `:city` (`DISABLE_REGIONAL_WEEKLY_CRON` in `.env.example`) |
| ✅ | **MaxMind + Native Sensor Pipeline** — MaxMind wired natively on backend; **Fully implemented Native Flutter Sensor pipeline** (`fraud_sensor_service.dart`) capturing live Barometer altitude and GPS Jitter variance during Android/iOS claim submissions, hooked directly into the mock-claim engine for instant testing. |
| ✅ | **OpenCelliD** — optional first hop in `POST /workers/cell-locate` when `OPENCELLID_API_KEY` is set; Unwired Labs fallback; no hardcoded keys |
| ✅ | **Hardware fingerprint clustering** — `device_fingerprint_events` in `schema_phase2.sql`; `POST /workers/fingerprint`; `GET /workers/fingerprint/stats`; optional `device_fingerprint` string on `POST /claims/create` bumps fraud when other users share the same hash in-zone |
| ✅ | **Auto-explanation** — `POST /claims/explanation` + `AutoExplanationScreen` (backend-generated when reasons not pre-passed) |
| ⚠️ | **Live Guidewire PC/CC/BC** — **ClaimCenter** + **PolicyCenter** + **BillingCenter** JSON stubs (`/guidewire/sample-payload`, `/guidewire/sample-policy`, `/guidewire/sample-billing/:id`) + optional webhook when `ENABLE_GUIDEWIRE_ROUTES=true` — not live carrier APIs |
| ✅ | **City risk profiles** — API live; **Chennai** primary; Mumbai / Bengaluru / Kolkata baselines in `cities` routes / risk service |

**Quick judge URLs:** API health `GET https://hustlr-ad32.onrender.com/health`, cron status `GET /health/cron`, fraud test `POST /claims/manual`.

---

## 🚀 Installation & Setup Guide

### Option 1 — Run Flutter App (Recommended for judges)

```bash
# Prerequisites: Flutter SDK >= 3.19, Dart >= 3.3
# https://docs.flutter.dev/get-started/install

# 1. Clone the repo
git clone https://github.com/Dhruvv-16/Hustlr.git
cd Hustlr

# 2. Install dependencies
flutter pub get

# 3a. Run on Chrome (web — fastest)
flutter run -d chrome

# 3b. Run on Android emulator
flutter emulators --launch <your-emulator-id>
flutter run

# 3c. Run on connected physical Android device
flutter run   # picks the connected device automatically
```

> **No `--dart-define` flags needed.** The app is hardwired to `https://hustlr-ad32.onrender.com` as the default API. Just run it.

### Option 2 — Install the APK directly on Android

1. Download **[hustlr-v1.0-release.apk](https://github.com/Dhruvv-16/Hustlr/raw/developer/releases/hustlr-v1.0-release.apk)** directly from this repo (`releases/` folder, 57 MB)
2. On your Android device: **Settings → Security → Allow Unknown Sources**
3. Transfer the APK via USB or use a share link and tap to install
4. Open **Hustlr** — the app connects to `hustlr-ad32.onrender.com` automatically, no config needed

> 📵 **Works offline too** — if the backend is unreachable (no WiFi, cold Render start), the app automatically loads the full **Karthik (Zepto Rider)** demo persona locally with mock policies, wallet, and claims.

### Option 3 — Run the Backend Locally

```bash
cd hustlr-backend

# 1. Copy the environment template
cp .env.example .env
# Edit .env — at minimum set SUPABASE_URL and SUPABASE_SERVICE_KEY
# All other keys are optional; the server gracefully degrades without them

# 2. Install dependencies
npm install

# 3. Start the API server
npm start
# Server runs on http://localhost:3000

# 4. Health check
curl http://localhost:3000/health
```

### Option 4 — Run the ML Service Locally

```bash
cd hustlr-backend/ml_service

# 1. Create a virtual environment
python -m venv venv
source venv/bin/activate   # Windows: venv\Scripts\activate

# 2. Install dependencies
pip install -r requirements.txt

# 3. Start the FastAPI server
uvicorn main:app --port 8000 --reload
# ML API runs on http://localhost:8000
# Swagger docs at http://localhost:8000/docs
```

### Environment Variables — Minimum Required

| Variable | Required | Where to get it |
|---|---|---|
| `SUPABASE_URL` | ✅ Yes | Supabase Dashboard → Project Settings → API |
| `SUPABASE_SERVICE_KEY` | ✅ Yes | Supabase Dashboard → Project Settings → API |
| `OWM_API_KEY` | Optional | [openweathermap.org](https://openweathermap.org/api) — free tier |
| `NEWSAPI_KEY` | Optional | [newsapi.org](https://newsapi.org) — free tier |
| `AQICN_API_KEY` | Optional | [aqicn.org/api](https://aqicn.org/api) — free tier |
| `PLAY_INTEGRITY_SIMULATED` | Set `true` | Enables mock integrity checks — no Google billing |

See `hustlr-backend/.env.example` for the full annotated list.

---

## 👨‍⚖️ Judge's Testing Guide

The app is wired directly to our **Live Production API** at `https://hustlr-ad32.onrender.com`. No config needed whatsoever — just run and test.

### Option A — Run the Flutter App (Recommended)

```bash
# 1. Install dependencies
flutter pub get

# 2. Run on Chrome (fastest) or a connected Android device
flutter run -d chrome
# OR
flutter run   # pick your connected device
```

**📱 App Login (Mock Demo Mode)**
The app is wired to gracefully fall back to robust mock data to ensure judges can evaluate the entire UI/UX even if the backend spins down.
- **Phone Number:** Enter *any* valid 10-digit number (e.g., `9876543210`).
- **OTP:** Enter *any* 6-digit OTP (e.g., `123456`).
You will be automatically logged into the **Karthik (Zepto Rider)** persona, complete with pre-populated policies, wallet balances, and active trigger statuses.

### 🎮 Triggering Live Demo Claims (Secret Menu)
We built a hidden "Demo Control Panel" so judges can easily manually trigger Parametric scenarios!
1. **Navigate to Dashboard** after logging in.
2. **Long-Press the Profile Icon** (Top-Left circular avatar icon).
3. The **"Demo Controls" bottom sheet** will instantly slide up!
4. Tap **"Trigger Rain Disruption"** to instantly crash the weather status and watch the mock payout funnel begin!

### Option B — Hit the API directly with curl

```bash
# Health check
curl https://hustlr-ad32.onrender.com/health

# Trigger a mock rain claim (Standard Shield worker)
curl -X POST https://hustlr-ad32.onrender.com/claims/create \
  -H "Content-Type: application/json" \
  -d '{"user_id":"mock-karthik-001","trigger_type":"rain","zone":"Adyar","city":"Chennai","severity":0.85,"duration_hours":3}'

# Submit a manual claim (GPS spoofing test — jitter 0.0 = FLAGGED)
curl -X POST https://hustlr-ad32.onrender.com/claims/manual \
  -H "Content-Type: application/json" \
  -d '{"user_id":"mock-karthik-001","trigger_type":"accident_blockspot","zone":"Adyar","sensor_features":{"gps_jitter":0.0,"barometer_hpa":1013.2}}'
```

### What to Look For

| Test | Expected Result |
|---|---|
| `GET /health` | `{"status":"ok"}` — all services up |
| Automated claim (jitter > 0.0) | `status: APPROVED`, payout calculated |
| Manual claim with `gps_jitter: 0.0` | `fraud_status: FLAGGED`, note: "Perfect GPS stability detected" |
| Manual claim from physical device | Natural jitter > 0.0 → `APPROVED` |
| Shadow policy nudge | `GET /policies/shadow/mock-karthik-001` → simulated missed payout shown |

### Mock User IDs for Testing

| User ID | Profile | Best for testing |
|---|---|---|
| `mock-karthik-001` | Adyar zone, Standard Shield | Automated rain claims |
| `mock-ravi-002` | Velachery zone, Full Shield | Compound trigger claims |
| `mock-muthu-003` | New user, no policy | Shadow policy nudge |

> **Note on Render cold starts:** The free tier may take ~30s to wake up on first hit. If `/health` returns a timeout, wait 30 seconds and try again. All subsequent calls are fast.

**Quick judge URLs:** API health `GET /health`, cron status `GET /health/cron`, ML via Node → `ML_SERVICE_URL`. Web on Vercel needs `HUSTLR_API_PROD`; Render `hustlr-api` should set `CORS_ORIGIN` to the Vercel origin.

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
| Average weekly premium (blended) | â‚¹49 |
| Weekly premium pool | â‚¹4,90,000 |
| Loss ratio target | < 0.65 |
| Reinsurance trigger | â‚¹19,60,000 (4Ã— pool) |

---

## ðŸ¤ IRDAI Compliance

- Technology partner model â€” not a licensed insurer
- Policy under partner insurer's IRDAI license
- Triggers rely on IMD â€” IRDAI-recognized data source
- Payout terms transparent at activation (parametric requirement)
- Microinsurance compliant: â‚¹29â€“â‚¹109/week, simplified format
- Within IRDAI Regulatory Sandbox guidelines for parametric products (2019)

---

## ðŸ‘¥ Team

| Member | Role |
|---|---|
| Inesh Agarwal | Flutter Development |
| V Dhruv | Backend / API + Guidewire Integration |
| Prisha Agarwal | AI/ML + Fraud Engine + NLP + Prophet |
| Daksh Gupta | UI/UX Design |
| T Anil Kumar | Insurance Domain + City Risk Profiles + Pitch |

---

## ðŸŽ¬ Phase 2 Deliverables

<div align="center">
  <a href="https://youtu.be/nD2snI4Tnu8?si=eS5sztT0aibvxodI">
    <img src="https://img.shields.io/badge/Demo_Video-FF0000?style=flat-square&logo=youtube&logoColor=white" alt="Video"/>
  </a>
  &nbsp;&nbsp;
  <a href="https://github.com/Dhruvv-16/Hustlr">
    <img src="https://img.shields.io/badge/GitHub_Repo-181717?style=flat-square&logo=github&logoColor=white" alt="GitHub"/>
  </a>
  &nbsp;&nbsp;
  <a href="https://hustlr-ad32.onrender.com/health">
    <img src="https://img.shields.io/badge/Live_API-00C853?style=flat-square&logo=render&logoColor=white" alt="Live API"/>
  </a>
</div>

### Phase 2 Additions vs Phase 1

| Delivered in Phase 2 | Details |
|---|---|
| âœ… **Live Production Backend** | Node.js + Supabase deployed on Render â€” `hustlr-ad32.onrender.com` |
| âœ… **Native Flutter Sensor Pipeline** | Live GPS Jitter + Barometer capture during claim submission (`fraud_sensor_service.dart`) |
| âœ… **Production SQL Schema** | Full Phase 1â€“4 schema deployed to Supabase (15 tables, triggers, RLS, PostGIS functions) |
| âœ… **Circuit Breaker + Pool Health** | Live BCR monitoring â€” auto-halts enrollment when loss ratio exceeds 85% |
| âœ… **Device Fingerprint Clustering** | `device_fingerprint_events` table live; ring fraud detection when >3 users share hash in-zone |
| âœ… **ML Microservice** | Python FastAPI service (`ml_service/`) deployable as a separate Render service |
| âœ… **App â†’ Render integration** | Flutter hardwired to production API; zero config for judges |
| âœ… **End-to-end Manual Claims** | Full flow: sensor capture â†’ fraud score â†’ APPROVED/FLAGGED with auto-explanation |

---

*Hustlr â€” Because every minute you can't deliver is a minute your income disappears.*

*We are from Chennai. We know what it means when Velachery floods. We built this for Muthu, Karthik, Ravi, Santhosh, and Priya â€” and the 7.7 million workers like them.*

