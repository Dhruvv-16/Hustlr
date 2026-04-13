import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/demo_state_service.dart';

import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../core/router/app_router.dart';
import 'package:go_router/go_router.dart';
import '../../services/app_events.dart';
import '../../shared/widgets/mobile_container.dart';

import '../../l10n/app_localizations.dart';
import '../../services/notification_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool _loading = true;
  String? _error;

  int _balance = 0;
  int _totalPayouts = 0;
  int _totalPremiums = 0;
  List<Map<String, dynamic>> _transactions = [];
  Map<String, dynamic>? _cashbackStatus;

  bool _isMock = false;

  @override
  void initState() {
    super.initState();
    _loadWallet();
    
    // Refresh when claims or policy events fire
    AppEvents.instance.onWalletUpdated.listen((_) => _loadWallet());
    AppEvents.instance.onClaimUpdated.listen((_) => _loadWallet());
  }

  Future<void> _loadWallet() async {
    final userId = await StorageService.instance.getUserId();
    if (userId == null) {
      _loadMockWallet();
      return;
    }
    
    setState(() { _loading = true; _error = null; });
    
    try {
      final res = await ApiService.instance.getWallet(userId);
      Map<String, dynamic>? cashbackData;
      try {
        cashbackData = await ApiService.instance.getCashbackStatus(userId);
      } catch (_) {}
      
      setState(() {
        _balance        = (res['balance'] ?? 0) + DemoStateService.instance.walletBalance;
        _totalPayouts   = (res['total_payouts'] ?? 0) + DemoStateService.instance.totalPayouts;
        _totalPremiums  = res['total_premiums'] ?? 0;
        
        final combinedTx = [
          ...DemoStateService.instance.transactions,
          ...(res['transactions'] ?? [])
        ];
        
        // sort combinedTx by created_at descending
        combinedTx.sort((a, b) {
          final dateA = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
          final dateB = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
          return dateB.compareTo(dateA);
        });

        _transactions   = List<Map<String, dynamic>>.from(combinedTx);
        _cashbackStatus = cashbackData;
        _loading        = false;
        _isMock         = res['_mock'] == true;
      });
      
    } catch (e) {
      print('[Wallet] API error: $e — loading mock');
      _loadMockWallet();
    }
  }

  void _loadMockWallet() {
    setState(() {
      _balance       = 1250;
      _totalPayouts  = 450;
      _totalPremiums = 196;
      _loading       = false;
      _isMock        = true;
      _transactions  = [
        {
          'id': 'TXN_001',
          'description': 'Heavy Rain Payout (70%)',
          'amount': 84,
          'type': 'credit',
          'category': 'payout_tranche1',
          'created_at': DateTime.now()
            .subtract(const Duration(hours: 2)).toIso8601String(),
        },
        {
          'id': 'TXN_002',
          'description': 'Standard Shield Premium',
          'amount': -49,
          'type': 'debit',
          'category': 'premium',
          'created_at': DateTime.now()
            .subtract(const Duration(days: 7)).toIso8601String(),
        },
        {
          'id': 'TXN_003',
          'description': 'Platform Downtime Payout (70%)',
          'amount': 98,
          'type': 'credit',
          'category': 'payout_tranche1',
          'created_at': DateTime.now()
            .subtract(const Duration(days: 3)).toIso8601String(),
        },
      ];
    });
  }

  void _handleNavTap(BuildContext context, int index) {
    switch (index) {
      case 0: context.go('/dashboard'); break;
      case 1: context.go('/policy'); break;
      case 2: context.go('/claims'); break;
      case 3: break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final bgScreen = isDark ? const Color(0xFF0a0b0a) : const Color(0xFFF4F6F4);
    final green    = isDark ? const Color(0xFF3FFF8B) : const Color(0xFF2E7D32);
    final red      = isDark ? const Color(0xFFFF5252) : const Color(0xFFB71C1C);
    final primary  = isDark ? Colors.white : const Color(0xFF0D1B0F);
    final l10n     = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: bgScreen,
      appBar: AppBar(
        backgroundColor: bgScreen,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          l10n.wallet_title,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primary),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.notifications_rounded, color: primary),
                  onPressed: () async {
                    NotificationService.instance.markAllRead();
                    await context.push(AppRoutes.notifications);
                    setState(() {});
                  },
                ),
                if (NotificationService.instance.unreadCount > 0)
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(color: red, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: MobileContainer(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _ErrorState(error: _error!, onRetry: _loadWallet)
                      : RefreshIndicator(
                          onRefresh: _loadWallet,
                          color: green,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                            child: Column(
                              children: [
                                _BalanceCard(
                                  balance: _balance,
                                  totalPayouts: _totalPayouts,
                                  totalPremiums: _totalPremiums,
                                  onRefresh: _loadWallet,
                                ),
                                const SizedBox(height: 16),
                                _SavingsInsightCard(totalPayouts: _totalPayouts, totalPremiums: _totalPremiums),
                                const SizedBox(height: 16),
                                const _AnalyticsButton(),
                                const SizedBox(height: 24),
                                _WeeklySummarySection(transactions: _transactions),
                                const SizedBox(height: 24),
                                if (_cashbackStatus != null) ...[
                                  _CashbackStatusCard(status: _cashbackStatus!),
                                  const SizedBox(height: 24),
                                ],
                                _InsuranceTransactionsSection(transactions: _transactions),
                                const SizedBox(height: 24),
                                const _SupportCard(),
                              ],
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

// ─── Error State ───────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final green   = isDark ? const Color(0xFF3FFF8B) : const Color(0xFF2E7D32);
    final primary = isDark ? Colors.white : const Color(0xFF0D1B0F);
    final grey    = isDark ? const Color(0xFF91938d) : const Color(0xFF8FAE8B);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 64, color: grey),
            const SizedBox(height: 16),
            Text('Could not load wallet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primary)),
            const SizedBox(height: 8),
            Text(error, style: TextStyle(fontSize: 12, color: grey), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: isDark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Balance Card ─────────────────────────────────────────────────────────────
class _BalanceCard extends StatelessWidget {
  final int balance;
  final int totalPayouts;
  final int totalPremiums;
  final VoidCallback onRefresh;

  const _BalanceCard({
    required this.balance,
    required this.totalPayouts,
    required this.totalPremiums,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final green = isDark ? const Color(0xFF3FFF8B) : const Color(0xFF2E7D32);
    final displayBalance = balance < 0 ? 0 : balance;
    final formattedBalance = '₹${displayBalance.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: green,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.wallet_balance, style: const TextStyle(color: Colors.white, fontSize: 13)),
                Icon(Icons.contactless_outlined, color: Colors.white.withValues(alpha: 0.8), size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              formattedBalance,
              style: const TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.bold, height: 1.1),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => _showWithdrawBottomSheet(context, balance),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: green,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(l10n.wallet_withdraw,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: green)),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 16, color: green),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Savings Insight ──────────────────────────────────────────────────────────
class _SavingsInsightCard extends StatelessWidget {
  final int totalPayouts;
  final int totalPremiums;

  const _SavingsInsightCard({required this.totalPayouts, required this.totalPremiums});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final green = isDark ? const Color(0xFF3FFF8B) : const Color(0xFF2E7D32);
    final lightGreen = isDark ? const Color(0xFF003D2A) : const Color(0xFFE8F5E9);
    final cardWhite = isDark ? const Color(0xFF1c1f1c) : Colors.white;
    final primary = isDark ? Colors.white : const Color(0xFF0D1B0F);
    final grey = isDark ? const Color(0xFF91938d) : const Color(0xFF8FAE8B);
    final netSavings = totalPayouts - totalPremiums;
    final formattedSavings = '${netSavings < 0 ? '-' : ''}${netSavings.abs().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: green, width: 3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: lightGreen, shape: BoxShape.circle),
            child: Icon(Icons.savings_rounded, color: green, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.wallet_smart_savings.toUpperCase(),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: grey, letterSpacing: 1.0),
                ),
                const SizedBox(height: 2),
                Text(
                  '${l10n.wallet_you_saved} ₹$formattedSavings',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primary),
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
class _AnalyticsButton extends StatelessWidget {
  const _AnalyticsButton();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final green = isDark ? const Color(0xFF3FFF8B) : const Color(0xFF2E7D32);
    final cardBg = isDark ? const Color(0xFF1c1f1c) : Colors.white;
    final borderColor = isDark ? green.withOpacity(0.3) : const Color(0xFF2D6A2D).withOpacity(0.3);
    final iconColor = isDark ? green : const Color(0xFF2D6A2D);

    return GestureDetector(
      onTap: () => context.push(AppRoutes.analytics),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Icon(Icons.bar_chart, color: iconColor),
              const SizedBox(width: 8),
              Text(l10n.wallet_see_analytics, style: TextStyle(color: iconColor, fontWeight: FontWeight.w600)),
            ]),
            Icon(Icons.chevron_right, color: iconColor),
          ],
        ),
      ),
    );
  }
}

