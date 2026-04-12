import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import '../../services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/biometric_service.dart';

/// AWS Rekognition Step-Up Identity Verification Screen
/// Triggered on: behavioral anomaly, high-value claims (>=300),
/// new device detected, or 1% random weekly audit.
///
/// Auth flow (two-tier):
///   Tier 1 → Native biometric (fingerprint / Face ID via local_auth)
///   Tier 2 → Camera selfie → AWS Rekognition (fallback or high-risk escalation)
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
  _AuthTier _tier = _AuthTier.biometric;

  String? _errorMessage;
  double? _similarityScore;
  bool _biometricAvailable = false;
  List<BiometricType> _enrolledBiometrics = [];

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
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final available = await BiometricService.instance.isAvailable();
    final enrolled = await BiometricService.instance.getEnrolledBiometrics();
    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _enrolledBiometrics = enrolled;
        // If biometric is unavailable, jump straight to camera tier
        if (!available) _tier = _AuthTier.camera;
      });
      // Auto-trigger biometric prompt on screen open if available
      if (available) _triggerBiometric();
    }
  }

  Future<void> _triggerBiometric() async {
    setState(() {
      _state = _VerificationState.verifying;
      _errorMessage = null;
    });

    final result = await BiometricService.instance.authenticate(
      reason: widget.triggerReason ??
          'Confirm your identity to proceed with this claim.',
    );

    if (!mounted) return;

    if (result.success) {
      setState(() => _state = _VerificationState.success);
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        Navigator.pop(context, {'verified': true, 'method': 'biometric'});
      }
    } else {
      setState(() {
        _state = _VerificationState.failed;
        _errorMessage = result.errorMessage;
        // On biometric failure, offer camera escalation
        _tier = _AuthTier.camera;
      });
    }
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
        if (mounted) {
          Navigator.pop(context, {
            'verified': true,
            'similarity_score': score,
            'method': 'rekognition',
          });
        }
      }
    } catch (e) {
      setState(() {
        _state = _VerificationState.failed;
        _errorMessage = 'Verification error. Please try again.';
      });
    }
  }

  // ── UI ──────────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
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
            color: primaryColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: primaryColor.withValues(alpha: 0.5)),
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

            // Auth tier indicator chips
            _buildTierChips(accentGreen),

            const SizedBox(height: 12),

            // Trigger reason banner
            if (widget.triggerReason != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFA000).withValues(alpha: 0.4)),
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

            // Biometric / face ring + status
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _tier == _AuthTier.biometric
                      ? _buildBiometricRing(accentGreen)
                      : _buildFaceRing(accentGreen),
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
                'Hustlr uses device biometrics and AWS Rekognition to verify your identity. Only a numeric face embedding is stored — never your raw photo. Processed under DPDPA 2023 § 7(b) fraud prevention purpose limitation.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white24, fontSize: 10, height: 1.5),
              ),
            ),

            // CTA Button(s)
            _buildActionButtons(primaryColor, accentGreen),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTierChips(Color accentGreen) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _TierChip(
          label: 'Tier 1: Biometric',
          icon: _primaryBiometricIcon(),
          active: _tier == _AuthTier.biometric,
          done: _tier == _AuthTier.camera,
          color: accentGreen,
        ),
        const SizedBox(width: 8),
        const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 12),
        const SizedBox(width: 8),
        _TierChip(
          label: 'Tier 2: Face (AWS)',
          icon: Icons.camera_front_outlined,
          active: _tier == _AuthTier.camera,
          done: false,
          color: accentGreen,
        ),
      ],
    );
  }

  IconData _primaryBiometricIcon() {
    if (_enrolledBiometrics.contains(BiometricType.face)) {
      return Icons.face_outlined;
    }
    return Icons.fingerprint;
  }

  Widget _buildBiometricRing(Color accentGreen) {
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
      icon = Icon(_primaryBiometricIcon(), color: Colors.white54, size: 64);
    }

    final shouldPulse = _state == _VerificationState.idle;

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
          color: ringColor.withValues(alpha: 0.08),
          boxShadow: [
            BoxShadow(
              color: ringColor.withValues(alpha: 0.25),
              blurRadius: 40,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Center(child: icon),
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
          color: ringColor.withValues(alpha: 0.08),
          boxShadow: [
            BoxShadow(
              color: ringColor.withValues(alpha: 0.25),
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
    if (_tier == _AuthTier.biometric) {
      switch (_state) {
        case _VerificationState.idle:
          title = 'Biometric Identity Check';
          subtitle = _biometricAvailable
              ? 'Use your fingerprint or Face ID to confirm your identity.'
              : 'No biometric enrolled — use camera instead.';
          break;
        case _VerificationState.verifying:
          title = 'Waiting for Biometric...';
          subtitle = 'Approve the prompt on your device.';
          break;
        case _VerificationState.success:
          title = 'Identity Confirmed';
          subtitle = 'Biometric match successful. Proceeding...';
          break;
        case _VerificationState.failed:
          title = 'Biometric Failed';
          subtitle = 'Switching to camera verification (AWS Rekognition).';
          break;
        default:
          title = 'Biometric Check';
          subtitle = '';
      }
    } else {
      switch (_state) {
        case _VerificationState.idle:
        case _VerificationState.failed:
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
          title = 'Identity Confirmed';
          subtitle = 'Similarity: ${(_similarityScore! * 100).toStringAsFixed(1)}% — Proceeding...';
          break;
      }
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

  Widget _buildActionButtons(Color primaryColor, Color accentGreen) {
    if (_state == _VerificationState.success) return const SizedBox.shrink();

    final isLoading = _state == _VerificationState.verifying ||
        _state == _VerificationState.capturing;

    if (_tier == _AuthTier.biometric) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : _triggerBiometric,
              icon: Icon(_primaryBiometricIcon()),
              label: Text(
                _state == _VerificationState.failed ? 'Retry Biometric' : 'Use Biometric',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: primaryColor.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          if (_biometricAvailable && _state == _VerificationState.failed) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() {
                _tier = _AuthTier.camera;
                _state = _VerificationState.idle;
                _errorMessage = null;
              }),
              child: const Text(
                'Use Camera Instead (AWS Rekognition)',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ),
          ],
        ],
      );
    }

    // Camera tier buttons
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : _captureAndVerify,
            icon: const Icon(Icons.camera_alt_outlined),
            label: Text(
              _state == _VerificationState.failed ? 'Try Again' : 'Verify Identity',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: primaryColor.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        if (_biometricAvailable) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() {
              _tier = _AuthTier.biometric;
              _state = _VerificationState.idle;
              _errorMessage = null;
            }),
            child: const Text(
              'Use Biometric Instead',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ),
        ],
      ],
    );
  }
}

class _TierChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final bool done;
  final Color color;

  const _TierChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.done,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = done
        ? color.withValues(alpha: 0.6)
        : active
            ? color
            : Colors.white12;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chipColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(done ? Icons.check_circle : icon, size: 14, color: chipColor),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: chipColor, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

enum _VerificationState { idle, capturing, verifying, success, failed }
enum _AuthTier { biometric, camera }
