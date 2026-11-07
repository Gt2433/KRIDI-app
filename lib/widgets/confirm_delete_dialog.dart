import 'package:flutter/material.dart';
import '../utils/app_strings.dart';

class ConfirmDeleteDialog extends StatelessWidget {
  final String personName;
  final String? title;
  final String? content;

  const ConfirmDeleteDialog({
    super.key,
    this.personName = '',
    this.title,
    this.content,
  });

  static Future<bool?> show(
    BuildContext context, {
    String personName = '',
    String? title,
    String? content,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withAlpha(80),
      builder: (context) => ConfirmDeleteDialog(
        personName: personName,
        title: title,
        content: content,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dialogTitle = title ?? AppStrings.tr(context, 'confirm_delete_title');
    final dialogContent = content ?? AppStrings.tr(context, 'confirm_delete_msg', personName);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB),
          width: 1.2,
        ),
      ),
      title: Text(
        dialogTitle,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      content: Text(
        dialogContent,
        style: TextStyle(
          fontSize: 14,
          color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF4B5563),
        ),
      ),
      actionsPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(AppStrings.tr(context, 'cancel'), style: TextStyle(color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280))),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(AppStrings.tr(context, 'delete')),
        ),
      ],
    );
  }
}
