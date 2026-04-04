import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/mock_data_service.dart';

class ClaimDetailScreen extends StatelessWidget {
  final String claimId;

  const ClaimDetailScreen({super.key, required this.claimId});

  @override
  Widget build(BuildContext context) {
    final mockData = Provider.of<MockDataService>(context);

    // Safeguard against missing data / early hydration
    if (mockData.claims.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).canvasColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: Theme.of(context).colorScheme.onSurface),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final claim = mockData.claims.firstWhere(
      (c) => c.id == claimId,
      orElse: () => mockData.claims.first,
    );

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bool isApproved = claim.status == 'APPROVED';
    final bool isPending = claim.status == 'PENDING';
    final bool isDeclined = claim.status == 'DECLINED';

    Color statusColor = Colors.orange;
    if (isApproved) statusColor = theme.colorScheme.primary;
    if (isDeclined) statusColor = Colors.redAccent;

    IconData triggerIcon = Icons.cloud_rounded;
    if (claim.icon == "downtime") triggerIcon = Icons.cloud_off_rounded;
    if (claim.icon == "heat") triggerIcon = Icons.thermostat_rounded;

    return Scaffold(
      backgroundColor: theme.canvasColor,
      appBar: AppBar(
        title: Text('Claim Details', style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: theme.colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Header
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(24)),
              child: Icon(triggerIcon, size: 36, color: statusColor),
            ),
            const SizedBox(height: 20),
            Text(claim.type, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface, letterSpacing: -0.5)),
            const SizedBox(height: 6),
            Text(claim.date, style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withOpacity(0.5), fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: statusColor.withOpacity(0.2), width: 1.5),
              ),
              child: Text(
                claim.status,
                style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5),
              ),
            ),
            if (isDeclined) ...[
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => context.push('/claims/explanation'),
                style: TextButton.styleFrom(
                  backgroundColor: statusColor.withOpacity(0.08),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('See why flagged', style: TextStyle(color: statusColor, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5)),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, color: statusColor, size: 16),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 40),

            // Timeline Stepper
            _buildTimeline(claim.timeline, statusColor, theme, isDark),
            const SizedBox(height: 32),

            // Payout Breakdown Card
            if (!isDeclined) _buildPayoutBreakdownCard(claim, isPending, theme, isDark),

            // FRS Score + Fraud Shield Card (APPROVED only)
            if (isApproved && claim.frsScore != null) ...[
              const SizedBox(height: 32),
              _buildFraudShieldCard(claim.frsScore!, theme, isDark),
            ],

            const SizedBox(height: 48),
            if (isApproved)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.colorScheme.primary, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.download_rounded, color: theme.colorScheme.primary, size: 20),
                      const SizedBox(width: 10),
                      Text('Download Receipt', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(List<TimelineStep> timeline, Color activeColor, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04), width: 1.5),
        boxShadow: isDark ? [] : [const BoxShadow(color: Color(0x05000000), blurRadius: 16, offset: Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 4, height: 16, color: theme.colorScheme.primary, margin: const EdgeInsets.only(right: 12)),
              Text('TIMELINE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface.withOpacity(0.5), letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 24),
          ...timeline.asMap().entries.map((entry) {
            int idx = entry.key;
            var step = entry.value;
            bool isLast = idx == timeline.length - 1;
            
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: step.isDone ? activeColor.withOpacity(0.15) : (step.isPending ? Colors.orange.withOpacity(0.15) : theme.colorScheme.onSurface.withOpacity(0.05)),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: step.isDone ? activeColor.withOpacity(0.5) : (step.isPending ? Colors.orange.withOpacity(0.5) : theme.colorScheme.onSurface.withOpacity(0.1)),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        step.isDone ? Icons.check_rounded : (step.isPending ? Icons.more_horiz_rounded : Icons.radio_button_unchecked_rounded),
                        color: step.isDone ? activeColor : (step.isPending ? Colors.orange : theme.colorScheme.onSurface.withOpacity(0.3)),
                        size: 16,
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 40,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: step.isDone ? activeColor.withOpacity(0.3) : theme.colorScheme.onSurface.withOpacity(0.08),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(step.title, style: TextStyle(fontSize: 15, fontWeight: step.isDone || step.isPending ? FontWeight.w800 : FontWeight.w600, color: step.isDone || step.isPending ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withOpacity(0.4))),
                        const SizedBox(height: 4),
                        Text(step.date, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: step.isDone || step.isPending ? theme.colorScheme.onSurface.withOpacity(0.6) : theme.colorScheme.onSurface.withOpacity(0.3))),
                        if (!isLast) const SizedBox(height: 24),
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

  Widget _buildPayoutBreakdownCard(ClaimModel claim, bool isPending, ThemeData theme, bool isDark) {
    final int duration = claim.durationHours ?? 3;
    final int rate = claim.ratePerHour ?? 50;
    final int gross = claim.grossAmount ?? (duration * rate);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04), width: 1.5),
        boxShadow: isDark ? [] : [const BoxShadow(color: Color(0x05000000), blurRadius: 16, offset: Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 4, height: 16, color: theme.colorScheme.primary, margin: const EdgeInsets.only(right: 12)),
              Text('PAYOUT BREAKDOWN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface.withOpacity(0.5), letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 24),
          _buildBreakdownRow('Trigger', claim.type, theme),
          _buildBreakdownRow('Duration', '$duration hours above 64.5mm threshold', theme),
          _buildBreakdownRow('Rate', '₹$rate/hr (Standard Shield)', theme),
          _buildBreakdownRow('Zone depth multiplier', '0.84 × 1.00 = full payout', theme),
          Divider(height: 32, color: theme.colorScheme.onSurface.withOpacity(0.1)),
          _buildBreakdownRow('Gross payout', '₹$gross', theme, isBold: true),
          Divider(height: 32, color: theme.colorScheme.onSurface.withOpacity(0.1)),
          if (isPending) ...[
            _buildBreakdownRow('Estimated payout', '₹$gross', theme, isBold: true, valueColor: Colors.orange),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: theme.colorScheme.onSurface.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 14, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  const SizedBox(width: 8),
                  Text('Settlement: Sunday 11 PM', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.8), fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ] else ...[
            _buildBreakdownRow('Provisional (70%)', '₹${claim.immediateAmount ?? 105}', theme, suffixText: '[Releasing Sunday 11 PM]'),
            _buildBreakdownRow('Settlement (30%)', '₹${claim.heldAmount ?? 45}', theme, suffixText: '[Releasing Tuesday after 48hr review]'),
          ],
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, String value, ThemeData theme, {bool isBold = false, Color? valueColor, IconData? icon, Color? iconColor, String? suffixText}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: Text(label, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w700))),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 14, color: iconColor),
                      const SizedBox(width: 4),
                    ],
                    Flexible(child: Text(value, textAlign: TextAlign.right, style: TextStyle(fontWeight: isBold ? FontWeight.w900 : FontWeight.w700, color: valueColor ?? theme.colorScheme.onSurface, fontSize: 14))),
                  ],
                ),
                if (suffixText != null) ...[
                  const SizedBox(height: 4),
                  Text(suffixText, textAlign: TextAlign.right, style: TextStyle(color: theme.colorScheme.primary, fontSize: 11, fontWeight: FontWeight.w700)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFraudShieldCard(int score, ThemeData theme, bool isDark) {
    const layers = [
      ('Layer 0', 'Play Integrity + device signals', 'Token verified on server when configured; ML + heuristics always'),
      ('Layer 1', 'GPS zone match', 'Adyar zone confirmed'),
      ('Layer 1', 'Wi-Fi fingerprint', 'No home SSID detected'),
      ('Layer 1', 'IP geolocation', 'Outdoor IP confirmed'),
      ('Layer 1', 'Accelerometer', 'Outdoor motion pattern'),
      ('Layer 2', 'Behavioral baseline', 'Normal work pattern'),
      ('Layer 3', 'News corroboration', 'IMD rain alert confirmed'),
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user_rounded, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 10),
              Text('Hustlr Fraud Shield', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: theme.colorScheme.primary, letterSpacing: -0.3)),
            ],
          ),
          const SizedBox(height: 6),
          Text('Your claim passed all 7 verification layers', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.6), fontWeight: FontWeight.w600)),
          const SizedBox(height: 24),
          ...layers.map((l) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 55,
                  child: Text(l.$1, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.4), fontWeight: FontWeight.w900)),
                ),
                Expanded(
                  child: Text(l.$2, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
                ),
                Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary, size: 14),
                    const SizedBox(width: 6),
                    Text(l.$3, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6), fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          )),
          Divider(height: 32, color: theme.colorScheme.primary.withOpacity(0.1)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('FPS Score', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: theme.colorScheme.primary.withOpacity(0.8), letterSpacing: 1.5)),
                    const SizedBox(height: 6),
                    Text('Normal Profile', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.6), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$score', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: theme.colorScheme.primary, height: 1.0)),
                  const SizedBox(width: 4),
                  Text('/ 100', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: theme.colorScheme.primary.withOpacity(0.5))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
