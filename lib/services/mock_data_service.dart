import 'package:flutter/foundation.dart';
import '../core/services/storage_service.dart';

class WorkerModel {
  final String id;
  final String name;
  final String platform;
  final String city;
  final String zone;
  final int issScore;
  final int weeklyIncomeEstimate;

  WorkerModel({
    required this.id,
    required this.name,
    required this.platform,
    required this.city,
    required this.zone,
    required this.issScore,
    required this.weeklyIncomeEstimate,
  });
}

class PolicyModel {
  final String plan;
  final int premium;
  final String status;
  final String coverageStart;
  final String coverageEnd;
  final List<String> riders;
  final String coverageDescription;

  PolicyModel({
    required this.plan,
    required this.premium,
    required this.status,
    required this.coverageStart,
    required this.coverageEnd,
    required this.riders,
    required this.coverageDescription,
  });
}

class TimelineStep {
  final String title;
  final String date;
  final bool isDone;
  final bool isPending;

  TimelineStep({
    required this.title,
    required this.date,
    this.isDone = false,
    this.isPending = false,
  });
}

class ClaimModel {
  final String id;
  final String type;
  final String date;
  final int amount;
  String status;
  final String zone;
  final String icon;
  final List<TimelineStep> timeline;
  final int? frsScore;
  final int? durationHours;
  final int? ratePerHour;
  final int? grossAmount;
  final int? immediateAmount;
  final int? heldAmount;
  final String? releaseDate;

  ClaimModel({
    required this.id,
    required this.type,
    required this.date,
    required this.amount,
    required this.status,
    required this.zone,
    required this.icon,
    this.timeline = const [],
    this.frsScore,
    this.durationHours,
    this.ratePerHour,
    this.grossAmount,
    this.immediateAmount,
    this.heldAmount,
    this.releaseDate,
  });
}

class NudgeModel {
  final String type;
  final String message;
  final String ctaText;
  final String targetRoute;

  NudgeModel({
    required this.type,
    required this.message,
    required this.ctaText,
    required this.targetRoute,
  });
}

class ShadowEventModel {
  final String triggerIcon;
  final String triggerName;
  final String date;
  final int claimableAmount;

  ShadowEventModel({
    required this.triggerIcon,
    required this.triggerName,
    required this.date,
    required this.claimableAmount,
  });
}

class ZoneRiskFactor {
  final String icon;
  final String label;
  final int percentage;

  ZoneRiskFactor({
    required this.icon,
    required this.label,
    required this.percentage,
  });
}

class ZoneRiskModel {
  final String city;
  final String zone;
  final String riskTier;
  final List<ZoneRiskFactor> factors;

  ZoneRiskModel({
    required this.city,
    required this.zone,
    required this.riskTier,
    required this.factors,
  });
}

class LiveStatusModel {
  final String icon;
  final String name;
  final double level; // 0.0 to 1.0 (for the bar)
  final String statusText;

  LiveStatusModel({
    required this.icon,
    required this.name,
    required this.level,
    required this.statusText,
  });
}

class ActiveDisruption {
  final String type;
  final String message;
  final int payoutExpected;
  final String creditDate;
  bool isActive;

  ActiveDisruption({
    required this.type,
    required this.message,
    required this.payoutExpected,
    required this.creditDate,
    required this.isActive,
  });
}

class PremiumBreakdownFactor {
  final String factor;
  final int adjustment;
  final String reason;
  PremiumBreakdownFactor({required this.factor, required this.adjustment, required this.reason});
}

class PremiumComparison {
  final String zone;
  final int rate;
  PremiumComparison({required this.zone, required this.rate});
}

class PremiumBreakdownModel {
  final int baseRate;
  final List<PremiumBreakdownFactor> factors;
  final int finalRate;
  final List<PremiumComparison> comparison;
  PremiumBreakdownModel({
    required this.baseRate,
    required this.factors,
    required this.finalRate,
    required this.comparison,
  });
}

class WeeklyDisruption {
  final int week;
  final int rain;
  final int heat;
  final int platform;
  WeeklyDisruption({required this.week, required this.rain, required this.heat, required this.platform});
}

class AnalyticsModel {
  final int earningsProtected;
  final int disruptionEventsCount;
  final List<WeeklyDisruption> weeklyHours;
  AnalyticsModel({
    required this.earningsProtected,
    required this.disruptionEventsCount,
    required this.weeklyHours,
  });
}

class MockDataService extends ChangeNotifier {
  MockDataService() {
    syncWithStorage();
  }

