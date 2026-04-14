import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

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
  String _sandboxMode = 'mock_sandbox';
  
  // Card input controllers
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvcController = TextEditingController();
  final TextEditingController _cardholderController = TextEditingController();
  
  bool _useCard = true; // Card vs Wallet toggle

  @override
  void initState() {
    super.initState();
    _loadBalance();
    _loadSandboxConfig();
    // Pre-fill test card for sandbox
    _cardNumberController.text = '4242 4242 4242 4242';
    _expiryController.text = '12/25';
    _cvcController.text = '123';
  }
  
  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    _cardholderController.dispose();
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

  void _loadSandboxConfig() async {
    try {
      final data = await ApiService.instance.getPaymentSandboxConfig();
      final providers = (data['providers'] as Map?)?.cast<String, dynamic>() ?? const {};
      final paypal = (providers['paypal'] as Map?)?.cast<String, dynamic>() ?? const {};
      if (!mounted) return;
      setState(() {
        _sandboxMode = (paypal['mode'] as String?) ?? 'mock_sandbox';
      });
    } catch (_) {}
  }

  String get _selectedProvider => _useCard ? 'card' : 'wallet';

  void _confirm() async {
    setState(() => _loading = true);
    try {
      final userId = await StorageService.instance.getUserId();
      if (userId != null) {
        final planName = widget.checkoutData?['plan'] ?? 'standard';
        final total = (widget.checkoutData?['total'] as num?)?.toInt() ?? 49;
        
        if (!_useCard && _walletBalance < total) {
          throw Exception('Insufficient wallet balance');
        }

        final session = await ApiService.instance.createPaymentSandboxSession(
          provider: _selectedProvider,
          amount: total,
          description: 'Hustlr coverage activation',
          userId: userId,
          metadata: {'plan': planName, 'sandbox_mode': _sandboxMode},
        );

        final sessionId = session['session_id'] as String? ?? 'sandbox_session';
        final payment = await ApiService.instance.confirmPaymentSandbox(
          provider: _selectedProvider,
          amount: total,
          sessionId: sessionId,
          userId: userId,
          metadata: {'plan': planName, 'sandbox_mode': _sandboxMode},
        );
        if (payment['success'] != true) {
          throw Exception('Payment failed');
        }

        final result = await ApiService.instance.createPolicy(
          userId: userId,
          planTier: planName.toString().toLowerCase().replaceAll(' shield', ''),
        );
        final policyId = result['policy']?['id'] as String?;
        if (policyId != null) {
          await StorageService.instance.savePolicyId(policyId);
          AppEvents.instance.policyUpdated();
          AppEvents.instance.walletUpdated();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment error: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _loading = false);
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
          onTap: () => Navigator.of(context).pop(),
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
          
          // Payment form
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
                          onTap: () => setState(() => _useCard = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: _useCard ? const Color(0xFF2E7D32) : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.credit_card,
                                  size: 18,
                                  color: _useCard ? const Color(0xFF2E7D32) : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Card',
                                  style: TextStyle(
                                    fontWeight: _useCard ? FontWeight.w600 : FontWeight.normal,
                                    color: _useCard ? const Color(0xFF2E7D32) : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _useCard = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: !_useCard ? const Color(0xFF2E7D32) : Colors.transparent,
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
                                  color: !_useCard ? const Color(0xFF2E7D32) : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Wallet (Rs $_walletBalance)',
                                  style: TextStyle(
                                    fontWeight: !_useCard ? FontWeight.w600 : FontWeight.normal,
                                    color: !_useCard ? const Color(0xFF2E7D32) : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  if (_useCard) ...[
                    // Card form
                    const Text(
                      'Card information',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Card number field
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _cardNumberController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(19),
                              _CardNumberFormatter(),
                            ],
                            decoration: InputDecoration(
                              hintText: '4242 4242 4242 4242',
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
                              suffixIcon: const Padding(
                                padding: EdgeInsets.all(12),
                                child: Icon(Icons.credit_card, color: Colors.grey),
                              ),
                            ),
                          ),
                          Divider(height: 1, color: Colors.grey.shade300),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _expiryController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(4),
                                    _ExpiryDateFormatter(),
                                  ],
                                  decoration: InputDecoration(
                                    hintText: 'MM / YY',
                                    hintStyle: TextStyle(color: Colors.grey.shade400),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(16),
                                  ),
                                ),
                              ),
                              Container(width: 1, height: 48, color: Colors.grey.shade300),
                              Expanded(
                                child: TextField(
                                  controller: _cvcController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(3),
                                  ],
                                  obscureText: true,
                                  decoration: InputDecoration(
                                    hintText: 'CVC',
                                    hintStyle: TextStyle(color: Colors.grey.shade400),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(16),
                                    suffixIcon: const Icon(Icons.credit_card, size: 20, color: Colors.grey),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Cardholder name
                    const Text(
                      'Cardholder name',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _cardholderController,
                        decoration: InputDecoration(
                          hintText: 'Full name on card',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Test card hint
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 18, color: Colors.blue.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Test card: 4242 4242 4242 4242, any future date, any CVC',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade800,
                              ),
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
                  onPressed: (_loading || (!_useCard && _walletBalance < total)) 
                      ? null 
                      : _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
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
                          _useCard ? 'Pay Rs $total' : 'Pay with Wallet',
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
}

// Card number formatter (adds spaces every 4 digits)
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;
    if (text.isEmpty) return newValue;
    
    text = text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i + 1) % 4 == 0 && i != text.length - 1) {
        buffer.write(' ');
      }
    }
    
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

// Expiry date formatter (adds / after MM)
class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll('/', '');
    if (text.isEmpty) return newValue;
    
    if (text.length >= 2) {
      text = '${text.substring(0, 2)}/${text.substring(2)}';
    }
    
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
