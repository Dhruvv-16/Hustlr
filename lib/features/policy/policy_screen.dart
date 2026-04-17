import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/router/app_router.dart';
import '../../shared/widgets/mobile_container.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/pdf_generator.dart';
import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../services/app_events.dart';
import '../../services/mock_data_service.dart';
import '../../services/storage_service.dart';
import 'package:provider/provider.dart';

// Dark mode palette
const _darkGreen       = Color(0xFF3FFF8B);
const _darkLightGreen  = Color(0xFF003D2A);
const _darkCardBg      = Color(0xFF1c1f1c);
const _darkTextPrimary = Colors.white;
const _darkTextSub     = Color(0xFF91938d);
const _darkBorder      = Color(0xFF2a2d2a);

// ─── Plan Data ────────────────────────────────────────────────────────────────
class _Plan {
  final String id;
  final String name;
  final String subtitle;
  final String price;
  final bool accentLeft;
  final bool isElite;
  final bool isMostPopular;

  const _Plan({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.price,
    this.accentLeft = false,
    this.isMostPopular = false,
    this.isElite = false,
  });
}

List<_Plan> _getPlans(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return [
    _Plan(id: 'basic',    name: l10n.policy_basic,    subtitle: 'Rain + extreme heat cover',             price: '₹35/wk', accentLeft: true),
    _Plan(id: 'standard', name: l10n.policy_standard, subtitle: 'Rain, heat, AQI, app downtime',         price: '₹49/wk', isMostPopular: true),
    _Plan(id: 'full',     name: l10n.policy_full,     subtitle: 'All 9 triggers + compound',             price: '₹79/wk'),
  ];
}

// ─── Rider Data ───────────────────────────────────────────────────────────────
class _Rider {
  final IconData icon;
  final String name;
  final String price;
  final bool defaultOn;

  const _Rider({required this.icon, required this.name, required this.price, required this.defaultOn});
}

