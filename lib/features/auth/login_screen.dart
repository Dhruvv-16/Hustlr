import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../shared/widgets/mobile_container.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  // bool _loading = false; // Removed as unused

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _sendOtp() {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please enter a phone number',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFFD32F2F),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    context.push('${AppRoutes.otp}?phone=${Uri.encodeComponent(phone)}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F0),
      body: Stack(
        children: [
          // ── Scrollable content ─────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
                child: _MainCard(
                  phoneController: _phoneController,
                  onSendOtp: _sendOtp,
                ),
              ),
            ),
          ),

          // ── Floating help button ────────────────────────────────────────────
          Positioned(
            right: 20,
            bottom: 20,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.headset_mic_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Main white card ─────────────────────────────────────────────────────────
class _MainCard extends StatelessWidget {
  final TextEditingController phoneController;
  final VoidCallback onSendOtp;

  const _MainCard({
    required this.phoneController,
    required this.onSendOtp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          // ── Top bar: back ← | Hustlr | spacer ──────────────────────────
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Icon(Icons.arrow_back, size: 20, color: Colors.black),
              ),
              const Expanded(
                child: Text(
                  'Hustlr',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),
              const SizedBox(width: 20), // balance the back arrow
            ],
          ),

          // ── Icon container ─────────────────────────────────────────────────
          const SizedBox(height: 24),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.shield_rounded,
              size: 40,
              color: Color(0xFF2E7D32),
            ),
          ),

          // ── Title ──────────────────────────────────────────────────────────
          const SizedBox(height: 20),
          const Text(
            'Welcome to\nHustlr',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
              height: 1.3,
            ),
          ),

          // ── Subtitle ───────────────────────────────────────────────────────
          const SizedBox(height: 8),
          const Text(
            'Enter your phone number to continue',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF6B7280),
            ),
          ),

          // ── Phone Number label ─────────────────────────────────────────────
          const SizedBox(height: 24),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Phone Number',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ),

          // ── Phone input field ──────────────────────────────────────────────
          const SizedBox(height: 8),
          _PhoneField(controller: phoneController),

          // ── Send OTP button ────────────────────────────────────────────────
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: onSendOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: const Text(
                'Send OTP',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // ── For Zepto delivery partners ───────────────────────────────────
          const SizedBox(height: 16),
          const Text(
            'For Q-commerce delivery partners (Zepto / Blinkit)',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF6B7280),
            ),
          ),

          // ── Help line ──────────────────────────────────────────────────────
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.phone_rounded, size: 14, color: Color(0xFF9CA3AF)),
              SizedBox(width: 4),
              Text(
                'Need help? Call 1800-SHIELD',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),

          // ── Terms ──────────────────────────────────────────────────────────
          const SizedBox(height: 24),
          const Text(
            'By signing in, you agree to our Terms and Privacy Policy',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF9CA3AF),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          // ── Invite Code / Waitlist logic ───────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {},
                child: const Text('Join Waitlist', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              const Text('•', style: TextStyle(color: Color(0xFF9CA3AF))),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {},
                child: const Text('Have Invite Code?', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Custom phone input field ─────────────────────────────────────────────────
class _PhoneField extends StatelessWidget {
  final TextEditingController controller;

  const _PhoneField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Row(
        children: [
          // +91 prefix
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '+91',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          // Divider
          Container(
            width: 1,
            height: 24,
            color: const Color(0xFFE5E7EB),
          ),
          // Text input
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                hintText: '00000 00000',
                hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                counterText: '',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              ),
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
