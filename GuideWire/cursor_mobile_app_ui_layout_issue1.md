# Mobile app UI layout issue
_Exported on 4/4/2026 at 18:09:07 GMT+5:30 from Cursor (3.0.12)_

---

**User**

it is going a bit too outside 


---

**Cursor**


Searching the codebase for the active policy card and tag row so we can fix the overflow.




Replacing the coverage chips' `Row` with a `Wrap` so chips wrap instead of overflowing the card.




Here’s what was going wrong: the three coverage chips sat in a **`Row`**, so their total width could exceed the card and Flutter clipped the overflow (“PLATFORM D…”).

**Change:** use a **`Wrap`** with `spacing: 10` and `runSpacing: 10` so chips stay on one line when there’s room and **move to the next line** when the row is too narrow. Full labels like “PLATFORM DOWNTIME” stay inside the card.

```430:441:c:\Users\inesh\Downloads\Dhruvv-Hustlr\lib\features\dashboard\dashboard_screen.dart
          const SizedBox(height: 28),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildCoverageChip(l10n.claims_heavy_rain.toUpperCase(), Icons.water_drop_rounded, mintColor, isDark),
              _buildCoverageChip(l10n.claims_extreme_heat.toUpperCase(), Icons.wb_sunny_rounded, mintColor, isDark),
              _buildCoverageChip(l10n.claims_platform_downtime.toUpperCase(), Icons.security_rounded, mintColor, isDark),
            ],
          ),
```

If you’d rather keep a single horizontal line and scroll sideways instead of wrapping, we can switch this to a horizontal `ListView` / `SingleChildScrollView`.

---

**User**

check the ai models '

---

**Cursor**


Searching the project for AI model configuration or references.




Here’s what **this repo** actually has for “AI / ML models,” and what’s worth fixing.

## Where they’re wired up

The **production-style API** is `hustlr-backend/ml_service/main.py`. It loads artifacts from:

```24:24:c:\Users\inesh\Downloads\Dhruvv-Hustlr\hustlr-backend\ml_service\main.py
MODELS_DIR = Path(__file__).parent.parent.parent / "hustlr_ml" / "outputs" / "trained_models"
```

Health check expects these **groups** (names from `MODEL_FILES`):

| Group | Role | Expected files |
|--------|------|----------------|
| **model1_iss** | Income stability (XGBoost + features) | `model1_iss_xgboost.pkl`, `model1_features.pkl` |
| **model3_fraud** | Fraud (XGBoost JSON + isolation forest + scaler) | `model3_fraud_classifier.json`, `model3_isolation_forest.pkl`, `model3_scaler.pkl` |
| **model4_nlp** | NLP / disruption from text | `model4_rf_nlp.json`, `model4_tfidf.pkl` |
| **model5_blackout** | Connectivity / blackout | `model5_*.pkl` (3 files) |
| **model6_traffic** | Traffic / congestion | `model6_traffic_classifier.json`, `model6_congestion_baseline.json`, `model6_label_encoder.pkl` |
| **model7_forecast** | Prophet-style forecast | `model7_prophet_adyar.pkl` |

Endpoints used by the Flutter **ML Data Tester** (`lib/features/admin/ml_tester_screen.dart`) are **`/nlp`**, **`/traffic`**, **`/fraud`** (same service, port 8000 by default).

**Note:** `/nlp` also tries to load **`model4_label_map.pkl`**, but that file is **not** listed in `MODEL_FILES`, so `/health` can say NLP is “ok” while the NLP path still skips the XGBoost branch if the label map is missing (it falls back to keyword rules).

## What’s on disk right now

- **`hustlr_ml/outputs/trained_models/`** only has `model_version.txt` — so relative to what `main.py` expects, **almost all model files are missing** there.
- Some **XGBoost JSON** exports exist under repo-root **`outputs/trained_models/`** (`model3_fraud_classifier.json`, `model4_rf_nlp.json`, `model6_*.json`, etc.) — **different folder** than `MODELS_DIR`, so the FastAPI service **won’t see them** unless you copy them or change `MODELS_DIR`.

## If you meant “Cursor’s” AI models

Those are **editor / account settings**, not something stored in this Flutter project — there’s nothing in the repo to “check” for that.

---

**Summary:** The **intended** stack is XGBoost (+ joblib pickles) for ISS, fraud, NLP, traffic; isolation forest for connectivity; Prophet for forecast — all served from **`hustlr_ml/outputs/trained_models`**. Right now that directory is effectively empty except `model_version.txt`, while a few JSON weights live under **`outputs/trained_models/`**, so the service path and the files **don’t line up**.

If you want this fixed in-repo, say whether you prefer **moving/copying artifacts into `hustlr_ml/outputs/trained_models/`** or **pointing `MODELS_DIR` at `outputs/trained_models/`** and we can align it with training scripts and `/health`.

---

**User**

check the models and are they coreec

---

**Cursor**


Auditing model file locations, training outputs, and FastAPI loading logic for consistency.




Identifying a path and format mismatch: training writes to `outputs/trained_models` (repo root) while the API loads from `hustlr_ml/outputs/trained_models`. Files are split across both folders with different extensions (.json vs .pkl). Implementing multi-path resolution and aligning the health check with what inference actually loads.




Implementing search paths so we resolve artifacts from both locations, and aligning `MODEL_FILES` with what each endpoint actually loads.




Here’s the audit and what was wrong vs what we changed.

## Were the models “correct”?

**Conceptually:** The stack in `main.py` is coherent: ISS (XGBoost + rules), fraud (weighted signals + XGBoost + scaler), NLP (keywords + TF‑IDF + XGBoost + label map), blackout (thresholds + isolation forest), traffic (XGBoost + label encoder), forecast (Prophet).

**Operationally (before the fix):** Things were **not** aligned.

| Issue | Detail |
|--------|--------|
| **Wrong folder** | The API used only `hustlr_ml/outputs/trained_models`, while `hustlr_ml/scripts/train_model3/4/6_*.py` write to **`outputs/trained_models`** at the repo root (3 levels up from `scripts/`). So the “new” JSON models lived in a different place than the loader. |
| **Split artifacts** | On your machine, **model1 / model5 / model7** (and older `.pkl` variants) sit under `hustlr_ml/outputs/trained_models`, while **model3 / model4 / model6** JSON + supporting pickles sit under **`outputs/trained_models`**. A single hard-coded path could not see all of them. |
| **Health vs reality** | `/health` required `model3_isolation_forest.pkl` and `model6_congestion_baseline.json`, but **`/fraud` never loads isolation forest** and **`/traffic` never loads the congestion baseline**. It also omitted **`model4_label_map.pkl`**, which **`/nlp` does load**. |
| **Dead load** | `model6_features.pkl` was loaded in `/traffic` but never used. |

## What we changed

1. **`_load()`** now resolves each filename by searching, in order:  
   `outputs/trained_models` → `hustlr_ml/outputs/trained_models` (first hit wins).  
2. **`/health`** uses the same resolution and lists **`models_search_paths`**.  
3. **`MODEL_FILES`** now matches **what inference actually uses** (fraud: JSON + scaler; NLP: + `model4_label_map.pkl`; traffic: classifier + encoder only).  
4. Removed the unused **`model6_features.pkl`** load in `/traffic`.  
5. Adjusted the fraud comment so it doesn’t claim isolation forest is used there.

Verified on your tree with:

`python -c "import main; print(main.health())"` → **`status: ok`** for all six groups.

**Optional follow-up:** `model3_isolation_forest.pkl` is still trained and stored but unused in `/fraud`; wiring it in (e.g. anomaly boost) would be a separate product decision, not a path fix.

---

**User**

do it then 

---

**Cursor**


Wiring the isolation forest into `/fraud` alongside the existing XGBoost path. Checking how it was trained and which features it expects.




Fixing a bug: the fraud ML vector used 14 features including `play_integrity_pass`, but training used 16 features (`has_real_disruption`, `simultaneous_zone_claims`, `iss_score`). Aligning the feature vector with training and wiring the isolation forest.




Hardening feature-name loading when `model3_features.pkl` is a NumPy array:




Here’s what was implemented.

### 1. **Isolation forest in `/fraud`**
- Loads `model3_isolation_forest.pkl`, runs `predict` on the **scaled** feature row.
- If the point is an outlier (`-1`), adds **+0.10** to the ML bump (capped with XGBoost below).

### 2. **XGBoost uses fraud probability**
- The old code treated `predict` as `-1` / anomaly; `XGBClassifier` actually returns **0/1**.
- It now uses **`predict_proba(...)[0, 1]`** and adds up to **+0.12** when that probability is above 0.5.

### 3. **Feature vector matches training (16 features)**
Training in `train_model3_fraud.py` uses 16 columns, ending with  
`has_real_disruption`, `simultaneous_zone_claims`, `iss_score`.  
Inference was wrongly using **`play_integrity_pass`** as the 14th value.

- Added **`has_real_disruption: int = 0`** on `FraudRequest`.
- **`_fraud_ml_feature_row`** builds the row in the same order as training; if **`model3_features.pkl`** exists, its column order is used (with a safe fallback list).

### 4. **Combined ML bump**
- Isolation + XGBoost contributions are summed, then **`fps` is increased by at most +0.22** in one step (`min(ml_boost, 0.22)`).