const _riders = [
  _Rider(icon: Icons.cyclone_rounded,      name: 'Cyclone',         price: '+₹20/wk', defaultOn: false),
  _Rider(icon: Icons.groups_rounded,       name: 'Curfew & Strike', price: '+₹12/wk', defaultOn: false),
  _Rider(icon: Icons.how_to_vote_rounded,  name: 'Election Day',    price: '+₹8/wk', defaultOn: false),
  _Rider(icon: Icons.phonelink_off_rounded,name: 'App Downtime',    price: '+₹10/wk', defaultOn: true),
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
  Map<String, dynamic>? activePolicy;
  List<Map<String, dynamic>> policyHistory = [];
  bool isLoading = true;
  StreamSubscription<void>? _policySub;
  StreamSubscription<void>? _walletSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
    _loadPolicy();
    _policySub = AppEvents.instance.onPolicyUpdated.listen((_) => _loadPolicy());
    _walletSub = AppEvents.instance.onWalletUpdated.listen((_) => _loadPolicy());
  }

  Future<void> _loadPolicy() async {
    final uid = await StorageService.instance.getUserId();
    if (uid != null) {
      try {
        final data = await ApiService.instance.getPolicyInstance(uid);
        if (mounted) {
          final mock = context.read<MockDataService>();
          final rawPolicy = data['policy'];
          final rawHistory = data['history'];

          setState(() {
            // ── Demo Sync ───────────────────────────────────────────────────
            if (mock.worker.id.isNotEmpty && mock.hasActivePolicy) {
              activePolicy = {
                'id': 'PROTO-POL-${mock.worker.id.hashCode}',
                'plan_name': mock.activePolicy.plan,
                'plan_tier': mock.activePolicy.plan.split(' ')[0].toLowerCase(),
                'status': mock.activePolicy.status,
                'coverage_start': mock.activePolicy.coverageStart,
                'commitment_end': mock.activePolicy.coverageEnd,
                'weekly_premium': mock.activePolicy.premium,
              };
            } else {
              activePolicy = rawPolicy is Map<String, dynamic> ? rawPolicy : null;
            }

            policyHistory = rawHistory is List
                ? rawHistory
                    .whereType<Map>()
                    .map((e) => Map<String, dynamic>.from(e))
                    .toList()
                : [];
            isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => isLoading = false);
      }
    } else {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _policySub?.cancel();
    _walletSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n       = AppLocalizations.of(context)!;
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.dashboard),
        ),
        title: Text(
          l10n.policy_title,
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
              tabs: [
                Tab(text: 'Current Plan'),
                Tab(text: l10n.policy_upgrade),
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
              child: isLoading ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)) : TabBarView(
                controller: _tabController,
                children: [
                  _CurrentPlanTab(activePolicy: activePolicy),
                  _UpgradeTab(onProceed: () => context.push('/policy/payment'), activePolicy: activePolicy),
                  _LiveHistoryTab(
                    activePolicy: activePolicy,
                    policyHistory: policyHistory,
                  ),
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

class _LiveHistoryTab extends StatelessWidget {
  final Map<String, dynamic>? activePolicy;
  final List<Map<String, dynamic>> policyHistory;

  const _LiveHistoryTab({
    this.activePolicy,
    this.policyHistory = const [],
  });

  List<Map<String, dynamic>> _entries() {
    final items = <Map<String, dynamic>>[];
    final seen = <String>{};
    for (final item in policyHistory) {
      final id = item['id']?.toString() ?? '${item['plan_tier']}_${item['created_at']}';
      if (seen.add(id)) items.add(item);
    }
    if (items.isEmpty && activePolicy != null) {
      items.add(activePolicy!);
    }
    return items;
  }

  String _planLabel(Map<String, dynamic> item) {
    final tier = item['plan_tier']?.toString().trim();
    return (tier == null || tier.isEmpty) ? 'Shield Plan' : tier;
  }

  String _premiumLabel(Map<String, dynamic> item) {
    final raw = item['weekly_premium'];
    final amount = raw is num ? raw.round() : int.tryParse('${raw ?? ''}');
    return amount == null ? '—' : '₹$amount/wk';
  }

  String _dateRange(Map<String, dynamic> item) {
    final start = DateTime.tryParse(item['created_at']?.toString() ?? '');
    final end = DateTime.tryParse(item['expires_at']?.toString() ?? '');
    String fmt(DateTime? value) {
      if (value == null) return '—';
      return '${value.day} ${[
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][value.month - 1]} ${value.year}';
    }
    if (start != null && end != null) {
      return '${fmt(start)} - ${fmt(end)}';
    }
    return fmt(start);
  }

  @override
  Widget build(BuildContext context) {
    final items = _entries();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = theme.cardColor;
    final borderCol = isDark
        ? Colors.white.withOpacity(0.06)
        : const Color(0xFFE5E7EB);
    final green = theme.colorScheme.primary;
    final hintColor = theme.colorScheme.onSurface.withOpacity(0.4);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionLabel(context, 'POLICY HISTORY'),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No policy history yet',
                style: TextStyle(color: hintColor, fontSize: 13),
              ),
            ),
          )
        else
          ...items.map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderCol),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield_rounded, color: green, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _planLabel(item),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _dateRange(item),
                          style: TextStyle(fontSize: 12, color: hintColor),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _premiumLabel(item),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: green,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Tab 1: Current Plan ──────────────────────────────────────────────────────
class _CurrentPlanTab extends StatelessWidget {
  final Map<String, dynamic>? activePolicy;
  const _CurrentPlanTab({this.activePolicy});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel(context, 'ACTIVE COVERAGE'),
        const SizedBox(height: 12),
        _ActiveCoverageCard(activePolicy: activePolicy),
        const SizedBox(height: 24),
        _sectionLabel(context, 'COVERAGE DETAILS'),
        const SizedBox(height: 12),
        _coverageItem(context, Icons.water_drop_rounded,    'Rain Disruption',  'Auto-triggers when rain > 3hrs'),
        _coverageItem(context, Icons.wb_sunny_rounded,      'Extreme Heat',     'Triggers above 42°C advisory'),
        _coverageItem(context, Icons.air_rounded,           'Pollution Alert',  'AQI > 200 in your zone'),
        _coverageItem(context, Icons.phonelink_off_rounded, 'App Downtime',     'Outages over 90 minutes'),
        _coverageItem(context, Icons.edit_document,         'Manual Disruption Filing', 'Report untracked disruptions manually'),
        const SizedBox(height: 20),
        _policyDisclosureCard(context),
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
  final Map<String, dynamic>? activePolicy;
  const _ActiveCoverageCard({this.activePolicy});

