import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart' as app_colors;
import '../../core/router/app_router.dart';
import '../../data/mock_data.dart';

const _bg = app_colors.background;
const _green = app_colors.primaryGreen;
const _lightGreen = app_colors.lightGreen;
const _amber = app_colors.amber;
const _lightAmber = app_colors.lightAmber;
const _errorRed = app_colors.errorRed;
const _textPrimary = app_colors.textPrimary;
const _textSub = app_colors.textSecondary;
const _borderLight = Color(0xFFE5E7EB);
const _cardWhite = Colors.white;

class PremiumBreakdownScreen extends StatelessWidget {
  const PremiumBreakdownScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final breakdown = MockData.premiumBreakdown;
    
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Your Premium Breakdown'),
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Current plan card (green)
            _buildCurrentPlanCard(),
            const SizedBox(height: 16),

            // 2. How it was calculated
            _buildCalculationCard(breakdown),
            const SizedBox(height: 16),

            // 3. Zone comparison
            _buildZoneComparisonCard(breakdown),
            const SizedBox(height: 16),

            // 4. High-risk week scenario
            _buildHighRiskScenarioCard(),
            const SizedBox(height: 16),

            // 5. Premium bounds
            _buildPremiumBoundsCard(breakdown),
            const SizedBox(height: 16),

