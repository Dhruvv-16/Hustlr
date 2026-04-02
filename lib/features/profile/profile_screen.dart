import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/mock_data_service.dart';
import '../../shared/widgets/mobile_container.dart';
import '../../core/theme/theme_provider.dart';
import '../../widgets/language_switcher.dart';
import '../../l10n/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mockData = Provider.of<MockDataService>(context);
    final worker = mockData.worker;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

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
                      Text(
                        l10n.profile_title.toUpperCase(),
                        style: theme.textTheme.displayMedium,
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
                    _buildUserIdentity(worker, theme, isDark),
                    const SizedBox(height: 32),

                    // ── Personal Info ─────────────────────────────────────
                    Text('PERSONAL INFO', style: theme.textTheme.labelSmall),
                    const SizedBox(height: 16),
                    _InfoCard(
                      theme: theme,
                      isDark: isDark,
                      rows: [
                        (Icons.person_rounded, 'NAME', worker.name),
                        (Icons.location_on_rounded, 'ZONE', worker.zone),
                        (Icons.phone_rounded, 'MOBILE', '+91 98765 43210'),
                        (Icons.account_balance_wallet_rounded, 'UPI ID', 'user@ybl'),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // ── Account Info ──────────────────────────────────────
                    Text('ACCOUNT INFO', style: theme.textTheme.labelSmall),
                    const SizedBox(height: 16),
                    _InfoCard(
                      theme: theme,
                      isDark: isDark,
                      rows: [
                        (Icons.badge_rounded, 'HUSTLR ID', worker.id),
                        (Icons.shield_rounded, 'ACTIVE PLAN', mockData.activePolicy.plan),
                        (Icons.calendar_today_rounded, 'VALIDITY', '${mockData.activePolicy.coverageStart} – ${mockData.activePolicy.coverageEnd}'),
                      ],
                    ),
                    const SizedBox(height: 48),

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

                    // ── Logout ────────────────────────────────────────────
                    Align(
                      alignment: Alignment.centerRight, // Asymmetric CTA alignment
                      child: GestureDetector(
                        onTap: () { /* Logout logic */ },
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

  Widget _buildUserIdentity(dynamic worker, ThemeData theme, bool isDark) {
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
                  Text(worker.name, style: theme.textTheme.displaySmall),
                  const SizedBox(height: 4),
                  Text(
                    '${worker.platform} PARTNER',
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
