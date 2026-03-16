import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/router/app_router.dart';

class FloatingHelpButton extends StatelessWidget {
  const FloatingHelpButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 80, // sits above the 64px bottom nav bar
      child: GestureDetector(
        onTap: () => context.push(AppRoutes.support),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: primaryGreen,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primaryGreen.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.headset_mic_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}

/// Wrap any Scaffold body with this to automatically include
/// the FloatingHelpButton in a Stack.
class ScaffoldWithHelp extends StatelessWidget {
  final Widget child;
  const ScaffoldWithHelp({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        const FloatingHelpButton(),
      ],
    );
  }
}