            // 6. ISS impact + improve link
            _buildISSImpactCard(context, MockData.issScore),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPlanCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _green,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x332D6A2D), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                MockData.activePlan,
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Policy #${MockData.policyNumber}', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const Text('VALIDITY: ${MockData.policyValidity}', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          const Text('Your personalised weekly rate:', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 4),
          const Text(
            '₹${MockData.weeklyPremium} / week',
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),
          const Text('Fixed for 6 months · Next review: Oct 2026', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const Text('Backed by ICICI Lombard', style: TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildCalculationCard(Map<String, dynamic> breakdown) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ISS-Based Dynamic Pricing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textPrimary)),
          const SizedBox(height: 8),
          const Text(
            'Your premium is calculated from your Income Stability Score (${MockData.issScore}), zone risk data, platform reliability, and claim history.',
            style: const TextStyle(fontSize: 13, color: _textSub),
          ),
          const SizedBox(height: 20),
          
          // Header Row
          const Row(
            children: [
              Expanded(flex: 3, child: Text('Factor', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _textSub))),
              Expanded(flex: 2, child: Text('Adjustment', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _textSub))),
              Expanded(flex: 3, child: Text('Why', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _textSub))),
            ],
          ),
          const Divider(height: 24),
          
          _buildCalcRow('Base rate (Standard Shield)', '₹${breakdown['base_rate']}/wk', '—'),
          _buildCalcRow('Zone flood risk (${MockData.userZone}, ${MockData.zoneFloodRisk})', '₹${breakdown['zone_adjustment']}/wk', 'Moderate — no surcharge ✅'),
          _buildCalcRow('Regional behavior index (${MockData.behavioralIndex})', '₹${breakdown['behavioral_adjustment']}/wk', 'Within normal range ✅'),
          _buildCalcRow('Platform outage rate', '${breakdown['platform_discount'] < 0 ? '' : '+'}₹${breakdown['platform_discount']}/wk', '${MockData.userPlatform} uptime > 97% ✅', isDiscount: breakdown['platform_discount'] < 0),
          _buildCalcRow('Clean claim history (${MockData.cleanWeeks} weeks)', '${breakdown['clean_history_discount'] < 0 ? '' : '+'}₹${breakdown['clean_history_discount']}/wk', 'No claims this season ✅', isDiscount: breakdown['clean_history_discount'] < 0),
          
          const Divider(height: 24, color: _textPrimary),
          
          Row(
            children: [
              const Expanded(flex: 3, child: Text('Your personalised rate', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textPrimary))),
              Expanded(flex: 5, child: Text('₹${breakdown['final_rate']}/wk', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _green))),
            ],
          ),
          
          const SizedBox(height: 20),
          const Text(
            'Sourced from IMD historical data, Zepto order logs,\nand PLFS Gig Worker Earnings Survey 2025.',
            style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: _textSub),
          ),
        ],
      ),
    );
  }

  Widget _buildCalcRow(String factor, String adjustment, String why, {bool isDiscount = false}) {
    final bool isZero = adjustment == '₹0/wk';
    final Color adjColor = isDiscount ? _green : (isZero ? _textSub : _textPrimary);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: Text(factor, style: const TextStyle(fontSize: 12, color: _textPrimary))),
          Expanded(flex: 2, child: Text(adjustment, style: TextStyle(fontSize: 12, fontWeight: isDiscount ? FontWeight.bold : FontWeight.normal, color: adjColor))),
          Expanded(flex: 3, child: Text(why, style: const TextStyle(fontSize: 11, color: _textPrimary))),
        ],
      ),
    );
  }

  Widget _buildZoneComparisonCard(Map<String, dynamic> breakdown) {
    final List<Map<String, dynamic>> zones = List<Map<String, dynamic>>.from(breakdown['zone_comparison']);
    // Ensure descending order by rate for correct bar lengths
    zones.sort((a, b) => (b['rate'] as int).compareTo(a['rate'] as int));
    
    final int maxRate = zones.isNotEmpty ? zones.first['rate'] as int : 100;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCCE4FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How your zone compares', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textPrimary)),
          const SizedBox(height: 20),
          ...zones.map((z) {
            final double ratio = (z['rate'] as int) / maxRate;
            final bool isAdyar = z['zone'] == 'Adyar';
            final String note = isAdyar ? 'YOUR ZONE' : '${z['risk']} RISK';
            if (isAdyar && z['risk'] == 'HIGH') {} // Wait, Adyar's risk in DB is MODERATE, prompt says Adyar YOUR ZONE

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: isAdyar ? const BoxDecoration(border: Border(left: BorderSide(color: _green, width: 4))) : null,
              padding: isAdyar ? const EdgeInsets.only(left: 8) : const EdgeInsets.only(left: 12),
              child: Row(
                children: [
                  SizedBox(width: 80, child: Text(z['zone'], style: TextStyle(fontSize: 13, fontWeight: isAdyar ? FontWeight.bold : FontWeight.normal, color: _textPrimary))),
                  SizedBox(width: 50, child: Text('₹${z['rate']}/wk', style: TextStyle(fontSize: 13, fontWeight: isAdyar ? FontWeight.bold : FontWeight.normal, color: _textPrimary))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(height: 8, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(4))),
                        FractionallySizedBox(
                          widthFactor: ratio,
                          child: Container(height: 8, decoration: BoxDecoration(color: isAdyar ? _green : _textSub, borderRadius: BorderRadius.circular(4))),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(width: 70, child: Text(note, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isAdyar ? _green : _textSub))),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          const Text(
            'Workers in Velachery pay ₹6 more per week due to higher\nflood exposure near Pallikaranai marshland.',
            style: TextStyle(fontSize: 11, color: _textSub),
          ),
        ],
      ),
    );
  }

  Widget _buildHighRiskScenarioCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _lightAmber,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _amber.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('During high-risk weeks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textPrimary)),
          const SizedBox(height: 8),
          const Text(
            'When your zone records 2+ disruption events in a week, Hustlr automatically lowers trigger thresholds by 10%:',
            style: TextStyle(fontSize: 13, color: _textPrimary),
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Normal week:', style: TextStyle(fontSize: 13, color: _textSub)),
              Text('Rain threshold → 64.5mm/hr', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _textPrimary)),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('High-risk week:', style: TextStyle(fontSize: 13, color: _amber, fontWeight: FontWeight.bold)),
              Text('Rain threshold → 58.1mm/hr  (-10%)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _amber)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Easier to trigger during your worst weeks — when you need it most.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _textPrimary)),
          const SizedBox(height: 4),
          const Text('Your premium stays fixed. Only the threshold changes.', style: TextStyle(fontSize: 12, color: _textSub)),
        ],
      ),
    );
  }

  Widget _buildPremiumBoundsCard(Map<String, dynamic> breakdown) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pricing Guardrails', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textPrimary)),
          const SizedBox(height: 8),
          const Text(
            'Hustlr never charges you more than 2× or less than 0.7× of your base plan rate:',
            style: TextStyle(fontSize: 13, color: _textPrimary),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Maximum this season:', style: TextStyle(fontSize: 13, color: _textSub)),
              Text('₹${breakdown['max_bound']}/week', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textPrimary)),
            ],
          ),
          const Text('(2.0× Standard Shield base)', style: TextStyle(fontSize: 11, color: _textSub)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Minimum this season:', style: TextStyle(fontSize: 13, color: _textSub)),
              Text('₹${breakdown['min_bound']}/week', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textPrimary)),
            ],
          ),
          const Text('(0.7× Standard Shield base)', style: TextStyle(fontSize: 11, color: _textSub)),
          const SizedBox(height: 16),
          const Text('Your rate is fixed regardless of weather forecasts or upcoming disruption risk. You always know what you pay.', style: TextStyle(fontSize: 12, color: _textSub)),
        ],
      ),
    );
  }

  Widget _buildISSImpactCard(BuildContext context, int score) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your ISS Score Impact', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textPrimary)),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 8,
                    backgroundColor: const Color(0xFFF0F0F0),
                    color: _amber,
                  ),
                  Center(
                    child: Text(
                      score.toString(),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _amber),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildScoreTierRow('50–69', 'Standard Shield ₹49/wk', isRecommended: true),
          _buildScoreTierRow('70–100', 'Basic Shield ₹29/wk'),
          _buildScoreTierRow('30–49', 'Full Shield ₹79/wk', isRecommended: true),
          _buildScoreTierRow('0–29', 'Elite Shield ₹109/wk', isRecommended: true),
          const SizedBox(height: 24),
          const Text('Improve your score to unlock lower-risk pricing tier.', style: TextStyle(fontSize: 12, color: _textSub)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => context.push(AppRoutes.issDetail),
            child: const Text(
              'See how to improve →',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _green),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreTierRow(String range, String planText, {bool isRecommended = false}) {
    // Current tier is 50-69
    final isCurrent = range == '50–69';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text('Score $range', style: TextStyle(fontSize: 12, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal, color: isCurrent ? _textPrimary : _textSub)),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.arrow_right_alt_rounded, size: 16, color: _textSub),
          ),
          Expanded(
            child: Text(
              '$planText ${isCurrent ? 'recommended' : (isRecommended ? 'recommended' : 'available')}',
              style: TextStyle(fontSize: 12, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal, color: isCurrent ? _green : _textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
