// lib/data/mock_data.dart
// Single source of truth for all Hustlr demo data.
// All screens must read from here — no hardcoded values in widgets.

class MockData {

  // ── USER ──────────────────────────────────────────────────
  static const String userName = 'Karthik';
  static const String hustlrId = 'HS-9821';
  static const String userCity = 'Chennai';
  static const String userZone = 'Adyar Dark Store Zone';
  static const String userPlatform = 'Zepto';
  static const int weeklyEarnings = 4200;
  static const int hourlyRate = 60;
  static const String shiftWindow = '8 AM – 10 PM';
  static const String activePlan = 'Standard Shield';
  static const int weeklyPremium = 49;
  static const String policyNumber = 'HS-98234-AX';
  static const String policyValidity = '26 Oct 2025 – 25 Oct 2026';
  static const String policyExpiry = '25 Oct 2026';
  static const int cleanWeeks = 4;
  static const double zoneFloodRisk = 0.62;
  static const double zoneDepthScore = 0.84;
  static const double behavioralIndex = 0.65;

  // ── PREMIUM BREAKDOWN ─────────────────────────────────────
  static const Map<String, dynamic> premiumBreakdown = {
    'base_rate': 55,
    'zone_adjustment': 0,
    'behavioral_adjustment': 0,
    'platform_discount': -3,
    'clean_history_discount': -3,
    'final_rate': 49,
    'min_bound': 34,
    'max_bound': 98,
    'zone_comparison': [
      {'zone': 'Velachery', 'rate': 55, 'risk': 'HIGH'},
      {'zone': 'Adyar', 'rate': 49, 'risk': 'MODERATE'},
      {'zone': 'Anna Nagar', 'rate': 34, 'risk': 'LOW'},
    ],
  };

  // ── CLAIMS ────────────────────────────────────────────────
  static const List<Map<String, dynamic>> claims = [
    {
      'id': 'CLM-001',
      'type': 'Rain Disruption',
      'icon': 'rain',
      'date': 'Mar 12, 2026',
      'amount': 150,
      'status': 'APPROVED',
      'fps_score': 14,
      'fps_tier': 'GREEN',
      'duration_hrs': 3,
      'rate_per_hr': 50,
      'zone_depth': 0.84,
      'provisional_70': 105,
      'settlement_30': 45,
      'settlement_date': 'Sunday Mar 15, 11 PM',
      'timeline': [
        {'step': 'Rain threshold crossed in Adyar zone', 'time': '11:00 AM', 'done': true},
        {'step': 'Shift window verified (8AM–10PM)', 'time': '11:02 AM', 'done': true},
        {'step': 'Zone depth score: 0.84 — PASS', 'time': '11:02 AM', 'done': true},
        {'step': 'FPS fraud check: 14/100 — GREEN', 'time': '11:02 AM', 'done': true},
        {'step': 'Claim logged to ClaimCenter', 'time': '11:02 AM', 'done': true},
        {'step': '₹105 (70%) provisional credit', 'time': '11:04 AM', 'done': true},
        {'step': '₹45 (30%) releasing Sunday 11 PM settlement', 'time': 'Sunday Mar 15, 11 PM', 'done': false},
      ],
    },
    {
      'id': 'CLM-002',
      'type': 'Platform Downtime',
      'icon': 'platform',
      'date': 'Mar 8, 2026',
      'amount': 100,
      'status': 'APPROVED',
      'fps_score': 22,
      'fps_tier': 'GREEN',
      'duration_hrs': 2,
      'rate_per_hr': 50,
      'zone_depth': 0.79,
      'provisional_70': 70,
      'settlement_30': 30,
      'settlement_date': 'Sunday Mar 11, 11 PM',
    },
    {
      'id': 'CLM-003',
      'type': 'Extreme Heat',
      'icon': 'heat',
      'date': 'Today',
      'amount': 120,
      'status': 'PENDING',
      'estimated_payout': 120,
      'settlement_date': 'This Sunday, 11 PM',
    },
  ];

  // ── CLAIMS SUMMARY ────────────────────────────────────────
  static const int totalClaimed = 370;
  static const int totalReceived = 250;
  static const int totalPending = 1;

  // ── WALLET ────────────────────────────────────────────────
  static const int walletBalance = 2190;
  static const int savedThisMonth = 1690;
  static const String upiId = 'karthik.r@ybl';

