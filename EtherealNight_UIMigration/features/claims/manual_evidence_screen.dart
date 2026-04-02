import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ManualEvidenceScreen extends StatelessWidget {
  final String disruptionType;

  const ManualEvidenceScreen({super.key, required this.disruptionType});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.canvasColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Report a Disruption',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface, letterSpacing: -0.5),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
              ),
              child: Text(
                disruptionType,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: theme.colorScheme.primary),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            if (disruptionType == 'Road Blocked / Accident' || disruptionType == 'Heavy Traffic Congestion') ...[
              _buildCameraButton('Take photo of blockage', theme, isDark, subtitle: 'App will GPS-stamp automatically'),
              const SizedBox(height: 16),
              _buildGPSPreview(theme, isDark),
              const SizedBox(height: 32),
              _buildSubmitButton(context, 'Confirm Location', theme, isDark, isOutlined: true),
            ] else if (disruptionType == 'Dark Store / Hub Closed') ...[
              _buildCameraButton('Take photo of closed hub', theme, isDark),
              const SizedBox(height: 16),
              _buildUploadPlaceholder('Upload Zepto screenshot (no orders)', theme, isDark),
              const SizedBox(height: 32),
              _buildSubmitButton(context, 'Submit Claim', theme, isDark),
            ] else if (disruptionType == 'Internet Outage') ...[
              _buildSignalBars(theme, isDark),
              const SizedBox(height: 32),
              _buildSubmitButton(context, 'Confirm I cannot work', theme, isDark, subtitle: 'No photo needed — verified by network data'),
            ] else ...[
              _buildCameraButton('Take one photo', theme, isDark),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Describe the disruption (max 100 characters)',
                  hintStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04), width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04), width: 1.5),
                  ),
                ),
                style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w600),
                maxLength: 100,
                maxLines: 4,
              ),
              const SizedBox(height: 32),
              _buildSubmitButton(context, 'Submit Claim', theme, isDark),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCameraButton(String text, ThemeData theme, bool isDark, {String? subtitle}) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.04),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3), width: 2),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(Icons.camera_alt_rounded, color: theme.colorScheme.primary, size: 28),
            ),
            const SizedBox(height: 20),
            Text(text, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 16)),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w600)),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildUploadPlaceholder(String text, ThemeData theme, bool isDark) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.cardColor,
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04), width: 1.5),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: theme.colorScheme.onSurface.withOpacity(0.04), shape: BoxShape.circle),
              child: Icon(Icons.upload_file_rounded, color: theme.colorScheme.onSurface.withOpacity(0.4), size: 24),
            ),
            const SizedBox(height: 16),
            Text(text, textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 14, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _buildGPSPreview(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2), width: 1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(Icons.location_on_rounded, color: theme.colorScheme.primary, size: 32),
          const SizedBox(height: 12),
          Text('Your location: Adyar, Chennai', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 4),
          Text('Captured automatically', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSignalBars(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04), width: 1.5),
        boxShadow: isDark ? [] : [
          const BoxShadow(color: Color(0x05000000), blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(width: 16, height: 24, margin: const EdgeInsets.symmetric(horizontal: 4), decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(4))),
              Container(width: 16, height: 40, margin: const EdgeInsets.symmetric(horizontal: 4), decoration: BoxDecoration(color: theme.colorScheme.onSurface.withOpacity(0.06), borderRadius: BorderRadius.circular(4))),
              Container(width: 16, height: 56, margin: const EdgeInsets.symmetric(horizontal: 4), decoration: BoxDecoration(color: theme.colorScheme.onSurface.withOpacity(0.06), borderRadius: BorderRadius.circular(4))),
            ],
          ),
          const SizedBox(height: 24),
          Text('Current signal: Weak (1 bar)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 6),
          Text('Zone avg: 45 Mbps normally', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context, String text, ThemeData theme, bool isDark, {bool isOutlined = false, String? subtitle}) {
    Widget btn;
    if (isOutlined) {
      btn = OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: theme.colorScheme.primary, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          minimumSize: const Size(double.infinity, 64),
        ),
        onPressed: () => context.push('/claims/submitted'),
        child: Text(text, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: theme.colorScheme.primary, letterSpacing: 0.5)),
      );
    } else {
      btn = ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: isDark ? theme.canvasColor : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          minimumSize: const Size(double.infinity, 64),
        ),
        onPressed: () => context.push('/claims/submitted'),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, size: 20),
          ],
        ),
      );
    }

    if (subtitle == null) return btn;
    
    return Column(
      children: [
        btn,
        const SizedBox(height: 12),
        Text(subtitle, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
