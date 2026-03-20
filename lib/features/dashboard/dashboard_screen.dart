import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/mock_data_service.dart';
import '../shared/widgets/demo_control_panel.dart';
import '../../shared/widgets/mobile_container.dart';

// ─── Local palette (avoids cross-file import churn) ──────────────────────────
const _bg          = Color(0xFFF8F9FA);
const _green       = Color(0xFF2E7D32);
const _lightGreen  = Color(0xFFE8F5E9);
const _amber       = Color(0xFFFFA726);
const _lightAmber  = Color(0xFFFFF8E1);
const _errorRed    = Color(0xFFD32F2F);
const _lightRed    = Color(0xFFFFEBEE);
const _cardWhite   = Color(0xFFFFFFFF);
const _textPrimary = Color(0xFF1A1A2E);
const _textSub     = Color(0xFF6B7280);
const _textHint    = Color(0xFF9CA3AF);

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final mockData = Provider.of<MockDataService>(context);

    return MobileContainer(
      child: Container(
        color: _bg,
        child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Top bar ──────────────────────────────────────────────
                    _TopBar(),
                    const SizedBox(height: 20),

                    // ── Greeting ─────────────────────────────────────────────
                    Row(children: [
                      Text(
                        '${_greeting()}, ${mockData.worker.name} ',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _textPrimary,
                        ),
                      ),
                      const Text('👋', style: TextStyle(fontSize: 20)),
                    ]),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.location_pin, size: 14, color: _green),
                      const SizedBox(width: 2),
                      Text(
                        '${mockData.worker.city} • ${mockData.worker.zone}',
                        style: const TextStyle(
                            fontSize: 13,
                            color: _green,
                            fontWeight: FontWeight.w600),
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // ── Predictive nudge card ─────────────────────────────────
                    if (mockData.showPredictiveNudge) ...[
                      _NudgeCard(message: mockData.predictiveMessage, amount: mockData.protectAmount),
                      const SizedBox(height: 16),
                    ],

                    // ── ISS score card ────────────────────────────────────────
                    _ISSCard(score: mockData.worker.issScore),
                    const SizedBox(height: 16),

                    // ── Alert card ────────────────────────────────────────────
                    if (mockData.activeDisruption != null) ...[
                      _AlertCard(disruption: mockData.activeDisruption!),
                      const SizedBox(height: 16),
                    ],

                    // ── Active Policy card ────────────────────────────────────
                    _PolicyCard(),
                    const SizedBox(height: 16),

                    // ── Quick Actions ─────────────────────────────────────────
                    _QuickActions(),
                    const SizedBox(height: 16),

                    // ── Missed payouts card ───────────────────────────────────
                    _MissedPayoutsCard(),
                    const SizedBox(height: 100), // space above nav
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
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Shield wordmark
        GestureDetector(
          onLongPress: () => showDemoPanel(context),
          child: Row(
            children: const [
              Icon(Icons.shield_rounded, color: _green, size: 28),
              SizedBox(width: 6),
              Text(
                'Hustlr',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        // Bell
        Stack(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                  color: _lightGreen, shape: BoxShape.circle),
              child:
                  const Icon(Icons.notifications_rounded, color: _green, size: 22),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: _errorRed, shape: BoxShape.circle),
              ),
            ),
          ],
        ),
        const SizedBox(width: 10),
        // Avatar
        Container(
          width: 40,
          height: 40,
          decoration:
              const BoxDecoration(color: Color(0xFFE0C8B0), shape: BoxShape.circle),
          child: const Icon(Icons.person_rounded, color: _textSub, size: 24),
        ),
      ],
    );
  }
}

// ─── Nudge Card ───────────────────────────────────────────────────────────────
class _NudgeCard extends StatelessWidget {
  final String message;
  final int amount;

  const _NudgeCard({required this.message, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _lightAmber,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Activate coverage to protect ₹$amount+ earnings',
                  style: const TextStyle(fontSize: 13, color: _textSub, height: 1.4),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => context.push('/policy/plans'),
                  child: Row(
                    children: const [
                      Text(
                        'ACTIVATE NOW',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _amber,
                          letterSpacing: 0.4,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward, size: 14, color: _amber),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Storm cloud icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _amber.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.thunderstorm_rounded,
                color: _amber, size: 28),
          ),
        ],
      ),
    );
  }
}

