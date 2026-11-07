import 'package:flutter/material.dart';
import '../models/debt_model.dart';
import '../services/finance_service.dart';
import '../utils/formatters.dart';

class AddVersementSheet extends StatefulWidget {
  final Debt debt;

  const AddVersementSheet({super.key, required this.debt});

  static Future<void> show(BuildContext context, Debt debt) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(90),
      builder: (context) => AddVersementSheet(debt: debt),
    );
  }

  @override
  State<AddVersementSheet> createState() => _AddVersementSheetState();
}

class _AddVersementSheetState extends State<AddVersementSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _noteController = TextEditingController();
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
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

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim().replaceAll(',', '.')) ?? 0.0;
    if (amount <= 0) return;

    final note = _noteController.text.trim().isEmpty ? null : _noteController.text.trim();

    final versement = DebtVersement(
      id: DebtVersement.generateId(),
      amount: amount,
      date: _selectedDate,
      note: note,
    );

    await FinanceService.instance.addVersement(widget.debt.id, versement);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تسجيل دفعة فيرسمو بقيمة ${Formatters.formatAmount(amount)} بنجاح ✓'),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderCol = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB);
    final textCol = isDark ? Colors.white : Colors.black;
    final fieldBg = isDark ? const Color(0xFF27272A) : const Color(0xFFF9FAFB);
    final subTextCol = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final remaining = widget.debt.remainingAmount;

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(color: borderCol, width: 1.2),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + bottomInset),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: borderCol,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تسجيل فيرسمو (دفعة جزئية)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textCol,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.debt.personName,
                          style: TextStyle(
                            fontSize: 13,
                            color: subTextCol,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.grey),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Debt Summary Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: fieldBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderCol),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('المبلغ الإجمالي', style: TextStyle(fontSize: 11, color: subTextCol)),
                          const SizedBox(height: 2),
                          Text(
                            Formatters.formatAmount(widget.debt.amount),
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textCol),
                          ),
                        ],
                      ),
                      Container(width: 1, height: 28, color: borderCol),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('المدفوع حالياً', style: TextStyle(fontSize: 11, color: subTextCol)),
                          const SizedBox(height: 2),
                          Text(
                            Formatters.formatAmount(widget.debt.totalPaid),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                          ),
                        ],
                      ),
                      Container(width: 1, height: 28, color: borderCol),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('المتبقي', style: TextStyle(fontSize: 11, color: subTextCol)),
                          const SizedBox(height: 2),
                          Text(
                            Formatters.formatAmount(remaining),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Amount Field
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'مبلغ الدفعة',
                    hintText: '0.00',
                    suffixIcon: TextButton(
                      onPressed: () {
                        if (remaining == remaining.roundToDouble()) {
                          _amountController.text = remaining.toInt().toString();
                        } else {
                          _amountController.text = remaining.toString();
                        }
                      },
                      child: const Text('كامل المتبقي', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'أدخل المبلغ';
                    final n = double.tryParse(val.trim().replaceAll(',', '.'));
                    if (n == null || n <= 0) return 'المبلغ غير صحيح';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Date & Time Row
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
                            border: Border.all(color: borderCol),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_rounded, size: 18, color: textCol),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('التاريخ', style: TextStyle(fontSize: 10, color: subTextCol)),
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

                    // Time
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
                            border: Border.all(color: borderCol),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.access_time_rounded, size: 18, color: textCol),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('الوقت', style: TextStyle(fontSize: 10, color: subTextCol)),
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
                const SizedBox(height: 14),

                // Note
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظة (اختياري)',
                    hintText: 'مثال: دفعة نقداً أو وصل تحويل',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
                const SizedBox(height: 22),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : Colors.black,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _submit,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_rounded, size: 20),
                        SizedBox(width: 8),
                        Text('حفظ الفيرسمو', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ],
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

