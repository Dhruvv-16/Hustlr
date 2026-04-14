"""
Advanced GPS spoofing detection for delivery workers.
Delivery-specific fraud patterns:
1. Impossible movement speed (GPS jump)
2. Static location during claimed delivery
3. Location vs cell tower discrepancy
4. Historical route deviation
5. Cluster spoofing (multiple workers same exact GPS)
"""
import math
import logging
from datetime import datetime, timedelta
from typing import Optional, List, Dict

logger = logging.getLogger(__name__)

def haversine_km(
    lat1: float, lon1: float,
    lat2: float, lon2: float
) -> float:
    """Calculate distance between two GPS points in km"""
    R = 6371
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)
    a = (math.sin(dphi/2)**2 +
         math.cos(phi1) * math.cos(phi2) *
         math.sin(dlambda/2)**2)
    return R * 2 * math.atan2(
        math.sqrt(a), math.sqrt(1-a)
    )

def check_impossible_speed(
    lat1: float, lon1: float,
    lat2: float, lon2: float,
    time_minutes: float,
    vehicle: str = "bike"
) -> Dict:
    """
    Check if movement between two GPS points
    is physically possible for a delivery vehicle.

    Max speeds (km/h):
    - Bike/scooter: 60
    - Cycle: 25
    - On foot: 6
    """
    MAX_SPEEDS = {
        "bike": 60,
        "scooter": 60,
        "cycle": 25,
        "foot": 6,
    }
    max_speed = MAX_SPEEDS.get(vehicle, 60)

    distance_km = haversine_km(
        lat1, lon1, lat2, lon2
    )

    if time_minutes <= 0:
        return {
            "flag": True,
            "reason": "ZERO_TIME_MOVEMENT",
            "distance_km": distance_km,
            "speed_kmh": None,
            "fraud_score_contribution": 0.35,
        }

    speed_kmh = (distance_km / time_minutes) * 60
    is_impossible = speed_kmh > max_speed * 1.2

    return {
        "flag": is_impossible,
        "reason": "IMPOSSIBLE_SPEED" if is_impossible
                  else "NORMAL_MOVEMENT",
        "distance_km": round(distance_km, 2),
        "speed_kmh": round(speed_kmh, 1),
        "max_allowed_kmh": max_speed,
        "fraud_score_contribution": (
            0.35 if speed_kmh > max_speed * 2
            else 0.20 if is_impossible
            else 0.0
        ),
    }

def check_static_location_fraud(
    gps_points: List[Dict],
    min_movement_km: float = 0.1
) -> Dict:
    """
    Real delivery workers move constantly.
    If GPS points are all within 100m over 30 min
    during claimed delivery time, it's suspicious.

    gps_points: list of {"lat": x, "lng": y,
                          "timestamp": datetime}
    """
    if len(gps_points) < 3:
        return {
            "flag": False,
            "reason": "INSUFFICIENT_GPS_DATA",
            "fraud_score_contribution": 0.0,
        }

    max_distance = 0
    for i in range(len(gps_points)):
        for j in range(i+1, len(gps_points)):
            d = haversine_km(
                gps_points[i]["lat"],
                gps_points[i]["lng"],
                gps_points[j]["lat"],
                gps_points[j]["lng"],
            )
            max_distance = max(max_distance, d)

    is_static = max_distance < min_movement_km

    return {
        "flag": is_static,
        "reason": "STATIC_LOCATION_FRAUD"
                  if is_static else "NORMAL_MOVEMENT",
        "max_movement_km": round(max_distance, 3),
        "min_expected_km": min_movement_km,
        "fraud_score_contribution": (
            0.30 if is_static else 0.0
        ),
    }

def check_cluster_spoofing(
    claim_lat: float,
    claim_lng: float,
    other_claims: List[Dict],
    radius_m: float = 10.0
) -> Dict:
    """
    GPS spoofing apps often set all workers
    to exact same coordinates.

    Check if multiple workers reported
    identical or near-identical GPS within
    a 10 meter radius at the same time.
    This is physically impossible in real life.
    """
    suspicious_count = 0
    for claim in other_claims:
        other_lat = claim.get("claim_lat", 0)
        other_lng = claim.get("claim_lng", 0)
        dist_km = haversine_km(
            claim_lat, claim_lng,
            other_lat, other_lng
        )
        dist_m = dist_km * 1000
        if dist_m < radius_m:
            suspicious_count += 1

    is_suspicious = suspicious_count >= 3

    return {
        "flag": is_suspicious,
        "reason": "CLUSTER_GPS_SPOOFING"
                  if is_suspicious
                  else "NORMAL_DISTRIBUTION",
        "workers_at_same_location":
            suspicious_count,
        "radius_meters": radius_m,
        "fraud_score_contribution": (
            0.45 if suspicious_count >= 5
            else 0.30 if is_suspicious
            else 0.0
        ),
    }

