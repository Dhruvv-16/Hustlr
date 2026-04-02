import 'package:flutter/material.dart';
import '../../core/constants/text_styles.dart';
import '../../shared/widgets/mobile_container.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/hustlr_bottom_nav.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────
const _green       = Color(0xFF2E7D32);
const _lightGreen  = Color(0xFFE8F5E9);
const _purple      = Color(0xFF7C3AED);
const _teal        = Color(0xFF00897B);
const _orange      = Color(0xFFF57C00);
const _cardWhite   = Color(0xFFFFFFFF);
const _textPrimary = Color(0xFF1A1A2E);
const _textSub     = Color(0xFF6B7280);
const _textHint    = Color(0xFF9CA3AF);
const _borderLight = Color(0xFFE5E7EB);

// Dark mode palette
const _darkGreen       = Color(0xFF3FFF8B);
const _darkLightGreen  = Color(0xFF003D2A);
const _darkCardBg      = Color(0xFF1c1f1c);
const _darkTextPrimary = Colors.white;
const _darkTextSub     = Color(0xFF91938d);
const _darkBorder      = Color(0xFF2a2d2a);

// ─── Plan Data ────────────────────────────────────────────────────────────────
class _Plan {
  final String name;
  final String subtitle;
  final String price;
  final Color priceColor;
  final Color? borderColor;
  final String? badge;
  final Color? badgeColor;
  final Color? cardBg;
  final bool accentLeft;

  const _Plan({
    required this.name,
    required this.subtitle,
    required this.price,
    required this.priceColor,
    this.borderColor,
    this.badge,
    this.badgeColor,
    this.cardBg,
    this.accentLeft = false,
  });
}

const _plans = [
  _Plan(
    name: 'Basic Shield',
    subtitle: 'Rain + extreme heat cover',
    price: '₹29/wk',
    priceColor: _green,
    borderColor: _borderLight,
    accentLeft: true,
  ),
  _Plan(
    name: 'Standard Shield',
    subtitle: 'Rain, heat, pollution, app downtime',
    price: '₹49/wk',
    priceColor: _green,
    borderColor: _green,
    badge: 'MOST POPULAR',
    badgeColor: _teal,
  ),
  _Plan(
    name: 'Full Shield',
    subtitle: 'All disruption types covered',
    price: '₹79/wk',
    priceColor: _purple,
    borderColor: _borderLight,
  ),
  _Plan(
    name: 'Elite Shield',
    subtitle: 'All types + compound triggers',
    price: '₹109/wk',
    priceColor: Colors.white,
    borderColor: _orange,
    badge: '★ BEST VALUE',
    badgeColor: Color(0xFFE65100),
    cardBg: _orange,
  ),
];

// ─── Rider Data ───────────────────────────────────────────────────────────────
class _Rider {
  final IconData icon;
  final String name;
  final String price;
  final bool defaultOn;

  const _Rider({
    required this.icon,
    required this.name,
    required this.price,
    required this.defaultOn,
  });
}