  void syncWithStorage() {
    final name = StorageService.getString('userName') ?? StorageService.getString('workerName') ?? "Karthik";
    final city = StorageService.getString('userCity') ?? StorageService.getString('workerCity') ?? "Chennai";
    final zone = StorageService.getString('userZone') ?? StorageService.getString('workerZone') ?? "Adyar Dark Store Zone";
    final platform = StorageService.getString('userPlatform') ?? StorageService.getString('workerPlatform') ?? "Zepto";

    worker = WorkerModel(
      id: "HS-9821",
      name: name,
      platform: platform,
      city: city,
      zone: zone,
      issScore: 62,
      weeklyIncomeEstimate: 4200,
    );
    notifyListeners();
  }

  // WORKER
  WorkerModel worker = WorkerModel(
    id: "HS-9821",
    name: "Karthik",
    platform: "Zepto",
    city: "Chennai",
    zone: "Adyar Dark Store Zone",
    issScore: 62,
    weeklyIncomeEstimate: 4200,
  );

  // POLICY
  PolicyModel activePolicy = PolicyModel(
    plan: "Standard Shield",
    premium: 49,
    status: "ACTIVE",
    coverageStart: "26 Oct 2025",
    coverageEnd: "25 Oct 2026",
    riders: ["App Downtime"],
    coverageDescription: "Rain, heat, pollution, app downtime, AQI > 200",
  );

  // WALLET
  int walletBalance = 2190;
  int monthlySavings = 1690;
  int potentialLoss = 2100;
  bool showPredictiveNudge = true;

  // CLAIMS
  List<ClaimModel> claims = [
    ClaimModel(
      id: "CLM-001",
      type: "Rain Disruption",
      date: "Mar 12, 2026",
      amount: 150,
      status: "APPROVED",
      zone: "Adyar Dark Store Zone",
      icon: "rain",
      frsScore: 14,
      durationHours: 3,
      ratePerHour: 50,
      grossAmount: 150,
      immediateAmount: 105,
      heldAmount: 45,
      releaseDate: "Sunday Mar 15, 11 PM",
      timeline: [
        TimelineStep(title: "Disruption detected in Adyar zone", date: "Mar 12, 11:00", isDone: true),
        TimelineStep(title: "Shift window verified (8AM–10PM)", date: "Mar 12, 11:02", isDone: true),
        TimelineStep(title: "Zone depth score: 0.84 — PASS", date: "Mar 12, 11:02", isDone: true),
        TimelineStep(title: "FPS fraud check: 14/100 — CLEAN", date: "Mar 12, 11:02", isDone: true),
        TimelineStep(title: "Claim logged to ClaimCenter", date: "Mar 12, 11:02", isDone: true),
        TimelineStep(title: "₹105 (70%) provisional credit", date: "Mar 12, 11:04", isDone: true),
        TimelineStep(title: "₹45 (30%) releasing Sunday 11 PM settlement", date: "Sunday Mar 15, 11 PM", isPending: true),
      ],
    ),
    ClaimModel(
      id: "CLM-002",
      type: "Platform Downtime",
      date: "Mar 08, 2026",
      amount: 100,
      status: "APPROVED",
      zone: "Adyar Dark Store Zone",
      icon: "downtime",
      frsScore: 22,
      durationHours: 2,
      ratePerHour: 50,
      grossAmount: 100,
      immediateAmount: 70,
      heldAmount: 30,
      releaseDate: "Sunday Mar 11, 11 PM",
      timeline: [
        TimelineStep(title: "Disruption detected in Adyar zone", date: "Mar 08, 09:12", isDone: true),
        TimelineStep(title: "Shift window verified (8AM–10PM)", date: "Mar 08, 09:15", isDone: true),
        TimelineStep(title: "FPS fraud check: 22/100 — CLEAN", date: "Mar 08, 09:16", isDone: true),
        TimelineStep(title: "Claim logged to ClaimCenter", date: "Mar 08, 09:20", isDone: true),
        TimelineStep(title: "₹70 (70%) provisional credit", date: "Mar 08, 09:25", isDone: true),
        TimelineStep(title: "₹30 (30%) releasing Sunday 11 PM settlement", date: "Sunday Mar 11, 11 PM", isPending: true),
      ],
    ),
    ClaimModel(
      id: "CLM-003",
      type: "Extreme Heat",
      date: "Today",
      amount: 120,
      status: "PENDING",
      zone: "Adyar Dark Store Zone",
      icon: "heat",
      durationHours: 3,
      ratePerHour: 40,
      grossAmount: 120,
      timeline: [
        TimelineStep(title: "Disruption detected in Adyar zone", date: "Today, 13:00", isDone: true),
        TimelineStep(title: "Shift window verified (8AM–10PM)", date: "Today, 13:02", isDone: true),
        TimelineStep(title: "FPS fraud check in progress", date: "Today, 13:05", isPending: true),
      ],
    ),
  ];

