import 'package:flutter/material.dart';
import '../../shared/widgets/mobile_container.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/hustlr_bottom_nav.dart';

// ─── Plan Data ────────────────────────────────────────────────────────────────
class _Plan {
  final String name;
  final String subtitle;
  final String price;
  final bool accentLeft;
  final bool isElite;
  final bool isMostPopular;

  const _Plan({
    required this.name,
    required this.subtitle,
    required this.price,
    this.accentLeft = false,
    this.isElite = false,
    this.isMostPopular = false,
  });
}

const _plans = [
  _Plan(name: 'Basic Shield',    subtitle: 'Rain + extreme heat cover',             price: '₹29/wk', accentLeft: true),
  _Plan(name: 'Standard Shield', subtitle: 'Rain, heat, pollution, app downtime',   price: '₹49/wk', isMostPopular: true),
  _Plan(name: 'Full Shield',     subtitle: 'All disruption types covered',          price: '₹79/wk'),
  _Plan(name: 'Elite Shield',    subtitle: 'All types + compound triggers',         price: '₹109/wk', isElite: true),
];

// ─── Rider Data ───────────────────────────────────────────────────────────────
class _Rider {
  final IconData icon;
  final String name;
  final String price;
  final bool defaultOn;

  const _Rider({required this.icon, required this.name, required this.price, required this.defaultOn});
}

const _riders = [
  _Rider(icon: Icons.groups_rounded,       name: 'Curfew & Strike', price: '+₹15/week', defaultOn: false),
  _Rider(icon: Icons.how_to_vote_rounded,  name: 'Election Day',    price: '+₹20/week', defaultOn: false),
  _Rider(icon: Icons.phonelink_off_rounded,name: 'App Downtime',    price: '+₹12/week', defaultOn: true),
  _Rider(icon: Icons.cyclone_rounded,      name: 'Cyclone',         price: '+₹25/week', defaultOn: false),
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
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme      = Theme.of(context);
    final isDark     = theme.brightness == Brightness.dark;
    final bgColor    = theme.scaffoldBackgroundColor;
    final appBarBg   = isDark ? const Color(0xFF141614) : Colors.white;
    final green      = theme.colorScheme.primary;
    final textSub    = theme.colorScheme.onSurface.withOpacity(0.5);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: appBarBg,
        elevation: 0,
        leading: BackButton(color: theme.colorScheme.onSurface),
        title: Text(
          'Policy & Plans',
          style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
            color: appBarBg,
            child: TabBar(
              controller: _tabController,
              labelColor: green,
              unselectedLabelColor: textSub,
              labelStyle:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              unselectedLabelStyle:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
}

// ─── Tab 1: Current Plan ──────────────────────────────────────────────────────
class _CurrentPlanTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel(context, 'ACTIVE COVERAGE'),
        const SizedBox(height: 12),
        _ActiveCoverageCard(),
        const SizedBox(height: 24),
        _sectionLabel(context, 'COVERAGE DETAILS'),
        const SizedBox(height: 12),
        _coverageItem(context, Icons.water_drop_rounded,    'Rain Disruption',  'Auto-triggers when rain > 3hrs'),
        _coverageItem(context, Icons.wb_sunny_rounded,      'Extreme Heat',     'Triggers above 42°C advisory'),
        _coverageItem(context, Icons.air_rounded,           'Pollution Alert',  'AQI > 200 in your zone'),
        _coverageItem(context, Icons.phonelink_off_rounded, 'App Downtime',     'Outages over 90 minutes'),
      ]),
    );
  }
}

// Standalone helper so context is always from a build method
Widget _coverageItem(BuildContext context, IconData icon, String title, String subtitle) {
  final theme     = Theme.of(context);
  final isDark    = theme.brightness == Brightness.dark;
  final cardBg    = theme.cardColor;
  final borderCol = isDark
      ? Colors.white.withOpacity(0.06)
      : const Color(0xFFE5E7EB);
  final iconBg    = isDark ? const Color(0xFF004734) : const Color(0xFFE8F5E9);
  final green     = theme.colorScheme.primary;
  final subColor  = theme.colorScheme.onSurface.withOpacity(0.5);

  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: cardBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: borderCol),
    ),
    child: Row(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: green, size: 18),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 12, color: subColor)),
        ]),
      ),
      Icon(Icons.check_circle_rounded, color: green, size: 20),
    ]),
  );
}