const _riders = [
  _Rider(
    icon: Icons.groups_rounded,
    name: 'Curfew & Strike',
    price: '+₹15/week',
    defaultOn: false,
  ),
  _Rider(
    icon: Icons.how_to_vote_rounded,
    name: 'Election Day',
    price: '+₹20/week',
    defaultOn: false,
  ),
  _Rider(
    icon: Icons.phonelink_off_rounded,
    name: 'App Downtime',
    price: '+₹12/week',
    defaultOn: true,
  ),
  _Rider(
    icon: Icons.cyclone_rounded,
    name: 'Cyclone',
    price: '+₹25/week',
    defaultOn: false,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
//  POLICY SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class PolicyScreen extends StatefulWidget {
  const PolicyScreen({super.key});

  @override
  State<PolicyScreen> createState() => _PolicyScreenState();
}

class _PolicyScreenState extends State<PolicyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Default active tab = "Upgrade" (index 1)
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0a0b0a) : const Color(0xFFF0F4F0);
    final appBarColor = isDark ? const Color(0xFF141614) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textSub = isDark ? const Color(0xFF91938d) : const Color(0xFF6B7280);
    final green = isDark ? const Color(0xFF3FFF8B) : const Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        leading: BackButton(color: textPrimary),
        title: Text(
          'Policy & Plans',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
            color: appBarColor,
            child: TabBar(
              controller: _tabController,
              labelColor: green,
              unselectedLabelColor: textSub,
              labelStyle: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500),
              indicatorColor: green,
              indicatorWeight: 2,
              tabs: const [
                Tab(text: 'Current Plan'),
                Tab(text: 'Upgrade'),
                Tab(text: 'History'),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: MobileContainer(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _CurrentPlanTab(),
                  _UpgradeTab(onProceed: () => context.push('/policy/payment')),
                  _HistoryTab(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        break;
      case 2:
        context.go('/claims');
        break;
      case 3:
        context.go('/wallet');
        break;
    }
  }
}

// ─── Tab 1: Current Plan ──────────────────────────────────────────────────────
class _CurrentPlanTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel('ACTIVE COVERAGE'),
        const SizedBox(height: 12),
        _ActiveCoverageCard(),
        const SizedBox(height: 24),
        _sectionLabel('COVERAGE DETAILS'),
        const SizedBox(height: 12),
        _coverageItem(context, Icons.water_drop_rounded, 'Rain Disruption',
            'Auto-triggers when rain > 3hrs'),
        _coverageItem(context, Icons.wb_sunny_rounded, 'Extreme Heat',
            'Triggers above 42°C advisory'),
        _coverageItem(context, Icons.air_rounded, 'Pollution Alert',
            'AQI > 200 in your zone'),
        _coverageItem(context, Icons.phonelink_off_rounded, 'App Downtime',
            'Outages over 90 minutes'),
      ]),
    );
  }

  Widget _coverageItem(BuildContext context, IconData icon, String title, String subtitle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardWhite = isDark ? const Color(0xFF1c1f1c) : Colors.white;
    final borderLight = isDark ? const Color(0xFF2a2d2a) : const Color(0xFFE5E7EB);
    final lightGreen = isDark ? const Color(0xFF003D2A) : const Color(0xFFE8F5E9);
    final green = isDark ? const Color(0xFF3FFF8B) : const Color(0xFF2E7D32);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textHint = isDark ? const Color(0xFF91938d) : const Color(0xFF9CA3AF);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderLight)),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: lightGreen, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: green, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: TextStyle(fontSize: 12, color: textHint)),
          ]),
        ),
        Icon(Icons.check_circle_rounded, color: green, size: 20),
      ]),
    );
  }
}

// ─── Active Coverage Card ─────────────────────────────────────────────────────
class _ActiveCoverageCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _green,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(
            child: Text('Standard Shield',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_rounded,
                color: Colors.white, size: 22),
          ),
        ]),
        const SizedBox(height: 4),
        const Text('Policy #HS-98234-AX',
            style: TextStyle(fontSize: 12, color: Colors.white70)),
        const SizedBox(height: 12),
        const Text('VALIDITY',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white60,
                letterSpacing: 0.8)),
        const SizedBox(height: 4),
        const Text('26 Oct 2025 - 25 Oct 2026',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: _GhostButton(
              onPressed: () {},
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.download_rounded, size: 15, color: Colors.white),
                  SizedBox(width: 6),
                  Text('Download Certificate',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          _GhostButton(
            onPressed: () {},
            width: 44,
            height: 40,
            child: const Icon(Icons.share_rounded,
                color: Colors.white, size: 18),
          ),
        ]),
      ]),
    );
  }
}

