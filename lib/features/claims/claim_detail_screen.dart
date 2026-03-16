import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ─── Local Palette ────────────────────────────────────────────────────────────
const _bgScreen   = Color(0xFFF8F9FA);
const _green      = Color(0xFF2E7D32);
const _lightGreen = Color(0xFFE8F5E9);
const _amber      = Color(0xFFF57C00);
const _blue       = Color(0xFF1976D2);
const _lightBlue  = Color(0xFFE3F2FD);
const _primary    = Color(0xFF1A1A2E);
const _grey       = Color(0xFF6B7280);
const _hint       = Color(0xFF9CA3AF);
const _divider    = Color(0xFFE5E7EB);
const _cardWhite  = Colors.white;

class ClaimDetailScreen extends StatelessWidget {
  final String claimId;
  const ClaimDetailScreen({super.key, required this.claimId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgScreen,
      appBar: AppBar(
        backgroundColor: _bgScreen,
        elevation: 0,
        leading: BackButton(color: _primary, onPressed: () => context.pop()),
        title: const Text(
          'Claim Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _primary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: _primary),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 120),
            child: Column(
              children: [
                _HeaderSection(),
                const SizedBox(height: 32),
                const _ProgressTrackerCard(),
                const SizedBox(height: 16),
                const _PayoutBreakdownCard(),
                const SizedBox(height: 16),
                const _EvidenceCard(),
                const SizedBox(height: 16),
                const _FraudCheckCard(),
                const SizedBox(height: 24),
                // Support Link
                GestureDetector(
                  onTap: () {},
                  child: const Text(
                    'Issue with this claim? Chat with support →',
                    style: TextStyle(
                      fontSize: 14,
                      color: _blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Floating Help Button
          Positioned(
            right: 20,
            bottom: 20,
            child: FloatingActionButton(
              onPressed: () {},
              backgroundColor: _green,
              elevation: 4,
              shape: const CircleBorder(),
              child: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────
class _HeaderSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: const BoxDecoration(
            color: _lightGreen,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: _green, size: 48),
        ),
        const SizedBox(height: 16),
        const Text(
          'Claim Approved',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _primary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Rain Disruption • Koramangala Zone',
          style: TextStyle(
            fontSize: 14,
            color: _grey,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Updated Today, 11:45 PM',
          style: TextStyle(
            fontSize: 12,
            color: _hint,
          ),
        ),
      ],
    );
  }
}

// ─── Progress Tracker ─────────────────────────────────────────────────────────
class _ProgressTrackerCard extends StatelessWidget {
  const _ProgressTrackerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildStep(
            label: 'Detected',
            time: '2:34 PM',
            state: _StepState.completed,
            isFirst: true,
          )),
          Expanded(child: _buildStep(
            label: 'Verified',
            time: '2:35 PM',
            state: _StepState.completed,
            subtitle: 'Fraud: 12/100',
            subtitleColor: const Color(0xFFE8F5E9),
            subtitleTextColor: _green,
          )),
          Expanded(child: _buildStep(
            label: 'Processing',
            time: 'Sun 11 PM',
            state: _StepState.completed,
          )),
          Expanded(child: _buildStep(
            label: 'Paid',
            time: '',
            state: _StepState.current,
            customSubtitle: const Column(
              children: [
                Text('70% paid', style: TextStyle(fontSize: 11, color: _green, fontWeight: FontWeight.w600)),
                Text('30% pending', style: TextStyle(fontSize: 11, color: _amber, fontWeight: FontWeight.w600)),
              ],
            ),
            isLast: true,
          )),
        ],
      ),
    );
  }

  Widget _buildStep({
    required String label,
    required String time,
    required _StepState state,
    bool isFirst = false,
    bool isLast = false,
    String? subtitle,
    Color? subtitleColor,
    Color? subtitleTextColor,
    Widget? customSubtitle,
  }) {
    // 28px diameter icon
    Widget icon;
    if (state == _StepState.completed) {
      icon = Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
      );
    } else {
      icon = Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: _green, width: 2),
        ),
        child: Center(
          child: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: _green,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }

    // Line segments
    Widget lineLeft = Expanded(
      child: Container(
        height: 2,
        color: isFirst ? Colors.transparent : _green,
      ),
    );
    Widget lineRight = Expanded(
      child: Container(
        height: 2,
        color: isLast ? Colors.transparent : (state == _StepState.completed ? _green : _divider),
      ),
    );
    // Custom logic to handle partial line after 'Processing'
    if (label == 'Processing') {
      lineRight = Expanded(
        child: Row(
          children: [
            Expanded(flex: 3, child: Container(height: 2, color: _green)),
            Expanded(flex: 7, child: Container(height: 2, color: _divider)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            lineLeft,
            icon,
            lineRight,
          ],
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
        const SizedBox(height: 2),
        if (time.isNotEmpty) ...[
          Text(
            time,
            style: const TextStyle(
              fontSize: 11,
              color: _hint,
            ),
          ),
        ],
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: subtitleColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: subtitleTextColor,
              ),
            ),
          ),
        ],
        if (customSubtitle != null) ...[
          const SizedBox(height: 4),
          customSubtitle,
        ],
      ],
    );
  }
}

enum _StepState { completed, current }

// ─── Payout Breakdown ─────────────────────────────────────────────────────────
class _PayoutBreakdownCard extends StatelessWidget {
  const _PayoutBreakdownCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(height: 3, color: _green, width: double.infinity),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'TOTAL PAYOUT',
                      style: TextStyle(
                        fontSize: 11,
                        color: _hint,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const Text(
                      '₹850',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: _green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: _divider, height: 1),
                const SizedBox(height: 16),
                _PayoutRow(color: _green, label: 'Payment Credited', amount: '₹595', amountColor: _green),
                const SizedBox(height: 16),
                const _PayoutRow(color: _amber, label: 'Verification Pending', amount: '₹255', amountColor: _amber),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PayoutRow extends StatelessWidget {
  final Color color;
  final String label;
  final String amount;
  final Color amountColor;

  const _PayoutRow({
    required this.color,
    required this.label,
    required this.amount,
    required this.amountColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _primary,
            ),
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: amountColor,
          ),
        ),
      ],
    );
  }
}

// ─── Evidence Card ────────────────────────────────────────────────────────────
class _EvidenceCard extends StatelessWidget {
  const _EvidenceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DISRUPTION EVIDENCE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _grey,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _lightBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.cloud_download_outlined, color: _blue, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '67.3mm rainfall detected',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Exceeded 64mm threshold',
                      style: TextStyle(fontSize: 13, color: _grey),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: _hint,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Data source: OpenWeather API',
                          style: TextStyle(fontSize: 11, color: _hint),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Fraud Check Card ─────────────────────────────────────────────────────────
class _FraudCheckCard extends StatelessWidget {
  const _FraudCheckCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_rounded, color: _green, size: 28),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fraud Check Passed',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _primary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Score: 12 / 100',
                  style: TextStyle(fontSize: 12, color: _grey),
                ),
              ],
            ),
          ),
          const Icon(Icons.expand_more_rounded, color: _hint),
        ],
      ),
    );
  }
}