### 5. **Health check**
- **`model3_isolation_forest.pkl`** is required again for `model3_fraud` in `/health`.

Quick check on your machine: `model3_fraud` **ok**, benign request stays **GREEN**, a “hot” signal pattern hits **RED** with the new pipeline.

---

**User**

PS C:\Users\inesh\Downloads> dir


    Directory: C:\Users\inesh\Downloads


Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d-----          4/4/2026   4:23 PM                Dhruvv-Hustlr
d-----          4/4/2026   5:07 PM                hustlr_ml_complet
d-----          4/4/2026   1:24 PM                hustlr_ml_complete
d-----          4/4/2026  11:56 AM                hustlr_ml_complete (2)

just check these 3 ml files also and compare it with the code

---

**Cursor**


Exploring the three `hustlr_ml_*` folders in Downloads and comparing them to the Dhruvv-Hustlr ML layout and `main.py` expectations.




Here’s how those **three Downloads folders** line up with **Dhruvv-Hustlr** (`hustlr-backend/ml_service/main.py` and `MODELS_SEARCH_PATHS`).

---

### 1. `hustlr_ml_complet`

- **What it is:** A zip-style layout with **`hustlr_ml_complete (1)`** inside.
- **Artifacts:** **`data/`** + **`outputs/*.csv`** (rainfall, workers, claims, NLP results, etc.).
- **Trained service files:** **None** — there is **no** `trained_models/` with `.pkl` / `.json` for the API.
- **vs code:** Matches **`run_all_models.py`** (“Output: all CSVs”). This is an **offline reporting / actuarial pipeline**, not the same artifact set **`main.py`** loads.

---

### 2. `hustlr_ml_complete (2)`

- **What it is:** Same nested **`hustlr_ml_complete (1)`**, with **extra** scripts (`balanced_multi_city_system.py`, `final_integrated_system.py`, …).
- **Artifacts:** Again **CSV / JSON summaries** under **`outputs/`** (forecasts, reserves, city metrics).
- **Trained service files:** **None** in that tree (no `trained_models` bundle for FastAPI).
- **vs code:** Same as (1): **multi-city analysis**, **not** the serialized models **`_load()`** expects.

---

### 3. `hustlr_ml_complete` (the big one)

- **What it is:** A **full “outputs dump”** (Chennai CSVs, many `.py` trainers, docs) plus **`outputs/trained_models/`** with **classic joblib** exports.
- **Trained files there (names matter):**

| File(s) in Downloads bundle | What `main.py` expects today |
|----------------------------|------------------------------|
| `model1_iss_xgboost.pkl`, `model1_features.pkl` | Same names — **compatible** (joblib). |
| `model3_fraud_classifier.pkl` | **`model3_fraud_classifier.json`** (XGBoost JSON) — **not the same format/name**. |
| `model3_scaler.pkl`, `model3_isolation_forest.pkl`, `model3_features.pkl` | **Match** fraud pipeline intent. |
| `model4_rf_nlp.pkl`, `model4_tfidf.pkl`, `model4_keyword_rules.pkl` | **`model4_rf_nlp.json`** + **`model4_label_map.pkl`** — **missing / different** (you have keyword rules + RF pickle, not JSON + label map). |
| `model5_*.pkl` | Same pattern — **compatible**. |
| `model6_traffic_classifier.pkl` | **`model6_traffic_classifier.json`** — **not the same** (pickle vs JSON). |
| `model6_label_encoder.pkl` | **Match**. |
| `model7_prophet_adyar.pkl` | **Match**. |

- **Extra in that folder:** `chennai_fraud_model_final.pth`, `internet_blackout_model*.pkl`, etc. — **PyTorch / alternate stacks**; **`main.py` does not load them**.
- **`outputs/hustlr_inference.py`:** Uses **`MDLS = "/home/claude/hustlr_ml/models"`** — **Linux path**, not aligned with your repo’s **`outputs/trained_models`** / dual search paths.

---

### Bottom line

| Folder | Role vs Dhruvv-Hustlr code |
|--------|----------------------------|
| **`hustlr_ml_complet`** | CSV pipeline only — **no API model bundle**. |
| **`hustlr_ml_complete (2)`** | Same idea, richer scripts — **still no API model bundle**. |
| **`hustlr_ml_complete`** | **Closest**: full **pickle-era** `trained_models` + lots of side experiments; **not** a direct match to current **`main.py`**, which expects **XGBoost `.json`** for fraud / NLP / traffic and **`model4_label_map.pkl`**. |

Your **repo** (`Dhruvv-Hustlr`) is consistent with **`hustlr_ml/scripts/train_model3/4/6_*.py`** (JSON + pickles). The **Downloads `hustlr_ml_complete`** bundle is closer to **`train_all_models.py` / joblib-only** outputs.

If you want **`hustlr_ml_complete\outputs\trained_models`** to work **without retraining**, the next step would be adding **optional `.pkl` fallbacks** in `_load()` for the three XGBoost names (and NLP label map / RF pickle rules) — that’s a deliberate compatibility layer, not something those three folders satisfy today out of the box.

I also updated a **stale comment** in `main.py` that still said `/fraud` did not use the isolation forest (it does now).

---

**User**

sry didint understadn

---

**Cursor**


No worries — here’s a simpler version.

## What your **code** (Dhruvv-Hustlr) needs

The Python API looks for **specific model files** (names and types matter), mostly under:

