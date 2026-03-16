import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/router/app_router.dart';
import '../../services/mock_data_service.dart';

// ─── Local Palette ────────────────────────────────────────────────────────────
const _bg        = Color(0xFFF0F4F0);
const _green     = Color(0xFF2E7D32);
const _lightGreen= Color(0xFFE8F5E9);
const _primary   = Color(0xFF1A1A2E);
const _grey      = Color(0xFF6B7280);
const _divider   = Color(0xFFE5E7EB);
const _blueLight = Color(0xFFE3F2FD);
const _blue      = Color(0xFF1565C0);

// ─── PaymentScreen ────────────────────────────────────────────────────────────
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int _selectedMethod = 0; // 0 = UPI, 1 = Wallet
  bool _loading = false;

  void _confirm() async {
    setState(() => _loading = true);

    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    // Update policy status in mock data
    final mockData = Provider.of<MockDataService>(context, listen: false);
    mockData.activePolicy = PolicyModel(
      plan: mockData.activePolicy.plan,
      premium: mockData.activePolicy.premium,
      status: 'ACTIVE',
      coverageStart: mockData.activePolicy.coverageStart,
      coverageEnd: mockData.activePolicy.coverageEnd,
      riders: mockData.activePolicy.riders,
      coverageDescription: mockData.activePolicy.coverageDescription,
    );

    setState(() => _loading = false);

    if (!mounted) return;

    context.go(AppRoutes.dashboard);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Coverage activated! You are protected\nMon 17 Mar – Sun 23 Mar',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, height: 1.4),
        ),
        backgroundColor: _green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(Icons.arrow_back, color: _primary),
        ),
        title: const Text(
          'Payment',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _primary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        child: Column(
          children: [
            // ── Order Summary Card ────────────────────────────────────────────
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Summary',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SummaryRow(label: 'Standard Shield', amount: '₹72/wk'),
                  const SizedBox(height: 12),
                  _SummaryRow(label: 'App Downtime Rider', amount: '₹12/wk'),
                  const SizedBox(height: 16),
                  Container(height: 1, color: _divider),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total weekly cost',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _primary,
                        ),
                      ),
                      const Text(
                        '₹84/wk',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Payment Method Card ────────────────────────────────────────────
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Method',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _primary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // UPI row
                  _PaymentMethodRow(
                    icon: Icons.account_balance_rounded,
                    title: 'UPI Payment',
                    selected: _selectedMethod == 0,
                    onTap: () => setState(() => _selectedMethod = 0),
                  ),

                  const SizedBox(height: 4),
                  Container(height: 1, color: _divider),
                  const SizedBox(height: 4),

                  // Wallet row
                  _PaymentMethodRow(
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'ShieldGig Wallet',
                    subtitle: 'Balance: ₹2,340',
                    selected: _selectedMethod == 1,
                    onTap: () => setState(() => _selectedMethod = 1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Important Note Card ────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _blueLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: _blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'i',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'This is a demo payment. No real money will be charged.',
                      style: TextStyle(
                        fontSize: 13,
                        color: _blue,
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

      // ── Sticky Confirm Button ──────────────────────────────────────────────
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _loading ? null : _confirm,
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
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Confirm & Activate Coverage →',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Reusable card wrapper ─────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─── Summary row (label + amount) ────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final String label;
  final String amount;
  const _SummaryRow({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, color: _grey)),
        Text(amount,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: _green)),
      ],
    );
  }
}

// ─── Payment method row ────────────────────────────────────────────────────────
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
                color: selected ? _lightGreen : const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  color: selected ? _green : _grey, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold, color: _primary)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: const TextStyle(fontSize: 12, color: _green)),
                  ],
                ],
              ),
            ),
            Radio<int>(
              value: selected ? 0 : 1,
              groupValue: 0,
              onChanged: (_) => onTap(),
              activeColor: _green,
              fillColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.selected)) return _green;
                return _grey;
              }),
            ),
          ],
        ),
      ),
    );
  }
}
