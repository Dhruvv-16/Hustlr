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

String _normalizePlanTier(dynamic raw) {
  final s = raw?.toString().toLowerCase().trim() ?? '';
  if (s.contains('full')) return 'full';
  if (s.contains('basic')) return 'basic';
  return 'standard';
}

int _planBasePremium(String tier) {
  if (tier == 'full') return 79;
  if (tier == 'basic') return 35;
  return 49;
}

int _planWeeklyPayoutCap(String tier) {
  if (tier == 'full') return 500;
  if (tier == 'basic') return 210;
  return 340;
}

int _planDailyPayoutCap(String tier) {
  if (tier == 'full') return 250;
  if (tier == 'basic') return 100;
  return 150;
}

int? _asPositiveInt(dynamic raw) {
  if (raw == null) return null;
  final value = raw is num ? raw.toInt() : int.tryParse(raw.toString());
  if (value == null || value <= 0) return null;
  // If backend accidentally sends paise-like values, normalize to rupees.
  if (value >= 10000) return (value / 100).round();
  return value;
}

int _resolveWeeklyCap(Map<String, dynamic>? policy, String tier) {
  final fromPolicy = _asPositiveInt(
      policy?['max_weekly_payout'] ?? policy?['max_weekly_payout_paise']);
  return fromPolicy ?? _planWeeklyPayoutCap(tier);
}

int _resolveDailyCap(Map<String, dynamic>? policy, String tier) {
  final fromPolicy = _asPositiveInt(
      policy?['max_daily_payout'] ?? policy?['max_daily_payout_paise']);
  return fromPolicy ?? _planDailyPayoutCap(tier);
}

List<String> _coverageTitlesForPolicy(Map<String, dynamic>? policy) {
  final tier = _normalizePlanTier(policy?['plan_tier'] ?? policy?['plan_name']);
  final titles = <String>[];

  void add(String name) {
    if (!titles.contains(name)) titles.add(name);
  }

  add('Heavy Rain');
  add('Extreme Heat');

  if (tier == 'standard' || tier == 'full') {
    add('Severe AQI');
    add('Platform Downtime');
    add('Bandh / Curfew');
  }

  if (tier == 'full') {
    add('Internet Blackout');
    add('Traffic Congestion');
    add('Cyclone Landfall');
  }

  final riders = policy?['riders'] as List<dynamic>?;
  if (riders != null) {
    for (final rider in riders) {
      if (rider is! Map) continue;
      final mapped = _coverageFromRiderName(rider['name']?.toString() ?? '');
      final title = mapped?['title']?.toString();
      if (title != null && title.isNotEmpty) add(title);
    }
  }

  return titles;
}

int _riderCostFromName(String riderName) {
  final n = riderName.toLowerCase();
  if (n.contains('cyclone')) return 20;
  if (n.contains('curfew') || n.contains('strike')) return 12;
  if (n.contains('election')) return 8;
  if (n.contains('app downtime') || n.contains('downtime')) return 10;
  return 0;
}

bool _isRiderIncludedInPlan(String tier, String riderName) {
  final n = riderName.toLowerCase();
  if (tier == 'full') return true;
  if (tier == 'standard' && (n.contains('app downtime') || n.contains('downtime'))) {
    return true;
  }
  return false;
}

int _billableRiderTotal(String tier, List<dynamic>? riders) {
  if (riders == null || riders.isEmpty) return 0;

  var total = 0;
  for (final r in riders) {
    if (r is! Map) continue;
    final name = r['name']?.toString() ?? '';
    if (name.isEmpty || _isRiderIncludedInPlan(tier, name)) continue;

    final explicitCost = (r['cost'] as num?)?.toInt();
    final resolvedCost = (explicitCost != null && explicitCost > 0)
        ? explicitCost
        : _riderCostFromName(name);
    total += resolvedCost;
  }
  return total;
}