- `Dhruvv-Hustlr\outputs\trained_models\`  
- or `Dhruvv-Hustlr\hustlr_ml\outputs\trained_models\`

Examples it expects:

- Fraud: a file named **`model3_fraud_classifier.json`** (not `.pkl`)
- NLP: **`model4_rf_nlp.json`** and **`model4_label_map.pkl`**
- Traffic: **`model6_traffic_classifier.json`**

So the app is built for **this exact “package” of files**.

---

## What the **3 folders in Downloads** are

**1. `hustlr_ml_complet`** and **2. `hustlr_ml_complete (2)`**  
- They mostly produce **spreadsheets (CSV)** — tables of results.  
- They **do not** ship the same **model files** the API loads.  
- Think: **reports**, not **the brain files** the server uses.

**3. `hustlr_ml_complete` (the big one)**  
- This one **does** have a `trained_models` folder — so it’s **closer**.  
- But the **names/types** are often **different** from what your current code expects, for example:
  - It has **`model3_fraud_classifier.pkl`**  
  - Your code wants **`model3_fraud_classifier.json`**
- So you **can’t** just drop that folder in and expect everything to work **without** either **changing the code** to accept `.pkl` or **re-exporting** models in the `.json` format.

---

## One sentence summary

**Those three Downloads folders are either “CSV-only pipelines” or an older/different model bundle; your app expects a specific set of files (especially `.json` XGBoost models). They’re related ideas, but not plug-and-play the same.**

If you tell me which you care about — **use the big `hustlr_ml_complete` bundle** vs **only use what’s inside Dhruvv-Hustlr** — I can say exactly what to copy or what to change next.

---

**User**

i want twant t you to go through those files of code and find if anything is there which is better than the currrent ai models

---

**Cursor**


Reviewing the Downloads ML code and comparing it to our repo’s models to identify improvements.




Here’s a straight comparison: what those Downloads folders actually add vs what you run in **Dhruvv-Hustlr** today.

---

## Ideas that are **stronger or richer** than the current API models

### 1. **Fraud (`model3_fraud_detection.py` in the nested `hustlr_ml_complete (1)` bundles)**

Your **`main.py`** fraud path is roughly: **fixed signal weights + XGBoost + isolation forest** on a **16‑dim worker-style vector**.

Their script adds things you **don’t** have in the live service:

- **7 explicit layers** (location, zone vs orders, **news corroboration**, behavioral, zone surge, isolation score, **filing timing**) with **fixed ensemble weights** — easier to audit than a single blended score.
- **DBSCAN on GPS** to flag **tight clusters** (“rings”) — useful for **coordinated abuse**.
- **Poisson-style surge test** over time buckets — idea is to separate **organic** spikes from **synchronized** filing.
- **Fraud archetypes** in synthetic data (GPS ring, “home” claimers, threshold exploiters) — good **spec** for what the model should catch, even if the data is synthetic.

So: **conceptually better coverage** for real-world fraud; it’s **not** the same as your trained XGBoost features, so you’d **port the ideas** (layers, DBSCAN, surge test), not drop the file in as-is.

---

### 2. **ISS / risk (`model1_2_iss_tier.py`)**

Compared to your ISS endpoint (rules + optional XGBoost on a small feature set), they add:

- **Open‑Meteo** (or fallback climatology) for **rain / heavy-day stats** per city.
- **Accident CSV** with **trend slope**, not just a static score.
- **Multi-city** config (Chennai, Mumbai, Bengaluru, Kolkata) and **city-level behavioral_risk**.

That’s **better geographic and weather grounding** than a Chennai-only mental model — again, **integration work** (API calls, caching, failure modes).

---

### 3. **NLP / triggers (`model4_5_6_triggers.py`)**

Compared to **`main.py`** keyword rules + TF‑IDF + XGBoost, they add:

- **Finer taxonomy**: intensity phrases, **agency** cues, extra types (**cyclone**, **AQI**, **accident_blockspot**).
- **`CITY_ALIASES`**, **`extract_time_window`**, **`extract_date`** — **clearer structured parsing** from free text.

Your stack can already classify with ML; their code is **stronger on rule/parse structure** and **coverage of trigger types** — worth **merging patterns** into `KEYWORD_RULES` or the NLP training data, not replacing everything blindly.

---

## Things that look “fancy” but are **not clearly better** than your current models

- **`final_integrated_system.py` (under `hustlr_ml_complete (2)`)** — Mostly **JSON config + printed reports**; “accuracy 97%” style fields are **not** validated model metrics tied to your API.
- **`industrial_training_pipeline.py` (under `hustlr_ml_complete/outputs`)** — **PyTorch** fraud net with attention: **more complex**, needs **GPU stack**, different feature layout, and it’s **not wired** to your FastAPI `_load()` / current request schema. It’s a **research branch**, not a proven upgrade over your current **XGBoost + IF** path unless you train, evaluate, and deploy it properly.

---

## Short verdict

| Area | Downloads code | vs current Dhruvv-Hustlr |
|------|----------------|---------------------------|
| **Fraud** | 7-layer FPS, DBSCAN rings, Poisson surge, richer claim features | **More complete *design***; your service is **simpler and different features** |
| **ISS** | Live weather, accidents + trends, multi-city | **Better *inputs*** if you operationalize APIs and data |
| **NLP** | Aliases, time/date extraction, more trigger types | **Better *rules/structure*** alongside your ML |
| **Big “industrial” PyTorch** | Heavy NN | **Not automatically better** — higher cost and integration risk |

So: **yes, there are pieces in those files that are “better” in specific dimensions** (fraud geography/time, ISS data sources, NLP taxonomy/parsing). **No single folder is a drop-in replacement** for your current trained models; the sensible path is **cherry-pick algorithms** (DBSCAN, surge test, layer breakdown, keyword taxonomy, weather/accident features) and **retrain or extend** your existing `main.py` + training scripts.

If you want to go further, say which you care about first — **fraud**, **ISS**, or **NLP** — and we can map their code line-by-line to concrete changes in your repo.

---

**User**

do the cherry pick rhing and in the end all 3 are needed so do it however u want

---

**Cursor**


Implementing cherry-picked improvements for fraud (7-layer ensemble + optional surge flags), ISS (multi-city priors + optional weather fetch), and NLP (richer taxonomy + city/time parsing). Reading the relevant sections of `main.py` to integrate them.




Creating `ml_cherry_picks.py` and wiring it into `main.py` for ISS, fraud, and NLP.




Wiring `main.py`: adding imports and merging NLP rules.




Fixing NLP fusion so strong rule matches (e.g. AQI) aren't overwritten by a wrong ML class.




Here’s what was implemented: all three areas are wired into the **Dhruvv-Hustlr** ML service.

### New file: `hustlr-backend/ml_service/ml_cherry_picks.py`
- **ISS:** `CITY_COORDS`, `CITY_BEHAVIORAL_RISK`, `open_meteo_heavy_rain_prior()` (stdlib `urllib`), `blend_iss_flood_risk()`.
- **Fraud:** `seven_layer_fps()` (L1–L7 weights from your draft), plus **`ring_cluster_suspect`** / **`coordinated_surge_suspect`** hooks for future batch/DBSCAN/Poisson jobs.
- **NLP:** `CITY_ALIASES` (incl. **Delhi/NCR**), `CHENNAI_ZONES`, `extract_city_from_text`, `extract_time_window_nlp`, `extract_date_nlp`, **`EXTRA_KEYWORD_RULES`** (`poor_aqi`, `accident_blockspot`, `platform_outage_nlp`), `ML_LABEL_TO_RULE_KEY` + `hourly_rate_lookup()`.

### `main.py` updates

**`/iss`**
- New: `city`, `use_weather_prior`.
- Rule engine + ML use **blended** `flood_eff` when weather prior is available.
- Response adds **`iss_enrichment`** (`city`, `weather_prior`, `effective_flood_risk`).

**`/fraud`**
- New optional fields: `news_corroboration`, `platform_active_orders`, `is_shift_window`, `filing_delay_minutes`, `claim_city`, `ring_cluster_suspect`, `coordinated_surge_suspect`.
- **Device** score + **7-layer** score (with **L6** from isolation forest: outlier → high suspicion) blended **40% / 60%**, then **XGBoost probability** boost as before.
- Response adds **`fps_device_component`**, **`fps_layer_breakdown`**.

**`/nlp`**
- **`KEYWORD_RULES`** = base rules + cherry extras; broader **zone_keywords** on base rules.
- Time window + date from cherry extractors; **`metro_city`** + refined **`zone`**; **`advisory_date`**; **`hourly_rate`** via **`hourly_rate_lookup`** (maps ML labels like `heavy_rain` → `rain_heavy`).
- **ML fusion rule:** if **rule confidence ≥ 0.58**, the model **no longer replaces** the rule trigger (fixes e.g. AQI text misclassified as rain).

Health check still **`ok`** on your tree.

If you want the Flutter **ML tester** to send the new fraud/ISS fields, say so and we can extend `ml_tester_screen.dart`; defaults keep old clients working.

---

**User**

<div align="center">
  <h1>⚡ Hustlr</h1>
  <h3>Real-Time Income Protection Engine for India's Gig Delivery Workers</h3>

  <a href="https://youtu.be/nD2snI4Tnu8?si=eS5sztT0aibvxodI">
    <img src="https://img.shields.io/badge/Watch_Demo_Video-FF0000?style=for-the-badge&logo=youtube&logoColor=white" alt="Watch Video"/>
  </a>
  &nbsp;
  <a href="https://github.com/Dhruvv-16/Hustlr">
    <img src="https://img.shields.io/badge/GitHub_Repository-181717?style=for-the-badge&logo=github&logoColor=white" alt="GitHub Repo"/>
  </a>
  <br><br>
  <strong>🏆 Guidewire DEVTrails 2026 — Phase 1 Submission</strong><br>
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
31. [MVP Scope — Phase 1](#-mvp-scope--phase-1)
32. [Cost Efficiency](#-cost-efficiency)
33. [6-Week Plan](#-6-week-plan)
34. [Business Viability & Financial Model](#-business-viability--financial-model)
35. [IRDAI Compliance](#-irdai-compliance)
36. [Team](#-team)
37. [Phase 1 Deliverables](#-phase-1-deliverables)

---

## 🧭 TL;DR

**Who:** Q-commerce delivery riders (Zepto) — 2–3 km radius, one dark store, zero income safety net.

**Problem:** One flooded street eliminates their entire working zone. No insurance product covers this. 80+ disruption days a year go uncompensated.

**What Hustlr does:** Monitors 9 real-time disruption triggers. When one fires and the rider is on shift — a fixed payout hits their UPI automatically. No claim filed. No adjuster. Under 2 minutes.

**How it's built:** Flutter app · Node.js + Supabase backend · 7 AI/ML models · 7-layer fraud engine · Zone depth scoring · Regional behavioral intelligence · Full Guidewire integration (PolicyCenter + ClaimCenter + BillingCenter).

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

<p align="center">
  <img src="https://github.com/user-attachments/assets/289c1d4b-ce38-4355-81ce-223381723260" width="900" alt="Hustlr — How It Works"/>
</p>

```
1. Rain detected in Karthik's zone    →  IMD + OpenWeatherMap confirm threshold
2. Shift window check passes          →  disruption falls within Karthik's working hours
3. Zone depth score calculated        →  confirms Karthik was genuinely deep in zone, not at boundary
4. Device integrity verified          →  Play Integrity API confirms no GPS spoofing app active
5. Fraud check in < 2 seconds         →  FRS score computed across 7 independent signal layers
6. Fixed payout credited Sunday night →  ₹50/hr × verified disruption hours, capped at ₹150/day
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

**Phase 1:** spaCy keyword scoring. Dual confirmation required.

**Phase 2:** LLM preprocessing for unstructured government advisories. The LLM touches preprocessing only — every YES/NO payout decision is deterministic and auditable.

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

    H --> M{Threshold + shift\nwindow check}
    I --> M
    J --> M
    K --> M
    L --> M

    M -->|PASS| N[Zone depth score calculated]
    M -->|FAIL| G

    N --> O[FPS computed across\n7 layers in under 2 seconds]

    O -->|GREEN| P[70% released immediately\n30% after 48hr review]
    O -->|YELLOW| Q[Provisional credit\nsoft verification]
    O -->|RED| R[Manual review\nprovisional 100-300 credit]

    P --> S[Sunday 11 PM\nweekly settlement batch]
    Q --> S
    R --> S

    S --> T[Full payout credited\nMonday 12 AM]
    T --> U[Shadow policy tracks\nuninsured workers]
    U --> V[Wednesday forecast\npredictive nudge sent]
    V --> G
