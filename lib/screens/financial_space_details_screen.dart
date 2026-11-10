import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';
import '../services/finance_service.dart';
import '../utils/formatters.dart';
import '../widgets/add_edit_transaction_sheet.dart';
import '../widgets/ambient_background.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/transaction_card.dart';

class FinancialSpaceDetailsScreen extends StatefulWidget {
  final String walletId;

  const FinancialSpaceDetailsScreen({super.key, required this.walletId});

  @override
  State<FinancialSpaceDetailsScreen> createState() => _FinancialSpaceDetailsScreenState();
}

class _FinancialSpaceDetailsScreenState extends State<FinancialSpaceDetailsScreen> {
  void _showEditWalletDialog(BuildContext context, WalletModel wallet) {
    final finance = FinanceService.instance;
    final nameController = TextEditingController(text: wallet.name);
    final balanceController = TextEditingController(
      text: wallet.initialBalance == wallet.initialBalance.toInt()
          ? wallet.initialBalance.toInt().toString()
          : wallet.initialBalance.toString(),
    );

    int selectedIconCode = wallet.iconCode;
    int selectedColorValue = wallet.colorValue;
    String selectedCurrency = wallet.currency;

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
          title: Text('تعديل المساحة المالية', style: TextStyle(color: textCol, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'اسم المساحة'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: balanceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'الرصيد الأولي'),
                ),
                const SizedBox(height: 16),
                Text('العملة', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textCol)),
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

