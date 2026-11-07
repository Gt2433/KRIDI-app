import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/debt_model.dart';
import '../services/settings_service.dart';
import '../utils/formatters.dart';

class DebtPdfService {
  /// Generate and open a comprehensive PDF report for a single Debt with its Versements
  static Future<String?> exportDebtPdf(Debt debt) async {
    try {
      final pdf = pw.Document();

      // Load Arabic fonts from assets
      final regularFontData = await rootBundle.load('assets/fonts/NotoNaskhArabic-Regular.ttf');
      final boldFontData = await rootBundle.load('assets/fonts/NotoNaskhArabic-Bold.ttf');
      final ttfRegular = pw.Font.ttf(regularFontData);
      final ttfBold = pw.Font.ttf(boldFontData);

      final currency = SettingsService.currencyNotifier.value;
      final isToMe = debt.type == DebtType.toMe;
      final typeTitle = isToMe ? 'دين لي (مستحق)' : 'دين عليّ (مطلوب مني)';
      final statusTitle = debt.isFullyPaid
          ? 'مسدد بالكامل'
          : (debt.isPartiallyPaid ? 'مسدد جزئياً' : 'غير مسدد');

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(
            base: ttfRegular,
            bold: ttfBold,
          ),
          build: (pw.Context context) {
            return pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Header
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
                              'كشف حساب دين ودفعات الفيرسمو',
                              style: pw.TextStyle(
                                font: ttfBold,
                                fontSize: 18,
                                color: PdfColors.black,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              'تطبيق أموالي للديون والمعاملات',
                              style: pw.TextStyle(
                                font: ttfRegular,
                                fontSize: 11,
                                color: PdfColors.grey700,
                              ),
                            ),
                          ],
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: pw.BoxDecoration(
                            color: debt.isFullyPaid
                                ? PdfColors.green100
                                : (debt.isPartiallyPaid ? PdfColors.blue100 : PdfColors.amber100),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                          ),
                          child: pw.Text(
                            statusTitle,
                            style: pw.TextStyle(
                              font: ttfBold,
                              fontSize: 12,
                              color: debt.isFullyPaid
                                  ? PdfColors.green900
                                  : (debt.isPartiallyPaid ? PdfColors.blue900 : PdfColors.amber900),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 18),

                  // Debt Info Cards
                  pw.Container(
                    padding: const pw.EdgeInsets.all(14),
                    decoration: pw.BoxDecoration(
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                      border: pw.Border.all(color: PdfColors.grey300, width: 1),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            _buildInfoRow('الطرف المعني:', debt.personName, ttfBold, ttfRegular),
                            _buildInfoRow('نوع الدين:', typeTitle, ttfBold, ttfRegular),
                          ],
                        ),
                        pw.SizedBox(height: 8),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            _buildInfoRow(
                              'رقم الهاتف:',
                              (debt.phoneNumber != null && debt.phoneNumber!.isNotEmpty)
                                  ? debt.phoneNumber!
                                  : 'غير مسجل',
                              ttfBold,
                              ttfRegular,
                            ),
                            _buildInfoRow(
                              'تاريخ التسجيل:',
                              Formatters.formatExactDateTime(debt.date),
                              ttfBold,
                              ttfRegular,
                            ),
                          ],
                        ),
                        if (debt.note != null && debt.note!.trim().isNotEmpty) ...[
                          pw.SizedBox(height: 8),
                          _buildInfoRow('ملاحظات:', debt.note!, ttfBold, ttfRegular),
                        ],
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 16),