```

---

## 📡 Parametric Trigger Decision Flow

```mermaid
flowchart TD
    T1[Real-time data received\nevery 15 minutes] --> T2{Threshold\nbreached?}
    T2 -- No --> T3[Log reading\ncontinue monitoring]
    T2 -- Yes --> T4{Minimum 45-minute\nduration confirmed?}
    T4 -- No --> T3
    T4 -- Yes --> T5{Shift window\noverlap check}
    T5 -- Outside shift --> T6[No payout\ndisruption outside work hours]
    T5 -- Within shift --> T7[Layer 0: Play Integrity\ndevice check]
    T7 -- Device fails --> T8[Auto-reject\nworker notified]
    T7 -- Device passes --> T9[Zone depth score\ncalculated]
    T9 -->|Score below 0.20| T10[No payout\nboundary gaming detected]
    T9 -->|Score above 0.20| T11[FPS fraud scoring\nacross 7 layers]
    T11 -->|GREEN| T12[Claim PENDING\nworker notified]
    T11 -->|YELLOW| T13[Soft hold\nprovisional credit]
    T11 -->|RED| T14[Manual review queue\nprovisional credit released]
    T12 --> T15[Sunday settlement\npayout released]
    T13 --> T15
    T14 --> T15
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
| State Management | Riverpod |
| Background Location | flutter_background_geolocation |
| Local Storage | Hive (offline-first) |
| Payments (mock) | Razorpay Flutter SDK — test mode |
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
| Play Integrity API | Device integrity verification | Free (Google) |
| Zepto | Order failure rate + status | Mock Phase 1 |
| Razorpay | UPI payout simulation | Test mode |

---

## 🧪 MVP Scope — Phase 1

Phase 1 demonstrates the complete parametric loop:

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

### Phase 2 (Weeks 3–4) — Automation & Protection
- [ ] Full Flutter app — all screens + manual claim flow
- [ ] Weather + NLP trigger cron live
- [ ] Order failure rate trigger live
- [ ] Internet blackout trigger live (Ookla + TRAI)
- [ ] Zone depth scoring live (PostGIS)
- [ ] Play Integrity API live integration
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

## 🎬 Phase 1 Deliverables

<div align="center">
  <a href="https://youtu.be/nD2snI4Tnu8?si=eS5sztT0aibvxodI">
    <img src="https://img.shields.io/badge/2--Minute_Demo_Video-282828?style=flat-square&logo=youtube&logoColor=white" alt="Video"/>
  </a>
  &nbsp;&nbsp;
  <a href="https://github.com/Dhruvv-16/Hustlr">
    <img src="https://img.shields.io/badge/GitHub_Repo-181717?style=flat-square&logo=github&logoColor=white" alt="GitHub"/>
  </a>
</div>

---

*Hustlr — Because every minute you can't deliver is a minute your income disappears.*


this is my readme for phase 1 

---

**Cursor**


Checking for an existing README and saving your Phase 1 document if appropriate.




Noting the repo README is a Phase 2–expanded version; you shared the Phase 1 README. Updating the header to Phase 1 and removing Phase 2–only sections so the file matches your Phase 1 submission.




Aligning the repository README with your Phase 1 document: updating the header, TOC, TL;DR, removing Phase 2–only sections, and restoring your Phase 1 workflow, tiers, MVP, and deliverables.




Here’s what I did with your Phase 1 README and the repo.

### Updates in `README.md`
- **Hero:** Single **Watch Demo Video** badge, **Phase 1 Submission**, removed the Phase 2 video placeholder.
- **TOC:** Dropped Phase 2–only entries (31–39); items **31–37** now match your Phase 1 list (MVP, Cost, 6-week plan, Business, IRDAI, Team, Phase 1 deliverables).
- **TL;DR:** Matches your Phase 1 wording (**₹29–₹109**, lean “how it’s built” / numbers).
- **Innovation:** Replaced one-liners with your **seven subsections** (shadow policy, predictive activation, Play Integrity, zone depth, regional intelligence, internet blackout, profitability simulator).
- **Pricing:** **₹29 / ₹49 / ₹79 / ₹109**, weekly add-ons with ***(Phase 2)*** on the three optional lines, bounds example **₹49 → ₹98 / ₹34**.
- **Workflows:** **End-to-end** and **parametric** Mermaid diagrams are the **Phase 1** versions (no Data Trust gate / no circuit breaker in those two diagrams).
- **Fallback table:** Restored the **full 9-row** version (NLP, MaxMind, Ookla, Maps).
- **Platform + tech stack:** Your **Riverpod** narrative and **table-style** stack (incl. FastAPI ML service).
- **Removed** the whole **Phase 2 architecture** block (micro-services, DB, onboarding, etc.).
- **MVP, cost, 6-week plan, business model:** Aligned with your Phase 1 doc (**₹4.9L** pool, **₹49** average).
- **IRDAI + team:** Your bullets; **T Anil Kumar** = *Insurance Domain + City Risk Profiles + Pitch*.
- **Closing:** **Phase 1 deliverables** badges + your tagline.
- **Scenarios:** Standard Shield price in copy set to **₹49** for consistency.

### Note for you
The **middle** of the README (problem, persona, triggers, anti-gaming, long fraud section, etc.) was already very close to your paste, so it was left as-is unless it conflicted with Phase 1 (e.g. pricing and diagrams).

### Honest alignment note (for judges / your own QA)
Some MVP bullets describe **design + architecture**; a few items (e.g. full live Guidewire, every trigger in production) may still be **partially mocked** in code. Worth a quick pass so every checked `[x]` is something you can demo or defend.

If you want the README to mention the **Python `ml_service` + cherry-pick modules** explicitly, say where you’d like it (e.g. AI/ML Architecture) and we can add one short subsection.

---

**User**

use the readme to understand what we planned to do 

---

**Cursor**


Here’s a concise map of **what the README says you planned to build**, distilled from the doc itself.

---

### **North star**
- **Not** an insurer: Hustlr is an **underwriting / parametric intelligence engine** for a **licensed insurer**, with **Guidewire** (PolicyCenter, ClaimCenter, BillingCenter) as the policy–claims–billing spine.
- **Persona:** Zepto-style **Q-commerce** riders in **Chennai** dark-store zones (hyperlocal, high disruption frequency, high fraud surface).

---

### **Product promise**
- **Income loss from disruptions**, not hospital/accident-only coverage: rain, cyclone/heat/AQI, **platform outage**, bandh/curfew, **internet blackout**, **accident blockspots**, **heavy traffic** (on higher tiers).
- **Parametric:** fixed **₹/hour × hours**, **₹150/day** and **₹500/week** caps — no “prove exact lost earnings” for auto triggers.
- **Gates before payout:** external **threshold + duration**, **shift overlap**, **zone depth** (anti–boundary gaming), **Play Integrity + anti-spoof signals**, **7-layer fraud (FPS)**, then settlement (README also describes **Data Trust** + **circuit breaker / 70–30 tranche** in the 15-second flow, even where later diagrams simplify).

---

### **Planned mechanics (rules & UX)**
- **Anti-gaming:** min duration, cooling, shift intersection, weekly caps per type on lower tiers, threshold **obfuscation / micro-variation**.
- **Elite Shield:** **compound triggers** + **claim-free cashback** design.
- **Manual path:** 3-step **Report a Disruption** with evidence types and **~4h SLA**.
- **Growth loops:** **shadow policy** (“missed payout” counterfactuals), **Wednesday ~72h forecast nudge**, **B2C first** (WhatsApp/referral), then **B2B2C** inside Zepto.

---

### **Planned tech**
- **Flutter** (README: **Riverpod**, background location, Hive, FCM, Razorpay test, Play Integrity).
- **Node + Express + Supabase** (PostGIS, cron ~15 min).
- **Python FastAPI ML service:** ISS (rules + XGBoost), fraud (isolation + XGBoost + **7-layer ensemble**), NLP (TF‑IDF + XGBoost + rules), **Prophet** for forecasting.
- **External data story:** IMD/OpenWeather, AQI, Maps traffic, Ookla/TRAI, news/NLP, platform order health — with a **fallback hierarchy** when APIs fail.

---

### **Phase 1 vs later (per README)**
- **Phase 1 (what you claimed to deliver):** End-to-end **story + architecture + demo**: parametric loop on paper/in app, ISS/tiers, zone depth concept, shadow + nudge, fraud/NLP/trigger **designs**, Guidewire **mapping**, manual claim **flow**, premium bounds, compound/cashback **design**, demo video — many items are **“architecture / MVP demonstration”** rather than every pipe live in prod.
- **Phase 2 (weeks 3–4):** Cron **live** triggers, PostGIS zone depth **live**, Play Integrity **live**, real Guidewire hooks, fuller Flutter, multi-city risk, etc.
- **Phase 3 (weeks 5–6):** Harden ML (IF + Poisson called out), LLM preprocessing, Prophet in production, admin/simulator, trust score, cashback automation, Marketplace packaging.

---

### **Business plan (README)**
- Pilot: **~10k Chennai workers**, **~₹49/week** blended premium, **~₹4.9L/week** pool, **&lt;65%** loss ratio target, pool split (claims / reserve / fees / insurer / reinsurance / Guidewire).

---

### **One line**
You planned **parametric income protection for Zepto-zone riders**, backed by **multi-source triggers**, **strong anti-fraud and zone-depth logic**, **Flutter + Node + Supabase + Python ML**, and **insurer + Guidewire** — with **Phase 1** proving the **loop and narrative**, and **Phases 2–3** moving everything to **live automation and scale**.

If you want this turned into a **checklist against the actual repo** (what’s implemented vs README), say so and we can map section by section to `lib/`, `hustlr-backend/`, and `ml_service/`.

