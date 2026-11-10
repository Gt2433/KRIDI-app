import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category_model.dart';
import '../models/debt_model.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';
import '../models/budget_model.dart';
import 'storage_service.dart';
import 'sync_service.dart';

class FinanceService extends ChangeNotifier {
  static final FinanceService instance = FinanceService._internal();
  FinanceService._internal();

  static const String _keyTransactions = 'kredi_transactions_v1';
  static const String _keyWallets = 'kredi_wallets_v1';
  static const String _keyBudgets = 'kredi_budgets_v1';
  static const String _keySelectedMainSpaceId = 'kredi_selected_main_space_id';

  List<TransactionModel> _transactions = [];
  List<WalletModel> _wallets = [];
  List<BudgetModel> _budgets = [];
  List<Debt> _debts = [];
  String? _selectedMainSpaceId;
  bool _isInitialized = false;

  List<TransactionModel> get transactions => List.unmodifiable(_transactions);
  List<WalletModel> get wallets => List.unmodifiable(_wallets);
  List<BudgetModel> get budgets => List.unmodifiable(_budgets);
  List<Debt> get debts => List.unmodifiable(_debts);
  bool get isInitialized => _isInitialized;

  String get selectedMainSpaceId => _selectedMainSpaceId ?? (_wallets.isNotEmpty ? _wallets.first.id : 'cash');

  WalletModel get selectedMainSpace {
    return _wallets.firstWhere(
      (w) => w.id == selectedMainSpaceId,
      orElse: () => _wallets.isNotEmpty ? _wallets.first : WalletModel.defaultWallets.first,
    );
  }

  double get mainSpaceBalance => getWalletBalance(selectedMainSpace.id);

