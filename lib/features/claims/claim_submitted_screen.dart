import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';

class ClaimSubmittedScreen extends StatelessWidget {
  final Map<String, dynamic>? claimData;
  final List<String>? imagePaths; // local File paths or network URLs

  const ClaimSubmittedScreen({super.key, this.claimData, this.imagePaths});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.canvasColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: primaryColor.withOpacity(0.4), blurRadius: 24, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.black, size: 40),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.submitted_title,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.submitted_subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Thumbnails Section
                    Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                for (var i = 0; i < 2; i++) ...[
                                  Expanded(
                                    child: Container(
                                      height: 120,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.onSurface.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      clipBehavior: Clip.hardEdge,
                                      child: _buildThumbnail(i, theme, isDark),
                                    ),
                                  ),
                                  if (i == 0) const SizedBox(width: 16),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Info Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: primaryColor.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline_rounded, color: primaryColor, size: 20),
                              const SizedBox(width: 8),
                              Text(l10n.submitted_next, style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(l10n.submitted_next_1, theme),
                          const SizedBox(height: 8),
                          _buildInfoRow(l10n.submitted_next_2, theme),
                          const SizedBox(height: 8),
                          _buildInfoRow(l10n.submitted_next_3, theme),
                        ],
                      ),
                    ),
                    if (claimData?['_mock'] == true) ...[
                      const SizedBox(height: 16),
                      Text(l10n.submitted_demo, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4), fontSize: 12)),
                    ]
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 64),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                ),
                onPressed: () {
                  // Go back to absolute root or claims tab
                  context.go('/claims');
                },
                child: Text(l10n.submitted_back, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(int i, ThemeData theme, bool isDark) {
    // Priority 1: local file paths passed from camera
    if (imagePaths != null && imagePaths!.length > i) {
      final path = imagePaths![i];
      if (path.startsWith('http')) {
        return Image.network(path, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _brokenImagePlaceholder(theme, isDark));
      } else {
        return Image.file(File(path), fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _brokenImagePlaceholder(theme, isDark));
      }
    }
    // Priority 2: network URLs from server response
    final urls = claimData?['evidence_urls'];
    if (urls is List && urls.length > i) {
      return Image.network(urls[i].toString(), fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _brokenImagePlaceholder(theme, isDark));
    }
    return _brokenImagePlaceholder(theme, isDark);
  }

  Widget _brokenImagePlaceholder(ThemeData theme, bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 32),
          SizedBox(height: 4),
          Text('Photo uploaded', style: TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String text, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Container(width: 4, height: 4, decoration: BoxDecoration(color: theme.colorScheme.onSurface.withOpacity(0.5), shape: BoxShape.circle)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontSize: 13)),
        ),
      ],
    );
  }
}