// ─── Active Coverage Card ─────────────────────────────────────────────────────
class _ActiveCoverageCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // In dark mode use a tonal surface + mint; in light, solid green
    final cardBg    = isDark ? const Color(0xFF004734) : const Color(0xFF1B5E20);
    final textColor = isDark ? const Color(0xFF3FFF8B) : Colors.white;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text('Standard Shield', style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
          ),
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.verified_rounded, color: textColor, size: 22),
          ),
        ]),
        const SizedBox(height: 4),
        Text('Policy #HS-98234-AX',
            style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.7))),
        const SizedBox(height: 12),
        Text('VALIDITY', style: TextStyle(
          fontSize: 10, fontWeight: FontWeight.w700,
          color: textColor.withOpacity(0.6), letterSpacing: 0.8)),
        const SizedBox(height: 4),
        Text('26 Oct 2025 - 25 Oct 2026',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: _GhostButton(
              onPressed: () {},
              textColor: textColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.download_rounded, size: 15, color: textColor),
                  const SizedBox(width: 6),
                  Text('Download Certificate',
                      style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          _GhostButton(
            onPressed: () {},
            textColor: textColor,
            width: 44, height: 40,
            child: Icon(Icons.share_rounded, color: textColor, size: 18),
          ),
        ]),
      ]),
    );
  }
}

