import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/transaction_model.dart';
import '../services/category_service.dart';
import '../services/finance_service.dart';
import '../services/settings_service.dart';
import '../utils/formatters.dart';

class TransactionPdfService {
  TransactionPdfService._();

  static const List<String> _months = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
  ];

  static String getMonthName(DateTime date) {
    return _months[date.month - 1];
  }

  /// Export a comprehensive PDF report for a single specific Day
  static Future<String?> exportDayPdf(DateTime date) async {
    final finance = FinanceService.instance;
    final transactions = finance.transactions
        .where((t) =>
            t.date.year == date.year &&
            t.date.month == date.month &&
            t.date.day == date.day)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final dayTitle = Formatters.formatDayHeader(date);
    return _generateAndOpenPdf(
      reportTitle: 'كشف المعاملات المالية اليومي',
      periodSubtitle: 'معاملات يوم: $dayTitle',
      dateLabel: dayTitle,
      transactions: transactions,
      fileNamePrefix: 'kredi_daily_${date.year}_${date.month}_${date.day}',
    );
  }

  /// Export a comprehensive PDF report for an entire specific Month
  static Future<String?> exportMonthPdf(DateTime monthDate) async {
    final finance = FinanceService.instance;
    final transactions = finance.transactions
        .where((t) =>
            t.date.year == monthDate.year &&
            t.date.month == monthDate.month)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final monthTitle = '${getMonthName(monthDate)} ${monthDate.year}';
    return _generateAndOpenPdf(
      reportTitle: 'كشف المعاملات المالية الشهري',
      periodSubtitle: 'معاملات شهر: $monthTitle',
      dateLabel: monthTitle,
      transactions: transactions,
      fileNamePrefix: 'kredi_monthly_${monthDate.year}_${monthDate.month}',
    );
  }

  /// Internal generator that builds the PDF document, writes to file and opens it
  static Future<String?> _generateAndOpenPdf({
    required String reportTitle,
    required String periodSubtitle,
    required String dateLabel,
    required List<TransactionModel> transactions,
    required String fileNamePrefix,
  }) async {
    try {
      final finance = FinanceService.instance;
      final pdf = pw.Document();

      // Load Arabic fonts
      final regularFontData = await rootBundle.load('assets/fonts/NotoNaskhArabic-Regular.ttf');
      final boldFontData = await rootBundle.load('assets/fonts/NotoNaskhArabic-Bold.ttf');
      final ttfRegular = pw.Font.ttf(regularFontData);
      final ttfBold = pw.Font.ttf(boldFontData);

      final currency = SettingsService.currencyNotifier.value;

      // Financial totals
      double totalIncome = 0;
      double totalExpense = 0;
      final Map<String, double> categoryExpenses = {};

      for (final t in transactions) {
        if (t.type == TransactionType.income) {
          totalIncome += t.amount;
        } else if (t.type == TransactionType.expense) {
          totalExpense += t.amount;
          categoryExpenses[t.categoryId] = (categoryExpenses[t.categoryId] ?? 0) + t.amount;
        }
      }

      final netFlow = totalIncome - totalExpense;

      // Split transactions into chunks of 16 to guarantee smooth multi-page pagination
      const chunkSize = 16;
      final List<List<TransactionModel>> chunks = [];
      if (transactions.isEmpty) {
        chunks.add([]);
      } else {
        for (var i = 0; i < transactions.length; i += chunkSize) {
          chunks.add(
            transactions.sublist(
              i,
              i + chunkSize > transactions.length ? transactions.length : i + chunkSize,
            ),
          );
        }
      }

      for (var pageIdx = 0; pageIdx < chunks.length; pageIdx++) {
        final currentChunk = chunks[pageIdx];
        final isFirstPage = pageIdx == 0;
        final startIdx = pageIdx * chunkSize;

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(24),
            theme: pw.ThemeData.withFont(
              base: ttfRegular,
              bold: ttfBold,
            ),
            build: (pw.Context context) {
              return pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    // Header on Page 1
                    if (isFirstPage) ...[
                      pw.Container(
                        padding: const pw.EdgeInsets.all(16),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey100,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                          border: pw.Border.all(color: PdfColors.grey300, width: 1),
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  reportTitle,
                                  style: pw.TextStyle(
                                    font: ttfBold,
                                    fontSize: 18,
                                    color: PdfColors.black,
                                  ),
                                ),
                                pw.SizedBox(height: 4),
                                pw.Text(
                                  periodSubtitle,
                                  style: pw.TextStyle(
                                    font: ttfRegular,
                                    fontSize: 12,
                                    color: PdfColors.grey800,
                                  ),
                                ),
                              ],
                            ),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: const pw.BoxDecoration(
                                color: PdfColors.blue100,
                                borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
                              ),
                              child: pw.Text(
                                'تطبيق كريدي ⚡',
                                style: pw.TextStyle(
                                  font: ttfBold,
                                  fontSize: 11,
                                  color: PdfColors.blue900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 14),

                      // Statistics Summary Grid (4 Boxes)
                      pw.Row(
                        children: [
                          pw.Expanded(
                            child: _buildStatCard(
                              title: 'المداخيل',
                              value: '+${_formatNum(totalIncome)} $currency',
                              bgColor: PdfColors.green50,
                              textColor: PdfColors.green900,
                              boldFont: ttfBold,
                              regularFont: ttfRegular,
                            ),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Expanded(
                            child: _buildStatCard(
                              title: 'المصاريف',
                              value: '-${_formatNum(totalExpense)} $currency',
                              bgColor: PdfColors.red50,
                              textColor: PdfColors.red900,
                              boldFont: ttfBold,
                              regularFont: ttfRegular,
                            ),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Expanded(
                            child: _buildStatCard(
                              title: 'الصافي',
                              value: '${netFlow >= 0 ? "+" : ""}${_formatNum(netFlow)} $currency',
                              bgColor: netFlow >= 0 ? PdfColors.teal50 : PdfColors.amber50,
                              textColor: netFlow >= 0 ? PdfColors.teal900 : PdfColors.amber900,
                              boldFont: ttfBold,
                              regularFont: ttfRegular,
                            ),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Expanded(
                            child: _buildStatCard(
                              title: 'العمليات',
                              value: '${transactions.length}',
                              bgColor: PdfColors.grey100,
                              textColor: PdfColors.grey900,
                              boldFont: ttfBold,
                              regularFont: ttfRegular,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 14),
                    ] else ...[
                      // Compact Header for continuation pages
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            '$reportTitle ($dateLabel)',
                            style: pw.TextStyle(font: ttfBold, fontSize: 11, color: PdfColors.grey700),
                          ),
                          pw.Text(
                            'تابع الصفحة ${pageIdx + 1} من ${chunks.length}',
                            style: pw.TextStyle(font: ttfRegular, fontSize: 10, color: PdfColors.grey600),
                          ),
                        ],
                      ),
                      pw.Divider(color: PdfColors.grey300, thickness: 0.8),
                      pw.SizedBox(height: 8),
                    ],

                    // Transactions Table Title
                    pw.Text(
                      'تفاصيل المعاملات المالية (${transactions.length})',
                      style: pw.TextStyle(
                        font: ttfBold,
                        fontSize: 13,
                        color: PdfColors.black,
                      ),
                    ),
                    pw.SizedBox(height: 8),

                    // Table
                    if (currentChunk.isEmpty)
                      pw.Container(
                        padding: const pw.EdgeInsets.all(24),
                        alignment: pw.Alignment.center,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey50,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                          border: pw.Border.all(color: PdfColors.grey200),
                        ),
                        child: pw.Text(
                          'لا توجد معاملات مسجلة في هذا التاريخ',
                          style: pw.TextStyle(font: ttfRegular, fontSize: 12, color: PdfColors.grey600),
                        ),
                      )
                    else
                      pw.Table(
                        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.6),
                        columnWidths: const {
                          0: pw.FlexColumnWidth(0.6), // #
                          1: pw.FlexColumnWidth(1.4), // الوقت/التاريخ
                          2: pw.FlexColumnWidth(2.5), // البيان
                          3: pw.FlexColumnWidth(1.5), // التصنيف
                          4: pw.FlexColumnWidth(1.2), // المساحة
                          5: pw.FlexColumnWidth(1.0), // النوع
                          6: pw.FlexColumnWidth(1.8), // المبلغ
                        },
                        children: [
                          // Header Row
                          pw.TableRow(
                            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                            children: [
                              _buildTableCell('#', isHeader: true, font: ttfBold),
                              _buildTableCell('الوقت / التاريخ', isHeader: true, font: ttfBold),
                              _buildTableCell('البيان / الوصف', isHeader: true, font: ttfBold),
                              _buildTableCell('التصنيف', isHeader: true, font: ttfBold),
                              _buildTableCell('المساحة', isHeader: true, font: ttfBold),
                              _buildTableCell('النوع', isHeader: true, font: ttfBold),
                              _buildTableCell('المبلغ', isHeader: true, font: ttfBold),
                            ],
                          ),
                          // Data Rows
                          ...currentChunk.asMap().entries.map((entry) {
                            final rowIdx = startIdx + entry.key + 1;
                            final tx = entry.value;

                            final cat = CategoryService.getById(tx.categoryId);
                            final catName = cat.nameAr;
                            final wallet = finance.wallets
                                .where((w) => w.id == tx.walletId)
                                .map((w) => w.name)
                                .firstOrNull ?? 'الرئيسية';

                            String typeStr;
                            PdfColor amountColor;
                            String prefix;

                            switch (tx.type) {
                              case TransactionType.income:
                                typeStr = 'دخل';
                                amountColor = PdfColors.green800;
                                prefix = '+';
                                break;
                              case TransactionType.expense:
                                typeStr = 'مصروف';
                                amountColor = PdfColors.red800;
                                prefix = '-';
                                break;
                              case TransactionType.transfer:
                                typeStr = 'تحويل';
                                amountColor = PdfColors.blue800;
                                prefix = '⇆';
                                break;
                            }

                            final dateStr = tx.date.hour == 0 && tx.date.minute == 0
                                ? '${tx.date.day}/${tx.date.month}'
                                : Formatters.formatTime(tx.date);

                            return pw.TableRow(
                              decoration: pw.BoxDecoration(
                                color: rowIdx % 2 == 0 ? PdfColors.grey50 : PdfColors.white,
                              ),
                              children: [
                                _buildTableCell('$rowIdx', font: ttfRegular),
                                _buildTableCell(dateStr, font: ttfRegular),
                                _buildTableCell(tx.title.isNotEmpty ? tx.title : 'معاملة', font: ttfBold),
                                _buildTableCell(catName, font: ttfRegular),
                                _buildTableCell(wallet, font: ttfRegular),
                                _buildTableCell(typeStr, font: ttfRegular),
                                _buildTableCell(
                                  '$prefix${_formatNum(tx.amount)} $currency',
                                  font: ttfBold,
                                  textColor: amountColor,
                                ),
                              ],
                            );
                          }),
                        ],
                      ),

                    pw.Spacer(),

                    // Page Footer
                    pw.Divider(color: PdfColors.grey300, thickness: 0.8),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'تم الاستخراج: ${Formatters.formatExactDateTime(DateTime.now())}',
                          style: pw.TextStyle(font: ttfRegular, fontSize: 8.5, color: PdfColors.grey600),
                        ),
                        pw.Text(
                          'صفحة ${pageIdx + 1} من ${chunks.length}',
                          style: pw.TextStyle(font: ttfBold, fontSize: 8.5, color: PdfColors.grey700),
                        ),
                        pw.Text(
                          'كريدي (KRIDI) - تقرير مالي شخصي',
                          style: pw.TextStyle(font: ttfRegular, fontSize: 8.5, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }

      // Save PDF to temp directory and open with system viewer
      final outputDir = await getTemporaryDirectory();
      final filePath = '${outputDir.path}/${fileNamePrefix}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      await OpenFilex.open(filePath);
      return filePath;
    } catch (e, stack) {
      debugPrint('Error generating transaction PDF: $e\n$stack');
      return null;
    }
  }

  static pw.Widget _buildStatCard({
    required String title,
    required String value,
    required PdfColor bgColor,
    required PdfColor textColor,
    required pw.Font boldFont,
    required pw.Font regularFont,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(font: regularFont, fontSize: 9.5, color: PdfColors.grey700),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            value,
            style: pw.TextStyle(font: boldFont, fontSize: 11, color: textColor),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    required pw.Font font,
    PdfColor textColor = PdfColors.black,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          font: font,
          fontSize: isHeader ? 9.5 : 8.5,
          color: isHeader ? PdfColors.black : textColor,
        ),
      ),
    );
  }

  static String _formatNum(double num) {
    if (num == num.roundToDouble()) {
      return num.toInt().toString();
    }
    return num.toStringAsFixed(2);
  }

  /// Show a modern, interactive dialog / sheet to choose between Day or Month export
  static Future<void> showExportPdfDialog(
    BuildContext context, {
    DateTime? initialDate,
    DateTime? initialMonth,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(120),
      builder: (ctx) => _ExportPdfModalSheet(
        initialDate: initialDate,
        initialMonth: initialMonth,
      ),
    );
  }
}

