import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart' as app_colors;
import '../../core/router/app_router.dart';
import '../../data/mock_data.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  String _selectedPeriod = 'This Month';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: app_colors.background,
      appBar: AppBar(
        title: const Text('My Protection Analytics'),
        backgroundColor: app_colors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Period selector chips
            _buildPeriodSelector(),
            const SizedBox(height: 16),

            // Earnings protected (large green card)
            _buildEarningsCard(),
            const SizedBox(height: 16),

            // Coverage summary (3 mini cards in a row)
            _buildCoverageSummary(),
            const SizedBox(height: 16),

            // Disruption events bar chart
            _buildDisruptionChart(),
            const SizedBox(height: 16),

            // Payout history timeline
            _buildPayoutHistory(),
            const SizedBox(height: 16),

            // ISS trend
            _buildISSTrend(),
            const SizedBox(height: 16),

            // Missed coverage (shadow policy nudge)
            _buildMissedCoverageCard(),
            const SizedBox(height: 16),

            // Pool health
            _buildPoolHealthCard(),
            const SizedBox(height: 24),

            const Text(
              'Data sourced from IMD, Zepto order logs, and TRAI.\nUpdated every Monday 12 AM.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ['This Week', 'This Month', 'Last 3 Months'].map((period) {
          final isSelected = _selectedPeriod == period;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(period),
              selected: isSelected,
              selectedColor: app_colors.primaryGreen,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (_) => setState(() => _selectedPeriod = period),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isSelected ? app_colors.primaryGreen : const Color(0xFFE5E7EB)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEarningsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: app_colors.primaryGreen,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Income protected this month', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          const Text('₹2,190', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Across 3 disruption events in ${MockData.userZone} zone', style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Vs. Uninsured:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                Row(
                  children: [
                    Text('Protected: ₹2,190', style: TextStyle(color: Color(0xFF81C784), fontWeight: FontWeight.bold, fontSize: 12)),
                    Text('  ·  ', style: TextStyle(color: Colors.white54)),
                    Text('Uninsured: ₹0', style: TextStyle(color: Color(0xFFEF9A9A), fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverageSummary() {
    return Row(
      children: [
        Expanded(child: _miniCard('Active Plan', MockData.activePlan, '₹49/wk')),
        const SizedBox(width: 8),
        Expanded(child: _miniCard('Policy Valid', 'Oct 2026', '✅ Active')),
        const SizedBox(width: 8),
        Expanded(child: _miniCard('Add-ons', '1 active', 'App Downtime')),
      ],
    );
  }

  Widget _miniCard(String title, String mainValue, String subValue) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      height: 90,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: app_colors.textSecondary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(mainValue, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: app_colors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(subValue, style: const TextStyle(fontSize: 11, color: app_colors.primaryGreen, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildDisruptionChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Disruption hours this month', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: app_colors.textPrimary)),
          const SizedBox(height: 24),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 5,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        if (value >= 0 && value < MockData.weeklyDisruptionHours.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(MockData.weeklyDisruptionHours[value.toInt()]['week'], style: const TextStyle(fontSize: 11, color: app_colors.textSecondary)),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: MockData.weeklyDisruptionHours.asMap().entries.map((entry) {
                  final i = entry.key;
                  final data = entry.value;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(toY: data['rain'].toDouble(), color: Colors.blue.shade300, width: 8),
                      BarChartRodData(toY: data['heat'].toDouble(), color: Colors.orange.shade300, width: 8),
                      BarChartRodData(toY: data['platform'].toDouble(), color: Colors.grey.shade400, width: 8),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendCircle(Colors.blue.shade300, 'Rain'),
              const SizedBox(width: 16),
              _legendCircle(Colors.orange.shade300, 'Heat'),
              const SizedBox(width: 16),
              _legendCircle(Colors.grey.shade400, 'Platform'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendCircle(Color color, String label) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: app_colors.textSecondary)),
      ],
    );
  }

  Widget _buildPayoutHistory() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payout History', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: app_colors.textPrimary)),
          const SizedBox(height: 16),
          _payoutItem('🌧', 'Rain Disruption', 'Mar 12 · Adyar', '+₹105', '✅ Provisional', true),
          const Divider(height: 24, color: Color(0xFFE5E7EB)),
          _payoutItem('📱', 'Platform Downtime', 'Mar 8 · Zepto', '+₹70', '✅ Settled', true),
          const Divider(height: 24, color: Color(0xFFE5E7EB)),
          _payoutItem('🌡', 'Extreme Heat', 'Mar 5', '+₹120', '⏳ Pending Sunday', false),
        ],
      ),
    );
  }

  Widget _payoutItem(String emoji, String title, String subtitle, String amount, String status, bool isComplete) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: app_colors.textPrimary)),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: app_colors.textSecondary)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(amount, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: app_colors.primaryGreen)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Text('AUTO ', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: app_colors.amber)),
                Text(status, style: TextStyle(fontSize: 10, color: isComplete ? app_colors.primaryGreen : app_colors.textSecondary)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildISSTrend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ISS Score This Month', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: app_colors.textPrimary)),
          const SizedBox(height: 24),
          SizedBox(
            height: 60,
            width: double.infinity,
            child: CustomPaint(
              painter: _TrendSparkPainter([58, 59, 60, 62]),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('62 · Trending up +4 this month', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: app_colors.textPrimary)),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_upward_rounded, color: app_colors.primaryGreen, size: 16),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMissedCoverageCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: app_colors.lightAmber,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: app_colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: app_colors.amber.withOpacity(0.15), shape: BoxShape.circle),
            child: const Icon(Icons.savings_rounded, color: app_colors.amber, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Before you were insured:', style: TextStyle(fontSize: 12, color: app_colors.textSecondary)),
                const SizedBox(height: 4),
                const Text('₹380 in payouts you missed', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: app_colors.textPrimary)),
                const SizedBox(height: 12),
                const Text('₹49 premium × 2 weeks = ₹98 cost\n₹380 missed payouts\n= ₹282 net benefit from being insured', style: TextStyle(fontSize: 12, color: app_colors.textPrimary, height: 1.4)),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => context.push(AppRoutes.plans),
                  child: const Text('Upgrade to Full Shield →', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: app_colors.amber)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoolHealthCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: app_colors.primaryGreen, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  const Text('Hustlr Pool Health', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: app_colors.textPrimary)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: app_colors.lightGreen, borderRadius: BorderRadius.circular(20)),
                child: const Text('STRONG ✅', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: app_colors.primaryGreen)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _healthRow('This week\'s pool:', '₹4,90,000'),
          _healthRow('Payout rate:', '57%'),
          _healthRow('Reserve fund:', '25%'),
          _healthRow('Buffer remaining:', '18%'),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: app_colors.background, borderRadius: BorderRadius.circular(8)),
            child: const Text('Your plan is backed by ICICI Lombard', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: app_colors.textSecondary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _healthRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: app_colors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: app_colors.textPrimary)),
        ],
      ),
    );
  }
}

class _TrendSparkPainter extends CustomPainter {
  final List<int> dataPoints;
  const _TrendSparkPainter(this.dataPoints);

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
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
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
  bool shouldRepaint(covariant _TrendSparkPainter oldDelegate) => true;
}