int _billableRiderCount(String tier, List<dynamic>? riders) {
  if (riders == null || riders.isEmpty) return 0;

  var count = 0;
  for (final r in riders) {
    if (r is! Map) continue;
    final name = r['name']?.toString() ?? '';
    if (name.isEmpty || _isRiderIncludedInPlan(tier, name)) continue;

    final explicitCost = (r['cost'] as num?)?.toInt();
    final resolvedCost = (explicitCost != null && explicitCost > 0)
        ? explicitCost
        : _riderCostFromName(name);
    if (resolvedCost > 0) count++;
  }
  return count;
}

int _effectiveWeeklyPremiumFromPolicy(Map<String, dynamic> item) {
  final tier = _normalizePlanTier(item['plan_tier'] ?? item['plan_name']);
  final base = _planBasePremium(tier);
  final riders = item['riders'] as List<dynamic>?;
  final computed = base + _billableRiderTotal(tier, riders);

  final raw = item['weekly_premium'];
  final stored = raw is num ? raw.toDouble() : double.tryParse('${raw ?? ''}');

  if (stored != null && stored >= computed && stored <= 200) {
    return stored.round();
  }
  return computed;
}

Map<String, dynamic>? _coverageFromRiderName(String riderName) {
  final n = riderName.toLowerCase();
  if (n.contains('cyclone')) {
    return {
      'key': 'cyclone',
      'icon': Icons.cyclone_rounded,
      'title': 'Cyclone Coverage',
      'subtitle': 'Severe cyclone warnings',
    };
  }
  if (n.contains('curfew') || n.contains('strike')) {
    return {
      'key': 'curfew',
      'icon': Icons.groups_rounded,
      'title': 'Curfew & Strikes',
      'subtitle': 'Work stoppages covered',
    };
  }
  if (n.contains('election')) {
    return {
      'key': 'election',
      'icon': Icons.how_to_vote_rounded,
      'title': 'Election Day Coverage',
      'subtitle': 'Poll-related closures',
    };
  }
  if (n.contains('app downtime') || n.contains('downtime')) {
    return {
      'key': 'downtime',
      'icon': Icons.phonelink_off_rounded,
      'title': 'App Downtime',
      'subtitle': 'Outages over 90 minutes',
    };
  }
  return null;
}

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
  bool _isLoadingPolicy = false;  // Prevent concurrent loads
  DateTime? _lastLoadTime;  // Debounce rapid successive loads
  static const _loadDebounceMs = 1500;  // Minimum 1.5s between loads

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
    _loadPolicy();
    // Use debounced listeners to prevent rapid successive reloads
    _policySub = AppEvents.instance.onPolicyUpdated.listen((_) => _debouncedLoad());
    _walletSub = AppEvents.instance.onWalletUpdated.listen((_) => _debouncedLoad());
  }

  /// Debounced version of _loadPolicy to prevent excessive API calls from event spam
  Future<void> _debouncedLoad() async {
    final now = DateTime.now();
    if (_lastLoadTime != null && now.difference(_lastLoadTime!).inMilliseconds < _loadDebounceMs) {
      // Skip if called within debounce window
      return;
    }
    _lastLoadTime = now;
    await _loadPolicy();
  }

  Future<void> _loadPolicy() async {
    // Prevent concurrent loads to avoid race conditions and duplicate API calls
    if (_isLoadingPolicy) return;
    
    _isLoadingPolicy = true;
    try {
      final uid = await StorageService.instance.getUserId();
      if (uid != null) {
        try {
          final data = await ApiService.instance.getPolicyInstance(uid);
          if (mounted) {
            final mock = context.read<MockDataService>();
            final rawPolicy = data['policy'];
            final rawHistory = data['history'];
            final wasInactive = activePolicy == null;

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
              
              // If policy was just purchased, switch to "Current Plan" tab
              if (wasInactive && activePolicy != null) {
                Future.microtask(() {
                  _tabController.animateTo(0);
                });
              }
            });
          }
        } catch (e) {
          if (mounted) setState(() => isLoading = false);
        }
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } finally {
      _isLoadingPolicy = false;
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
    
    // Add active policy first if it exists and status is active/renewed
    if (activePolicy != null) {
      final status = activePolicy!['status']?.toString().toLowerCase() ?? '';
      if (status == 'active' || status == 'renewed') {
        final id = activePolicy!['id']?.toString() ?? 'active_policy';
        if (seen.add(id)) {
          items.add(activePolicy!);
        }
      }
    }
    
    // Add historical entries
    for (final item in policyHistory) {
      final id = item['id']?.toString() ?? '${item['plan_tier']}_${item['created_at']}';
      if (seen.add(id)) items.add(item);
    }
    
    return items;
  }

  String _planLabel(Map<String, dynamic> item) {
    final tier = item['plan_tier']?.toString().trim();
    return (tier == null || tier.isEmpty) ? 'Shield Plan' : tier;
  }

  String _premiumLabel(Map<String, dynamic> item) {
    final amount = _effectiveWeeklyPremiumFromPolicy(item);
    return '₹$amount/wk';
  }

  String _dateRange(Map<String, dynamic> item) {
    final start = DateTime.tryParse(item['created_at']?.toString() ?? '') ?? DateTime.now();
    final end = DateTime.tryParse(item['expires_at']?.toString() ?? '') ?? start.add(const Duration(days: 7));
    String fmt(DateTime value) {
      return '${value.day} ${[
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][value.month - 1]} ${value.year}';
    }
    return '${fmt(start)} - ${fmt(end)}';
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
                          _planLabel(item).toUpperCase(),
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
class _CurrentPlanTab extends StatefulWidget {
  final Map<String, dynamic>? activePolicy;
  const _CurrentPlanTab({this.activePolicy});