class _ExportPdfModalSheet extends StatefulWidget {
  final DateTime? initialDate;
  final DateTime? initialMonth;

  const _ExportPdfModalSheet({
    this.initialDate,
    this.initialMonth,
  });

  @override
  State<_ExportPdfModalSheet> createState() => _ExportPdfModalSheetState();
}

class _ExportPdfModalSheetState extends State<_ExportPdfModalSheet> {
  bool _isDaily = true;
  late DateTime _selectedDay;
  late DateTime _selectedMonth;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.initialDate ?? DateTime.now();
    _selectedMonth = widget.initialMonth ?? DateTime.now();
  }

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('ar'),
    );
    if (picked != null) {
      setState(() => _selectedDay = picked);
    }
  }

  void _prevMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  Future<void> _export() async {
    setState(() => _isExporting = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      String? path;
      if (_isDaily) {
        path = await TransactionPdfService.exportDayPdf(_selectedDay);
      } else {
        path = await TransactionPdfService.exportMonthPdf(_selectedMonth);
      }

      if (mounted) {
        navigator.pop();
        if (path != null) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('تم استخراج وفتح ملف PDF بنجاح! 📄✓'),
              backgroundColor: Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('تعذر إنشاء ملف PDF، يرجى المحاولة ثانية'),
              backgroundColor: Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderCol = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB);
    final textCol = isDark ? Colors.white : Colors.black;
    final subTextCol = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);
    final toggleBg = isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6);

    final finance = FinanceService.instance;

    // Calculate preview counts
    int txCount = 0;
    double income = 0;
    double expense = 0;

    if (_isDaily) {
      final list = finance.transactions.where((t) =>
          t.date.year == _selectedDay.year &&
          t.date.month == _selectedDay.month &&
          t.date.day == _selectedDay.day);
      txCount = list.length;
      for (final t in list) {
        if (t.type == TransactionType.income) income += t.amount;
        if (t.type == TransactionType.expense) expense += t.amount;
      }
    } else {
      final list = finance.transactions.where((t) =>
          t.date.year == _selectedMonth.year &&
          t.date.month == _selectedMonth.month);
      txCount = list.length;
      for (final t in list) {
        if (t.type == TransactionType.income) income += t.amount;
        if (t.type == TransactionType.expense) expense += t.amount;
      }
    }

    final currency = SettingsService.currencyNotifier.value;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: borderCol, width: 1.2)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: borderCol,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title & PDF Badge
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withAlpha(isDark ? 35 : 20),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFDC2626), size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'استخراج تقرير مالي (PDF)',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: textCol,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'تصدير كشف حساب قابل للطباعة والمشاركة',
                        style: TextStyle(fontSize: 12, color: subTextCol),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Period Selector Toggle (يومي / شهري)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: toggleBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isDaily = true),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: _isDaily
                              ? (isDark ? const Color(0xFF3F3F46) : Colors.white)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _isDaily
                              ? [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 4, offset: const Offset(0, 2))]
                              : [],
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.today_rounded,
                              size: 16,
                              color: _isDaily ? const Color(0xFF2563EB) : subTextCol,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'كشف يومي',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: _isDaily ? FontWeight.bold : FontWeight.w500,
                                color: textCol,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isDaily = false),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: !_isDaily
                              ? (isDark ? const Color(0xFF3F3F46) : Colors.white)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: !_isDaily
                              ? [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 4, offset: const Offset(0, 2))]
                              : [],
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_month_rounded,
                              size: 16,
                              color: !_isDaily ? const Color(0xFF2563EB) : subTextCol,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'كشف شهري',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: !_isDaily ? FontWeight.bold : FontWeight.w500,
                                color: textCol,
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

            // Date / Month Picker Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF27272A) : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderCol),
              ),
              child: _isDaily
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.event_note_rounded, size: 20, color: Color(0xFF2563EB)),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Formatters.formatDayHeader(_selectedDay),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: textCol,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'تاريخ الكشف المحدد',
                                  style: TextStyle(fontSize: 11, color: subTextCol),
                                ),
                              ],
                            ),
                          ],
                        ),
                        OutlinedButton.icon(
                          onPressed: _pickDay,
                          icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                          label: const Text('تغيير', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_right_rounded),
                          tooltip: 'الشهر السابق',
                          onPressed: _prevMonth,
                        ),
                        Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, size: 20, color: Color(0xFF2563EB)),
                            const SizedBox(width: 8),
                            Text(
                              '${TransactionPdfService.getMonthName(_selectedMonth)} ${_selectedMonth.year}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: textCol,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded),
                          tooltip: 'الشهر التالي',
                          onPressed: _nextMonth,
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 14),

            // Live Preview Stats of Selected Period
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B).withAlpha(80) : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF2563EB).withAlpha(isDark ? 60 : 40),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildPreviewStat('العمليات', '$txCount', textCol, subTextCol),
                  Container(width: 1, height: 28, color: borderCol),
                  _buildPreviewStat('المداخيل', '+${Formatters.formatAmount(income)} $currency', const Color(0xFF16A34A), subTextCol),
                  Container(width: 1, height: 28, color: borderCol),
                  _buildPreviewStat('المصاريف', '-${Formatters.formatAmount(expense)} $currency', const Color(0xFFDC2626), subTextCol),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Export Button
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isExporting ? null : _export,
                icon: _isExporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf_rounded, size: 20),
                label: Text(
                  _isExporting
                      ? 'جارٍ تجهيز ملف PDF...'
                      : (_isDaily ? 'استخراج كشف اليوم (PDF)' : 'استخراج كشف الشهر (PDF)'),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewStat(String label, String value, Color valueColor, Color labelColor) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: labelColor)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
