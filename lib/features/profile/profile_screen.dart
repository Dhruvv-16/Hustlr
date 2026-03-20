import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/mock_data_service.dart';

import '../../core/constants/colors.dart' as app_colors;
import '../../core/router/app_router.dart';
import '../../shared/widgets/mobile_container.dart';
import '../../core/constants/text_styles.dart';

// ─── Local Palette (mapping to global tokens) ──────────────────────────────────
const _bgScreen   = app_colors.background;
const _green      = app_colors.primaryGreen;
const _lightGreen = app_colors.lightGreen;
const _red        = app_colors.errorRed;
const _lightRed   = app_colors.lightRed;
const _primary    = app_colors.textPrimary;
const _grey       = app_colors.textSecondary;
const _hint       = app_colors.textHint;
const _divider    = Color(0xFFE5E7EB);
const _cardWhite  = app_colors.cardWhite;

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgScreen,
      appBar: AppBar(
        backgroundColor: _bgScreen,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _primary,
          ),
        ),
        centerTitle: true,
      ),
      body: MobileContainer(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WorkerIdentityCard(),
            const SizedBox(height: 16),
            _IssTrendCard(),
            const SizedBox(height: 24),
            _SectionLabel('MY DOCUMENTS'),
            const SizedBox(height: 12),
            _DocumentsSection(),
            const SizedBox(height: 24),
            _SectionLabel('SUPPORT & HELP'),
            const SizedBox(height: 12),
            _SupportQuickRow(),
            const SizedBox(height: 24),
            _SectionLabel('ACCOUNT'),
            const SizedBox(height: 12),
            _AccountSection(),
            const SizedBox(height: 24),
            _SectionLabel('APP LANGUAGE'),
            const SizedBox(height: 12),
            _LanguageSelection(),
            const SizedBox(height: 24),
            _LogoutRow(),
          ],
        ),
      ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: _grey,
        letterSpacing: 1.2,
      ),
    );
  }
}

// ─── Worker Identity Card ─────────────────────────────────────────────────────
class _WorkerIdentityCard extends StatelessWidget {
  const _WorkerIdentityCard();

  @override
  Widget build(BuildContext context) {
    final mockData = Provider.of<MockDataService>(context);
    final worker = mockData.worker;

    return Container(
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top green accent bar
          Container(
            height: 4,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: _green,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HUSTLR ID: ${worker.id}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _green,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            worker.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.edit_rounded, size: 16, color: _hint),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${worker.city}, ${worker.zone}',
                        style: const TextStyle(fontSize: 14, color: _grey),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _lightGreen,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFC8E6C9)),
                        ),
                        child: Text(
                          '${worker.platform} Delivery Partner',
                          style: const TextStyle(
                            fontSize: 11, // Match spec feeling slightly smaller
                            fontWeight: FontWeight.w600,
                            color: _green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Avatar
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFE0B2), // Warm background
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  // We simulate the requested avatar visually using an icon,
                  // as providing a custom SVG/Image requires an external asset.
                  // If standard app uses real images, `AssetImage` would go here.
                  child: const Center(
                    child: Icon(Icons.person, size: 48, color: Color(0xFFFB8C00)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── ISS Trend Card ───────────────────────────────────────────────────────────
class _IssTrendCard extends StatelessWidget {
  const _IssTrendCard();

  @override
  Widget build(BuildContext context) {
    final mockData = Provider.of<MockDataService>(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your Stability Trend',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _primary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _lightGreen,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'ISS History',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${mockData.worker.issScore}%',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: _primary,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '↗+5%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Area line chart
          const SizedBox(
            height: 80,
            width: double.infinity,
            child: _ChartWidget(),
          ),
          const SizedBox(height: 8),
          // X-Axis labels
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('WK 1', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _hint, letterSpacing: 0.5)),
              Text('WK 2', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _hint, letterSpacing: 0.5)),
              Text('WK 3', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _hint, letterSpacing: 0.5)),
              Text('WK 4', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _hint, letterSpacing: 0.5)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartWidget extends StatelessWidget {
  const _ChartWidget();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ChartPainter(lineColor: _green, fillColor: _green.withValues(alpha: 0.08)),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final Color lineColor;
  final Color fillColor;

  const _ChartPainter({required this.lineColor, required this.fillColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintFill = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    // Data points to simulate the ISS history trend
    final points = [
      Offset(0, size.height * 0.8),
      Offset(size.width * 0.15, size.height * 0.2),
      Offset(size.width * 0.3, size.height * 0.7),
      Offset(size.width * 0.5, size.height * 0.1),
      Offset(size.width * 0.65, size.height * 0.5),
      Offset(size.width * 0.75, size.height * 0.9),
      Offset(size.width * 0.9, size.height * 0.05),
      Offset(size.width, size.height * 0.4),
    ];

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    // Draw smooth cubic bezier curve
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      path.cubicTo(
        p0.dx + (p1.dx - p0.dx) / 2,
        p0.dy,
        p0.dx + (p1.dx - p0.dx) / 2,
        p1.dy,
        p1.dx,
        p1.dy,
      );
    }

    // Fill path
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    // Draw gradient fill
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [lineColor.withValues(alpha: 0.2), Colors.white.withValues(alpha: 0.0)],
    );
    paintFill.shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, paintFill);
    canvas.drawPath(path, paintLine);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Documents Section ────────────────────────────────────────────────────────
class _DocumentsSection extends StatelessWidget {
  const _DocumentsSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Column(
        children: [
          _DocumentRow(
            icon: Icons.description_rounded,
            title: 'Policy Certificate',
          ),
          Divider(color: _divider, height: 1, indent: 48),
          _DocumentRow(
            icon: Icons.shield_rounded,
            title: 'Coverage Summary',
          ),
          Divider(color: _divider, height: 1, indent: 48),
          _DocumentRow(
            icon: Icons.receipt_long_rounded,
            title: 'Premium Receipts',
          ),
        ],
      ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  final IconData icon;
  final String title;

  const _DocumentRow({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: _green, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _primary,
              ),
            ),
          ),
          const Text(
            'VIEW',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _green,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.download_rounded, color: _hint, size: 18),
        ],
      ),
    );
  }
}

