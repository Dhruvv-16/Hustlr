from __future__ import annotations

import csv
import io
import json
import os
import ssl
import urllib.parse
import urllib.request
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[2]
RAW_DIR = PROJECT_ROOT / "hustlr-ml" / "outputs" / "external_data"
ENV_FILES = [
    PROJECT_ROOT / "hustlr-backend" / ".env.local",
    PROJECT_ROOT / "hustlr-backend" / ".env",
]

OPENCITY_RAINFALL_URL = (
    "https://newdata.opencity.in/dataset/256d1a20-adf5-4e3a-ae18-27664339117a/"
    "resource/3086f865-a04c-431e-815d-105ae658871f/download/"
    "e5c275eb-a4f2-4412-9677-73654e8f5f4d.csv"
)
OPEN_METEO_AIR_URL = (
    "https://air-quality-api.open-meteo.com/v1/air-quality"
    "?latitude=13.0827&longitude=80.2707"
    "&hourly=pm2_5,pm10,nitrogen_dioxide,sulphur_dioxide,ozone,european_aqi"
    "&start_date=2024-01-01&end_date=2025-12-31&timezone=Asia%2FKolkata"
)
OPENAQ_LOCATIONS_URL = "https://api.openaq.org/v3/locations?country=IN&city=Chennai&limit=25"
OPENAQ_MEASUREMENTS_URL = (
    "https://api.openaq.org/v3/sensors/{sensor_id}/measurements"
    "?limit=1000&date_from=2024-01-01T00%3A00%3A00Z&date_to=2025-12-31T23%3A59%3A59Z"
)


def read_env_key(name: str) -> str | None:
    for env_path in ENV_FILES:
        if not env_path.is_file():
            continue
        for line in env_path.read_text(encoding="utf-8").splitlines():
            if not line or line.lstrip().startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            if key.strip() == name:
                return value.strip()
    return os.environ.get(name)


def fetch_text(url: str, headers: dict[str, str] | None = None, insecure_ssl: bool = False) -> str:
    req = urllib.request.Request(url, headers=headers or {"User-Agent": "HustlrML/1.0"})
    context = ssl._create_unverified_context() if insecure_ssl else None
    with urllib.request.urlopen(req, context=context, timeout=60) as resp:
        return resp.read().decode("utf-8")


def save_text(text: str, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def download_rainfall() -> Path:
    try:
        text = fetch_text(OPENCITY_RAINFALL_URL)
    except Exception:
        text = fetch_text(OPENCITY_RAINFALL_URL, insecure_ssl=True)
    out = RAW_DIR / "chennai_rainfall_1991_2023.csv"
    save_text(text, out)
    return out


def download_open_meteo_air() -> Path:
    text = fetch_text(OPEN_METEO_AIR_URL)
    out = RAW_DIR / "chennai_openmeteo_air_quality_2024_2025.json"
    save_text(text, out)
    return out


def download_openaq() -> tuple[Path, Path] | None:
    api_key = read_env_key("OPENAQ_API_KEY")
    if not api_key:
        return None

    headers = {
        "User-Agent": "HustlrML/1.0",
        "X-API-Key": api_key,
    }
    locations_text = fetch_text(OPENAQ_LOCATIONS_URL, headers=headers)
    locations_out = RAW_DIR / "openaq_chennai_locations.json"
    save_text(locations_text, locations_out)

    payload = json.loads(locations_text)
    sensors = []
    for result in payload.get("results", []):
        for sensor in result.get("sensors", []):
            sensor_id = sensor.get("id")
            parameter = ((sensor.get("parameter") or {}).get("name") or "").lower()
            if sensor_id and parameter in {"pm25", "pm10", "no2", "so2", "o3"}:
                sensors.append((sensor_id, parameter))

    rows: list[dict[str, str | int | float]] = []
    seen = set()
    for sensor_id, parameter in sensors[:10]:
        url = OPENAQ_MEASUREMENTS_URL.format(sensor_id=sensor_id)
        try:
            text = fetch_text(url, headers=headers)
            data = json.loads(text)
        except Exception:
            continue
        for item in data.get("results", []):
            stamp = ((item.get("period") or {}).get("datetimeFrom", {}) or {}).get("utc")
            value = item.get("value")
            if stamp is None or value is None:
                continue
            key = (sensor_id, stamp)
            if key in seen:
                continue
            seen.add(key)
            rows.append(
                {
                    "sensor_id": sensor_id,
                    "parameter": parameter,
                    "timestamp_utc": stamp,
                    "value": value,
                }
            )

    measurements_out = RAW_DIR / "openaq_chennai_measurements.csv"
    measurements_out.parent.mkdir(parents=True, exist_ok=True)
    with measurements_out.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=["sensor_id", "parameter", "timestamp_utc", "value"])
        writer.writeheader()
        writer.writerows(rows)
    return locations_out, measurements_out


def main() -> None:
    print("Downloading external datasets...")
    rain = download_rainfall()
    print(f"Saved rainfall -> {rain}")
    air = download_open_meteo_air()
    print(f"Saved air quality -> {air}")
    aq = download_openaq()
    if aq is None:
        print("Skipped OpenAQ download: OPENAQ_API_KEY missing")
    else:
        print(f"Saved OpenAQ -> {aq[0]} and {aq[1]}")


if __name__ == "__main__":
    main()