  // ACTIVE DISRUPTION (shown as red banner on dashboard)
  ActiveDisruption? activeDisruption;

  // PREMIUM BREAKDOWN (Feature 9)
  PremiumBreakdownModel premiumBreakdown = PremiumBreakdownModel(
    baseRate: 55,
    finalRate: 49,
    factors: [
      PremiumBreakdownFactor(factor: "Base rate (Standard Shield)", adjustment: 55, reason: "—"),
      PremiumBreakdownFactor(factor: "Zone flood risk (Adyar, 0.62)", adjustment: 0, reason: "Moderate — no surcharge ✅"),
      PremiumBreakdownFactor(factor: "Regional behavior index (0.65)", adjustment: 0, reason: "Within normal range ✅"),
      PremiumBreakdownFactor(factor: "Platform outage rate", adjustment: -3, reason: "Zepto uptime > 97% ✅"),
      PremiumBreakdownFactor(factor: "Clean claim history (4 weeks)", adjustment: -3, reason: "No claims this season ✅"),
    ],
    comparison: [
      PremiumComparison(zone: "Velachery", rate: 55),
      PremiumComparison(zone: "Adyar (your zone)", rate: 49),
      PremiumComparison(zone: "Anna Nagar", rate: 34),
    ],
  );

  // WORKER ANALYTICS (Feature 10)
  AnalyticsModel analytics = AnalyticsModel(
    earningsProtected: 2190,
    disruptionEventsCount: 3,
    weeklyHours: [
      WeeklyDisruption(week: 1, rain: 2, heat: 0, platform: 0),
      WeeklyDisruption(week: 2, rain: 0, heat: 3, platform: 2),
      WeeklyDisruption(week: 3, rain: 0, heat: 0, platform: 0),
      WeeklyDisruption(week: 4, rain: 3, heat: 0, platform: 0),
    ],
  );

  // AUTOCOMPLETE DATA (Feature 6)
  Map<String, List<String>> autocompleteCities = {
    'Chennai': ['Velachery', 'Anna Nagar', 'OMR (Old Mahabalipuram Road)', 'Adyar', 'Tambaram', 'Porur', 'Perambur', 'Korattur', 'T Nagar', 'Mylapore'],
    'Bengaluru': ['Koramangala', 'HSR Layout', 'Whitefield', 'Electronic City', 'Indiranagar', 'Marathahalli', 'Jayanagar', 'BTM Layout', 'Hebbal', 'Sarjapur Road'],
    'Mumbai': ['Andheri', 'Bandra', 'Powai', 'Thane', 'Borivali', 'Kurla', 'Dadar', 'Malad', 'Goregaon', 'Vile Parle'],
    'Delhi': ['Lajpat Nagar', 'Dwarka', 'Rohini', 'Saket', 'Noida Sector 18', 'Greater Kailash', 'Janakpuri', 'Vasant Kunj', 'Pitampura', 'Karol Bagh'],
    'Hyderabad': ['Hitech City', 'Kondapur', 'Gachibowli', 'Madhapur', 'Begumpet', 'Kukatpally', 'Miyapur', 'Banjara Hills', 'Jubilee Hills', 'Ameerpet'],
  };

  // PREDICTIVE NUDGES (Feature 2)
  List<NudgeModel> nudges = [
    NudgeModel(
      type: "Heavy rain",
      message: "72-hr forecast: 78% rain probability Friday 2–6 PM in Adyar. Activate ₹49 Standard Shield now to protect ₹360 Friday earnings.",
      ctaText: "ACTIVATE NOW →",
      targetRoute: "/policy/plans",
    ),
    NudgeModel(
      type: "Internet outage",
      message: "Internet outage risk this week in your zone — add Internet Blackout cover",
      ctaText: "ADD COVER →",
      targetRoute: "/policy/plans",
    ),
    NudgeModel(
      type: "High traffic",
      message: "High traffic week forecast — GST Road corridor at risk Thursday evening",
      ctaText: "ADD COVER →",
      targetRoute: "/policy/plans",
    ),
    NudgeModel(
      type: "Platform downtime",
      message: "Platform downtime last Tuesday cost you ₹100 — you weren't covered",
      ctaText: "SEE PLANS →",
      targetRoute: "/policy/plans",
    ),
  ];
  int currentNudgeIndex = 0;