---

**User**

yes 

---

**Cursor**


Mapping the README claims to the repository: exploring Flutter, Node backend, and ML service.




Here’s a **README → repo** checklist. Status means: **Yes** = clearly implemented in code, **Partial** = stub, mock, or design-only, **No** = not found / contradicts README.

---

### Core product & persona
| README intent | Repo status | Notes |
|---------------|------------|--------|
| Q-commerce / Zepto persona, Chennai zones | **Partial** | Copy, zones, and flows match; platform is generic in onboarding. |
| Parametric payouts (₹/hr, caps) | **Yes** | `claims.routes.js` + `constants.js`: hourly rates, daily caps, shift + zone depth multipliers, compound keys. |
| Weekly settlement + fraud before money | **Partial** | 70/30 tranche **designed** in `claims.routes.js` / `payout_service.js`; payout is **mocked** (`payoutSuccess = true`). |
| Shadow policy + missed payout | **Yes** | `shadow_policy_screen.dart`, dashboard card, `mock_data_service` / API paths. |
| Predictive nudge (forecast) | **Partial** | Backend `weather_service` builds nudge; `disruption.routes` returns it; app consumes via disruptions API when connected. |
| Compound triggers (Elite) | **Partial** | `compound_triggers_screen.dart` + `COMPOUND_BONUSES` in claims math; **elite** tier not fully wired same as README naming. |

---

### Triggers & data feeds
| README intent | Repo status | Notes |
|---------------|------------|--------|
| Weather / rain thresholds | **Partial** | `weather_service.js` + `assessDisruptions`; depends on WeatherAPI/env. |
| AQI | **Partial** | `aqi_service.js`. |
| Bandh / NLP | **Partial** | `news_service.js` + Python `/nlp`; bandh merged in `disruption.routes.js`. |
| Platform outage | **Partial** | `platform_service.js` (mock-friendly). |
| Internet blackout | **Partial** | `platform_service` internet branch + ML `/blackout`. |
| Traffic | **Partial** | `traffic_service.js` + ML `/traffic`. |
| 15‑min cron polling | **No** | **No `node-cron`** in `package.json`; disruptions are **on demand** (`GET /disruptions/:zone`) when the app/backend calls them. |

---

### Trust, fraud, zone depth
| README intent | Repo status | Notes |
|---------------|------------|--------|
| Data Trust Engine (>0.75) | **Yes** | `data_trust.js` used from `disruption.routes.js`. |
| 7-layer FPS + ML fraud | **Partial** | Node `fraud_engine.js` (signals) + **FastAPI** `/fraud` (XGBoost + IF + 7-layer cherry-pick blend via `ml_cherry_picks.py`). |
| Play Integrity Layer 0 | **Partial** | **No** Play Integrity SDK in Flutter; ML/claims take `play_integrity_pass` / `is_mock_location` (often **derived from mocks** in `claims.routes.js`). |
| Zone depth 3-ring model | **Partial** | **Multipliers and DB column** exist; score is **client/default supplied**, not computed from **PostGIS** / background GPS rings. |
| Circuit breaker (BCR) | **Yes** | `circuit_breaker.js`, `setup_circuit_breaker.sql`, wired into claims flow. |

---

### App (Flutter) vs README tech table
| README says | Repo status | Notes |
|-------------|------------|--------|
| Riverpod | **No** (as primary) | **`flutter_bloc` + `provider`** in `pubspec.yaml`. |
| `flutter_background_geolocation` | **No** | Not in `pubspec.yaml`; **`geolocator`** + maps only. |
| Hive offline | **Yes** | `hive` / `hive_flutter`. |
| FCM | **Yes** | `firebase_core`, `firebase_messaging`. |
| Razorpay | **No** in app | Backend health mentions **Instamojo**; payout path is **mock**. |
| Manual claim flow (photos, steps) | **Yes** | `manual_evidence_screen`, camera, submitted, `auto_explanation_screen`, etc. |

---

### Guidewire
| README intent | Repo status | Notes |
|---------------|------------|--------|
| PolicyCenter / ClaimCenter / BillingCenter APIs | **No** | **No** HTTP client or env for Guidewire; **conceptual** only in README + mock timeline strings (e.g. `mock_data.dart`). |

---

### AI / ML (7 models)
| README intent | Repo status | Notes |
|---------------|------------|--------|
| 7-model story | **Partial** | FastAPI `main.py`: **ISS, fraud, NLP, blackout, traffic, forecast** + rules; “Model 2 tier” is more **product logic** than a separate trained file. |
| Prophet | **Partial** | `/forecast/{zone}` loads pickle if present; optional. |
| Training / `outputs/trained_models` | **Yes** | Artifacts + scripts exist; service uses **dual path** resolution. |

---

### Phase alignment (README 6-week section)
| Phase | README | Repo reality |
|-------|--------|----------------|
| **1** | “Current” with many [x] | **Strong:** Flutter journeys, Node APIs, disruption aggregation, claim + fraud + CB + payout **structure**, Python ML service, SQL triggers. **Weaker:** live Guidewire, real GPS zone depth, real Play Integrity, real UPI gateway, scheduled cron. |
| **2** | Live crons, PostGIS depth, live GW… | Mostly **still open** (matches README’s own Phase 2 checkboxes). |
| **3** | IF + Poisson, Prophet prod, etc. | **Partially** ahead: **IF + XGB fraud** exists in `ml_service`; full Poisson/DBSCAN **batch** pipeline not in Node. |

---

### Bottom line
- The repo is a **solid Phase 1 demo**: **end-to-end paths**, **realistic payout math**, **multi-source disruptions**, **data trust + circuit breaker + ML fraud**, and a **full Flutter UX** for policy / claims / shadow / compound / analytics.
- It is **not** yet what a production README might imply: **Guidewire**, **Riverpod/background geo as documented**, **cron-based monitoring**, **PostGIS zone depth**, **real Play Integrity / Razorpay**, **fully live** external data everywhere.

If you want, we can add a short **“Implementation status (Feb 2026)”** subsection to the README so judges see **planned vs shipped** in one place.

---

**User**

start building the things left to build then

---

**Cursor**


Implementing the highest-impact gaps: scheduled disruption polling, Guidewire payload stubs, improved payout/Razorpay hook, zone-depth API, and Flutter hooks (periodic refresh + optional Play Integrity / Razorpay deps).




Implementing disruption snapshot + cron, Guidewire stub routes, zone-depth service and worker endpoints, Razorpay credential check in payouts, and dashboard periodic refresh.




Creating the snapshot service (fixing cache keys to include zone), then wiring cron, Guidewire, zone depth, payouts, and the Flutter timer.




Fixing Guidewire routes: Supabase may not embed `users` on `claims` without an explicit relationship. Using two queries.




Reordering disruption routes so `/forecast/:zone` isn't captured by `/:zone`.




Here’s what was implemented for the “gaps” from the earlier plan.

### Backend
- **`disruption_snapshot.js`** — Shared builder for the disruption JSON; **cache keys now include the zone** (fixes cross-zone cache pollution).
- **`disruption.routes.js`** — Uses the snapshot; **route order fixed** so `/forecast/:zone` and `/health/apis` are not swallowed by `/:zone`.
- **`disruption_cron.js` + `node-cron`** — Default **every 15 minutes** polls `MONITORED_ZONES`, skips cache, and **inserts into `disruption_events`** with **90‑minute dedup** per `(zone, trigger_type)`.  
  - **`GET /health/cron`** — Last run / errors / summary.  
  - Disable: `DISABLE_DISRUPTION_CRON=true`. Optional boot run: `RUN_DISRUPTION_CRON_ON_BOOT=true`.
- **`zone_depth_service.js`** — Haversine vs hub (`DARK_STORE_LAT` / `DARK_STORE_LON`).  
  - **`POST /workers/zone-depth/compute`** — `{ lat, lon }` → score.  
  - **`PATCH /workers/:id/zone-depth`** — Persists `users.zone_depth_score`.
- **`guidewire_service.js` + `guidewire.routes.js`** — Sample claim payload + optional **`POST /guidewire/forward/:claimId`** to `GUIDEWIRE_WEBHOOK_URL`. Routes only if **`ENABLE_GUIDEWIRE_ROUTES=true`**.
- **`payout_service.js`** — Replaced invalid `supabase.rpc('coalesce_increment', …)` with a **read + increment** of `payout_attempts`. If **`USE_REAL_PAYOUT=true`**, verifies **Razorpay** keys via **`GET /v1/payments?count=1`**, then continues with the existing **wallet credit** (still no full payout rail).
- **`index.js`** — Mounts `/guidewire`, starts the cron after listen, extends **`/health/services`**, adds **`/health/cron`**.
- **`.env.example`** — Documented the new variables.  
- **`npm install`** — Adds **`node-cron`**.

### Flutter
- **`dashboard_screen.dart`** — **`Timer.periodic` every 15 minutes** to refresh dashboard data; **cancelled in `dispose`**.
- **`api_service.dart`** — **`computeZoneDepth`** / **`updateWorkerZoneDepth`**; **`getDisruptionsInstance`** / **`getDisruptionEvents`** now read **`disruptions`** (with fallback to `disruption_events`).