                finance.editWallet(wallet.copyWith(
                  name: name,
                  initialBalance: initBal,
                  currency: selectedCurrency,
                  colorValue: selectedColorValue,
                  iconCode: selectedIconCode,
                ));
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white : Colors.black,
                foregroundColor: isDark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSafeDelete(BuildContext context, WalletModel wallet) async {
    final finance = FinanceService.instance;
    final currentBalance = finance.getWalletBalance(wallet.id);

    if (finance.wallets.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يمكن حذف المساحة المالية الوحيدة في التطبيق'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    // Condition 1: Check if balance is non-zero
    if (currentBalance.abs() > 0.001) {
      _showTransferBeforeDeleteDialog(context, wallet, currentBalance);
      return;
    }

    // Check if transactions exist
    final txCount = finance.getTransactionCountForWallet(wallet.id);
    final confirm = await ConfirmDeleteDialog.show(
      context,
      title: 'حذف المساحة المالية',
      content: txCount > 0
          ? 'المساحة "${wallet.name}" تحتوي على $txCount معاملة مسجلة. هل تريد بالتأكيد حذف هذه المساحة؟ سيتم الاحتفاظ بسجل المعاملات بأمان.'
          : 'هل تريد بالتأكيد حذف المساحة المالية "${wallet.name}"؟',
      confirmText: 'حذف',
      isDestructive: true,
    );

    if (confirm == true && mounted) {
      await finance.deleteWallet(wallet.id);
      if (mounted) {
        Navigator.of(this.context).pop();
      }
    }
  }

  void _showTransferBeforeDeleteDialog(BuildContext context, WalletModel wallet, double balance) {
    final finance = FinanceService.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? Colors.white : Colors.black;

    // Filter target spaces that have matching currency
    final eligibleTargets = finance.wallets
        .where((w) => w.id != wallet.id && w.currency == wallet.currency)
        .toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFEAB308), size: 28),
            const SizedBox(width: 8),
            Text('تنبيه: رصيد متبقٍ', style: TextStyle(color: textCol, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'لا يمكن حذف المساحة "${wallet.name}" لأنها تحتوي على رصيد متبقٍ قدره:',
              style: TextStyle(color: textCol, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                Formatters.formatAmount(balance, currency: wallet.currency),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              eligibleTargets.isNotEmpty
                  ? 'يرجى تحويل الرصيد المتبقي إلى مساحة مالية أخرى من نفس العملة قبل الحذف.'
                  : 'يرجى تصفية أو نقل الرصيد أولاً، حيث لا توجد مساحة أخرى بنفس العملة (${wallet.currency}).',
              style: TextStyle(color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280), fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          if (eligibleTargets.isNotEmpty)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                AddEditTransactionSheet.show(
                  context,
                  initialType: TransactionType.transfer,
                  initialTransaction: TransactionModel(
                    id: '',
                    title: 'تصفية رصيد قبل الحذف',
                    amount: balance,
                    currency: wallet.currency,
                    type: TransactionType.transfer,
                    categoryId: 'other_exp',
                    walletId: wallet.id,
                    toWalletId: eligibleTargets.first.id,
                    date: DateTime.now(),
                    note: 'تحويل الرصيد المتبقي قبل حذف المساحة',
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white : Colors.black,
                foregroundColor: isDark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('تحويل الرصيد الآن'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final finance = FinanceService.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? Colors.white : Colors.black;
    final subTextCol = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);

    return ListenableBuilder(
      listenable: finance,
      builder: (context, _) {
        final walletExists = finance.wallets.any((w) => w.id == widget.walletId);
        if (!walletExists) {
          return Scaffold(
            appBar: AppBar(title: const Text('تفاصيل المساحة')),
            body: const Center(child: Text('المساحة غير موجودة أو تم حذفها')),
          );
        }

        final wallet = finance.wallets.firstWhere((w) => w.id == widget.walletId);
        final currentBalance = finance.getWalletBalance(wallet.id);
        final transactions = finance.getTransactionsForWallet(wallet.id);

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            scrolledUnderElevation: 0,
            elevation: 0,
            iconTheme: IconThemeData(color: textCol),
            title: Text(wallet.name, style: TextStyle(color: textCol, fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'تعديل',
                onPressed: () => _showEditWalletDialog(context, wallet),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626)),
                tooltip: 'حذف',
                onPressed: () => _handleSafeDelete(context, wallet),
              ),
            ],
          ),
          body: AmbientBackground(
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                children: [
                  // Space Hero Card
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB), width: 1.4),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black.withAlpha(40) : Colors.black.withAlpha(8),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: wallet.color.withAlpha(30),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(wallet.icon, color: wallet.color, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    wallet.name,
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textCol),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          wallet.currency,
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textCol),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'الرصيد الأولي: ${Formatters.formatAmount(wallet.initialBalance, currency: wallet.currency)}',
                                        style: TextStyle(fontSize: 11, color: subTextCol),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Divider(height: 1, color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFF3F4F6)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('الرصيد الحالي', style: TextStyle(fontSize: 12, color: subTextCol)),
                                const SizedBox(height: 4),
                                Text(
                                  Formatters.formatAmount(currentBalance, currency: wallet.currency),
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: currentBalance >= 0 ? textCol : const Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                            ),
                            // Quick Transfer Button
                            ElevatedButton.icon(
                              onPressed: () {
                                AddEditTransactionSheet.show(
                                  context,
                                  initialType: TransactionType.transfer,
                                  initialTransaction: TransactionModel(
                                    id: '',
                                    title: 'تحويل',
                                    amount: 0.0,
                                    currency: wallet.currency,
                                    type: TransactionType.transfer,
                                    categoryId: 'other_exp',
                                    walletId: wallet.id,
                                    date: DateTime.now(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                              label: const Text('أخذ / تحويل'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? Colors.white : Colors.black,
                                foregroundColor: isDark ? Colors.black : Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Transactions Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'المعاملات المرتبطة (${transactions.length})',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textCol),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (transactions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E).withAlpha(120) : Colors.white.withAlpha(120),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 48, color: subTextCol.withAlpha(140)),
                          const SizedBox(height: 10),
                          Text('لا توجد معاملات مسجلة لهذه المساحة بعد', style: TextStyle(color: subTextCol, fontSize: 13)),
                        ],
                      ),
                    )
                  else
                    ...transactions.map((tx) => TransactionCard(transaction: tx)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

