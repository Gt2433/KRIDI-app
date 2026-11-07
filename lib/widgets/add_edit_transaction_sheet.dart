hvimport 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';
import '../services/category_service.dart';
import '../services/finance_service.dart';
import '../services/settings_service.dart';
import '../utils/formatters.dart';
import 'add_category_sheet.dart';

class AddEditTransactionSheet extends StatefulWidget {
  final TransactionModel? initialTransaction;
  final TransactionType initialType;

  const AddEditTransactionSheet({
    super.key,
    this.initialTransaction,
    this.initialType = TransactionType.expense,
  });

  static Future<void> show(
    BuildContext context, {
    TransactionModel? initialTransaction,
    TransactionType initialType = TransactionType.expense,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(90),
      builder: (context) => AddEditTransactionSheet(
        initialTransaction: initialTransaction,
        initialType: initialType,
      ),
    );
  }

  @override
  State<AddEditTransactionSheet> createState() => _AddEditTransactionSheetState();
}

class _AddEditTransactionSheetState extends State<AddEditTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  late TransactionType _type;
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late DateTime _selectedDate;
  late String _selectedCategoryId;
  late String _selectedWalletId;
  String? _selectedToWalletId;

  @override
  void initState() {
    super.initState();
    final tx = widget.initialTransaction;
    _type = tx?.type ?? widget.initialType;
    _titleController = TextEditingController(text: tx?.title ?? '');
    _amountController = TextEditingController(
      text: tx != null ? (tx.amount == tx.amount.roundToDouble() ? tx.amount.toInt().toString() : tx.amount.toString()) : '',
    );
    _noteController = TextEditingController(text: tx?.note ?? '');
    _selectedDate = tx?.date ?? DateTime.now();

    final finance = FinanceService.instance;
    final defaultWallet = finance.wallets.isNotEmpty ? finance.wallets.first.id : 'cash';
    _selectedWalletId = tx?.walletId ?? defaultWallet;

    if (finance.wallets.length > 1) {
      _selectedToWalletId = tx?.toWalletId ?? finance.wallets[1].id;
    }

    final catType = _type == TransactionType.income ? CategoryType.income : CategoryType.expense;
    final availableCats = CategoryService.getCategoriesForType(catType);
    _selectedCategoryId = tx?.categoryId ?? (availableCats.isNotEmpty ? availableCats.first.id : 'other_exp');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onTypeChanged(TransactionType newType) {
    setState(() {
      _type = newType;
      final catType = _type == TransactionType.income ? CategoryType.income : CategoryType.expense;
      final availableCats = CategoryService.getCategoriesForType(catType);
      if (!availableCats.any((c) => c.id == _selectedCategoryId)) {
        _selectedCategoryId = availableCats.isNotEmpty ? availableCats.first.id : 'other_exp';
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _typeColor,
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
          _selectedDate.second,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _typeColor,
              onPrimary: Colors.white,
            ),
            timePickerTheme: TimePickerThemeData(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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

  Color get _typeColor {
    switch (_type) {
      case TransactionType.expense:
        return const Color(0xFFEF4444);
      case TransactionType.income:
        return const Color(0xFF10B981);
      case TransactionType.transfer:
        return const Color(0xFF3B82F6);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim().replaceAll(',', '.')) ?? 0.0;
    final title = _titleController.text.trim();
    final note = _noteController.text.trim().isEmpty ? null : _noteController.text.trim();

    final finance = FinanceService.instance;

    if (widget.initialTransaction != null) {
      final updated = widget.initialTransaction!.copyWith(
        title: title.isEmpty ? (_type == TransactionType.transfer ? 'تحويل مالي' : CategoryModel.getById(_selectedCategoryId).nameAr) : title,
        amount: amount,
        type: _type,
        categoryId: _selectedCategoryId,
        walletId: _selectedWalletId,
        toWalletId: _type == TransactionType.transfer ? _selectedToWalletId : null,
        date: _selectedDate,
        note: note,
      );
      finance.editTransaction(updated);
    } else {
      final newTx = TransactionModel(
        id: TransactionModel.generateId(),
        title: title.isEmpty ? (_type == TransactionType.transfer ? 'تحويل مالي' : CategoryModel.getById(_selectedCategoryId).nameAr) : title,
        amount: amount,
        type: _type,
        categoryId: _selectedCategoryId,
        walletId: _selectedWalletId,
        toWalletId: _type == TransactionType.transfer ? _selectedToWalletId : null,
        date: _selectedDate,
        note: note,
      );
      finance.addTransaction(newTx);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderCol = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB);
    final textCol = isDark ? Colors.white : Colors.black;
    final fieldBg = isDark ? const Color(0xFF27272A) : const Color(0xFFF9FAFB);
    final toggleBg = isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6);
    final finance = FinanceService.instance;
    final catType = _type == TransactionType.income ? CategoryType.income : CategoryType.expense;

    return Container(
      margin: EdgeInsets.only(
        top: 50,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: borderCol,
            width: 1.2,
          ),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: borderCol,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header
                Text(
                  widget.initialTransaction != null ? 'تعديل' : 'إضافة',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textCol),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Type Segmented Selector
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: toggleBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      _buildTypeTab('مصروف', TransactionType.expense, const Color(0xFFEF4444), Icons.arrow_downward_rounded),
                      _buildTypeTab('دخل', TransactionType.income, const Color(0xFF16A34A), Icons.arrow_upward_rounded),
                      _buildTypeTab('تحويل', TransactionType.transfer, const Color(0xFF2563EB), Icons.swap_horiz_rounded),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Amount Input Field
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: fieldBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderCol, width: 1.2),
                  ),
                  child: Row(
                    children: [
                      Text(
                        SettingsService.currencyNotifier.value,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _typeColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: _typeColor,
                          ),
                          decoration: const InputDecoration(
                            hintText: '0.00',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.zero,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'يرجى إدخال المبلغ';
                            }
                            final n = double.tryParse(value.trim().replaceAll(',', '.'));
                            if (n == null || n <= 0) {
                              return 'يرجى إدخال مبلغ صحيح أكبر من 0';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Title Input
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'الوصف',
                    prefixIcon: Icon(Icons.edit_note_rounded),
                  ),
                ),
                const SizedBox(height: 16),

                // Category Selection (Only for Expense & Income)
                if (_type != TransactionType.transfer) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'التصنيف',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final newCat = await AddCategorySheet.show(context, defaultType: catType);
                          if (newCat != null) {
                            setState(() => _selectedCategoryId = newCat.id);
                          }
                        },
                        icon: const Icon(Icons.add_rounded, size: 16, color: Colors.black),
                        label: const Text(
                          'تصنيف جديد',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<List<CategoryModel>>(
                    valueListenable: CategoryService.categoriesNotifier,
                    builder: (context, _, child) {
                      final categories = CategoryService.getCategoriesForType(catType);
                      return SizedBox(
                        height: 90,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length + 1,
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemBuilder: (context, idx) {
                            // Quick Add Button at index 0
                            if (idx == 0) {
                              return GestureDetector(
                                onTap: () async {
                                  final newCat = await AddCategorySheet.show(context, defaultType: catType);
                                  if (newCat != null) {
                                    setState(() => _selectedCategoryId = newCat.id);
                                  }
                                },
                                child: Container(
                                  width: 76,
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFAFAFA),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFFE5E7EB),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_circle_outline_rounded,
                                        color: Colors.black87,
                                        size: 26,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'إضافة',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final cat = categories[idx - 1];
                            final isSelected = cat.id == _selectedCategoryId;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedCategoryId = cat.id),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 76,
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                decoration: BoxDecoration(
                                  color: isSelected ? cat.color : cat.color.withAlpha(25),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected ? cat.color : cat.color.withAlpha(80),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      cat.icon,
                                      color: isSelected ? Colors.white : cat.color,
                                      size: 26,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      cat.nameAr,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Wallet Selection
                if (_type == TransactionType.transfer) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('من', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            _buildWalletDropdown(
                              value: _selectedWalletId,
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedWalletId = val);
                              },
                              wallets: finance.wallets,
                            ),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 20),
                        child: Icon(Icons.arrow_forward_rounded, color: Colors.blue),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('إلى', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            _buildWalletDropdown(
                              value: _selectedToWalletId ?? (finance.wallets.isNotEmpty ? finance.wallets.first.id : ''),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedToWalletId = val);
                              },
                              wallets: finance.wallets,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const Text('المحفظة', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildWalletDropdown(
                    value: _selectedWalletId,
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedWalletId = val);
                    },
                    wallets: finance.wallets,
                  ),
                ],
                const SizedBox(height: 16),

                // Date & Time Picker Row
                Row(
                  children: [
                    // Date
                    Expanded(
                      flex: 6,
                      child: InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: fieldBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderCol, width: 1.2),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_rounded, size: 18, color: textCol),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('التاريخ', style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280))),
                                    Text(
                                      Formatters.formatExactDate(_selectedDate),
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textCol),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Time (Hour & Minute)
                    Expanded(
                      flex: 5,
                      child: InkWell(
                        onTap: _pickTime,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: fieldBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderCol, width: 1.2),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.access_time_rounded, size: 18, color: textCol),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('الوقت', style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280))),
                                    Text(
                                      Formatters.formatTime(_selectedDate),
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textCol),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Note
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظة',
                    prefixIcon: Icon(Icons.comment_outlined),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: const Text(
                    'حفظ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeTab(String label, TransactionType type, Color color, IconData icon) {
    final isSelected = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTypeChanged(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.grey),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletDropdown({
    required String value,
    required void Function(String?) onChanged,
    required List<WalletModel> wallets,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fieldBg = isDark ? const Color(0xFF27272A) : const Color(0xFFF9FAFB);
    final borderCol = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB);
    final textCol = isDark ? Colors.white : Colors.black;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: fieldBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol, width: 1.2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: wallets.any((w) => w.id == value) ? value : (wallets.isNotEmpty ? wallets.first.id : null),
          isExpanded: true,
          dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          icon: Icon(Icons.arrow_drop_down_rounded, color: textCol),
          items: wallets.map((w) {
            return DropdownMenuItem<String>(
              value: w.id,
              child: Row(
                children: [
                  Icon(w.icon, size: 18, color: w.color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      w.name,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textCol),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

