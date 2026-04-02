import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/hustlr_bottom_nav.dart';

/// Shell wrapper used by GoRouter's ShellRoute.
/// Renders floating bottom nav + floating help button over the child screen.
class ScaffoldWithNav extends StatelessWidget {
  final Widget child;
  final String location;

  const ScaffoldWithNav({
    super.key,
    required this.child,
    required this.location,
  });

  int _selectedIndex(String loc) {
    if (loc.startsWith('/policy'))   return 1;
    if (loc.startsWith('/claims'))   return 2;
    if (loc.startsWith('/wallet'))   return 3;
    return 0; // dashboard
  }

  @override
  Widget build(BuildContext context) {
    final idx = _selectedIndex(location);
    final isSupport = location.startsWith('/support');

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // The main screen content with bottom padding so content isn't
          // hidden behind the floating nav.
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 120),
              child: child,
            ),
          ),

          // The floating Help Button — hidden on /support itself
          if (!isSupport)
            Positioned(
              right: 20,
              bottom: 100,
              child: _FloatingHelpButton(),
            ),

          // The entirely floating Capsule Nav Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: HustlrBottomNav(
              currentIndex: idx,
              onTap: (i) {
                final routes = [
                  AppRoutes.dashboard,
                  AppRoutes.policy,
                  AppRoutes.claims,
                  AppRoutes.wallet,
                ];
                context.go(routes[i]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Floating Help Button ─────────────────────────────────────────────────────
class _FloatingHelpButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.support),
      child: Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          color: Color(0xFF1B5E20),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x661B5E20),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.headset_mic_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

// ─── Dual-Mode Floating Bottom Nav Bar ───────────────────────────────────────
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // The redesign is dark mode only (Ethereal Night Atelier)
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: const Color(0xFF1a1c19),
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _NavItem(icon: Icons.shield_outlined, label: 'HOME', index: 0, current: currentIndex, onTap: onTap),
            _NavItem(icon: Icons.article_outlined, label: 'POLICY', index: 1, current: currentIndex, onTap: onTap),
            _NavItem(icon: Icons.verified_user_outlined, label: 'CLAIMS', index: 2, current: currentIndex, onTap: onTap),
            _NavItem(icon: Icons.grid_view_rounded, label: 'WALLET', index: 3, current: currentIndex, onTap: onTap),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF3fff8b)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive
                  ? const Color(0xFF0a0b0a)
                  : const Color(0xFF91938d),
              size: 22,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: isActive
                  ? const Color(0xFF3fff8b)
                  : const Color(0xFF91938d),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
