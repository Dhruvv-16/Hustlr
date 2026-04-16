"""
Cherry-picked logic from multi-city / industrial Hustlr ML drafts:
- ISS: city priors + optional Open-Meteo heavy-rain prior (stdlib only).
- Fraud: 7-layer weighted FPS (batch flags for DBSCAN/Poisson-style signals).
- NLP: city aliases, richer time/date extraction, extra trigger taxonomies.
"""

from __future__ import annotations

import json
import re
import urllib.error
import urllib.request
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional, Tuple

# ── ISS: multi-city coordinates + behavioral prior (from draft city config) ─────
CITY_COORDS: Dict[str, Tuple[float, float]] = {
    "Chennai": (13.08, 80.27),
    "Mumbai": (19.07, 72.87),
    "Bengaluru": (12.97, 77.59),
    "Kolkata": (22.57, 88.36),
}

CITY_BEHAVIORAL_RISK: Dict[str, float] = {
    "Chennai": 0.65,
    "Mumbai": 0.50,
    "Bengaluru": 0.55,
    "Kolkata": 0.45,
}

CITY_ZONE_BASE_PRIOR: Dict[str, float] = {
    "Chennai": 0.55,
    "Mumbai": 0.48,
    "Bengaluru": 0.44,
    "Bangalore": 0.44,
    "Kolkata": 0.50,
    "Delhi": 0.52,
}


def open_meteo_heavy_rain_prior(
    lat: float,
    lon: float,
    start_year: int = 2015,
    end_year: int = 2024,
    timeout_sec: float = 5.0,
) -> Optional[float]:
    """
    Normalised 0–1 flood/heavy-rain prior from Open-Meteo archive (annual heavy days + total mm).
    Returns None on network/shape failure (caller keeps client-supplied zone_flood_risk).
    """
    url = (
        "https://archive-api.open-meteo.com/v1/archive"
        f"?latitude={lat}&longitude={lon}"
        f"&start_date={start_year}-01-01&end_date={end_year}-12-31"
        "&daily=precipitation_sum&timezone=Asia%2FKolkata"
    )
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "HustlrML/1.0"})
        with urllib.request.urlopen(req, timeout=timeout_sec) as resp:
            data = json.loads(resp.read().decode())
        daily = data.get("daily") or {}
        rains = daily.get("precipitation_sum") or []
        if not rains:
            return None
        heavy_days = sum(1 for x in rains if x is not None and float(x) > 25)
        years = max(1, end_year - start_year + 1)
        avg_heavy = heavy_days / years
        avg_mm = sum(float(x) for x in rains if x is not None) / max(1, len(rains)) * 365.0
        day_score = min(avg_heavy / 80.0, 1.0)
        mm_score = min(avg_mm / 2500.0, 1.0)
        return round(0.6 * day_score + 0.4 * mm_score, 4)
    except (urllib.error.URLError, urllib.error.HTTPError, json.JSONDecodeError, TypeError, ValueError):
        return None


def blend_iss_flood_risk(
    zone_flood_risk: float,
    city: str,
    use_weather_prior: bool,
) -> Tuple[float, Dict[str, Any]]:
    """Blend client flood risk with optional Open-Meteo prior for the city."""
    meta: Dict[str, Any] = {"city": city, "weather_prior": None, "effective_flood_risk": zone_flood_risk}
    if not use_weather_prior:
        return zone_flood_risk, meta
    coords = CITY_COORDS.get(city.strip())
    if not coords:
        return zone_flood_risk, meta
    prior = open_meteo_heavy_rain_prior(coords[0], coords[1])
    meta["weather_prior"] = prior
    if prior is None:
        return zone_flood_risk, meta
    eff = min(1.0, 0.55 * zone_flood_risk + 0.45 * prior)
    meta["effective_flood_risk"] = eff
    return eff, meta


