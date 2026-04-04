import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/mock_data_service.dart';
import '../../widgets/hustlr_bottom_nav.dart';
import '../../shared/widgets/mobile_container.dart';
import 'package:go_router/go_router.dart';

class ClaimsScreen extends StatelessWidget {
  const ClaimsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mockData = Provider.of<MockDataService>(context);
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    int totalClaimed = mockData.claims.fold(0, (sum, c) => sum + c.amount);
    int totalReceived = mockData.claims
        .where((c) => c.status == "APPROVED")
        .fold(0, (sum, c) => sum + c.amount);
    int pendingCount = mockData.claims
        .where((c) => c.status == "PENDING")
        .length;

    // ── Theme-aware palette ──────────────────────────────────────────────────
    final bgScreen   = theme.scaffoldBackgroundColor;
    final mintColor  = isDark ? const Color(0xFF3FFF8B) : const Color(0xFF1B5E20);
    // Rain icon colors
    final blueLight  = isDark ? const Color(0xFF003D2A) : const Color(0xFFE3F2FD);
    final blue       = isDark ? const Color(0xFF3FFF8B) : const Color(0xFF1976D2);
    // Downtime icon colors
    final tealLight  = isDark ? const Color(0xFF1C1F1C) : const Color(0xFFE8F5E9);
    final teal       = isDark ? const Color(0xFF3FFF8B) : const Color(0xFF1B5E20);
    // Heat icon colors
    final amberLight = isDark ? const Color(0xFF2D1B00) : const Color(0xFFFFF3E0);
    final amber      = isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100);
    // Badge colors
    final greenText  = isDark ? const Color(0xFF3FFF8B) : const Color(0xFF1B5E20);
    final greenBg    = isDark ? const Color(0xFF004734) : const Color(0xFFE8F5E9);

    return Scaffold(
      backgroundColor: bgScreen,
      body: Stack(
        children: [
          Positioned.fill(
            child: MobileContainer(
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    _TopBar(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SummaryRow(
                              totalClaimed: totalClaimed,
                              totalReceived: totalReceived,
                              pendingCount: pendingCount,
                            ),
                            const SizedBox(height: 16),
                            const _EducationBanner(),
                            const SizedBox(height: 20),
                            Text(
                              'RECENT HISTORY',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurface,
                                letterSpacing: 0.3,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: mockData.claims.length,
                              itemBuilder: (context, index) {
                                final claim = mockData.claims[index];

                                Color iconBg    = blueLight;
                                IconData iconData = Icons.cloud_rounded;
                                Color iconColor = blue;

                                if (claim.icon == "downtime") {
                                  iconBg    = tealLight;
                                  iconData  = Icons.cloud_off_rounded;
                                  iconColor = teal;
                                } else if (claim.icon == "heat") {
                                  iconBg    = amberLight;
                                  iconData  = Icons.thermostat_rounded;
                                  iconColor = amber;
                                }

                                // Badge colors by status
                                Color statusBg, statusColor;
                                if (claim.status == 'APPROVED') {
                                  statusBg    = greenBg;
                                  statusColor = greenText;
                                } else if (claim.status == 'PENDING') {
                                  statusBg    = amberLight;
                                  statusColor = amber;
                                } else {
                                  // DECLINED
                                  statusBg    = isDark ? const Color(0xFF4A0000) : const Color(0xFFFFEBEE);
                                  statusColor = isDark ? const Color(0xFFFF6B6B) : const Color(0xFFB71C1C);
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: InkWell(
                                    onTap: () => context.push('/claims/${claim.id}'),
                                    borderRadius: BorderRadius.circular(16),
                                    child: _ClaimCard(
                                      iconBg: iconBg,
                                      icon: iconData,
                                      iconColor: iconColor,
                                      title: claim.type,
                                      date: claim.date,
                                      status: claim.status,
                                      statusBg: statusBg,
                                      statusColor: statusColor,
                                      amount: '₹${claim.amount}',
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 100, // Safe distance above the navigation bar
            child: FloatingActionButton.extended(
              backgroundColor: isDark ? const Color(0xFF3FFF8B) : const Color(0xFF1B5E20),
              elevation: 4,
              icon: Icon(Icons.add, color: isDark ? const Color(0xFF0A0B0A) : Colors.white),
              label: Text(
                'Report a Disruption',
                style: TextStyle(
                  color: isDark ? const Color(0xFF0A0B0A) : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () => context.push('/claims/evidence'),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/policy');
        break;
      case 2:
        break;
      case 3:
        context.go('/wallet');
        break;
    }
  }
}

// ─── Top Bar ─────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final bgColor = theme.scaffoldBackgroundColor;

    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const Expanded(child: SizedBox()),
          Text(
            'Claims',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Icon(Icons.notifications_outlined,
                  color: theme.colorScheme.onSurface, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Summary Row Card ─────────────────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final int totalClaimed;
  final int totalReceived;
  final int pendingCount;

  const _SummaryRow({
    required this.totalClaimed,
    required this.totalReceived,
    required this.pendingCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final isDark   = theme.brightness == Brightness.dark;
    final cardBg   = theme.cardColor;
    final greenText = isDark ? const Color(0xFF3FFF8B) : const Color(0xFF1B5E20);
    final amber     = isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.20 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(child: _SummarySection(label: 'CLAIMED',  value: '₹$totalClaimed',  valueColor: theme.colorScheme.onSurface)),
            const _VerticalDivider(),
            Expanded(child: _SummarySection(
              label: 'RECEIVED', value: '₹$totalReceived', valueColor: greenText,
              trailing: Icon(Icons.check_circle, color: greenText, size: 16),
            )),
            const _VerticalDivider(),
            Expanded(child: _SummarySection(label: 'PENDING',  value: '$pendingCount',   valueColor: amber)),
          ],
        ),
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final Widget? trailing;

  const _SummarySection({
    required this.label,
    required this.value,
    required this.valueColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final grey   = isDark ? const Color(0xFF91938D) : const Color(0xFF8FAE8B);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w600,
          color: grey, letterSpacing: 1.0,
        )),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(value, style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w700, color: valueColor)),
            if (trailing != null) ...[const SizedBox(width: 4), trailing!],
          ],
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final divColor = isDark ? const Color(0xFF2A2D2A) : const Color(0xFFE0E0E0);

    return Container(
      width: 1, height: 40,
      color: divColor,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

// ─── Education Banner ─────────────────────────────────────────────────────────
class _EducationBanner extends StatelessWidget {
  const _EducationBanner();

  @override
  Widget build(BuildContext context) {
    final isDark     = Theme.of(context).brightness == Brightness.dark;
    final bannerBg   = isDark ? const Color(0xFF003D2A) : const Color(0xFFE3F2FD);
    final accentColor = isDark ? const Color(0xFF3FFF8B) : const Color(0xFF1976D2);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoCircle(color: accentColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Hustlr auto-detects disruptions and processes claims by Sunday 11 PM for you.',
              style: TextStyle(
                fontSize: 13, color: accentColor, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCircle extends StatelessWidget {
  final Color color;
  const _InfoCircle({required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 32, height: 32,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(
        child: Text(
          'i',
          style: TextStyle(
            color: isDark ? const Color(0xFF0A0B0A) : Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}

// ─── Claim Card ───────────────────────────────────────────────────────────────
class _ClaimCard extends StatelessWidget {
  final Color iconBg;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String date;
  final String status;
  final Color statusBg;
  final Color statusColor;
  final String amount;

  const _ClaimCard({
    required this.iconBg,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.date,
    required this.status,
    required this.statusBg,
    required this.statusColor,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final isDark   = theme.brightness == Brightness.dark;
    final cardBg   = theme.cardColor;
    final errorRed = isDark ? const Color(0xFFFF6B6B) : const Color(0xFFB71C1C);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.20 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface)),
                const SizedBox(height: 4),
                Text(date, style: TextStyle(
                  fontSize: 13,
                  color: isDark ? const Color(0xFF91938D) : const Color(0xFF8FAE8B))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(status, style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: statusColor, letterSpacing: 0.8)),
                    ),
                    if (status == 'DECLINED') ...[
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => context.push('/claims/explanation'),
                        child: Text('See why →', style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold,
                          color: errorRed)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(amount, style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface)),
        ],
      ),
    );
  }
}
