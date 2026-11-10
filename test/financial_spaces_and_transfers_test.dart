import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kredi/models/transaction_model.dart';
import 'package:kredi/models/wallet_model.dart';
import 'package:kredi/services/finance_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('KREDI — Financial Spaces & Money Transfer System Tests', () {
    test('Test A: Creating spaces with multi-currency support', () async {
      final finance = FinanceService.instance;
      await finance.init();

      // Clear existing test wallets
      while (finance.wallets.isNotEmpty) {
        await finance.deleteWallet(finance.wallets.first.id);
      }

      final wallet = WalletModel(
        id: 'space_wallet',
        name: 'جيبي',
        initialBalance: 2000.0,
        currency: 'DZD',
        iconCode: 0xf05e0,
        colorValue: 0xFF10B981,
      );

      final savings = WalletModel(
        id: 'space_savings',
        name: 'الحصالة',
        initialBalance: 20000.0,
        currency: 'DZD',
        iconCode: 0xe571,
        colorValue: 0xFFF59E0B,
      );

      final redotPay = WalletModel(
        id: 'space_redotpay',
        name: 'RedotPay',
        initialBalance: 120.0,
        currency: 'USD',
        iconCode: 0xe048,
        colorValue: 0xFF3B82F6,
      );

      await finance.addWallet(wallet);
      await finance.addWallet(savings);
      await finance.addWallet(redotPay);

      expect(finance.wallets.length, 3);
      expect(finance.getWalletBalance('space_wallet'), 2000.0);
      expect(finance.wallets.firstWhere((w) => w.id == 'space_wallet').currency, 'DZD');

      expect(finance.getWalletBalance('space_savings'), 20000.0);
      expect(finance.wallets.firstWhere((w) => w.id == 'space_savings').currency, 'DZD');

      expect(finance.getWalletBalance('space_redotpay'), 120.0);
      expect(finance.wallets.firstWhere((w) => w.id == 'space_redotpay').currency, 'USD');
    });

    test('Test B: Main balance selection does not change financial values', () async {
      final finance = FinanceService.instance;

      await finance.setSelectedMainSpace('space_wallet');
      expect(finance.selectedMainSpaceId, 'space_wallet');
      expect(finance.mainSpaceBalance, 2000.0);

      await finance.setSelectedMainSpace('space_savings');
      expect(finance.selectedMainSpaceId, 'space_savings');
      expect(finance.mainSpaceBalance, 20000.0);

      await finance.setSelectedMainSpace('space_redotpay');
      expect(finance.selectedMainSpaceId, 'space_redotpay');
      expect(finance.mainSpaceBalance, 120.0);

      // Verify original balances are unchanged
      expect(finance.getWalletBalance('space_wallet'), 2000.0);
      expect(finance.getWalletBalance('space_savings'), 20000.0);
      expect(finance.getWalletBalance('space_redotpay'), 120.0);
    });

    test('Test C: Internal Transfer ("Take" / أخذ) between spaces', () async {
      final finance = FinanceService.instance;
      final now = DateTime.now();

      // Transfer 3,000 DZD from Savings Box to Wallet
      final transferTx = TransactionModel(
        id: 'tx_transfer_1',
        title: 'أخذ من الحصالة إلى جيبي',
        amount: 3000.0,
        currency: 'DZD',
        type: TransactionType.transfer,
        categoryId: 'other_exp',
        walletId: 'space_savings',
        toWalletId: 'space_wallet',
        date: now,
      );

      await finance.addTransaction(transferTx);

      // Verify updated balances
      expect(finance.getWalletBalance('space_savings'), 17000.0);
      expect(finance.getWalletBalance('space_wallet'), 5000.0);
      expect(finance.getWalletBalance('space_redotpay'), 120.0);

      // Verify transfer is NOT counted as income or expense
      expect(finance.getDailyIncome(now), 0.0);
      expect(finance.getDailyExpense(now), 0.0);
    });

    test('Test D: Expense decreases only the selected space', () async {
      final finance = FinanceService.instance;
      final now = DateTime.now();

      final expenseTx = TransactionModel(
        id: 'tx_expense_1',
        title: 'عشاء',
        amount: 1000.0,
        currency: 'DZD',
        type: TransactionType.expense,
        categoryId: 'food',
        walletId: 'space_wallet',
        date: now,
      );

      await finance.addTransaction(expenseTx);

      // Wallet should decrease from 5000 to 4000
      expect(finance.getWalletBalance('space_wallet'), 4000.0);
      // Savings Box remains 17000
      expect(finance.getWalletBalance('space_savings'), 17000.0);
      // RedotPay remains 120
      expect(finance.getWalletBalance('space_redotpay'), 120.0);

      // Expense is correctly recorded in stats
      expect(finance.getDailyExpense(now), 1000.0);
    });

    test('Test E: Income increases only the selected space', () async {
      final finance = FinanceService.instance;
      final now = DateTime.now();

      final incomeTx = TransactionModel(
        id: 'tx_income_1',
        title: 'مكافأة',
        amount: 2000.0,
        currency: 'DZD',
        type: TransactionType.income,
        categoryId: 'salary',
        walletId: 'space_savings',
        date: now,
      );

      await finance.addTransaction(incomeTx);

      // Savings increases from 17000 to 19000
      expect(finance.getWalletBalance('space_savings'), 19000.0);
      // Wallet remains 4000
      expect(finance.getWalletBalance('space_wallet'), 4000.0);
      // RedotPay remains 120
      expect(finance.getWalletBalance('space_redotpay'), 120.0);

      // Income is correctly recorded in stats
      expect(finance.getDailyIncome(now), 2000.0);
    });

    test('Test F: Editing a transfer atomically updates both spaces without double counting', () async {
      final finance = FinanceService.instance;

      // Edit the transfer from 3,000 to 5,000 DZD
      final originalTransfer = finance.transactions.firstWhere((t) => t.id == 'tx_transfer_1');
      final updatedTransfer = originalTransfer.copyWith(amount: 5000.0);

      await finance.editTransaction(updatedTransfer);

      // Savings: initial 20000 - 5000 (transfer) + 2000 (income) = 17000 DZD
      expect(finance.getWalletBalance('space_savings'), 17000.0);
      // Wallet: initial 2000 + 5000 (transfer) - 1000 (expense) = 6000 DZD
      expect(finance.getWalletBalance('space_wallet'), 6000.0);
    });

    test('Test G: Deleting a transfer safely restores both spaces balances', () async {
      final finance = FinanceService.instance;

      await finance.deleteTransaction('tx_transfer_1');

      // Savings: initial 20000 + 2000 (income) = 22000 DZD
      expect(finance.getWalletBalance('space_savings'), 22000.0);
      // Wallet: initial 2000 - 1000 (expense) = 1000 DZD
      expect(finance.getWalletBalance('space_wallet'), 1000.0);
    });

    test('Test H: Editing initial balance preserves single source of truth without double counting', () async {
      final finance = FinanceService.instance;

      final currentSavings = finance.wallets.firstWhere((w) => w.id == 'space_savings');
      // Update initial balance from 20000 to 25000
      final updatedWallet = currentSavings.copyWith(initialBalance: 25000.0);

      await finance.editWallet(updatedWallet);

      // Savings: initial 25000 + 2000 (income) = 27000 DZD
      expect(finance.getWalletBalance('space_savings'), 27000.0);
    });

    test('Test I: Deletion safety prevents deleting space with non-zero balance', () async {
      final finance = FinanceService.instance;

      expect(finance.getWalletBalance('space_wallet'), 1000.0);
      final canDelete = await finance.deleteWalletSafe('space_wallet');
      expect(canDelete, false); // Blocked because balance is 1000.0 DZD!
      expect(finance.wallets.any((w) => w.id == 'space_wallet'), true);
    });
  });
}