# ── Fraud: 7-layer ensemble (draft model3_fraud_detection.py) ─────────────────
def seven_layer_fps(
    *,
    wifi_home_ssid: int,
    zone_depth_score: float,
    platform_active_orders: int,
    is_shift_window: int,
    news_corroboration: float,
    days_since_onboard: int,
    referral_depth: int,
    filing_delay_minutes: float,
    simultaneous_zone_claims: int,
    city_behavioral_risk: float,
    l6_isolation: float,
    ring_cluster_suspect: int = 0,
    coordinated_surge_suspect: int = 0,
) -> Tuple[float, Dict[str, float]]:
    scores: Dict[str, float] = {}

    loc_score = 0.0
    if wifi_home_ssid == 1:
        loc_score += 0.6
    if zone_depth_score < 0.20:
        loc_score += 0.4
    elif zone_depth_score < 0.40:
        loc_score += 0.2
    scores["L1_location"] = min(1.0, loc_score)

    if platform_active_orders == 0 and is_shift_window == 0:
        scores["L2_zone_match"] = 0.9
    elif platform_active_orders == 0:
        scores["L2_zone_match"] = 0.5
    else:
        scores["L2_zone_match"] = max(0.0, 0.3 - platform_active_orders * 0.03)

    scores["L3_news"] = max(0.0, 1.0 - news_corroboration)

    behav = 0.0
    if days_since_onboard < 7:
        behav += 0.4
    if referral_depth >= 3:
        behav += 0.3
    if filing_delay_minutes < 0.5:
        behav += 0.3
    scores["L4_behavioral"] = min(1.0, behav) * (0.5 + city_behavioral_risk * 0.5)

    surge_norm = min(simultaneous_zone_claims / 50.0, 1.0)
    if ring_cluster_suspect:
        surge_norm = min(1.0, surge_norm + 0.25)
    if coordinated_surge_suspect:
        surge_norm = min(1.0, surge_norm + 0.15)
    scores["L5_zone_anomaly"] = surge_norm

    scores["L6_isolation_forest"] = max(0.0, min(1.0, l6_isolation))

    if filing_delay_minutes < 1.0:
        scores["L7_timing"] = 0.85
    elif filing_delay_minutes < 5.0:
        scores["L7_timing"] = 0.40
    else:
        scores["L7_timing"] = 0.10

    fps = (
        scores["L1_location"] * 0.25
        + scores["L2_zone_match"] * 0.20
        + scores["L3_news"] * 0.25
        + scores["L4_behavioral"] * 0.15
        + scores["L5_zone_anomaly"] * 0.08
        + scores["L6_isolation_forest"] * 0.04
        + scores["L7_timing"] * 0.03
    )
    return round(min(1.0, fps), 4), scores


# ── NLP: aliases + extraction + extra keyword rules ────────────────────────────
CITY_ALIASES: Dict[str, List[str]] = {
    "Chennai": ["chennai", "madras", "chennai district", "chennai metropolitan"],
    "Mumbai": ["mumbai", "bombay", "mumbai district", "greater mumbai", "mmr"],
    "Bengaluru": ["bengaluru", "bangalore", "bengaluru urban", "blr"],
    "Kolkata": ["kolkata", "calcutta", "kolkata district", "howrah"],
    "Delhi": ["delhi", "new delhi", "ncr", "gurugram", "gurgaon", "noida", "dwarka", "faridabad"],
}

