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
  Map<String, dynamic>? activeDisruption;
  String? userId;
  String? userZone;
  String? userName;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
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
        disruptionRes = await ApiService.instance.getDisruptions(userZone ?? '');
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
          nudgeData = (rawNudge?['active'] == true) ? rawNudge : null;
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
      'elite': 'Elite Shield',
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

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
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
    
    if (isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        )),
      );
    }

    final premium = policyData?['weekly_premium']?.toString() ?? '72';
    final planName = policyData?['plan_name'] ?? 'Standard Shield';
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
                      _buildTitleSection(),
                      const SizedBox(height: 32),
                      _buildActivePolicyCard(planName, premium),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF111311) : const Color(0xFFF0F4F0),
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: Column(
                          children: [
                            _buildRainAlertCard(),
                            const SizedBox(height: 16),
                            _buildActionCards(context),
                            if (policyData != null) ...[
                              const SizedBox(height: 16),
                              _buildMissedPayoutsCard(pAmount, context),
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

  Widget _buildTitleSection() {
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
              'Vault',
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
          '${_getGreeting()}, ${userName ?? 'Karthik'}',
          style: TextStyle(
            color: subtextColor,
            fontSize: 14,
            fontFamily: 'Manrope',
          ),
        ),
      ],
    );
  }

  Widget _buildActivePolicyCard(String planName, String premium) {
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
                'CURRENT ACTIVE POLICY',
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
                      text: '/wk',
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
          Row(
            children: [
              _buildCoverageChip('RAIN', Icons.water_drop_rounded, mintColor, isDark),
              const SizedBox(width: 10),
              _buildCoverageChip('HEAT', Icons.wb_sunny_rounded, mintColor, isDark),
              const SizedBox(width: 10),
              _buildCoverageChip('PLATFORM', Icons.security_rounded, mintColor, isDark),
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

  Widget _buildRainAlertCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1c1f1c) : Colors.white;
    final mintColor = isDark ? const Color(0xFF3fff8b) : const Color(0xFF1B5E20);
    final iconBg = isDark ? const Color(0xFF003D2A) : const Color(0xFFE8F5E9);
    final textColor = Theme.of(context).colorScheme.onSurface;

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
                  'RAIN ALERT',
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
                  'High risk in Indiranagar.\nSecure coverage now.',
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
                  'ACTIVATE',
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

  Widget _buildActionCards(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            Icons.shield_outlined, 
            'MODULAR',
            'Add New\nCoverage',
            () => context.push(AppRoutes.policy),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionCard(
            Icons.article_outlined,
            'LEGAL',
            'View\nCertificate',
            () => context.push(AppRoutes.policy),
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

  Widget _buildMissedPayoutsCard(int amount, BuildContext context) {
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
                        'SEE WHY',
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
              '₹$amount missed\npayouts',
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
              'Potential earnings lost this month',
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
