import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/mock_data_service.dart';

import '../../core/constants/colors.dart' as app_colors;
import '../../core/router/app_router.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/mobile_container.dart';

// ─── Local Palette (mapping to global tokens) ──────────────────────────────────
const _bgScreen   = app_colors.background;
const _green      = app_colors.primaryGreen;
const _lightGreen = app_colors.lightGreen;
const _red        = app_colors.errorRed;
const _lightRed   = app_colors.lightRed;
const _blue       = Color(0xFF1976D2);
const _lightBlue  = Color(0xFFE3F2FD);
const _primary    = app_colors.textPrimary;
const _grey       = app_colors.textSecondary;
const _hint       = app_colors.textHint;
const _divider    = Color(0xFFE5E7EB);
const _cardWhite  = app_colors.cardWhite;

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgScreen,
      appBar: AppBar(
        backgroundColor: _bgScreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: _primary),
          onPressed: () {},
        ),
        title: const Text(
          'Wallet',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _primary,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_rounded, color: _primary),
                  onPressed: () {},
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: _red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: MobileContainer(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          child: Column(
          children: [
            _BalanceCard(),
            const SizedBox(height: 16),
            _SavingsInsightCard(),
            const SizedBox(height: 16),
            const _AnalyticsButton(),
            const SizedBox(height: 24),
            _WeeklySummarySection(),
            const SizedBox(height: 24),
            _InsuranceTransactionsSection(),
            const SizedBox(height: 24),
            _SupportCard(),
          ],
        ),
      ),
      ),
    );
  }
}

// ─── Balance Card ─────────────────────────────────────────────────────────────
class _BalanceCard extends StatelessWidget {
  const _BalanceCard();

  @override
  Widget build(BuildContext context) {
    final mockData = Provider.of<MockDataService>(context);
    final formattedBalance = mockData.walletBalance.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
      (m) => '${m[1]},'
    );

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _green,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          // Watermark Shield
          Positioned(
            right: -20,
            bottom: -30,
            child: Icon(
              Icons.shield_rounded,
              size: 160,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Available Balance',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    Icon(
                      Icons.contactless_outlined,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '₹$formattedBalance',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 52,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => _showWithdrawBottomSheet(context, mockData),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _green,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Withdraw to UPI',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _green,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 16, color: _green),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Savings Insight ──────────────────────────────────────────────────────────
class _SavingsInsightCard extends StatelessWidget {
  const _SavingsInsightCard();

  @override
  Widget build(BuildContext context) {
    final mockData = Provider.of<MockDataService>(context);
    final formattedSavings = mockData.monthlySavings.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: const Border(left: BorderSide(color: _green, width: 3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: _lightGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.savings_rounded, color: _green, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SAVINGS INSIGHT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _grey,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'You saved ₹$formattedSavings this month',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Analytics Navigation ─────────────────────────────────────────────────────
// ─── Analytics Navigation ─────────────────────────────────────────────────────
class _AnalyticsButton extends StatelessWidget {
  const _AnalyticsButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.analytics),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2D6A2D).withOpacity(0.3)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Icon(Icons.bar_chart, color: Color(0xFF2D6A2D)),
              SizedBox(width: 8),
              Text('See Analytics', style: TextStyle(
                  color: Color(0xFF2D6A2D), fontWeight: FontWeight.w600)),
            ]),
            Icon(Icons.chevron_right, color: Color(0xFF2D6A2D)),
          ],
        ),
      ),
    );
  }
}

// ─── Weekly Summary ───────────────────────────────────────────────────────────
class _WeeklySummarySection extends StatelessWidget {
  const _WeeklySummarySection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _BarIcon(),
            const SizedBox(width: 8),
            const Text(
              'Weekly Summary',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildCard(
          icon: Icons.account_balance_wallet_rounded,
          iconBg: _lightGreen,
          iconColor: _green,
          title: 'Insurance Payout',
          date: 'Mar 12, 2026',
          amount: '+₹300',
          amountColor: _green,
        ),
        const SizedBox(height: 12),
        _buildCard(
          icon: Icons.shield_rounded,
          iconBg: _lightRed,
          iconColor: _red,
          title: 'Policy Premium',
          date: 'Mar 10, 2026',
          amount: '-₹49',
          amountColor: _red,
        ),
      ],
    );
  }

  Widget _buildCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String date,
    required String amount,
    required Color amountColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: const TextStyle(fontSize: 12, color: _grey),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}