  Future<void> setSelectedMainSpace(String spaceId) async {
    if (_selectedMainSpaceId == spaceId) return;
    _selectedMainSpaceId = spaceId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySelectedMainSpaceId, spaceId);
    notifyListeners();
  }

  Future<void> init() async {
    if (_isInitialized) return;
    final prefs = await SharedPreferences.getInstance();

    // 1. Load Wallets
    final walletsStr = prefs.getString(_keyWallets);
    if (walletsStr != null && walletsStr.isNotEmpty) {
      final List<dynamic> list = json.decode(walletsStr);
      _wallets = list.map((e) => WalletModel.fromMap(e as Map<String, dynamic>)).toList();
    }
    if (_wallets.isEmpty) {
      _wallets = WalletModel.defaultWallets;
      await _saveWallets();
    }

    // 2. Load Transactions
    final txStr = prefs.getString(_keyTransactions);
    if (txStr != null && txStr.isNotEmpty) {
      final List<dynamic> list = json.decode(txStr);
      _transactions = list.map((e) => TransactionModel.fromMap(e as Map<String, dynamic>)).toList();
      _transactions.sort((a, b) => b.date.compareTo(a.date));
    }

    // 3. Load Budgets
    final budgetStr = prefs.getString(_keyBudgets);
    if (budgetStr != null && budgetStr.isNotEmpty) {
      final List<dynamic> list = json.decode(budgetStr);
      _budgets = list.map((e) => BudgetModel.fromMap(e as Map<String, dynamic>)).toList();
    }

    // 4. Load Debts
    _debts = await StorageService.loadDebts();

    // 5. Load Selected Main Space
    _selectedMainSpaceId = prefs.getString(_keySelectedMainSpaceId);
    if (_selectedMainSpaceId == null || !_wallets.any((w) => w.id == _selectedMainSpaceId)) {
      _selectedMainSpaceId = _wallets.isNotEmpty ? _wallets.first.id : 'cash';
      await prefs.setString(_keySelectedMainSpaceId, _selectedMainSpaceId!);
    }

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> loadFromCloudData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    if (data['wallets'] is List) {
      final list = data['wallets'] as List;
      final parsed = list.map((e) => WalletModel.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      if (parsed.isNotEmpty) {
        _wallets = parsed;
        await _saveWallets();
      }
    }

    if (data['transactions'] is List) {
      final list = data['transactions'] as List;
      _transactions = list.map((e) => TransactionModel.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      _transactions.sort((a, b) => b.date.compareTo(a.date));
      await _saveTransactions();
    }

    if (data['budgets'] is List) {
      final list = data['budgets'] as List;
      _budgets = list.map((e) => BudgetModel.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      await prefs.setString(_keyBudgets, json.encode(_budgets.map((b) => b.toMap()).toList()));
    }

    if (data['debts'] is List) {
      final list = data['debts'] as List;
      _debts = list.map((e) => Debt.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      await StorageService.saveDebts(_debts);
    }

    if (_selectedMainSpaceId == null || !_wallets.any((w) => w.id == _selectedMainSpaceId)) {
      _selectedMainSpaceId = _wallets.isNotEmpty ? _wallets.first.id : 'cash';
      await prefs.setString(_keySelectedMainSpaceId, _selectedMainSpaceId!);
    }

    notifyListeners();
  }

  // --- Transactions ---
  Future<void> addTransaction(TransactionModel tx) async {
    _transactions.insert(0, tx);
    _transactions.sort((a, b) => b.date.compareTo(a.date));
    await _saveTransactions();
    notifyListeners();
    SyncService.instance.scheduleCloudSync();
  }

  Future<void> editTransaction(TransactionModel tx) async {
    final idx = _transactions.indexWhere((t) => t.id == tx.id);
    if (idx != -1) {
      _transactions[idx] = tx;
      _transactions.sort((a, b) => b.date.compareTo(a.date));
      await _saveTransactions();
      notifyListeners();
      SyncService.instance.scheduleCloudSync();
    }
  }

  Future<void> deleteTransaction(String id) async {
    _transactions.removeWhere((t) => t.id == id);
    await _saveTransactions();
    notifyListeners();
    SyncService.instance.scheduleCloudSync();
  }

  Future<void> _saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final str = json.encode(_transactions.map((t) => t.toMap()).toList());
    await prefs.setString(_keyTransactions, str);
  }

  // --- Wallets ---
  Future<void> addWallet(WalletModel wallet) async {
    _wallets.add(wallet);
    await _saveWallets();
    notifyListeners();
    SyncService.instance.scheduleCloudSync();
  }

  Future<void> editWallet(WalletModel wallet) async {
    final idx = _wallets.indexWhere((w) => w.id == wallet.id);
    if (idx != -1) {
      _wallets[idx] = wallet;
      await _saveWallets();
      notifyListeners();
      SyncService.instance.scheduleCloudSync();
    }
  }

  bool hasTransactionsForWallet(String id) {
    return _transactions.any((t) => t.walletId == id || t.toWalletId == id);
  }

  int getTransactionCountForWallet(String id) {
    return _transactions.where((t) => t.walletId == id || t.toWalletId == id).length;
  }

  List<TransactionModel> getTransactionsForWallet(String id) {
    return _transactions.where((t) => t.walletId == id || t.toWalletId == id).toList();
  }

  Future<void> deleteWallet(String id) async {
    _wallets.removeWhere((w) => w.id == id);
    if (_selectedMainSpaceId == id) {
      _selectedMainSpaceId = _wallets.isNotEmpty ? _wallets.first.id : 'cash';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySelectedMainSpaceId, _selectedMainSpaceId!);
    }
    await _saveWallets();
    notifyListeners();
    SyncService.instance.scheduleCloudSync();
  }

  /// Safe deletion method (Condition 1)
  /// Blocks deletion if wallet is the only space or has a non-zero balance
  Future<bool> deleteWalletSafe(String id) async {
    if (_wallets.length <= 1) return false;
    final bal = getWalletBalance(id);
    if (bal.abs() > 0.001) {
      return false;
    }
    await deleteWallet(id);
    return true;
  }

  Future<void> transferRemainingBalance({
    required String fromId,
    required String toId,
    String? note,
  }) async {
    final fromBal = getWalletBalance(fromId);
    if (fromBal <= 0) return;

    final fromWallet = _wallets.firstWhere((w) => w.id == fromId, orElse: () => _wallets.first);

    final tx = TransactionModel(
      id: TransactionModel.generateId(),
      title: 'تحويل تصفية رصيد',
      amount: fromBal,
      currency: fromWallet.currency,
      type: TransactionType.transfer,
      categoryId: 'other_exp',
      walletId: fromId,
      toWalletId: toId,
      date: DateTime.now(),
      note: note ?? 'تصفية رصيد قبل حذف المساحة',
    );
    await addTransaction(tx);
  }

  Future<void> _saveWallets() async {
    final prefs = await SharedPreferences.getInstance();
    final str = json.encode(_wallets.map((w) => w.toMap()).toList());
    await prefs.setString(_keyWallets, str);
  }

  double getWalletBalance(String walletId) {
    final wallet = _wallets.firstWhere((w) => w.id == walletId, orElse: () => _wallets.first);
    double balance = wallet.initialBalance;

    for (final tx in _transactions) {
      if (tx.type == TransactionType.income && tx.walletId == walletId) {
        balance += tx.amount;
      } else if (tx.type == TransactionType.expense && tx.walletId == walletId) {
        balance -= tx.amount;
      } else if (tx.type == TransactionType.transfer) {
        if (tx.walletId == walletId) {
          balance -= tx.amount; // Outgoing
        } else if (tx.toWalletId == walletId) {
          balance += tx.amount; // Incoming
        }
      }
    }
    return balance;
  }

  double get totalNetBalance {
    double total = 0.0;
    for (final wallet in _wallets) {
      total += getWalletBalance(wallet.id);
    }
    return total;
  }

  // --- Daily Stats ---
  double getDailyIncome(DateTime date) {
    return _transactions
        .where((t) =>
            t.type == TransactionType.income &&
            t.date.year == date.year &&
            t.date.month == date.month &&
            t.date.day == date.day)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getDailyExpense(DateTime date) {
    return _transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.date.year == date.year &&
            t.date.month == date.month &&
            t.date.day == date.day)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  Map<String, double> getDailyCategoryExpenses(DateTime date) {
    final Map<String, double> map = {};
    for (final t in _transactions) {
      if (t.type == TransactionType.expense &&
          t.date.year == date.year &&
          t.date.month == date.month &&
          t.date.day == date.day) {
        map[t.categoryId] = (map[t.categoryId] ?? 0.0) + t.amount;
      }
    }
    return map;
  }

  // --- Monthly Stats ---
  double getMonthlyIncome(DateTime date) {
    return _transactions
        .where((t) =>
            t.type == TransactionType.income &&
            t.date.year == date.year &&
            t.date.month == date.month)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getMonthlyExpense(DateTime date) {
    return _transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.date.year == date.year &&
            t.date.month == date.month)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  Map<String, double> getCategoryExpenses(DateTime date) {
    final Map<String, double> map = {};
    for (final t in _transactions) {
      if (t.type == TransactionType.expense &&
          t.date.year == date.year &&
          t.date.month == date.month) {
        map[t.categoryId] = (map[t.categoryId] ?? 0.0) + t.amount;
      }
    }
    return map;
  }

  // --- Budgets ---
  BudgetModel? getBudgetForCategory(String categoryId, String monthKey) {
    try {
      return _budgets.firstWhere(
        (b) => b.categoryId == categoryId && b.monthKey == monthKey,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> setBudget(String categoryId, double limit, String monthKey) async {
    _budgets.removeWhere((b) => b.categoryId == categoryId && b.monthKey == monthKey);
    if (limit > 0) {
      _budgets.add(BudgetModel(categoryId: categoryId, limitAmount: limit, monthKey: monthKey));
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBudgets, json.encode(_budgets.map((b) => b.toMap()).toList()));
    notifyListeners();
  }

  // --- Debts ---
  Future<void> addDebt(Debt debt) async {
    _debts.insert(0, debt);
    await StorageService.saveDebts(_debts);
    notifyListeners();
    SyncService.instance.scheduleCloudSync();
  }

  Future<void> editDebt(Debt debt) async {
    final idx = _debts.indexWhere((d) => d.id == debt.id);
    if (idx != -1) {
      _debts[idx] = debt;
      await StorageService.saveDebts(_debts);
      notifyListeners();
      SyncService.instance.scheduleCloudSync();
    }
  }

  Future<void> toggleDebtPaid(String id) async {
    final idx = _debts.indexWhere((d) => d.id == id);
    if (idx != -1) {
      final current = _debts[idx];
      _debts[idx] = current.copyWith(isPaid: !current.isPaid);
      await StorageService.saveDebts(_debts);
      notifyListeners();
      SyncService.instance.scheduleCloudSync();
    }
  }

  Future<void> deleteDebt(String id) async {
    _debts.removeWhere((d) => d.id == id);
    await StorageService.saveDebts(_debts);
    notifyListeners();
    SyncService.instance.scheduleCloudSync();
  }

  Future<void> addVersement(String debtId, DebtVersement versement) async {
    final idx = _debts.indexWhere((d) => d.id == debtId);
    if (idx != -1) {
      final current = _debts[idx];
      final newVersements = List<DebtVersement>.from(current.versements)..insert(0, versement);
      final totalPaid = newVersements.fold<double>(0.0, (sum, v) => sum + v.amount);
      final isNowPaid = totalPaid >= current.amount;
      _debts[idx] = current.copyWith(
        versements: newVersements,
        isPaid: isNowPaid,
      );
      await StorageService.saveDebts(_debts);
      notifyListeners();
      SyncService.instance.scheduleCloudSync();
    }
  }

  Future<void> deleteVersement(String debtId, String versementId) async {
    final idx = _debts.indexWhere((d) => d.id == debtId);
    if (idx != -1) {
      final current = _debts[idx];
      final newVersements = current.versements.where((v) => v.id != versementId).toList();
      final totalPaid = newVersements.fold<double>(0.0, (sum, v) => sum + v.amount);
      _debts[idx] = current.copyWith(
        versements: newVersements,
        isPaid: totalPaid >= current.amount,
      );
      await StorageService.saveDebts(_debts);
      notifyListeners();
      SyncService.instance.scheduleCloudSync();
    }
  }

  double get totalDebtsFromMeUnpaid {
    return _debts
        .where((d) => !d.isFullyPaid && d.type == DebtType.fromMe)
        .fold(0.0, (sum, d) => sum + d.remainingAmount);
  }

  double get totalDebtsToMeUnpaid {
    return _debts
        .where((d) => !d.isFullyPaid && d.type == DebtType.toMe)
        .fold(0.0, (sum, d) => sum + d.remainingAmount);
  }

  // --- CSV Export ---
  Future<String?> exportCsvReport() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final fileName = 'Kredi_Report_${now.year}_${now.month}_${now.day}.csv';
      final file = File('${dir.path}/$fileName');

      final buffer = StringBuffer();
      // Add UTF-8 BOM for Excel compatibility with Arabic
      buffer.write('\uFEFF');

      // Transactions Section
      buffer.writeln('=== سجل المعاملات المالية (Transactions) ===');
      buffer.writeln('المعرف,التاريخ,النوع,التصنيف,المحفظة,المبلغ,ملاحظة');
      for (final tx in _transactions) {
        final cat = CategoryModel.getById(tx.categoryId);
        final w = _wallets.firstWhere((w) => w.id == tx.walletId, orElse: () => _wallets.first);
        final typeStr = tx.type == TransactionType.income
            ? 'دخل'
            : (tx.type == TransactionType.expense ? 'مصروف' : 'تحويل');
        buffer.writeln(
            '"${tx.id}","${tx.date.toString().substring(0, 16)}","$typeStr","${cat.nameAr}","${w.name}","${tx.amount}","${tx.note ?? ''}"');
      }

      buffer.writeln();
      buffer.writeln('=== سجل الديون (Debts) ===');
      buffer.writeln('المعرف,الاسم,النوع,المبلغ,التاريخ,الحالة,ملاحظة');
      for (final d in _debts) {
        final typeStr = d.type == DebtType.toMe ? 'دين لي (أطلبه منه)' : 'دين عليّ (يطلبه مني)';
        final statusStr = d.isPaid ? 'مسدد' : 'غير مسدد';
        buffer.writeln(
            '"${d.id}","${d.personName}","$typeStr","${d.amount}","${d.date.toString().substring(0, 10)}","$statusStr","${d.note ?? ''}"');
      }

      await file.writeAsString(buffer.toString());
      await OpenFilex.open(file.path);
      return file.path;
    } catch (e) {
      return null;
    }
  }
}

