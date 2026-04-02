import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ClaimSubmittedScreen extends StatefulWidget {
  const ClaimSubmittedScreen({super.key});

  @override
  State<ClaimSubmittedScreen> createState() => _ClaimSubmittedScreenState();
}

class _ClaimSubmittedScreenState extends State<ClaimSubmittedScreen> with TickerProviderStateMixin {
  late AnimationController _checkBounce;
  late Animation<double> _checkScale;
  late Animation<double> _checkFade;

  @override
  void initState() {
    super.initState();

    // Entry animation only - no repeating floating/bobbing
    _checkBounce = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _checkScale = CurvedAnimation(parent: _checkBounce, curve: Curves.elasticOut);
    _checkFade = CurvedAnimation(parent: _checkBounce, curve: Curves.easeOut);
    _checkBounce.forward();
  }

  @override
  void dispose() {
    _checkBounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.canvasColor,
      body: Stack(
        children: [
          // ── Radial glow behind header (Static) ───────────────────
          Positioned(
            top: -80, left: 0, right: 0,
            child: Center(
              child: Container(
                width: 360, height: 360,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [theme.colorScheme.primary.withOpacity(isDark ? 0.12 : 0.08), Colors.transparent],
                    radius: 0.5,
                  ),
                ),
              ),
            ),
          ),

          // ── Main Content ─────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.go('/claims'),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04)),
                            boxShadow: isDark ? [] : [const BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 2))],
                          ),
                          child: Icon(Icons.close_rounded, color: theme.colorScheme.onSurface, size: 20),
                        ),
                      ),
                      const Spacer(),
                      Text('HUSTLR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: theme.colorScheme.primary, letterSpacing: 2)),
                      const Spacer(),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
                    child: Column(
                      children: [
                        // ── Success Checkmark ─────────────────────────────
                        _StaticCheckmark(
                          checkScale: _checkScale,
                          checkFade: _checkFade,
                          theme: theme, isDark: isDark,
                        ),
                        const SizedBox(height: 32),

                        // ── Title ─────────────────────────────────────────
                        FadeTransition(
                          opacity: _checkFade,
                          child: Column(
                            children: [
                              Text('Submitted', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface, letterSpacing: -0.5)),
                              const SizedBox(height: 12),
                              Text(
                                'Your evidence was successfully uploaded\nand is now being processed by our team.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withOpacity(0.6), height: 1.5, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 48),

                        Row(
                          children: [
                            Text('UPLOADED EVIDENCE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: theme.colorScheme.primary.withOpacity(0.8), letterSpacing: 2)),
                            const Spacer(),
                            Text('2 Files', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface.withOpacity(0.4))),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // ── Static Document Cards ───────────────────
                        _StaticDocumentPair(theme: theme, isDark: isDark),
                        const SizedBox(height: 40),

                        // ── Reference Chips ────────────────────────
                        _ReferenceChips(theme: theme, isDark: isDark),
                        const SizedBox(height: 24),

                        // ── Review Capsule ────────────────────────
                        _ReviewCapsule(theme: theme, isDark: isDark),
                        const SizedBox(height: 48),

                        // ── Back Button ────────────────────────────
                        _BackButton(onTap: () => context.go('/claims'), theme: theme, isDark: isDark),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StaticCheckmark extends StatelessWidget {
  final Animation<double> checkScale;
  final Animation<double> checkFade;
  final ThemeData theme; final bool isDark;

  const _StaticCheckmark({required this.checkScale, required this.checkFade, required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100, height: 100,
      child: Center(
        child: ScaleTransition(
          scale: checkScale,
          child: FadeTransition(
            opacity: checkFade,
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary,
                boxShadow: [
                  BoxShadow(color: theme.colorScheme.primary.withOpacity(0.5), blurRadius: 30, spreadRadius: 4),
                ],
              ),
              child: Icon(Icons.check_rounded, color: isDark ? theme.canvasColor : Colors.white, size: 40),
            ),
          ),
        ),
      ),
    );
  }
}

class _StaticDocumentPair extends StatelessWidget {
  final ThemeData theme;
  final bool isDark;

  const _StaticDocumentPair({required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final doc1Bg = isDark ? const Color(0xFF1E3A2E) : const Color(0xFFE8F5E9);
    final doc1IconColor = isDark ? const Color(0xFF80FFB8) : const Color(0xFF2E7D32);
    
    final doc2Bg = isDark ? const Color(0xFF0F2D45) : const Color(0xFFE3F2FD);
    final doc2IconColor = isDark ? const Color(0xFF64B5F6) : const Color(0xFF1565C0);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Transform.rotate(
          angle: -0.05,
          child: _DocumentTile(icon: Icons.article_rounded, label: 'Evidence_01.pdf', color: doc1Bg, iconColor: doc1IconColor, isDark: isDark),
        ),
        const SizedBox(width: 20),
        Transform.rotate(
          angle: 0.05,
          child: _DocumentTile(icon: Icons.image_rounded, label: 'Screenshot.jpg', color: doc2Bg, iconColor: doc2IconColor, isDark: isDark),
        ),
      ],
    );
  }
}

class _DocumentTile extends StatelessWidget {
  final IconData icon; final String label; final Color color; final Color iconColor; final bool isDark;

  const _DocumentTile({required this.icon, required this.label, required this.color, required this.iconColor, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130, height: 160,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: (isDark ? Colors.black : iconColor).withOpacity(isDark ? 0.3 : 0.1), blurRadius: 20, offset: const Offset(0, 16)),
        ],
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04), width: 1.5),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: iconColor, size: 42),
                const SizedBox(height: 12),
                Container(height: 4, width: 50, decoration: BoxDecoration(color: iconColor.withOpacity(0.4), borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 5),
                Container(height: 3, width: 40, decoration: BoxDecoration(color: iconColor.withOpacity(0.2), borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 4),
                Container(height: 3, width: 30, decoration: BoxDecoration(color: iconColor.withOpacity(0.15), borderRadius: BorderRadius.circular(2))),
              ],
            ),
          ),
          Positioned(
            bottom: 12, right: 12,
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.6),
                shape: BoxShape.circle,
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.05)),
              ),
              child: Icon(Icons.open_in_new_rounded, color: isDark ? Colors.white : iconColor, size: 14),
            ),
          ),
          Positioned(
            bottom: 14, left: 12,
            child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: isDark ? Colors.white.withOpacity(0.5) : iconColor.withOpacity(0.7), letterSpacing: 0.3)),
          ),
        ],
      ),
    );
  }
}

