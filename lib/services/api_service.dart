import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  /// **Production (like Swiggy / Facebook):** users install one app; it talks to **your cloud API**
  /// (Node on AWS/GCP/Azure, ML as an internal service — never on the phone). You bake the prod URL
  /// into the release binary with `--dart-define=HUSTLR_API_PROD=https://api.yourdomain.com`.
  ///
  /// **Local dev:** `--dart-define=HUSTLR_API_BASE=...` or repo [scripts/start-dev.ps1].
  static String get baseUrl {
    const prod = String.fromEnvironment('HUSTLR_API_PROD');
    const devOverride = String.fromEnvironment('HUSTLR_API_BASE');

    // Web (e.g. Vercel): same prod URL as mobile — set HUSTLR_API_PROD in the host env and build.sh.
    if (kIsWeb) {
      if (prod.isNotEmpty) return prod;
      if (devOverride.isNotEmpty) return devOverride;
      if (kReleaseMode) {
        return 'https://hustlr-ta8r.onrender.com';
      }
      return 'https://hustlr-ta8r.onrender.com';
    }

    if (kReleaseMode) {
      if (prod.isNotEmpty) return prod;
      return 'https://hustlr-ta8r.onrender.com';
    }

    if (devOverride.isNotEmpty) return devOverride;
    return 'https://hustlr-ta8r.onrender.com';
  }

  static const _timeout = Duration(seconds: 5); // 5s — real network may be slower

  static final ApiService instance = ApiService._internal();
  ApiService._internal();

  String? currentUserId;
  String? currentPolicyId;
  String? accessToken;

  Map<String, String> get headers => {
        'Content-Type': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      };

  Map<String, dynamic> _decodeMap(http.Response res) {
    final raw = res.body.isEmpty ? '{}' : res.body;
    final data = jsonDecode(raw);
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid response');
    }
    if (res.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Request failed (${res.statusCode})');
    }
    return data;
  }

  /// Fetch a worker by ID. Used by [UserBloc] on login.
  Future<Map<String, dynamic>> getWorkerById(String userId) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/workers/$userId'),
        headers: headers,
      ).timeout(_timeout);
      final data = jsonDecode(res.body);
      if (data is! Map<String, dynamic>) throw Exception('Invalid response');
      if (res.statusCode == 200) {
        return (data['user'] as Map<String, dynamic>?) ?? data;
      }
      throw Exception(data['error'] ?? 'Failed to fetch worker');
    } catch (_) {
      // Backend unreachable — return empty so MockDataService takes over
      return {};
    }
  }

  /// Cancel an active policy. Used by [PolicyBloc].
  Future<Map<String, dynamic>> cancelPolicy(String userId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/policies/cancel'),
      headers: headers,
      body: jsonEncode({'user_id': userId}),
    );
    return _decodeMap(res);
  }

  /// Best-effort onboarding flag update on the worker record. Used by [UserBloc].
  Future<void> updateWorkerOnboarding(String userId) async {
    try {
      await http.patch(
        Uri.parse('$baseUrl/workers/$userId'),
        headers: headers,
        body: jsonEncode({'onboarding_complete': true}),
      );
    } on Exception {
      // Best-effort — not critical.
    }
  }

  Future<Map<String, dynamic>> registerWorker({
    required String name,
    required String phone,
    required String zone,
    required String city,
    required String platform,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/workers/register'),
        headers: headers,
        body: jsonEncode({
          'name': name,
          'phone': phone,
          'zone': zone,
          'city': city,
          'platform': platform,
        }),
      ).timeout(_timeout);
      final data = jsonDecode(res.body);
      if (data is! Map<String, dynamic>) throw Exception('Invalid response');
      if (res.statusCode == 201 || res.statusCode == 200) return data;
      throw Exception(data['error'] ?? 'Registration failed');
    } catch (_) {
      // Backend unreachable on real device — return a mock worker so onboarding completes
      // Backend unreachable on real device — return a mock worker so onboarding completes
      return {
        'user': {
          'id': 'mock-${phone.replaceAll(RegExp(r'\D'), '')}-001',
          'name': name,
          'phone': phone,
          'zone': zone,
          'city': city,
          'platform': platform,
          'onboarding_complete': false,
        }
      };
    }
  }

  Future<Map<String, dynamic>> createPolicy({
    required String userId,
    required String planTier,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/policies/create'),
        headers: headers,
        body: jsonEncode({'user_id': userId, 'plan_tier': planTier}),
      ).timeout(_timeout);
      final data = jsonDecode(res.body);
      if (data is! Map<String, dynamic>) throw Exception('Invalid response');
      if (res.statusCode == 201 || res.statusCode == 200) return data;
      throw Exception(data['error'] ?? 'Policy creation failed');
    } catch (_) {
      SharedPreferences.getInstance().then((prefs) => prefs.setString('mockPlanTier', planTier));
      return {
        'policy': {
          'id': 'mock-policy-${DateTime.now().millisecondsSinceEpoch}',
          'plan_tier': planTier,
        }
      };
    }
  }

  Future<Map<String, dynamic>> getPolicy(String userId) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/policies/$userId'),
        headers: headers,
      ).timeout(_timeout);
      final data = jsonDecode(res.body);
      if (data is! Map<String, dynamic>) throw Exception('Invalid response');
      if (res.statusCode == 200) return data;
      throw Exception(data['error'] ?? 'Failed to fetch policy');
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      final tier = prefs.getString('mockPlanTier') ?? 'Standard Shield';
      return {
        'policy': {
          'id': 'mock-policy',
          'plan_tier': tier,
          'weekly_premium': tier == 'Full Shield' ? 79 : (tier == 'Standard Shield' ? 59 : 35),
          'base_premium': tier == 'Full Shield' ? 79 : (tier == 'Standard Shield' ? 59 : 35),
          'zone_adjustment': 0,
          'status': 'active',
        }
      };
    }
  }

  Future<Map<String, dynamic>> createClaim({
    required String userId,
    required String triggerType,
    required double severity,
    required double durationHours,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/claims/create'),
        headers: headers,
        body: jsonEncode({
          'user_id': userId,
          'trigger_type': triggerType,
          'severity': severity,
          'duration_hours': durationHours,
        }),
      ).timeout(_timeout);
      final data = jsonDecode(res.body);
      if (data is! Map<String, dynamic>) throw Exception('Invalid response');
      if (res.statusCode == 201 || res.statusCode == 200) return data;
      throw Exception(data['error'] ?? 'Claim creation failed');
    } catch (_) {
      return {'claim': null};
    }
  }

  Future<Map<String, dynamic>> getClaims(String userId) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/claims/$userId'),
        headers: headers,
      ).timeout(_timeout);
      final data = jsonDecode(res.body);
      if (data is! Map<String, dynamic>) throw Exception('Invalid response');
      if (res.statusCode == 200) return data;
      throw Exception(data['error'] ?? 'Failed to fetch claims');
    } catch (_) {
      return {'claims': []};
    }
  }

  Future<Map<String, dynamic>> getWallet(String userId) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/wallet/$userId'),
        headers: headers,
      ).timeout(_timeout);
      final data = jsonDecode(res.body);
      if (data is! Map<String, dynamic>) throw Exception('Invalid response');
      if (res.statusCode == 200) return data;
      throw Exception(data['error'] ?? 'Failed to fetch wallet');
    } catch (_) {
      return {'balance': 0, 'transactions': []};
    }
  }

  /// Shadow policy estimate from zone [disruption_events] (falls back to empty map on error).
  Future<Map<String, dynamic>> getShadowSummary(String userId, {int days = 14}) async {
    try {
      final res = await http
          .get(
            Uri.parse(
              '$baseUrl/policies/shadow/${Uri.encodeComponent(userId)}?days=$days',
            ),
            headers: headers,
          )
          .timeout(_timeout);
      if (res.statusCode == 404) return {};
      final data = jsonDecode(res.body.isEmpty ? '{}' : res.body);
      if (data is! Map<String, dynamic>) throw Exception('Invalid response');
      if (res.statusCode >= 400) {
        throw Exception(data['error'] ?? 'Request failed');
      }
      return data;
    } catch (_) {
      return {};
    }
  }

  /// Server nonce for Play Integrity (Android). Pair with [obtainPlayIntegrityToken].
  Future<Map<String, dynamic>> getPlayIntegrityNonce() async {
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/integrity/play/nonce'),
            headers: headers,
          )
          .timeout(_timeout);
      final raw = res.body.isEmpty ? '{}' : res.body;
      final data = jsonDecode(raw);
      if (data is! Map<String, dynamic>) return {};
      if (res.statusCode != 200) return {};
      return data;
    } catch (_) {
      return {};
    }
  }

  /// Optional: verify token only (manual claims usually send [integrityToken] on submit).
  Future<Map<String, dynamic>> verifyPlayIntegrity({
    required String integrityToken,
    String? packageName,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/integrity/play/verify'),
            headers: headers,
            body: jsonEncode({
              'integrity_token': integrityToken,
              if (packageName != null) 'package_name': packageName,
            }),
          )
          .timeout(_timeout);
      final data = jsonDecode(res.body.isEmpty ? '{}' : res.body);
      return data is Map<String, dynamic> ? data : {};
    } catch (_) {
      return {'ok': false, 'play_integrity_pass': false};
    }
  }

  /// FPS-style body → `{ reasons, summary }` from `/claims/explanation`.
  Future<Map<String, dynamic>> postClaimExplanation(Map<String, dynamic> body) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/claims/explanation'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      final raw = res.body.isEmpty ? '{}' : res.body;
      final data = jsonDecode(raw);
      if (data is! Map<String, dynamic>) throw Exception('Invalid response');
      if (res.statusCode >= 400) {
        return {
          'reasons': [
            {
              'title': 'Request failed',
              'detail': data['error']?.toString() ?? 'Could not build explanation',
              'severity': 'info',
            },
          ],
          'summary': '',
        };
      }
      return data;
    } catch (_) {
      return {
        'reasons': [
          {
            'title': 'Offline',
            'detail': 'Showing sample signals until the server is reachable.',
            'severity': 'info',
          },
        ],
        'summary': 'Offline',
      };
    }
  }

  /// Haversine zone depth vs configured dark-store hub (no auth).
  Future<Map<String, dynamic>> computeZoneDepth({
    required double lat,
    required double lon,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/workers/zone-depth/compute'),
            headers: headers,
            body: jsonEncode({'lat': lat, 'lon': lon}),
          )
          .timeout(_timeout);
      return _decodeMap(res);
    } catch (_) {
      return {};
    }
  }

  /// Persists [users.zone_depth_score] for underwriting.
  Future<Map<String, dynamic>> updateWorkerZoneDepth({
    required String userId,
    required double lat,
    required double lon,
  }) async {
    try {
      final res = await http
          .patch(
            Uri.parse('$baseUrl/workers/$userId/zone-depth'),
            headers: headers,
            body: jsonEncode({'lat': lat, 'lon': lon}),
          )
          .timeout(_timeout);
      return _decodeMap(res);
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, dynamic>> getDisruptions(
    String zone, {
    int? issScore,
  }) async {
    try {
      final encoded = Uri.encodeComponent(zone);
      final q = issScore != null ? '?iss=$issScore' : '';
      final res = await http.get(
        Uri.parse('$baseUrl/disruptions/$encoded$q'),
        headers: headers,
      ).timeout(_timeout);
      final data = jsonDecode(res.body);
      if (data is! Map<String, dynamic>) throw Exception('Invalid response');
      if (res.statusCode == 200) return data;
      throw Exception(data['error'] ?? 'Failed to fetch disruptions');
    } catch (_) {
      return {'disruptions': [], 'active': false};
    }
  }

  // ── Instance helpers used by screens ──────────────────────────────────────

  Future<Map<String, dynamic>> registerWorkerInstance({
    required String name,
    required String phone,
    required String zone,
    required String city,
    required String platform,
  }) =>
      registerWorker(
        name: name,
        phone: phone,
        zone: zone,
        city: city,
        platform: platform,
      );

  Future<Map<String, dynamic>> createPolicyInstance({
    required String userId,
    required String planTier,
  }) =>
      createPolicy(
        userId: userId,
        planTier: planTier,
      );

  /// Active policy document only (throws if missing).
  Future<Map<String, dynamic>> getPolicyInstance(String userId) async {
    final data = await getPolicy(userId);
    final p = data['policy'];
    if (p is Map<String, dynamic>) return p;
    throw Exception('Failed to fetch policy');
  }

  Future<Map<String, dynamic>> getClaimsInstance(String userId) =>
      getClaims(userId);

  Future<Map<String, dynamic>> getWalletInstance(String userId) =>
      getWallet(userId);

  /// Shape expected by older UI: `{ 'disruptions': List }`.
  Future<Map<String, dynamic>> getDisruptionsInstance(String zone) async {
    final body = await getDisruptions(zone);
    final raw = body['disruptions'] ?? body['disruption_events'];
    final events = raw is List<dynamic> ? raw : <dynamic>[];
    return {'disruptions': events};
  }

  // ── Static compatibility (MockDataService & helpers) ────────────────────

  static Future<Map<String, dynamic>?> getWorkerByPhone(String phone) async {
    try {
      final encoded = Uri.encodeComponent(phone);
      final res = await http.get(
        Uri.parse('$baseUrl/workers/phone/$encoded'),
        headers: instance.headers,
      ).timeout(_timeout);
      if (res.statusCode == 404) return null;
      final data = instance._decodeMap(res);
      return data['user'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  /// Policy row only (or null) — [MockDataService] helper.
  static Future<Map<String, dynamic>?> getPolicyDocument(String userId) async {
    try {
      final data = await instance.getPolicy(userId);
      return data['policy'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  static Future<List<dynamic>> getClaimsList(String userId) async {
    final data = await instance.getClaims(userId);
    return data['claims'] as List<dynamic>? ?? [];
  }

  static Future<Map<String, dynamic>> getWalletData(String userId) =>
      instance.getWallet(userId);

  static Future<List<dynamic>> getDisruptionEvents(String zone) async {
    final data = await instance.getDisruptions(zone);
    final raw = data['disruptions'] ?? data['disruption_events'];
    return raw is List<dynamic> ? raw : <dynamic>[];
  }

  static Future<Map<String, dynamic>> submitClaim({
    required String userId,
    required String triggerType,
    required double severity,
    required double durationHours,
  }) =>
      instance.createClaim(
        userId: userId,
        triggerType: triggerType,
        severity: severity,
        durationHours: durationHours,
      );

  static Future<Map<String, dynamic>> walletCredit({
    required String userId,
    required int amount,
    required String description,
    String? reference,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/wallet/credit'),
      headers: instance.headers,
      body: jsonEncode({
        'user_id': userId,
        'amount': amount,
        'description': description,
        'reference': reference,
      }),
    );
    return instance._decodeMap(res);
  }

  static Future<Map<String, dynamic>> walletDebit({
    required String userId,
    required int amount,
    required String description,
    String? reference,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/wallet/debit'),
      headers: instance.headers,
      body: jsonEncode({
        'user_id': userId,
        'amount': amount,
        'description': description,
        'reference': reference,
      }),
    );
    return instance._decodeMap(res);
  }

  static Future<Map<String, dynamic>> createDisruption({
    required String zone,
    required String triggerType,
    required double severity,
    double rainfallMm = 0,
    double temperatureC = 0,
    int aqi = 0,
    required String startedAt,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/disruptions/create'),
      headers: instance.headers,
      body: jsonEncode({
        'zone': zone,
        'trigger_type': triggerType,
        'severity': severity,
        'rainfall_mm': rainfallMm,
        'temperature_c': temperatureC,
        'aqi': aqi,
        'started_at': startedAt,
      }),
    );
    return instance._decodeMap(res);
  }

  Future<Map<String, dynamic>> submitManualClaim({
    required String userId,
    required String disruptionType,
    String? description,
    List<String>? evidenceUrls,
    int? deviceSignalStrength,
    String? integrityToken,
    Map<String, dynamic>? sensorFeatures,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/claims/manual'),
        headers: headers,
        body: jsonEncode({
          'user_id':                userId,
          'disruption_type':        disruptionType,
          'description':            description,
          'evidence_urls':          evidenceUrls ?? [],
          'device_signal_strength': deviceSignalStrength,
          'sensor_features':        sensorFeatures,
          if (integrityToken != null && integrityToken.isNotEmpty)
            'integrity_token': integrityToken,
        }),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 201) return data;
      
      // Fallback to mock on API error
      String mockNote = 'Claim logged — review within 4 hours';
      String mockStatus = 'PENDING';
      
      if (sensorFeatures != null) {
        final jitter = sensorFeatures['gps_jitter'];
        if (jitter != null && jitter == 0.0) {
           mockNote = 'FRAUD ALERT: GPS Spoofing Detected (0.0 Jitter).';
           mockStatus = 'FLAGGED';
        } else if (jitter != null && jitter > 0.0) {
           mockNote = 'Sensors Validated: Natural GPS Variance Detected.';
           mockStatus = 'APPROVED';
        }
      }

      return {
        'claim': {
          'id': 'CLM_MOCK_${DateTime.now().millisecondsSinceEpoch}',
          'display_name': 'Manual Report (Mock)',
          'status': mockStatus,
          'gross_payout': 100,
          'tranche1_amount': 70,
          'tranche2_amount': 30,
          'provisional_note': mockNote,
          '_mock': true,
        }
      };
    } catch (e) {
      String mockNote = 'Offline mode — will sync when connected';
      String mockStatus = 'PENDING';
      
      if (sensorFeatures != null) {
        final jitter = sensorFeatures['gps_jitter'];
        if (jitter != null && jitter == 0.0) {
           mockNote = 'Offline FRAUD ALERT: GPS Spoofing (Jitter 0.0).';
           mockStatus = 'FLAGGED';
        } else if (jitter != null && jitter > 0.0) {
           mockNote = 'Offline Validated: Natural GPS Variance.';
           mockStatus = 'APPROVED';
        }
      }

      return {
        'claim': {
          'id': 'CLM_MOCK_ERR',
          'display_name': 'Manual Report (Mock)',
          'status': mockStatus,
          'gross_payout': 100,
          'tranche1_amount': 70,
          'tranche2_amount': 30,
          'provisional_note': mockNote,
          '_mock': true,
        }
      };
    }
  }
}