# Master list: (lowercase substring needle, actuarial prior 0–1). Used for forecasts, work-advisor, etc.
# Needles are matched with `needle in zone.lower()`; longest needles win (see zone_actuarial_prior).
CHENNAI_LOCALITY_PRIORS: List[Tuple[str, float]] = [
    # Coastal / ECR-adjacent — higher pluvial / surge-style disruption exposure (heuristic)
    ("foreshore estate", 0.79),
    ("thiruvanmiyur", 0.79),
    ("besant nagar", 0.78),
    ("neelankarai", 0.77),
    ("injambakkam", 0.77),
    ("kottivakkam", 0.76),
    ("palavakkam", 0.76),
    ("panaiyur", 0.75),
    ("muttukadu", 0.74),
    ("uthandi", 0.73),
    ("mandaveli", 0.74),
    ("santhome", 0.74),
    ("mylapore", 0.73),
    ("adyar", 0.72),
    ("indira nagar", 0.71),
    ("velachery", 0.78),
    ("pallikaranai", 0.77),
    ("perumbakkam", 0.75),
    ("medavakkam", 0.75),
    ("madipakkam", 0.76),
    ("kovilambakkam", 0.74),
    ("madambakkam", 0.74),
    ("puzhuthivakkam", 0.73),
    ("nanmangalam", 0.72),
    ("sunnambu kolathur", 0.74),
    ("semmancherry", 0.71),
    ("semmencherry", 0.71),
    ("kelambakkam", 0.70),
    ("siruseri", 0.69),
    ("thaiyur", 0.68),
    ("padur", 0.68),
    ("karapakkam", 0.70),
    ("thoraipakkam", 0.69),
    ("sholinganallur", 0.66),
    ("perungudi", 0.65),
    ("karapakkam omr", 0.70),
    ("t nagar", 0.70),
    ("thyagaraya nagar", 0.70),
    ("west mambalam", 0.66),
    ("east tambaram", 0.64),
    ("west tambaram", 0.64),
    ("george town", 0.72),
    ("royapuram", 0.71),
    ("basin bridge", 0.73),
    ("washermenpet", 0.70),
    ("tiruvottiyur", 0.69),
    ("tondiarpet", 0.69),
    ("ennore", 0.71),
    ("manali", 0.70),
    ("madhavaram", 0.67),
    ("red hills", 0.64),
    ("kolathur", 0.65),
    ("perambur", 0.56),
    ("villivakkam", 0.63),
    ("icf colony", 0.62),
    ("thiru vi ka nagar", 0.64),
    ("purasawalkam", 0.66),
    ("perambur barracks", 0.58),
    ("anna nagar", 0.58),
    ("anna nagar west", 0.58),
    ("anna nagar east", 0.58),
    ("mogappair", 0.59),
    ("mogappair west", 0.59),
    ("ayyappanthangal", 0.56),
    ("iyyapanthangal", 0.56),
    ("koyambedu", 0.65),
    ("arumbakkam", 0.64),
    ("vadapalani", 0.65),
    ("saligramam", 0.62),
    ("virugambakkam", 0.61),
    ("valasaravakkam", 0.60),
    ("alwarpet", 0.67),
    ("teynampet", 0.68),
    ("nungambakkam", 0.67),
    ("egmore", 0.66),
    ("chetpet", 0.64),
    ("kilpauk", 0.63),
    ("ayanavaram", 0.62),
    ("ambattur", 0.58),
    ("ambattur ot", 0.58),
    ("madhuravoyal", 0.60),
    ("maduravoyal", 0.60),
    ("porur", 0.55),
    ("gerugambakkam", 0.55),
    ("kundrathur", 0.54),
    ("poonamallee", 0.54),
    ("mangadu", 0.53),
    ("avadi", 0.52),
    ("pattabiram", 0.51),
    ("thiruninravur", 0.51),
    ("minjur", 0.56),
    ("gummidipoondi", 0.55),
    ("tiruvallur", 0.52),
    ("pallavaram", 0.63),
    ("chromepet", 0.64),
    ("pammal", 0.63),
    ("anakaputhur", 0.62),
    ("tambaram", 0.62),
    ("perungalathur", 0.61),
    ("peerkankaranai", 0.62),
    ("chitlapakkam", 0.63),
    ("selaiyur", 0.64),
    ("camp road", 0.63),
    ("vandalur", 0.62),
    ("gowrivakkam", 0.63),
    ("guindy", 0.60),
    ("alandur", 0.61),
    ("st thomas mount", 0.61),
    ("meenambakkam", 0.62),
    ("little mount", 0.64),
    ("saidapet", 0.66),
    ("jafferkhanpet", 0.65),
    ("ashok nagar", 0.64),
    ("kk nagar", 0.64),
    ("k k nagar", 0.64),
    ("kotturpuram", 0.71),
    ("ramapuram", 0.59),
    ("manapakkam", 0.58),
    ("mugalivakkam", 0.57),
    ("iit madras", 0.68),
    ("taramani", 0.71),
    ("tharamani", 0.71),
    ("perungudi industrial", 0.66),
    ("okkiyam thoraipakkam", 0.69),
    ("injambakkam ecr", 0.77),
    ("navalur", 0.67),
    ("sithalapakkam", 0.68),
    ("medavakkam koot road", 0.75),
    ("velachery main road", 0.78),
    ("madhya kailash", 0.67),
    ("santhome cathedral", 0.74),
    ("light house", 0.73),
    ("marina", 0.72),
    ("triplicane", 0.71),
    ("park town", 0.67),
    ("broadway", 0.71),
    ("mannady", 0.70),
    ("high court", 0.66),
    ("nungambakkam high road", 0.67),
    ("omr it corridor", 0.68),
    ("siruseri sipcot", 0.69),
    ("tambaram sanatorium", 0.63),
    ("west mambalam siddha", 0.66),
    ("nungambakkam sterling", 0.67),
    ("anna university", 0.62),
    ("sriperumbudur", 0.51),
    ("oragadam", 0.52),
    ("singaperumal koil", 0.54),
    ("maraimalai nagar", 0.55),
    ("chengalpattu", 0.53),
    ("guduvanchery", 0.56),
    ("urapakkam", 0.57),
    ("kattankulathur", 0.55),
    ("potheri", 0.55),
    ("mahindra world city", 0.54),
    ("melmaruvathur", 0.50),
    ("minambakkam", 0.62),
    ("pallikaranai marsh", 0.78),
    ("north chennai", 0.68),
    ("south chennai", 0.70),
    ("central chennai", 0.66),
]