// ─── Support Quick Row ────────────────────────────────────────────────────────
class _SupportQuickRow extends StatelessWidget {
  const _SupportQuickRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _SupportItem(icon: Icons.chat_bubble_rounded, label: 'Live Chat'),
          _SupportItem(icon: Icons.phone_rounded, label: 'Call Us'),
          _SupportItem(icon: Icons.help_rounded, label: 'FAQ'),
        ],
      ),
    );
  }
}

class _SupportItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SupportItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: _lightGreen,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: _green, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: _primary,
          ),
        ),
      ],
    );
  }
}

// ─── Account Section ──────────────────────────────────────────────────────────
class _AccountSection extends StatelessWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.notifications_rounded, color: _green, size: 22),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _primary,
                    ),
                  ),
                ),
                Switch(
                  value: true,
                  onChanged: (v) {},
                  activeThumbColor: Colors.white,
                  activeTrackColor: _green,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
          const Divider(color: _divider, height: 1, indent: 48),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Icon(Icons.lock_rounded, color: _green, size: 22),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Privacy',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _primary,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: _hint, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── App Language ─────────────────────────────────────────────────────────────
class _LanguageSelection extends StatelessWidget {
  const _LanguageSelection();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: _LanguagePill(label: 'English', isSelected: true)),
        SizedBox(width: 8),
        Expanded(child: _LanguagePill(label: 'Tamil', isSelected: false)),
        SizedBox(width: 8),
        Expanded(child: _LanguagePill(label: 'Hindi', isSelected: false)),
      ],
    );
  }
}

class _LanguagePill extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _LanguagePill({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? _green : _cardWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSelected ? _green : Colors.transparent,
        ),
        boxShadow: isSelected
            ? null
            : const [
                BoxShadow(
                  color: Color(0x05000000),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : _grey,
        ),
      ),
    );
  }
}

// ─── Logout Row ───────────────────────────────────────────────────────────────
class _LogoutRow extends StatelessWidget {
  const _LogoutRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: _lightRed,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.logout_rounded, color: _red, size: 20),
          SizedBox(width: 8),
          Text(
            'Logout from Device',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: _red,
            ),
          ),
        ],
      ),
    );
  }
}
