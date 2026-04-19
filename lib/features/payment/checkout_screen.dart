import 'package:flutter/material.dart';

import 'wallet_tab_screen.dart';

// ─── Shared colour constants ──────────────────────────────────────────────────
const Color kDarkGreen  = Color(0xFF1B5E20);
const Color kLightGreen = Color(0xFFE8F5E9);
const Color kBorderGreen = Color(0xFFBBF7D0);
const Color kBgGrey     = Color(0xFFF0F4F0);
const Color kTextDark   = Color(0xFF0D1B0F);
const Color kTextGrey   = Color(0xFF6B7280);
const Color kTextLight  = Color(0xFF9CA3AF);
const Color kRed        = Color(0xFFEF4444);
const Color kRedLight   = Color(0xFFFEF2F2);
const Color kRedBorder  = Color(0xFFFECACA);

// ─── Checkout screen ─────────────────────────────────────────────────────────
class CheckoutScreen extends StatefulWidget {
  final double amount;
  final String planName;

  const CheckoutScreen({
    required this.amount,
    required this.planName,
    super.key,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgGrey,
      bottomNavigationBar: _tabController.index == 0
          ? _buildStickyBottom(
              amount: widget.amount,
              buttonLabel: 'Proceed to Pay ₹${widget.amount.toInt()} →',
              onTap: () {
                // Razorpay checkout will be triggered here
              },
            )
          : null,
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCardUpiTab(),
                WalletTabScreen(
                  amount: widget.amount,
                  onSwitchToCard: () {
                    _tabController.animateTo(0);
                    setState(() {}); // refresh bottomNavBar
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: kBgGrey,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 16,
        left: 16,
        right: 16,
      ),
      child: Column(
        children: [
          // Top nav row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back, color: kDarkGreen, size: 22),
              ),
              const Text(
                'Checkout',
                style: TextStyle(
                  color: kDarkGreen,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(Icons.lock, color: kDarkGreen, size: 20),
            ],
          ),
          const SizedBox(height: 24),

          // Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '₹${widget.amount.toInt()}',
                style: const TextStyle(
                  color: kDarkGreen,
                  fontSize: 52,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                '/week',
                style: TextStyle(color: kTextGrey, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Plan name
          Text(
            '${widget.planName} — Weekly Premium',
            style: const TextStyle(color: kTextDark, fontSize: 15),
          ),
          const SizedBox(height: 12),

          // Razorpay badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: kLightGreen,
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock, color: kDarkGreen, size: 12),
                SizedBox(width: 6),
                Text(
                  'RAZORPAY SECURED · TEST MODE',
                  style: TextStyle(
                    color: kDarkGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab bar ─────────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: kBgGrey,
      child: TabBar(
        controller: _tabController,
        labelColor: kDarkGreen,
        unselectedLabelColor: kTextGrey,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontSize: 14),
        indicatorColor: kDarkGreen,
        indicatorWeight: 2.5,
        onTap: (_) => setState(() {}), // refresh bottomNavBar
        tabs: const [
          Tab(text: 'Card / UPI / Netbank'),
          Tab(text: 'Hustlr Wallet'),
        ],
      ),
    );
  }

  // ── Card/UPI tab ─────────────────────────────────────────────────────────────
  Widget _buildCardUpiTab() {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // PAY WITH label
              const Text(
                'PAY WITH',
                style: TextStyle(
                  color: kTextGrey,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),

              // 2×2 payment method grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: const [
                  _PaymentMethodCard(
                    icon: Icons.credit_card,
                    title: 'Card',
                    subtitle: 'Visa, MC, RuPay',
                  ),
                  _PaymentMethodCard(
                    icon: Icons.qr_code_scanner,
                    title: 'UPI',
                    subtitle: 'GPay, PhonePe',
                  ),
                  _PaymentMethodCard(
                    icon: Icons.account_balance,
                    title: 'Net Banking',
                    subtitle: 'All Indian Banks',
                  ),
                  _PaymentMethodCard(
                    icon: Icons.account_balance_wallet,
                    title: 'Wallets',
                    subtitle: 'Paytm, MobiKwik',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Test Mode card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kLightGreen,
                  border: Border.all(color: kBorderGreen, width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: kDarkGreen, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Test Mode',
                            style: TextStyle(
                              color: kDarkGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Card: 5267 3181 8797 5449\n'
                            'Expiry: any future  CVV: any  OTP: 1234',
                            style: TextStyle(
                              color: kTextDark,
                              fontSize: 12,
                              height: 1.5,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom padding for sticky bar
              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }

  // ── Sticky bottom bar (Card/UPI tab only) ────────────────────────────────────
  Widget _buildStickyBottom({
    required double amount,
    required String buttonLabel,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Payable',
                style: TextStyle(color: kTextGrey, fontSize: 13),
              ),
              Text(
                '₹${amount.toInt()}',
                style: const TextStyle(
                  color: kTextDark,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: enabled ? onTap : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    enabled ? kDarkGreen : const Color(0xFFE5E7EB),
                foregroundColor:
                    enabled ? Colors.white : kTextLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (enabled) ...[
                    const Icon(Icons.lock, size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    buttonLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Payment method card widget ───────────────────────────────────────────────
class _PaymentMethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PaymentMethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: kDarkGreen, size: 26),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: kTextDark,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(color: kTextGrey, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
