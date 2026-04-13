import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MLLiveScreen extends StatefulWidget {
  const MLLiveScreen({super.key});

  @override
  State<MLLiveScreen> createState() => _MLLiveScreenState();
}

class _MLLiveScreenState extends State<MLLiveScreen> {
  
  Map<String, dynamic> _issResult    = {};
  Map<String, dynamic> _fraudResult  = {};
  Map<String, dynamic> _premiumResult = {};
  Map<String, dynamic> _forecastResult = {};
  bool _loading = false;
  
  final _mlUrl = 'https://hustlr-ml-complete.onrender.com'; // your ML service

  @override
  void initState() {
    super.initState();
    _runAllModels();
  }

  Future<void> _runAllModels() async {
    setState(() => _loading = true);
    
    await Future.wait([
      _runISS(),
      _runFraud(),
      _runPremium(),
      _runForecast(),
    ]);
    
    setState(() => _loading = false);
  }

  Future<void> _runISS() async {
    try {
      final res = await http.post(
        Uri.parse('$_mlUrl/iss'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'zone_flood_risk':       0.75,
          'avg_daily_income':      600.0,
          'disruption_freq_12mo':  8,
          'platform_tenure_weeks': 4,
          'city':                  'Chennai',
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (res.statusCode == 200) {
        setState(() => _issResult = jsonDecode(res.body));
      }
    } catch (e) {
      setState(() => _issResult = {
        'iss_score': 62, 'tier': 'AMBER',
        'recommendation': 'standard', '_mock': true,
      });
    }
  }

  Future<void> _runFraud() async {
    try {
      final res = await http.post(
        Uri.parse('$_mlUrl/ml/fraud-score'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'worker_id': 'demo-karthik',
          'zone_id': 'adyar',
          'claim_timestamp': DateTime.now().toIso8601String(),
          'feature_vector': {
            'claim_latency_seconds': 120.0,
            'simultaneous_zone_claims': 2,
            'account_age_days': 45,
            'historical_clean_claim_ratio': 0.85,
            'shift_gap_count_today': 0,
            'device_shared_with_n_accounts': 1,
            'zone_depth_score': 0.84,
            'orders_completed_during_disruption': 0,
            'is_mock_location_ever': false,
          },
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (res.statusCode == 200) {
        setState(() => _fraudResult = jsonDecode(res.body));
      }
    } catch (e) {
      setState(() => _fraudResult = {
        'is_anomalous': false,
        'anomaly_score': 0.14,
        'top_features': ['claim_latency_seconds', 'zone_depth_score'],
        '_mock': true,
      });
    }
  }

  Future<void> _runPremium() async {
    try {
      final res = await http.post(
        Uri.parse('$_mlUrl/premium'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'plan_tier': 'standard',
          'zone': 'Adyar Dark Store Zone',
          'iss_score': _issResult['iss_score'] ?? 62,
          'previous_premium': 0.0,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (res.statusCode == 200) {
        setState(() => _premiumResult = jsonDecode(res.body));
      }
    } catch (e) {
      setState(() => _premiumResult = {
        'final_premium': 60, 'base_premium': 49,
        'zone_adjustment': 11, '_mock': true,
      });
    }
  }

  Future<void> _runForecast() async {
    try {
      final res = await http.get(
        Uri.parse('$_mlUrl/forecast/adyar?days=3'),
      ).timeout(const Duration(seconds: 15));
      
      if (res.statusCode == 200) {
        setState(() => _forecastResult = jsonDecode(res.body));
      }
    } catch (e) {
      setState(() => _forecastResult = {
        'zone_id': 'adyar',
        'forecasts': [
          {'date': '2026-04-14', 'disruption_probability': 0.72,
           'trigger_type': 'heavy_rain', 'predicted_rainfall_mm': 68.4},
          {'date': '2026-04-15', 'disruption_probability': 0.08,
           'trigger_type': 'none', 'predicted_rainfall_mm': 2.1},
          {'date': '2026-04-16', 'disruption_probability': 0.61,
           'trigger_type': 'heavy_rain', 'predicted_rainfall_mm': 54.2},
        ],
        '_mock': true,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        title: Row(children: [
          Container(width: 8, height: 8,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF10B981))),
          const SizedBox(width: 8),
          const Text('ML Models — Live', style: TextStyle(color: Colors.white, fontSize: 16)),
          if (_loading) ...[
            const SizedBox(width: 10),
            const SizedBox(width: 14, height: 14,
              child: CircularProgressIndicator(color: Color(0xFF10B981), strokeWidth: 2)),
          ],
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF10B981)),
            onPressed: _runAllModels,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF10B981),
        onRefresh: _runAllModels,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildModelCard(
                'M1 — ISS Score',
                'XGBoost — Income Stability',
                const Color(0xFF10B981),
                _issResult,
                [
                  _resultRow('ISS Score', '${_issResult['iss_score'] ?? "—"} / 100'),
                  _resultRow('Risk Tier', _issResult['tier'] ?? '—'),
                  _resultRow('Plan Recommendation', _issResult['recommendation'] ?? '—'),
                ],
              ),
              const SizedBox(height: 12),
              _buildModelCard(
                'M2/M3 — Fraud Detection',
                'Isolation Forest — 50k samples trained',
                const Color(0xFFF59E0B),
                _fraudResult,
                [
                  _resultRow('Anomaly Score',
                    '${((_fraudResult['anomaly_score'] ?? 0.14) * 100).toStringAsFixed(1)} / 100'),
                  _resultRow('Decision',
                    (_fraudResult['is_anomalous'] == true) ? '🔴 FLAGGED' : '🟢 CLEAN'),
                  _resultRow('Top Signal',
                    (_fraudResult['top_features'] as List?)?.first ?? 'claim_latency'),
                ],
              ),
              const SizedBox(height: 12),
              _buildModelCard(
                'M7 — Prophet Forecast',
                'Facebook Prophet — 10 Chennai zones',
                const Color(0xFF3B82F6),
                _forecastResult,
                [
                  if ((_forecastResult['forecasts'] as List?)?.isNotEmpty == true)
                    ...(_forecastResult['forecasts'] as List)
                      .take(3)
                      .map((f) => _resultRow(
                        f['date'],
                        '${((f['disruption_probability'] ?? 0) * 100).toStringAsFixed(0)}% — ${f['trigger_type']}',
                      ))
                      .toList(),
                ],
              ),
              const SizedBox(height: 12),
              _buildModelCard(
                'Premium Calculator',
                'Zone + ISS adjusted pricing',
                const Color(0xFF8B5CF6),
                _premiumResult,
                [
                  _resultRow('Plan', 'Standard Shield'),
                  _resultRow('Base Premium', '₹${_premiumResult['base_premium'] ?? 49}'),
                  _resultRow('Zone Adjustment', '+₹${_premiumResult['zone_adjustment'] ?? 5}'),
                  _resultRow('Final Premium', '₹${_premiumResult['final_premium'] ?? 49}/week'),
                ],
              ),
              const SizedBox(height: 24),
              // Mock data indicator
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _anyMock()
                    ? '⚠️ Some results using fallback data — tap ↻ to retry live models'
                    : '✅ All results from live ML service',
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _anyMock() =>
    _issResult['_mock'] == true ||
    _fraudResult['_mock'] == true ||
    _forecastResult['_mock'] == true;

  Widget _buildModelCard(
    String title,
    String subtitle,
    Color color,
    Map<String, dynamic> data,
    List<Widget> rows,
  ) {
    final isMock = data['_mock'] == true;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isMock ? Colors.orange : color,
                  ),
                ),
                const SizedBox(width: 8),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(
                    color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                ]),
                const Spacer(),
                if (isMock)
                  const Text('MOCK', style: TextStyle(color: Colors.orange, fontSize: 9))
                else
                  Text('LIVE', style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: rows),
          ),
        ],
      ),
    );
  }

  Widget _resultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(value, style: const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
