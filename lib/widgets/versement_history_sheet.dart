import 'package:flutter/material.dart';
import '../models/debt_model.dart';
import '../services/debt_pdf_service.dart';
import '../services/finance_service.dart';
import '../utils/formatters.dart';
import 'add_versement_sheet.dart';

class VersementHistorySheet extends StatelessWidget {
  final Debt debt;

  const VersementHistorySheet({super.key, required this.debt});

  static Future<void> show(BuildContext context, Debt debt) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(90),
      builder: (context) => VersementHistorySheet(debt: debt),
    );
  }

  void _onExportPdf(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('جارٍ إنشاء ملف PDF...'),
        duration: Duration(seconds: 1),
      ),
    );
    final path = await DebtPdfService.exportDebtPdf(debt);
    if (context.mounted) {
      if (path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تصدير وفتح ملف PDF بنجاح ✓'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر تصدير ملف PDF'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final finance = FinanceService.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderCol = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB);
    final textCol = isDark ? Colors.white : Colors.black;
    final fieldBg = isDark ? const Color(0xFF27272A) : const Color(0xFFF9FAFB);
    final itemBg = isDark ? const Color(0xFF27272A) : const Color(0xFFFAFAFA);
    final itemBorder = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFF3F4F6);
    final subTextCol = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);

    return ListenableBuilder(
      listenable: finance,
      builder: (context, _) {
        // Find updated debt object
        final currentDebt = finance.debts.firstWhere(
          (d) => d.id == debt.id,
          orElse: () => debt,
        );

        final versements = currentDebt.versements;

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.82,
          ),
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(
              top: BorderSide(color: borderCol, width: 1.2),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: borderCol,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 14),

              // Title & PDF Export
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'سجل دفعات الفيرسمو',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textCol,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currentDebt.personName,
                        style: TextStyle(
                          fontSize: 13,
                          color: subTextCol,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // PDF Export Button
                      InkWell(
                        onTap: () => _onExportPdf(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: fieldBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderCol),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.picture_as_pdf_rounded, size: 16, color: Color(0xFFDC2626)),
                              const SizedBox(width: 4),
                              Text(
                                'PDF',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: textCol,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.grey),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Stats summary
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
                        Text('الإجمالي', style: TextStyle(fontSize: 11, color: subTextCol)),
                        const SizedBox(height: 2),
                        Text(
                          Formatters.formatAmount(currentDebt.amount),
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textCol),
                        ),
                      ],
                    ),
                    Container(width: 1, height: 28, color: borderCol),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('المسدد', style: TextStyle(fontSize: 11, color: subTextCol)),
                        const SizedBox(height: 2),
                        Text(
                          Formatters.formatAmount(currentDebt.totalPaid),
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
                          Formatters.formatAmount(currentDebt.remainingAmount),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // List of versements
              Expanded(
                child: versements.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.payments_outlined, size: 48, color: Colors.grey.withAlpha(120)),
                            const SizedBox(height: 10),
                            const Text(
                              'لا توجد دفعات فيرسمو مسجلة',
                              style: TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: versements.length,
                        separatorBuilder: (_, index) => const SizedBox(height: 8),
                        itemBuilder: (context, idx) {
                          final v = versements[idx];
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: itemBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: itemBorder),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF16A34A).withAlpha(30),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.arrow_downward_rounded, size: 16, color: Color(0xFF16A34A)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '+${Formatters.formatAmount(v.amount)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF16A34A),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        Formatters.formatExactDateTime(v.date),
                                        style: TextStyle(fontSize: 11, color: subTextCol),
                                      ),
                                      if (v.note != null && v.note!.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          v.note!,
                                          style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: textCol),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.grey),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        backgroundColor: sheetBg,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        title: Text('حذف الدفعة', style: TextStyle(color: textCol)),
                                        content: Text(
                                          'هل أنت متأكد من حذف هذه الدفعة؟ سيتم إعادة المبلغ إلى الرصيد المتبقي.',
                                          style: TextStyle(color: subTextCol),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, false),
                                            child: Text('إلغاء', style: TextStyle(color: subTextCol)),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: const Text('حذف', style: TextStyle(color: Colors.white)),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await FinanceService.instance.deleteVersement(currentDebt.id, v.id);
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 12),

              // Bottom Actions: Add Versement & Export PDF
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? Colors.white : Colors.black,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('فيرسمو جديد', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          AddVersementSheet.show(context, currentDebt);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textCol,
                          side: BorderSide(color: borderCol, width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.picture_as_pdf_rounded, size: 18, color: Color(0xFFDC2626)),
                        label: const Text('تصدير PDF', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        onPressed: () => _onExportPdf(context),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