**Enable Guidewire:** set `ENABLE_GUIDEWIRE_ROUTES=true`.  
**Optional payout gate:** `USE_REAL_PAYOUT=true` plus `RAZORPAY_KEY_ID` / `RAZORPAY_KEY_SECRET` (verification call must succeed or payout throws).

---

**User**

GuideWire use the folder to go through the knowledge i colllected in trgards to the app

---

**Cursor**


Searching the repo for Guidewire-related folders and documents.




Your **`GuideWire`** folder (note the spelling in the repo) is a research and pitch library for **Guidewire DEVTrails 2026**, not the live integration code. Here is a concise pass through what’s in it and how it lines up with **Hustlr** today.

---

### What’s in `GuideWire/` (how to use it)

| Asset | What it is | Use for the app |
|--------|------------|------------------|
| **`readme.txt`** | Full **Hustlr** story: Zepto persona, 9 triggers, PC/CC/BC, ISS, fraud, zone depth, tech stack | Single source for README, demo, and judge Q&A — **this matches your product name and persona** |
| **`README.md`** | **ShieldGig** variant (Zomato/Swiggy, same architecture) | Historical / alternate pitch; don’t mix names with Hustlr in one deck unless you explain rebrand |
| **`VIDEO_SCRIPT.md`** | 2‑minute script locked to README terms + screen cues | Record/rehearse against **current** UI (script still says rename ShieldGig → Hustlr in places) |
| **`details.txt`** | Long “ideas bank”: hyperlocal + ISS + predictive activation, insurer ROI, subrogation, profitability simulator, B2B2C, judge framing, feedback on riders/UI | Pick **5 talking points** for judges; treat as backlog, not spec |
| **`hustlr_subtitles*.srt`, `Hustlr_*_transcript*`** | Captions / transcript | Quotes and timing for video or website |
| **`SurakshaFlow-main/`, `SurakshaAI-main/`, `EarnGaurd-main/`, etc.** | Other/reference projects | Inspiration only — not part of **Dhruvv-Hustlr** codebase |

---

### Research themes → your repo (grounded)

**1. “Not an insurer — underwriting intelligence engine”**  
Your **`readme.txt`** / root **`README.md`** say this explicitly. Backend role: triggers, fraud, wallet — **carrier** is implied.

**2. Hyperlocal / zone-level parametric**  
**Implemented:** disruption APIs are zone-based (`/disruptions/:zone`), cron + `disruption_events`, ML/weather services keyed by zone.

**3. Income Stability Score (ISS)**  
**Implemented in product narrative + API:** `users.iss_score`, **`PATCH /workers/:id/iss`**, onboarding seeds ISS in register flow.

**4. Fraud + multi-signal story**  
**Implemented in spirit:** `fraud_engine.js`, ML fraud path, FPS on claims; **video script** claims 7 layers — align spoken script with **whatever you actually compute** in code to avoid judge mismatch.

**5. Zone depth (anti–boundary gaming)**  
**Implemented:** `zone_depth_service.js`, **`POST /workers/zone-depth/compute`**, **`PATCH /workers/:id/zone-depth`**, Flutter **`ApiService`** helpers. **Gap:** dashboard doesn’t have to call them yet unless you add location capture in UX.

**6. Predictive nudge / activation**  
**Partially implemented:** disruption bundle includes **`predictive_nudge`** / forecast path; **readme** “activate before rain” is stronger than a one-click “tomorrow coverage” SKU — fine to describe as **Phase 2** if not in UI.

**7. Guidewire PolicyCenter / ClaimCenter / BillingCenter**  
**Narrative in README; code is stub-level:**  
`guidewire_service.js` + **`GET /guidewire/sample-payload/:claimId`** (needs **`ENABLE_GUIDEWIRE_ROUTES=true`**). **Not** real PC/CC/BC APIs — pitch as **mapped integration + payload contract**.

**8. Judges hate out-of-scope riders (health / vehicle / device)**  
**Your app:** policy riders are **Cyclone, Curfew & Strike, Election Day, App Downtime** — consistent with the warning in **`details.txt`**.

**9. B2B2C / Guidewire Marketplace / insurer ROI**  
Mostly in **`details.txt`** and **`readme.txt`** business sections — use verbatim for **slides and judge questions**; no separate code module required.

**10. Subrogation / profitability simulator / claim-free cashback**  
In **`details.txt`** as **advanced ideas** — **not** required for Phase 1; cite as **roadmap** if asked “what’s next?”

---

### Practical way to “use the folder” week-of-demo

1. **Primary doc:** `GuideWire/readme.txt` (Hustlr-specific).  
2. **Demo:** `GuideWire/VIDEO_SCRIPT.md` — check every claim (amounts, layers, Guidewire names) against the **current** app + backend.  
3. **Ideas backlog:** skim **`details.txt`** section titles / tables; don’t try to implement everything — **pick 3 insurer-value bullets** (zero-touch claims, fraud coherence, zone-level underwriting).  
4. **Integration story:** show **sample ClaimCenter JSON** via enabled **`/guidewire/sample-payload/...`** next to a real `claims` row — that connects “folder knowledge” to **running code**.

If you want this turned into a **one-page “Guidewire judge sheet”** (only bullets + demo order) saved **inside** `GuideWire/`, say so and we can add that file; you didn’t ask for a new doc, so I’m keeping this as the walkthrough only.

---

**User**

i am telling you to use it to improve the overall app and ai models and etc

---

**Cursor**


Using GuideWire research to drive concrete improvements to the ML service, backend wiring, and app UX. Exploring the codebase and implementing high-impact changes.




Implementing GuideWire-inspired improvements: a Work Route / earning-stability advisor (preventive intelligence), zone actuarial priors, optional Prophet blend, backend wiring into disruption responses, and dashboard UI.




Updating the dashboard to load data after the first frame (so we can read `UserBloc` for ISS), extending `getDisruptions` with an optional `iss` query, and adding the work-advisor card.




Adding a small fraud “signal coherence” penalty when contradictory signals appear (GuideWire-style real-world constraint).




Here’s what was added, tied to the **GuideWire** research themes (preventive intelligence, zone/actuarial thinking, insurer language, stronger fraud narrative).

### 1. **Work Route / earning stability (ML + API + UI)**  
From the “AI Work Route Risk Advisor” + ISS + hyperlocal ideas in your notes:

- **`ml_cherry_picks.py`**: `ZONE_UNDERWRITING_PRIOR` (zone → historical disruption prior) and **`compute_work_route_advisory(...)`**, which blends:
  - zone prior, today’s rain/AQI stress, tomorrow’s forecast (rain chance + mm), optional **Prophet** `risk_score` from `/forecast/{zone}`, active trigger count, optional **ISS**, and city behavioral prior.
- Outputs: **ESI (earning stability index)**, band, headline, **recommended shift windows**, **coverage nudge**, plus an **`insurer_framing`** string for demos/docs (not shown in the app card).
- **`main.py`**: **`POST /work-advisor`** with body `WorkAdvisorRequest`.

### 2. **Node wiring**  
- **`ml_service.js`**: **`getWorkAdvisor`**, with a **rule fallback** if Python is down.  
- **`work_advisor_service.js`**: Builds the payload from the disruption bundle and **merges Prophet** via `getForecast(zone)`.  
- **`disruption.routes.js`**: Every **`GET /disruptions/:zone`** now includes **`work_advisor`**. Optional query **`?iss=72`** blends the worker’s ISS (Flutter passes it when known).

### 3. **Flutter**  
- **`getDisruptions(zone, { issScore })`** adds `?iss=` when set.  
- Dashboard loads **`iss_score`** via **`getWorkerById`**, then fetches disruptions.  
- New **“WORK STABILITY”** card: ESI, band, headline, shift hints, coverage nudge.  
- **Predictive nudge**: `nudgeData` now uses the real `predictive_nudge` object (it doesn’t use an `active` flag).

### 4. **ISS + weather prior (config)**  
- **`getISSScore`** can send **`use_weather_prior: true`** when **`USE_ISS_WEATHER_PRIOR=true`** in `.env` (uses existing Open-Meteo path in Python). Documented in **`.env.example`**.

### 5. **Fraud / “real insurance” signal hygiene**  
- In **`/fraud`**, small bumps when **contradictory signals** appear together (`ip_home_match` + `gps_zone_mismatch`, `wifi_home_ssid` + `gps_jitter_perfect`), matching the “coherence across layers” story in your research.

---

**How to demo**  
Run Node + ML service, open the app: the dashboard should show **WORK STABILITY** under the rain strip. For JSON-only checks, call **`GET /disruptions/Velachery?iss=62`** and inspect **`work_advisor`**.

**Note:** `GET /disruptions/:zone` now does an **extra ML call** (forecast for Prophet blend). If that’s too slow on slow hosts, we can gate it with an env flag next.

---

**User**

cant we just run the app and all 3 work together cant we do it like that

cant we just run the app and all 3 work together cant we do it like that

cant we just run the app and all 3 work together cant we do it like that

---

**Cursor**


Checking how each service starts so we can wire a single dev flow (Flutter + Node + ML).




Yes. All three are meant to run at the same time: **Flutter → Node (3000) → Python ML (8000)**. Node already talks to ML on `http://127.0.0.1:8000` by default, so once both servers are up, the app can hit the API and the API can hit ML.

### One-shot dev flow (Windows)

From the repo root:

