import 'package:flutter/material.dart';
import '../models/debt_model.dart';
import '../services/finance_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class AddEditDebtSheet extends StatefulWidget {
  final Debt? initialDebt;
  final ValueChanged<Debt>? onSave;

  const AddEditDebtSheet({super.key, this.initialDebt, this.onSave});

  static Future<void> show(
    BuildContext context, {
    Debt? initialDebt,
    ValueChanged<Debt>? onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(90),
      builder: (_) => AddEditDebtSheet(
        initialDebt: initialDebt,
        onSave: onSave,
      ),
    );
  }

  @override
  State<AddEditDebtSheet> createState() => _AddEditDebtSheetState();
}

class _AddEditDebtSheetState extends State<AddEditDebtSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late TextEditingController _phoneController;
  late DateTime _selectedDate;
  late DebtType _type;

  bool get isEditing => widget.initialDebt != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialDebt?.personName ?? '',
    );
    _amountController = TextEditingController(
      text: widget.initialDebt != null
          ? (widget.initialDebt!.amount == widget.initialDebt!.amount.toInt()
                ? widget.initialDebt!.amount.toInt().toString()
                : widget.initialDebt!.amount.toString())
          : '',
    );
    _noteController = TextEditingController(
      text: widget.initialDebt?.note ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.initialDebt?.phoneNumber ?? '',
    );
    _selectedDate = widget.initialDebt?.date ?? DateTime.now();
    _type = widget.initialDebt?.type ?? DebtType.fromMe;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: Localizations.localeOf(context),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: isDark ? AppTheme.accent : AppTheme.primary,
              onPrimary: Colors.white,
              onSurface: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
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
            colorScheme: const ColorScheme.light(
              primary: Colors.black,
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

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final String name = _nameController.text.trim();
    final double amount = double.parse(
      _amountController.text.trim().replaceAll(',', '.'),
    );
    final String? note = _noteController.text.trim().isEmpty
        ? null
        : _noteController.text.trim();
    final String? phone = _phoneController.text.trim().isEmpty
        ? null
        : _phoneController.text.trim();

    final Debt debt = isEditing
        ? widget.initialDebt!.copyWith(
            personName: name,
            amount: amount,
            note: note,
            date: _selectedDate,
            type: _type,
            phoneNumber: phone,
          )
        : Debt(
            id: Debt.generateId(),
            personName: name,
            amount: amount,
            note: note,
            date: _selectedDate,
            isPaid: false,
            type: _type,
            phoneNumber: phone,
          );

    if (widget.onSave != null) {
      widget.onSave!(debt);
    } else {
      if (isEditing) {
        FinanceService.instance.editDebt(debt);
      } else {
        FinanceService.instance.addDebt(debt);
      }
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final textSecondary = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);
    final fieldBg = isDark ? const Color(0xFF27272A) : const Color(0xFFF9FAFB);
    final sheetBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderCol = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
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
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Indicator Bar
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: borderCol,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // Sheet Header Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'تعديل' : 'إضافة',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Debt Type Selector: "عليّ" vs "لي"
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: fieldBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _type = DebtType.fromMe),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _type == DebtType.fromMe
                                  ? const Color(0xFFE11D48)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.call_received_rounded,
                                  size: 16,
                                  color: _type == DebtType.fromMe
                                      ? Colors.white
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'عليّ',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: _type == DebtType.fromMe
                                        ? Colors.white
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _type = DebtType.toMe),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _type == DebtType.toMe
                                  ? const Color(0xFF10B981)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.call_made_rounded,
                                  size: 16,
                                  color: _type == DebtType.toMe
                                      ? Colors.white
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'لي',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: _type == DebtType.toMe
                                        ? Colors.white
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Person Name Field
                Text(
                  'الاسم *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: 'الاسم',
                    prefixIcon: Icon(
                      Icons.person_outline_rounded,
                      color: textSecondary,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال الاسم';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Amount Field
                Text(
                  'المبلغ *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    hintText: '0',
                    prefixIcon: Icon(
                      Icons.monetization_on_outlined,
                      color: textSecondary,
                    ),
                    suffixText: SettingsService.currencyNotifier.value,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال المبلغ';
                    }
                    final num? parsed = num.tryParse(
                       value.trim().replaceAll(',', '.'),
                    );
                    if (parsed == null || parsed <= 0) {
                      return 'المبلغ غير صالح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone number
                Text(
                  'الهاتف',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    hintText: 'الهاتف',
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                      color: textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Date Picker Field
                Text(
                  'التاريخ والوقت',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: fieldBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                color: textSecondary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  Formatters.formatExactDate(_selectedDate),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 5,
                      child: InkWell(
                        onTap: _pickTime,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: fieldBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                color: textSecondary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  Formatters.formatTime(_selectedDate),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
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

                // Note Field
                Text(
                  'ملاحظة',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _noteController,
                  textDirection: TextDirection.rtl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'ملاحظة',
                    prefixIcon: Icon(
                      Icons.sticky_note_2_outlined,
                      color: textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : Colors.black,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'حفظ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
}
