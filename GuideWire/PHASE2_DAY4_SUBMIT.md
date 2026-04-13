# HUSTLR — DAY 4: POLISH + README + SUBMISSION
## Final day before April 4 deadline
## Lock everything, record video, submit

---

## MORNING — UI polish (Inesh + Daksh)

Fix the specific issues called out in the feedback:

1. Demote "Report a Disruption" button
   - Move it out of the main Claims flow
   - Put it under Help & Support → "Report unlisted disruption"
   - The MAIN claim story is auto-detected, not manually filed
   - Keep the screen but make it a fallback, not the entry point

2. Fix Elite Shield card overflow
   - If text overflows the card, reduce font size to 13px
   - Or break the card into two sections with a divider

3. Fix empty space on wide desktop layouts
   - Add maxWidth: 600 constraint on all cards
   - Center the content on wide screens

4. Make the zero-touch story the hero of Home screen
   - The home screen should lead with: "Last event auto-detected"
   - Not with a manual "Report" CTA

---

## AFTERNOON — README final update (anyone)

Add two sections to the README:

SECTION 1 — Add backend API link at the top:

```markdown
<a href="https://hustlr-api.onrender.com/health">
  <img src="https://img.shields.io/badge/Backend_API-Live-2D6A2D?style=for-the-badge&logo=fastapi&logoColor=white" alt="API"/>
</a>
```

SECTION 2 — Add to Phase 2 Deliverables section:

```markdown
## 🎬 Phase 2 Deliverables

<div align="center">
  <a href="YOUR_PHASE2_VIDEO_LINK">
    <img src="https://img.shields.io/badge/Phase_2_Demo_Video-FF0000?style=for-the-badge&logo=youtube&logoColor=white"/>
  </a>
  &nbsp;
  <a href="https://github.com/Dhruvv-16/Hustlr">
    <img src="https://img.shields.io/badge/GitHub_Repository-181717?style=for-the-badge&logo=github&logoColor=white"/>
  </a>
  &nbsp;
  <a href="https://hustlr-api.onrender.com/health">
    <img src="https://img.shields.io/badge/Backend_API-Live-2D6A2D?style=for-the-badge&logo=fastapi&logoColor=white"/>
  </a>
</div>

### Phase 2 — What was built

**Backend (FastAPI on Render):**
- /detect-disruption — real-time trigger detection across 6 trigger types
- /fraud-score — 7-layer FPS scoring engine (rule-based, < 2 seconds)
- /calculate-payout — zone depth multiplier + 70/30 split logic
- /calculate-premium — ISS-based dynamic pricing with ±20% weekly cap

**Flutter app:**
- Full registration flow (onboarding → OTP → ISS calculation → confirmation)
- Policy management (4 plans, add-ons, history)
- Dynamic premium breakdown screen (live from backend API)
- Claims management (auto-detected + manual fallback)
- Claim detail with FPS fraud shield (7 layers visible)
- Declined/flagged claim state with auto-explanation
- Worker analytics dashboard
- Live trigger monitoring (5 triggers, real API)
- UPI withdrawal mock flow
```

SECTION 3 — Update 6-Week Plan checkboxes:

Mark these as complete:
- [x] Full Flutter app — all screens + manual claim flow
- [x] FastAPI backend — 4 endpoints live on Render
- [x] Dynamic premium calculation (ISS-based, weekly repricing)
- [x] Fraud scoring engine (7-layer FPS, rule-based)
- [x] Zone depth scoring (PostGIS-ready logic)
- [x] Shadow policy calculation
- [x] Auto-explanation for rejected claims
- [x] City risk profiles: Chennai baseline

---

## AFTERNOON — Record Phase 2 video (T Anil Kumar + Daksh)

2-minute video script:

```
0:00–0:05  "Hustlr. Phase 2. Code Crafters."

0:05–0:25  REGISTRATION
  Show: Phone → OTP → Onboarding → type "Adyar" in search
  → Zepto selected → ISS 62 AMBER on confirmation
  Narrate: "Registration takes 45 seconds. ISS score
            calculated from zone flood history and
            disruption frequency."

0:25–0:45  DYNAMIC PREMIUM
  Show: Tap plan card → Premium Breakdown
  → "Live from API" badge visible
  → Breakdown: base ₹55 → platform discount -₹3
  → history discount -₹3 → final ₹49
  Narrate: "Premium recalculates every Monday.
            This number came from the backend right now."

0:45–1:10  ZERO-TOUCH CLAIMS
  Show: Tap Demo button → loading spinner
  → Home alert: "Rain detected — ₹105 crediting Sunday"
  → Claim Detail opens
  → Timeline: all steps ticked
  → FPS 14/100 GREEN — 7 layers shown
  → ₹105 / ₹45 payout split
  Narrate: "Karthik did nothing.
            Detect. Verify. Pay. 2 minutes."

1:10–1:30  FRAUD ENGINE
  Show: Switch to DECLINED claim
  → Flagged signals: home Wi-Fi, idle motion, 28-second latency
  → "₹45 provisional credit released"
  → Auto-explanation screen
  Narrate: "The fraud engine runs 7 signal layers
            in under 2 seconds. Honest workers
            are never blocked — provisional credit
            releases immediately."

1:30–1:45  ANALYTICS
  Show: Wallet → Analytics
  → ₹2,190 protected this month
  → Disruption chart
  → Pool health: STRONG
  Narrate: "Every rupee accounted for.
            65% payouts. 15% reserve.
            8% Hustlr fee. 7% insurer margin.
            3% Guidewire licensing."

1:45–2:00  CLOSE
  Show: Trigger Status screen — Heat Wave ELEVATED
  Narrate: "8 triggers. 7-layer fraud engine.
            Weekly ISS repricing. Full Guidewire
            integration. Hustlr — income protection
            for every hustle."
```

---

## SUBMISSION CHECKLIST

### Code:
[ ] Flutter app pushed to GitHub (Dhruvv-16/Hustlr)
[ ] Backend code in /backend folder of same repo
[ ] requirements.txt in /backend folder
[ ] README updated with backend URL + Phase 2 deliverables
[ ] flutter build web --release passes

### Running systems:
[ ] Render backend live at /health
[ ] Flutter web deployed (Vercel or GitHub Pages)
[ ] All 4 API endpoints return correct JSON

### Demo:
[ ] 2-minute video recorded and uploaded (YouTube unlisted or public)
[ ] Video link added to README Phase 2 Deliverables
[ ] Full demo flow tested 3 times without errors

### Naming consistency (final check):
[ ] Zero "ShieldGig" anywhere
[ ] Zero "Raj" anywhere (all Karthik)
[ ] Zero "Code Crackers" (all Code Crafters)
[ ] Zero old prices (₹87, ₹125, ₹199)
[ ] Zero 2023/2024 dates
[ ] All policy numbers start HS- not SG-

### Judge requirements:
[ ] Registration flow demonstrable end to end
[ ] Policy management — all 4 plans + add-ons
[ ] Dynamic premium — live API, breakdown visible
[ ] Claims management — auto + manual + declined
[ ] Analytics dashboard
[ ] 3–5 automated triggers visible

---

## WHAT NOT TO DO ON DAY 4

❌ Do not add new features
❌ Do not redesign existing screens
❌ Do not change the data model
❌ Do not start Phase 3 work
❌ Do not spend time on things judges won't see in 2 minutes

Focus only on:
✅ Making the demo flow work perfectly
✅ Recording a clean video
✅ Pushing everything to GitHub
✅ Submitting before April 4
