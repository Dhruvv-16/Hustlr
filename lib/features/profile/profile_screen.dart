import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/storage_service.dart';
import '../../services/api_service.dart';
import '../../services/app_events.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/biometric_service.dart';
import '../../shared/widgets/mobile_container.dart';
import '../../core/theme/theme_provider.dart';
import '../../widgets/language_switcher.dart';
import '../../l10n/app_localizations.dart';
import '../../services/api_health_service.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/auth_service.dart';
import '../../features/shared/widgets/demo_control_panel.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _worker;
  Map<String, dynamic>? _policy;
  Map<String, dynamic>? _trustProfile = {
    'score': 124,
    'tier': {'label': '🥇 Gold'},
    'clean_weeks': 3,
    'cashback_earned': 49,
  };
  bool _isLoading = true;
  bool _biometricEnabled = false;
  StreamSubscription<void>? _policySub;
  StreamSubscription<void>? _claimSub;
  StreamSubscription<void>? _walletSub;

  @override
  void initState() {
    super.initState();
    _loadData();
    _policySub = AppEvents.instance.onPolicyUpdated.listen((_) => _loadData());
    _claimSub = AppEvents.instance.onClaimUpdated.listen((_) => _loadData());
    _walletSub = AppEvents.instance.onWalletUpdated.listen((_) => _loadData());
  }

  @override
  void dispose() {
    _policySub?.cancel();
    _claimSub?.cancel();
    _walletSub?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final userId = await StorageService.instance.getUserId();
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    
    try {
      final worker = await ApiService.instance.getWorkerById(userId);
      Map<String, dynamic>? policy;
      Map<String, dynamic>? trustProfile;
      try {
        final policyData = await ApiService.instance.getPolicy(userId);
        policy = policyData['policy'] as Map<String, dynamic>?;
      } catch (_) {}
      
      try {
        trustProfile = await ApiService.instance.getTrustProfile(userId);
      } catch (_) {}
      
      final prefs = await SharedPreferences.getInstance();
      final bioEnabled = prefs.getBool('biometric_enabled') ?? false;

      if (mounted) {
        setState(() {
          _worker = worker;
          _policy = policy;
          _trustProfile = trustProfile ?? _trustProfile; // fallback if fails completely
          _biometricEnabled = bioEnabled;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.canvasColor,
        body: Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)),
      );
    }

    return MobileContainer(
      child: Scaffold(
        backgroundColor: theme.canvasColor,
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back_rounded, color: theme.colorScheme.onSurface),
                            onPressed: () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go('/dashboard');
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.profile_title.toUpperCase(),
                            style: theme.textTheme.displayMedium,
                          ),
                        ],
                      ),
                      // Mode Toggle
                      const _ThemeToggle(),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    
                    // ── User Identity ─────────────────────────────────────
                    _buildUserIdentity(_worker, theme, isDark, l10n),
                    const SizedBox(height: 32),

                    // ── Personal Info ─────────────────────────────────────
                    Text(l10n.profile_personal_info, style: theme.textTheme.labelSmall),
                    const SizedBox(height: 16),
                    _InfoCard(
                      theme: theme,
                      isDark: isDark,
                      rows: [
                        (Icons.person_rounded, l10n.profile_name, _worker?['name'] as String? ?? 'John Doe'),
                        (Icons.location_on_rounded, l10n.profile_zone, _worker?['zone'] as String? ?? 'N/A'),
                        (Icons.phone_rounded, l10n.profile_mobile, _worker?['phone'] as String? ?? '+91 98765 43210'),
                        (Icons.account_balance_wallet_rounded, l10n.profile_upi_id, '${_worker?['phone'] as String? ?? 'user'}@ybl'),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // ── Account Info ──────────────────────────────────────
                    Text(l10n.profile_account_info, style: theme.textTheme.labelSmall),
                    const SizedBox(height: 16),
                    _InfoCard(
                      theme: theme,
                      isDark: isDark,
                      rows: [
                        (Icons.badge_rounded, l10n.profile_hustlr_id, _worker?['id']?.toString().split('-')[0].toUpperCase() ?? 'HUSTLR-XXXX'),
                        (Icons.shield_rounded, l10n.profile_active_plan, _policy?['plan_tier'] != null ? '${_policy!['plan_tier'].toString().toUpperCase()} SHIELD' : 'None'),
                        (Icons.calendar_today_rounded, l10n.profile_validity, _policy != null ? 'Active' : 'N/A'),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // ── Security ──────────────────────────────────────────────
                    Text('SECURITY', style: theme.textTheme.labelSmall),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: isDark ? [] : [
                          BoxShadow(color: theme.colorScheme.primary.withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 10))
                        ],
                      ),
                      child: FutureBuilder<bool>(
                        future: BiometricService.instance.isAvailable(),
                        builder: (context, snap) {
                          if (!(snap.data ?? false)) return const SizedBox.shrink();
                          return SwitchListTile(
                            title: const Text('Fingerprint Lock', style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: const Text('Require biometrics on app open', style: TextStyle(fontSize: 12)),
                            value: _biometricEnabled,
                            activeColor: const Color(0xFF2E7D32),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            onChanged: (val) async {
                              if (val) {
                                final result = await BiometricService.instance.authenticate(
                                  reason: 'Enable fingerprint lock for Hustlr');
                                if (!result.success) return;
                              }
                              setState(() => _biometricEnabled = val);
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setBool('biometric_enabled', val);
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Language Switcher ───────────────────────────────────────
                    Container(
                      margin: const EdgeInsets.only(bottom: 32),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: isDark ? [] : [
                          BoxShadow(color: theme.colorScheme.primary.withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 10))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 3, height: 18,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                l10n.profile_language.toUpperCase(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.5)
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const LanguageSwitcher(showLabel: false),
                        ],
                      ),
                    ),

                    // ── API Status ────────────────────────────────────────
                    _ApiStatusTile(theme: theme, isDark: isDark),
                    const SizedBox(height: 16),
                    
                    // ── Developer Options ─────────────────────────────────
                    GestureDetector(
                      onTap: () => context.push('/admin/ml-tester'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1B5E20).withOpacity(0.2) : const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF3FFF8B).withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.code_rounded, color: Color(0xFF3FFF8B), size: 24),
                            const SizedBox(width: 16),
                            const Expanded(child: Text("Developer: ML Tester", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3FFF8B)))),
                            const Icon(Icons.chevron_right_rounded, color: Color(0xFF3FFF8B)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => showDemoPanel(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1B5E20).withOpacity(0.2) : const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF3FFF8B).withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.build_circle_rounded, color: Color(0xFF3FFF8B), size: 24),
                            const SizedBox(width: 16),
                            const Expanded(child: Text("Developer: Demo Controls", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3FFF8B)))),
                            const Icon(Icons.chevron_right_rounded, color: Color(0xFF3FFF8B)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Logout ────────────────────────────────────────────
                    Align(
                      alignment: Alignment.centerRight, // Asymmetric CTA alignment
                      child: GestureDetector(
                        onTap: () async {
                          await AuthService.logout();
                          if (context.mounted) {
                            context.go('/login');
                          }
                        },
                        child: Container(
                          width: 200,
                          height: 56,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1c1f1c) : const Color(0xFFFFF0F0),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                            boxShadow: isDark ? [] : [
                              BoxShadow(color: Colors.redAccent.withOpacity(0.1), blurRadius: 16, offset: const Offset(0, 8)),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                              const SizedBox(width: 8),
                              Text(l10n.profile_logout, style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.redAccent, fontWeight: FontWeight.bold
                              )),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserIdentity(dynamic worker, ThemeData theme, bool isDark, AppLocalizations l10n) {
    return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24), // dual mode convention
          border: isDark ? null : Border.all(color: theme.colorScheme.primary.withOpacity(0.0)),
          boxShadow: isDark ? [
            // Ethereal ambient shadow
            BoxShadow(color: theme.colorScheme.primary.withOpacity(0.02), blurRadius: 40, offset: const Offset(0, 20)),
          ] : [
            // Organic shadow
            BoxShadow(color: theme.colorScheme.primary.withOpacity(0.08), blurRadius: 40, offset: const Offset(0, 20)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withOpacity(0.1),
              ),
              child: Icon(Icons.person_rounded, size: 40, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_worker?['name'] as String? ?? 'John Doe', style: theme.textTheme.displaySmall),
                  const SizedBox(height: 4),
                  Text(
                    '${(_worker?['platform'] as String? ?? 'Swiggy').toUpperCase()} ${l10n.profile_partner.toUpperCase()}',
                    style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
  }
}

// ── Theme Toggle Switch ──────────────────────────────────────────────────────
class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final isDark = themeProvider.isDarkMode(context);

    // Pill switch with sun/moon
    return GestureDetector(
      onTap: () {
        themeProvider.toggleTheme(!isDark);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.fastOutSlowIn,
        width: 64,
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: isDark ? theme.colorScheme.surface : theme.colorScheme.surface,
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(isDark ? 0.4 : 0.2),
            width: 1,
          ),
          boxShadow: isDark ? [
             BoxShadow(color: theme.colorScheme.primary.withOpacity(0.1), blurRadius: 12)
          ] : [],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              left: isDark ? 28 : 0,
              right: isDark ? 0 : 28,
              child: Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary,
                  boxShadow: [
                    BoxShadow(color: theme.colorScheme.primary.withOpacity(0.5), blurRadius: 8)
                  ],
                ),
                child: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  size: 16,
                  color: isDark ? theme.canvasColor : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable Info Card ───────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final ThemeData theme;
  final bool isDark;
  final List<(IconData, String, String)> rows;

  const _InfoCard({required this.theme, required this.isDark, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isDark ? [] : [
            BoxShadow(color: theme.colorScheme.primary.withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 10))
          ],
        ),
        child: Column(
          children: rows.asMap().entries.map((entry) {
            final idx = entry.key;
            final row = entry.value;
            final isLast = idx == rows.length - 1;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(row.$1, color: theme.colorScheme.primary, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(row.$2, style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.5)
                            )),
                            const SizedBox(height: 4),
                            Text(row.$3, style: theme.textTheme.bodyLarge),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Container(
                    height: 1, 
                    margin: const EdgeInsets.only(left: 80, right: 24), 
                    color: isDark ? theme.colorScheme.surface : theme.colorScheme.surface,
                    // Use surface color as divider to match "no 1px solid dividers" rule 
                    // Tonal background shift creates the line implicitly in Dark Mode
                  )
              ],
            );
          }).toList(),
        ),
      );
  }
}