                  // Financial Summary Boxes
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: _buildStatBox(
                          'المبلغ الإجمالي',
                          '${_formatNum(debt.amount)} $currency',
                          PdfColors.grey100,
                          PdfColors.black,
                          ttfBold,
                          ttfRegular,
                        ),
                      ),
                      pw.SizedBox(width: 10),
                      pw.Expanded(
                        child: _buildStatBox(
                          'المسدد (فيرسمو)',
                          '${_formatNum(debt.totalPaid)} $currency',
                          PdfColors.green50,
                          PdfColors.green800,
                          ttfBold,
                          ttfRegular,
                        ),
                      ),
                      pw.SizedBox(width: 10),
                      pw.Expanded(
                        child: _buildStatBox(
                          'المتبقي للدفع',
                          '${_formatNum(debt.remainingAmount)} $currency',
                          PdfColors.red50,
                          PdfColors.red800,
                          ttfBold,
                          ttfRegular,
                        ),
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 22),

                  // Versements Section Title
                  pw.Text(
                    'سجل دفعات الفيرسمو',
                    style: pw.TextStyle(
                      font: ttfBold,
                      fontSize: 14,
                      color: PdfColors.black,
                    ),
                  ),
                  pw.SizedBox(height: 8),

                  // Versements Table
                  if (debt.versements.isEmpty)
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(16),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey50,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                        border: pw.Border.all(color: PdfColors.grey200),
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          'لا توجد دفعات فيرسمو مسجلة حتى الآن لهذا الدين.',
                          style: pw.TextStyle(font: ttfRegular, fontSize: 11, color: PdfColors.grey600),
                        ),
                      ),
                    )
                  else
                    pw.Table(
                      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.8),
                      children: [
                        // Table Header
                        pw.TableRow(
                          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                          children: [
                            _buildTableCell('الرقم', isHeader: true, font: ttfBold),
                            _buildTableCell('التاريخ والوقت', isHeader: true, font: ttfBold),
                            _buildTableCell('مبلغ الدفعة ($currency)', isHeader: true, font: ttfBold),
                            _buildTableCell('ملاحظة', isHeader: true, font: ttfBold),
                          ],
                        ),
                        // Table Rows
                        ...debt.versements.asMap().entries.map((entry) {
                          final idx = entry.key + 1;
                          final v = entry.value;
                          return pw.TableRow(
                            decoration: pw.BoxDecoration(
                              color: idx % 2 == 0 ? PdfColors.grey50 : PdfColors.white,
                            ),
                            children: [
                              _buildTableCell('$idx', font: ttfRegular),
                              _buildTableCell(Formatters.formatExactDateTime(v.date), font: ttfRegular),
                              _buildTableCell(_formatNum(v.amount), font: ttfBold),
                              _buildTableCell(v.note != null && v.note!.isNotEmpty ? v.note! : 'لا توجد', font: ttfRegular),
                            ],
                          );
                        }),
                      ],
                    ),

                  pw.Spacer(),

                  // Footer
                  pw.Divider(color: PdfColors.grey300, thickness: 0.8),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'تم التصدير بتاريخ: ${Formatters.formatExactDateTime(DateTime.now())}',
                        style: pw.TextStyle(font: ttfRegular, fontSize: 9, color: PdfColors.grey600),
                      ),
                      pw.Text(
                        'أموالي & كريدي - وثيقة مالية غير رسمية',
                        style: pw.TextStyle(font: ttfRegular, fontSize: 9, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );

      // Save PDF to temp file and open it
      final outputDir = await getTemporaryDirectory();
      final sanitizedName = debt.personName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final filePath = '${outputDir.path}/debt_${sanitizedName}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      // Open the file with default system PDF viewer
      await OpenFilex.open(filePath);
      return filePath;
    } catch (e, stack) {
      debugPrint('Error generating debt PDF: $e\n$stack');
      return null;
    }
  }

  static pw.Widget _buildInfoRow(
    String label,
    String value,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          '$label ',
          style: pw.TextStyle(font: boldFont, fontSize: 11, color: PdfColors.grey700),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(font: regularFont, fontSize: 11, color: PdfColors.black),
        ),
      ],
    );
  }

  static pw.Widget _buildStatBox(
    String title,
    String amountStr,
    PdfColor bgColor,
    PdfColor textColor,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(font: regularFont, fontSize: 10, color: PdfColors.grey700),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            amountStr,
            style: pw.TextStyle(font: boldFont, fontSize: 12, color: textColor),
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
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          font: font,
          fontSize: isHeader ? 10 : 9,
          color: isHeader ? PdfColors.black : PdfColors.grey800,
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
}
