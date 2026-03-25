import 'package:flutter/material.dart';
import '../../core/constants/colors.dart' as app_colors;
import '../../data/mock_data.dart';
import 'package:go_router/go_router.dart';

class ShadowPolicyScreen extends StatelessWidget {
  const ShadowPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: app_colors.background,
      appBar: AppBar(
        title: const Text('What You Missed'),
        backgroundColor: app_colors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: app_colors.primaryGreen,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Color(0x332D6A2D), blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: Column(
                children: [
                  const Text('If you\'d had Standard Shield this fortnight:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 8),
                  Text(
                    '₹${MockData.shadowMissed}',
                    style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
                  ),
                  const Text('in missed payouts', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _shadowStat('₹98', 'Premium cost\n(2 weeks)'),
                      _shadowStat('₹582', 'Net benefit'),
                      _shadowStat('0', 'Claims filed'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Missed events list
            const Text('Events while uninsured:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: app_colors.textPrimary)),
            const SizedBox(height: 12),

            ...MockData.shadowEvents.map((event) => _buildMissedEventCard(event)).toList(),

            const SizedBox(height: 32),

            // CTA
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push('/policy/plans'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: app_colors.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Activate Standard Shield — ₹49/wk', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text('Coverage starts next Monday', style: TextStyle(color: app_colors.textSecondary, fontSize: 12)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _shadowStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _buildMissedEventCard(Map<String, dynamic> event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: app_colors.lightRed, shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, color: app_colors.errorRed, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event['triggerName'] ?? event['trigger'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: app_colors.textPrimary)),
                  Text(event['date'], style: const TextStyle(fontSize: 12, color: app_colors.textSecondary)),
                ],
              ),
            ],
          ),
          Text(
            '₹${event['missed'] ?? event['claimableAmount']}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: app_colors.textPrimary),
          ),
        ],
      ),
    );
  }
}
