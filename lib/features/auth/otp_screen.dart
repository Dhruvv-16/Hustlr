import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/services/storage_service.dart';
import '../../core/router/app_router.dart';
import '../../shared/widgets/mobile_container.dart';

import '../../core/constants/colors.dart' as app_colors;
import '../../core/constants/text_styles.dart';

// ─── Palette (using global tokens) ────────────────────────────────────────────
const _green      = app_colors.primaryGreen;
const _lightGreen = app_colors.lightGreen;
const _primary    = app_colors.textPrimary;
const _grey       = app_colors.textSecondary;
const _hint       = app_colors.textHint;
const _border     = Color(0xFFE5E7EB);
const _bg         = Color(0xFFF0F4F0);

class OTPScreen extends StatefulWidget {
  final String phone;
  const OTPScreen({super.key, required this.phone});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  // 6 controllers + focus nodes for each digit box
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(6, (_) => FocusNode());

  bool _loading = false;
  String? _error;

  // Hardcoded demo OTP — any 6-digit code passes
  static const _validOtp = '123456';

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  String get _currentOtp =>
      _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() => _error = null);
  }

  Future<void> _verify() async {
    final otp = _currentOtp;
    if (otp.length < 6) {
      setState(() => _error = 'Please enter all 6 digits');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Accept any 6-digit code for demo (or validate against _validOtp)
    if (otp.length == 6) {
      final box = Hive.box('appData');
      await box.put('isLoggedIn', true);

      if (!mounted) return;

      final onboardingComplete = box.get('onboardingComplete', defaultValue: false);
      if (onboardingComplete) {
        context.go(AppRoutes.dashboard);
      } else {
        context.go(AppRoutes.carousel);
      }
    } else {
      setState(() {
        _loading = false;
        _error = 'Invalid OTP. Try: $_validOtp';
      });
    }
  }

  void _resendOtp() {
    for (final c in _controllers) c.clear();
    _focusNodes[0].requestFocus();
    setState(() => _error = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('OTP resent successfully!',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: _green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: MobileContainer(
        child: SafeArea(
          child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0F000000),
                      blurRadius: 12,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Top bar ──────────────────────────────────────────────
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: const Icon(Icons.arrow_back,
                              size: 20, color: _primary),
                        ),
                        const Expanded(
                          child: Text(
                            'Hustlr',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                      ],
                    ),

                    // ── Shield icon ───────────────────────────────────────────
                    const SizedBox(height: 28),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _lightGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.lock_rounded,
                          size: 40, color: _green),
                    ),

                    // ── Title ─────────────────────────────────────────────────
                    const SizedBox(height: 20),
                    const Text(
                      'Verify your number',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _primary,
                      ),
                    ),

                    // ── Subtitle ──────────────────────────────────────────────
                    const SizedBox(height: 8),
                    Text(
                      'Enter the 6-digit code sent to\n+91 ${widget.phone}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: _grey,
                        height: 1.5,
                      ),
                    ),

                    // ── OTP boxes ─────────────────────────────────────────────
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (i) => _OtpBox(
                        controller: _controllers[i],
                        focusNode: _focusNodes[i],
                        hasError: _error != null,
                        onChanged: (v) => _onDigitChanged(i, v),
                        onBackspace: () {
                          if (_controllers[i].text.isEmpty && i > 0) {
                            _focusNodes[i - 1].requestFocus();
                            _controllers[i - 1].clear();
                          }
                        },
                      )),
                    ),

                    // ── Error ─────────────────────────────────────────────────
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFD32F2F),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],

                    // ── Demo hint ─────────────────────────────────────────────
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _lightGreen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '💡 Demo: enter any 6 digits to proceed',
                        style: TextStyle(
                            fontSize: 12,
                            color: _green,
                            fontWeight: FontWeight.w600),
                      ),
                    ),

                    // ── Verify button ─────────────────────────────────────────
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _verify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text(
                                'Verify & Continue',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    // ── Resend ────────────────────────────────────────────────
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _resendOtp,
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(fontSize: 14, color: _grey),
                          children: [
                            TextSpan(text: "Didn't receive it? "),
                            TextSpan(
                              text: 'Resend OTP',
                              style: TextStyle(
                                color: _green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Floating help button ─────────────────────────────────────────
            Positioned(
              right: 20,
              bottom: 20,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _green,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _green.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.help_outline_rounded,
                    color: Colors.white, size: 24),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// ─── Single OTP digit box ─────────────────────────────────────────────────────
class _OtpBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.onChanged,
    required this.onBackspace,
  });

  @override
  State<_OtpBox> createState() => _OtpBoxState();
}

class _OtpBoxState extends State<_OtpBox> {
  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 52,
      child: KeyboardListener(
        focusNode: _keyboardFocusNode,
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              widget.controller.text.isEmpty) {
            widget.onBackspace();
          }
        },
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: widget.onChanged,
          style: AppTextStyles.heading2,
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: widget.hasError
                ? app_colors.lightRed
                : const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: widget.hasError ? app_colors.errorRed : _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: widget.hasError ? app_colors.errorRed : _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: widget.hasError ? app_colors.errorRed : _green,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }
}
