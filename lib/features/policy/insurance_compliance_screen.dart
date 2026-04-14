import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class InsuranceComplianceScreen extends StatelessWidget {
  const InsuranceComplianceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0a0b0a) : const Color(0xFFF4F6F4);
    final cardBg = isDark ? const Color(0xFF1c1f1c) : Colors.white;
    final green = isDark ? const Color(0xFF3FFF8B) : const Color(0xFF2E7D32);
    final text = isDark ? Colors.white : const Color(0xFF0D1B0F);
    final subtext = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: text),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Insurance Disclosure',
          style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(green, text),
            const SizedBox(height: 24),

            // 10-Point Checklist
            _buildSectionTitle('Insurance Sense Checklist', green),
            const SizedBox(height: 12),
            _buildChecklistCard(cardBg, text, subtext, green),
            const SizedBox(height: 24),

            // Social Security & DPDP
            _buildSectionTitle('Regulatory Compliance', green),
            const SizedBox(height: 12),
            _buildComplianceCard(cardBg, text, subtext, green),
            const SizedBox(height: 24),

            // IRDAI Guidelines
            _buildSectionTitle('IRDAI Guidelines', green),
            const SizedBox(height: 12),
            _buildIRDAICard(cardBg, text, subtext, green),
            const SizedBox(height: 24),

            // Data Collection Notice
            _buildSectionTitle('Data We Collect', green),
            const SizedBox(height: 12),
            _buildDataCollectionCard(cardBg, text, subtext, green),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color green, Color text) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user_rounded, color: green, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Hustlr is IRDAI-compliant parametric insurance',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'This screen explains how Hustlr follows insurance regulations and protects your data.',
            style: TextStyle(fontSize: 13, color: text.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color green) {
    return Row(
      children: [
        Container(width: 4, height: 20, color: green),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildChecklistCard(Color cardBg, Color text, Color subtext, Color green) {
    final checklist = [
      {
        'icon': Icons.check_circle,
        'title': 'Objective & Verifiable Trigger',
        'desc': 'AQI > 300 from CPCB API. Rain > 64.5mm/hr. Platform outage > 90 min. Quantifiable.',
      },
      {
        'icon': Icons.health_and_safety,
        'title': 'Excluded: Health, Life, Vehicle',
        'desc': 'Coverage is ONLY income loss from weather/AQI/platform disruption.',
      },
      {
        'icon': Icons.timer,
        'title': 'Automatic Payout',
        'desc': 'Trigger fires → GPS verified → UPI transfer within 2 hours. No human approval needed.',
      },
      {
        'icon': Icons.account_balance,
        'title': 'Financially Sustainable Pool',
        'desc': 'BCR 0.65. Stress-tested for 14-day monsoon. Liquidity reserve shown.',
      },
      {
        'icon': Icons.shield,
        'title': 'Fraud Detection on Data',
        'desc': 'Platform login cross-check. Duplicate zone detection. GPS jitter analysis.',
      },
      {
        'icon': Icons.credit_card,
        'title': 'Frictionless Premium Collection',
        'desc': 'Weekly micro-deductions via UPI auto-pay or wallet balance.',
      },
      {
        'icon': Icons.trending_up,
        'title': 'Dynamic Pricing',
        'desc': 'Premiums adjust algorithmically based on season (monsoon vs winter) and localized risk.',
      },
      {
        'icon': Icons.block,
        'title': 'Adverse Selection Blocked',
        'desc': 'Strict enrollment lock-out: Buying blocked 48 hours before official weather red alert.',
      },
      {
        'icon': Icons.speed,
        'title': 'Near-Zero Operational Cost',
        'desc': 'Straight-through processing. No manual claim handlers.',
      },
      {
        'icon': Icons.location_on,
        'title': 'Minimized Basis Risk',
        'desc': 'Hyper-localized weather data matches exact municipal ward where you work.',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: checklist.asMap().entries.map((e) {
          final item = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: green.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${e.key + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: green,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['desc'] as String,
                        style: TextStyle(fontSize: 12, color: subtext),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildComplianceCard(Color cardBg, Color text, Color subtext, Color green) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildComplianceItem(
            Icons.people,
            'Social Security Code, 2020',
            'Recognizes gig workers as a category eligible for welfare benefits. Hustlr provides the 90/120-day engagement tracking.',
            green,
            text,
            subtext,
          ),
          const SizedBox(height: 16),
          _buildComplianceItem(
            Icons.lock,
            'Digital Personal Data Protection Act, 2023',
            'India\'s primary data protection law. We collect only necessary data with explicit consent.',
            green,
            text,
            subtext,
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceItem(IconData icon, String title, String desc, Color green, Color text, Color subtext) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: green, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: text)),
              const SizedBox(height: 4),
              Text(desc, style: TextStyle(fontSize: 12, color: subtext)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIRDAICard(Color cardBg, Color text, Color subtext, Color green) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Most Relevant Provisions',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: text),
          ),
          const SizedBox(height: 12),
          _buildBulletPoint('Fairness and zero-touch claims', subtext),
          _buildBulletPoint('Trusted, reliable, independent public data sources', subtext),
          _buildBulletPoint('Automatic trigger claim payouts', subtext),
          const SizedBox(height: 16),
          Text(
            'Things We Care About',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: text),
          ),
          const SizedBox(height: 12),
          _buildCareItem('Pricing', 'Auto-adjusts based on season and area', subtext),
          _buildCareItem('Accuracy', 'GPS + weather data matching for fair payouts', subtext),
          _buildCareItem('Fraud Prevention', 'Built-in checks to stop location spoofing', subtext),
          _buildCareItem('Financial Proof', 'Historical data proves pool sustainability', subtext),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•  ', style: TextStyle(color: color, fontSize: 14)),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: color))),
        ],
      ),
    );
  }

  Widget _buildCareItem(String title, String desc, Color subtext) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•  ', style: TextStyle(color: subtext)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 13, color: subtext),
                children: [
                  TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.w600)),
                  TextSpan(text: desc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCollectionCard(Color cardBg, Color text, Color subtext, Color green) {
    final dataTypes = [
      {
        'icon': Icons.location_on,
        'title': 'GPS Location',
        'purpose': 'Verify you are in trigger zone',
        'consent': 'Separate consent screen required',
      },
      {
        'icon': Icons.account_balance,
        'title': 'Bank / UPI Account',
        'purpose': 'For payout disbursement',
        'consent': 'Explicit consent + KYC required',
      },
      {
        'icon': Icons.work,
        'title': 'Platform Activity Data',
        'purpose': 'Confirm active delivery days',
        'consent': 'Data sharing agreement with platform',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: dataTypes.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item['icon'] as IconData, color: green, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'] as String,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: text),
                      ),
                      Text(
                        item['purpose'] as String,
                        style: TextStyle(fontSize: 12, color: subtext),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item['consent'] as String,
                          style: TextStyle(fontSize: 10, color: green, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
