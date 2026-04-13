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

class _ManualClaimCameraScreenState extends State<ManualClaimCameraScreen> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    
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
    } else {
      // Auto-launch the camera immediately instead of waiting for a button tap
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _capturePhoto();
      });
    }
  }

  @override
  void dispose() {
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
      } else if (mounted) {
        // User cancelled camera, go back
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
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
      body: Center(
        child: CircularProgressIndicator(color: primaryColor),
      ),
    );
  }
}