class _GhostButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final double? width;
  final double height;

  const _GhostButton({
    required this.onPressed,
    required this.child,
    this.width,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: width,
        height: height,
        padding: width == null
            ? const EdgeInsets.symmetric(horizontal: 12)
            : EdgeInsets.zero,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ─── Tab 2: Upgrade ───────────────────────────────────────────────────────────
class _UpgradeTab extends StatefulWidget {
  final VoidCallback onProceed;
  const _UpgradeTab({required this.onProceed});

  @override
  State<_UpgradeTab> createState() => _UpgradeTabState();
}

class _UpgradeTabState extends State<_UpgradeTab> {
  String _selectedPlan = 'Standard Shield';
  final Map<String, bool> _riderToggles = {
    'Curfew & Strike': false,
    'Election Day': false,
    'App Downtime': true,
    'Cyclone': false,
  };

  int get _totalCost {
    const planPrices = {
      'Basic Shield': 29,
      'Standard Shield': 49,
      'Full Shield': 79,
      'Elite Shield': 109,
    };
    const riderPrices = {
      'Curfew & Strike': 15,
      'Election Day': 20,
      'App Downtime': 12,
      'Cyclone': 25,
    };
    int total = planPrices[_selectedPlan] ?? 49;
    for (final r in _riderToggles.entries) {
      if (r.value) total += riderPrices[r.key] ?? 0;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ACTIVE COVERAGE section
          _sectionLabel('ACTIVE COVERAGE'),
          const SizedBox(height: 12),
          _ActiveCoverageCard(),
          const SizedBox(height: 24),
          // UPGRADE section
          _sectionLabel('UPGRADE YOUR PROTECTION'),
          const SizedBox(height: 12),
          ..._plans.map((p) => _PlanCard(
                plan: p,
                isSelected: _selectedPlan == p.name,
                onTap: () => setState(() => _selectedPlan = p.name),
              )),
          const SizedBox(height: 20),
          // Add-ons header
          Row(children: [
            _sectionLabel('INCOME ADD-ONS'),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _lightGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Protects Earnings',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _green)),
            ),
          ]),
          const SizedBox(height: 12),
          ..._riders.map((r) => _RiderRow(
                rider: r,
                value: _riderToggles[r.name] ?? r.defaultOn,
                onChanged: (v) =>
                    setState(() => _riderToggles[r.name] = v),
              )),
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
        ]),
      ),
      Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: _StickyBottomBar(
          total: _totalCost,
          onProceed: widget.onProceed,
        ),
      ),
    ]);
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

// ─── Plan Card ────────────────────────────────────────────────────────────────
class _PlanCard extends StatelessWidget {
  final _Plan plan;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlanCard(
      {required this.plan, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasBadge = plan.badge != null;
    final isElite = plan.cardBg != null;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: EdgeInsets.only(
                bottom: 10, top: hasBadge ? 10 : 0),
            decoration: BoxDecoration(
              color: plan.cardBg ?? _cardWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? (plan.borderColor ?? _green)
                    : (plan.borderColor ?? _borderLight),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left accent line (Basic Shield only)
                    if (plan.accentLeft)
                      Container(width: 3, color: _green),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(plan.name,
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: isElite
                                            ? Colors.white
                                            : _textPrimary)),
                                const SizedBox(height: 2),
                                Text(plan.subtitle,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: isElite
                                            ? Colors.white70
                                            : _textSub)),
                                if (isElite) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text('10% CASHBACK',
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: 0.5)),
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
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(plan.price,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: plan.priceColor)),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Floating badge top-right
          if (hasBadge)
            Positioned(
              right: 12,
              top: 2,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: plan.badgeColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(plan.badge!,
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
}

// ─── Rider Row ────────────────────────────────────────────────────────────────
class _RiderRow extends StatelessWidget {
  final _Rider rider;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _RiderRow(
      {required this.rider, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
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
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(rider.icon, color: _textSub, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(rider.name,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary)),
              const SizedBox(height: 2),
              Text(rider.price,
                  style: const TextStyle(fontSize: 12, color: _textHint)),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: _green,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ]),
    );
  }
}

// ─── Sticky Bottom Bar ────────────────────────────────────────────────────────
class _StickyBottomBar extends StatelessWidget {
  final int total;
  final VoidCallback onProceed;

  const _StickyBottomBar({required this.total, required this.onProceed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _borderLight)),
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
                text: '₹$total',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary),
              ),
              const TextSpan(
                text: '/week',
                style: TextStyle(fontSize: 13, color: _textSub),
              ),
            ]),
          ),
        ]),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: onProceed,
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Proceed to\nPayment',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.3),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded,
                      size: 18, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ─── Tab 3: History ───────────────────────────────────────────────────────────
class _HistoryTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const items = [
      ('Standard Shield', 'Mar 2025 – Mar 2026', '₹49/wk'),
      ('Basic Shield', 'Sep 2024 – Mar 2025', '₹29/wk'),
    ];
    return ListView(padding: const EdgeInsets.all(16), children: [
      _sectionLabel('POLICY HISTORY'),
      const SizedBox(height: 12),
      ...items.map((i) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _cardWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _borderLight),
            ),
            child: Row(children: [
              const Icon(Icons.shield_rounded, color: _green, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(i.$1,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary)),
                  const SizedBox(height: 2),
                  Text(i.$2,
                      style:
                          const TextStyle(fontSize: 12, color: _textHint)),
                ]),
              ),
              Text(i.$3,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _green)),
            ]),
          )),
    ]);
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
Widget _sectionLabel(String text) => Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: _textHint,
        letterSpacing: 1.0,
      ),
    );
