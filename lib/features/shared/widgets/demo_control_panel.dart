import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// If your services are directly inside lib/services:
import '../../../services/mock_data_service.dart';

void showDemoPanel(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      final mockData = Provider.of<MockDataService>(
        context, listen: false);

      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Title
            const Text(
              "Demo Controls",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const Text(
              "Internal use only — tap to simulate disruptions",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Rain button
            _DemoButton(
              icon: Icons.water_drop,
              label: "Trigger Rain Disruption",
              subtitle: "Simulates 67mm rainfall → ₹120 payout",
              color: const Color(0xFF1976D2),
              bgColor: const Color(0xFFE3F2FD),
              onTap: () {
                Navigator.pop(context);
                mockData.triggerRainDisruption();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "🌧 Rain disruption detected — claim processing"),
                    backgroundColor: Color(0xFF1976D2),
                    duration: Duration(seconds: 3),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),

            // Downtime button
            _DemoButton(
              icon: Icons.cloud_off,
              label: "Trigger Platform Downtime",
              subtitle: "Simulates Zepto outage → ₹140 payout",
              color: const Color(0xFF00897B),
              bgColor: const Color(0xFFE0F2F1),
              onTap: () {
                Navigator.pop(context);
                mockData.triggerPlatformDowntime();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "📵 Platform downtime detected — claim processing"),
                    backgroundColor: Color(0xFF00897B),
                    duration: Duration(seconds: 3),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),

            // Heat button
            _DemoButton(
              icon: Icons.thermostat,
              label: "Trigger Extreme Heat",
              subtitle: "Simulates 43°C heatwave → ₹130 payout",
              color: const Color(0xFFF57C00),
              bgColor: const Color(0xFFFFF8E1),
              onTap: () {
                Navigator.pop(context);
                mockData.triggerExtremeHeat();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "🌡 Extreme heat detected — claim processing"),
                    backgroundColor: Color(0xFFF57C00),
                    duration: Duration(seconds: 3),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),

            // Reset button
            _DemoButton(
              icon: Icons.refresh,
              label: "Reset Demo",
              subtitle: "Restores all data to default state",
              color: Colors.grey,
              bgColor: const Color(0xFFF3F4F6),
              onTap: () {
                Navigator.pop(context);
                mockData.resetDemo();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Demo reset to default state"),
                    backgroundColor: Colors.grey,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    },
  );
}

class _DemoButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _DemoButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: color,
                    ),
                  ),
                  Text(subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }
}