  @override
  State<_CurrentPlanTab> createState() => _CurrentPlanTabState();
}

class _CurrentPlanTabState extends State<_CurrentPlanTab> {
  bool? _coverageExpanded;
  bool? _lastCompact;

  /// Return coverage items based on plan tier
  List<Map<String, dynamic>> _getCoverageItems() {
    final tier = _normalizePlanTier(
        widget.activePolicy?['plan_tier'] ?? widget.activePolicy?['plan_name']);
    final riders = widget.activePolicy?['riders'] as List<dynamic>?;
    final items = <Map<String, dynamic>>[];
    final addedKeys = <String>{};

    void addCoverage({
      required String key,
      required IconData icon,
      required String title,
      required String subtitle,
    }) {
      if (!addedKeys.add(key)) return;
      items.add({
        'icon': icon,
        'title': title,
        'subtitle': subtitle,
      });
    }
    
    // All tiers include Rain & Heat
    addCoverage(
      key: 'rain',
      icon: Icons.water_drop_rounded,
      title: 'Rain Disruption',
      subtitle: 'Auto-triggers when rain > 3hrs',
    );
    addCoverage(
      key: 'heat',
      icon: Icons.wb_sunny_rounded,
      title: 'Extreme Heat',
      subtitle: 'Triggers above 42°C advisory',
    );
    
    // Standard & Full include Pollution Alert
    if (tier == 'standard' || tier == 'full') {
      addCoverage(
        key: 'pollution',
        icon: Icons.air_rounded,
        title: 'Pollution Alert',
        subtitle: 'AQI > 200 in your zone',
      );
    }
    
    // Standard & Full include App Downtime
    if (tier == 'standard' || tier == 'full') {
      addCoverage(
        key: 'downtime',
        icon: Icons.phonelink_off_rounded,
        title: 'App Downtime',
        subtitle: 'Outages over 90 minutes',
      );
    }

    // Standard & Full include bandh/curfew disruption coverage
    if (tier == 'standard' || tier == 'full') {
      addCoverage(
        key: 'bandh',
        icon: Icons.gavel_rounded,
        title: 'Bandh & Curfew Alerts',
        subtitle: 'City shutdown and route restrictions',
      );
    }
    
    // Full Shield includes all advanced triggers (all 9 + compound)
    if (tier == 'full') {
      addCoverage(
        key: 'internet_blackout',
        icon: Icons.signal_wifi_statusbar_connected_no_internet_4_rounded,
        title: 'Internet Zone Blackout',
        subtitle: 'Network blackout in your delivery zone',
      );
      addCoverage(
        key: 'dark_store',
        icon: Icons.store_mall_directory_rounded,
        title: 'Dark Store Closure',
        subtitle: 'Store-side shutdown or dispatch halt',
      );
      addCoverage(
        key: 'accident_blockspot',
        icon: Icons.car_crash_rounded,
        title: 'Accident Blockspot',
        subtitle: 'Critical route blocked by major accident',
      );
      addCoverage(
        key: 'traffic_congestion',
        icon: Icons.traffic_rounded,
        title: 'Heavy Traffic Congestion',
        subtitle: 'Severe congestion sustained in zone',
      );
      addCoverage(
        key: 'compound',
        icon: Icons.call_split_rounded,
        title: 'Compound Disruptions',
        subtitle: 'Multiple triggers in same week',
      );
    }

    // Billable rider coverages: add only if selected and not already included by plan.
    if (riders != null) {
      for (final r in riders) {
        if (r is! Map) continue;
        final name = r['name']?.toString() ?? '';
        if (name.isEmpty || _isRiderIncludedInPlan(tier, name)) continue;
        final coverage = _coverageFromRiderName(name);
        if (coverage == null) continue;

        addCoverage(
          key: coverage['key'] as String,
          icon: coverage['icon'] as IconData,
          title: coverage['title'] as String,
          subtitle: coverage['subtitle'] as String,
        );
      }
    }
    
    // Manual Disruption Filing always included
    items.add({
      'icon': Icons.edit_document,
      'title': 'Manual Disruption Filing',
      'subtitle': 'Report untracked disruptions manually',
    });
    
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final coverageItems = _getCoverageItems();
    final isCompact = MediaQuery.of(context).size.width < 380;
    if (_coverageExpanded == null || _lastCompact != isCompact) {
      _coverageExpanded = !isCompact;
      _lastCompact = isCompact;
    }
    final headerTextColor = Theme.of(context).colorScheme.onSurface;
    final headerBorderColor = headerTextColor.withOpacity(0.18);
    final headerBg = Theme.of(context).cardColor.withOpacity(0.45);
    
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, isCompact ? 108 : 120),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel(context, 'ACTIVE COVERAGE'),
        SizedBox(height: isCompact ? 10 : 12),
        _ActiveCoverageCard(activePolicy: widget.activePolicy),
        SizedBox(height: isCompact ? 18 : 24),
        GestureDetector(
          onTap: () => setState(() => _coverageExpanded = !(_coverageExpanded ?? true)),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 10 : 12,
              vertical: isCompact ? 8 : 10,
            ),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: headerBorderColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'COVERAGE DETAILS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: headerTextColor,
                    ),
                  ),
                ),
                Text(
                  (_coverageExpanded ?? true) ? 'Hide' : 'View',
                  style: TextStyle(
                    fontSize: isCompact ? 11 : 12,
                    fontWeight: FontWeight.w700,
                    color: headerTextColor.withOpacity(0.85),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  (_coverageExpanded ?? true)
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: headerTextColor.withOpacity(0.9),
                  size: isCompact ? 18 : 20,
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: EdgeInsets.only(top: isCompact ? 8 : 12),
            child: Column(
              children: coverageItems
                  .map((item) => _coverageItem(
                        context,
                        item['icon'] as IconData,
                        item['title'] as String,
                        item['subtitle'] as String,
                        isCompact: isCompact,
                      ))
                  .toList(),
            ),
          ),
          crossFadeState: (_coverageExpanded ?? true)
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
        ),
        SizedBox(height: isCompact ? 16 : 20),
        _policyDisclosureCard(context),
      ]),
    );
  }
}