  static const List<Map<String, dynamic>> walletTransactions = [
    {
      'title': 'Rain Disruption (70%)', 'subtitle': 'Mar 12 · Adyar zone',
      'amount': 105, 'type': 'credit', 'status': 'settled',
    },
    {
      'title': 'Standard Shield Premium', 'subtitle': 'Mar 10 · Week of Mar 10',
      'amount': -49, 'type': 'debit', 'status': 'settled',
    },
    {
      'title': 'Platform Downtime (70%)', 'subtitle': 'Mar 8 · Zepto outage',
      'amount': 70, 'type': 'credit', 'status': 'settled',
    },
    {
      'title': 'App Downtime Add-on', 'subtitle': 'Mar 10 · Week of Mar 10',
      'amount': -12, 'type': 'debit', 'status': 'settled',
    },
    {
      'title': 'Claim-Free Cashback', 'subtitle': 'Mar 8 · 4 weeks bonus',
      'amount': 42, 'type': 'credit', 'status': 'settled',
    },
    {
      'title': 'Rain Disruption (30%)', 'subtitle': 'Releasing Sunday 11 PM',
      'amount': 45, 'type': 'credit', 'status': 'pending',
    },
  ];

  // ── LIVE TRIGGER STATUS ───────────────────────────────────
  static const List<Map<String, dynamic>> liveStatus = [
    {
      'trigger': 'Rain', 'emoji': '🌧',
      'status': 'CLEAR',
      'reading': '12mm/hr', 'threshold': '64.5mm/hr',
      'source': 'IMD + OpenWeatherMap',
      'rate': '₹50/hr if triggered',
    },
    {
      'trigger': 'Heat Wave', 'emoji': '🌡',
      'status': 'ELEVATED',
      'reading': '41°C', 'threshold': '43°C',
      'source': 'IMD Chennai Nungambakkam',
      'rate': '₹40/hr if triggered',
    },
    {
      'trigger': 'Platform', 'emoji': '📱',
      'status': 'CLEAR',
      'reading': '99% uptime', 'threshold': '>60% failure rate',
      'source': 'Zepto order failure rate',
      'rate': '₹50/hr if triggered',
    },
    {
      'trigger': 'Internet', 'emoji': '🌐',
      'status': 'CLEAR',
      'reading': '45 Mbps avg', 'threshold': '<10% connectivity',
      'source': 'TRAI + Ookla',
      'rate': '₹50/hr if triggered',
    },
    {
      'trigger': 'Bandh/Strike', 'emoji': '⚠️',
      'status': 'CLEAR',
      'reading': 'No alerts detected', 'threshold': 'NLP confidence ≥ 0.6',
      'source': 'NLP Scraper + NewsAPI',
      'rate': '₹50/hr if triggered',
    },
  ];

  // ── ANALYTICS ─────────────────────────────────────────────
  static const int earningsProtected = 2190;
  static const int disruptionEvents = 3;
  static const List<int> issTrend = [58, 59, 60, 62];

  static const List<Map<String, dynamic>> weeklyDisruptionHours = [
    {'week': 'Wk 1', 'rain': 2, 'heat': 0, 'platform': 0},
    {'week': 'Wk 2', 'rain': 0, 'heat': 3, 'platform': 2},
    {'week': 'Wk 3', 'rain': 0, 'heat': 0, 'platform': 0},
    {'week': 'Wk 4', 'rain': 3, 'heat': 0, 'platform': 0},
  ];

  static const int shadowMissed = 680;

  static const List<Map<String, dynamic>> shadowEvents = [
    {'trigger': 'Rain Disruption', 'date': 'Oct 12, 2025', 'missed': 450},
    {'trigger': 'Platform Downtime', 'date': 'Oct 8, 2025', 'missed': 230},
  ];

  // ── NUDGES ────────────────────────────────────────────────
  static const List<Map<String, dynamic>> nudges = [
    {
      'type': 'rain',
      'emoji': '🌧',
      'title': 'Heavy rain expected Friday in your zone',
      'subtitle': 'Activate to protect ₹600+ earnings',
      'cta': 'ACTIVATE NOW →',
      'route': 'plans',
    },
    {
      'type': 'internet',
      'emoji': '🌐',
      'title': 'Internet outage risk this week',
      'subtitle': 'Add Internet Blackout cover',
      'cta': 'ADD COVER →',
      'route': 'plans',
    },
    {
      'type': 'traffic',
      'emoji': '🚦',
      'title': 'High traffic week forecast',
      'subtitle': 'GST Road corridor at risk Thursday evening',
      'cta': 'ADD COVER →',
      'route': 'plans',
    },
  ];