  String _formatPolicyDates(Map<String, dynamic>? policy) {
    if (policy == null) return '—';
    final start = DateTime.tryParse(policy['created_at']?.toString() ?? '');
    final end = DateTime.tryParse(policy['expires_at']?.toString() ?? '');
    if (start == null || end == null) return '—';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${start.day} ${months[start.month - 1]} ${start.year} - ${end.day} ${months[end.month - 1]} ${end.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n   = AppLocalizations.of(context)!;
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
            child: Text(activePolicy?['plan_name'] ?? l10n.policy_standard, style: TextStyle(
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
        Text('Policy #${activePolicy?['id']?.toString().toUpperCase() ?? "—"}',
            style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.7))),
        const SizedBox(height: 12),
        Text('VALIDITY', style: TextStyle(
          fontSize: 10, fontWeight: FontWeight.w700,
          color: textColor.withOpacity(0.6), letterSpacing: 0.8)),
        const SizedBox(height: 4),
        Text(_formatPolicyDates(activePolicy),
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: _GhostButton(
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Generating official certificate...'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    backgroundColor: theme.colorScheme.primary,
                  ),
                );
                await PdfGenerator.generateAndPreviewCertificate();
              },
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
            onPressed: () async {
              await PdfGenerator.generateAndPreviewCertificate();
            },
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
  final Map<String, dynamic>? activePolicy;
  const _UpgradeTab({required this.onProceed, this.activePolicy});

  @override
  State<_UpgradeTab> createState() => _UpgradeTabState();
}

class _UpgradeTabState extends State<_UpgradeTab> {
  String? _selectedPlan;
  final Map<String, bool> _riderToggles = {
    'Curfew & Strike': false,
    'Election Day': false,
    'App Downtime': true,
    'Cyclone': false,
  };

  // ── helpers ──────────────────────────────────────────────────────────────
  static int _planBasePrice(String? planId) {
    if (planId == null) return 49;
    if (planId == 'full') return 79;
    if (planId == 'basic') return 35;
    return 49; // Standard Shield default
  }

  int get _totalCost {
    int total = _planBasePrice(_selectedPlan);

    const riderPrices = {
      'Cyclone': 20, 'Curfew & Strike': 12,
      'Election Day': 8, 'App Downtime': 10,
    };
    
    final bool allIncluded = _selectedPlan == 'full';

    if (!allIncluded) {
      for (final r in _riderToggles.entries) {
        if (r.key == 'App Downtime' && _selectedPlan == 'standard') continue;
        if (r.value) total += riderPrices[r.key] ?? 0;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Use hardcoded internal ID default
    _selectedPlan ??= 'standard';

    return Stack(children: [
      SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 200),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionLabel(context, 'ACTIVE COVERAGE'),
          const SizedBox(height: 12),
          _ActiveCoverageCard(activePolicy: widget.activePolicy),
          const SizedBox(height: 24),
          _sectionLabel(context, 'UPGRADE YOUR PROTECTION'),
          const SizedBox(height: 12),
          ..._getPlans(context).map((p) => _PlanCard(
                plan: p,
                isSelected: _selectedPlan == p.id,
                onTap: () => setState(() {
                  _selectedPlan = p.id;
                  if (_selectedPlan == 'basic') {
                    _riderToggles['App Downtime'] = false;
                  } else if (_selectedPlan == 'standard') {
                    _riderToggles['App Downtime'] = true;
                  }
                }),
              )),
          const SizedBox(height: 20),
          Row(children: [
            _sectionLabel(context, 'INCOME ADD-ONS'),
          ]),
          const SizedBox(height: 12),
          ..._riders.map((r) {
            final bool allIncluded = (_selectedPlan == 'full');
            final bool thisIncluded = allIncluded || (_selectedPlan == 'standard' && r.name == 'App Downtime');
            return _RiderRow(
              rider: r,
              value: _riderToggles[r.name] ?? r.defaultOn,
              isIncluded: thisIncluded,
              onChanged: thisIncluded ? null : (v) => setState(() => _riderToggles[r.name] = v),
            );
          }),
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
                _ruleText(context, 'Manual Disruption Filing', 'For disruptions not covered by automated triggers, you can manually report it within 24 hours via the Claims screen. Subject to evidence review.'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _policyDisclosureCard(context),
        ]),
      ),
      Positioned(
        left: 0, right: 0, bottom: 0,
        child: _StickyBottomBar(
          total: _totalCost,
          activePolicy: widget.activePolicy,
          selectedPlan: _selectedPlan,
          onProceed: () {
            final riderPrices = {'Cyclone': 20, 'Curfew & Strike': 12, 'Election Day': 8, 'App Downtime': 10};
            final plans = _getPlans(context);
            final selectedPlanObj = plans.firstWhere((p) => p.id == _selectedPlan, orElse: () => plans[1]);
            final planName = selectedPlanObj.name;
            final planCost = _planBasePrice(_selectedPlan);
            final bool allIncluded = _selectedPlan == 'full';

            List<Map<String, dynamic>> activeRiders = [];
            if (!allIncluded) {
              for (final r in _riderToggles.entries) {
                if (r.key == 'App Downtime' && _selectedPlan == 'standard') continue;
                if (r.value) {
                  activeRiders.add({
                    'name': '${r.key} Rider',
                    'cost': riderPrices[r.key] ?? 0
                  });
                }
              }
            }

            context.push('/policy/payment', extra: <String, dynamic>{
              'plan': planName,
              'planCost': planCost,
              'total': _totalCost,
              'riders': activeRiders
            });
          }
        ),
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
      behavior: HitTestBehavior.opaque,
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
  final ValueChanged<bool>? onChanged;
  final bool isIncluded;

  const _RiderRow({required this.rider, required this.value, this.onChanged, this.isIncluded = false});

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

    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isIncluded ? theme.colorScheme.primary.withOpacity(0.3) : borderCol),
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
              color: isIncluded ? theme.colorScheme.primary : theme.colorScheme.onSurface)),
            const SizedBox(height: 2),
            Text(isIncluded ? 'Included in Plan' : rider.price, style: TextStyle(
              fontSize: 12, 
              color: isIncluded ? theme.colorScheme.primary : subColor,
              fontWeight: isIncluded ? FontWeight.w700 : FontWeight.normal,
            )),
          ]),
        ),
        const SizedBox(width: 10),
        Switch(
          value: isIncluded ? true : value,
          onChanged: isIncluded ? null : onChanged,
          activeThumbColor: theme.colorScheme.primary,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ]),
    ));
  }
}