# Corridors & product-specific needles (not always localities)
CHENNAI_SPECIAL_PRIORS: List[Tuple[str, float]] = [
    ("old mahabalipuram road", 0.68),
    ("east coast road", 0.75),
    ("grand southern trunk road", 0.66),
    ("gst road", 0.66),
    ("omr", 0.68),
    ("ecr", 0.74),
    ("dark store", 0.74),
    ("chennai metro", 0.62),
    ("outer ring road chennai", 0.64),
]

# Longest needle first — avoids e.g. "nagar" swallowing "anna nagar" if short needles existed
ZONE_UNDERWRITING_PRIOR: List[Tuple[str, float]] = sorted(
    CHENNAI_LOCALITY_PRIORS + CHENNAI_SPECIAL_PRIORS,
    key=lambda x: -len(x[0]),
)

# NLP zone extraction: same localities + corridors; longest match first in main.py loop
CHENNAI_ZONES: List[str] = sorted(
    {p[0] for p in CHENNAI_LOCALITY_PRIORS + CHENNAI_SPECIAL_PRIORS},
    key=len,
    reverse=True,
)

# Extra locality strings merged into KEYWORD_RULES "zone_keywords" for rain triggers (main.py)
CHENNAI_NLP_RULE_ZONE_HINTS: List[str] = [
    "omr",
    "ecr",
    "gst road",
    "besant nagar",
    "thiruvanmiyur",
    "pallikaranai",
    "madipakkam",
    "medavakkam",
    "perungudi",
    "sholinganallur",
    "mylapore",
    "mandaveli",
    "kotturpuram",
    "taramani",
    "poonamallee",
    "ambattur",
    "madhuravoyal",
    "red hills",
    "tiruvottiyur",
    "minjur",
    "guduvanchery",
    "perungalathur",
    "selaiyur",
    "kelambakkam",
    "siruseri",
    "navalur",
    "mogappair",
    "koyambedu",
    "nungambakkam",
    "egmore",
    "royapuram",
    "george town",
    "triplicane",
    "marina",
    "basin bridge",
    "chengalpattu",
]


def extract_city_from_text(text: str) -> str:
    tl = text.lower()
    for city, aliases in CITY_ALIASES.items():
        for a in aliases:
            if a in tl:
                return city
    return "Chennai"


def extract_time_window_nlp(text: str) -> Tuple[str, str]:
    m = re.search(
        r"(\d{1,2})\s*(?:PM|AM|pm|am)?\s*(?:to|and|-)\s*(\d{1,2})\s*(?:PM|AM|pm|am)",
        text,
        re.IGNORECASE,
    )
    if m:
        return f"{m.group(1)}:00", f"{m.group(2)}:00"
    m2 = re.search(
        r"between\s+(\d{1,2})\s*(?:AM|PM|am|pm)?\s+and\s+(\d{1,2})\s*(?:AM|PM|am|pm)",
        text,
        re.IGNORECASE,
    )
    if m2:
        return f"{m2.group(1)}:00", f"{m2.group(2)}:00"
    times = re.findall(r"\b(\d{1,2})\s*(?:PM|AM|pm|am)\b", text, flags=re.IGNORECASE)
    if times:
        h0 = int(times[0])
        h1 = int(times[-1]) if len(times) > 1 else h0
        return f"{h0:02d}:00", f"{h1:02d}:00"
    return "00:00", "23:59"


