import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/colors.dart' as app_colors;

class ClaimSubmittedScreen extends StatefulWidget {
  const ClaimSubmittedScreen({super.key});

  @override
  State<ClaimSubmittedScreen> createState() => _ClaimSubmittedScreenState();
}

class _ClaimSubmittedScreenState extends State<ClaimSubmittedScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnimation = CurvedAnimation(
        parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: app_colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: const CircleAvatar(
                  radius: 50,
                  backgroundColor: app_colors.lightGreen,
                  child: Icon(Icons.check_circle_rounded,
                      color: app_colors.primaryGreen, size: 60),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Claim Submitted',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: app_colors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "We're verifying 3 data sources.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: app_colors.textSecondary),
              ),
              const SizedBox(height: 32),
              const LinearProgressIndicator(
                color: app_colors.primaryGreen,
                backgroundColor: Color(0xFFE5E7EB),
                minHeight: 6,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.access_time, color: Color(0xFF2D6A2D), size: 16),
                        SizedBox(width: 8),
                        Text('Review within 4 hours'),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.notifications, color: Color(0xFF2D6A2D), size: 16),
                        SizedBox(width: 8),
                        Text("We'll notify you when resolved"),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go('/claims'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF2D6A2D)),
                    foregroundColor: const Color(0xFF2D6A2D),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Back to Claims',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D6A2D))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
