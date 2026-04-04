import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import 'package:image_picker/image_picker.dart';
import '../../l10n/app_localizations.dart';

import 'manual_claim_review_screen.dart';

class ManualClaimCameraScreen extends StatefulWidget {
  final String disruptionType;
  const ManualClaimCameraScreen({super.key, required this.disruptionType});

  @override
  State<ManualClaimCameraScreen> createState() => _ManualClaimCameraScreenState();
}

class _ManualClaimCameraScreenState extends State<ManualClaimCameraScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    
    // Auto-progress internet outages
    if (widget.disruptionType == 'internet_outage') {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(
              builder: (_) => ManualClaimReviewScreen(
                disruptionType: widget.disruptionType,
                capturedImages: const [],
                signalStrength: 1,
              )
            )
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null && mounted) {
        // Go to review screen with the new photo
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(
            builder: (_) => ManualClaimReviewScreen(
              disruptionType: widget.disruptionType,
              capturedImages: [File(photo.path)],
            )
          )
        );
      }
    } catch (e) {
      // Handle camera permissions or errors
    }
  }

  void _onGalleryTapped() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Live capture required for fraud prevention', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      )
    );
  }

  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final l10n = AppLocalizations.of(context)!;

    if (widget.disruptionType == 'internet_outage') {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off_rounded, color: primaryColor, size: 64),
              const SizedBox(height: 24),
              Text(l10n.camera_internet_auto, style: const TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 8),
              Text(l10n.camera_no_photo, style: TextStyle(color: Colors.white.withOpacity(0.5))),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Simulated Camera View (would be CameraPreview ordinarily)
          Positioned.fill(
            child: Opacity(
              opacity: 0.4,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black, Color(0xFF1c1f1c)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                ),
              ),
            ),
          ),
          
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 20,
            child: InkWell(
              onTap: () => context.pop(),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                ),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.camera_title,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.1,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 100),
                  child: Text(
                    l10n.camera_subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.8),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Actions
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // AI anim
                Text(l10n.camera_scanning, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _capturePhoto,
                  child: AnimatedBuilder(
                    animation: _animController,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Transform.rotate(
                            angle: _animController.value * 2 * math.pi,
                            child: SizedBox(
                              width: 100, height: 100,
                              child: CustomPaint(
                                painter: _DashedCirclePainter(color: primaryColor.withOpacity(0.8)),
                              ),
                            ),
                          ),
                          Container(
                            width: 72, height: 72,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: primaryColor.withOpacity(0.4), blurRadius: 20, spreadRadius: 5),
                              ],
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: Colors.black, size: 32),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 48), // Padding added to match bottom inset without the gallery button
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final radius = size.width / 2;
    const dashLength = 4.0;
    const gapLength = 6.0;
    const totalLength = dashLength + gapLength;
    final totalDashes = (2 * math.pi * radius) / totalLength;

    for (int i = 0; i < totalDashes; i++) {
      final angle = i * (2 * math.pi / totalDashes);
      canvas.drawArc(
        Rect.fromCircle(center: Offset(radius, radius), radius: radius),
        angle,
        dashLength / radius,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