// ─── Sticky Bottom Bar ────────────────────────────────────────────────────────
class _StickyBottomBar extends StatelessWidget {
  final int total;
  final VoidCallback onProceed;
  final Map<String, dynamic>? activePolicy;
  final String? selectedPlan;

  const _StickyBottomBar({required this.total, required this.onProceed, this.activePolicy, this.selectedPlan});

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

    int getRank(String? p) {
      if (p == null) return 0;
      final lower = p.toLowerCase();
      if (lower.contains('full')) return 3;
      if (lower.contains('standard')) return 2;
      if (lower.contains('basic')) return 1;
      return 0;
    }
    
    final currentRank = getRank(
      (activePolicy?['plan_name'] ?? activePolicy?['plan_tier']) as String?,
    );
    final selectedRank = getRank(selectedPlan);

    final bool isDowngrade = selectedRank < currentRank && currentRank > 0;
    final bool isSame = selectedRank == currentRank && currentRank > 0;
    final bool isDisabled = isDowngrade || isSame;

    String btnText = 'Proceed to\nPayment';
    IconData btnIcon = Icons.arrow_forward_rounded;
    if (isSame) {
      btnText = 'Already Active';
      btnIcon = Icons.check_circle_rounded;
    } else if (isDowngrade) {
      btnText = 'Downgrade\nUnavailable';
      btnIcon = Icons.block_rounded;
    }

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
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('WEEKLY PREMIUM',
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
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: (isDisabled || activePolicy != null) ? null : onProceed,
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
                  Text(activePolicy != null ? 'PLAN ACTIVE' : btnText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold,
                          color: (isDisabled || activePolicy != null) ? btnTextColor.withOpacity(0.5) : btnTextColor, height: 1.3)),
                  const SizedBox(width: 8),
                  Icon(activePolicy != null ? Icons.check_circle_rounded : btnIcon, 
                      size: 18, color: (isDisabled || activePolicy != null) ? btnTextColor.withOpacity(0.5) : btnTextColor),
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
      ('Basic Shield',    'Sep 2024 – Mar 2025', '₹35/wk'),
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

/// Regulatory / IRDAI disclosure; opens [InsuranceComplianceScreen].
Widget _policyDisclosureCard(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final green = theme.colorScheme.primary;
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () => context.push(AppRoutes.insuranceCompliance),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF004734) : const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: green.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.verified_user_rounded, color: green, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Insurance & data disclosure',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'IRDAI norms, DPDP, triggers & payouts — tap to read',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: green, size: 16),
          ],
        ),
      ),
    ),
  );
}

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
