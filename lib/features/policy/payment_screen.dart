import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'razorpay_bridge_io.dart' if (dart.library.html) 'razorpay_bridge_web.dart'
    as razorpay_bridge;

import '../../blocs/claims/claims_bloc.dart';
import '../../blocs/claims/claims_event.dart';
import '../../blocs/policy/policy_bloc.dart';
import '../../blocs/policy/policy_event.dart';
import '../../core/router/app_router.dart';
import '../../services/api_service.dart';
import '../../services/app_events.dart';
import '../../services/storage_service.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic>? checkoutData;
  const PaymentScreen({super.key, this.checkoutData});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _loading = false;
  int _walletBalance = 0;
  bool _useRazorpay = true; // Razorpay vs Wallet toggle

  @override
  void initState() {
    super.initState();
    _loadBalance();
    if (!kIsWeb) {
      razorpay_bridge.initializeRazorpay(
        onPaymentSuccess: (paymentId) => _verifyAndCreatePolicy(paymentId),
        onPaymentError: (message) {
          if (!mounted) return;
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment failed: $message'),
              backgroundColor: Colors.red,
            ),
          );
        },
        onExternalWallet: (walletName) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('External wallet: $walletName'),
              backgroundColor: Colors.blue,
            ),
          );
        },
      );
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) razorpay_bridge.disposeRazorpay();
    super.dispose();
  }

  void _loadBalance() async {
    try {
      final userId = await StorageService.instance.getUserId();
      if (userId == null) return;
      final data = await ApiService.instance.getWallet(userId);
      if (!mounted) return;
      setState(() {
        _walletBalance = (data['balance'] as num?)?.toInt() ?? 0;
        if (_walletBalance < 0) _walletBalance = 0;
      });
    } catch (_) {}
  }

  void _openRazorpayCheckout() async {
    setState(() => _loading = true);
    
    final total = (widget.checkoutData?['total'] as num?)?.toInt() ?? 49;
    final planName = widget.checkoutData?['plan'] ?? 'Standard Shield';
    final userId = await StorageService.instance.getUserId();

    // Web fallback: use backend sandbox flow since razorpay_flutter callbacks
    // can be unreliable/not supported in Flutter web contexts.
    if (kIsWeb) {
      await _startWebSandboxPayment(
        total: total,
        planName: planName.toString(),
        userId: userId,
      );
      return;
    }
    
    // Razorpay test key (sandbox mode)
    const razorpayTestKey = 'rzp_test_SdS5pzapxUC7EU'; // Replace with your test key
    
    var options = {
      'key': razorpayTestKey,
      'amount': total * 100, // Razorpay expects amount in paise
      'currency': 'INR',
      'name': 'Hustlr Insurance',
      'description': '$planName Coverage',
      'image': 'https://hustlr.in/logo.png', // Your app logo
      'prefill': {
        'contact': '', // Can add user's phone
        'email': '',   // Can add user's email
      },
      'theme': {
        'color': '#2E7D32', // Your brand color
      },
      'notes': {
        'plan': planName,
        'user_id': userId ?? 'unknown',
      },
    };

    try {
      razorpay_bridge.openRazorpay(options);
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _startWebSandboxPayment({
    required int total,
    required String planName,
    required String? userId,
  }) async {
    try {
      final session = await ApiService.instance.createPaymentSandboxSession(
        provider: 'razorpay',
        amount: total,
        description: '$planName Coverage',
        userId: userId,
        metadata: {
          'plan': planName,
          'source': 'flutter_web_payment_screen',
        },
      );

      final sessionId = session['session_id']?.toString();
      if (sessionId == null || sessionId.isEmpty) {
        throw Exception('Sandbox session not created');
      }

      await ApiService.instance.confirmPaymentSandbox(
        provider: 'razorpay',
        amount: total,
        sessionId: sessionId,
        userId: userId,
        metadata: {
          'plan': planName,
          'simulated': true,
        },
      );

      await _verifyAndCreatePolicy('sandbox_$sessionId');
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Web sandbox payment failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _verifyAndCreatePolicy(String paymentId) async {
    try {
      final userId = await StorageService.instance.getUserId();
      if (userId == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final planName = widget.checkoutData?['plan'] ?? 'standard';
      final riders = widget.checkoutData?['riders'] as List<Map<String, dynamic>>?;

      final result = await ApiService.instance.createPolicy(
        userId: userId,
        planTier: planName.toString().toLowerCase().replaceAll(' shield', ''),
        riders: riders,
      );
      final policyId = result['policy']?['id'] as String?;
      if (policyId != null) {
        await StorageService.instance.savePolicyId(policyId);
      }

      AppEvents.instance.policyUpdated();
      AppEvents.instance.walletUpdated();
      if (mounted) {
        context.read<PolicyBloc>().add(LoadPolicy(userId));
        context.read<ClaimsBloc>().add(LoadClaims(userId));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating policy: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    setState(() => _loading = false);
    context.go(AppRoutes.dashboard);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Payment successful! Coverage is active.',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _payWithWallet() async {
    setState(() => _loading = true);
    try {
      final userId = await StorageService.instance.getUserId();
      if (userId == null) throw Exception('User not logged in');
      
      final total = (widget.checkoutData?['total'] as num?)?.toInt() ?? 49;
      
      if (_walletBalance < total) {
        throw Exception('Insufficient wallet balance');
      }

      // Deduct from wallet
      final planName = widget.checkoutData?['plan'] ?? 'standard';
      
      // Create policy
      final result = await ApiService.instance.createPolicy(
        userId: userId,
        planTier: planName.toString().toLowerCase().replaceAll(' shield', ''),
      );
      final policyId = result['policy']?['id'] as String?;
      if (policyId != null) {
        await StorageService.instance.savePolicyId(policyId);
      }

      AppEvents.instance.policyUpdated();
      AppEvents.instance.walletUpdated();
      if (mounted) {
        context.read<PolicyBloc>().add(LoadPolicy(userId));
        context.read<ClaimsBloc>().add(LoadClaims(userId));
      }

      if (!mounted) return;
      setState(() => _loading = false);
      context.go(AppRoutes.dashboard);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Payment successful! Coverage is active.',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.checkoutData?['total'] ?? 49;
    final planName = widget.checkoutData?['plan'] ?? 'Standard Shield';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, color: Colors.white),
        ),
        title: Column(
          children: [
            const Text(
              'Checkout',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Text(
              'hustlr.app',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Green header with amount
          Container(
            width: double.infinity,
            color: const Color(0xFF2E7D32),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: [
                Text(
                  'Rs $total.00',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  planName,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          
          // Payment method selection
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Payment method tabs
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _useRazorpay = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: _useRazorpay ? const Color(0xFF2E7D32) : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.payment,
                                  size: 18,
                                  color: _useRazorpay ? const Color(0xFF2E7D32) : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Card/UPI/Netbanking',
                                  style: TextStyle(
                                    fontWeight: _useRazorpay ? FontWeight.w600 : FontWeight.normal,
                                    color: _useRazorpay ? const Color(0xFF2E7D32) : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _useRazorpay = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: !_useRazorpay ? const Color(0xFF2E7D32) : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.account_balance_wallet,
                                  size: 18,
                                  color: !_useRazorpay ? const Color(0xFF2E7D32) : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Wallet (Rs $_walletBalance)',
                                  style: TextStyle(
                                    fontWeight: !_useRazorpay ? FontWeight.w600 : FontWeight.normal,
                                    color: !_useRazorpay ? const Color(0xFF2E7D32) : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  if (_useRazorpay) ...[
                    // Razorpay info
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.payment,
                            size: 48,
                            color: Color(0xFF2E7D32),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Razorpay Secure Checkout',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You will be redirected to Razorpay secure payment page',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'SANDBOX MODE - TEST PAYMENTS ONLY',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Supported methods
                    const Text(
                      'Supported payment methods:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _paymentMethodChip('Credit/Debit Card', Icons.credit_card),
                        _paymentMethodChip('UPI', Icons.account_balance),
                        _paymentMethodChip('Netbanking', Icons.language),
                        _paymentMethodChip('Wallets', Icons.account_balance_wallet),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Test info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, size: 18, color: Colors.orange.shade800),
                              const SizedBox(width: 8),
                              Text(
                                'Test Mode Info',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Use these test card details:\nCard: 5267 3181 8797 5449\nExpiry: Any future date\nCVV: Any 3 digits\nOTP: 1234',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.orange.shade900,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Wallet view
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.account_balance_wallet, size: 48, color: Color(0xFF2E7D32)),
                          const SizedBox(height: 12),
                          Text(
                            'Hustlr Wallet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Balance: Rs $_walletBalance',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Available for payment',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    if (_walletBalance < total)
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade100),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, size: 18, color: Colors.red.shade600),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Insufficient balance. Add Rs ${total - _walletBalance} more.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          
          // Pay button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading 
                      ? null 
                      : (_useRazorpay 
                          ? _openRazorpayCheckout 
                          : (_walletBalance < total ? null : _payWithWallet)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _useRazorpay ? 'Proceed to Pay Rs $total' : 'Pay with Wallet',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentMethodChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}
