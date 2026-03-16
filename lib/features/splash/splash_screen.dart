import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();

    // Subtle pulsing glow animation
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _glowAnim = Tween<double>(begin: 0.18, end: 0.32).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Navigate after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), _navigate);
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (!mounted) return;
    context.go(isLoggedIn ? '/dashboard' : '/login');
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F0),
      body: Stack(
        children: [
          // ── Centered content ───────────────────────────────────────────────
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Outer glow + icon container
                AnimatedBuilder(
                  animation: _glowAnim,
                  builder: (_, __) => Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF2E7D32).withValues(alpha: _glowAnim.value),
                    ),
                    alignment: Alignment.center,
                    child: _iconContainer(),
                  ),
                ),

                // "ShieldGig" title
                const SizedBox(height: 24),
                const Text(
                  'ShieldGig',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                    letterSpacing: 0.2,
                  ),
                ),

                // Tagline
                const SizedBox(height: 8),
                const Text(
                  'Your income.\nProtected.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF6B7280),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom progress indicator ───────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 60,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),

          // ── Floating help button ────────────────────────────────────────────
          Positioned(
            right: 20,
            bottom: 20,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.35),
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
        ],
      ),
    );
  }

  Widget _iconContainer() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: const Color(0xFFDCE8DC),
        borderRadius: BorderRadius.circular(32),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.shield_rounded,
        size: 72,
        color: Color(0xFF2E7D32),
      ),
    );
  }
}