// ─── Weekly Summary ───────────────────────────────────────────────────────────
class _WeeklySummarySection extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  const _WeeklySummarySection({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final green = isDark ? const Color(0xFF3FFF8B) : const Color(0xFF2E7D32);
    final lightGreen = isDark ? const Color(0xFF003D2A) : const Color(0xFFE8F5E9);
    final lightRed = isDark ? const Color(0xFF4A0000) : const Color(0xFFFFEBEE);
    final red = isDark ? const Color(0xFFFF6B6B) : const Color(0xFFB71C1C);
    final cardWhite = isDark ? const Color(0xFF1c1f1c) : Colors.white;
    final primary = isDark ? Colors.white : const Color(0xFF0D1B0F);
    final grey = isDark ? const Color(0xFF91938d) : const Color(0xFF8FAE8B);

    final recentTx = transactions.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _BarIcon(color: green),
            const SizedBox(width: 8),
            Text(
              l10n.wallet_recent_activity,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primary),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (recentTx.isEmpty)
          Center(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('No recent activity', style: TextStyle(color: grey, fontSize: 14)),
          ))
        else
          ...recentTx.map((tx) {
            final rawAmount = (tx['amount'] as num?)?.toInt() ?? 0;
            final isCredit = tx['type'] == 'credit' || (tx['type'] == null && rawAmount > 0);
            final rawDate = tx['created_at'] as String? ?? '';
            final dateStr = rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildCard(
                icon: isCredit ? Icons.account_balance_wallet_rounded : Icons.shield_rounded,
                iconBg: isCredit ? lightGreen : lightRed,
                iconColor: isCredit ? green : red,
                title: tx['description'] ?? 'Transaction',
                date: dateStr,
                amount: isCredit ? '+₹${rawAmount.abs()}' : '−₹${rawAmount.abs()}',
                amountColor: isCredit ? green : red,
                cardBg: cardWhite,
                primary: primary,
                grey: grey,
              ),
            );
          }),
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
    required Color cardBg,
    required Color primary,
    required Color grey,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primary)),
                const SizedBox(height: 2),
                Text(date, style: TextStyle(fontSize: 12, color: grey)),
              ],
            ),
          ),
          Text(amount, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: amountColor)),
        ],
      ),
    );
  }
}

