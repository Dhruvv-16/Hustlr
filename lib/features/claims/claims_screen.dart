import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/mock_data_service.dart';
import '../../widgets/hustlr_bottom_nav.dart';

import '../../core/constants/colors.dart' as app_colors;
import '../../core/constants/text_styles.dart';
import '../../shared/widgets/mobile_container.dart';
import 'package:go_router/go_router.dart';

// ─── Color constants local to this screen (dark theme matching dashboard) ─────────
const Color _bgScreen   = Color(0xFF0a0b0a);
const Color _cardBg     = Color(0xFF1c1f1c);
const Color _blueLight  = Color(0xFF003D2A);
const Color _blueDark   = Color(0xFF3fff8b);
const Color _blue       = Color(0xFF3fff8b);
const Color _tealLight  = Color(0xFF1c1f1c);
const Color _teal       = Color(0xFF3fff8b);
const Color _amberLight = Color(0xFF1c1f1c);
const Color _amber      = Color(0xFFFFA726);
const Color _greenText  = Color(0xFF3fff8b);
const Color _greenBg    = Color(0xFF003D2A);
const Color _divider    = Color(0xFF2a2d2a);
const Color _primary    = Colors.white;
const Color _grey       = Color(0xFF91938d);
const Color _errorRed   = Color(0xFFFF5252);

class ClaimsScreen extends StatelessWidget {
  const ClaimsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mockData = Provider.of<MockDataService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    int totalClaimed = mockData.claims.fold(0, (sum, c) => sum + c.amount);
    int totalReceived = mockData.claims
        .where((c) => c.status == "APPROVED")
        .fold(0, (sum, c) => sum + c.amount);
    int pendingCount = mockData.claims
        .where((c) => c.status == "PENDING")
        .length;

    final bgScreen = isDark ? const Color(0xFF0a0b0a) : const Color(0xFFF4F6F4);
    final cardBg = isDark ? const Color(0xFF1c1f1c) : Colors.white;
    final blueLight = isDark ? const Color(0xFF003D2A) : const Color(0xFFE3F2FD);
    final blueDark = isDark ? const Color(0xFF3fff8b) : const Color(0xFF1976D2);
    final blue = isDark ? const Color(0xFF3fff8b) : const Color(0xFF1976D2);
    final tealLight = isDark ? const Color(0xFF1c1f1c) : const Color(0xFFE8F5E9);
    final teal = isDark ? const Color(0xFF3fff8b) : const Color(0xFF1B5E20);
    final amberLight = isDark ? const Color(0xFF1c1f1c) : const Color(0xFFFFF3E0);
    final amber = isDark ? const Color(0xFFFFA726) : const Color(0xFFE65100);
    final greenText = isDark ? const Color(0xFF3fff8b) : const Color(0xFF1B5E20);
    final greenBg = isDark ? const Color(0xFF003D2A) : const Color(0xFFE8F5E9);
    final divider = isDark ? const Color(0xFF2a2d2a) : const Color(0xFFE0E0E0);
    final primary = isDark ? Colors.white : const Color(0xFF0D1B0F);
    final grey = isDark ? const Color(0xFF91938d) : const Color(0xFF8FAE8B);
    final errorRed = isDark ? const Color(0xFFFF5252) : const Color(0xFFB71C1C);
    final mintColor = isDark ? const Color(0xFF3fff8b) : const Color(0xFF1B5E20);

