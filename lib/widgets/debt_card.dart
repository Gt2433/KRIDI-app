import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/debt_model.dart';
import '../services/debt_pdf_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'add_versement_sheet.dart';
import 'glass_container.dart';
import 'versement_history_sheet.dart';

class DebtCard extends StatelessWidget {
  final Debt debt;
  final VoidCallback onTogglePaid;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const DebtCard({
    super.key,
    required this.debt,
    required this.onTogglePaid,
    required this.onEdit,
    required this.onDelete,
  });

  void _sendWhatsAppReminder(BuildContext context) async {
    if (debt.phoneNumber == null || debt.phoneNumber!.trim().isEmpty) return;

    var phone = debt.phoneNumber!.replaceAll(RegExp(r'\s+'), '');
    if (phone.startsWith('0')) {
      // Default to Algerian prefix +213 if starts with 0
      phone = '213${phone.substring(1)}';
    }

    final remainingStr = Formatters.formatAmount(debt.remainingAmount, forceShow: true);
    final message = debt.type == DebtType.toMe
        ? 'السلام عليكم أخي ${debt.personName}، تذكير لطيف بخصوص المبلغ المتبقي ($remainingStr). شكراً جزيلاً لك.'
        : 'السلام عليكم أخي ${debt.personName}، بخصوص الدين الذي بيننا بقيمة ($remainingStr)، سأقوم بتسديده في أقرب وقت إن شاء الله.';

    final uri = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  void _exportPdf(BuildContext context) async {
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
            content: Text('تعذر إنشاء ملف PDF'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB);
    final textPrimary = isDark ? Colors.white : Colors.black;
    final textSecondary = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);
    final textMuted = isDark ? const Color(0xFF71717A) : const Color(0xFF9CA3AF);
    final noteBg = isDark ? const Color(0xFF27272A) : const Color(0xFFF9FAFB);
    final buttonBg = isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6);
    final popupBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final isToMe = debt.type == DebtType.toMe;
    final hasVersements = debt.versements.isNotEmpty;
    final progress = debt.amount > 0 ? (debt.totalPaid / debt.amount).clamp(0.0, 1.0) : 0.0;

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Type Badge + Person Name + Status Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isToMe ? const Color(0xFF10B981) : const Color(0xFFE11D48)).withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (isToMe ? const Color(0xFF10B981) : const Color(0xFFE11D48)).withAlpha(70),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isToMe ? Icons.call_made_rounded : Icons.call_received_rounded,
                      size: 13,
                      color: isToMe ? const Color(0xFF10B981) : const Color(0xFFE11D48),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isToMe ? 'لي' : 'عليّ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isToMe ? const Color(0xFF10B981) : const Color(0xFFE11D48),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  debt.personName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: debt.isFullyPaid ? textMuted : textPrimary,
                    decoration: debt.isFullyPaid ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildStatusBadge(),
            ],
          ),
          const SizedBox(height: 10),

          // Amount Section
          if (hasVersements) ...[
            // Breakdown with remaining amount and progress bar (tap to view history)
            InkWell(
              onTap: () => VersementHistorySheet.show(context, debt),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('المتبقي', style: TextStyle(fontSize: 11, color: textSecondary)),
                            const SizedBox(height: 2),
                            Text(
                              Formatters.formatAmount(debt.remainingAmount),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: debt.isFullyPaid
                                    ? textSecondary
                                    : (isToMe ? const Color(0xFF10B981) : const Color(0xFFE11D48)),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'الأصلي: ${Formatters.formatAmount(debt.amount)}',
                              style: TextStyle(fontSize: 11, color: textMuted),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'المسدد: ${Formatters.formatAmount(debt.totalPaid)}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          debt.isFullyPaid ? const Color(0xFF16A34A) : (isDark ? Colors.white : Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Simple Amount & Date Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Formatters.formatAmount(debt.amount),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: debt.isFullyPaid
                        ? textSecondary
                        : (isToMe ? const Color(0xFF10B981) : const Color(0xFFE11D48)),
                  ),
                ),
                Text(
                  Formatters.formatDateTime(debt.date),
                  style: TextStyle(fontSize: 12, color: textMuted),
                ),
              ],
            ),
          ],

          // Note (if exists)
          if (debt.note != null && debt.note!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: noteBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Text(
                debt.note!,
                style: TextStyle(
                  fontSize: 13,
                  color: debt.isFullyPaid ? textMuted : textSecondary,
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 10),

          // Action Row: Date on the right, Buttons on the left
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Creation Date & Time with subtle clock icon
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time_rounded, size: 13, color: textMuted),
                  const SizedBox(width: 4),
                  Text(
                    Formatters.formatDateTime(debt.date),
                    style: TextStyle(fontSize: 11, color: textMuted),
                  ),
                ],
              ),

              // Actions: WhatsApp, Toggle Paid, 3-Dots Menu
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // WhatsApp Reminder (if phone exists and debt is unpaid)
                  if (!debt.isFullyPaid && debt.phoneNumber != null && debt.phoneNumber!.isNotEmpty) ...[
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Color(0xFF25D366)),
                      tooltip: 'واتساب',
                      onPressed: () => _sendWhatsAppReminder(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    const SizedBox(width: 4),
                  ],

                  // Toggle Paid Button (تسديد / تراجع)
                  InkWell(
                    onTap: onTogglePaid,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: debt.isFullyPaid
                            ? buttonBg
                            : (isDark ? const Color(0xFF064E3B).withAlpha(80) : const Color(0xFFF0FDF4)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: debt.isFullyPaid
                              ? borderColor
                              : (isDark ? const Color(0xFF065F46) : const Color(0xFFBBF7D0)),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            debt.isFullyPaid ? Icons.undo_rounded : Icons.check_circle_outline_rounded,
                            size: 14,
                            color: debt.isFullyPaid ? textSecondary : AppTheme.statusPaidText,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            debt.isFullyPaid ? 'تراجع' : 'تسديد',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: debt.isFullyPaid ? textSecondary : AppTheme.statusPaidText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 3-Dots Menu Button (قائمة 3 نقاط: فيرسمو، السجل، PDF، تعديل، حذف)
                  PopupMenuButton<String>(
                    tooltip: 'خيارات الدين',
                    offset: const Offset(0, 36),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: popupBg,
                    surfaceTintColor: Colors.transparent,
                    elevation: 6,
                    onSelected: (val) {
                      switch (val) {
                        case 'versement':
                          AddVersementSheet.show(context, debt);
                          break;
                        case 'history':
                          VersementHistorySheet.show(context, debt);
                          break;
                        case 'pdf':
                          _exportPdf(context);
                          break;
                        case 'edit':
                          onEdit();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (ctx) => [
                      if (!debt.isFullyPaid)
                        PopupMenuItem(
                          value: 'versement',
                          child: Row(
                            children: [
                              Icon(Icons.add_circle_outline_rounded, size: 19, color: textPrimary),
                              const SizedBox(width: 10),
                              Text(
                                'إضافة فيرسمو',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary),
                              ),
                            ],
                          ),
                        ),
                      if (hasVersements)
                        PopupMenuItem(
                          value: 'history',
                          child: Row(
                            children: [
                              Icon(Icons.receipt_long_rounded, size: 19, color: textSecondary),
                              const SizedBox(width: 10),
                              Text(
                                'سجل الفيرسمو (${debt.versements.length})',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textPrimary),
                              ),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'pdf',
                        child: Row(
                          children: [
                            Icon(Icons.picture_as_pdf_rounded, size: 19, color: Color(0xFFDC2626)),
                            SizedBox(width: 10),
                            Text(
                              'تصدير كشف PDF',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFFDC2626)),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(height: 1),
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 19, color: textSecondary),
                            const SizedBox(width: 10),
                            Text(
                              'تعديل الدين',
                              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: textPrimary),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, size: 19, color: Color(0xFFE11D48)),
                            SizedBox(width: 10),
                            Text(
                              'حذف الدين',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFFE11D48)),
                            ),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                      decoration: BoxDecoration(
                        color: buttonBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: Icon(Icons.more_horiz_rounded, size: 18, color: textPrimary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Widget badge;
    if (debt.isFullyPaid) {
      badge = Container(
        key: const ValueKey('paid'),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: const Text(
          'مسدد',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF16A34A),
          ),
        ),
      );
    } else if (debt.isPartiallyPaid) {
      final percent = ((debt.totalPaid / debt.amount) * 100).toInt();
      badge = Container(
        key: ValueKey('partial_$percent'),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: Text(
          'فيرسمو $percent%',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2563EB),
          ),
        ),
      );
    } else {
      badge = Container(
        key: const ValueKey('unpaid'),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: const Text(
          'غير مسدد',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFFDC2626),
          ),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
      child: badge,
    );
  }
}