class _BarIcon extends StatelessWidget {
  final Color color;
  const _BarIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 16,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _bar(10, color), const SizedBox(width: 2),
          _bar(16, color), const SizedBox(width: 2),
          _bar(8,  color), const SizedBox(width: 2),
          _bar(12, color),
        ],
      ),
    );
  }

  Widget _bar(double height, Color color) => Container(
    width: 3, height: height,
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
  );
}

// ─── Insurance Transactions ───────────────────────────────────────────────────
class _InsuranceTransactionsSection extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  const _InsuranceTransactionsSection({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final green = isDark ? const Color(0xFF3FFF8B) : const Color(0xFF2E7D32);
    final red = isDark ? const Color(0xFFFF6B6B) : const Color(0xFFB71C1C);
    final cardWhite = isDark ? const Color(0xFF1c1f1c) : Colors.white;
    final primary = isDark ? Colors.white : const Color(0xFF0D1B0F);
    final grey = isDark ? const Color(0xFF91938d) : const Color(0xFF8FAE8B);
    final divider = isDark ? const Color(0xFF2a2d2a) : const Color(0xFFE0E0E0);
    final blue = isDark ? const Color(0xFF3FFF8B) : const Color(0xFF1976D2);
    final lightBlue = isDark ? const Color(0xFF003D2A) : const Color(0xFFE3F2FD);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history_rounded, size: 20, color: green),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.wallet_recent_transactions,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primary),
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/wallet/analytics'),
              child: Text(
                l10n.wallet_see_all,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: green),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (transactions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(16)),
            child: Center(
              child: Text('No transactions yet', style: TextStyle(color: grey, fontSize: 14)),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(16)),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              separatorBuilder: (_, __) => Padding(
                padding: const EdgeInsets.only(left: 64),
                child: Divider(color: divider, height: 1),
              ),
              itemBuilder: (context, index) {
                final tx = transactions[index];
                final rawAmount = (tx['amount'] as num?)?.toInt() ?? 0;
                final isCredit = tx['type'] == 'credit' || (tx['type'] == null && rawAmount > 0);
                final rawDate = tx['created_at'] as String? ?? '';
                final dateStr = rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate;
                return _buildTransactionRow(
                  icon: isCredit ? Icons.card_giftcard_rounded : Icons.shield_rounded,
                  iconColor: isCredit ? blue : red,
                  iconBg: isCredit ? lightBlue : const Color(0xFFFFEBEE),
                  title: tx['description'] ?? 'Transaction',
                  subtitle: dateStr,
                  amount: isCredit ? '+₹${rawAmount.abs()}' : '−₹${rawAmount.abs()}',
                  amountColor: isCredit ? green : red,
                  primary: primary,
                  grey: grey,
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
    required Color primary,
    required Color grey,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primary)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: grey)),
              ],
            ),
          ),
          Text(amount, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: amountColor)),
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
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final green = isDark ? const Color(0xFF3FFF8B) : const Color(0xFF2E7D32);
    final cardWhite = isDark ? const Color(0xFF1c1f1c) : Colors.white;
    final primary = isDark ? Colors.white : const Color(0xFF0D1B0F);

    return GestureDetector(
      onTap: () => context.push('/support'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06), blurRadius: 10, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: green, borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l10n.wallet_help_title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primary)),
              const SizedBox(height: 2),
              Row(children: [
                Text(l10n.wallet_chat, style: TextStyle(fontSize: 13, color: green, fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 14, color: green),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─── UPI Withdrawal Flow ──────────────────────────────────────────────────────
void _showWithdrawBottomSheet(BuildContext context, int balance) {
  if (balance <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No balance available to withdraw')),
    );
    return;
  }

  final upiController = TextEditingController();
  final isDark     = Theme.of(context).brightness == Brightness.dark;
  final sheetBg    = isDark ? const Color(0xFF1C1F1C) : Colors.white;
  final inputBg    = isDark ? const Color(0xFF0A0B0A) : const Color(0xFFF4F6F4);
  final green      = isDark ? const Color(0xFF3FFF8B) : const Color(0xFF2E7D32);
  final lightGreen = isDark ? const Color(0xFF004734) : const Color(0xFFE8F5E9);
  final primary    = isDark ? Colors.white : const Color(0xFF0D1B0F);
  final grey       = isDark ? const Color(0xFF91938D) : const Color(0xFF8FAE8B);
  final divider    = isDark ? Colors.white.withOpacity(0.10) : const Color(0xFFE5E7EB);
  final btnTxt     = isDark ? const Color(0xFF0A0B0A) : Colors.white;
  final formattedBalance = balance.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  final parentContext = context;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: sheetBg,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (sheetCtx) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
          left: 24, right: 24, top: 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(sheetCtx)!.wallet_withdraw,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primary)),
            const SizedBox(height: 8),
            Text('Enter your UPI ID to receive ₹$formattedBalance',
                style: TextStyle(fontSize: 14, color: grey)),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                color: inputBg, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: divider),
              ),
              child: TextField(
                controller: upiController,
                style: TextStyle(color: primary),
                decoration: InputDecoration(
                  labelText: 'UPI ID',
                  labelStyle: TextStyle(color: grey),
                  hintText: 'yourname@upi',
                  hintStyle: TextStyle(color: grey),
                  prefixIcon: Icon(Icons.account_balance_wallet_rounded, color: green),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: lightGreen, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: green.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('₹$formattedBalance',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: green)),
                  const SizedBox(height: 2),
                  Text('Full available balance', style: TextStyle(fontSize: 12, color: green)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                onPressed: () {
                  final upi = upiController.text.trim();
                  if (upi.isEmpty) return;
                  Navigator.pop(sheetCtx);
                  _processWithdrawal(parentContext, balance, upi);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: green, foregroundColor: btnTxt,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
                child: Text('Initiate Transfer →',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: btnTxt)),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel',
                    style: TextStyle(color: grey, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    },
  );
}

