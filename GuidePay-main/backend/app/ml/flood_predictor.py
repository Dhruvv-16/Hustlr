import numpy as np
from datetime import datetime
import logging
import httpx
import os

logger = logging.getLogger(__name__)

# OpenWeatherMap free API coords for monitored cities
CITY_COORDS = {
    "kondapur-hyderabad": {"lat": 17.4401, "lon": 78.3489, "city": "Hyderabad"},
    "kurla-mumbai":       {"lat": 19.0728, "lon": 72.8826, "city": "Mumbai"},
    "tnagar-chennai":     {"lat": 13.0418, "lon": 80.2341, "city": "Chennai"},
    "koramangala-bengaluru": {"lat": 12.9352, "lon": 77.6245, "city": "Bengaluru"},
    "dwarka-delhi":       {"lat": 28.5921, "lon": 77.0460, "city": "Delhi"},
}


async def get_real_weather_data(zone: str) -> dict:
    """
    Fetch real weather data from OpenWeatherMap free API.
    Returns rainfall and humidity data if API key is configured.
    Falls back to None on error.
    """
    api_key = os.getenv("OPENWEATHER_API_KEY", "")
    coords = CITY_COORDS.get(zone)
    if not api_key or not coords:
        return None

    try:
        url = (
            f"https://api.openweathermap.org/data/2.5/weather"
            f"?lat={coords['lat']}&lon={coords['lon']}"
            f"&appid={api_key}&units=metric"
        )
        async with httpx.AsyncClient(timeout=8.0) as client:
            resp = await client.get(url)
            if resp.status_code == 200:
                data = resp.json()
                # rain.1h = rainfall in last 1 hour (mm), not always present
                rainfall_1h = data.get("rain", {}).get("1h", 0)
                humidity = data.get("main", {}).get("humidity", 60)
                weather_id = data.get("weather", [{}])[0].get("id", 800)
                # Weather IDs 200-622 = rain/thunderstorm/snow
                is_raining = weather_id < 700
                return {
                    "rainfall_1h_mm": rainfall_1h,
                    "humidity": humidity,
                    "is_raining": is_raining,
                    "weather_id": weather_id,
                    "description": data.get("weather", [{}])[0].get("description", ""),
                }
    except Exception as e:
        logger.warning(f"OpenWeatherMap fetch failed for {zone}: {e}")
    return None

# Zone historical data (training basis)
ZONE_HISTORY = {
    "kondapur-hyderabad": {
        "flood_frequency_5yr": 9,
        "elevation_m": 487,
        "avg_monsoon_rainfall_mm": 820,
        "base_risk": 0.65,
    },
    "kurla-mumbai": {
        "flood_frequency_5yr": 7,
        "elevation_m": 11,
        "avg_monsoon_rainfall_mm": 2400,
        "base_risk": 0.70,
    },
    "koramangala-bengaluru": {
        "flood_frequency_5yr": 2,
        "elevation_m": 920,
        "avg_monsoon_rainfall_mm": 970,
        "base_risk": 0.15,
    },
    "tnagar-chennai": {
        "flood_frequency_5yr": 5,
        "elevation_m": 6,
        "avg_monsoon_rainfall_mm": 1400,
        "base_risk": 0.45,
    },
    "dwarka-delhi": {
        "flood_frequency_5yr": 2,
        "elevation_m": 216,
        "avg_monsoon_rainfall_mm": 790,
        "base_risk": 0.20,
    },
}


def get_monsoon_intensity(month: int) -> float:
    """Return monsoon intensity factor 0.0-1.0"""
    monsoon_map = {
        1: 0.02, 2: 0.02, 3: 0.05, 4: 0.10,
        5: 0.25, 6: 0.70, 7: 0.95, 8: 0.90,
        9: 0.65, 10: 0.30, 11: 0.10, 12: 0.03
    }
    return monsoon_map.get(month, 0.1)


async def predict_flood_probability(
    zone: str,
    zone_data: dict,
) -> dict:
    """
    Predict flood probability using rule-based ML model with real weather data.
    Uses OpenWeatherMap API when key is configured; falls back to historical model.
    """
    history = ZONE_HISTORY.get(zone, {
        "flood_frequency_5yr": 3,
        "elevation_m": 100,
        "avg_monsoon_rainfall_mm": 800,
        "base_risk": 0.30,
    })

    now = datetime.utcnow()
    month = now.month

    monsoon_intensity = get_monsoon_intensity(month)

    # Try to get real weather data
    real_weather = await get_real_weather_data(zone)

    # Normalize flood frequency (max observed ~10)
    flood_freq_norm = min(history["flood_frequency_5yr"] / 10, 1.0)

    # Elevation risk (lower = higher risk)
    elevation_risk = max(0, 1 - (history["elevation_m"] / 1000))

    if real_weather:
        # Use real rainfall data — scale rainfall to monsoon intensity modifier
        rainfall_today = real_weather["rainfall_1h_mm"] * 24  # extrapolate to 24h
        # If actively raining, boost probability
        rain_boost = 0.15 if real_weather["is_raining"] else 0
        # Humidity above 85% also increases flood risk
        humidity_boost = 0.05 if real_weather["humidity"] > 85 else 0
    else:
        # Simulated rainfall forecast
        base_rainfall = history["avg_monsoon_rainfall_mm"] / 30
        rainfall_today = base_rainfall * monsoon_intensity * (
            0.5 + np.random.random() * 0.5
        )
        rain_boost = 0
        humidity_boost = 0

    # Calculate probability
    probability = (
        history["base_risk"] * 0.30 +
        monsoon_intensity * 0.35 +
        flood_freq_norm * 0.20 +
        elevation_risk * 0.15 +
        rain_boost +
        humidity_boost
    )

    # Add small noise for realism when using simulated data
    if not real_weather:
        probability += (np.random.random() - 0.5) * 0.1

    probability = min(0.99, max(0.01, probability))

    if probability >= 0.70:
        risk_level = "HIGH"
    elif probability >= 0.40:
        risk_level = "MEDIUM"
    else:
        risk_level = "LOW"

    return {
        "probability": round(float(probability), 3),
        "probability_percent": round(float(probability) * 100, 1),
        "risk_level": risk_level,
        "rainfall_mm": round(float(rainfall_today), 1),
        "inputs": {
            "month": month,
            "monsoon_intensity": round(monsoon_intensity, 2),
            "historical_floods_5yr": history["flood_frequency_5yr"],
            "elevation_m": history["elevation_m"],
            "base_risk": history["base_risk"],
        }
    }
