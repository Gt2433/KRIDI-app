import 'package:flutter/material.dart';
import '../../models/wallet_model.dart';
import '../../services/finance_service.dart';
import '../../services/security_service.dart';
import '../../services/settings_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/action_choice_sheet.dart';
import '../../widgets/bouncing_button.dart';
import '../../widgets/transaction_card.dart';
import '../financial_space_details_screen.dart';
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
        final selectedSpace = finance.selectedMainSpace;
        final mainSpaceBalance = finance.mainSpaceBalance;
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
                // 1. Configurable Main Space Balance Card
                _buildNetBalanceCard(context, mainSpaceBalance, selectedSpace, todayIncome, todayExpense, isDark),
                const SizedBox(height: 22),

                // 2. Financial Spaces Quick Carousel
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'أموالي (المساحات المالية)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                          tooltip: 'إضافة مساحة مالية',
                          onPressed: () => _showAddWalletDialog(context),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(6),
                        ),
                        const SizedBox(width: 4),
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
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 104,
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
    double spaceBalance,
    WalletModel selectedSpace,
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
                      color: selectedSpace.color.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(selectedSpace.icon, color: selectedSpace.color, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الرصيد الرئيسي',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280),
                        ),
                      ),
                      Text(
                        selectedSpace.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textCol,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  InkWell(
                    onTap: () => _showSelectMainSpaceSheet(context, isDark),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderCol, width: 1.1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'تغيير المساحة',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textCol),
                          ),
                          const SizedBox(width: 2),
                          Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: textCol),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.12),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                  child: child,
                ),
              );
            },
            child: Text(
              Formatters.formatAmount(spaceBalance, currency: selectedSpace.currency),
              key: ValueKey<String>(
                '${selectedSpace.id}_${spaceBalance}_${SettingsService.hideBalanceNotifier.value}',
              ),
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: textCol,
                letterSpacing: -0.5,
              ),
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

  Widget _buildWalletCard(BuildContext context, WalletModel wallet, double balance, bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderCol = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB);
    final iconBg = isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6);
    final textCol = isDark ? Colors.white : Colors.black;

    return BouncingButton(
      scaleFactor: 0.94,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FinancialSpaceDetailsScreen(walletId: wallet.id)),
        );
      },
      child: Container(
        width: 160,
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    wallet.currency,
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280)),
                  ),
                ),
              ],
            ),
            Text(
              Formatters.formatAmount(balance, currency: wallet.currency),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: balance >= 0 ? textCol : const Color(0xFFDC2626),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showSelectMainSpaceSheet(BuildContext context, bool isDark) {
    final finance = FinanceService.instance;
    final bgCol = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderCol = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB);
    final textCol = isDark ? Colors.white : Colors.black;
    final subText = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: bgCol,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: borderCol, width: 1.2)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'اختيار الرصيد الرئيسي',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textCol),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const WalletsScreen()),
                        );
                      },
                      icon: const Icon(Icons.tune_rounded, size: 16),
                      label: const Text('إدارة المساحات'),
                    ),
                  ],
                ),
                Text(
                  'اختر المساحة المالية التي تريد عرض رصيدها كـ رصيد رئيسي في التطبيق:',
                  style: TextStyle(fontSize: 12, color: subText),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: finance.wallets.length,
                    itemBuilder: (context, index) {
                      final wallet = finance.wallets[index];
                      final isSelected = wallet.id == finance.selectedMainSpaceId;
                      final balance = finance.getWalletBalance(wallet.id);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? (isDark ? Colors.white : Colors.black)
                                : borderCol,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: ListTile(
                          onTap: () {
                            finance.setSelectedMainSpace(wallet.id);
                            Navigator.pop(ctx);
                          },
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: wallet.color.withAlpha(30),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(wallet.icon, color: wallet.color, size: 22),
                          ),
                          title: Row(
                            children: [
                              Text(
                                wallet.name,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  color: textCol,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFE5E7EB),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  wallet.currency,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: textCol,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            'الرصيد: ${Formatters.formatAmount(balance, currency: wallet.currency)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: balance >= 0 ? textCol : const Color(0xFFDC2626),
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981))
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddWalletDialog(BuildContext context) {
    final finance = FinanceService.instance;
    final nameController = TextEditingController();
    final balanceController = TextEditingController(text: '0');

    int selectedIconCode = 0xe040;
    int selectedColorValue = 0xFF10B981;
    String selectedCurrency = 'DZD';

    final icons = [
      0xe040, // payments_rounded
      0xe048, // credit_card_rounded
      0xe000, // account_balance_rounded
      0xe571, // savings_rounded
      0xf05e0, // wallet_rounded
      0xe318, // inventory_2_rounded
      0xe59c, // shopping_bag_rounded
    ];

    final colors = [
      0xFF10B981, // Green
      0xFF3B82F6, // Blue
      0xFFF59E0B, // Amber
      0xFF8B5CF6, // Purple
      0xFFEC4899, // Pink
      0xFF0F172A, // Dark
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? Colors.white : Colors.black;

    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(80),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB), width: 1.2),
          ),
          title: Text('إضافة مساحة مالية جديدة', style: TextStyle(color: textCol, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'اسم المساحة (مثال: جيبي، الخزانة، بريدي موب)'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: balanceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'الرصيد الأولي'),
                ),
                const SizedBox(height: 16),
                Text('العملة (إجباري)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textCol)),
                const SizedBox(height: 8),
                Row(
                  children: WalletModel.supportedCurrencies.map((curr) {
                    final isSel = selectedCurrency == curr;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => selectedCurrency = curr),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel ? (isDark ? Colors.white : Colors.black) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSel ? (isDark ? Colors.white : Colors.black) : (isDark ? const Color(0xFF3F3F46) : const Color(0xFFE5E7EB)),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            curr,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isSel ? (isDark ? Colors.black : Colors.white) : textCol,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text('الأيقونة', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textCol)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: icons.map((code) {
                    final isSel = selectedIconCode == code;
                    final tempWallet = WalletModel(id: '', name: '', iconCode: code, colorValue: selectedColorValue);
                    return GestureDetector(
                      onTap: () => setState(() => selectedIconCode = code),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSel ? Color(selectedColorValue).withAlpha(40) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: isSel ? Border.all(color: Color(selectedColorValue), width: 1.5) : null,
                        ),
                        child: Icon(tempWallet.icon, size: 22, color: Color(selectedColorValue)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text('اللون', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textCol)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: colors.map((c) {
                    final isSel = selectedColorValue == c;
                    return GestureDetector(
                      onTap: () => setState(() => selectedColorValue = c),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(c),
                          shape: BoxShape.circle,
                          border: isSel ? Border.all(color: Colors.white, width: 3) : null,
                          boxShadow: isSel ? [const BoxShadow(color: Colors.black26, blurRadius: 4)] : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء', style: TextStyle(color: isDark ? const Color(0xFFA1A1AA) : Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final initBal = double.tryParse(balanceController.text.trim()) ?? 0.0;

                finance.addWallet(WalletModel(
                  id: 'w_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  initialBalance: initBal,
                  currency: selectedCurrency,
                  iconCode: selectedIconCode,
                  colorValue: selectedColorValue,
                  createdAt: DateTime.now(),
                ));
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white : Colors.black,
                foregroundColor: isDark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('إضافة'),
            ),
          ],
        ),
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
