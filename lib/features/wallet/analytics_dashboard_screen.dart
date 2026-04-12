import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/claims/claims_bloc.dart';
import '../../models/claim.dart';
import '../../services/storage_service.dart';
import 'package:intl/intl.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  String _zone = '';

  @override
  void initState() {
    super.initState();
    StorageService.instance.getUserZone().then((z) {
      if (mounted) setState(() => _zone = z ?? '');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: theme.colorScheme.onSurface), onPressed: () => context.pop()),
        title: Text('My Protection Analytics',
            style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
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
                _buildHeroCard(context),
                const SizedBox(height: 16),
                _buildPolicyInfoCard(context),
                const SizedBox(height: 16),
                _buildDisruptionChart(context),
                const SizedBox(height: 16),
                _buildPayoutHistory(context),
                const SizedBox(height: 16),
                _buildUpgradeNudge(context),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Returns the quarterly policy expiry — 3 months from today — formatted as "Mon YYYY".
  String _quarterlyExpiry() {
    final expiry = DateTime.now().add(const Duration(days: 90));
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[expiry.month - 1]} ${expiry.year}';
  }

  Widget _buildHeroCard(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final userZone = _zone.replaceAll(RegExp(r' dark store zone', caseSensitive: false), '')
                          .replaceAll(RegExp(r' zone', caseSensitive: false), '').trim();
    final green = theme.colorScheme.primary;
    final heroBg = isDark ? const Color(0xFF004734) : const Color(0xFF125117);
    final subText = isDark ? green.withOpacity(0.8) : const Color(0xFFB0F3A6);

    final claimsState = context.watch<ClaimsBloc>().state;
    final claims = claimsState.claims;
    
    int total = 0;
    int count = 0;
    for (var c in claims) {
      if (c.status != ClaimStatus.rejected) {
        total += c.grossPayout;
        count++;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: heroBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: heroBg.withOpacity(0.25),
            blurRadius: 20, offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total income protected this month',
            style: TextStyle(color: subText, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            '₹$total',
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Across $count disruption event${count == 1 ? '' : 's'} in $userZone',
            style: TextStyle(color: subText, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyInfoCard(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          _buildPolicyRow(context, title: 'Active Plan', value: 'Standard Shield', chip: 'Active'),
          const SizedBox(height: 12),
          _buildPolicyRow(context, title: 'Policy Valid', value: _quarterlyExpiry()),
          const SizedBox(height: 12),
          _buildPolicyRow(context, title: 'Add-ons', value: 'App Downtime (1 active)'),
        ],
      ),
    );
  }

  Widget _buildPolicyRow(BuildContext context, {
    required String title,
    required String value,
    String? chip,
  }) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final green  = theme.colorScheme.primary;
    final text   = theme.colorScheme.onSurface;
    final btnTxt = isDark ? const Color(0xFF0A0B0A) : Colors.white;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(color: text, fontSize: 14, fontWeight: FontWeight.w400)),
        Row(
          children: [
            Text(value, style: TextStyle(color: text, fontSize: 14, fontWeight: FontWeight.w600)),
            if (chip != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: green, borderRadius: BorderRadius.circular(12)),
                child: Text(chip, style: TextStyle(color: btnTxt, fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildDisruptionChart(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final green  = theme.colorScheme.primary;
    final text   = theme.colorScheme.onSurface;
    final empty  = theme.colorScheme.onSurface.withOpacity(0.2);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Disruption hours this week',
            style: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                barGroups: [
                  _buildBarGroup(0, 0, empty),
                  _buildBarGroup(1, 0, empty),
                  _buildBarGroup(2, 0, empty),
                  _buildBarGroup(3, 0, empty),
                  _buildBarGroup(4, 0, empty),
                  _buildBarGroup(5, 0, empty),
                  _buildBarGroup(6, 0, empty),
                ],
                titlesData: FlTitlesData(
                  leftTitles:   AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:  AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(days[value.toInt()],
                              style: TextStyle(color: text.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w500)),
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
              _buildLegendItem(context, 'Rain',     green),
              const SizedBox(width: 16),
              _buildLegendItem(context, 'Heat',     const Color(0xFFFF9800)),
              const SizedBox(width: 16),
              _buildLegendItem(context, 'Platform', const Color(0xFF2196F3)),
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

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    final text = Theme.of(context).colorScheme.onSurface.withOpacity(0.7);
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: text, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildPayoutHistory(BuildContext context) {
    final theme  = Theme.of(context);
    final green  = theme.colorScheme.primary;
    final text   = theme.colorScheme.onSurface;
    final userZone = _zone.replaceAll(RegExp(r' dark store zone', caseSensitive: false), '')
                          .replaceAll(RegExp(r' zone', caseSensitive: false), '').trim();

    final claimsState = context.watch<ClaimsBloc>().state;
    final claims = claimsState.claims;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payout history', style: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        if (claims.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Text(
                'No recent payouts to show.',
                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
              ),
            ),
          )
        else
          ...claims.take(3).map((claim) {
            IconData icon;
            if (claim.triggerType.contains('rain')) {
              icon = Icons.water_drop_rounded;
            } else if (claim.triggerType.contains('heat')) {
              icon = Icons.wb_sunny_rounded;
            } else {
              icon = Icons.phonelink_off_rounded;
            }
            
            Color statusColor;
            switch (claim.status) {
              case ClaimStatus.approved: statusColor = green; break;
              case ClaimStatus.rejected: statusColor = theme.colorScheme.error; break;
              case ClaimStatus.processing: statusColor = const Color(0xFF2196F3); break;
              default: statusColor = const Color(0xFFFF9800); break;
            }

            final dateStr = DateFormat('MMM d, yyyy').format(claim.createdAt);
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildPayoutCard(
                context, 
                icon: icon, 
                trigger: claim.displayLabel,
                date: dateStr, 
                zone: userZone, 
                amount: '₹${claim.grossPayout}',
                status: claim.status.displayLabel, 
                statusColor: statusColor
              ),
            );
          }),
      ],
    );
  }

  Widget _buildPayoutCard(BuildContext context, {
    required IconData icon,
    required String trigger,
    required String date,
    required String zone,
    required String amount,
    required String status,
    required Color statusColor,
  }) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final text   = theme.colorScheme.onSurface;
    final sub    = theme.colorScheme.onSurface.withOpacity(0.5);
    final iconBg = isDark ? const Color(0xFF1C1F1C) : const Color(0xFFF4F4EF);
    final green  = theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: green, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(trigger, style: TextStyle(color: text, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('$date • $zone', style: TextStyle(color: sub, fontSize: 12, fontWeight: FontWeight.w400)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: TextStyle(color: green, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeNudge(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final green  = theme.colorScheme.primary;
    final text   = theme.colorScheme.onSurface;
    final btnTxt = isDark ? const Color(0xFF0A0B0A) : Colors.white;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border.all(color: green.withOpacity(isDark ? 0.4 : 1.0)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Upgrade to Full Shield to cover bandh and internet blackouts',
            style: TextStyle(color: text, fontSize: 14, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push('/policy'),
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: btnTxt,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text('Upgrade Now',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: btnTxt)),
            ),
          ),
        ],
      ),
    );
  }
}
