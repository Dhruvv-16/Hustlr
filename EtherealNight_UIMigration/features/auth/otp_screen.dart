import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/router/app_router.dart';
import '../../shared/widgets/primary_button.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';

class OTPScreen extends StatefulWidget {
  final String phone;
  const OTPScreen({super.key, required this.phone});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _loading = false;
  String? _error;
  static const _validOtp = '123456';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  String get _currentOtp => _controllers.map((c) => c.text).join();

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

    try {
      if (otp.length == 6) {
        final box = Hive.box('appData');
        await box.put('isLoggedIn', true);
        final phoneNumber = '+91${widget.phone}';
        await box.put('phone', phoneNumber);
        await StorageService.instance.savePhone(phoneNumber);

        // Check if user already exists
        final existingUser = await ApiService.getWorkerByPhone(phoneNumber);

        if (!mounted) return;

        if (existingUser != null) {
          // User exists, save context and navigate straight to dashboard
          final userId = existingUser['id'] as String;
          await StorageService.setUserId(userId);
          await StorageService.setOnboarded(true);
          await StorageService.instance.saveUserName(
              existingUser['name'] as String? ?? '');
          await StorageService.instance.saveUserCity(
              existingUser['city'] as String? ?? '');
          await StorageService.instance.saveUserZone(
              existingUser['zone'] as String? ?? '');
          await StorageService.setString(
              'userPlatform', existingUser['platform'] as String? ?? '');

          await box.put('userName', existingUser['name']);
          await box.put('userCity', existingUser['city']);
          await box.put('userZone', existingUser['zone']);
          await box.put('userPlatform', existingUser['platform']);
          await box.put('onboardingComplete', true);

          context.go(AppRoutes.dashboard);
        } else {
          // User does not exist, proceed to onboarding
          final onboardingComplete = box.get('onboardingComplete', defaultValue: false);
          if (onboardingComplete) {
            context.go(AppRoutes.dashboard); // Safety fallback
          } else {
            context.go(AppRoutes.carousel);
          }
        }
      } else {
        setState(() {
          _loading = false;
          _error = 'Invalid OTP. Try: $_validOtp';
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Connection failed. Please ensure the backend is running.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _resendOtp() {
    for (final c in _controllers) c.clear();
    _focusNodes[0].requestFocus();
    setState(() => _error = null);
    
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'OTP RESENT SUCCESSFULLY',
          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onPrimary),
        ),
        backgroundColor: theme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.canvasColor,
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Header Bar ─────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Row(
                      children: [
                        Icon(Icons.arrow_back, color: theme.colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Verification',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Hustlr',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 60),

              // ── Title & Intro ──────────────────────────────────────────
              Text(
                'SECURITY STEP',
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 12),
              Text(
                'Enter the code\nsent to your phone',
                style: theme.textTheme.displayMedium,
              ),
              const SizedBox(height: 16),
              RichText(
                text: TextSpan(
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                  children: [
                    const TextSpan(text: "We've sent a 6-digit verification code to\n"),
                    TextSpan(
                      text: '+91 ${widget.phone}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const TextSpan(text: '. Please enter it below to continue.'),
                  ],
                ),
              ),

              const SizedBox(height: 60),

              // ── Static OTP Tiles ──────────────────────────────────────
              Center(
                child: SizedBox(
                  height: 100, // Reduced height since no floating overlap needed
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (i) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5.0),
                        child: _StaticOtpBox(
                          index: i,
                          controller: _controllers[i],
                          focusNode: _focusNodes[i],
                          hasError: _error != null,
                          theme: theme,
                          isDark: isDark,
                          onChanged: (v) => _onDigitChanged(i, v),
                          onBackspace: () {
                            if (_controllers[i].text.isEmpty && i > 0) {
                              _focusNodes[i - 1].requestFocus();
                              _controllers[i - 1].clear();
                            }
                          },
                        ),
                      );
                    }),
                  ),
                ),
              ),

              // ── Error State ────────────────────────────────────────────
              if (_error != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      _error!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 48),

              // ── Resend Text ────────────────────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: _resendOtp,
                  child: Text(
                    "Didn't receive the code? Resend in 00:45",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 60),

              // ── Button ────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: PrimaryButton(
                      text: 'Verify & Continue',
                      onPressed: _loading ? null : _verify,
                      isLoading: _loading,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              
              // ── Legal Footer ───────────────────────────────────────────
              Center(
                child: Text(
                  'By continuing, you agree to Hustlr\'s professional\nconduct guidelines and secure transaction\nprotocols.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Static OTP Box Tile ───────────────────────────────────────────────────
class _StaticOtpBox extends StatefulWidget {
  final int index;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final ThemeData theme;
  final bool isDark;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;

  const _StaticOtpBox({
    required this.index,
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.theme,
    required this.isDark,
    required this.onChanged,
    required this.onBackspace,
  });

  @override
  State<_StaticOtpBox> createState() => _StaticOtpBoxState();
}

class _StaticOtpBoxState extends State<_StaticOtpBox> {
  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    widget.focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  void _onTextChanged() {
    if (mounted) setState(() {}); 
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    widget.focusNode.removeListener(_onFocusChanged);
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.isNotEmpty;
    final isFocused = widget.focusNode.hasFocus;
    
    final theme  = widget.theme;
    final isDark  = widget.isDark;
    final primary = theme.colorScheme.primary;
    final defaultBg = isDark ? const Color(0xFF1C1F1C) : Colors.white;

    Color borderColor;
    Color bgColor;
    double borderWidth;

    if (widget.hasError) {
      borderColor = theme.colorScheme.error;
      bgColor = defaultBg;
      borderWidth = 1.5;
    } else if (isFocused) {
      borderColor = primary;
      bgColor = isDark ? const Color(0xFF1C2A1C) : const Color(0xFFF9FFF9);
      borderWidth = 2.0;
    } else if (hasText) {
      borderColor = primary;
      bgColor = defaultBg;
      borderWidth = 1.5;
    } else {
      borderColor = isDark ? Colors.white.withOpacity(0.12) : const Color(0xFFE5E7EB);
      bgColor = defaultBg;
      borderWidth = 1.5;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 48,
      height: 56,
      decoration: BoxDecoration(
        color: bgColor, 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
        boxShadow: const [], // NO shadow, NO glow as requested
      ),
      child: KeyboardListener(
        focusNode: _keyboardFocusNode,
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              widget.controller.text.isEmpty) {
            widget.onBackspace();
          }
        },
        child: Center(
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: widget.onChanged,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: widget.theme.colorScheme.onSurface,
            ),
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ),
    );
  }
}
