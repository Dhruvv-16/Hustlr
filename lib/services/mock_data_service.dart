import 'package:flutter/foundation.dart';
import '../core/services/storage_service.dart';
import '../core/services/api_service.dart';
import '../models/claim.dart' as domain;
import 'package:hive_flutter/hive_flutter.dart';

class WorkerModel {
  final String id;
  final String name;
  final String platform;
  final String city;
  final String zone;
  final int weeklyIncomeEstimate;
  /// Income stability score (UI / analytics); optional for backward compatibility.
  final int issScore;

  WorkerModel({
    required this.id,
    required this.name,
    required this.platform,
    required this.city,
    required this.zone,
    required this.weeklyIncomeEstimate,
    this.issScore = 62,
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
  final double level;
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

// ─── Helper to map API trigger_type → display label + icon ───────────────────
String _triggerLabel(String t) {
  const m = {
    'rain_heavy': 'Rain Disruption',
    'rain_moderate': 'Rain Disruption',
    'rain_light': 'Rain Disruption',
    'heat_severe': 'Extreme Heat',
    'heat_stress': 'Extreme Heat',
    'aqi_hazardous': 'Air Quality Alert',
    'aqi_very_unhealthy': 'Air Quality Alert',
    'platform_outage': 'Platform Downtime',
    'dark_store_closure': 'Dark Store Closure',
  };
  return m[t] ?? t;
}

String _triggerIcon(String t) {
  if (t.startsWith('rain')) return 'rain';
  if (t.startsWith('heat')) return 'heat';
  if (t.startsWith('aqi')) return 'heat';
  if (t.startsWith('platform')) return 'downtime';
  return 'downtime';
}

String _planLabel(String tier) {
  const m = {
    'basic': 'Basic Shield',
    'standard': 'Standard Shield',
    'full': 'Full Shield',
    'elite': 'Elite Shield',
  };
  return m[tier] ?? tier;
}

class MockDataService extends ChangeNotifier {
  /// Demo bridge: set by main.dart so disruption triggers also flow through
  /// ClaimsBloc. Receives an immutable [domain.Claim] when a claim is approved.
  void Function(domain.Claim claim)? onClaimApproved;

  MockDataService() {
    syncWithStorage();
  }

  // ── State ──────────────────────────────────────────────────────────────────

  WorkerModel worker = WorkerModel(
    id: "HS-9821",
    name: "Karthik",
    platform: "Zepto",
    city: "Chennai",
    zone: "Adyar Dark Store Zone",
    weeklyIncomeEstimate: 4200,
  );

  PolicyModel activePolicy = PolicyModel(
    plan: "Standard Shield",
    premium: 49,
    status: "ACTIVE",
    coverageStart: "26 Oct 2025",
    coverageEnd: "25 Oct 2026",
    riders: ["App Downtime"],
    coverageDescription: "Rain, heat, pollution, app downtime, AQI > 200",
  );

  int walletBalance = 0;
  int monthlySavings = 0;
  int totalPremiums = 0;
  int potentialLoss = 2100;
  bool showPredictiveNudge = true;

  List<ClaimModel> claims = [];

  ActiveDisruption? activeDisruption;

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

  Map<String, List<String>> autocompleteCities = {
    'Chennai': ['Velachery', 'Anna Nagar', 'OMR (Old Mahabalipuram Road)', 'Adyar', 'Tambaram', 'Porur', 'Perambur', 'Korattur', 'T Nagar', 'Mylapore'],
    'Bengaluru': ['Koramangala', 'HSR Layout', 'Whitefield', 'Electronic City', 'Indiranagar', 'Marathahalli', 'Jayanagar', 'BTM Layout', 'Hebbal', 'Sarjapur Road'],
    'Mumbai': ['Andheri', 'Bandra', 'Powai', 'Thane', 'Borivali', 'Kurla', 'Dadar', 'Malad', 'Goregaon', 'Vile Parle'],
    'Delhi': ['Lajpat Nagar', 'Dwarka', 'Rohini', 'Saket', 'Noida Sector 18', 'Greater Kailash', 'Janakpuri', 'Vasant Kunj', 'Pitampura', 'Karol Bagh'],
    'Hyderabad': ['Hitech City', 'Kondapur', 'Gachibowli', 'Madhapur', 'Begumpet', 'Kukatpally', 'Miyapur', 'Banjara Hills', 'Jubilee Hills', 'Ameerpet'],
  };

  List<NudgeModel> nudges = [
    NudgeModel(type: "Heavy rain", message: "72-hr forecast: 78% rain probability Friday 2–6 PM in Adyar. Activate ₹49 Standard Shield now to protect ₹360 Friday earnings.", ctaText: "ACTIVATE NOW →", targetRoute: "/policy"),
    NudgeModel(type: "Internet outage", message: "Internet outage risk this week in your zone — add Internet Blackout cover", ctaText: "ADD COVER →", targetRoute: "/policy"),
    NudgeModel(type: "High traffic", message: "High traffic week forecast — GST Road corridor at risk Thursday evening", ctaText: "ADD COVER →", targetRoute: "/policy"),
    NudgeModel(type: "Platform downtime", message: "Platform downtime last Tuesday cost you ₹100 — you weren't covered", ctaText: "SEE PLANS →", targetRoute: "/policy"),
  ];
  int currentNudgeIndex = 0;

  NudgeModel get currentNudge => nudges[currentNudgeIndex];

  bool showShadowNudge = true;
  int missedAmount = 680;
  int missedEventsCount = 2;

  List<ShadowEventModel> shadowEvents = [
    ShadowEventModel(triggerIcon: "rain", triggerName: "Rain Disruption", date: "Oct 12, 2025", claimableAmount: 450),
    ShadowEventModel(triggerIcon: "downtime", triggerName: "Platform Downtime", date: "Oct 8, 2025", claimableAmount: 230),
  ];

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

  List<LiveStatusModel> liveStatuses = [
    LiveStatusModel(icon: "rain", name: "Rain", level: 0.1, statusText: "12mm/hr · Threshold 64.5mm/hr · IMD"),
    LiveStatusModel(icon: "heat", name: "Heat Wave", level: 0.85, statusText: "41°C · Threshold 43°C · IMD"),
    LiveStatusModel(icon: "downtime", name: "Platform", level: 0.05, statusText: "Operational · 99% uptime · Zepto API"),
    LiveStatusModel(icon: "internet", name: "Internet", level: 0.15, statusText: "45 Mbps avg · Normal · TRAI"),
    LiveStatusModel(icon: "strike", name: "Bandh/Strike", level: 0.0, statusText: "No alerts · NLP scraper clear"),
  ];

  List<double> issHistory = [55, 60, 52, 68, 58, 62];

  List<Map<String, dynamic>> transactions = [];

  // ── Sync ──────────────────────────────────────────────────────────────────

  /// Populate from local storage (fast) then hydrate from API (async).
  void syncWithStorage() {
    final box = Hive.box('appData');
    final name = box.get('userName') ?? StorageService.getString('userName') ?? StorageService.getString('workerName') ?? "Karthik";
    final city = box.get('userCity') ?? StorageService.getString('userCity') ?? StorageService.getString('workerCity') ?? "Chennai";
    final zone = box.get('userZone') ?? StorageService.getString('userZone') ?? StorageService.getString('workerZone') ?? "Adyar Dark Store Zone";
    final platform = box.get('userPlatform') ?? StorageService.getString('userPlatform') ?? StorageService.getString('workerPlatform') ?? "Zepto";
    final userId = StorageService.userId;

    worker = WorkerModel(
      id: userId.isNotEmpty ? userId : "HS-9821",
      name: name,
      platform: platform,
      city: city,
      zone: zone,
      weeklyIncomeEstimate: 4200,
    );
    notifyListeners();

    // Always load live zone data (AQI, Weather, NewsAPI) — no login required
    _hydrateZoneData(zone);

    // If we have a real userId, also hydrate user-specific data
    if (userId.isNotEmpty) {
      _hydrateFromApi(userId);
    }
  }

  /// Loads live zone-specific data (AQI, Weather, Bandh/NLP) — no userId needed.
  Future<void> _hydrateZoneData(String zone) async {
    if (zone.isEmpty) return;
    try {
      final data = await ApiService.instance.getDisruptions(zone);

      final aqiData = data['aqi'] as Map<String, dynamic>?;
      final weatherData = data['weather'] as Map<String, dynamic>?;
      final newsAlert = data['news_alert'] as Map<String, dynamic>?;
      final platform = data['platform'] as Map<String, dynamic>?;

      if (aqiData != null) {
        final aqiVal = (aqiData['current'] as num?)?.toDouble() ?? 0;
        final aqiLevel = aqiData['level'] as String? ?? 'Unknown';
        final pm25 = (aqiData['pm25'] as num?)?.toDouble() ?? 0;
        final station = aqiData['station'] as String? ?? 'AQICN';
        final aqiIdx = liveStatuses.indexWhere((s) => s.name == 'Air Quality');
        final aqiStatus = LiveStatusModel(
          icon: 'heat',
          name: 'Air Quality',
          level: (aqiVal / 500).clamp(0.0, 1.0),
          statusText: 'AQI $aqiVal · PM2.5 ${pm25.toStringAsFixed(1)} · $aqiLevel · $station',
        );
        if (aqiIdx != -1) {
          liveStatuses[aqiIdx] = aqiStatus;
        } else {
          liveStatuses.add(aqiStatus);
        }
      }

      if (weatherData != null) {
        final rain = (weatherData['rainfall_mm_1h'] as num?)?.toDouble() ?? 0;
        final temp = (weatherData['temp_celsius'] as num?)?.toDouble() ?? 0;
        final condition = weatherData['condition'] as String? ?? '';
        final rainIdx = liveStatuses.indexWhere((s) => s.name == 'Rain');
        if (rainIdx != -1) {
          liveStatuses[rainIdx] = LiveStatusModel(
            icon: 'rain', name: 'Rain',
            level: (rain / 64.5).clamp(0.0, 1.0),
            statusText: '${rain.toStringAsFixed(1)}mm/hr · Threshold 64.5mm/hr · $condition',
          );
        }
        final heatIdx = liveStatuses.indexWhere((s) => s.name == 'Heat Wave');
        if (heatIdx != -1) {
          liveStatuses[heatIdx] = LiveStatusModel(
            icon: 'heat', name: 'Heat Wave',
            level: ((temp - 30) / 15).clamp(0.0, 1.0),
            statusText: '${temp.toStringAsFixed(1)}°C · Threshold 43°C · $condition',
          );
        }
      }

      if (newsAlert != null && newsAlert['detected'] == true) {
        final confidence = (newsAlert['confidence'] as num?)?.toDouble() ?? 0;
        final headline = newsAlert['headline'] as String? ?? 'Disruption detected';
        final strikeIdx = liveStatuses.indexWhere((s) => s.name == 'Bandh/Strike');
        if (strikeIdx != -1) {
          liveStatuses[strikeIdx] = LiveStatusModel(
            icon: 'strike', name: 'Bandh/Strike',
            level: confidence,
            statusText: '${(confidence * 100).round()}% confidence · $headline',
          );
        }
      }

      if (platform != null) {
        final failRate = (platform['failure_rate'] as num?)?.toDouble() ?? 0;
        final platformIdx = liveStatuses.indexWhere((s) => s.name == 'Platform');
        if (platformIdx != -1) {
          liveStatuses[platformIdx] = LiveStatusModel(
            icon: 'downtime', name: 'Platform',
            level: failRate.clamp(0.0, 1.0),
            statusText: failRate > 0.1
                ? 'Failure rate ${(failRate * 100).round()}% · Disrupted'
                : 'Operational · ${((1 - failRate) * 100).round()}% uptime',
          );
        }
      }

      final isActive = data['active'] as bool? ?? false;
      if (isActive && activeDisruption == null) {
        final disruptions = data['disruptions'] as List<dynamic>? ?? [];
        if (disruptions.isNotEmpty) {
          final d = disruptions.first as Map<String, dynamic>;
          final tType = d['trigger_type'] as String? ?? 'disruption';
          activeDisruption = ActiveDisruption(
            type: _triggerLabel(tType),
            message: '${_triggerLabel(tType)} active in your zone',
            payoutExpected: (d['hourly_rate'] as num?)?.toInt() ?? 0,
            creditDate: 'Auto-disbursed upon confirmation',
            isActive: true,
          );
        }
      }

      notifyListeners();
      debugPrint('[MockDataService] Zone data hydrated from live API ✅');
    } catch (e) {
      debugPrint('[MockDataService] Zone hydration error: $e');
    }
  }

  Future<void> _hydrateFromApi(String userId) async {
    try {
      // Fetch wallet
      final wallet = await ApiService.instance.getWallet(userId);
      walletBalance = (wallet['balance'] as num?)?.toInt() ?? 0;
      monthlySavings = (wallet['total_payouts'] as num?)?.toInt() ?? 0;
      totalPremiums = (wallet['total_premiums'] as num?)?.toInt() ?? 0;
      final rawTx = wallet['transactions'] as List<dynamic>? ?? [];
      transactions = rawTx.map((t) => {
        'type': t['type'],
        'title': t['description'] ?? (t['type'] == 'credit' ? 'Payout Credited' : 'Premium Deducted'),
        'subtitle': t['reference'] ?? '',
        'amount': (t['amount'] as num).toInt(),
        'date': _formatDate(t['created_at'] as String?),
      }).toList();

      // Fetch claims
      final rawClaims = await ApiService.getClaimsList(userId);
      if (rawClaims.isNotEmpty) {
        claims = rawClaims.map<ClaimModel>((c) {
          final tranche1 = (c['tranche1'] as num?)?.toInt() ?? 0;
          final tranche2 = (c['tranche2'] as num?)?.toInt() ?? 0;
          final gross = (c['gross_payout'] as num?)?.toInt() ?? 0;
          return ClaimModel(
            id: c['id'] as String,
            type: _triggerLabel(c['trigger_type'] as String),
            date: _formatDate(c['created_at'] as String?),
            amount: gross,
            status: c['status'] as String,
            zone: c['zone'] as String,
            icon: _triggerIcon(c['trigger_type'] as String),
            grossAmount: gross,
            immediateAmount: tranche1,
            heldAmount: tranche2,
          );
        }).toList();
      }

      // Fetch active policy
      final policy = await ApiService.getPolicyDocument(userId);
      if (policy != null) {
        // Persist the policy ID for later use
        final pid = policy['id'] as String? ?? '';
        if (pid.isNotEmpty) await StorageService.setPolicyId(pid);

        activePolicy = PolicyModel(
          plan: _planLabel(policy['plan_tier'] as String),
          premium: (policy['weekly_premium'] as num).toInt(),
          status: (policy['status'] as String).toUpperCase(),
          coverageStart: _formatDate(policy['start_date'] as String?),
          coverageEnd: _formatDate(null, addDays: 365),
          riders: [],
          coverageDescription: 'Rain, heat, pollution, app downtime, AQI > 200',
        );
        // Update premium breakdown with real API values
        premiumBreakdown = PremiumBreakdownModel(
          baseRate: (policy['base_premium'] as num).toInt(),
          finalRate: (policy['weekly_premium'] as num).toInt(),
          factors: [
            PremiumBreakdownFactor(factor: "Base rate (${_planLabel(policy['plan_tier'])})", adjustment: (policy['base_premium'] as num).toInt(), reason: "—"),
            PremiumBreakdownFactor(factor: "Zone risk adjustment", adjustment: (policy['zone_adjustment'] as num).toInt(), reason: "Based on your zone"),
          ],
          comparison: [
            PremiumComparison(zone: "Velachery", rate: 55),
            PremiumComparison(zone: "Your zone", rate: (policy['weekly_premium'] as num).toInt()),
            PremiumComparison(zone: "Anna Nagar", rate: 34),
          ],
        );
      }

      // Fetch live disruptions for the user's zone (last 24hrs → show alert card)
      if (worker.zone.isNotEmpty) {
        final disruptions =
            await ApiService.getDisruptionEvents(worker.zone);
        if (disruptions.isNotEmpty) {
          final latest = disruptions.first as Map<String, dynamic>;
          final startedAt = latest['started_at'] as String?;
          final isRecent = startedAt != null &&
              DateTime.now().difference(DateTime.parse(startedAt)).inHours < 24;
          if (isRecent && activeDisruption == null) {
            final tType = latest['trigger_type'] as String? ?? 'disruption';
            activeDisruption = ActiveDisruption(
              type: _triggerLabel(tType),
              message: '${_triggerLabel(tType)} active in your zone',
              payoutExpected: 0,
              creditDate: 'Auto-disbursed upon confirmation',
              isActive: true,
            );
          }
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('[MockDataService] API hydration error: $e');
      // App still works with local/mock data on failure
    }
  }

  // ── Demo triggers (now hits the real API) ─────────────────────────────────

  void triggerRainDisruption() => _triggerClaim(
    type: 'Rain',
    message: 'Rain disruption in your zone',
    triggerType: 'rain_heavy',
    severity: 1.0,
    durationHours: 3,
  );

  void triggerPlatformDowntime() => _triggerClaim(
    type: 'Downtime',
    message: 'Platform app downtime in your zone',
    triggerType: 'platform_outage',
    severity: 0.9,
    durationHours: 2,
  );

  void triggerExtremeHeat() => _triggerClaim(
    type: 'Heat',
    message: 'Extreme heat alert in your zone',
    triggerType: 'heat_severe',
    severity: 0.8,
    durationHours: 3,
  );

  void _triggerClaim({
    required String type,
    required String message,
    required String triggerType,
    required double severity,
    required double durationHours,
  }) {
    final userId = StorageService.userId;

    // Show active disruption banner immediately
    activeDisruption = ActiveDisruption(
      type: type,
      message: message,
      payoutExpected: 0,
      creditDate: "Credited instantly",
      isActive: true,
    );

    // Add a PENDING claim optimistically
    final tempId = 'CLM_PENDING_${DateTime.now().millisecondsSinceEpoch}';
    claims.insert(0, ClaimModel(
      id: tempId,
      type: _triggerLabel(triggerType),
      date: 'Just now',
      amount: 0,
      status: 'PENDING',
      zone: worker.zone,
      icon: _triggerIcon(triggerType),
    ));
    notifyListeners();

    if (userId.isEmpty) {
      // No API: fallback to mock amounts so demo still works offline
      Future.delayed(const Duration(seconds: 3), () {
        const payout = 150;
        claims.first.status = 'APPROVED';
        if (claims.first.id == tempId) {
          claims[0] = ClaimModel(
            id: tempId, type: _triggerLabel(triggerType),
            date: 'Just now', amount: payout, status: 'APPROVED',
            zone: worker.zone, icon: _triggerIcon(triggerType),
            grossAmount: payout, immediateAmount: (payout * 0.7).round(),
            heldAmount: (payout * 0.3).round(),
          );
        }
        walletBalance += payout;
        monthlySavings += payout;
        transactions.insert(0, {
          'type': 'credit',
          'title': '${_triggerLabel(triggerType)} Payout',
          'subtitle': 'Auto-triggered · ${worker.zone}',
          'amount': payout,
          'date': 'Just now',
        });
        // Notify ClaimsBloc via the demo bridge so BLoC state stays in sync.
        onClaimApproved?.call(domain.Claim(
          id: tempId,
          userId: '',
          triggerType: triggerType,
          displayLabel: _triggerLabel(triggerType),
          status: domain.ClaimStatus.approved,
          grossPayout: payout,
          tranche1: (payout * 0.7).round(),
          tranche2: (payout * 0.3).round(),
          zone: worker.zone,
          createdAt: DateTime.now(),
        ));
        notifyListeners();
      });
      return;
    }

    // Hit the real API
    ApiService.submitClaim(
      userId: userId,
      triggerType: triggerType,
      severity: severity,
      durationHours: durationHours,
    ).then((result) {
      final payout = result['payout'] as Map<String, dynamic>;
      final gross = (payout['gross_payout'] as num).toInt();
      final t1 = (payout['tranche1'] as num).toInt();
      final t2 = (payout['tranche2'] as num).toInt();
      final newBalance = (result['wallet_balance'] as num).toInt();
      final claim = result['claim'] as Map<String, dynamic>;

      // Replace the temp claim with the real one
      final idx = claims.indexWhere((c) => c.id == tempId);
      if (idx != -1) {
        claims[idx] = ClaimModel(
          id: claim['id'] as String,
          type: _triggerLabel(triggerType),
          date: 'Just now',
          amount: gross,
          status: claim['status'] as String,
          zone: worker.zone,
          icon: _triggerIcon(triggerType),
          grossAmount: gross,
          immediateAmount: t1,
          heldAmount: t2,
        );
      }

      walletBalance = newBalance;
      monthlySavings += t1;
      transactions.insert(0, {
        'type': 'credit',
        'title': '${_triggerLabel(triggerType)} (70%)',
        'subtitle': 'Tranche 1 credit · ${worker.zone}',
        'amount': t1,
        'date': 'Just now',
      });
      activeDisruption = ActiveDisruption(
        type: type,
        message: message,
        payoutExpected: gross,
        creditDate: 'Credited instantly',
        isActive: true,
      );
      // Notify ClaimsBloc via the demo bridge so BLoC state stays in sync.
      onClaimApproved?.call(domain.Claim(
        id: claim['id'] as String,
        userId: userId,
        triggerType: triggerType,
        displayLabel: _triggerLabel(triggerType),
        status: domain.ClaimStatus.approved,
        grossPayout: gross,
        tranche1: t1,
        tranche2: t2,
        zone: worker.zone,
        createdAt: DateTime.now(),
      ));
      notifyListeners();
    }).catchError((e) {
      debugPrint('[MockDataService] createClaim error: $e');
      // Silently revert pending claim on failure
      claims.removeWhere((c) => c.id == tempId);
      activeDisruption = null;
      notifyListeners();
    });
  }

  // ── Wallet ─────────────────────────────────────────────────────────────────

  void withdrawToUPI(int amount, String upiId) {
    if (amount <= 0 || walletBalance < amount) return;

    final userId = StorageService.userId;

    // Optimistic UI update
    walletBalance -= amount;
    transactions.insert(0, {
      'type': 'debit',
      'title': 'UPI Withdrawal',
      'subtitle': upiId,
      'amount': amount,
      'date': 'Just now',
    });
    notifyListeners();

    if (userId.isEmpty) return;

    ApiService.walletDebit(
      userId: userId,
      amount: amount,
      description: 'UPI Withdrawal',
      reference: upiId,
    ).then((_) {
      // Success — optimistic UI already applied
    }).onError((e, _) {
      debugPrint('[MockDataService] walletDebit error: $e');
      // Revert on failure
      walletBalance += amount;
      transactions.removeAt(0);
      notifyListeners();
    });
  }

  // ── Misc UI helpers ────────────────────────────────────────────────────────

  void rotateNudge() {
    currentNudgeIndex = (currentNudgeIndex + 1) % nudges.length;
    notifyListeners();
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
    walletBalance = 0;
    monthlySavings = 0;
    activeDisruption = null;
    showPredictiveNudge = true;
    claims = [];
    transactions = [];
    notifyListeners();
    final userId = StorageService.userId;
    if (userId.isNotEmpty) _hydrateFromApi(userId);
  }

  // ── Utilities ──────────────────────────────────────────────────────────────

  static String _formatDate(String? isoString, {int addDays = 0}) {
    try {
      if (isoString == null) {
        final d = DateTime.now().add(Duration(days: addDays));
        return '${d.day} ${_month(d.month)} ${d.year}';
      }
      final d = DateTime.parse(isoString).add(Duration(days: addDays));
      return '${d.day} ${_month(d.month)} ${d.year}';
    } catch (_) {
      return isoString ?? '';
    }
  }

  static String _month(int m) => const [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ][m];
}