  NudgeModel get currentNudge => nudges[currentNudgeIndex];

  void rotateNudge() {
    currentNudgeIndex = (currentNudgeIndex + 1) % nudges.length;
    notifyListeners();
  }

  // SHADOW POLICY NUDGE (shown when uninsured)
  bool showShadowNudge = true; // Enabled for Phase 2 demo
  int missedAmount = 680;
  int missedEventsCount = 2;

  // SHADOW EVENTS (Feature 4)
  List<ShadowEventModel> shadowEvents = [
    ShadowEventModel(triggerIcon: "rain", triggerName: "Rain Disruption", date: "Oct 12, 2025", claimableAmount: 450),
    ShadowEventModel(triggerIcon: "downtime", triggerName: "Platform Downtime", date: "Oct 8, 2025", claimableAmount: 230),
  ];

  // ZONE RISK PROFILE (Feature 5)
  ZoneRiskModel zoneRisk = ZoneRiskModel(
    city: "Chennai",
    zone: "Adyar Dark Store Zone",
    riskTier: "HIGH FLOOD RISK",
    factors: [
      ZoneRiskFactor(icon: "rain", label: "Flood frequency", percentage: 85),
      ZoneRiskFactor(icon: "downtime", label: "Platform outage rate", percentage: 45),
      ZoneRiskFactor(icon: "heat", label: "Traffic congestion", percentage: 55),
    ],
  );

  // LIVE MONITORING WIDGET (Feature 8)
  List<LiveStatusModel> liveStatuses = [
    LiveStatusModel(icon: "rain", name: "Rain", level: 0.1, statusText: "12mm/hr · Threshold 64.5mm/hr · IMD"),
    LiveStatusModel(icon: "heat", name: "Heat Wave", level: 0.85, statusText: "41°C · Threshold 43°C · IMD"),
    LiveStatusModel(icon: "downtime", name: "Platform", level: 0.05, statusText: "Operational · 99% uptime · Zepto API"),
    LiveStatusModel(icon: "internet", name: "Internet", level: 0.15, statusText: "45 Mbps avg · Normal · TRAI"),
    LiveStatusModel(icon: "strike", name: "Bandh/Strike", level: 0.0, statusText: "No alerts · NLP scraper clear"),
  ];

  // ISS HISTORY for chart (6 weeks)
  List<double> issHistory = [55, 60, 52, 68, 58, 62];

  // TRANSACTIONS for wallet
  List<Map<String, dynamic>> transactions = [
    {
      "type": "credit",
      "title": "Rain Disruption (70%)",
      "subtitle": "Mar 12 · Adyar zone",
      "amount": 105,
      "date": "Mar 12, 2026",
    },
    {
      "type": "debit",
      "title": "Standard Shield Premium",
      "subtitle": "Week of Mar 10",
      "amount": 49,
      "date": "Mar 10, 2026",
    },
    {
      "type": "credit",
      "title": "Platform Downtime (70%)",
      "subtitle": "Mar 8 · Zepto outage",
      "amount": 70,
      "date": "Mar 08, 2026",
    },
    {
      "type": "debit",
      "title": "App Downtime Add-on",
      "subtitle": "Week of Mar 10",
      "amount": 12,
      "date": "Mar 10, 2026",
    },
    {
      "type": "credit",
      "title": "Claim-Free Cashback",
      "subtitle": "Mar 8 · 4 weeks bonus",
      "amount": 42,
      "date": "Mar 08, 2026",
    },
    {
      "type": "credit",
      "title": "Rain Disruption (30%)",
      "subtitle": "Releasing Sunday 11 PM",
      "amount": 45,
      "date": "Mar 15, 2026",
      "pending": true,
    },
  ];

  void withdrawToUPI(int amount, String upiId) {
    if (amount <= 0 || walletBalance < amount) return;
    
    walletBalance -= amount;
    transactions.insert(0, {
      "type": "debit",
      "title": "UPI Withdrawal",
      "subtitle": upiId,
      "amount": amount,
      "date": "Today",
    });
    notifyListeners();
  }

  // ============================================
  // DEMO TRIGGER METHODS
  // ============================================