def extract_date_nlp(text: str) -> str:
    tl = text.lower()
    months = {
        "january": "01",
        "february": "02",
        "march": "03",
        "april": "04",
        "may": "05",
        "june": "06",
        "july": "07",
        "august": "08",
        "september": "09",
        "october": "10",
        "november": "11",
        "december": "12",
    }
    for month, num in months.items():
        m = re.search(rf"(\d{{1,2}})\s+{month}", tl)
        if m:
            y = datetime.now().year
            return f"{y}-{num}-{int(m.group(1)):02d}"
    if "today" in tl:
        return datetime.now().strftime("%Y-%m-%d")
    if "tomorrow" in tl:
        return (datetime.now() + timedelta(days=1)).strftime("%Y-%m-%d")
    return datetime.now().strftime("%Y-%m-%d")


# Extra rules merged with base KEYWORD_RULES in main (hourly_rate_inr required).
EXTRA_KEYWORD_RULES: Dict[str, Dict[str, Any]] = {
    "poor_aqi": {
        "keywords": [
            "severe air quality",
            "hazardous aqi",
            "aqi above 300",
            "aqi above 400",
            "smog",
            "poor air quality alert",
            "cpcb",
            "pollution emergency",
        ],
        "zone_keywords": [
            "chennai",
            "tamil nadu",
            "delhi",
            "mumbai",
            "bengaluru",
            "kolkata",
            "ncr",
        ],
        "hourly_rate_inr": 42,
    },
    "accident_blockspot": {
        "keywords": [
            "road accident",
            "major accident",
            "multi-vehicle accident",
            "pile-up",
            "road blocked",
            "traffic block due to accident",
            "fatal accident",
            "nhai",
            "traffic police",
        ],
        "zone_keywords": [
            "chennai",
            "gst road",
            "omr",
            "ecr",
            "mumbai",
            "bengaluru",
            "outer ring road",
            "kolkata",
        ],
        "hourly_rate_inr": 38,
    },
    "platform_outage_nlp": {
        "keywords": [
            # Official / news language
            "app outage", "platform down", "platform outage", "delivery app crash",
            "server error widespread", "service disruption",
            # Platform names + state (news + worker slang)
            "zepto outage", "zepto down", "zepto not working", "zepto app down",
            "blinkit down", "blinkit outage", "blinkit not working",
            "swiggy down", "swiggy outage", "swiggy not working",
            "zomato outage", "zomato down", "zomato not working",
            "dunzo down", "dunzo not working",
            # Worker informal language
            "app completely down", "app crashed", "app crash", "app down",
            "cannot accept orders", "not accepting orders", "cannot accept any",
            "no orders coming", "orders stopped", "platform not working",
            "tech issue", "technical issue", "backend down",
            "app not loading", "app stuck", "app frozen",
        ],
        "zone_keywords": ["india", "chennai", "bengaluru", "mumbai", "metro",
                          "zepto", "blinkit", "swiggy", "zomato", "dunzo"],
        "hourly_rate_inr": 48,
    },
}

# Map XGBoost / training labels to rate table keys used in KEYWORD_RULES
ML_LABEL_TO_RULE_KEY: Dict[str, str] = {
    "heavy_rain": "rain_heavy",
    "extreme_rain": "rain_extreme",
    "heat_wave": "heat_severe",
    "bandh": "bandh",
    "normal": "normal",
}


def hourly_rate_lookup(trigger: str, merged_rules: Dict[str, Dict[str, Any]]) -> int:
    rule_key = ML_LABEL_TO_RULE_KEY.get(trigger, trigger)
    cfg = merged_rules.get(rule_key) or merged_rules.get(trigger) or {}
    return int(cfg.get("hourly_rate_inr", 50))


# ── Work Route / earning stability (Guidewire research: preventive intelligence) ─
# Zone priors: CHENNAI_LOCALITY_PRIORS + CHENNAI_SPECIAL_PRIORS → ZONE_UNDERWRITING_PRIOR (longest needle first).


def zone_actuarial_prior(zone: str, city: Optional[str] = None) -> float:
    z = (zone or "").lower()
    for needle, p in ZONE_UNDERWRITING_PRIOR:
        if needle in z:
            return p
    city_guess = city or extract_city_from_text(zone or "")
    return CITY_ZONE_BASE_PRIOR.get(city_guess.strip(), 0.50)


