import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/mock_data_service.dart';

import '../../core/constants/colors.dart' as app_colors;
import '../../core/constants/text_styles.dart';
import '../../shared/widgets/mobile_container.dart';

// ─── Color constants local to this screen (mapping to global tokens) ─────────
const Color _bgScreen   = app_colors.background;
const Color _blueLight  = Color(0xFFE3F2FD);
const Color _blueDark   = Color(0xFF1565C0);
const Color _blue       = Color(0xFF1976D2);
const Color _tealLight  = Color(0xFFE0F2F1);
const Color _teal       = Color(0xFF00897B);
const Color _amberLight = app_colors.lightAmber;
const Color _amber      = app_colors.amber;
const Color _greenText  = app_colors.primaryGreen;
const Color _greenBg    = app_colors.lightGreen;
const Color _divider    = Color(0xFFE5E7EB);
const Color _primary    = app_colors.textPrimary;
const Color _grey       = app_colors.textSecondary;

class ClaimsScreen extends StatelessWidget {
  const ClaimsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mockData = Provider.of<MockDataService>(context);

    int totalClaimed = mockData.claims.fold(0, (sum, c) => sum + c.amount);
    int totalReceived = mockData.claims
        .where((c) => c.status == "APPROVED")
        .fold(0, (sum, c) => sum + c.amount);
    int pendingCount = mockData.claims
        .where((c) => c.status == "PENDING")
        .length;

    return Scaffold(
      backgroundColor: _bgScreen,
      body: MobileContainer(
        child: SafeArea(
          child: Column(
            children: [
            _TopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
                    const Text(
                      'RECENT HISTORY',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _primary,
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
                        
                        Color iconBg = _blueLight;
                        IconData iconData = Icons.cloud_rounded;
                        Color iconColor = _blue;
                        
                        if (claim.icon == "downtime") {
                          iconBg = _tealLight;
                          iconData = Icons.cloud_off_rounded;
                          iconColor = _teal;
                        } else if (claim.icon == "heat") {
                          iconBg = _amberLight;
                          iconData = Icons.thermostat_rounded;
                          iconColor = _amber;
                        }
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ClaimCard(
                            iconBg: iconBg,
                            icon: iconData,
                            iconColor: iconColor,
                            title: claim.type,
                            date: claim.date,
                            status: claim.status,
                            statusBg: claim.status == 'APPROVED' ? _greenBg : const Color(0xFFFFF3E0),
                            statusColor: claim.status == 'APPROVED' ? _greenText : _amber,
                            amount: '₹${claim.amount}',
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
    );
  }
}

// ─── Top Bar ─────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bgScreen,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: const Row(
        children: [
          Expanded(child: SizedBox()),
          Text(
            'Claims',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _primary,
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Icon(Icons.notifications_outlined, color: _primary, size: 24),
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
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
                valueColor: _primary,
              ),
            ),
            const _VerticalDivider(),
            Expanded(
              child: _SummarySection(
                label: 'RECEIVED',
                value: '₹$totalReceived',
                valueColor: _greenText,
                trailing: const Icon(Icons.check_circle, color: _greenText, size: 16),
              ),
            ),
            const _VerticalDivider(),
            Expanded(
              child: _SummarySection(
                label: 'PENDING',
                value: '$pendingCount',
                valueColor: _amber,
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _grey,
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
    return Container(
      width: 1,
      height: 40,
      color: _divider,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

// ─── Education Banner ─────────────────────────────────────────────────────────
class _EducationBanner extends StatelessWidget {
  const _EducationBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _blueLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoCircle(),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Hustlr auto-detects disruptions and processes claims instantly for you.',
              style: TextStyle(
                fontSize: 13,
                color: _blueDark,
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
  const _InfoCircle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        color: _blue,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _grey,
                  ),
                ),
                const SizedBox(height: 8),
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
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Amount — top aligned
          Text(
            amount,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _primary,
            ),
          ),
        ],
      ),
    );
  }
}