class _GhostButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color textColor;
  final double? width;
  final double height;

  const _GhostButton({
    required this.onPressed,
    required this.child,
    required this.textColor,
    this.width,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: width, height: height,
        padding: width == null
            ? const EdgeInsets.symmetric(horizontal: 12)
            : EdgeInsets.zero,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: textColor.withOpacity(0.5)),
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
      'Basic Shield': 29, 'Standard Shield': 49,
      'Full Shield': 79,  'Elite Shield': 109,
    };
    const riderPrices = {
      'Curfew & Strike': 15, 'Election Day': 20,
      'App Downtime': 12,    'Cyclone': 25,
    };
    int total = planPrices[_selectedPlan] ?? 49;
    for (final r in _riderToggles.entries) {
      if (r.value) total += riderPrices[r.key] ?? 0;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final green  = theme.colorScheme.primary;
    final lightGreen = isDark ? const Color(0xFF004734) : const Color(0xFFE8F5E9);
    final textSub = theme.colorScheme.onSurface.withOpacity(0.5);

    return Stack(children: [
      SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 200),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionLabel(context, 'ACTIVE COVERAGE'),
          const SizedBox(height: 12),
          _ActiveCoverageCard(),
          const SizedBox(height: 24),
          _sectionLabel(context, 'UPGRADE YOUR PROTECTION'),
          const SizedBox(height: 12),
          ..._plans.map((p) => _PlanCard(
                plan: p,
                isSelected: _selectedPlan == p.name,
                onTap: () => setState(() => _selectedPlan = p.name),
              )),
          const SizedBox(height: 20),
          Row(children: [
            _sectionLabel(context, 'INCOME ADD-ONS'),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: lightGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('Protects Earnings',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: green)),
            ),
          ]),
          const SizedBox(height: 12),
          ..._riders.map((r) => _RiderRow(
                rider: r,
                value: _riderToggles[r.name] ?? r.defaultOn,
                onChanged: (v) => setState(() => _riderToggles[r.name] = v),
              )),
          const SizedBox(height: 20),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: Text('Coverage Rules',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14,
                      color: theme.colorScheme.onSurface)),
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 16),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ruleText(context, '45-minute minimum', 'disruption must last 45 continuous minutes'),
                _ruleText(context, '24-hour cooling period', 'same trigger cannot fire again within 24 hours'),
                _ruleText(context, 'Shift overlap required', 'disruption must overlap shift by minimum 2 hours'),
                _ruleText(context, 'One event per week per type', 'Basic + Standard Shield only'),
                _ruleText(context, 'Post-activation only', 'events before activation never covered'),
              ],
            ),
          ),
        ]),
      ),
      Positioned(
        left: 0, right: 0, bottom: 96,
        child: _StickyBottomBar(total: _totalCost, onProceed: widget.onProceed),
      ),
    ]);
  }

  Widget _ruleText(BuildContext context, String title, String desc) {
    final theme   = Theme.of(context);
    final textSub = theme.colorScheme.onSurface.withOpacity(0.5);
    final textHint = theme.colorScheme.onSurface.withOpacity(0.35);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontSize: 14, color: textHint)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 12, color: textSub, height: 1.4),
                children: [
                  TextSpan(text: '$title — ',
                      style: TextStyle(fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface)),
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

  const _PlanCard({required this.plan, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final green  = theme.colorScheme.primary;
    final cardBg = plan.isElite
        ? (isDark ? const Color(0xFF2D1A00) : const Color(0xFFF57C00))
        : theme.cardColor;
    final borderCol = isSelected
        ? green
        : (isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE5E7EB));
    final textColor  = plan.isElite ? Colors.white : theme.colorScheme.onSurface;
    final subColor   = plan.isElite ? Colors.white70 : theme.colorScheme.onSurface.withOpacity(0.5);
    final priceColor = plan.isElite
        ? Colors.white
        : (isDark ? const Color(0xFF3FFF8B) : const Color(0xFF2E7D32));

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: EdgeInsets.only(bottom: 10, top: (plan.isMostPopular || plan.isElite) ? 10 : 0),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderCol, width: isSelected ? 2 : 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (plan.accentLeft)
                      Container(width: 3, color: green),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(plan.name, style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold,
                                  color: textColor)),
                                const SizedBox(height: 2),
                                Text(plan.subtitle, style: TextStyle(
                                  fontSize: 12, color: subColor)),
                                if (plan.isElite) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text('10% CASHBACK',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                                            color: Colors.white, letterSpacing: 0.5)),
                                  ),
                                  const SizedBox(height: 10),
                                  GestureDetector(
                                    onTap: () => context.push('/policy/compound'),
                                    child: const Text('Learn about compound triggers →',
                                        style: TextStyle(
                                          fontSize: 11, fontWeight: FontWeight.bold,
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
                          Text(plan.price, style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold,
                            color: priceColor)),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (plan.isMostPopular)
            Positioned(
              right: 12, top: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00695C),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('MOST POPULAR',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                        color: Colors.white, letterSpacing: 0.3)),
              ),
            ),
          if (plan.isElite)
            Positioned(
              right: 12, top: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE65100),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('★ BEST VALUE',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                        color: Colors.white, letterSpacing: 0.3)),
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

  const _RiderRow({required this.rider, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final isDark   = theme.brightness == Brightness.dark;
    final cardBg   = theme.cardColor;
    final borderCol = isDark
        ? Colors.white.withOpacity(0.06)
        : const Color(0xFFE5E7EB);
    final iconBg   = isDark ? const Color(0xFF2A2D2A) : const Color(0xFFF3F4F6);
    final subColor = theme.colorScheme.onSurface.withOpacity(0.4);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderCol),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
          child: Icon(rider.icon, color: theme.colorScheme.onSurface.withOpacity(0.6), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(rider.name, style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface)),
            const SizedBox(height: 2),
            Text(rider.price, style: TextStyle(fontSize: 12, color: subColor)),
          ]),
        ),
        const SizedBox(width: 10),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: theme.colorScheme.primary,
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
    final theme    = Theme.of(context);
    final isDark   = theme.brightness == Brightness.dark;
    final barBg    = isDark ? const Color(0xFF141614) : Colors.white;
    final borderCol = isDark
        ? Colors.white.withOpacity(0.08)
        : const Color(0xFFE5E7EB);
    final hintColor = theme.colorScheme.onSurface.withOpacity(0.4);
    final green     = theme.colorScheme.primary;
    // dark-mode: mint text on dark bg; light-mode: white text on green bg
    final btnTextColor = isDark ? const Color(0xFF0A0B0A) : Colors.white;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: barBg,
        border: Border(top: BorderSide(color: borderCol)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('TOTAL WEEKLY COST',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                  color: hintColor, letterSpacing: 0.5)),
          const SizedBox(height: 2),
          RichText(
            text: TextSpan(children: [
              TextSpan(
                text: '₹$total',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface),
              ),
              TextSpan(
                text: '/week',
                style: TextStyle(fontSize: 13, color: hintColor),
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
                backgroundColor: green,
                foregroundColor: btnTextColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Proceed to\nPayment',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold,
                          color: btnTextColor, height: 1.3)),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18, color: btnTextColor),
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
      ('Basic Shield',    'Sep 2024 – Mar 2025', '₹29/wk'),
    ];
    final theme    = Theme.of(context);
    final isDark   = theme.brightness == Brightness.dark;
    final cardBg   = theme.cardColor;
    final borderCol = isDark
        ? Colors.white.withOpacity(0.06)
        : const Color(0xFFE5E7EB);
    final green    = theme.colorScheme.primary;
    final hintColor = theme.colorScheme.onSurface.withOpacity(0.4);

    return ListView(padding: const EdgeInsets.all(16), children: [
      _sectionLabel(context, 'POLICY HISTORY'),
      const SizedBox(height: 12),
      ...items.map((i) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderCol),
            ),
            child: Row(children: [
              Icon(Icons.shield_rounded, color: green, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(i.$1, style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 2),
                  Text(i.$2, style: TextStyle(fontSize: 12, color: hintColor)),
                ]),
              ),
              Text(i.$3, style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: green)),
            ]),
          )),
    ]);
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
Widget _sectionLabel(BuildContext context, String text) {
  final hintColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.4);
  return Text(
    text,
    style: TextStyle(
      fontSize: 11, fontWeight: FontWeight.w700,
      color: hintColor, letterSpacing: 1.0,
    ),
  );
}
