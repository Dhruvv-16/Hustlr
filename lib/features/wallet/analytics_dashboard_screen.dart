import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import 'package:provider/provider.dart';
import '../../services/mock_data_service.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF5),
      appBar: AppBar(
        title: const Text('My Protection Analytics'),
        backgroundColor: const Color(0xFF125117),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 16),
                
                // Hero card - Income protected
                _buildHeroCard(context),
                const SizedBox(height: 16),

                // Policy info section
                _buildPolicyInfoCard(),
                const SizedBox(height: 16),

                // Disruption chart
                _buildDisruptionChart(),
                const SizedBox(height: 16),

                // Payout history
                _buildPayoutHistory(context),
                const SizedBox(height: 16),

                // Upgrade nudge
                _buildUpgradeNudge(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    final mockData = Provider.of<MockDataService>(context);
    final userZone = mockData.worker.zone.isNotEmpty ? mockData.worker.zone : 'Adyar Dark Store Zone';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF125117),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF125117).withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total income protected this month',
            style: TextStyle(
              color: Color(0xFFB0F3A6),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '₹2,190',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Across 3 disruption events in $userZone zone this month',
            style: const TextStyle(
              color: Color(0xFFB0F3A6),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildPolicyRow(
            title: 'Active Plan',
            value: 'Standard Shield',
            chip: 'Active',
            chipColor: const Color(0xFF125117),
          ),
          const SizedBox(height: 12),
          _buildPolicyRow(
            title: 'Policy Valid',
            value: 'Oct 2026',
          ),
          const SizedBox(height: 12),
          _buildPolicyRow(
            title: 'Add-ons',
            value: 'App Downtime (1 active)',
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyRow({
    required String title,
    required String value,
    String? chip,
    Color? chipColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF1A1C19),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        Row(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1A1C19),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (chip != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: chipColor ?? const Color(0xFF125117),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  chip!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildDisruptionChart() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Disruption hours this week',
            style: TextStyle(
              color: Color(0xFF1A1C19),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                barGroups: [
                  _buildBarGroup(0, 12, const Color(0xFF125117)), // Monday - Rain
                  _buildBarGroup(1, 8, const Color(0xFFFF9800)), // Tuesday - Heat
                  _buildBarGroup(2, 0, const Color(0xFF9E9E9E)), // Wednesday
                  _buildBarGroup(3, 6, const Color(0xFF125117)), // Thursday - Rain
                  _buildBarGroup(4, 4, const Color(0xFF2196F3)), // Friday - Platform
                  _buildBarGroup(5, 0, const Color(0xFF9E9E9E)), // Saturday
                  _buildBarGroup(6, 0, const Color(0xFF9E9E9E)), // Sunday
                ],
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            days[value.toInt()],
                            style: const TextStyle(
                              color: Color(0xFF1A1C19),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: false),
                barTouchData: BarTouchData(enabled: false),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Rain', const Color(0xFF125117)),
              const SizedBox(width: 16),
              _buildLegendItem('Heat', const Color(0xFFFF9800)),
              const SizedBox(width: 16),
              _buildLegendItem('Platform', const Color(0xFF2196F3)),
            ],
          ),
        ],
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, int y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y.toDouble(),
          color: color,
          width: 20,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF1A1C19),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPayoutHistory(BuildContext context) {
    final mockData = Provider.of<MockDataService>(context);
    final userZone = mockData.worker.zone.isNotEmpty ? mockData.worker.zone : 'Adyar Dark Store Zone';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payout history',
          style: TextStyle(
            color: Color(0xFF1A1C19),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        _buildPayoutCard(
          icon: Icons.water_drop_rounded,
          trigger: 'Heavy Rain',
          date: 'Oct 15, 2025',
          zone: userZone,
          amount: '₹820',
          status: 'Approved',
          statusColor: const Color(0xFF125117),
        ),
        const SizedBox(height: 8),
        _buildPayoutCard(
          icon: Icons.phonelink_off_rounded,
          trigger: 'Platform Downtime',
          date: 'Oct 12, 2025',
          zone: userZone,
          amount: '₹450',
          status: 'Pending',
          statusColor: const Color(0xFFFF9800),
        ),
        const SizedBox(height: 8),
        _buildPayoutCard(
          icon: Icons.wb_sunny_rounded,
          trigger: 'Extreme Heat',
          date: 'Oct 8, 2025',
          zone: userZone,
          amount: '₹920',
          status: 'Scheduled',
          statusColor: const Color(0xFF2196F3),
        ),
      ],
    );
  }

  Widget _buildPayoutCard({
    required IconData icon,
    required String trigger,
    required String date,
    required String zone,
    required String amount,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4EF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF125117),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trigger,
                  style: const TextStyle(
                    color: Color(0xFF1A1C19),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$date • $zone',
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: const TextStyle(
                  color: Color(0xFF125117),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeNudge() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF125117)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Upgrade to Full Shield to cover bandh and internet blackouts',
            style: TextStyle(
              color: Color(0xFF1A1C19),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push('/policy'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF125117),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Upgrade Now',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
