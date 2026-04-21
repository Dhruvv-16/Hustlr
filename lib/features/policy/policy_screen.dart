import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/pdf_generator.dart';
import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../services/app_events.dart';
import '../../services/storage_service.dart';
import '../../shared/widgets/mobile_container.dart';
import '../../shared/widgets/offline_banner.dart';
import '../../shared/widgets/animated_skeleton.dart';
import 'package:provider/provider.dart';
import '../../services/mock_data_service.dart';

// ─── Plan Data ────────────────────────────────────────────────────────────────
class _Plan {
  final String id;
  final String name;
  final String subtitle;
  final String price;
  final bool accentLeft;
  final bool isMostPopular;
  final bool isElite;

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
    _Plan(
      id: 'basic',
      name: l10n.policy_basic,
      subtitle: 'Rain + extreme heat cover',
      price: 'Rs.35/wk',
      accentLeft: true,
    ),
    _Plan(
      id: 'standard',
      name: l10n.policy_standard,
      subtitle: 'Everything in Basic + platform downtime + severe AQI',
      price: 'Rs.49/wk',
      accentLeft: true,
      isMostPopular: true,
    ),
    _Plan(
      id: 'full',
      name: l10n.policy_full,
      subtitle: 'Everything in Standard + bandh/curfew + internet blackout',      
      price: 'Rs.79/wk',
      accentLeft: true,
      isElite: true,
    ),
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
  _Rider(icon: Icons.groups_rounded,        name: 'Bandh / Curfew',    price: '+₹15/wk', defaultOn: false),
  _Rider(icon: Icons.wifi_off_rounded,      name: 'Internet Blackout', price: '+₹12/wk', defaultOn: false),
];

// ─── Helpers ──────────────────────────────────────────────────────────────────
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
  }

  if (tier == 'full') {
    add('Bandh / Curfew');
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
  if (n.contains('bandh') || n.contains('curfew') || n.contains('strike')) return 15;
  if (n.contains('internet') || n.contains('blackout')) return 12;
  return 0;
}

