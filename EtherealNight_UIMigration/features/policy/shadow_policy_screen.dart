import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import 'package:go_router/go_router.dart';

class ShadowPolicyScreen extends StatelessWidget {
  const ShadowPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final green  = theme.colorScheme.primary;
    final bg     = theme.scaffoldBackgroundColor;
    final btnTxt = isDark ? const Color(0xFF0A0B0A) : Colors.white;
    final subText = isDark ? const Color(0xFF91938D) : const Color(0xFF4A6741);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text('What You Missed',
            style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary hero card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF004734) : const Color(0xFF125117),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: green.withOpacity(isDark ? 0.15 : 0.2),
                    blurRadius: 10, offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    "If you'd had Standard Shield this fortnight:",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
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
            Text('Events while uninsured:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onSurface)),
            const SizedBox(height: 12),

            ...MockData.shadowEvents.map((event) => _buildMissedEventCard(context, event)).toList(),

            const SizedBox(height: 32),

            // CTA
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push('/policy'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: btnTxt,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text('Activate Standard Shield — ₹49/wk',
                    style: TextStyle(color: btnTxt, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text('Coverage starts next Monday',
                  style: TextStyle(color: subText, fontSize: 12)),
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

  Widget _buildMissedEventCard(BuildContext context, Map<String, dynamic> event) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = theme.cardColor;
    final border = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE5E7EB);
    final redBg  = isDark ? const Color(0xFF2D0011) : const Color(0xFFFFEBEE);
    final red    = isDark ? const Color(0xFFFF6B6B) : const Color(0xFFB71C1C);
    final text   = theme.colorScheme.onSurface;
    final sub    = theme.colorScheme.onSurface.withOpacity(0.5);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: redBg, shape: BoxShape.circle),
                child: Icon(Icons.close_rounded, color: red, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event['triggerName'] ?? event['trigger'],
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: text)),
                  Text(event['date'],
                      style: TextStyle(fontSize: 12, color: sub)),
                ],
              ),
            ],
          ),
          Text(
            '₹${event['missed'] ?? event['claimableAmount']}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: text),
          ),
        ],
      ),
    );
  }
}