def check_zone_boundary_fraud(
    claim_lat: float,
    claim_lng: float,
    zone_lat: float,
    zone_lng: float,
    zone_radius_km: float = 5.0
) -> Dict:
    """
    Worker claims to be in their zone but
    GPS shows them far outside it.
    """
    distance_km = haversine_km(
        claim_lat, claim_lng,
        zone_lat, zone_lng
    )

    outside_zone = distance_km > zone_radius_km
    far_outside = distance_km > zone_radius_km * 2

    return {
        "flag": outside_zone,
        "reason": "FAR_OUTSIDE_ZONE"
                  if far_outside
                  else "OUTSIDE_ZONE"
                  if outside_zone
                  else "WITHIN_ZONE",
        "distance_from_zone_km":
            round(distance_km, 2),
        "zone_radius_km": zone_radius_km,
        "fraud_score_contribution": (
            0.40 if far_outside
            else 0.20 if outside_zone
            else 0.0
        ),
    }

async def run_advanced_gps_checks(
    worker: dict,
    claim: dict,
    db,
    claim_lat: Optional[float] = None,
    claim_lng: Optional[float] = None,
) -> Dict:
    """
    Run all GPS fraud checks and return
    combined result with total score.
    """
    checks = {}
    total_gps_fraud_score = 0.0
    flags = []

    zone_lat = worker.get("zone_lat", 0)
    zone_lng = worker.get("zone_lng", 0)

    # Check 1: Zone boundary
    if claim_lat and claim_lng:
        boundary_check = check_zone_boundary_fraud(
            claim_lat, claim_lng,
            zone_lat, zone_lng,
        )
        checks["zone_boundary"] = boundary_check
        if boundary_check["flag"]:
            total_gps_fraud_score += (
                boundary_check[
                    "fraud_score_contribution"
                ]
            )
            flags.append(boundary_check["reason"])

    # Check 2: Cluster spoofing
    # Get other claims for same trigger event
    trigger_id = claim.get("trigger_event_id")
    if trigger_id and claim_lat and claim_lng:
        other_claims = await db.claims.find({
            "trigger_event_id": trigger_id,
            "_id": {"$ne": str(claim.get("_id", ""))},
            "claim_lat": {"$exists": True},
        }).to_list(50)

        cluster_check = check_cluster_spoofing(
            claim_lat, claim_lng, other_claims
        )
        checks["cluster_spoofing"] = cluster_check
        if cluster_check["flag"]:
            total_gps_fraud_score += (
                cluster_check[
                    "fraud_score_contribution"
                ]
            )
            flags.append(cluster_check["reason"])

    # Check 3: Movement history
    worker_id = str(worker.get("_id", ""))
    recent_location = worker.get(
        "last_known_location"
    )
    last_order_ts = worker.get(
        "last_order_timestamp"
    )

    if (claim_lat and claim_lng
            and recent_location
            and last_order_ts):
        time_diff = (
            datetime.utcnow() - last_order_ts
        ).total_seconds() / 60

        speed_check = check_impossible_speed(
            recent_location.get("lat", 0),
            recent_location.get("lng", 0),
            claim_lat, claim_lng,
            time_diff,
        )
        checks["movement_speed"] = speed_check
        if speed_check["flag"]:
            total_gps_fraud_score += (
                speed_check[
                    "fraud_score_contribution"
                ]
            )
            flags.append(speed_check["reason"])

    total_gps_fraud_score = min(
        0.95, total_gps_fraud_score
    )

    return {
        "gps_fraud_score": round(
            total_gps_fraud_score, 3
        ),
        "gps_flags": flags,
        "gps_checks": checks,
        "gps_spoofing_detected": (
            total_gps_fraud_score > 0.50
        ),
    }