def compute_work_route_advisory(
    *,
    zone: str,
    city: str = "Chennai",
    iss_score: Optional[int] = None,
    tomorrow_rain_chance_pct: float = 0.0,
    tomorrow_rain_mm: float = 0.0,
    today_rain_mm_1h: float = 0.0,
    aqi: int = 50,
    ml_tomorrow_risk: Optional[float] = None,
    active_disruption_count: int = 0,
) -> Dict[str, Any]:
    """
    Combines zone prior + short-horizon weather + optional ISS + optional Prophet risk
    into actionable earning-stability guidance (insurance-aware, not navigation).
    """
    prior = zone_actuarial_prior(zone, city)
    city_br = CITY_BEHAVIORAL_RISK.get(city.strip(), 0.55)

    weather_stress = min(
        1.0,
        min(today_rain_mm_1h / 64.5, 1.0) * 0.45 + max(0, aqi - 100) / 250.0 * 0.35,
    )
    fc = min(
        1.0,
        (tomorrow_rain_chance_pct / 100.0) * 0.55 + min(tomorrow_rain_mm / 85.0, 1.0) * 0.35,
    )
    if ml_tomorrow_risk is not None:
        ml_r = float(max(0.0, min(1.0, ml_tomorrow_risk)))
        forecast_stress = 0.5 * fc + 0.5 * ml_r
    else:
        forecast_stress = fc

    trigger_penalty = min(1.0, active_disruption_count * 0.22)

    raw_stability = (
        100.0
        - 28.0 * prior
        - 18.0 * weather_stress
        - 22.0 * forecast_stress
        - 12.0 * trigger_penalty
        - 6.0 * city_br
    )
    if iss_score is not None:
        iss = float(max(0, min(100, iss_score)))
        raw_stability = 0.52 * raw_stability + 0.48 * iss

    esi = int(max(0, min(100, round(raw_stability))))
    if esi >= 72:
        band = "STABLE"
        band_label = "Stable earnings outlook"
    elif esi >= 48:
        band = "ELEVATED"
        band_label = "Elevated disruption risk"
    else:
        band = "STRESSED"
        band_label = "High disruption risk — protect income"

    # Simple shift-window hints (Q-commerce peaks; not literal routing).
    if forecast_stress >= 0.55 or weather_stress >= 0.35:
        best_windows = [
            {"label": "Morning push", "hours": "8:00–11:00", "rationale": "Lower rain odds before afternoon cells"},
            {"label": "Evening slot", "hours": "17:00–20:00", "rationale": "Second demand peak if streets drain"},
        ]
    elif band == "STABLE":
        best_windows = [
            {"label": "Standard shift", "hours": "8:00–22:00", "rationale": "Conditions support normal zone coverage"},
        ]
    else:
        best_windows = [
            {"label": "Peak demand", "hours": "8:00–11:00 & 17:00–21:00", "rationale": "Stack hours when platform volume is highest"},
        ]

    suggest_coverage = forecast_stress >= 0.42 or band == "STRESSED" or trigger_penalty >= 0.44

    headlines = {
        "STABLE": "Your zone looks workable — keep usual shift patterns.",
        "ELEVATED": "Weather or air quality may trim earnings — plan shorter deep-zone blocks.",
        "STRESSED": "Strong chance of lost hours — coverage or shift timing matters this week.",
    }

    return {
        "earning_stability_index": esi,
        "stability_band": band,
        "stability_band_label": band_label,
        "headline": headlines[band],
        "zone_actuarial_prior": round(prior, 3),
        "drivers": {
            "weather_stress": round(weather_stress, 3),
            "forecast_stress": round(forecast_stress, 3),
            "active_disruption_stress": round(trigger_penalty, 3),
            "city_behavioral_risk": round(city_br, 3),
        },
        "recommended_shift_windows": best_windows,
        "suggest_activate_coverage": suggest_coverage,
        "coverage_nudge": (
            "Rain or disruption risk is elevated — activating shield before the window reduces uninsured hours."
            if suggest_coverage
            else "Conditions are relatively calm; still keep auto-renew on so parametric triggers stay armed."
        ),
        "insurer_framing": (
            "Preventive intelligence reduces adverse selection: workers nudged pre-event retain coverage "
            "and generate auditable risk signals for PolicyCenter pricing attributes."
        ),
    }