class _ReferenceChips extends StatelessWidget {
  final ThemeData theme; final bool isDark;

  const _ReferenceChips({required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04), width: 1.5),
        boxShadow: isDark ? [] : [
          BoxShadow(color: theme.colorScheme.primary.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text('CLAIM REFERENCE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface.withOpacity(0.4), letterSpacing: 2)),
              const Spacer(),
              Text('#HSTR-9284-X', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: theme.colorScheme.onSurface.withOpacity(0.08), height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('DATE SUBMITTED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface.withOpacity(0.4), letterSpacing: 2)),
              const Spacer(),
              Text('Oct 24, 2026', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewCapsule extends StatelessWidget {
  final ThemeData theme; final bool isDark;

  const _ReviewCapsule({required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
            child: Icon(Icons.access_time_filled_rounded, color: isDark ? theme.canvasColor : Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Review within 4 hours', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface)),
                const SizedBox(height: 6),
                Text(
                  "Our compliance team is verifying your upload. We'll notify you when resolved.",
                  style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.6), height: 1.5, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap; final ThemeData theme; final bool isDark;

  const _BackButton({required this.onTap, required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: theme.colorScheme.onSurface,
        foregroundColor: theme.canvasColor,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        minimumSize: const Size(double.infinity, 64),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_back_rounded, size: 20),
          SizedBox(width: 10),
          Text('Back to Claims', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}
