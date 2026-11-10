import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/category_model.dart';
import '../models/debt_model.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';
import '../services/category_service.dart';
import '../services/finance_service.dart';
import '../services/settings_service.dart';
import '../utils/formatters.dart';
import 'add_category_sheet.dart';
import 'bouncing_button.dart';

class OperationMeta {
  final String title;
  final String shortTitle;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String actionLabel;

  const OperationMeta({
    required this.title,
    required this.shortTitle,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.actionLabel,
  });
}

class AddOperationSheet extends StatefulWidget {
  final int initialIndex;

  const AddOperationSheet({
    super.key,
    this.initialIndex = 0, // 0 = Transfer (Default)
  });

  static Future<void> show(
    BuildContext context, {
    int initialIndex = 0,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(120),
      builder: (_) => AddOperationSheet(initialIndex: initialIndex),
    );
  }

  @override
  State<AddOperationSheet> createState() => _AddOperationSheetState();
}

class _AddOperationSheetState extends State<AddOperationSheet>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  double _slideDirection = 1.0; // 1.0 = right-to-left, -1.0 = left-to-right

  // Form Controllers
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  final _debtPersonController = TextEditingController();
  final _debtPhoneController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  late String _selectedWalletId;
  String? _selectedToWalletId;
  late String _selectedCategoryId;
  DebtType _debtType = DebtType.fromMe; // Default: عليّ (أنا مدين)

  bool _isSuccess = false;
  final _formKey = GlobalKey<FormState>();

  // Operations Definition in Required Circular Order
  static const List<OperationMeta> _operations = [
    OperationMeta(
      title: 'أخذ / تحويل',
      shortTitle: 'أخذ / تحويل',
      subtitle: 'نقل رصيد بين مساحاتك المالية الخاصة',
      icon: Icons.swap_horiz_rounded,
      color: Color(0xFF3B82F6), // Blue
      actionLabel: 'تأكيد التحويل',
    ),
    OperationMeta(
      title: 'تسجيل مصروف',
      shortTitle: 'مصروف',
      subtitle: 'خصم مبلغ من رصيدك وتسجيله كمصروف',
      icon: Icons.arrow_downward_rounded,
      color: Color(0xFFEF4444), // Red
      actionLabel: 'حفظ المصروف',
    ),
    OperationMeta(
      title: 'تسجيل دخل',
      shortTitle: 'دخل',
      subtitle: 'إضافة مبلغ جديد إلى رصيدك المالي',
      icon: Icons.arrow_upward_rounded,
      color: Color(0xFF10B981), // Green
      actionLabel: 'حفظ الدخل',
    ),
    OperationMeta(
      title: 'تسجيل دَين',
      shortTitle: 'دَين',
      subtitle: 'تسجيل دين لك أو عليك مع تاريخ الاستحقاق',
      icon: Icons.handshake_rounded,
      color: Color(0xFF8B5CF6), // Purple
      actionLabel: 'حفظ الدَّين',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 3);

    final finance = FinanceService.instance;
    final defaultWallet =
        finance.wallets.isNotEmpty ? finance.wallets.first.id : 'cash';
    _selectedWalletId = defaultWallet;

    if (finance.wallets.length > 1) {
      _selectedToWalletId = finance.wallets[1].id;
    }

    _updateCategoryForCurrentType();
    CategoryService.categoriesNotifier.addListener(_onCategoriesChanged);
  }

  @override
  void dispose() {
    CategoryService.categoriesNotifier.removeListener(_onCategoriesChanged);
    _amountController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    _debtPersonController.dispose();
    _debtPhoneController.dispose();
    super.dispose();
  }

  void _onCategoriesChanged() {
    if (mounted) {
      setState(() {
        _updateCategoryForCurrentType();
      });
    }
  }

  void _updateCategoryForCurrentType() {
    final catType = _currentIndex == 2 ? CategoryType.income : CategoryType.expense;
    final cats = CategoryService.getCategoriesForType(catType);
    if (!cats.any((c) => c.id == _selectedCategoryId)) {
      _selectedCategoryId = cats.isNotEmpty ? cats.first.id : 'other';
    }
  }

  void _switchToIndex(int newIndex, {double? direction}) {
    if (_currentIndex == newIndex) return;
    HapticFeedback.lightImpact();
    setState(() {
      _slideDirection = direction ?? (newIndex > _currentIndex ? 1.0 : -1.0);
      _currentIndex = newIndex;
      _updateCategoryForCurrentType();
    });
  }

  void _nextOperation() {
    HapticFeedback.selectionClick();
    setState(() {
      _slideDirection = 1.0;
      _currentIndex = (_currentIndex + 1) % _operations.length;
      _updateCategoryForCurrentType();
    });
  }

  void _prevOperation() {
    HapticFeedback.selectionClick();
    setState(() {
      _slideDirection = -1.0;
      _currentIndex = (_currentIndex - 1 + _operations.length) % _operations.length;
      _updateCategoryForCurrentType();
    });
  }

  void _handleHorizontalDrag(DragEndDetails details) {
    final vx = details.primaryVelocity ?? 0;
    // Right drag (velocity > 0) -> Next circular operation
    if (vx > 180) {
      _nextOperation();
    }
    // Left drag (velocity < 0) -> Previous circular operation
    else if (vx < -180) {
      _prevOperation();
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: Localizations.localeOf(context),
      builder: (context, child) {
        final activeColor = _operations[_currentIndex].color;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: activeColor,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
      builder: (context, child) {
        final activeColor = _operations[_currentIndex].color;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: activeColor,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedTime != null) {
      setState(() {
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final finance = FinanceService.instance;
    final amount = double.tryParse(_amountController.text.trim().replaceAll(',', '.')) ?? 0.0;
    final note = _noteController.text.trim().isEmpty ? null : _noteController.text.trim();
    final title = _titleController.text.trim();

    final sourceWallet = finance.wallets.firstWhere(
      (w) => w.id == _selectedWalletId,
      orElse: () => finance.wallets.isNotEmpty ? finance.wallets.first : WalletModel.defaultWallets.first,
    );

    // 0: Transfer
    if (_currentIndex == 0) {
      if (_selectedToWalletId == null || _selectedToWalletId == _selectedWalletId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يرجى اختيار مساحتين ماليتين مختلفتين للتحويل'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
        return;
      }

      final destWallet = finance.wallets.firstWhere(
        (w) => w.id == _selectedToWalletId,
        orElse: () => finance.wallets.first,
      );

      if (sourceWallet.currency != destWallet.currency) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('لا يمكن التحويل المباشر بين عملتين مختلفتين (${sourceWallet.currency} و ${destWallet.currency})'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
        return;
      }

      final available = finance.getWalletBalance(sourceWallet.id);
      if (amount > available) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('الرصيد غير كافٍ في "${sourceWallet.name}"! المتوفر: ${Formatters.formatAmount(available, currency: sourceWallet.currency)}'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
        return;
      }

      final defaultTitle = 'أخذ من ${sourceWallet.name} إلى ${destWallet.name}';
      final tx = TransactionModel(
        id: TransactionModel.generateId(),
        title: title.isEmpty ? defaultTitle : title,
        amount: amount,
        currency: sourceWallet.currency,
        type: TransactionType.transfer,
        categoryId: 'transfer',
        walletId: _selectedWalletId,
        toWalletId: _selectedToWalletId,
        date: _selectedDate,
        note: note,
      );
      await finance.addTransaction(tx);
    }
    // 1: Expense
    else if (_currentIndex == 1) {
      final cat = CategoryService.getById(_selectedCategoryId);
      final tx = TransactionModel(
        id: TransactionModel.generateId(),
        title: title.isEmpty ? cat.nameAr : title,
        amount: amount,
        currency: sourceWallet.currency,
        type: TransactionType.expense,
        categoryId: _selectedCategoryId,
        walletId: _selectedWalletId,
        date: _selectedDate,
        note: note,
      );
      await finance.addTransaction(tx);
    }
    // 2: Income
    else if (_currentIndex == 2) {
      final cat = CategoryService.getById(_selectedCategoryId);
      final tx = TransactionModel(
        id: TransactionModel.generateId(),
        title: title.isEmpty ? cat.nameAr : title,
        amount: amount,
        currency: sourceWallet.currency,
        type: TransactionType.income,
        categoryId: _selectedCategoryId,
        walletId: _selectedWalletId,
        date: _selectedDate,
        note: note,
      );
      await finance.addTransaction(tx);
    }
    // 3: Debt
    else if (_currentIndex == 3) {
      final personName = _debtPersonController.text.trim();
      final phone = _debtPhoneController.text.trim().isEmpty ? null : _debtPhoneController.text.trim();

      final debt = Debt(
        id: Debt.generateId(),
        personName: personName,
        amount: amount,
        note: note,
        date: _selectedDate,
        isPaid: false,
        type: _debtType,
        phoneNumber: phone,
      );
      await finance.addDebt(debt);
    }

    // Success Animation
    HapticFeedback.mediumImpact();
    setState(() => _isSuccess = true);
    await Future.delayed(const Duration(milliseconds: 550));
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentMeta = _operations[_currentIndex];
    final activeColor = currentMeta.color;

    final sheetBg = isDark ? const Color(0xFF111416) : Colors.white;
    final borderCol = isDark ? const Color(0xFF242A2E) : const Color(0xFFE2E8F0);
    final textCol = isDark ? Colors.white : const Color(0xFF0F172A);
    final subTextCol = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.90;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      margin: EdgeInsets.only(
        top: mediaQuery.padding.top + 20,
        bottom: mediaQuery.viewInsets.bottom,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: sheetBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border(
                top: BorderSide(color: activeColor.withAlpha(isDark ? 90 : 120), width: 2),
              ),
              boxShadow: [
                BoxShadow(
                  color: activeColor.withAlpha(isDark ? 40 : 25),
                  blurRadius: 32,
                  spreadRadius: 2,
                  offset: const Offset(0, -4),
                ),
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 160 : 40),
                  blurRadius: 30,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Stack(
              children: [
                SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      // Fixed Top Section: Grabber, Navigation Bar & Hero Card
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Grabber
                            Center(
                              child: Container(
                                width: 42,
                                height: 4.5,
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white24 : Colors.black12,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Top Header with Close Button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Close Button
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => Navigator.pop(context),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1E2428) : const Color(0xFFF1F5F9),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: borderCol, width: 1),
                                      ),
                                      child: Icon(Icons.close_rounded, size: 18, color: textCol),
                                    ),
                                  ),
                                ),

                                // Pill Tabs Row (Interactive circular operation selector)
                                Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 10),
                                    padding: const EdgeInsets.all(3.5),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF191F23) : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: borderCol, width: 1),
                                    ),
                                    child: Row(
                                      children: List.generate(_operations.length, (idx) {
                                        final op = _operations[idx];
                                        final isSelected = _currentIndex == idx;
                                        return Expanded(
                                          child: GestureDetector(
                                            onTap: () => _switchToIndex(idx),
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 240),
                                              curve: Curves.easeOutCubic,
                                              padding: const EdgeInsets.symmetric(vertical: 7),
                                              decoration: BoxDecoration(
                                                color: isSelected ? op.color : Colors.transparent,
                                                borderRadius: BorderRadius.circular(16),
                                                boxShadow: isSelected
                                                    ? [
                                                        BoxShadow(
                                                          color: op.color.withAlpha(90),
                                                          blurRadius: 8,
                                                          offset: const Offset(0, 2),
                                                        ),
                                                      ]
                                                    : [],
                                              ),
                                              alignment: Alignment.center,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    op.icon,
                                                    size: 14,
                                                    color: isSelected ? Colors.white : subTextCol,
                                                  ),
                                                  if (isSelected) ...[
                                                    const SizedBox(width: 4),
                                                    Flexible(
                                                      child: Text(
                                                        op.shortTitle,
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                ),

                                // Step indicator badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: activeColor.withAlpha(25),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: activeColor.withAlpha(80), width: 1),
                                  ),
                                  child: Text(
                                    '${_currentIndex + 1} / 4',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: activeColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Swipeable Hero Card Banner
                            GestureDetector(
                              onHorizontalDragEnd: _handleHorizontalDrag,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 260),
                                curve: Curves.easeOutCubic,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      activeColor.withAlpha(isDark ? 35 : 20),
                                      activeColor.withAlpha(isDark ? 15 : 10),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: activeColor.withAlpha(isDark ? 70 : 90),
                                    width: 1.3,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Previous Arrow Button
                                    BouncingButton(
                                      scaleFactor: 0.88,
                                      onTap: _prevOperation,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF1E2428) : Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: borderCol, width: 1),
                                        ),
                                        child: Icon(Icons.chevron_right_rounded, size: 20, color: textCol),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Icon with animated glow
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 260),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: activeColor,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: activeColor.withAlpha(110),
                                            blurRadius: 12,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 220),
                                        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                                        child: Icon(
                                          currentMeta.icon,
                                          key: ValueKey<IconData>(currentMeta.icon),
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Titles
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          AnimatedSwitcher(
                                            duration: const Duration(milliseconds: 220),
                                            transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                                            child: Text(
                                              currentMeta.title,
                                              key: ValueKey<String>(currentMeta.title),
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: textCol,
                                                letterSpacing: -0.2,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            currentMeta.subtitle,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: subTextCol,
                                              height: 1.25,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Next Arrow Button
                                    BouncingButton(
                                      scaleFactor: 0.88,
                                      onTap: _nextOperation,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF1E2428) : Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: borderCol, width: 1),
                                        ),
                                        child: Icon(Icons.chevron_left_rounded, size: 20, color: textCol),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Divider(height: 1),

                      // Form Body (With Gesture Detector for Swiping & Smooth AnimatedSwitcher)
                      Expanded(
                        child: GestureDetector(
                          onHorizontalDragEnd: _handleHorizontalDrag,
                          child: Form(
                            key: _formKey,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 260),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, anim) {
                                final offsetTween = Tween<Offset>(
                                  begin: Offset(_slideDirection * 0.10, 0),
                                  end: Offset.zero,
                                );
                                return FadeTransition(
                                  opacity: anim,
                                  child: SlideTransition(
                                    position: offsetTween.animate(anim),
                                    child: child,
                                  ),
                                );
                              },
                              child: KeyedSubtree(
                                key: ValueKey<int>(_currentIndex),
                                child: SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                                  child: _buildCurrentFormContent(isDark, textCol, subTextCol, borderCol),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Pinned Bottom Submit Button
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                        decoration: BoxDecoration(
                          color: sheetBg,
                          border: Border(top: BorderSide(color: borderCol, width: 1)),
                        ),
                        child: BouncingButton(
                          scaleFactor: 0.95,
                          onTap: _submit,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 240),
                            height: 52,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                colors: [
                                  activeColor,
                                  activeColor.withAlpha(220),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: activeColor.withAlpha(100),
                                  blurRadius: 18,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _currentIndex == 0
                                        ? Icons.swap_horiz_rounded
                                        : Icons.check_circle_outline_rounded,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    currentMeta.actionLabel,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Success Overlay Animation
                if (_isSuccess)
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        color: Colors.black.withAlpha(120),
                        child: Center(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.elasticOut,
                            builder: (context, scale, child) {
                              return Transform.scale(
                                scale: scale,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                                  decoration: BoxDecoration(
                                    color: sheetBg,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: activeColor, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: activeColor.withAlpha(120),
                                        blurRadius: 30,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: activeColor,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'تم الحفظ بنجاح ✓',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: textCol,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Current Form Builder ---
  Widget _buildCurrentFormContent(
    bool isDark,
    Color textCol,
    Color subTextCol,
    Color borderCol,
  ) {
    switch (_currentIndex) {
      case 0:
        return _buildTransferForm(isDark, textCol, subTextCol, borderCol);
      case 1:
        return _buildExpenseForm(isDark, textCol, subTextCol, borderCol);
      case 2:
        return _buildIncomeForm(isDark, textCol, subTextCol, borderCol);
      case 3:
        return _buildDebtForm(isDark, textCol, subTextCol, borderCol);
      default:
        return const SizedBox();
    }
  }

  // ==========================================
  // 1. TRANSFER FORM (أخذ / تحويل)
  // ==========================================
  Widget _buildTransferForm(bool isDark, Color textCol, Color subTextCol, Color borderCol) {
    final finance = FinanceService.instance;
    final wallets = finance.wallets;
    final color = _operations[0].color;

    final sourceWallet = wallets.firstWhere(
      (w) => w.id == _selectedWalletId,
      orElse: () => wallets.isNotEmpty ? wallets.first : WalletModel.defaultWallets.first,
    );
    final destWallet = _selectedToWalletId != null
        ? wallets.firstWhere((w) => w.id == _selectedToWalletId, orElse: () => sourceWallet)
        : null;

    final isMismatch = destWallet != null && sourceWallet.currency != destWallet.currency;
    final sourceBalance = finance.getWalletBalance(sourceWallet.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Amount Field
        _buildAmountInput(color: color, isDark: isDark, textCol: textCol, currency: sourceWallet.currency),
        const SizedBox(height: 18),

        // Wallet Selection (From / To)
        if (wallets.length < 2)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withAlpha(isDark ? 30 : 20),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.amber.withAlpha(80)),
            ),
            child: const Text(
              'تنبيه: يجب أن تمتلك مساحتين ماليتين على الأقل لإجراء عملية تحويل بينهما.',
              style: TextStyle(fontSize: 12, color: Colors.amber),
            ),
          )
        else ...[
          // Source Wallet
          _buildSectionHeader('من المساحة المالية (المصدر):', textCol),
          const SizedBox(height: 8),
          _buildWalletSelector(
            wallets: wallets,
            selectedId: _selectedWalletId,
            activeColor: color,
            isDark: isDark,
            onSelected: (id) => setState(() => _selectedWalletId = id),
          ),
          const SizedBox(height: 6),
          Text(
            'الرصيد المتاح: ${Formatters.formatAmount(sourceBalance, currency: sourceWallet.currency)}',
            style: TextStyle(fontSize: 11.5, color: subTextCol),
          ),
          const SizedBox(height: 16),

          // Destination Wallet
          _buildSectionHeader('إلى المساحة المالية (الوجهة):', textCol),
          const SizedBox(height: 8),
          _buildWalletSelector(
            wallets: wallets,
            selectedId: _selectedToWalletId,
            activeColor: color,
            isDark: isDark,
            disabledId: _selectedWalletId,
            onSelected: (id) => setState(() => _selectedToWalletId = id),
          ),
        ],

        if (isMismatch) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withAlpha(25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEF4444).withAlpha(80)),
            ),
            child: Text(
              'لا يمكن التحويل المباشر بين عملتين مختلفتين (${sourceWallet.currency} ≠ ${destWallet.currency})',
              style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
            ),
          ),
        ],

        const SizedBox(height: 18),
        // Date & Time
        _buildDateTimeRow(isDark: isDark, textCol: textCol, activeColor: color),
        const SizedBox(height: 14),

        // Optional Note
        _buildTextInput(
          controller: _noteController,
          label: 'ملاحظة أو بيان التحويل (اختياري)',
          icon: Icons.note_alt_outlined,
          isDark: isDark,
          textCol: textCol,
          borderCol: borderCol,
        ),
      ],
    );
  }

  // ==========================================
  // 2. EXPENSE FORM (مصروف)
  // ==========================================
  Widget _buildExpenseForm(bool isDark, Color textCol, Color subTextCol, Color borderCol) {
    final finance = FinanceService.instance;
    final wallets = finance.wallets;
    final color = _operations[1].color;
    final categories = CategoryService.expenseCategories;

    final sourceWallet = wallets.firstWhere(
      (w) => w.id == _selectedWalletId,
      orElse: () => wallets.isNotEmpty ? wallets.first : WalletModel.defaultWallets.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Amount Field
        _buildAmountInput(color: color, isDark: isDark, textCol: textCol, currency: sourceWallet.currency),
        const SizedBox(height: 16),

        // Space / Wallet Selection
        _buildSectionHeader('المساحة المالية المخصوم منها:', textCol),
        const SizedBox(height: 8),
        _buildWalletSelector(
          wallets: wallets,
          selectedId: _selectedWalletId,
          activeColor: color,
          isDark: isDark,
          onSelected: (id) => setState(() => _selectedWalletId = id),
        ),
        const SizedBox(height: 16),

        // Category Selector
        _buildSectionHeader('التصنيف:', textCol),
        const SizedBox(height: 8),
        _buildCategorySelector(
          categories: categories,
          selectedId: _selectedCategoryId,
          activeColor: color,
          isDark: isDark,
          textCol: textCol,
          type: CategoryType.expense,
        ),
        const SizedBox(height: 16),

        // Title / Description
        _buildTextInput(
          controller: _titleController,
          label: 'البيان أو الوصف (اختياري)',
          icon: Icons.title_rounded,
          isDark: isDark,
          textCol: textCol,
          borderCol: borderCol,
        ),
        const SizedBox(height: 14),

        // Date & Time
        _buildDateTimeRow(isDark: isDark, textCol: textCol, activeColor: color),
        const SizedBox(height: 14),

        // Note
        _buildTextInput(
          controller: _noteController,
          label: 'ملاحظة إضافية (اختياري)',
          icon: Icons.note_alt_outlined,
          isDark: isDark,
          textCol: textCol,
          borderCol: borderCol,
        ),
      ],
    );
  }

  // ==========================================
  // 3. INCOME FORM (دخل)
  // ==========================================
  Widget _buildIncomeForm(bool isDark, Color textCol, Color subTextCol, Color borderCol) {
    final finance = FinanceService.instance;
    final wallets = finance.wallets;
    final color = _operations[2].color;
    final categories = CategoryService.incomeCategories;

    final sourceWallet = wallets.firstWhere(
      (w) => w.id == _selectedWalletId,
      orElse: () => wallets.isNotEmpty ? wallets.first : WalletModel.defaultWallets.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Amount Field
        _buildAmountInput(color: color, isDark: isDark, textCol: textCol, currency: sourceWallet.currency),
        const SizedBox(height: 16),

        // Space / Wallet Selection
        _buildSectionHeader('المساحة المالية المودع فيها:', textCol),
        const SizedBox(height: 8),
        _buildWalletSelector(
          wallets: wallets,
          selectedId: _selectedWalletId,
          activeColor: color,
          isDark: isDark,
          onSelected: (id) => setState(() => _selectedWalletId = id),
        ),
        const SizedBox(height: 16),

        // Category Selector
        _buildSectionHeader('التصنيف:', textCol),
        const SizedBox(height: 8),
        _buildCategorySelector(
          categories: categories,
          selectedId: _selectedCategoryId,
          activeColor: color,
          isDark: isDark,
          textCol: textCol,
          type: CategoryType.income,
        ),
        const SizedBox(height: 16),

        // Title / Description
        _buildTextInput(
          controller: _titleController,
          label: 'البيان أو الوصف (اختياري)',
          icon: Icons.title_rounded,
          isDark: isDark,
          textCol: textCol,
          borderCol: borderCol,
        ),
        const SizedBox(height: 14),

        // Date & Time
        _buildDateTimeRow(isDark: isDark, textCol: textCol, activeColor: color),
        const SizedBox(height: 14),

        // Note
        _buildTextInput(
          controller: _noteController,
          label: 'ملاحظة إضافية (اختياري)',
          icon: Icons.note_alt_outlined,
          isDark: isDark,
          textCol: textCol,
          borderCol: borderCol,
        ),
      ],
    );
  }

  // ==========================================
  // 4. DEBT FORM (دَين)
  // ==========================================
  Widget _buildDebtForm(bool isDark, Color textCol, Color subTextCol, Color borderCol) {
    final color = _operations[3].color;
    final currency = SettingsService.currencyNotifier.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Debt Type Segmented Toggle (عليّ / لي)
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2428) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderCol, width: 1),
          ),
          child: Row(
            children: [
              // عليّ (دين عليّ - أنا مدين)
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _debtType = DebtType.fromMe),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _debtType == DebtType.fromMe ? const Color(0xFFEF4444) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _debtType == DebtType.fromMe
                          ? [
                              BoxShadow(
                                color: const Color(0xFFEF4444).withAlpha(80),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'دين عليّ (أنا مدين)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _debtType == DebtType.fromMe ? Colors.white : subTextCol,
                      ),
                    ),
                  ),
                ),
              ),
              // لي (دين لي - الآخر مدين لي)
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _debtType = DebtType.toMe),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _debtType == DebtType.toMe ? const Color(0xFF10B981) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _debtType == DebtType.toMe
                          ? [
                              BoxShadow(
                                color: const Color(0xFF10B981).withAlpha(80),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'دين لي (أنا الدائن)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _debtType == DebtType.toMe ? Colors.white : subTextCol,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Person Name Field
        TextFormField(
          controller: _debtPersonController,
          style: TextStyle(color: textCol, fontSize: 14),
          decoration: InputDecoration(
            labelText: 'اسم الشخص *',
            prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
            filled: true,
            fillColor: isDark ? const Color(0xFF1A1F23) : const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: borderCol),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: color, width: 1.5),
            ),
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'يرجى إدخال اسم الشخص';
            }
            return null;
          },
        ),
        const SizedBox(height: 14),

        // Amount Field
        _buildAmountInput(color: color, isDark: isDark, textCol: textCol, currency: currency),
        const SizedBox(height: 14),

        // Phone Number (Optional)
        _buildTextInput(
          controller: _debtPhoneController,
          label: 'رقم الهاتف (اختياري)',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          isDark: isDark,
          textCol: textCol,
          borderCol: borderCol,
        ),
        const SizedBox(height: 14),

        // Date & Time
        _buildDateTimeRow(isDark: isDark, textCol: textCol, activeColor: color),
        const SizedBox(height: 14),

        // Note
        _buildTextInput(
          controller: _noteController,
          label: 'ملاحظة حول الدين (اختياري)',
          icon: Icons.note_alt_outlined,
          isDark: isDark,
          textCol: textCol,
          borderCol: borderCol,
        ),
      ],
    );
  }

  // ==========================================
  // SHARED INPUT WIDGETS
  // ==========================================
  Widget _buildAmountInput({
    required Color color,
    required bool isDark,
    required Color textCol,
    required String currency,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF191F23) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(isDark ? 80 : 100), width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: textCol,
                letterSpacing: -0.5,
              ),
              decoration: const InputDecoration(
                hintText: '0.00',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'يرجى إدخال المبلغ';
                }
                final num = double.tryParse(val.trim().replaceAll(',', '.'));
                if (num == null || num <= 0) {
                  return 'يرجى إدخال مبلغ صحيح أكبر من صفر';
                }
                return null;
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withAlpha(70), width: 1),
            ),
            child: Text(
              currency,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textCol) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: textCol,
      ),
    );
  }

  Widget _buildWalletSelector({
    required List<WalletModel> wallets,
    required String? selectedId,
    required Color activeColor,
    required bool isDark,
    String? disabledId,
    required ValueChanged<String> onSelected,
  }) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: wallets.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, idx) {
          final w = wallets[idx];
          final isSelected = w.id == selectedId;
          final isDisabled = w.id == disabledId;

          return GestureDetector(
            onTap: isDisabled ? null : () => onSelected(w.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor
                    : (isDisabled
                        ? (isDark ? Colors.white10 : Colors.black12)
                        : (isDark ? const Color(0xFF1E2428) : const Color(0xFFF1F5F9))),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? activeColor : (isDark ? Colors.white12 : Colors.black12),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 16,
                    color: isSelected ? Colors.white : (isDisabled ? Colors.grey : null),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    w.name,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : (isDisabled ? Colors.grey : null),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategorySelector({
    required List<CategoryModel> categories,
    required String selectedId,
    required Color activeColor,
    required bool isDark,
    required Color textCol,
    required CategoryType type,
  }) {
    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, idx) {
          if (idx == categories.length) {
            // Add Custom Category Button
            return GestureDetector(
              onTap: () async {
                final newCat = await AddCategorySheet.show(context, defaultType: type);
                if (newCat != null) {
                  setState(() => _selectedCategoryId = newCat.id);
                }
              },
              child: Container(
                width: 64,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2428) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: activeColor.withAlpha(60), style: BorderStyle.solid),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, color: activeColor, size: 24),
                    const SizedBox(height: 4),
                    Text(
                      'إضافة',
                      style: TextStyle(fontSize: 10, color: activeColor, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            );
          }

          final cat = categories[idx];
          final isSelected = cat.id == selectedId;

          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryId = cat.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 68,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected ? activeColor.withAlpha(isDark ? 50 : 30) : (isDark ? const Color(0xFF1E2428) : const Color(0xFFF8FAFC)),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? activeColor : (isDark ? Colors.white12 : Colors.black12),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: cat.color.withAlpha(isSelected ? 255 : 40),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(cat.icon, size: 16, color: isSelected ? Colors.white : cat.color),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cat.nameAr,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? activeColor : textCol,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateTimeRow({
    required bool isDark,
    required Color textCol,
    required Color activeColor,
  }) {
    return Row(
      children: [
        // Date
        Expanded(
          child: GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2428) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 16, color: activeColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      Formatters.formatDayHeader(_selectedDate),
                      style: TextStyle(fontSize: 12.5, color: textCol),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Time
        Expanded(
          child: GestureDetector(
            onTap: _pickTime,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2428) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 16, color: activeColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      Formatters.formatTime(_selectedDate),
                      style: TextStyle(fontSize: 12.5, color: textCol),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    required Color textCol,
    required Color borderCol,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: textCol, fontSize: 13.5),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12.5),
        prefixIcon: Icon(icon, size: 18),
        filled: true,
        fillColor: isDark ? const Color(0xFF1A1F23) : const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderCol),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _operations[_currentIndex].color, width: 1.5),
        ),
      ),
    );
  }
}

