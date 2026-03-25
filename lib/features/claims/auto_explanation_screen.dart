import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/colors.dart' as app_colors;

class AutoExplanationScreen extends StatelessWidget {
  const AutoExplanationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: app_colors.background,
      appBar: AppBar(
        title: const Text('Why your claim was flagged', style: TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: app_colors.errorRed,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.warning_amber_rounded, color: app_colors.errorRed, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Our fraud engine detected the following signals:',
              style: TextStyle(fontSize: 16, color: app_colors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildSignalItem(Icons.wifi, 'Home network detected', 'Your Wi-Fi showed a home SSID during the disruption window'),
            const SizedBox(height: 16),
            _buildSignalItem(Icons.directions_walk, 'No outdoor motion detected', 'Your device motion was below your usual outdoor work pattern'),
            const Spacer(),
            const Text('If you were genuinely affected, appeal below.\nWe review within 4 hours.', textAlign: TextAlign.center, style: TextStyle(color: app_colors.textPrimary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: app_colors.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  // Mock open camera for EXIF liveness photo
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening camera for EXIF photo...')),
                  );
                },
                child: const Text('Submit Appeal →', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Appeal resolved within 4 hours.\nFirst-time flags are treated as caution only.', textAlign: TextAlign.center, style: TextStyle(color: app_colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSignalItem(IconData icon, String title, String detail) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: app_colors.errorRed.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: app_colors.errorRed.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: app_colors.errorRed, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: app_colors.errorRed, fontSize: 15)),
                const SizedBox(height: 4),
                Text(detail, style: const TextStyle(color: app_colors.textPrimary, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
