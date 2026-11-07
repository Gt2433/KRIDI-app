import 'package:flutter/material.dart';
import '../models/wallet_model.dart';
import '../services/finance_service.dart';
import '../utils/formatters.dart';
import '../widgets/ambient_background.dart';
import '../widgets/glass_container.dart';

class WalletsScreen extends StatelessWidget {
  const WalletsScreen({super.key});

  void _showAddEditWalletDialog(BuildContext context, {WalletModel? wallet}) {
    final finance = FinanceService.instance;
    final nameController = TextEditingController(text: wallet?.name ?? '');
    final balanceController = TextEditingController(
      text: wallet != null ? (wallet.initialBalance == wallet.initialBalance.toInt() ? wallet.initialBalance.toInt().toString() : wallet.initialBalance.toString()) : '0',
    );

    int selectedIconCode = wallet?.iconCode ?? 0xe040;
    int selectedColorValue = wallet?.colorValue ?? 0xFF10B981;

    final icons = [
      0xe040, // payments_rounded
      0xe048, // credit_card_rounded
      0xe000, // account_balance_rounded
      0xe571, // savings_rounded
      0xe59c, // shopping_bag_rounded
      0xf05e0, // wallet_rounded
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
          title: Text(wallet != null ? 'تعديل' : 'إضافة', style: TextStyle(color: textCol)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'الاسم',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: balanceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'الرصيد',
                  ),
                ),
                const SizedBox(height: 16),
                Text('الأيقونة', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textCol)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
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

                if (wallet != null) {
                  finance.editWallet(wallet.copyWith(
                    name: name,
                    initialBalance: initBal,
                    colorValue: selectedColorValue,
                    iconCode: selectedIconCode,
                  ));
                } else {
                  finance.addWallet(WalletModel(
                    id: 'w_${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    initialBalance: initBal,
                    colorValue: selectedColorValue,
                    iconCode: selectedIconCode,
                  ));
                }
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

  @override
  Widget build(BuildContext context) {
    final finance = FinanceService.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? Colors.white : Colors.black;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        iconTheme: IconThemeData(color: textCol),
        title: Text('المحافظ', style: TextStyle(color: textCol, fontWeight: FontWeight.bold)),
      ),
      body: AmbientBackground(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: finance,
            builder: (context, _) {
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                itemCount: finance.wallets.length,
                itemBuilder: (context, index) {
                  final wallet = finance.wallets[index];
                  final currentBalance = finance.getWalletBalance(wallet.id);

                  return GlassContainer(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    borderRadius: BorderRadius.circular(22),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: wallet.color.withAlpha(25),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(wallet.icon, color: wallet.color, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                wallet.name,
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textCol),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'المبدئي: ${Formatters.formatAmount(wallet.initialBalance)}',
                                style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280)),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              Formatters.formatAmount(currentBalance),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: currentBalance >= 0 ? textCol : const Color(0xFFDC2626),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit_outlined, size: 18, color: textCol),
                                  onPressed: () => _showAddEditWalletDialog(context, wallet: wallet),
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(6),
                                ),
                                if (finance.wallets.length > 1)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                                    onPressed: () => finance.deleteWallet(wallet.id),
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(6),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditWalletDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('إضافة'),
        backgroundColor: isDark ? Colors.white : Colors.black,
        foregroundColor: isDark ? Colors.black : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