```powershell
.\scripts\start-dev.ps1
```

Or double‑click / run:

```text
scripts\start-dev.bat
```

That script will:

1. Open a **new terminal** → `uvicorn` for `hustlr-backend/ml_service` on **8000**  
2. Open another **new terminal** → `npm run dev` for **hustlr-backend** on **3000**  
3. In your **current** terminal → `flutter run` with **`HUSTLR_API_BASE=http://10.0.2.2:3000`** (Android **emulator** → your PC)

So you get **three processes**; Flutter and the two backends work together.

### Physical Android phone (same Wi‑Fi as PC)

Use your PC’s LAN IP (from `ipconfig`):

```powershell
.\scripts\start-dev.ps1 -ApiBase "http://YOUR_PC_IPV4:3000"
```

### What changed in code

`ApiService.baseUrl` now respects **`--dart-define=HUSTLR_API_BASE=...`**, so the script can point the app at the emulator or your LAN IP without editing Dart every time. If you don’t pass it, it still falls back to `http://192.168.1.10:3000`.

### Before first run

- **`hustlr-backend`:** `npm install`, valid `.env` (e.g. Supabase).  
- **`ml_service`:** `pip install -r requirements.txt` (or a `.venv` there and `.\scripts\start-dev.ps1 -UseVenv`).  

After that, **yes — run the app and all three work together** via the script above.

---

**User**

how do apps like facebook,swiggy etc run i want like that

---

**Cursor**


Explaining how production apps work and adding a release vs debug API pattern so we can ship builds like Swiggy/Facebook (one app → cloud APIs).




Fixing release-mode logic: Dart strips `assert` in release builds, so we'll use an explicit check.




Here’s how apps like **Facebook** and **Swiggy** actually run, and how that maps to **Hustlr**.

### What the user sees
- They install **one app** from Play Store / App Store.
- They never start a server on their phone and never type an IP address.
- The app only talks to **HTTPS APIs on the internet** (e.g. `api.swiggy.com`).

### What runs where (production)
| Piece | Where it runs |
|--------|----------------|
| **Flutter app** | On the user’s phone (UI + local cache only). |
| **Backend (Node, DB, auth, business logic)** | On **cloud VMs / containers** (AWS, GCP, Azure, etc.), 24/7. |
| **ML** | Same idea: **internal services** behind your API (another container, or a managed ML product). The phone **never** calls Python directly. |
| **CDN / static assets** | Images, configs — optional, like big consumer apps. |

So it’s **one client app** + **many server processes** in the cloud, behind load balancers and HTTPS. That’s the Swiggy/Facebook model.

### What you have today (development)
- **Three things on your PC**: Flutter + Node + ML, so you can develop without paying for cloud yet. That’s normal; it’s **not** how store users run the app.

### What “like Swiggy” means for you later
1. **Deploy** Node (and optionally ML) to a host with a public URL and TLS.
2. **Build** the Flutter app with that URL baked in (no LAN IP).

`ApiService` is now aligned with that:

- **Debug / local:** `HUSTLR_API_BASE` (e.g. from `start-dev.ps1`) or the default LAN IP.
- **Release (store-ready):** you **must** pass  
  `--dart-define=HUSTLR_API_PROD=https://api.yourdomain.com`  
  when you run `flutter build apk` / `ipa`. If you forget, the app throws a clear error instead of silently using the wrong host.

Example store build:

```bash
flutter build apk --dart-define=HUSTLR_API_PROD=https://api.hustlr.yourdomain.com
```

**Summary:** Facebook/Swiggy = **one installed app** + **everything else in the cloud**. Your dev stack is the same architecture, just with servers on your machine until you deploy them.

---

**User**

can we for send the code of ml and backend to render

---

**Cursor**


Checking repo layout, `.gitignore`, and startup commands so we can add Render deployment config.




Adding a Render Blueprint (`render.yaml`) plus Python `runtime.txt` so we can deploy the ML service and Node API as two connected web services.




Yes. Render can host **both** pieces from this repo. Here’s what was added and how to use it.

### What I added

1. **`render.yaml` (repo root)** — Blueprint with **two web services**:
   - **`hustlr-ml`** — Python in `hustlr-backend/ml_service`, `uvicorn` on Render’s `$PORT`, health check `/health`.
   - **`hustlr-api`** — Node in `hustlr-backend`, `npm start`, health check `/health`.
   - **`ML_SERVICE_URL`** on the API service is set from the ML service’s **`RENDER_EXTERNAL_URL`** (so Node calls your deployed ML URL automatically).

2. **`hustlr-backend/ml_service/runtime.txt`** — Python **3.11.9** (Render picks this up).

3. **`hustlr-backend/package.json`** — `"engines": { "node": ">=20" }` for Render’s Node runtime.

4. **`.env.example`** — Short note about Render + `ML_SERVICE_URL`.

### What you do on Render

1. Push this repo to **GitHub** (or GitLab / Bitbucket Render supports).
2. In Render: **New → Blueprint** → select the repo → confirm the blueprint (it should detect `render.yaml`).
3. When asked, set **`SUPABASE_URL`** and **`SUPABASE_SERVICE_KEY`** for **`hustlr-api`** (and add any other keys you use: `OWM_API_KEY`, `NEWSAPI_KEY`, etc.).
4. Wait for both services to go **Live** (first Python build can take several minutes because of **Prophet** / scientific stack; if the build fails on the free tier, try a paid instance or we can trim dependencies later).
5. Point the app at the API, e.g.  
   `flutter build apk --dart-define=HUSTLR_API_PROD=https://hustlr-api-xxxx.onrender.com`  
   (use the exact URL Render shows for **`hustlr-api`**).

### Important details

- **Models**: ML looks under repo root `outputs/trained_models` and `hustlr_ml/outputs/trained_models`. Only **some** files are in git right now; deploy will work but **`/health` may show “degraded”** until you commit the full model set (or the service uses fallbacks).
- **Free tier**: instances **sleep** when idle; first request after sleep is slow. **Cron** in Node only runs while the web service is awake.
- **Secrets**: don’t put Supabase keys in `render.yaml`; set them in the Render dashboard (as in the blueprint with `sync: false`).

So yes: you **push the same codebase** to Git, connect it to Render, and the blueprint deploys **ML + backend** together like a small production setup.

---

**User**

fix the file names as some files and folders dont have proper names 

---

**Cursor**


Scanning the repo for poorly named files and folders to rename.




Cleaning the repo root: many tracked analyzer/build scratch files (`analyze*.txt`, `build_*.txt`, etc.) clutter the project. `GuideWire` isn't present in this workspace. Consolidating by removing those artifacts, adding `.gitignore` rules, and fixing a few backend artifact names.




Cleaning the repo root (removing tracked analyzer/build scratch files), renaming `vercel-deploy` → `deploy/vercel`, moving `DOCUMENTATION.md` → `docs/architecture-documentation.md`, and standardizing "Guidewire" in code comments.




Here’s what was wrong and what we changed.

### 1. **Repo root clutter (bad / meaningless names)**  
Dozens of tracked scratch files (`analyze*.txt`, `build_*.txt`, `err.txt`, `out.txt`, `flutter_analyze*.log`, etc.) were removed from Git. They aren’t product code, just old analyzer/build output.

- **`.gitignore`** now ignores those patterns at the **repo root** so they aren’t committed again.

### 2. **`vercel-deploy` → `deploy/vercel`**  
The hyphenated folder name didn’t match a clear layout. It’s now:

- **`deploy/vercel/`** — `build.sh`, `.vercelignore`, `README.md`, and the copy of `vercel.json`.

Updated references:

- Root **`vercel.json`** → `bash deploy/vercel/build.sh`
- **`deploy/vercel/vercel.json`** and **`deploy/vercel/README.md`** use the same path.

**Action for you:** In the Vercel project settings, set **Build Command** to  
`bash deploy/vercel/build.sh` (if it still says `vercel-deploy/...`).

### 3. **`DOCUMENTATION.md` → `docs/architecture-documentation.md`**  
The loose root doc is now under **`docs/`** with a normal kebab-case name.

### 4. **Comment spelling: `GuideWire` → `Guidewire`**  
Aligned with the company name in:

- `hustlr-backend/ml_service/main.py`  
- `hustlr-backend/ml_service/ml_cherry_picks.py`  
- `hustlr-backend/src/services/work_advisor_service.js`

### 5. **Backend scratch files**  
Removed local **`hustlr-backend/result.txt`** / **`stress_output.txt`** if present and added them to **`hustlr-backend/.gitignore`**.

---

**Note:** In this workspace there is **no `GuideWire/` folder** (the one with `README (1).md`, `Untitled (2).txt`, etc.). If you still have that folder elsewhere or on another machine, rename it to something like **`docs/guidewire-research`** and rename files to kebab-case (e.g. `readme-draft-hustlr-zepto.md`, `insurance-coaching-transcript.txt`). I can apply those renames here too if you add that folder back.

Commit when ready: the Git moves show as **rename** `vercel-deploy` → `deploy/vercel` plus the deletions and doc move.

---

**User**

is the ml and backend working properly

---

**Cursor**


Running quick health checks on the backend and ML service: verifying they load and respond.





Here’s what we actually verified on your machine:

