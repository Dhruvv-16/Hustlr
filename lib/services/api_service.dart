import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class ApiService {
  // Use 127.0.0.1 to bypass Windows IPv6 routing bug in Chrome, or 10.0.2.2 for Android emulators
  static String get baseUrl => kIsWeb ? 'http://127.0.0.1:3000' : 'http://10.0.2.2:3000';
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

  Future<Map<String, dynamic>> registerWorker({
    required String name,
    required String phone,
    required String zone,
    required String city,
    required String platform,
  }) async {
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
    );
    final data = jsonDecode(res.body);
    if (data is! Map<String, dynamic>) throw Exception('Invalid response');
    if (res.statusCode == 201 || res.statusCode == 200) return data;
    throw Exception(data['error'] ?? 'Registration failed');
  }

  Future<Map<String, dynamic>> createPolicy({
    required String userId,
    required String planTier,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/policies/create'),
      headers: headers,
      body: jsonEncode({
        'user_id': userId,
        'plan_tier': planTier,
      }),
    );
    final data = jsonDecode(res.body);
    if (data is! Map<String, dynamic>) throw Exception('Invalid response');
    if (res.statusCode == 201 || res.statusCode == 200) return data;
    throw Exception(data['error'] ?? 'Policy creation failed');
  }

  Future<Map<String, dynamic>> getPolicy(String userId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/policies/$userId'),
      headers: headers,
    );
    final data = jsonDecode(res.body);
    if (data is! Map<String, dynamic>) throw Exception('Invalid response');
    if (res.statusCode == 200) return data;
    throw Exception(data['error'] ?? 'Failed to fetch policy');
  }

  Future<Map<String, dynamic>> createClaim({
    required String userId,
    required String triggerType,
    required double severity,
    required double durationHours,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/claims/create'),
      headers: headers,
      body: jsonEncode({
        'user_id': userId,
        'trigger_type': triggerType,
        'severity': severity,
        'duration_hours': durationHours,
      }),
    );
    final data = jsonDecode(res.body);
    if (data is! Map<String, dynamic>) throw Exception('Invalid response');
    if (res.statusCode == 201 || res.statusCode == 200) return data;
    throw Exception(data['error'] ?? 'Claim creation failed');
  }

  Future<Map<String, dynamic>> getClaims(String userId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/claims/$userId'),
      headers: headers,
    );
    final data = jsonDecode(res.body);
    if (data is! Map<String, dynamic>) throw Exception('Invalid response');
    if (res.statusCode == 200) return data;
    throw Exception(data['error'] ?? 'Failed to fetch claims');
  }

  Future<Map<String, dynamic>> getWallet(String userId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/wallet/$userId'),
      headers: headers,
    );
    final data = jsonDecode(res.body);
    if (data is! Map<String, dynamic>) throw Exception('Invalid response');
    if (res.statusCode == 200) return data;
    throw Exception(data['error'] ?? 'Failed to fetch wallet');
  }

  Future<Map<String, dynamic>> getDisruptions(String zone) async {
    final encoded = Uri.encodeComponent(zone);
    final res = await http.get(
      Uri.parse('$baseUrl/disruptions/$encoded'),
      headers: headers,
    );
    final data = jsonDecode(res.body);
    if (data is! Map<String, dynamic>) throw Exception('Invalid response');
    if (res.statusCode == 200) return data;
    throw Exception(data['error'] ?? 'Failed to fetch disruptions');
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
    final events = body['disruption_events'] as List<dynamic>? ?? [];
    return {'disruptions': events};
  }

  // ── Static compatibility (MockDataService & helpers) ────────────────────

  static Future<Map<String, dynamic>?> getWorkerByPhone(String phone) async {
    try {
      final encoded = Uri.encodeComponent(phone);
      final res = await http.get(
        Uri.parse('$baseUrl/workers/phone/$encoded'),
        headers: instance.headers,
      );
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
    return data['disruption_events'] as List<dynamic>? ?? [];
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
}
