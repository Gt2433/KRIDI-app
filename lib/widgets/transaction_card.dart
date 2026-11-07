import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';
import '../services/finance_service.dart';
import '../utils/formatters.dart';
import 'add_edit_transaction_sheet.dart';
import 'confirm_delete_dialog.dart';
import 'glass_container.dart';

class TransactionCard extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionCard({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final finance = FinanceService.instance;

    final cat = CategoryModel.getById(transaction.categoryId);
    final wallet = finance.wallets.firstWhere(
      (w) => w.id == transaction.walletId,
      orElse: () => finance.wallets.isNotEmpty ? finance.wallets.first : walletFallback,
    );

    Color typeColor;
    String prefix;
    IconData typeIcon;

    switch (transaction.type) {
      case TransactionType.expense:
        typeColor = const Color(0xFFEF4444);
        prefix = '-';
        typeIcon = cat.icon;
        break;
      case TransactionType.income:
        typeColor = const Color(0xFF10B981);
        prefix = '+';
        typeIcon = cat.icon;
        break;
      case TransactionType.transfer:
        typeColor = const Color(0xFF3B82F6);
        prefix = '';
        typeIcon = Icons.swap_horiz_rounded;
        break;
    }

    String walletDisplay = wallet.name;
    if (transaction.type == TransactionType.transfer && transaction.toWalletId != null) {
      final toW = finance.wallets.firstWhere(
        (w) => w.id == transaction.toWalletId,
        orElse: () => wallet,
      );
      walletDisplay = '${wallet.name} ← ${toW.name}';
    }

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFE11D48),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        return await ConfirmDeleteDialog.show(
          context,
          title: 'حذف',
          content: 'هل تريد الحذف؟',
        );
      },
      onDismissed: (_) {
        finance.deleteTransaction(transaction.id);
      },
      child: GlassContainer(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          AddEditTransactionSheet.show(
            context,
            initialTransaction: transaction,
          );
        },
        child: Row(
          children: [
            // Category / Type Icon Box
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (transaction.type == TransactionType.transfer ? typeColor : cat.color).withAlpha(30),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                typeIcon,
                color: transaction.type == TransactionType.transfer ? typeColor : cat.color,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // Title + Wallet + Date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title.isNotEmpty
                        ? transaction.title
                        : (transaction.type == TransactionType.transfer ? 'تحويل' : cat.nameAr),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet_outlined, size: 12, color: Colors.grey.withAlpha(200)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          walletDisplay,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•  ${Formatters.formatDateTime(transaction.date)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                  if (transaction.note != null && transaction.note!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      transaction.note!,
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.withAlpha(180),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Amount
            Text(
              '$prefix${Formatters.formatAmount(transaction.amount)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: typeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final walletFallback = WalletModel.defaultWallets.first;
