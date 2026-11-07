import 'package:flutter/material.dart';
import '../../services/finance_service.dart';
import '../../services/security_service.dart';
import '../../services/settings_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/action_choice_sheet.dart';
import '../../widgets/transaction_card.dart';
import '../wallets_screen.dart';

class DashboardTab extends StatelessWidget {
  final VoidCallback onSeeAllTransactions;
  final VoidCallback onSeeAllDebts;

  const DashboardTab({
    super.key,
    required this.onSeeAllTransactions,
    required this.onSeeAllDebts,
  });

  @override
  Widget build(BuildContext context) {
    final finance = FinanceService.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

    return ListenableBuilder(
      listenable: Listenable.merge([finance, SettingsService.hideBalanceNotifier, SettingsService.currencyNotifier]),
      builder: (context, _) {
        final totalBalance = finance.totalNetBalance;
        final todayIncome = finance.getDailyIncome(now);
        final todayExpense = finance.getDailyExpense(now);
        final debtsToMe = finance.totalDebtsToMeUnpaid;
        final debtsFromMe = finance.totalDebtsFromMeUnpaid;
        final recentTransactions = finance.transactions.take(5).toList();

        return RefreshIndicator(
          onRefresh: () async => finance.init(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Big Frosted Balance Card
                _buildNetBalanceCard(context, totalBalance, todayIncome, todayExpense, isDark),
                const SizedBox(height: 22),

                // 2. Wallets Quick Carousel
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'المحافظ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const WalletsScreen()),
                        );
                      },
                      icon: const Icon(Icons.tune_rounded, size: 16),
                      label: const Text('إدارة', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 98,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: finance.wallets.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final wallet = finance.wallets[index];
                      final balance = finance.getWalletBalance(wallet.id);
                      return _buildWalletCard(context, wallet, balance, isDark);
                    },
                  ),
                ),
                const SizedBox(height: 22),

                // 3. Debts Status Card (KRIDI Integration)
                _buildDebtsOverviewCard(context, debtsToMe, debtsFromMe, isDark),
                const SizedBox(height: 24),

                // 4. Recent Transactions Header + List
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'المعاملات',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (finance.transactions.isNotEmpty)
                      TextButton(
                        onPressed: onSeeAllTransactions,
                        child: const Text('الكل', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                if (recentTransactions.isEmpty)
                  _buildEmptyTransactionsPrompt(context, isDark)
                else
                  ...recentTransactions.map((tx) => TransactionCard(transaction: tx)),

                const SizedBox(height: 90), // Room for floating dock
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNetBalanceCard(
    BuildContext context,
    double totalBalance,
    double monthlyIncome,
    double monthlyExpense,
    bool isDark,
  ) {
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderCol = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB);
    final iconBg = isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6);
    final iconCol = isDark ? Colors.white : Colors.black;
    final textCol = isDark ? Colors.white : Colors.black;
    final dividerCol = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFF3F4F6);
    final incomeBoxBg = isDark ? const Color(0xFF064E3B).withAlpha(90) : const Color(0xFFF0FDF4);
    final expenseBoxBg = isDark ? const Color(0xFF7F1D1D).withAlpha(90) : const Color(0xFFFEF2F2);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: borderCol,
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withAlpha(40) : Colors.black.withAlpha(6),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.account_balance_wallet_rounded, color: iconCol, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'الرصيد',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () async {
                  if (SettingsService.hideBalanceNotifier.value) {
                    final authenticated = await SecurityService.authenticateToReveal(context);
                    if (authenticated) {
                      await SettingsService.toggleHideBalance();
                    }
                  } else {
                    await SettingsService.toggleHideBalance();
                  }
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    SettingsService.hideBalanceNotifier.value ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: iconCol,
                    size: 18,
                  ),
                ),
                tooltip: 'إخفاء / إظهار',
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            Formatters.formatAmount(totalBalance),
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: textCol,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: dividerCol),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: incomeBoxBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_downward_rounded, color: Color(0xFF16A34A), size: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'دخل اليوم',
                            style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280)),
                          ),
                          Text(
                            Formatters.formatAmount(monthlyIncome),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF16A34A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 32, color: dividerCol),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: expenseBoxBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_upward_rounded, color: Color(0xFFDC2626), size: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'مصروف اليوم',
                            style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280)),
                          ),
                          Text(
                            Formatters.formatAmount(monthlyExpense),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFDC2626),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard(BuildContext context, dynamic wallet, double balance, bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderCol = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB);
    final iconBg = isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6);
    final textCol = isDark ? Colors.white : Colors.black;

    return Container(
      width: 155,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderCol, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withAlpha(40) : Colors.black.withAlpha(5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(wallet.icon, size: 16, color: wallet.color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  wallet.name,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textCol),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            Formatters.formatAmount(balance),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: balance >= 0 ? textCol : const Color(0xFFDC2626),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDebtsOverviewCard(
    BuildContext context,
    double debtsToMe,
    double debtsFromMe,
    bool isDark,
  ) {
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderCol = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB);
    final textCol = isDark ? Colors.white : Colors.black;
    final toMeBg = isDark ? const Color(0xFF064E3B).withAlpha(80) : const Color(0xFFF0FDF4);
    final toMeBorder = isDark ? const Color(0xFF065F46) : const Color(0xFFBBF7D0);
    final fromMeBg = isDark ? const Color(0xFF7F1D1D).withAlpha(80) : const Color(0xFFFEF2F2);
    final fromMeBorder = isDark ? const Color(0xFF991B1B) : const Color(0xFFFECACA);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderCol, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withAlpha(40) : Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.handshake_rounded, size: 18, color: textCol),
                  const SizedBox(width: 8),
                  Text(
                    'الديون',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textCol),
                  ),
                ],
              ),
              InkWell(
                onTap: onSeeAllDebts,
                child: Text(
                  'الكل ←',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textCol),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: toMeBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: toMeBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'لك',
                        style: TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Formatters.formatAmount(debtsToMe),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: fromMeBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: fromMeBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'عليك',
                        style: TextStyle(fontSize: 11, color: Color(0xFFDC2626), fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Formatters.formatAmount(debtsFromMe),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTransactionsPrompt(BuildContext context, bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderCol = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB);
    final textCol = isDark ? Colors.white : Colors.black;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderCol, width: 1.2),
      ),
      child: Column(
        children: [
          const Icon(Icons.receipt_long_outlined, size: 40, color: Color(0xFF9CA3AF)),
          const SizedBox(height: 8),
          Text(
            'لا توجد معاملات',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textCol),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => ActionChoiceSheet.show(context),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('إضافة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white : Colors.black,
              foregroundColor: isDark ? Colors.black : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }
}
