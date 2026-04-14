import 'package:flutter/material.dart';
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
  int _selectedMethod = 0; // 0 = PayPal sandbox, 1 = UPI demo, 2 = Wallet
  bool _loading = false;
  int _walletBalance = 0;
  String _sandboxMode = 'mock_sandbox';

  @override
  void initState() {
    super.initState();
    _loadBalance();
    _loadSandboxConfig();
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

  String get _selectedProvider {
    switch (_selectedMethod) {
      case 0:
        return 'paypal';
      case 1:
        return 'upi';
      case 2:
        return 'wallet';
      default:
        return 'stripe';
    }
  }

  void _confirm() async {
    setState(() => _loading = true);
    try {
      final userId = await StorageService.instance.getUserId();
      if (userId != null) {
        final planName = widget.checkoutData?['plan'] ?? 'standard';
        final total = (widget.checkoutData?['total'] as num?)?.toInt() ?? 49;
        if (_selectedProvider == 'wallet' && _walletBalance < total) {
          throw Exception('Insufficient wallet balance for this sandbox payment');
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
          throw Exception('Sandbox payment failed');
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
              'Payment sandbox error: $e',
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

    final green = Theme.of(context).colorScheme.primary;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _selectedProvider == 'paypal'
              ? 'PayPal sandbox payment confirmed. Coverage is active.'
              : 'Sandbox payment confirmed. Coverage is active.',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
        backgroundColor: green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = theme.scaffoldBackgroundColor;
    final primaryText = theme.colorScheme.onSurface;
    final green = theme.colorScheme.primary;
    final divider = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE5E7EB);

    final planName = widget.checkoutData?['plan'] ?? 'Standard Shield';
    final planCost = widget.checkoutData?['planCost'] ?? 49;
    final rawRiders = widget.checkoutData?['riders'];
    final riders = <Map<String, dynamic>>[];
    if (rawRiders is List) {
      for (final rider in rawRiders) {
        if (rider is Map) riders.add(Map<String, dynamic>.from(rider));
      }
    }
    final total = widget.checkoutData?['total'] ?? 49;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF141614) : Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Icon(Icons.arrow_back, color: primaryText),
        ),
        title: Text(
          'Payment',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: primaryText,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Column(
          children: [
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Summary',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SummaryRow(label: planName, amount: 'Rs $planCost/wk'),
                  if (riders.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ...riders.map(
                      (rider) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _SummaryRow(
                          label: '${rider['name']}',
                          amount: 'Rs ${rider['cost']}/wk',
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Container(height: 1, color: divider),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total weekly cost',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: primaryText,
                        ),
                      ),
                      Text(
                        'Rs $total/wk',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Method',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _PaymentMethodRow(
                    icon: Icons.credit_card_rounded,
                    title: 'PayPal Sandbox',
                    subtitle: _sandboxMode == 'sandbox_keys_present'
                        ? 'Test keys configured'
                        : 'Recommended mock sandbox',
                    selected: _selectedMethod == 0,
                    onTap: () => setState(() => _selectedMethod = 0),
                  ),
                  const SizedBox(height: 4),
                  Container(height: 1, color: divider),
                  const SizedBox(height: 4),
                  _PaymentMethodRow(
                    icon: Icons.account_balance_rounded,
                    title: 'UPI Demo',
                    subtitle: 'Safe fallback without gateway onboarding',
                    selected: _selectedMethod == 1,
                    onTap: () => setState(() => _selectedMethod = 1),
                  ),
                  const SizedBox(height: 4),
                  Container(height: 1, color: divider),
                  const SizedBox(height: 4),
                  _PaymentMethodRow(
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'Hustlr Wallet',
                    subtitle: 'Balance: Rs ${_formatCurrency(_walletBalance)}',
                    selected: _selectedMethod == 2,
                    onTap: () => setState(() => _selectedMethod = 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? green.withOpacity(0.05) : const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? green.withOpacity(0.2) : Colors.transparent,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark ? green.withOpacity(0.2) : const Color(0xFF1565C0),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        'i',
                        style: TextStyle(
                          color: isDark ? green : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Sandbox checkout is enabled. PayPal is the recommended test path; Razorpay is not required for this demo.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? theme.colorScheme.onSurface.withOpacity(0.8)
                            : const Color(0xFF1565C0),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _loading ? null : _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: isDark ? const Color(0xFF0A0B0A) : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: _loading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? const Color(0xFF0A0B0A) : Colors.white,
                        ),
                      ),
                    )
                  : const Text(
                      'Confirm & Activate Coverage ->',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatCurrency(int amount) {
    final raw = amount.toString();
    return raw.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
        border: isDark ? Border.all(color: Colors.white.withOpacity(0.05)) : null,
      ),
      child: child,
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String amount;
  const _SummaryRow({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withOpacity(0.6)),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

class _PaymentMethodRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentMethodRow({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final green = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected
                    ? green.withOpacity(0.1)
                    : (isDark ? const Color(0xFF2A2D2A) : const Color(0xFFF3F4F6)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: selected ? green : onSurface.withOpacity(0.6),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(fontSize: 12, color: green),
                    ),
                  ],
                ],
              ),
            ),
            Radio<int>(
              value: selected ? 0 : 1,
              groupValue: 0,
              onChanged: (_) => onTap(),
              activeColor: green,
              fillColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.selected)) return green;
                return onSurface.withOpacity(0.5);
              }),
            ),
          ],
        ),
      ),
    );
  }
}
