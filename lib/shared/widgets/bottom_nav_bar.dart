import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/router/app_router.dart';
import 'floating_help_button.dart';

/// Shell wrapper used by GoRouter's ShellRoute.
/// Renders bottom nav + floating help button on every tab screen.
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
    if (loc.startsWith('/profile'))  return 4;
    return 0; // dashboard
  }

  @override
  Widget build(BuildContext context) {
    final idx = _selectedIndex(location);
    return Scaffold(
      body: Stack(
        children: [
          child,
          const FloatingHelpButton(),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: idx,
        onTap: (i) {
          final routes = [
            AppRoutes.dashboard,
            AppRoutes.policy,
            AppRoutes.claims,
            AppRoutes.wallet,
            AppRoutes.profile,
          ];
          context.go(routes[i]);
        },
      ),
    );
  }
}

// ─── Bottom Nav Bar ───────────────────────────────────────────────────────────
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
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: cardWhite,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(icon: Icons.home_rounded,        label: 'HOME',    index: 0, current: currentIndex, onTap: onTap),
          _NavItem(icon: Icons.shield_rounded,      label: 'POLICY',  index: 1, current: currentIndex, onTap: onTap),
          _NavItem(icon: Icons.receipt_long_rounded,label: 'CLAIMS',  index: 2, current: currentIndex, onTap: onTap),
          _NavItem(icon: Icons.account_balance_wallet_rounded, label: 'WALLET', index: 3, current: currentIndex, onTap: onTap),
          _NavItem(icon: Icons.person_rounded,      label: 'PROFILE', index: 4, current: currentIndex, onTap: onTap),
        ],
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
      child: SizedBox(
        width: 64,
        height: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive ? primaryGreen : textHint,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isActive ? primaryGreen : textHint,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
