import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart' as app_colors;
import '../../services/mock_data_service.dart';

class ClaimDetailScreen extends StatelessWidget {
  final String claimId;

  const ClaimDetailScreen({super.key, required this.claimId});

  @override
  Widget build(BuildContext context) {
    final mockData = Provider.of<MockDataService>(context);
    final claim = mockData.claims.firstWhere(
      (c) => c.id == claimId,
      orElse: () => mockData.claims.first, // fallback
    );

    final bool isApproved = claim.status == 'APPROVED';
    final bool isPending = claim.status == 'PENDING';
    final bool isDeclined = claim.status == 'DECLINED';

    Color statusColor = app_colors.amber;
    if (isApproved) statusColor = app_colors.primaryGreen;
    if (isDeclined) statusColor = app_colors.errorRed;

    IconData triggerIcon = Icons.cloud_rounded;
    if (claim.icon == "downtime") triggerIcon = Icons.cloud_off_rounded;
    if (claim.icon == "heat") triggerIcon = Icons.thermostat_rounded;

    return Scaffold(
      backgroundColor: app_colors.background,
      appBar: AppBar(
        title: const Text('Claim Details', style: TextStyle(color: app_colors.textPrimary, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: app_colors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header
            Icon(triggerIcon, size: 52, color: statusColor),
            const SizedBox(height: 12),
            Text(claim.type, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: app_colors.textPrimary)),
            const SizedBox(height: 4),
            Text(claim.date, style: const TextStyle(fontSize: 14, color: app_colors.textSecondary)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                claim.status,
                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2),
              ),
            ),
            if (isDeclined) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.push('/claims/explanation'),
                child: const Text('See why', style: TextStyle(color: app_colors.errorRed, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
              ),
            ],
            const SizedBox(height: 32),

            // Timeline Stepper
            _buildTimeline(claim.timeline, statusColor),
            const SizedBox(height: 32),

            // Payout Breakdown Card
            if (!isDeclined) _buildPayoutBreakdownCard(claim, isPending),

            // FRS Score + Fraud Shield Card (APPROVED only)
            if (isApproved && claim.frsScore != null) ...[
              const SizedBox(height: 16),
              _buildFraudShieldCard(claim.frsScore!),
            ],

            const SizedBox(height: 32),
            if (isApproved)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: app_colors.primaryGreen),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Download receipt', style: TextStyle(color: app_colors.primaryGreen, fontWeight: FontWeight.bold)),
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(List<TimelineStep> timeline, Color activeColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TIMELINE', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: app_colors.textPrimary, letterSpacing: 1.0)),
          const SizedBox(height: 16),
          ...timeline.asMap().entries.map((entry) {
            int idx = entry.key;
            var step = entry.value;
            bool isLast = idx == timeline.length - 1;
            
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Icon(
                      step.isDone ? Icons.check_circle_rounded : (step.isPending ? Icons.hourglass_top_rounded : Icons.radio_button_unchecked),
                      color: step.isDone ? activeColor : (step.isPending ? app_colors.amber : app_colors.textSecondary),
                      size: 20,
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 30,
                        color: step.isDone ? activeColor : app_colors.textSecondary.withOpacity(0.3),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(step.title, style: TextStyle(fontSize: 14, fontWeight: step.isDone || step.isPending ? FontWeight.bold : FontWeight.normal, color: app_colors.textPrimary)),
                        const SizedBox(height: 2),
                        Text(step.date, style: const TextStyle(fontSize: 12, color: app_colors.textSecondary)),
                        if (!isLast) const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPayoutBreakdownCard(ClaimModel claim, bool isPending) {
    final int duration = claim.durationHours ?? 3;
    final int rate = claim.ratePerHour ?? 50;
    final int gross = claim.grossAmount ?? (duration * rate);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PAYOUT BREAKDOWN', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: app_colors.textPrimary, letterSpacing: 1.0)),
          const SizedBox(height: 16),
          _buildBreakdownRow('Trigger', claim.type),
          _buildBreakdownRow('Duration', '$duration hours above 64.5mm threshold'),
          _buildBreakdownRow('Rate', '₹$rate/hr (Standard Shield)'),
          _buildBreakdownRow('Zone depth multiplier', '0.84 × 1.00 = full payout'),
          const Divider(height: 24),
          _buildBreakdownRow('Gross payout', '₹$gross', isBold: true),
          const Divider(height: 24),
          if (isPending) ...[
            _buildBreakdownRow('Estimated payout', '₹$gross', isBold: true, valueColor: app_colors.amber),
            const SizedBox(height: 8),
            const Text('Settlement: Sunday 11 PM', style: TextStyle(fontSize: 12, color: app_colors.textSecondary, fontStyle: FontStyle.italic)),
          ] else ...[
            _buildBreakdownRow('Provisional (70%)', '₹${claim.immediateAmount ?? 105}', suffixText: '[Releasing Sunday 11 PM]'),
            _buildBreakdownRow('Settlement (30%)', '₹${claim.heldAmount ?? 45}', suffixText: '[Releasing Tuesday after 48hr review]'),
          ],
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, String value, {bool isBold = false, Color valueColor = app_colors.textPrimary, IconData? icon, Color? iconColor, String? suffixText}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: app_colors.textSecondary, fontSize: 14)),
          const Spacer(),
          if (icon != null) ...[
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 4),
          ],
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.w500, color: valueColor, fontSize: 14)),
          if (suffixText != null) ...[
            const SizedBox(width: 4),
            Text(suffixText, style: const TextStyle(color: app_colors.textSecondary, fontSize: 12, fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }

  Widget _buildFraudShieldCard(int score) {
    const layers = [
      ('Layer 0', 'Play Integrity API', 'Device not rooted'),
      ('Layer 1', 'GPS zone match', 'Adyar zone confirmed'),
      ('Layer 1', 'Wi-Fi fingerprint', 'No home SSID detected'),
      ('Layer 1', 'IP geolocation', 'Outdoor IP confirmed'),
      ('Layer 1', 'Accelerometer', 'Outdoor motion pattern'),
      ('Layer 2', 'Behavioral baseline', 'Normal work pattern'),
      ('Layer 3', 'News corroboration', 'IMD rain alert confirmed'),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: app_colors.primaryGreen.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hustlr Fraud Shield ✅', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: app_colors.textPrimary)),
          const SizedBox(height: 4),
          const Text('Your claim passed all 7 verification layers', style: TextStyle(fontSize: 13, color: app_colors.textSecondary)),
          const SizedBox(height: 16),
          ...layers.map((l) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 55,
                  child: Text(l.$1 + ':', style: const TextStyle(fontSize: 12, color: app_colors.textSecondary)),
                ),
                Expanded(
                  child: Text(l.$2, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: app_colors.textPrimary)),
                ),
                Row(
                  children: [
                    const Text('✅ ', style: TextStyle(fontSize: 10)),
                    Text(l.$3, style: const TextStyle(fontSize: 12, color: app_colors.textSecondary)),
                  ],
                ),
              ],
            ),
          )),
          const SizedBox(height: 16),
          Text('FPS Score: $score / 100 — GREEN', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: app_colors.textPrimary)),
          const SizedBox(height: 4),
          const Text('Score below 30 = auto-approved', style: TextStyle(fontSize: 12, color: app_colors.textSecondary)),
        ],
      ),
    );
  }
}