  void triggerRainDisruption() {
    // Step 1: Show active disruption banner
    activeDisruption = ActiveDisruption(
      type: "Rain",
      message: "Rain disruption in your zone",
      payoutExpected: 150,
      creditDate: "Sunday night",
      isActive: true,
    );

    // Step 2: Add new PENDING claim
    claims.insert(0, ClaimModel(
      id: "CLM_DEMO_${DateTime.now().millisecondsSinceEpoch}",
      type: "Rain Disruption",
      date: "Just now",
      amount: 150,
      status: "PENDING",
      zone: "Adyar Dark Store Zone",
      icon: "rain",
    ));

    notifyListeners();

    // Step 3: After 3 seconds move to APPROVED
    Future.delayed(const Duration(seconds: 3), () {
      claims.first.status = "APPROVED";
      walletBalance += 150;
      monthlySavings += 150;
      transactions.insert(0, {
        "type": "credit",
        "title": "Rain Disruption Payout",
        "subtitle": "Auto-triggered — Koramangala Dark Store Zone",
        "amount": 150,
        "date": "Just now",
      });
      notifyListeners();
    });
  }

  void triggerPlatformDowntime() {
    activeDisruption = ActiveDisruption(
      type: "Downtime",
      message: "Zepto app downtime in your zone",
      payoutExpected: 280,
      creditDate: "Sunday night",
      isActive: true,
    );

    claims.insert(0, ClaimModel(
      id: "CLM_DEMO_${DateTime.now().millisecondsSinceEpoch}",
      type: "Platform Downtime",
      date: "Just now",
      amount: 280,
      status: "PENDING",
      zone: "Koramangala Dark Store Zone",
      icon: "downtime",
    ));

    notifyListeners();

    Future.delayed(const Duration(seconds: 3), () {
      claims.first.status = "APPROVED";
      walletBalance += 280;
      transactions.insert(0, {
        "type": "credit",
        "title": "Platform Downtime Payout",
        "subtitle": "Auto-triggered — Zepto outage detected",
        "amount": 280,
        "date": "Just now",
      });
      notifyListeners();
    });
  }

  void triggerExtremeHeat() {
    activeDisruption = ActiveDisruption(
      type: "Heat",
      message: "Extreme heat alert in your zone",
      payoutExpected: 210,
      creditDate: "Sunday night",
      isActive: true,
    );

    claims.insert(0, ClaimModel(
      id: "CLM_DEMO_${DateTime.now().millisecondsSinceEpoch}",
      type: "Extreme Heat",
      date: "Just now",
      amount: 210,
      status: "PENDING",
      zone: "Koramangala Dark Store Zone",
      icon: "heat",
    ));

    notifyListeners();

    Future.delayed(const Duration(seconds: 3), () {
      claims.first.status = "APPROVED";
      walletBalance += 210;
      transactions.insert(0, {
        "type": "credit",
        "title": "Extreme Heat Payout",
        "subtitle": "Auto-triggered — 43°C threshold exceeded",
        "amount": 210,
        "date": "Just now",
      });
      notifyListeners();
    });
  }

  void dismissDisruption() {
    activeDisruption = null;
    notifyListeners();
  }

  void dismissPredictiveNudge() {
    showPredictiveNudge = false;
    notifyListeners();
  }

  void resetDemo() {
    walletBalance = 2190;
    monthlySavings = 1690;
    activeDisruption = null;
    showPredictiveNudge = true;
    claims = [
      ClaimModel(
        id: "CLM001",
        type: "Rain Disruption",
        date: "Mar 12, 2026",
        amount: 150,
        status: "APPROVED",
        zone: "Koramangala Dark Store Zone",
        icon: "rain",
      ),
      ClaimModel(
        id: "CLM002",
        type: "Platform Downtime",
        date: "Mar 08, 2026",
        amount: 100,
        status: "APPROVED",
        zone: "Koramangala Dark Store Zone",
        icon: "downtime",
      ),
      ClaimModel(
        id: "CLM003",
        type: "Extreme Heat",
        date: "Today",
        amount: 120,
        status: "PENDING",
        zone: "Koramangala Dark Store Zone",
        icon: "heat",
      ),
    ];
    transactions = [
      {
        "type": "credit",
        "title": "Rain Disruption Payout",
        "subtitle": "Koramangala Dark Store Zone",
        "amount": 150,
        "date": "Mar 12, 2026",
      },
      {
        "type": "debit",
        "title": "Standard Shield Premium",
        "subtitle": "Week of Mar 10, 2026",
        "amount": 49,
        "date": "Mar 10, 2026",
      },
      {
        "type": "credit",
        "title": "Claim-Free Cashback",
        "subtitle": "4 weeks bonus reward",
        "amount": 42,
        "date": "Mar 08, 2026",
      },
      {
        "type": "debit",
        "title": "App Downtime Rider",
        "subtitle": "Week of Mar 10, 2026",
        "amount": 12,
        "date": "Mar 10, 2026",
      },
    ];
    notifyListeners();
  }
}
