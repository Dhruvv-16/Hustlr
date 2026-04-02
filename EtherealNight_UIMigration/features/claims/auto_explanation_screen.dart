import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AutoExplanationScreen extends StatelessWidget {
  const AutoExplanationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.canvasColor,
      appBar: AppBar(
        title: const Text('Why your claim was flagged', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
        backgroundColor: Colors.redAccent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 72),
            const SizedBox(height: 24),
            Text(
              'Our engine detected the following signals:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface, letterSpacing: -0.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildSignalItem(Icons.wifi_rounded, 'Home network detected', 'Your Wi-Fi showed a home SSID during the disruption window', theme, isDark),
            const SizedBox(height: 16),
            _buildSignalItem(Icons.directions_walk_rounded, 'No outdoor motion', 'Your device motion was below your usual outdoor work pattern', theme, isDark),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04), width: 1.5),
                boxShadow: isDark ? [] : [const BoxShadow(color: Color(0x05000000), blurRadius: 16, offset: Offset(0, 8))],
              ),
              child: Column(
                children: [
                  Text('If you were genuinely affected, appeal below. We review within 4 hours.', textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w800, fontSize: 14, height: 1.5)),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: isDark ? theme.canvasColor : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening camera for EXIF photo...')));
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Submit Appeal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('First-time flags are treated as caution only.', textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignalItem(IconData icon, String title, String detail, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.redAccent.withOpacity(0.2), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: Colors.redAccent, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.redAccent, fontSize: 15)),
                const SizedBox(height: 6),
                Text(detail, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w600, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