  // ── AUTOCOMPLETE AREAS ────────────────────────────────────
  static const Map<String, List<String>> areasByCity = {
    'Chennai': [
      'Velachery', 'Adyar', 'OMR (Old Mahabalipuram Road)',
      'Anna Nagar', 'Tambaram', 'Porur', 'Perambur',
      'T Nagar', 'Mylapore', 'Korattur',
    ],
    'Bengaluru': [
      'Koramangala', 'HSR Layout', 'Whitefield', 'Electronic City',
      'Indiranagar', 'Marathahalli', 'Jayanagar',
      'BTM Layout', 'Hebbal', 'Sarjapur Road',
    ],
    'Mumbai': [
      'Andheri', 'Bandra', 'Powai', 'Thane', 'Borivali',
      'Kurla', 'Dadar', 'Malad', 'Goregaon', 'Vile Parle',
    ],
    'Delhi': [
      'Lajpat Nagar', 'Dwarka', 'Rohini', 'Saket', 'Noida Sector 18',
      'Greater Kailash', 'Janakpuri', 'Vasant Kunj', 'Pitampura', 'Karol Bagh',
    ],
    'Hyderabad': [
      'Hitech City', 'Kondapur', 'Gachibowli', 'Madhapur', 'Begumpet',
      'Kukatpally', 'Miyapur', 'Banjara Hills', 'Jubilee Hills', 'Ameerpet',
    ],
  };

  // ── PAYOUT RATES ──────────────────────────────────────────
  static const Map<String, int> hourlyRates = {
    'Heavy Rain': 50,
    'Extreme Rain / Cyclone': 65,
    'Heat Wave': 40,
    'Severe Pollution': 40,
    'Platform App Outage': 50,
    'Bandh / Strike / Curfew': 50,
    'Heavy Traffic Congestion': 40,
    'Internet Zone Blackout': 50,
    'Accident Blockspot': 40,
  };

  static const int dailyCap = 150;
  static const int weeklyCap = 500;

  // ── PLANS ─────────────────────────────────────────────────
  static const List<Map<String, dynamic>> plans = [
    {
      'name': 'Basic Shield',
      'price': 29,
      'covers': 'Rain + extreme heat',
      'triggers': ['Heavy Rain', 'Extreme Rain / Cyclone', 'Heat Wave'],
      'loss_ratio': 0.65,
      'badge': null,
    },
    {
      'name': 'Standard Shield',
      'price': 49,
      'covers': 'Rain, heat, pollution, app downtime',
      'triggers': ['Heavy Rain', 'Extreme Rain / Cyclone', 'Heat Wave',
                   'Severe Pollution', 'Platform App Outage'],
      'loss_ratio': 0.65,
      'badge': 'MOST POPULAR',
    },
    {
      'name': 'Full Shield',
      'price': 79,
      'covers': 'All types incl. bandh + internet blackout',
      'triggers': ['Heavy Rain', 'Extreme Rain / Cyclone', 'Heat Wave',
                   'Severe Pollution', 'Platform App Outage',
                   'Bandh / Strike / Curfew', 'Internet Zone Blackout',
                   'Heavy Traffic Congestion'],
      'loss_ratio': 0.67,
      'badge': null,
    },
    {
      'name': 'Elite Shield',
      'price': 109,
      'covers': 'All types + compound triggers + 10% cashback',
      'triggers': ['All triggers + compound combinations'],
      'loss_ratio': 0.55,
      'badge': 'BEST VALUE',
      'cashback': true,
    },
  ];

  // ── POLICY HISTORY ────────────────────────────────────────
  static const List<Map<String, dynamic>> policyHistory = [
    {
      'plan': 'Standard Shield',
      'period': 'Mar 2025 – Mar 2026',
      'price': 49,
    },
    {
      'plan': 'Basic Shield',
      'period': 'Sep 2024 – Mar 2025',
      'price': 29,
    },
  ];

  // ── Q-COMMERCE PLATFORMS ──────────────────────────────────
  static const List<String> platforms = [
    'Zepto',
    'Blinkit',
    'Swiggy Instamart',
    'Dunzo',
    'BB Now',
  ];
}