// ─── ISS Score Card ───────────────────────────────────────────────────────────
class _ISSCard extends StatelessWidget {
  final int score;

  const _ISSCard({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Circular ring
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(100, 100),
                  painter: _RingPainter(progress: 0.62, color: _amber),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary,
                      ),
                    ),
                    Text(
                      'AMBER',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _amber,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Right text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Income Stability\nScore',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Moderate risk this week',
                  style: TextStyle(fontSize: 13, color: _textSub),
                ),
                const SizedBox(height: 8),
                Row(children: const [
                  Icon(Icons.trending_up_rounded, size: 16, color: _green),
                  SizedBox(width: 4),
                  Text(
                    'Trending up +5',
                    style: TextStyle(
                        fontSize: 13,
                        color: _green,
                        fontWeight: FontWeight.w600),
                  ),
                  SizedBox(width: 6),
                  // Bar chart mini
                  _MiniBarChart(),
                ]),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: _textHint, size: 22),
        ],
      ),
    );
  }
}

class _MiniBarChart extends StatelessWidget {
  const _MiniBarChart();

  @override
  Widget build(BuildContext context) {
    final heights = [8.0, 10.0, 12.0, 16.0];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: heights
          .map((h) => Container(
                width: 4,
                height: h,
                margin: const EdgeInsets.only(left: 2),
                decoration: BoxDecoration(
                  color: _green,
                  borderRadius: BorderRadius.circular(2),
                ),
              ))
          .toList(),
    );
  }
}

// Draws the amber arc ring
class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = (math.min(cx, cy)) - 8;
    final strokeWidth = 9.0;

    // Background track
    final trackPaint = Paint()
      ..color = const Color(0xFFF0F0F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(cx, cy), radius, trackPaint);

    // Progress arc
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color;
}

// ─── Alert Card ───────────────────────────────────────────────────────────────
class _AlertCard extends StatelessWidget {
  final ActiveDisruption disruption;

  const _AlertCard({required this.disruption});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _lightRed,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_rounded, color: _errorRed, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  disruption.message,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _errorRed,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Claim auto-triggered — ₹${disruption.payoutExpected} crediting ${disruption.creditDate}',
                  style: const TextStyle(fontSize: 13, color: _errorRed),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Active Policy Card ───────────────────────────────────────────────────────
class _PolicyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/policy'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardWhite,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Shield icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                      color: _lightGreen, shape: BoxShape.circle),
                  child: const Icon(Icons.shield_rounded,
                      color: _green, size: 24),
                ),
                const SizedBox(width: 12),
                // Name + price
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Standard Shield',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Text('₹87/week',
                            style: TextStyle(fontSize: 13, color: _textSub)),
                        const SizedBox(width: 8),
                        _ActiveBadge(),
                      ]),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: _textHint, size: 22),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(color: Color(0xFFF0F0F0), height: 1),
            const SizedBox(height: 10),
            const Text(
              'Covers rain, heat, pollution, app downtime',
              style: TextStyle(fontSize: 13, color: _textSub),
            ),
            const SizedBox(height: 4),
            const Text(
              'ACTIVE UNTIL 24 OCT 2026',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _textHint,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _lightGreen,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'ACTIVE',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _green,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─── Quick Actions ────────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickCard(
            icon: Icons.add_circle_rounded,
            label: 'Add Coverage',
            onTap: () => context.push('/policy/plans'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickCard(
            icon: Icons.article_rounded,
            label: 'View Certificate',
            onTap: () => context.push('/policy'),
          ),
        ),
      ],
    );
  }
}

class _QuickCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickCard(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: _cardWhite,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _green, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Missed Payouts Card ──────────────────────────────────────────────────────
class _MissedPayoutsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _lightAmber,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _amber.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.savings_rounded, color: _amber, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                const Text(
                  '₹680 could have been claimed',
                  style: TextStyle(fontSize: 13, color: _textSub),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: const Text(
                'SEE WHY',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _amber,
                  letterSpacing: 0.3,
                  decoration: TextDecoration.underline,
                  decorationColor: _amber,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
