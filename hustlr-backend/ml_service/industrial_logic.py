"""
Hustlr Industrial Logic Engines
===============================
Merged from Windsurf's implementation.
Provides catastrophic financial protection and data trust scoring.
"""

class DataTrustEngine:
    """Industrial-grade Data Trust Validation Engine"""
    
    def __init__(self):
        self.trust_tiers = {
            'TIER_1_OFFICIAL': 0.95,    # IMD, NDMA, TRAI
            'TIER_2_THIRD_PARTY': 0.80,  # OpenWeatherMap, News APIs
            'TIER_3_PLATFORM': 0.65,      # Platform logs, AQICN
            'TIER_4_DEVICE': 0.25         # GPS, Accelerometers
        }
        self.trust_threshold = 0.70
        
    def calculate_trust_score(self, sources):
        """Calculate composite trust score from a dictionary of source confidences (e.g. {'imd': 0.9})"""
        if not sources:
            return 0.0

        total_weight = 0.0
        weighted_trust = 0.0
        
        for source, confidence in sources.items():
            tier = self._classify_source(source)
            trust_weight = self.trust_tiers[tier]
            weighted_trust += trust_weight * float(confidence)
            total_weight += float(confidence)
        
        if total_weight == 0:
            return 0.0
            
        return weighted_trust / total_weight
    
    def _classify_source(self, source):
        """Classify data source into trust tier"""
        source_lower = source.lower()
        if any(official in source_lower for official in ['imd', 'ndma', 'trai', 'govt']):
            return 'TIER_1_OFFICIAL'
        elif any(third in source_lower for third in ['openweather', 'news_api', 'aqicn', 'news']):
            return 'TIER_2_THIRD_PARTY'
        elif any(plat in source_lower for plat in ['platform_logs', 'swiggy', 'zomato', 'hustlr', 'ai_parser']):
            return 'TIER_3_PLATFORM'
        else:
            return 'TIER_4_DEVICE'
    
    def validate_disruption(self, event_sources):
        """Validate if disruption meets trust threshold"""
        trust_score = self.calculate_trust_score(event_sources)
        return trust_score >= self.trust_threshold, trust_score


class EconomicCircuitBreaker:
    """Industrial-grade Economic Circuit Breaker prevents catastrophic financial exposure"""
    
    def __init__(self, max_bcr=0.85, max_claims_per_hour_per_zone=50):
        self.max_bcr = max_bcr
        self.max_claims_per_hour_per_zone = max_claims_per_hour_per_zone
        self.zone_claim_counts = {}
        # In a real deployed app, these would be in a synchronized Redis store
        self.premiums_collected = 100000 # Mocked base capital pool
        self.claims_paid = 20000
        
    def update_financials(self, premiums, claims):
        """Update financial metrics globally"""
        self.premiums_collected += premiums
        self.claims_paid += claims
        
    def get_bcr(self):
        """Calculate Burning Cost Rate (Claims Paid / Premiums Collected)"""
        if self.premiums_collected == 0:
            return 0.0
        return self.claims_paid / self.premiums_collected
    
    def check_claim_limit(self, zone, timestamp):
        """Check if claim limits or BCR limits are exceeded before issuing payout"""
        # Format: "Adyar_14" (Zone and hour)
        hour_key = f"{zone}_{timestamp.hour}"
        
        if hour_key not in self.zone_claim_counts:
            self.zone_claim_counts[hour_key] = 0
        
        # Check hourly threshold for the zone (prevents a flood of synchronous bot attacks)
        if self.zone_claim_counts[hour_key] >= self.max_claims_per_hour_per_zone:
            return False, "CIRCUIT_BREAKER_ACTIVE: Hourly zone claim limit exceeded."
        
        # Check holistic Burning Cost Rate for the platform
        bcr = self.get_bcr()
        if bcr >= self.max_bcr:
            return False, f"CIRCUIT_BREAKER_ACTIVE: Critical platform BCR limit exceeded: {bcr:.2%}"
        
        return True, "SYSTEM_NOMINAL"
    
    def increment_claim(self, zone, timestamp, amount):
        hour_key = f"{zone}_{timestamp.hour}"
        self.zone_claim_counts[hour_key] = self.zone_claim_counts.get(hour_key, 0) + 1
        self.claims_paid += amount
