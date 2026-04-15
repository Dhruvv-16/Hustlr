import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/router/app_router.dart';
import '../../shared/widgets/mobile_container.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/income_tip_card.dart';
import '../../widgets/hustlr_bottom_nav.dart';
import '../../services/notification_service.dart';
import '../../l10n/app_localizations.dart';
import '../../core/utils/pdf_generator.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? policyData;
  Map<String, dynamic>? walletData;
  Map<String, dynamic>? disruptionData;
  Map<String, dynamic>? weatherData;
  Map<String, dynamic>? nudgeData;
  Map<String, dynamic>? workAdvisorData;
  Map<String, dynamic>? activeDisruption;
  String? userId;
  String? userZone;
  String? userName;
  bool isLoading = true;
  Timer? _disruptionRefreshTimer;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _disruptionRefreshTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      if (!mounted) return;
      _loadDashboardData();
    });
  }

  @override
  void dispose() {
    _disruptionRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    userId = await StorageService.instance.getUserId();
    userZone = await StorageService.instance.getUserZone();
    userName = await StorageService.instance.getUserName();

    if (userId == null) {
      if (mounted) setState(() => isLoading = false);
      return;
    }

    try {
      final policyRes = await ApiService.instance.getPolicy(userId!);
      final walletRes = await ApiService.instance.getWallet(userId!);
      Map<String, dynamic> disruptionRes = {};
      try {
        int? issScore;
        final w = await ApiService.instance.getWorkerById(userId!);
        final rawIss = w['iss_score'];
        if (rawIss is num) {
          issScore = rawIss.round().clamp(0, 100);
        }
        disruptionRes = await ApiService.instance.getDisruptions(
          userZone ?? '',
          issScore: issScore,
        );
      } catch (_) {}

      final rawPolicy = policyRes['policy'] as Map<String, dynamic>?;
      final tier = rawPolicy?['plan_tier'] as String?;
      policyData = rawPolicy == null
          ? null
          : {
              ...rawPolicy,
              'plan_name': _planDisplayName(tier),
            };

      final events = disruptionRes['disruptions'] as List<dynamic>? ?? [];
      final active = disruptionRes['active'] == true;
      final rawWeather = disruptionRes['weather'] as Map<String, dynamic>?;
      final rawNudge = disruptionRes['predictive_nudge'] as Map<String, dynamic>?;
      final rawAdvisor = disruptionRes['work_advisor'] as Map<String, dynamic>?;

      Map<String, dynamic>? latestDisruption;
      if (!active || events.isEmpty) {
        disruptionData = const {'active': false};
      } else {
        latestDisruption = events.first as Map<String, dynamic>;
        disruptionData = {
          'active': true,
          'trigger_type': latestDisruption['display_name'] as String? ?? 
              _disruptionTriggerLabel(latestDisruption['trigger_type'] as String?),
          'zone': userZone ?? 'Adyar Dark Store Zone',
        };
      }

      if (mounted) {
        setState(() {
          walletData = walletRes;
          weatherData = rawWeather;
          activeDisruption = latestDisruption;
          nudgeData = rawNudge;
          workAdvisorData = rawAdvisor;
          isLoading = false;
        });
      }

      // Trigger notifications based on policy status and disruptions
      final hasActivePolicy = policyData != null;
      final hasDisruptions = events.isNotEmpty;
      
      if (hasDisruptions) {
        if (hasActivePolicy) {
          NotificationService.instance.addRainAlert(userZone ?? 'Adyar Dark Store Zone');
        } else {
          NotificationService.instance.addMissedPayout(350);
        }
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  static String _planDisplayName(String? tier) {
    const m = {
      'basic': 'Basic Shield',
      'standard': 'Standard Shield',
      'full': 'Full Shield',
    };
    return m[tier] ?? 'Standard Shield';
  }

  static String _disruptionTriggerLabel(String? t) {
    const labels = {
      'rain_heavy': 'Heavy Rain',
      'platform_outage': 'Platform Downtime',
      'heat_severe': 'Extreme Heat',
      'extreme_heat': 'Extreme Heat',
      'bandh': 'Bandh / Curfew',
      'aqi_severe': 'Severe Pollution',
      'aqi_hazardous': 'Severe Pollution',
    };
    if (t == null) return 'Rain';
    return labels[t] ?? (t.isNotEmpty ? '${t[0].toUpperCase()}${t.substring(1).replaceAll('_', ' ')}' : 'Rain');
  }

  String _getGreetingText(BuildContext context) {
    final h = DateTime.now().hour;
    final l10n = AppLocalizations.of(context)!;
    if (h < 12) return l10n.dashboard_greeting_morning;
    if (h < 17) return l10n.dashboard_greeting_afternoon;
    return l10n.dashboard_greeting_evening;
  }

  void _handleNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        break;
      case 1:
        context.go('/policy');
        break;
      case 2:
        context.go('/claims');
        break;
      case 3:
        context.go('/wallet');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    
    if (isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        )),
      );
    }

    final planName = policyData?['plan_name'] ?? 'Standard Shield';
    final premium = policyData?['weekly_premium']?.toString() ?? 
        (planName == 'Basic Shield' ? '29' : 
         planName == 'Standard Shield' ? '49' : 
         planName == 'Full Shield' ? '79' : '109');
    final pAmount = (walletData?['balance'] as num?)?.toInt() ?? 680;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              physics: const BouncingScrollPhysics(),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 32),
                      _buildTitleSection(l10n),
                      const SizedBox(height: 20),
                      _buildRainAlertCard(l10n),
                      if (workAdvisorData != null) ...[
                        const SizedBox(height: 16),
                        _buildWorkAdvisorCard(),
                      ],
                      const SizedBox(height: 20),
                      _buildActivePolicyCard(planName, premium, l10n),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF111311) : const Color(0xFFF0F4F0),
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: Column(
                          children: [
                            _buildActionCards(context, l10n),
                            if (policyData != null) ...[
                              const SizedBox(height: 16),
                              _buildMissedPayoutsCard(pAmount, context, l10n),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1c1f1c) : const Color(0xFFE8F5E9);
    final borderColor = isDark 
        ? const Color(0xFF3fff8b).withOpacity(0.1) 
        : const Color(0xFF1B5E20).withOpacity(0.2);
    final iconColor = isDark 
        ? const Color(0xFFe1e3de).withOpacity(0.8) 
        : const Color(0xFF1B5E20);
    final mintColor = isDark ? const Color(0xFF3fff8b) : const Color(0xFF1B5E20);

    return Row(
      children: [
        GestureDetector(
          onTap: () => context.push(AppRoutes.profile),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.person, color: iconColor),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          userName ?? 'Karthik',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
            fontFamily: 'Manrope',
          ),
        ),
        const Spacer(),
        _buildMintIconBtn(Icons.headset_mic_rounded, () => context.push(AppRoutes.support), mintColor, isDark),
        const SizedBox(width: 12),
        _buildMintIconBtn(Icons.notifications_rounded, () => context.push(AppRoutes.notifications), mintColor, isDark),
      ],
    );
  }

  Widget _buildMintIconBtn(IconData icon, VoidCallback onTap, Color mintColor, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
           color: Colors.transparent,
           shape: BoxShape.circle,
           border: Border.all(color: mintColor.withOpacity(0.15)),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: mintColor, size: 18),
      ),
    );
  }

  Widget _buildTitleSection(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mintColor = isDark ? const Color(0xFF3fff8b) : const Color(0xFF1B5E20);
    final deepContainer = isDark ? const Color(0xFF003324) : const Color(0xFFE8F5E9);
    final subtextColor = isDark ? const Color(0xFF91938d) : const Color(0xFF4A6741);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.wallet_title,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
                fontFamily: 'Manrope',
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: deepContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: mintColor, size: 12),
                  const SizedBox(width: 6),
                  Text(
                    (userZone ?? 'BENGALURU, KA').toUpperCase(),
                    style: TextStyle(
                      color: mintColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Manrope',
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '${_getGreetingText(context)}, ${userName ?? 'Karthik'}',
          style: TextStyle(
            color: subtextColor,
            fontSize: 14,
            fontFamily: 'Manrope',
          ),
        ),
      ],
    );
  }

  Widget _buildActivePolicyCard(String planName, String premium, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1c1f1c) : Colors.white;
    final mintColor = isDark ? const Color(0xFF3fff8b) : const Color(0xFF1B5E20);
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subtleText = isDark ? const Color(0xFFe1e3de) : const Color(0xFF4A6741);
    final shadowColor = isDark 
        ? const Color(0xFF3fff8b).withOpacity(0.04) 
        : const Color(0xFF1B5E20).withOpacity(0.08);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
           BoxShadow(
              color: shadowColor,
              blurRadius: 40,
              spreadRadius: 10,
              offset: const Offset(0, 10),
           )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.dashboard_current_active,
                style: TextStyle(
                  color: mintColor,
                  fontSize: 11,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Manrope',
                ),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '₹$premium',
                      style: TextStyle(
                        color: mintColor,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Manrope',
                      ),
                    ),
                    TextSpan(
                      text: l10n.policy_per_week,
                      style: TextStyle(
                        color: subtleText,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            planName.replaceAll(' ', '\n'), 
            style: TextStyle(
              color: textColor,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              height: 1.1,
              fontFamily: 'Manrope',
            ),
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildCoverageChip(l10n.claims_heavy_rain.toUpperCase(), Icons.water_drop_rounded, mintColor, isDark),
              _buildCoverageChip(l10n.claims_extreme_heat.toUpperCase(), Icons.wb_sunny_rounded, mintColor, isDark),
              _buildCoverageChip(l10n.claims_platform_downtime.toUpperCase(), Icons.security_rounded, mintColor, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoverageChip(String label, IconData icon, Color mintColor, bool isDark) {
    final chipBg = isDark ? const Color(0xFF003D2A) : const Color(0xFFE8F5E9);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: mintColor, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: mintColor,
              fontSize: 9,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w900,
              fontFamily: 'Manrope',
            ),
          ),
        ],
      ),
    );
  }

  /// Earning-stability + shift hints from ML `/work-advisor` (bundled in disruptions API).
  Widget _buildWorkAdvisorCard() {
    final a = workAdvisorData;
    if (a == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF141614) : const Color(0xFFF8FAF8);
    final mintColor = isDark ? const Color(0xFF3fff8b) : const Color(0xFF1B5E20);
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subColor = textColor.withOpacity(0.65);

    final esi = (a['earning_stability_index'] as num?)?.round() ?? 0;
    final band = a['stability_band_label'] as String? ?? 'Earning outlook';
    final headline = a['headline'] as String? ?? '';
    final nudge = a['coverage_nudge'] as String? ?? '';
    final suggest = a['suggest_activate_coverage'] == true;
    final windows = a['recommended_shift_windows'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: mintColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, color: mintColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'WORK STABILITY',
                  style: TextStyle(
                    color: mintColor,
                    fontSize: 10,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Manrope',
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: mintColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'ESI $esi',
                  style: TextStyle(
                    color: mintColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Manrope',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            band,
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              fontFamily: 'Manrope',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            headline,
            style: TextStyle(
              color: subColor,
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w600,
              fontFamily: 'Manrope',
            ),
          ),
          if (windows.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Suggested shift focus',
              style: TextStyle(
                color: textColor.withOpacity(0.85),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                fontFamily: 'Manrope',
              ),
            ),
            const SizedBox(height: 6),
            ...windows.take(2).map((w) {
              final m = w is Map<String, dynamic> ? w : null;
              if (m == null) return const SizedBox.shrink();
              final label = m['label'] as String? ?? '';
              final hours = m['hours'] as String? ?? '';
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.schedule_rounded, size: 16, color: mintColor.withOpacity(0.85)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$label · $hours',
                        style: TextStyle(
                          color: subColor,
                          fontSize: 12,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Manrope',
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          if (nudge.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              nudge,
              style: TextStyle(
                color: suggest ? mintColor.withOpacity(0.95) : subColor,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
                fontFamily: 'Manrope',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRainAlertCard(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1c1f1c) : Colors.white;
    final mintColor = isDark ? const Color(0xFF3fff8b) : const Color(0xFF1B5E20);
    final iconBg = isDark ? const Color(0xFF003D2A) : const Color(0xFFE8F5E9);
    final textColor = Theme.of(context).colorScheme.onSurface;

    String locality = userZone ?? 'your area';
    locality = locality.replaceAll(RegExp(r' dark store zone', caseSensitive: false), '');
    locality = locality.replaceAll(RegExp(r' zone', caseSensitive: false), '');
    locality = locality.trim();
    if (locality.isEmpty) locality = 'your area';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(Icons.thunderstorm_rounded, color: mintColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.dashboard_rain_alert.toUpperCase(),
                  style: TextStyle(
                    color: mintColor,
                    fontSize: 10,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Manrope',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${l10n.dashboard_high_risk_prefix} $locality.\n${l10n.dashboard_secure_coverage}',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Manrope',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: mintColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Text(
                  l10n.dashboard_activate,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF0a0b0a) : Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Manrope',
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, 
                  color: isDark ? const Color(0xFF0a0b0a) : Colors.white, 
                  size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCards(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            Icons.shield_outlined, 
            l10n.dashboard_modular,
            l10n.dashboard_add_coverage,
            () => context.push(AppRoutes.policy),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionCard(
            Icons.article_outlined,
            l10n.dashboard_legal,
            l10n.dashboard_view_cert,
            () async {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.dashboard_generating_cert),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
              );
              await PdfGenerator.generateAndPreviewCertificate();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(IconData icon, String kicker, String label, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1c1f1c) : Colors.white;
    final mintColor = isDark ? const Color(0xFF3fff8b) : const Color(0xFF1B5E20);
    final iconBg = isDark ? const Color(0xFF003D2A) : const Color(0xFFE8F5E9);
    final subtextColor = isDark ? const Color(0xFF91938d) : const Color(0xFF4A6741);
    final textColor = Theme.of(context).colorScheme.onSurface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
               padding: const EdgeInsets.all(8),
               decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
               ),
               child: Icon(icon, color: mintColor, size: 22)
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kicker,
                  style: TextStyle(
                    color: subtextColor,
                    fontSize: 10,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Manrope',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    height: 1.3,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Manrope',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissedPayoutsCard(int amount, BuildContext context, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1c1f1c) : Colors.white;
    final mintColor = isDark ? const Color(0xFF3fff8b) : const Color(0xFF1B5E20);
    final pinkColor = isDark ? const Color(0xFFff8ba0) : const Color(0xFFE91E63);
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subtextColor = isDark ? const Color(0xFF91938d) : const Color(0xFF4A6741);

    return GestureDetector(
      onTap: () => context.push(AppRoutes.shadowPolicy),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.savings_rounded, color: pinkColor, size: 32), 
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: mintColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        l10n.dashboard_see_why,
                        style: TextStyle(
                          color: mintColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Manrope',
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, color: mintColor, size: 14),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              '₹$amount ${l10n.dashboard_missed_payouts}',
              style: TextStyle(
                color: textColor,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                height: 1.2,
                fontFamily: 'Manrope',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.dashboard_potential_loss,
              style: TextStyle(
                color: subtextColor,
                fontSize: 13,
                fontFamily: 'Manrope',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
