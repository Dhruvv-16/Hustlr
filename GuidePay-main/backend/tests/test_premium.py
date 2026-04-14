import pytest
from app.services.premium_service import (
    calculate_premium,
    get_zone_multiplier,
    get_worker_multiplier,
    get_premium_breakdown,
    BASE_PREMIUM,
)


def test_base_premium():
    """Default premium should be BASE_PREMIUM for unknown zone and medium risk"""
    premium = calculate_premium("unknown-zone", 0.75)
    assert premium == BASE_PREMIUM  # multiplier = 1.0, worker mult = 0.85
    # Actually: BASE_PREMIUM * 1.0 * 0.85 = 41.65... let me check
    # worker_multiplier for 0.75 (> 0.75 is false, >= 0.50 is true) = 1.00
    # So: 49 * 1.0 * 1.0 = 49.0


def test_high_flood_zone():
    """High flood zone should have higher premium"""
    premium_high = calculate_premium("kurla-mumbai", 0.75)
    premium_low = calculate_premium("koramangala-bengaluru", 0.75)
    assert premium_high > premium_low


def test_low_risk_worker_discount():
    """Low-risk worker (high score) should get discount"""
    premium_low_risk = calculate_premium("kondapur-hyderabad", 0.90)
    premium_high_risk = calculate_premium("kondapur-hyderabad", 0.30)
    assert premium_low_risk < premium_high_risk


def test_zone_multiplier_known_zone():
    """Known zone should return multiplier > 1"""
    mult = get_zone_multiplier("kurla-mumbai")
    assert mult > 1.0


def test_zone_multiplier_unknown_zone():
    """Unknown zone should return 1.0"""
    mult = get_zone_multiplier("unknown-zone-xyz")
    assert mult == 1.0


def test_worker_multiplier_tiers():
    """Test all 3 worker multiplier tiers"""
    assert get_worker_multiplier(0.90) == 0.85   # high score = discount
    assert get_worker_multiplier(0.60) == 1.00   # medium score = standard
    assert get_worker_multiplier(0.30) == 1.15   # low score = surcharge


def test_premium_breakdown_structure():
    """Premium breakdown should contain all required fields"""
    breakdown = get_premium_breakdown("kondapur-hyderabad", 0.75)
    assert "base" in breakdown
    assert "zone_multiplier" in breakdown
    assert "worker_multiplier" in breakdown
    assert "total" in breakdown
    assert "coverage_cap" in breakdown
    assert breakdown["coverage_cap"] == 600.0