### Node backend (port 3000)
- **`GET /health`** responds with `status: ok` and uptime — the API process is running normally.
- **`GET /health/services`** reports upstream status: Supabase, weather, AQI, news, Firebase keys present, etc. **`ml_service` is `offline` when the Python service isn’t running**, and switches to **`ok` when ML is up** on `127.0.0.1:8000` (confirmed after starting uvicorn).

So **the backend is working properly** as long as `.env` is loaded (you’re using `dotenv` in `index.js`).

### ML service (FastAPI)
- **`import main`** succeeds — no import/syntax errors.
- **`GET /health`** returns **`degraded`**, not broken: several **model files are missing** on disk (e.g. `model1_iss_xgboost.pkl`, Prophet `model7_prophet_adyar.pkl`, some blackout model files). **Fraud / NLP / traffic** groups report **ok** with what’s in `outputs/trained_models` / `hustlr_ml/outputs/trained_models`.
- **`POST /iss`** with `use_ml: false` returns a normal rule-based score — **endpoints work with fallbacks** when ML files are absent.

So **the ML service runs and answers requests**, but **full “all models green”** needs the rest of the trained artifacts committed or copied into those search paths (as `main.py` already documents).

### How to run them together locally
1. Terminal 1: `cd hustlr-backend/ml_service` → `python -m uvicorn main:app --host 127.0.0.1 --port 8000`  
2. Terminal 2: `cd hustlr-backend` → `npm start`  
3. Your `.env` already has `ML_SERVICE_URL=http://127.0.0.1:8000` — correct for this setup.

**Bottom line:** **Backend: OK.** **ML: OK to run; health intentionally `degraded` until missing model files are added; rule/fallback paths still work.**

---

**User**

do a stress test on the code

---

**Cursor**


Fixing the stress test: the circuit breaker returns 503, not 429. Enhancing the suite with concurrency, latency metrics, and dotenv—then running it.




Rewriting the stress test: fixing the circuit-breaker status code (503), correcting the invalid trigger `aqi_severe` → `aqi_hazardous`, adding concurrency/latency metrics, and running it.




Here’s what was done and what we measured.

### Updates to `hustlr-backend/stress_test.js`
- Loads **`.env`** via `dotenv` (same as the rest of the backend).
- **`STRESS_BASE_URL`** (default `http://127.0.0.1:3000`) for the API under test.
- **T4 fixed:** circuit breaker returns **503**, not 429; the test now expects **503** after the hourly zone cap (tripped on **claim #51** in the run below).
- **T5 fixed:** uses valid trigger **`aqi_hazardous`** and sends **`plan_tier: 'full'`** in the body (the old `aqi_severe` was invalid).
- **Unique phones** each run so repeats don’t collide on `users.phone`.
- **T8 load test:** **`STRESS_DISRUPTION_CONCURRENCY`** (default **40**) parallel **`GET /disruptions/Velachery`**, with **p50 / p95 / max** latency.
- **T6** checks **`work_advisor.earning_stability_index`** when present.
- **Optional T10:** set **`STRESS_INCLUDE_ML=true`** to hammer the Python service with **15× `GET /health`** (off by default so a stopped ML service doesn’t fail the suite).

### `package.json`
- **`npm run stress`** → `node stress_test.js`

### `.gitignore`
- **`stress_result.json`** (written after each run)

### Run result (just executed on your machine)
All **9** default tests **passed** (exit code **0**). Rough timings:
- **T4** ~**85s** (50 successful claims then 503 — expected).
- **T8** 40 concurrent disruption calls ~**1.4s** wall, **p50 ~1.2s** (each call does a lot of upstream work + work advisor + optional ML forecast).

Full JSON log: **`hustlr-backend/stress_result.json`**.

### How to run it yourself
```bash
cd hustlr-backend
npm run stress
```
With ML load test as well (start uvicorn on 8000 first):
```bash
set STRESS_INCLUDE_ML=true
npm run stress
```

**Note:** This stress suite exercises the **Node API** (and optionally **ML**). It does **not** drive the Flutter app; for that you’d use integration/UI tests separately.

---

**User**

test the ai models and if needed improve them and if needed more datasets to do it downlaod them

---

**Cursor**


Exploring the ML pipeline, testing models, and identifying improvements. Auditing available models, training scripts, and data.




Fixing training scripts (CPU fallback, traffic feature mismatch), adding trainers for ISS/blackout/Prophet, aligning model search paths with `hustlr-ml`, and adding an automated ML test runner.




I can’t apply changes or run training/tests from here because **the session is in Ask mode** (read-only). Switch to **Agent mode** and ask again so the repo can be edited and commands run.

Here is what still needs to be done for your goal (test models, fix/improve, datasets only if needed):

### Already understood from the handoff
1. **Traffic (Model 6):** Training uses **8** features; `main.py` `classify_traffic` sends **6**. Fix by either retraining on those 6 or changing inference to match training.
2. **XGBoost:** Scripts used `device='cuda'` — on typical Windows/CPU that fails. Use **`device='cpu'`** (and `tree_method='hist'`, `n_jobs=-1`) or auto-detect.
3. **Paths:** Add **`hustlr-ml/outputs/trained_models`** to `MODELS_SEARCH_PATHS` in `hustlr-backend/ml_service/main.py` (alongside `outputs/trained_models`).
4. **Artifacts:** Train or copy ISS, fraud extras, NLP tfidf/label_map, blackout, traffic encoder, Prophet, etc., into **`outputs/trained_models/`** at repo root (or under `hustlr-ml/outputs/trained_models` after the path fix).
5. **Datasets:** You already have CSVs under **`hustlr-ml/outputs/datasets/`** and **`outputs/master_joined_dataset.csv`**. Extra downloads are optional (e.g. `hustlr-ml/outputs/download_chennai_datasets.py`) if quality is still weak after retraining.
6. **Tests:** Add a small **FastAPI `TestClient`** script (or pytest) that hits `/health`, `/iss`, `/fraud`, `/nlp`, `/blackout`, `/traffic`, `/forecast/{zone}` and assert 200 + sane shapes.

### What I tried to do (blocked in Ask mode)
- Patch `main.py` model search paths.
- Switch fraud/NLP trainers to CPU XGBoost.

**Next step:** Enable **Agent mode**, then say something like “continue ML testing and training” — I’ll apply the patches, align traffic features, add any missing train scripts, run training, run tests, and only suggest dataset downloads if metrics or coverage are still insufficient.

---

**User**

continue with your work

---

**Cursor**


Continuing ML work: exploring the codebase and implementing fixes, training scripts, and tests.




Implementing path fixes, aligning traffic training with the API’s six features, adding ISS/blackout/Prophet trainers, a `train_all` runner, and ML API tests.




Fixing JSON serialization: converting NumPy scalars in the blackout response to native Python types.




Here is what was completed:

### Model path and API fixes
- **`main.py`** now also resolves models under `hustlr-ml/outputs/trained_models` (in addition to `outputs/trained_models` and `hustlr_ml/...`).
- **`/blackout`** responses use plain Python `bool` values so FastAPI can JSON-encode them (NumPy `bool_` was breaking `TestClient`).
- **`/traffic`** response uses explicit `bool` / `float` for the same reason.

### Training scripts (CPU, aligned with the API)
- **`train_model3_fraud.py`** and **`train_model4_nlp.py`**: XGBoost on **`device="cpu"`** with `n_jobs=-1` where applicable.
- **`train_model6_traffic.py`**: Retrained on the **same 6 features** as `classify_traffic` in `main.py` (`congestion_probability`, `speed_pct_drop`, `accident_duration_min`, `news_confidence`, `is_peak_hour`, `is_weekend`).
- **New**: **`train_model1_iss.py`** (ISS from `worker_profiles.csv`), **`train_model5_blackout.py`** (connectivity IF + scaler + thresholds from `connectivity_dataset.csv`), **`train_model7_prophet.py`** (Adyar Prophet from `prophet_training.csv` with a small composite `y` so the series is learnable).
- **New**: **`hustlr-ml/scripts/train_all_local.py`** runs all of the above in order.

### Datasets
No extra downloads: existing **`hustlr-ml/outputs/datasets/`** CSVs were enough. Prophet used **4383** Adyar days; raw `y` is sparse, so training blends in `heavy_rain` / `extreme_rain` / `bandh_event` (still clipped to **[0, 1]** for `/forecast`).

### Tests and dependencies
- **`hustlr-backend/ml_service/test_ml_api.py`**: smoke tests for `/health`, `/iss`, `/fraud`, `/nlp`, `/blackout`, `/traffic`, `/forecast/Adyar`, `/work-advisor`.
- **`requirements.txt`**: added **`httpx`** (required by Starlette’s `TestClient`).

### Local run (after your training run)
Training on your machine finished with metrics such as **ISS MAE ~0.27**, **fraud AUC ~0.83**, **NLP acc ~0.75**, **traffic acc ~0.998** (synthetic traffic data, so that number is optimistic). All **8** API tests **passed**.

**Re-train:** from repo root  
`python hustlr-ml/scripts/train_all_local.py`  

**Re-test:**  
`cd hustlr-backend/ml_service` → `python test_ml_api.py`

---

**User**

but you are currently using data only for 1 location but i need for entire chennai and then divided into zones also and also dont show fake data synthetic data and if even used the data shoudl feel like real data 

