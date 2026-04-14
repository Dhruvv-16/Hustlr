import math


def haversine_distance(lat1: float, lon1: float,
                        lat2: float, lon2: float) -> float:
    """
    Calculate distance between two coordinates in km.
    Uses Haversine formula.
    """
    R = 6371  # Earth radius in km

    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    d_phi = math.radians(lat2 - lat1)
    d_lambda = math.radians(lon2 - lon1)

    a = (math.sin(d_phi / 2) ** 2 +
         math.cos(phi1) * math.cos(phi2) *
         math.sin(d_lambda / 2) ** 2)

    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

    return R * c


def is_within_zone(lat: float, lng: float,
                    zone_lat: float, zone_lng: float,
                    radius_km: float = 5.0) -> bool:
    """Check if coordinates are within zone radius"""
    distance = haversine_distance(lat, lng, zone_lat, zone_lng)
    return distance <= radius_km
