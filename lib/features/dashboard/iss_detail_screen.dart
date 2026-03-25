import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart' as app_colors;
import '../../core/router/app_router.dart';
import '../../data/mock_data.dart';

class ISSDetailScreen extends StatelessWidget {
  const ISSDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: app_colors.background,
      appBar: AppBar(
        title: const Text('Income Stability Score'),
        backgroundColor: app_colors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Large gauge
            _buildLargeISSGauge(MockData.issScore, MockData.issTier),
            const SizedBox(height: 24),

            // Score breakdown table
            _buildScoreBreakdownCard(),
            const SizedBox(height: 16),

            // How to improve (collapsible)
            _buildHowToImproveCard(),
            const SizedBox(height: 16),

            // Trend chart (4 weeks)
            _buildTrendChartCard(),
            const SizedBox(height: 16),

            // Plan recommendation
            _buildPlanRecommendationCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildLargeISSGauge(int score, String tier) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10)],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(160, 160),
                  painter: _LargeRingPainter(progress: score / 100, color: app_colors.amber),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$score', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: app_colors.textPrimary)),
                    Text(tier, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: app_colors.amber, letterSpacing: 1.2)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Moderate Risk · Standard Shield recommended', style: TextStyle(color: app_colors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildScoreBreakdownCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Score Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: app_colors.textPrimary)),
          const SizedBox(height: 16),
          _buildBreakdownRow('Zone flood risk (${MockData.userZone} ${MockData.zoneFloodRisk})', '-12 pts', 'High exposure', true),
          _buildBreakdownRow('Platform outage history', '-8 pts', 'Moderate', true),
          _buildBreakdownRow('Earnings consistency', '+5 pts', 'Stable 4 weeks', false),
          _buildBreakdownRow('Clean claim history', '+0 pts', 'No claims yet', false),
          _buildBreakdownRow('Regional behavior index (${MockData.behavioralIndex})', '-3 pts', '${MockData.userCity} score', true),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFFE5E7EB), height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Final ISS:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: app_colors.textPrimary)),
              Text('${MockData.issScore} / 100', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: app_colors.primaryGreen)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String factor, String impact, String value, bool isNegative) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: Text(factor, style: const TextStyle(fontSize: 12, color: app_colors.textPrimary, height: 1.3))),
          Expanded(flex: 1, child: Text(impact, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isNegative ? app_colors.errorRed : app_colors.primaryGreen))),
          Expanded(flex: 2, child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, color: app_colors.textSecondary))),
        ],
      ),
    );
  }

  Widget _buildHowToImproveCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: const Text('How to improve your score', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: app_colors.textPrimary)),
          iconColor: app_colors.primaryGreen,
          collapsedIconColor: app_colors.textSecondary,
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            _buildImprovementItem('Work more consistent hours', '+3 pts'),
            _buildImprovementItem('Build 4 weeks clean history', '+5 pts'),
            _buildImprovementItem('Move to lower flood-risk zone', '+10 pts'),
            _buildImprovementItem('Complete 8 clean weeks', 'Worker Trust Score unlocks'),
          ],
        ),
      ),
    );
  }

  Widget _buildImprovementItem(String text, String reward) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.arrow_forward_rounded, size: 14, color: app_colors.primaryGreen),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: app_colors.textPrimary))),
          Text(reward, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: app_colors.primaryGreen)),
        ],
      ),
    );
  }

  Widget _buildTrendChartCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Score Trend (4 Weeks)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: app_colors.textPrimary)),
              Text('Trending Up', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: app_colors.primaryGreen)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 100,
            width: double.infinity,
            child: CustomPaint(
              painter: _SimpleTrendChartPainter(MockData.issTrend),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Wk 1', style: TextStyle(fontSize: 11, color: app_colors.textSecondary)),
              Text('Wk 2', style: TextStyle(fontSize: 11, color: app_colors.textSecondary)),
              Text('Wk 3', style: TextStyle(fontSize: 11, color: app_colors.textSecondary)),
              Text('Wk 4', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: app_colors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlanRecommendationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: app_colors.lightGreen,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8E6C9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_rounded, color: app_colors.primaryGreen, size: 24),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Plan Recommendation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: app_colors.textPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 13, color: app_colors.textPrimary, height: 1.4),
              children: [
                TextSpan(text: 'Score 50–69 → ', style: TextStyle(color: app_colors.textSecondary)),
                TextSpan(text: 'Standard Shield ₹49/wk\n', style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: 'Improve to 70+ → ', style: TextStyle(color: app_colors.textSecondary)),
                TextSpan(text: 'Basic Shield ₹29/wk available', style: TextStyle(fontWeight: FontWeight.bold, color: app_colors.primaryGreen)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: app_colors.primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Text('See Plans →', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _LargeRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _LargeRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = (math.min(cx, cy)) - 10;
    const strokeWidth = 14.0;

    final trackPaint = Paint()
      ..color = const Color(0xFFF0F0F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(cx, cy), radius, trackPaint);
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _LargeRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _SimpleTrendChartPainter extends CustomPainter {
  final List<int> dataPoints;
  const _SimpleTrendChartPainter(this.dataPoints);

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.length < 2) return;

    final double minVal = dataPoints.reduce(math.min).toDouble() - 2;
    final double maxVal = dataPoints.reduce(math.max).toDouble() + 2;
    final double range = maxVal - minVal;

    final double xStep = size.width / (dataPoints.length - 1);

    final path = Path();
    for (int i = 0; i < dataPoints.length; i++) {
      final double x = i * xStep;
      final double y = size.height - ((dataPoints[i] - minVal) / range * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paintLine = Paint()
      ..color = app_colors.primaryGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paintLine);

    final paintDot = Paint()..color = app_colors.primaryGreen;
    final paintWhite = Paint()..color = Colors.white;
    for (int i = 0; i < dataPoints.length; i++) {
      final double x = i * xStep;
      final double y = size.height - ((dataPoints[i] - minVal) / range * size.height);
      
      canvas.drawCircle(Offset(x, y), 5, paintDot);
      canvas.drawCircle(Offset(x, y), 3, paintWhite);
    }
  }

  @override
  bool shouldRepaint(covariant _SimpleTrendChartPainter oldDelegate) {
    return true;
  }
}
