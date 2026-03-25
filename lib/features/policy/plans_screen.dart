// PlansScreen — standalone plan selection page reachable from
// /policy/plans (e.g. Dashboard "Add Coverage" CTA).
// Mirrors the Upgrade tab of PolicyScreen without the tab wrapper.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _green       = Color(0xFF2E7D32);
const _lightGreen  = Color(0xFFE8F5E9);
const _amber       = Color(0xFFFFA726);
const _purple      = Color(0xFF7B1FA2);
const _teal        = Color(0xFF00897B);
const _cardWhite   = Color(0xFFFFFFFF);
const _textPrimary = Color(0xFF1A1A2E);
const _textSub     = Color(0xFF6B7280);
const _textHint    = Color(0xFF9CA3AF);
const _borderLight = Color(0xFFE5E7EB);

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  String _selectedPlan = 'Standard Shield';
  final Map<String, bool> _riders = {
    'Curfew & Strike': false,
    'Election Day': false,
    'App Downtime': true,
  };

  static const _planPrices = {
    'Basic Shield': 29,
    'Standard Shield': 49,
    'Full Shield': 79,
    'Elite Shield': 109,
  };
  static const _riderPrices = {
    'Curfew & Strike': 15,
    'Election Day': 20,
    'App Downtime': 12,
  };

  int get _total {
    int t = _planPrices[_selectedPlan] ?? 49;
    for (final r in _riders.entries) {
      if (r.value) t += _riderPrices[r.key] ?? 0;
    }
    return t;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: _cardWhite,
        elevation: 0,
        leading: const BackButton(color: _textPrimary),
        title: const Text('Choose a Plan',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _textPrimary)),
        centerTitle: true,
      ),
      body: Stack(children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('UPGRADE YOUR PROTECTION',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _textHint,
                      letterSpacing: 0.8)),
              const SizedBox(height: 12),

              // ── Plan cards ──────────────────────────────────────────────────
              _planCard(
                name: 'Basic Shield',
                subtitle: 'Rain + Extreme Heat coverage',
                price: '₹29/wk',
                priceColor: _green,
                selectBorder: _green,
              ),
              _planCard(
                name: 'Standard Shield',
                subtitle: 'Rain, heat, pollution, app downtime',
                price: '₹49/wk',
                priceColor: _teal,
                selectBorder: _teal,
                badge: 'MOST POPULAR',
                badgeColor: _teal,
              ),
              _planCard(
                name: 'Full Shield',
                subtitle: 'All disruption types covered',
                price: '₹79/wk',
                priceColor: _purple,
                selectBorder: _purple,
              ),
              _planCard(
                name: 'Elite Shield',
                subtitle: 'All types + compound triggers',
                price: '₹109/wk',
                priceColor: Colors.white,
                selectBorder: _amber,
                badge: '★ BEST VALUE',
                badgeColor: _amber,
                cardBg: _amber,
                extra: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8)),
                      child: const Text('10% CASHBACK',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => context.push('/policy/compound'),
                      child: const Text('Learn about compound triggers \u2192',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white,
                          )),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              // ── Riders ──────────────────────────────────────────────────────
              Row(children: [
                const Text('Income Add-Ons',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: _lightGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('Protects Earnings',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _green)),
                ),
              ]),
              const SizedBox(height: 12),
              _riderRow(Icons.block_rounded, 'Curfew & Strike',
                  'Income loss during shutdowns', '+₹15/wk', 'Curfew & Strike'),
              _riderRow(Icons.how_to_vote_rounded, 'Election Day',
                  'Reduced orders on polling days', '+₹20/wk', 'Election Day'),
              _riderRow(Icons.phonelink_off_rounded, 'App Downtime',
                  'Platform outages over 90 mins', '+₹12/wk', 'App Downtime'),
              const SizedBox(height: 20),
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: const Text('Coverage Rules', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _textPrimary)),
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 16),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ruleText('45-minute minimum', 'disruption must last 45 continuous minutes'),
                    _ruleText('24-hour cooling period', 'same trigger cannot fire again within 24 hours'),
                    _ruleText('Shift overlap required', 'disruption must overlap shift by minimum 2 hours'),
                    _ruleText('One event per week per type', 'Basic + Standard Shield only'),
                    _ruleText('Post-activation only', 'events before activation never covered'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Sticky bottom ────────────────────────────────────────────────────
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 16,
                    offset: Offset(0, -4))
              ],
            ),
            child: Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('TOTAL WEEKLY COST',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _textHint,
                        letterSpacing: 0.5)),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(children: [
                    TextSpan(
                        text: '₹$_total',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _textPrimary)),
                    const TextSpan(
                        text: ' /week',
                        style:
                            TextStyle(fontSize: 13, color: _textSub)),
                  ]),
                ),
              ]),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/policy/payment'),
                  icon: const Icon(Icons.arrow_forward_rounded,
                      size: 18, color: Colors.white),
                  label: const Text(
                    'Proceed to\nPayment',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.3),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28)),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _planCard({
    required String name,
    required String subtitle,
    required String price,
    required Color priceColor,
    required Color selectBorder,
    String? badge,
    Color? badgeColor,
    Color? cardBg,
    Widget? extra,
  }) {
    final isSelected = _selectedPlan == name;
    final hasBadge = badge != null;
    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = name),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: EdgeInsets.only(
                bottom: hasBadge ? 18 : 10, top: hasBadge ? 10 : 0),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: cardBg ?? _cardWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: isSelected ? selectBorder : _borderLight,
                  width: isSelected ? 2 : 1),
            ),
            child: Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(name,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color:
                              cardBg != null ? Colors.white : _textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 13,
                          color:
                              cardBg != null ? Colors.white70 : _textSub)),
                  if (extra != null) ...[
                    const SizedBox(height: 6),
                    extra,
                  ],
                ]),
              ),
              Text(price,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: priceColor)),
            ]),
          ),
          if (hasBadge)
            Positioned(
              right: 16,
              top: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(10)),
                child: Text(badge!,
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _riderRow(IconData icon, String name, String subtitle,
      String price, String key) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderLight),
      ),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: _textSub, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(name,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary)),
            const SizedBox(height: 2),
            Row(children: [
              Text(subtitle,
                  style:
                      const TextStyle(fontSize: 12, color: _textHint)),
              const Spacer(),
              Text(price,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _textSub)),
            ]),
          ]),
        ),
        const SizedBox(width: 10),
        Switch(
          value: _riders[key] ?? false,
          onChanged: (v) => setState(() => _riders[key] = v),
          activeColor: _green,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ]),
    );
  }

  Widget _ruleText(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 14, color: _textHint)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: _textSub, height: 1.4),
                children: [
                  TextSpan(text: '$title — ', style: const TextStyle(fontWeight: FontWeight.bold, color: _textPrimary)),
                  TextSpan(text: desc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