bool _isRiderIncludedInPlan(String tier, String riderName) {
  if (tier == 'full') return true;
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
  if (n.contains('bandh') || n.contains('curfew') || n.contains('strike')) {
    return {
      'key': 'curfew',
      'icon': Icons.groups_rounded,
      'title': 'Curfew & Strikes',
      'subtitle': 'Work stoppages covered',
    };
  }
  if (n.contains('internet') || n.contains('blackout')) {
    return {
      'key': 'blackout',
      'icon': Icons.wifi_off_rounded,
      'title': 'Internet Blackout',
      'subtitle': 'Connectivity disruption cover',
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
  bool _isLoadingPolicy = false;
  int _activeDays = 0;
  bool _isCheckingEligibility = true;
  DateTime? _lastLoadTime;
  static const _loadDebounceMs = 1500;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
    _loadPolicy();
    _policySub = AppEvents.instance.onPolicyUpdated.listen((_) => _loadPolicy());
    _walletSub = AppEvents.instance.onWalletUpdated.listen((_) => _loadPolicy());
  }

  Future<void> _loadPolicy() async {
    final now = DateTime.now();
    if (_lastLoadTime != null && now.difference(_lastLoadTime!).inMilliseconds < _loadDebounceMs) {
      return;
    }
    _lastLoadTime = now;

    if (_isLoadingPolicy) return;
    _isLoadingPolicy = true;
    try {
      final uid = await StorageService.instance.getUserId();
      if (uid != null) {
        final data = await ApiService.instance.getPolicy(uid);
        if (mounted) {
          final rawPolicy = data['policy'];
          final rawHistory = data['history'];
          final wasInactive = activePolicy == null;

          final mock = context.read<MockDataService>();
          var policyToUse = rawPolicy is Map<String, dynamic> ? rawPolicy : null;
          
          final isDemoUser = uid.startsWith('DEMO_') ||
              uid.startsWith('demo-') ||
              uid.startsWith('mock-') ||
              StorageService.getString('isDemoSession') == 'true';

          if (policyToUse == null && isDemoUser && mock.hasActivePolicy) {
            final tier = mock.activePolicy.plan.split(' ')[0].toLowerCase();
            policyToUse = {
              'id': 'MOCK-${uid.hashCode}',
              'plan_tier': tier,
              'plan_name': mock.activePolicy.plan,
              'status': 'active',
              'weekly_premium': mock.activePolicy.premium,
              'coverage_start': mock.activePolicy.coverageStart,
              'commitment_end': mock.activePolicy.coverageEnd,
              'riders': mock.activePolicy.riders.map((r) => {'name': r}).toList(),
              'created_at': mock.activePolicy.coverageStart,
            };
          }

          setState(() {
            activePolicy = policyToUse;
            policyHistory = rawHistory is List
                ? rawHistory.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
                : [];
            isLoading = false;
            if (wasInactive && activePolicy != null) {
              Future.microtask(() => _tabController.animateTo(0));
            }
          });

          try {
            final profile = await ApiService.instance.getWorkerById(uid);
            if (mounted) {
              setState(() {
                _activeDays = profile['active_days'] ?? 0;
                _isCheckingEligibility = false;
              });
            }
          } catch (_) {
            if (mounted) setState(() => _isCheckingEligibility = false);
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() {
        isLoading = false;
        _isCheckingEligibility = false;
      });
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final green = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF141614) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.dashboard),
        ),
        title: const Text('Hustlr Shield', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: green,
          unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          indicatorColor: green,
          tabs: const [
            Tab(text: 'Current Plan'),
            Tab(text: 'Upgrade'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: MobileContainer(
              child: isLoading 
                  ? _buildPolicySkeleton() 
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _CurrentPlanTab(activePolicy: activePolicy),
                        _UpgradeTab(
                          onProceed: () => context.push(AppRoutes.checkout, extra: {'amount': 79.0, 'planName': 'Full Shield'}),
                          activePolicy: activePolicy,
                          activeDays: _activeDays,
                        ),
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

  Widget _buildPolicySkeleton() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          AnimatedSkeleton(height: 140, width: double.infinity, borderRadius: 16),
          SizedBox(height: 24),
          AnimatedSkeleton(height: 24, width: 120, borderRadius: 6),
          SizedBox(height: 16),
          AnimatedSkeleton(height: 80, width: double.infinity, borderRadius: 12),
          SizedBox(height: 12),
          AnimatedSkeleton(height: 80, width: double.infinity, borderRadius: 12),
        ],
      ),
    );
  }
}

// ─── Current Plan Tab ────────────────────────────────────────────────────────
class _CurrentPlanTab extends StatefulWidget {
  final Map<String, dynamic>? activePolicy;
  const _CurrentPlanTab({this.activePolicy});

  @override
  State<_CurrentPlanTab> createState() => _CurrentPlanTabState();
}

class _CurrentPlanTabState extends State<_CurrentPlanTab> {
  bool _coverageExpanded = true;

  @override
  Widget build(BuildContext context) {
    if (widget.activePolicy == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shield_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No active shield found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Upgrade to start your protection', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final coverageItems = _getCoverageItems(widget.activePolicy);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(context, 'ACTIVE COVERAGE'),
          const SizedBox(height: 12),
          _ActiveCoverageCard(activePolicy: widget.activePolicy),
          
          // 7-Day Waiting Period Notice
          _buildWaitingPeriodNotice(),

          const SizedBox(height: 24),
          _buildCoverageHeader(),
          if (_coverageExpanded) 
            ...coverageItems.map((item) => _buildCoverageItem(item)),
          
          const SizedBox(height: 20),
          _policyDisclosureCard(context),
        ],
      ),
    );
  }

  Widget _buildWaitingPeriodNotice() {
    final createdAtStr = widget.activePolicy!['created_at']?.toString();
    if (createdAtStr == null) return const SizedBox.shrink();
    
    final createdAt = DateTime.tryParse(createdAtStr) ?? DateTime.now();
    final daysSinceStart = DateTime.now().difference(createdAt).inDays;
    
    if (daysSinceStart < 7) {
      final daysLeft = 7 - daysSinceStart;
      return Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.timer_outlined, color: Colors.orange, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Waiting Period Active', 
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('Payouts are enabled after 7 days of protection. $daysLeft days remaining.',
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildCoverageHeader() {
    return GestureDetector(
      onTap: () => setState(() => _coverageExpanded = !_coverageExpanded),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            const Expanded(child: Text('COVERAGE DETAILS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
            Icon(_coverageExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverageItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(children: [
        Icon(item['icon'] as IconData, color: Theme.of(context).primaryColor, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(item['subtitle'] as String, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ]),
    );
  }

  List<Map<String, dynamic>> _getCoverageItems(Map<String, dynamic>? policy) {
    final tier = _normalizePlanTier(policy?['plan_tier'] ?? policy?['plan_name']);
    final items = <Map<String, dynamic>>[];
    
    items.add({'icon': Icons.water_drop, 'title': 'Rain Disruption', 'subtitle': 'Triggers when rain > 3hrs'});
    items.add({'icon': Icons.wb_sunny, 'title': 'Extreme Heat', 'subtitle': 'Triggers above 42°C'});
    
    if (tier == 'standard' || tier == 'full') {
      items.add({'icon': Icons.air, 'title': 'Pollution Alert', 'subtitle': 'AQI > 200'});
      items.add({'icon': Icons.phonelink_off, 'title': 'Platform Downtime', 'subtitle': 'Outages over 90 mins'});
    }
    
    if (tier == 'full') {
      items.add({'icon': Icons.gavel, 'title': 'Bandh & Curfew', 'subtitle': 'City-wide shutdowns'});
      items.add({'icon': Icons.wifi_off, 'title': 'Internet Blackout', 'subtitle': 'Network connectivity loss'});
    }
    
    return items;
  }
}

// ─── Upgrade Tab ─────────────────────────────────────────────────────────────
class _UpgradeTab extends StatefulWidget {
  final VoidCallback? onProceed;
  final Map<String, dynamic>? activePolicy;
  final int activeDays;
  const _UpgradeTab({this.onProceed, this.activePolicy, this.activeDays = 0});

  @override
  State<_UpgradeTab> createState() => _UpgradeTabState();
}

class _UpgradeTabState extends State<_UpgradeTab> {
  String _selectedPlan = 'standard';
  final Map<String, bool> _riderToggles = {
    'Bandh / Curfew': false,
    'Internet Blackout': false,
  };

  @override
  Widget build(BuildContext context) {
    final plans = _getPlans(context);
    final total = _calculateTotal();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.activeDays < 5) _buildProbationNotice(),
          _sectionLabel(context, 'CHOOSE A SHIELD'),
          const SizedBox(height: 12),
          ...plans.map((p) => _PlanCard(
                plan: p,
                isSelected: _selectedPlan == p.id,
                isLocked: (p.id == 'standard' || p.id == 'full') && widget.activeDays < 5,
                activeDays: widget.activeDays,
                onTap: () => setState(() => _selectedPlan = p.id),
              )),
          const SizedBox(height: 24),
          if (_selectedPlan == 'standard') ...[
            _sectionLabel(context, 'ADD-ONS'),
            const SizedBox(height: 12),
            ..._riders.map((r) => _RiderRow(
                  rider: r,
                  value: _riderToggles[r.name] ?? false,
                  onChanged: (v) => setState(() => _riderToggles[r.name] = v),
                )),
          ],
          const SizedBox(height: 32),
          _buildActionSection(total),
        ],
      ),
    );
  }

  int _calculateTotal() {
    int t = _planBasePremium(_selectedPlan);
    if (_selectedPlan == 'standard') {
      if (_riderToggles['Bandh / Curfew']!) t += 15;
      if (_riderToggles['Internet Blackout']!) t += 12;
    }
    return t;
  }

  Widget _buildProbationNotice() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.security, color: Colors.red, size: 20),
              SizedBox(width: 12),
              Text('Underwriting Lock', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('New partners are restricted to Basic Shield for the first 5 days.', style: TextStyle(fontSize: 13)),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (widget.activeDays / 5).clamp(0.0, 1.0),
            backgroundColor: Colors.red.withValues(alpha: 0.1),
            valueColor: const AlwaysStoppedAnimation(Colors.red),
          ),
          const SizedBox(height: 6),
          Text('${widget.activeDays} of 5 days completed', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionSection(int total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('TOTAL PREMIUM', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                Text('₹$total/week', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.push(AppRoutes.checkout, extra: {
                'amount': total.toDouble(),
                'planName': _selectedPlan.toUpperCase(),
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Proceed →'),
          ),
        ],
      ),
    );
  }
}

// ─── History Tab ─────────────────────────────────────────────────────────────
class _LiveHistoryTab extends StatelessWidget {
  final Map<String, dynamic>? activePolicy;
  final List<Map<String, dynamic>> policyHistory;

  const _LiveHistoryTab({this.activePolicy, this.policyHistory = const []});

  @override
  Widget build(BuildContext context) {
    if (policyHistory.isEmpty) {
      return const Center(child: Text('No previous policies found', style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: policyHistory.length,
      itemBuilder: (context, index) {
        final item = policyHistory[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.history_edu),
            title: Text(item['plan_tier']?.toString().toUpperCase() ?? 'SHIELD'),
            subtitle: Text('Status: ${item['status']}'),
            trailing: Text('₹${item['weekly_premium']}'),
          ),
        );
      },
    );
  }
}

// ─── Shared Components ────────────────────────────────────────────────────────

class _ActiveCoverageCard extends StatelessWidget {
  final Map<String, dynamic>? activePolicy;
  const _ActiveCoverageCard({this.activePolicy});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF004734) : const Color(0xFF1B5E20);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(activePolicy?['plan_name'] ?? 'Protection Active', 
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              const Icon(Icons.verified, color: Colors.white, size: 24),
            ],
          ),
          const SizedBox(height: 12),
          const Text('VALIDITY', style: TextStyle(fontSize: 10, color: Colors.white60, fontWeight: FontWeight.bold)),
          Text(_formatValidity(activePolicy), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _GhostButton(
            onPressed: () => PdfGenerator.generateAndPreviewCertificate(),
            textColor: Colors.white,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.download, size: 16, color: Colors.white),
                SizedBox(width: 8),
                Text('Download Certificate', style: TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatValidity(Map<String, dynamic>? policy) {
    if (policy == null) return 'N/A';
    final start = DateTime.tryParse(policy['created_at']?.toString() ?? '') ?? DateTime.now();
    final end = DateTime.tryParse(policy['commitment_end']?.toString() ?? '') ?? start.add(const Duration(days: 7));
    return '${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}';
  }
}

class _PlanCard extends StatelessWidget {
  final _Plan plan;
  final bool isSelected;
  final bool isLocked;
  final int activeDays;
  final VoidCallback onTap;

  const _PlanCard({required this.plan, required this.isSelected, required this.onTap, this.isLocked = false, this.activeDays = 0});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: Opacity(
        opacity: isLocked ? 0.6 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? theme.primaryColor : theme.dividerColor, width: isSelected ? 2 : 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(plan.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        if (isLocked) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.lock, size: 14, color: Colors.red),
                        ],
                      ],
                    ),
                    Text(isLocked ? 'Unlocks in ${5 - activeDays} days' : plan.subtitle, 
                        style: TextStyle(fontSize: 12, color: isLocked ? Colors.red : Colors.grey)),
                  ],
                ),
              ),
              Text(plan.price, style: TextStyle(fontWeight: FontWeight.bold, color: theme.primaryColor)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RiderRow extends StatelessWidget {
  final _Rider rider;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _RiderRow({required this.rider, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(rider.icon),
      title: Text(rider.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      subtitle: Text(rider.price),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}

class _GhostButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color textColor;

  const _GhostButton({required this.onPressed, required this.child, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: textColor.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: child,
    );
  }
}

Widget _policyDisclosureCard(BuildContext context) {
  return InkWell(
    onTap: () => context.push(AppRoutes.insuranceCompliance),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          const Expanded(child: Text('Policy Disclosures & Compliance', style: TextStyle(fontWeight: FontWeight.bold))),
          const Icon(Icons.chevron_right),
        ],
      ),
    ),
  );
}

Widget _sectionLabel(BuildContext context, String text) {
  return Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2));
}
