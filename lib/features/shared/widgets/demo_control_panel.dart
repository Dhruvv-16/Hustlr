import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/api_service.dart';
import '../../../services/storage_service.dart';
import '../../../core/router/app_router.dart';

void showDemoPanel(BuildContext context, {VoidCallback? onSubmit}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetCtx) {
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
            ),
            const Text(
              "Internal use only — file simulated disruption claims via backend",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Rain button
            _DemoButton(
              icon: Icons.water_drop,
              label: "Trigger Rain Disruption",
              subtitle: "Files rain claim → ₹120 payout",
              color: const Color(0xFF1976D2),
              bgColor: const Color(0xFFE3F2FD),
              onTap: () async {
                Navigator.pop(sheetCtx);
                await _fileClaim(context, 'rain');
                if (onSubmit != null) onSubmit();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("🌧 Rain claim filed — processing"),
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
              subtitle: "Files downtime claim → ₹140 payout",
              color: const Color(0xFF00897B),
              bgColor: const Color(0xFFE0F2F1),
              onTap: () async {
                Navigator.pop(sheetCtx);
                await _fileClaim(context, 'platform_downtime');
                if (onSubmit != null) onSubmit();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("📵 Downtime claim filed — processing"),
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
              subtitle: "Files heat claim → ₹130 payout",
              color: const Color(0xFFF57C00),
              bgColor: const Color(0xFFFFF8E1),
              onTap: () async {
                Navigator.pop(sheetCtx);
                await _fileClaim(context, 'extreme_heat');
                if (onSubmit != null) onSubmit();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("🌡 Heat claim filed — processing"),
                    backgroundColor: Color(0xFFF57C00),
                    duration: Duration(seconds: 3),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),

            // Face Liveness button
            _DemoButton(
              icon: Icons.face_unlock_outlined,
              label: "Step-Up Identity Check",
              subtitle: "Demo AWS Rekognition face liveness (Phase 3)",
              color: const Color(0xFF6A1B9A),
              bgColor: const Color(0xFFF3E5F5),
              onTap: () {
                Navigator.pop(sheetCtx);
                context.push(
                  '${AppRoutes.stepUpAuth}?reason=Demo+triggered+by+judge+review',
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

/// Files a simulated claim via ApiService
Future<void> _fileClaim(BuildContext context, String triggerType) async {
  try {
    final userId = await StorageService.instance.getUserId();
    if (userId == null) return;
    await ApiService.instance.fileClaim(userId: userId, triggerType: triggerType);
  } catch (_) {
    // Silently fail — demo panel only
  }
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
                  Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
