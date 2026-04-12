import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../core/services/storage_service.dart';

/// AWS Rekognition Step-Up Identity Verification Screen
/// Triggered on: behavioral anomaly, high-value claims (>=300),
/// new device detected, or 1% random weekly audit.
class StepUpAuthScreen extends StatefulWidget {
  /// Optional reason string shown to the user explaining why this was triggered
  final String? triggerReason;

  const StepUpAuthScreen({super.key, this.triggerReason});

  @override
  State<StepUpAuthScreen> createState() => _StepUpAuthScreenState();
}

class _StepUpAuthScreenState extends State<StepUpAuthScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  _VerificationState _state = _VerificationState.idle;
  String? _errorMessage;
  double? _similarityScore;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _captureAndVerify() async {
    setState(() {
      _state = _VerificationState.capturing;
      _errorMessage = null;
    });

    try {
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 640,
        maxHeight: 640,
        imageQuality: 85,
      );

      if (photo == null) {
        setState(() => _state = _VerificationState.idle);
        return;
      }

      setState(() => _state = _VerificationState.verifying);

      final bytes = await File(photo.path).readAsBytes();
      final base64Image = base64Encode(bytes);
      final userId = await StorageService.instance.getUserId();

      final result = await ApiService.instance.verifyFaceLiveness(
        workerId: userId ?? 'demo-user',
        imageBase64: base64Image,
      );

      final verified = result['verified'] as bool? ?? false;
      final score = (result['similarity_score'] as num?)?.toDouble() ?? 0.0;

      setState(() {
        _similarityScore = score;
        _state = verified
            ? _VerificationState.success
            : _VerificationState.failed;
        if (!verified) _errorMessage = 'Face did not match registered profile.';
      });

      if (verified) {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context, {'verified': true, 'similarity_score': score});
      }
    } catch (e) {
      setState(() {
        _state = _VerificationState.failed;
        _errorMessage = 'Verification error. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2E7D32);
    const accentGreen = Color(0xFF4CAF50);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: () => Navigator.pop(context, {'verified': false}),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: primaryColor.withOpacity(0.5)),
          ),
          child: const Text(
            'STEP-UP IDENTITY CHECK',
            style: TextStyle(
              color: accentGreen,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Trigger reason banner
            if (widget.triggerReason != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFA000).withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFF57C00), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.triggerReason!,
                        style: const TextStyle(
                          color: Color(0xFF7B3F00),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),

            // Face ring + status
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildFaceRing(accentGreen),
                  const SizedBox(height: 32),
                  _buildStatusText(),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                    ),
                  ],
                  if (_similarityScore != null && _state == _VerificationState.failed) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Similarity: ${(_similarityScore! * 100).toStringAsFixed(1)}% (threshold: 80%)',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),

            // Legal disclosure
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Hustlr uses AWS Rekognition to verify your identity. Only a numeric face embedding is stored — never your raw photo. Processed under DPDPA 2023 § 7(b) fraud prevention purpose limitation.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white24, fontSize: 10, height: 1.5),
              ),
            ),

            // CTA Button
            _buildActionButton(primaryColor, accentGreen),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFaceRing(Color accentGreen) {
    final ringColor = _state == _VerificationState.success
        ? accentGreen
        : _state == _VerificationState.failed
            ? Colors.redAccent
            : accentGreen;

    Widget icon;
    if (_state == _VerificationState.verifying) {
      icon = const CircularProgressIndicator(color: Color(0xFF4CAF50), strokeWidth: 3);
    } else if (_state == _VerificationState.success) {
      icon = Icon(Icons.check_circle_outline_rounded, color: accentGreen, size: 64);
    } else if (_state == _VerificationState.failed) {
      icon = const Icon(Icons.highlight_off_rounded, color: Colors.redAccent, size: 64);
    } else {
      icon = const Icon(Icons.face_outlined, color: Colors.white38, size: 64);
    }

    final shouldPulse = _state == _VerificationState.idle ||
        _state == _VerificationState.capturing;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (_, child) => Transform.scale(
        scale: shouldPulse ? _pulseAnimation.value : 1.0,
        child: child,
      ),
      child: Container(
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ringColor, width: 3),
          color: ringColor.withOpacity(0.08),
          boxShadow: [
            BoxShadow(
              color: ringColor.withOpacity(0.25),
              blurRadius: 40,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Center(child: icon),
      ),
    );
  }

  Widget _buildStatusText() {
    String title, subtitle;
    switch (_state) {
      case _VerificationState.idle:
        title = 'Face Identity Check';
        subtitle = 'Look into the camera and tap "Verify Identity" when ready.';
        break;
      case _VerificationState.capturing:
        title = 'Opening Camera...';
        subtitle = 'Please hold your phone steady in good lighting.';
        break;
      case _VerificationState.verifying:
        title = 'Verifying via AWS Rekognition...';
        subtitle = 'Comparing against your registered face profile. This takes ~3 seconds.';
        break;
      case _VerificationState.success:
        title = 'Identity Confirmed ✓';
        subtitle = 'Similarity: ${(_similarityScore! * 100).toStringAsFixed(1)}% — Proceeding...';
        break;
      case _VerificationState.failed:
        title = 'Verification Failed';
        subtitle = 'Face did not match your registered profile. Try again in good lighting.';
        break;
    }

    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _state == _VerificationState.success
                ? const Color(0xFF4CAF50)
                : _state == _VerificationState.failed
                    ? Colors.redAccent
                    : Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontFamily: 'Manrope',
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 13,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(Color primaryColor, Color accentGreen) {
    if (_state == _VerificationState.success) return const SizedBox.shrink();

    final isLoading = _state == _VerificationState.verifying ||
        _state == _VerificationState.capturing;
    final label = _state == _VerificationState.failed ? 'Try Again' : 'Verify Identity';

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : _captureAndVerify,
        icon: const Icon(Icons.camera_alt_outlined),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primaryColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

enum _VerificationState { idle, capturing, verifying, success, failed }