void _processWithdrawal(BuildContext context, int amount, String upiId) {
  final isDark    = Theme.of(context).brightness == Brightness.dark;
  final barrierBg = isDark ? Colors.black.withOpacity(0.95) : Colors.white.withOpacity(0.98);
  final green     = isDark ? const Color(0xFF3FFF8B) : const Color(0xFF2D6A2D);
  final primary   = isDark ? const Color(0xFFE1E3DE) : const Color(0xFF0D1B0F);
  final grey      = isDark ? const Color(0xFF91938D) : Colors.grey;
  final successBg = isDark ? const Color(0xFF0A0B0A) : Colors.white;
  final refBg     = isDark ? const Color(0xFF1C1F1C) : const Color(0xFFE8F5E9);
  final refText   = isDark ? const Color(0xFFE1E3DE) : Colors.black87;
  final btnTxt    = isDark ? const Color(0xFF0A0B0A) : Colors.white;

  showDialog(
    context: context,
    barrierColor: barrierBg,
    barrierDismissible: false,
    builder: (context) => Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(green)),
            const SizedBox(height: 24),
            Text('Initiating transfer...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primary)),
            const SizedBox(height: 8),
            Text('Connecting to UPI network', style: TextStyle(fontSize: 14, color: grey)),
            const SizedBox(height: 8),
            Text('Powered by Razorpay', style: TextStyle(fontSize: 12, color: grey)),
          ],
        ),
      ),
    ),
  );

  Future.delayed(const Duration(seconds: 2), () {
    if (!context.mounted) return;
    Navigator.pop(context);
    final formattedBalance = amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: successBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2D6A2D),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 24),
                Text('Withdrawal successful', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primary)),
                const SizedBox(height: 8),
                Text('Your transfer of ₹$formattedBalance to $upiId is complete.', style: TextStyle(color: grey), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: refBg, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reference Number', style: TextStyle(fontSize: 12, color: grey)),
                      const SizedBox(height: 4),
                      Text('TXN-HUSTLR-892374${DateTime.now().millisecondsSinceEpoch % 1000}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: refText)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      while (Navigator.of(context).canPop()) Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: btnTxt,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text('Done', style: TextStyle(color: btnTxt, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  });
}

// ─── Cashback Status Card ─────────────────────────────────────────────────────
class _CashbackStatusCard extends StatelessWidget {
  final Map<String, dynamic> status;

  const _CashbackStatusCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final green = isDark ? const Color(0xFF3FFF8B) : const Color(0xFF2E7D32);
    final isDone = status['status'] == 'earned';
    final cardWhite = isDark ? const Color(0xFF1c1f1c) : Colors.white;
    final primary = isDark ? Colors.white : const Color(0xFF0D1B0F);
    final grey = isDark ? const Color(0xFF91938D) : const Color(0xFF607D8B);

    if (isDone) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: green.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.workspace_premium_rounded, color: green),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Quarterly Cashback deposited ✔',
                style: TextStyle(color: green, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    final weeks = (status['current_clean_weeks'] as num?)?.toInt() ?? 0;
    final cashback = (status['potential_cashback'] as num?)?.toDouble() ?? 0.0;
    final remaining = 13 - weeks;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.electric_bolt_rounded, size: 20, color: green),
              const SizedBox(width: 8),
              Text(
                'Quarterly Claim-Free Bonus',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(13, (index) {
              Color blockColor;
              if (index < weeks) {
                blockColor = green; 
              } else if (index == weeks) {
                blockColor = Colors.blue;
              } else {
                blockColor = isDark ? const Color(0xFF2E332E) : const Color(0xFFECEFF1);
              }
              return Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsets.only(right: index < 12 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: blockColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Text(
            'Keep up the 0 claims streak for $remaining more weeks to earn ₹${cashback.toStringAsFixed(0)} cashback!',
            style: TextStyle(fontSize: 13, height: 1.4, color: grey),
          ),
        ],
      ),
    );
  }
}
