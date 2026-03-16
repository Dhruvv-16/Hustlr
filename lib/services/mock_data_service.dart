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

class ClaimModel {
  final String id;
  final String type;
  final String date;
  final int amount;
  String status;
  final String zone;
  final String icon;

  ClaimModel({
    required this.id,
    required this.type,
    required this.date,
    required this.amount,
    required this.status,
    required this.zone,
    required this.icon,
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

class MockDataService extends ChangeNotifier {
  MockDataService() {
    syncWithStorage();
  }

  void syncWithStorage() {
    final name = StorageService.getString('workerName') ?? "Karthik";
    final city = StorageService.getString('workerCity') ?? "Bengaluru";
    final zone = StorageService.getString('workerZone') ?? "Koramangala";
    final platform = StorageService.getString('workerPlatform') ?? "Zepto";

    worker = WorkerModel(
      id: "SG-9821",
      name: name,
      platform: platform,
      city: city,
      zone: "$zone Zone",
      issScore: 62,
      weeklyIncomeEstimate: 4200,
    );
    notifyListeners();
  }

  // WORKER
  WorkerModel worker = WorkerModel(
    id: "SG-9821",
    name: "Karthik",
    platform: "Zepto",
    city: "Bengaluru",
    zone: "Koramangala Dark Store Zone",
    issScore: 62,
    weeklyIncomeEstimate: 4200,
  );

  // POLICY
  PolicyModel activePolicy = PolicyModel(
    plan: "Standard Shield",
    premium: 72,
    status: "ACTIVE",
    coverageStart: "Mon 17 Mar",
    coverageEnd: "Sun 23 Mar",
    riders: ["App Downtime"],
    coverageDescription: "Rain, heat, pollution, app downtime",
  );

  // WALLET
  int walletBalance = 2340;
  int monthlySavings = 1840;
  int potentialLoss = 2100;

  // CLAIMS
  List<ClaimModel> claims = [
    ClaimModel(
      id: "CLM001",
      type: "Rain Disruption",
      date: "Oct 12, 2023",
      amount: 450,
      status: "APPROVED",
      zone: "Koramangala Dark Store Zone",
      icon: "rain",
    ),
    ClaimModel(
      id: "CLM002",
      type: "Platform Downtime",
      date: "Oct 08, 2023",
      amount: 200,
      status: "APPROVED",
      zone: "Koramangala Dark Store Zone",
      icon: "downtime",
    ),
    ClaimModel(
      id: "CLM003",
      type: "Extreme Heat",
      date: "Today",
      amount: 300,
      status: "PENDING",
      zone: "Koramangala Dark Store Zone",
      icon: "heat",
    ),
  ];

  // ACTIVE DISRUPTION (shown as red banner on dashboard)
  ActiveDisruption? activeDisruption;

  // PREDICTIVE NUDGE (shown as amber card on dashboard)
  bool showPredictiveNudge = true;
  String predictiveMessage = "Heavy rain expected Friday";
  int protectAmount = 800;

  // SHADOW POLICY NUDGE (shown when uninsured)
  bool showShadowNudge = false;
  int missedAmount = 680;

  // ISS HISTORY for chart (6 weeks)
  List<double> issHistory = [55, 60, 52, 68, 58, 62];

  // TRANSACTIONS for wallet
  List<Map<String, dynamic>> transactions = [
    {
      "type": "credit",
      "title": "Rain Disruption Payout",
      "subtitle": "Koramangala Dark Store Zone",
      "amount": 595,
      "date": "Oct 12, 2023",
    },
    {
      "type": "debit",
      "title": "Standard Shield Premium",
      "subtitle": "Week of Oct 10, 2023",
      "amount": 72,
      "date": "Oct 10, 2023",
    },
    {
      "type": "credit",
      "title": "Claim-Free Cashback",
      "subtitle": "4 weeks bonus reward",
      "amount": 42,
      "date": "Oct 08, 2023",
    },
    {
      "type": "debit",
      "title": "App Downtime Rider",
      "subtitle": "Week of Oct 10, 2023",
      "amount": 12,
      "date": "Oct 10, 2023",
    },
  ];

  // ============================================
  // DEMO TRIGGER METHODS
  // ============================================

  void triggerRainDisruption() {
    // Step 1: Show active disruption banner
    activeDisruption = ActiveDisruption(
      type: "Rain",
      message: "Rain disruption in your zone",
      payoutExpected: 595,
      creditDate: "Sunday night",
      isActive: true,
    );

    // Step 2: Add new PENDING claim
    claims.insert(0, ClaimModel(
      id: "CLM_DEMO_${DateTime.now().millisecondsSinceEpoch}",
      type: "Rain Disruption",
      date: "Just now",
      amount: 595,
      status: "PENDING",
      zone: "Koramangala Dark Store Zone",
      icon: "rain",
    ));

    notifyListeners();

    // Step 3: After 3 seconds move to APPROVED
    Future.delayed(const Duration(seconds: 3), () {
      claims.first.status = "APPROVED";
      walletBalance += 595;
      monthlySavings += 595;
      transactions.insert(0, {
        "type": "credit",
        "title": "Rain Disruption Payout",
        "subtitle": "Auto-triggered — Koramangala Dark Store Zone",
        "amount": 595,
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
    walletBalance = 2340;
    monthlySavings = 1840;
    activeDisruption = null;
    showPredictiveNudge = true;
    claims = [
      ClaimModel(
        id: "CLM001",
        type: "Rain Disruption",
        date: "Oct 12, 2023",
        amount: 450,
        status: "APPROVED",
        zone: "Koramangala Dark Store Zone",
        icon: "rain",
      ),
      ClaimModel(
        id: "CLM002",
        type: "Platform Downtime",
        date: "Oct 08, 2023",
        amount: 200,
        status: "APPROVED",
        zone: "Koramangala Dark Store Zone",
        icon: "downtime",
      ),
      ClaimModel(
        id: "CLM003",
        type: "Extreme Heat",
        date: "Today",
        amount: 300,
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
        "amount": 595,
        "date": "Oct 12, 2023",
      },
      {
        "type": "debit",
        "title": "Standard Shield Premium",
        "subtitle": "Week of Oct 10, 2023",
        "amount": 72,
        "date": "Oct 10, 2023",
      },
      {
        "type": "credit",
        "title": "Claim-Free Cashback",
        "subtitle": "4 weeks bonus reward",
        "amount": 42,
        "date": "Oct 08, 2023",
      },
      {
        "type": "debit",
        "title": "App Downtime Rider",
        "subtitle": "Week of Oct 10, 2023",
        "amount": 12,
        "date": "Oct 10, 2023",
      },
    ];
    notifyListeners();
  }
}