    return Scaffold(
      backgroundColor: bgScreen,
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: mintColor,
        icon: Icon(Icons.add, color: isDark ? const Color(0xFF0a0b0a) : Colors.white),
        label: Text('Report a Disruption', 
          style: TextStyle(color: isDark ? const Color(0xFF0a0b0a) : Colors.white, 
          fontWeight: FontWeight.bold)),
        onPressed: () => _showDisruptionSheet(context),
      ),
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
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: primary,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: mockData.claims.length,
                              itemBuilder: (context, index) {
                                final claim = mockData.claims[index];
                                
                                Color iconBg = blueLight;
                                IconData iconData = Icons.cloud_rounded;
                                Color iconColor = blue;
                                
                                if (claim.icon == "downtime") {
                                  iconBg = tealLight;
                                  iconData = Icons.cloud_off_rounded;
                                  iconColor = teal;
                                } else if (claim.icon == "heat") {
                                  iconBg = amberLight;
                                  iconData = Icons.thermostat_rounded;
                                  iconColor = amber;
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
                                      statusBg: claim.status == 'APPROVED' ? greenBg : const Color(0xFFFFF3E0),
                                      statusColor: claim.status == 'APPROVED' ? greenText : amber,
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

  void _showDisruptionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('What happened?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primary)),
              ),
              const Divider(height: 1),
              _buildSheetItem(context, 'Road Blocked / Accident', '🚧', 'Manual claim · 4hr SLA · Photo required'),
              _buildSheetItem(context, 'Dark Store / Hub Closed', '🏪', 'Manual claim · 4hr SLA · Photo + screenshot'),
              _buildSheetItem(context, 'Internet Outage', '🌐', 'Auto-verified · No photo needed'),
              _buildSheetItem(context, 'Heavy Traffic Congestion', '🚦', 'Manual claim · 4hr SLA · Photo + GPS'),
              _buildSheetItem(context, 'Other Disruption', '📦', 'Manual claim · 4hr SLA · Photo + description'),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSheetItem(BuildContext context, String title, String emoji, String subtitle) {
    return InkWell(
      onTap: () {
        context.pop(); // close sheet
        context.push('/claims/evidence?type=$title');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: _primary, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: _grey, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _grey),
          ],
        ),
      ),
    );
  }
}

// ─── Top Bar ─────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgScreen = isDark ? const Color(0xFF0a0b0a) : const Color(0xFFF4F6F4);
    final primary = isDark ? Colors.white : const Color(0xFF0D1B0F);

    return Container(
      color: bgScreen,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const Expanded(child: SizedBox()),
          Text(
            'Claims',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: primary,
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Icon(Icons.notifications_outlined, color: primary, size: 24),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1c1f1c) : Colors.white;
    final primary = isDark ? Colors.white : const Color(0xFF0D1B0F);
    final greenText = isDark ? const Color(0xFF3fff8b) : const Color(0xFF1B5E20);
    final amber = isDark ? const Color(0xFFFFA726) : const Color(0xFFE65100);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _SummarySection(
                label: 'CLAIMED',
                value: '₹$totalClaimed',
                valueColor: primary,
              ),
            ),
            const _VerticalDivider(),
            Expanded(
              child: _SummarySection(
                label: 'RECEIVED',
                value: '₹$totalReceived',
                valueColor: greenText,
                trailing: Icon(Icons.check_circle, color: greenText, size: 16),
              ),
            ),
            const _VerticalDivider(),
            Expanded(
              child: _SummarySection(
                label: 'PENDING',
                value: '$pendingCount',
                valueColor: amber,
              ),
            ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final grey = isDark ? const Color(0xFF91938d) : const Color(0xFF8FAE8B);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: grey,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 4),
              trailing!,
            ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final divider = isDark ? const Color(0xFF2a2d2a) : const Color(0xFFE0E0E0);

    return Container(
      width: 1,
      height: 40,
      color: divider,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

// ─── Education Banner ─────────────────────────────────────────────────────────
class _EducationBanner extends StatelessWidget {
  const _EducationBanner();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final blueLight = isDark ? const Color(0xFF003D2A) : const Color(0xFFE3F2FD);
    final blueDark = isDark ? const Color(0xFF3fff8b) : const Color(0xFF1976D2);
    final blue = isDark ? const Color(0xFF3fff8b) : const Color(0xFF1976D2);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: blueLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoCircle(color: blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Hustlr auto-detects disruptions and processes claims by Sunday 11 PM for you.',
              style: TextStyle(
                fontSize: 13,
                color: blueDark,
                height: 1.5,
              ),
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
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text(
          'i',
          style: TextStyle(
            color: Colors.white,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1c1f1c) : Colors.white;
    final primary = isDark ? Colors.white : const Color(0xFF0D1B0F);
    final grey = isDark ? const Color(0xFF91938d) : const Color(0xFF8FAE8B);
    final errorRed = isDark ? const Color(0xFFFF5252) : const Color(0xFFB71C1C);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon circle
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          // Center content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 13,
                    color: grey,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    if (status == 'DECLINED') ...[
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => context.push('/claims/explanation'),
                        child: Text(
                          'See why →',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: errorRed,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Amount — top aligned
          Text(
            amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: primary,
            ),
          ),
        ],
      ),
    );
  }
}