// Standalone helper so context is always from a build method
Widget _coverageItem(BuildContext context, IconData icon, String title,
    String subtitle,
    {bool isCompact = false}) {
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
    margin: EdgeInsets.only(bottom: isCompact ? 8 : 10),
    padding: EdgeInsets.all(isCompact ? 12 : 14),
    decoration: BoxDecoration(
      color: cardBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: borderCol),
    ),
    child: Row(children: [
      Container(
        width: isCompact ? 34 : 36,
        height: isCompact ? 34 : 36,
        decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: green, size: isCompact ? 16 : 18),
      ),
      SizedBox(width: isCompact ? 10 : 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(
            fontSize: isCompact ? 13 : 14, fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface)),
          const SizedBox(height: 2),
          Text(subtitle,
              style: TextStyle(fontSize: isCompact ? 11 : 12, color: subColor)),
        ]),
      ),
      Icon(Icons.check_circle_rounded,
          color: green, size: isCompact ? 18 : 20),
    ]),
  );
}

// ─── Active Coverage Card ─────────────────────────────────────────────────────
class _ActiveCoverageCard extends StatefulWidget {
  final Map<String, dynamic>? activePolicy;
  const _ActiveCoverageCard({this.activePolicy});

  @override
  State<_ActiveCoverageCard> createState() => _ActiveCoverageCardState();
}