// ── API Status Tile ──────────────────────────────────────────────────────────
class _ApiStatusTile extends StatelessWidget {
  final ThemeData theme;
  final bool isDark;
  const _ApiStatusTile({required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ApiHealthService.instance,
      builder: (context, _) {
        final status = ApiHealthService.instance.overallStatus;
        final isChecking = ApiHealthService.instance.isChecking;

        final (dotColor, label) = switch (status) {
          ApiStatus.online   => (const Color(0xFF3FFF8B), 'All APIs Online'),
          ApiStatus.degraded => (const Color(0xFFFFD54F), 'Partial Degradation'),
          ApiStatus.offline  => (const Color(0xFFFF5252), 'APIs Offline'),
          ApiStatus.unknown  => (const Color(0xFF91938d), 'Checking...'),
        };

        return GestureDetector(
          onTap: () => context.push('/profile/api-status'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isDark ? [] : [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: dotColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isChecking
                      ? Center(
                          child: SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: dotColor,
                            ),
                          ),
                        )
                      : Icon(Icons.wifi_tethering_rounded, color: dotColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'API Status',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 7, height: 7,
                            margin: const EdgeInsets.only(right: 5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: dotColor,
                              boxShadow: [BoxShadow(color: dotColor.withOpacity(0.5), blurRadius: 4)],
                            ),
                          ),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              color: dotColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurface.withOpacity(0.35),
                  size: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