// A custom icon consisting of 4 vertical green bars of varying heights
class _BarIcon extends StatelessWidget {
  const _BarIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 16,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _bar(10),
          const SizedBox(width: 2),
          _bar(16),
          const SizedBox(width: 2),
          _bar(8),
          const SizedBox(width: 2),
          _bar(12),
        ],
      ),
    );
  }

  Widget _bar(double height) {
    return Container(
      width: 3,
      height: height,
      decoration: BoxDecoration(
        color: _green,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

// ─── Insurance Transactions ───────────────────────────────────────────────────
class _InsuranceTransactionsSection extends StatelessWidget {
  const _InsuranceTransactionsSection();

  @override
  Widget build(BuildContext context) {
    final mockData = Provider.of<MockDataService>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history_rounded, size: 20, color: _green),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Insurance Transactions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _primary,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: const Text(
                'See All',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _green,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        Container(
          decoration: BoxDecoration(
            color: _cardWhite,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: mockData.transactions.length,
            separatorBuilder: (context, index) => const Padding(
              padding: EdgeInsets.only(left: 64),
              child: Divider(color: _divider, height: 1),
            ),
            itemBuilder: (context, index) {
              final tx = mockData.transactions[index];
              return _buildTransactionRow(
                icon: tx['type'] == 'credit' ? Icons.card_giftcard_rounded : Icons.shield_rounded,
                iconColor: tx['type'] == 'credit' ? _blue : const Color(0xFF607D8B),
                iconBg: tx['type'] == 'credit' ? _lightBlue : const Color(0xFFECEFF1),
                title: tx['title'],
                subtitle: tx['date']! + ' • ' + tx['subtitle']!,
                amount: (tx['type'] == 'credit' ? '+' : '-') + '₹${tx['amount']}',
                amountColor: tx['type'] == 'credit' ? _green : _red,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required String amount,
    required Color amountColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: _grey),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Support Card ─────────────────────────────────────────────────────────────
class _SupportCard extends StatelessWidget {
  const _SupportCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _green,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Questions about a payout?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _primary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Text(
                      'Chat with us',
                      style: TextStyle(
                        fontSize: 13,
                        color: _green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: _green,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── UPI Withdrawal Flow ──────────────────────────────────────────────────────
void _showWithdrawBottomSheet(BuildContext context, MockDataService mockData) {
  if (mockData.walletBalance <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No balance available to withdraw')),
    );
    return;
  }

  final upiController = TextEditingController(text: 'karthik.r@ybl');

  final formattedBalance = mockData.walletBalance.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24, right: 24, top: 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Withdraw to UPI',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _primary)),
            const SizedBox(height: 8),
            Text('Enter your UPI ID to receive \u20b9$formattedBalance',
                style: const TextStyle(fontSize: 14, color: _grey)),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                color: _bgScreen, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _divider),
              ),
              child: TextField(
                controller: upiController,
                decoration: const InputDecoration(
                  labelText: 'UPI ID',
                  hintText: 'yourname@upi',
                  prefixIcon: Icon(Icons.account_balance_wallet_rounded, color: _green),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: _lightGreen, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _green.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('\u20b9$formattedBalance',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _green)),
                  const SizedBox(height: 2),
                  const Text('Full available balance',
                      style: TextStyle(fontSize: 12, color: _green)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _processWithdrawal(context, mockData, upiController.text);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
                child: const Text('Initiate Transfer \u2192',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel',
                    style: TextStyle(color: _grey, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    },
  );
}

void _processWithdrawal(BuildContext context, MockDataService mockData, String upiId) {
  final amount = mockData.walletBalance;

  showDialog(
    context: context,
    barrierColor: Colors.white.withOpacity(0.98),
    barrierDismissible: false,
    builder: (context) => const Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_green)),
            SizedBox(height: 24),
            Text('Initiating transfer...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primary)),
            SizedBox(height: 8),
            Text('Connecting to UPI network', style: TextStyle(fontSize: 14, color: _grey)),
            SizedBox(height: 8),
            Text('Powered by Razorpay', style: TextStyle(fontSize: 12, color: _grey)),
          ],
        ),
      ),
    ),
  );

  Future.delayed(const Duration(seconds: 2), () {
    if (!context.mounted) return;
    Navigator.pop(context); // close processing

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final formattedBalance = amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
          
        return Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100, height: 100,
                    decoration: const BoxDecoration(color: Color(0xFF2D6A2D), shape: BoxShape.circle),
                    child: const Icon(Icons.check, color: Colors.white, size: 60),
                  ),
                  const SizedBox(height: 24),
                  const Text('Transfer Initiated!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('₹$formattedBalance → $upiId', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 8),
                  const Text('Funds will reflect within 2 hours', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
                    child: const Column(
                      children: [
                        Text('Reference Number', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Text('UPI/REF/2603/HUSTLR847291', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        mockData.withdrawToUPI(amount, upiId); // zero out balance and add transaction
                        while (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D6A2D),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  });
}