class _ActiveCoverageCardState extends State<_ActiveCoverageCard> {
  bool? _detailsExpanded;
  bool? _lastCompact;

  String _formatPolicyDates(Map<String, dynamic>? policy) {
    if (policy == null) return '—';
    final start = DateTime.tryParse(policy['created_at']?.toString() ?? '') ?? DateTime.now();
    final end = DateTime.tryParse(policy['expires_at']?.toString() ?? '') ?? start.add(const Duration(days: 7));
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${start.day} ${months[start.month - 1]} ${start.year} - ${end.day} ${months[end.month - 1]} ${end.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n   = AppLocalizations.of(context)!;
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isCompact = MediaQuery.of(context).size.width < 380;
    if (_detailsExpanded == null || _lastCompact != isCompact) {
      _detailsExpanded = !isCompact;
      _lastCompact = isCompact;
    }
    final activePolicy = widget.activePolicy;
    final tier = _normalizePlanTier(activePolicy?['plan_tier'] ?? activePolicy?['plan_name']);
    final riders = activePolicy?['riders'] as List<dynamic>?;
    final weeklyPremium = activePolicy == null
        ? _planBasePremium('standard')
        : _effectiveWeeklyPremiumFromPolicy(activePolicy!);
    final addonTotal = _billableRiderTotal(tier, riders);
    final addonCount = _billableRiderCount(tier, riders);
    final coverageTitles = _coverageTitlesForPolicy(activePolicy);
    final weeklyCap = _resolveWeeklyCap(activePolicy, tier);
    final dailyCap = _resolveDailyCap(activePolicy, tier);
    // In dark mode use a tonal surface + mint; in light, solid green
    final cardBg    = isDark ? const Color(0xFF004734) : const Color(0xFF1B5E20);
    final textColor = isDark ? const Color(0xFF3FFF8B) : Colors.white;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(activePolicy?['plan_name'] ?? l10n.policy_standard, style: TextStyle(
              fontSize: isCompact ? 18 : 20, fontWeight: FontWeight.bold, color: textColor)),
          ),
          Container(
            width: isCompact ? 36 : 40, height: isCompact ? 36 : 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.verified_rounded, color: textColor, size: isCompact ? 20 : 22),
          ),
        ]),
        const SizedBox(height: 4),
        Text('Policy #${activePolicy?['id']?.toString().toUpperCase() ?? "—"}',
            style: TextStyle(fontSize: isCompact ? 11 : 12, color: textColor.withOpacity(0.7))),
        SizedBox(height: isCompact ? 10 : 12),
        Text('VALIDITY', style: TextStyle(
          fontSize: 10, fontWeight: FontWeight.w700,
          color: textColor.withOpacity(0.6), letterSpacing: 0.8)),
        const SizedBox(height: 4),
        Text(_formatPolicyDates(activePolicy),
            style: TextStyle(fontSize: isCompact ? 13 : 14, fontWeight: FontWeight.bold, color: textColor)),
        SizedBox(height: isCompact ? 10 : 12),
        Text('WEEKLY PREMIUM', style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor.withOpacity(0.6),
          letterSpacing: 0.8,
        )),
        const SizedBox(height: 4),
        Text(
          '₹$weeklyPremium/week',
          style: TextStyle(
            fontSize: isCompact ? 16 : 18,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        if (addonTotal > 0 && addonCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'Includes $addonCount add-on${addonCount > 1 ? 's' : ''} (+₹$addonTotal/week)',
              style: TextStyle(
                fontSize: isCompact ? 10 : 11,
                fontWeight: FontWeight.w600,
                color: textColor.withOpacity(0.78),
              ),
            ),
          ),
        SizedBox(height: isCompact ? 10 : 14),
        GestureDetector(
          onTap: () => setState(() => _detailsExpanded = !(_detailsExpanded ?? true)),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 10 : 12,
              vertical: isCompact ? 8 : 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: textColor.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'POLICY DETAILS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: textColor.withOpacity(0.75),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Text(
                  (_detailsExpanded ?? true) ? 'Hide' : 'View',
                  style: TextStyle(
                    fontSize: isCompact ? 11 : 12,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  (_detailsExpanded ?? true)
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: textColor,
                  size: isCompact ? 18 : 20,
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: EdgeInsets.only(top: isCompact ? 8 : 10),
            child: Column(
              children: [
                _detailRow(
                  'Coverage Included',
                  coverageTitles.take(6).join(', '),
                  textColor,
                  compact: false,
                  isCompact: isCompact,
                ),
                _detailRow(
                  'Payout Split',
                  '70% instant + 30% after verification',
                  textColor,
                  isCompact: isCompact,
                ),
                _detailRow('Max Weekly Payout', '₹$weeklyCap', textColor,
                    isCompact: isCompact),
                _detailRow('Max Daily Payout', '₹$dailyCap', textColor,
                    isCompact: isCompact),
                _detailRow(
                  'Claim Processing',
                  'Auto processed by Sunday 11 PM',
                  textColor,
                  isCompact: isCompact,
                ),
              ],
            ),
          ),
          crossFadeState: (_detailsExpanded ?? true)
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
        ),
        SizedBox(height: isCompact ? 12 : 16),
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
                   Icon(Icons.download_rounded, size: isCompact ? 14 : 15, color: textColor),
                   const SizedBox(width: 6),
                   Text('Download Certificate',
                       style: TextStyle(fontSize: isCompact ? 12 : 13, color: textColor, fontWeight: FontWeight.w600)),
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

  Widget _detailRow(String label, String value, Color textColor,
      {bool compact = true, bool isCompact = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? (isCompact ? 5 : 6) : (isCompact ? 7 : 8)),
      child: Row(
        crossAxisAlignment:
            compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isCompact ? 10 : 11,
                fontWeight: FontWeight.w600,
                color: textColor.withOpacity(0.75),
              ),
            ),
          ),
          SizedBox(width: isCompact ? 10 : 12),
          Expanded(
            flex: 7,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: isCompact ? 11 : 12,
                fontWeight: FontWeight.w700,
                color: textColor,
                height: compact ? 1.2 : 1.35,
              ),
            ),
          ),
        ],
      ),
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

  List<Map<String, String>> _coverageRules() {
    final plan = _selectedPlan ?? 'standard';

    final rules = <Map<String, String>>[
      {
        'title': '45-minute minimum',
        'desc': 'disruption must last 45 continuous minutes',
      },
      {
        'title': '24-hour cooling period',
        'desc': 'same trigger cannot fire again within 24 hours',
      },
      {
        'title': 'Shift overlap required',
        'desc': 'disruption must overlap shift by minimum 2 hours',
      },
      {
        'title': 'Post-activation only',
        'desc': 'events before activation are never covered',
      },
    ];

    if (plan == 'full') {
      rules.add({
        'title': 'Multi-event coverage enabled',
        'desc': 'Full Shield supports multiple trigger payouts, including compound disruptions',
      });
    } else {
      rules.add({
        'title': 'One event per week per type',
        'desc': 'Basic and Standard allow one payout per trigger type each week',
      });
    }

    if (plan == 'basic') {
      rules.add({
        'title': 'Addon-dependent triggers',
        'desc': 'Downtime, Curfew, Election, and Cyclone triggers apply only when added',
      });
    }

    if (plan == 'standard') {
      rules.add({
        'title': 'Built-in App Downtime',
        'desc': 'App Downtime coverage is included by default in Standard Shield',
      });
    }

    if (plan != 'full') {
      final selectedAddons = _riderToggles.entries
          .where((e) {
            if (!e.value) return false;
            if (plan == 'standard' && e.key == 'App Downtime') return false;
            return true;
          })
          .map((e) => e.key)
          .toList();

      if (selectedAddons.isNotEmpty) {
        rules.add({
          'title': 'Selected add-ons active',
          'desc': selectedAddons.join(', '),
        });
      }
    }

    rules.add({
      'title': 'Manual Disruption Filing',
      'desc': 'For disruptions not covered by automated triggers, report within 24 hours via Claims. Subject to evidence review.',
    });

    return rules;
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
                ..._coverageRules().map((r) => _ruleText(
                      context,
                      r['title'] ?? '',
                      r['desc'] ?? '',
                    )),
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
          addonTotal: _totalCost - _planBasePrice(_selectedPlan),
          addonCount: (() {
            final bool allIncluded = _selectedPlan == 'full';
            if (allIncluded) return 0;
            int count = 0;
            for (final r in _riderToggles.entries) {
              if (r.key == 'App Downtime' && _selectedPlan == 'standard') continue;
              if (r.value) count++;
            }
            return count;
          })(),
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
              'planTier': _selectedPlan ?? 'standard',
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
  final int addonTotal;
  final int addonCount;
  final VoidCallback onProceed;
  final Map<String, dynamic>? activePolicy;
  final String? selectedPlan;

  const _StickyBottomBar({
    required this.total,
    required this.addonTotal,
    required this.addonCount,
    required this.onProceed,
    this.activePolicy,
    this.selectedPlan,
  });

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

    // Treat any present policy as active unless explicitly ended.
    // Some responses omit status but still represent a live policy.
    final status = activePolicy?['status']?.toString().toLowerCase() ?? '';
    final bool hasActivePolicy = activePolicy != null &&
      (status.isEmpty ||
        status == 'active' ||
        status == 'renewed' ||
        status == 'pending' ||
        status == 'suspended');
    final bool isDowngrade = selectedRank < currentRank && currentRank > 0;
    final bool isSame = selectedRank == currentRank && currentRank > 0;
    final bool isDisabled = isDowngrade || isSame || hasActivePolicy;

    String btnText = 'Proceed to\nPayment';
    IconData btnIcon = Icons.arrow_forward_rounded;
    if (hasActivePolicy) {
      btnText = 'ACTIVE PLAN';
      btnIcon = Icons.verified_user_rounded;
    } else if (isSame) {
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
            Text(hasActivePolicy ? 'CURRENT PLAN' : 'WEEKLY PREMIUM',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                    color: hintColor, letterSpacing: 0.5)),
            const SizedBox(height: 2),
            if (hasActivePolicy)
              Text(activePolicy!['plan_name']?.toString() ?? 'Hustlr Shield',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis)
            else ...[
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
              if (addonTotal > 0 && addonCount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Includes $addonCount add-on${addonCount > 1 ? 's' : ''} (+₹$addonTotal)',
                    style: TextStyle(
                      fontSize: 11,
                      color: hintColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ]),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: isDisabled ? null : onProceed,
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
                  Text(btnText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold,
                          color: isDisabled ? btnTextColor.withOpacity(0.5) : btnTextColor, height: 1.3)),
                  const SizedBox(width: 8),
                  Icon(btnIcon, 
                      size: 18, color: isDisabled ? btnTextColor.withOpacity(0.5) : btnTextColor),
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
