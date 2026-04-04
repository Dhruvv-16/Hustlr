import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';

class MlTesterScreen extends StatefulWidget {
  const MlTesterScreen({super.key});

  @override
  State<MlTesterScreen> createState() => _MlTesterScreenState();
}

class _MlTesterScreenState extends State<MlTesterScreen> {
  // Uses the Node backend to proxy the request to the ML service
  String _baseUrl = '${ApiService.baseUrl}/ml';
  final TextEditingController _nlpController = TextEditingController(text: 'Extreme flooding in Adyar right now');
  
  double _trafficSpeed = 15.0;
  double _trafficBaseline = 35.0;
  
  String _responseLog = '';
  bool _isLoading = false;

  Future<void> _testNLP() async {
    setState(() { _isLoading = true; _responseLog = 'Testing NLP...'; });
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/nlp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': _nlpController.text,
          'require_dual_source': false,
          'sources': {'imd': 0.9}
        }),
      ).timeout(const Duration(seconds: 70));
      setState(() { _responseLog = 'Status: ${res.statusCode}\\nResponse:\\n${const JsonEncoder.withIndent('  ').convert(jsonDecode(res.body))}'; });
    } catch (e) {
      setState(() { _responseLog = 'Error: $e'; });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _testTraffic() async {
    setState(() { _isLoading = true; _responseLog = 'Testing Traffic...'; });
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/traffic'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'zone': 'Adyar',
          'traffic_speed_kmh': _trafficSpeed,
          'baseline_speed_kmh': _trafficBaseline,
          'traffic_duration_min': 45,
          'news_confidence': 0.8,
          'time_of_day': 18,
          'is_weekend': false,
        }),
      ).timeout(const Duration(seconds: 70));
      setState(() { _responseLog = 'Status: ${res.statusCode}\\nResponse:\\n${const JsonEncoder.withIndent('  ').convert(jsonDecode(res.body))}'; });
    } catch (e) {
      setState(() { _responseLog = 'Error: $e'; });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _testFraud() async {
    setState(() { _isLoading = true; _responseLog = 'Testing Fraud...'; });
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/fraud'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'days_since_onboard': 30, 'avg_daily_income': 400, 'platform_app_inactive': 0,
          'gps_zone_mismatch': 1, 'claim_latency_under30s': 1, 'battery_charging': 1,
          'ip_home_match': 0, 'accelerometer_idle': 1, 'hw_fingerprint_match': 0, 'wifi_home_ssid': 0
        }),
      ).timeout(const Duration(seconds: 70));
      setState(() { _responseLog = 'Status: ${res.statusCode}\\nResponse:\\n${const JsonEncoder.withIndent('  ').convert(jsonDecode(res.body))}'; });
    } catch (e) {
      setState(() { _responseLog = 'Error: $e'; });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final green = isDark ? const Color(0xFF3FFF8B) : const Color(0xFF1B5E20);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ML Data Tester (Demo)', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Note: This screen now proxies requests through the Node.js backend. If you get a TimeoutException, ensure the backend is running and can reach the ML service.', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.blueAccent)),
            const SizedBox(height: 12),
            TextField(
              onChanged: (val) => _baseUrl = val,
              decoration: const InputDecoration(labelText: 'Backend URL / IP', hintText: 'http://127.0.0.1:8000', border: OutlineInputBorder()),
              controller: TextEditingController(text: _baseUrl),
            ),
            const SizedBox(height: 16),
            const Text('NLP Disruption Model', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            TextField(
              controller: _nlpController,
              decoration: const InputDecoration(labelText: 'Test claim text', border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: green, foregroundColor: Colors.white),
              onPressed: _isLoading ? null : _testNLP,
              child: const Text('Test NLP Engine'),
            ),
            const Divider(height: 32),

            const Text('Traffic Predictor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Row(
              children: [
                Expanded(child: Text('Cur Speed: ${_trafficSpeed.toStringAsFixed(1)} km/h')),
                Expanded(
                  flex: 2,
                  child: Slider(
                    value: _trafficSpeed, min: 0, max: 60,
                    activeColor: green,
                    onChanged: (val) => setState(() => _trafficSpeed = val),
                  ),
                ),
              ],
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: green, foregroundColor: Colors.white),
              onPressed: _isLoading ? null : _testTraffic,
              child: const Text('Test Traffic Engine'),
            ),
            const Divider(height: 32),

            const Text('Fraud & Bot Engine', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: green, foregroundColor: Colors.white),
              onPressed: _isLoading ? null : _testFraud,
              child: const Text('Simulate Suspicious Telemetry'),
            ),
            const Divider(height: 32),

            const Text('Response Output', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: isDark ? Colors.black : Colors.grey[200], borderRadius: BorderRadius.circular(8)),
              child: SelectableText(_responseLog, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
