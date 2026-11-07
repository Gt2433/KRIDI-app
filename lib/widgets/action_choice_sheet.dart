import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../theme/app_theme.dart';
import 'add_edit_debt_sheet.dart';
import 'add_edit_transaction_sheet.dart';

class ActionChoiceSheet extends StatelessWidget {
  const ActionChoiceSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(90),
      isScrollControlled: true,
      builder: (context) => const ActionChoiceSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0F172A).withAlpha(200)
                : Colors.white.withAlpha(210),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withAlpha(35)
                    : Colors.white.withAlpha(220),
                width: 1.5,
              ),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // iOS Pill Grabber
                Container(
                  width: 38,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'إضافة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.primary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 18),

                // Choice Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildChoiceCard(
                        context: context,
                        title: 'مصروف',
                        color: const Color(0xFFEF4444),
                        icon: Icons.arrow_downward_rounded,
                        isDark: isDark,
                        onTap: () {
                          Navigator.pop(context);
                          AddEditTransactionSheet.show(
                            context,
                            initialType: TransactionType.expense,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildChoiceCard(
                        context: context,
                        title: 'دخل',
                        color: const Color(0xFF10B981),
                        icon: Icons.arrow_upward_rounded,
                        isDark: isDark,
                        onTap: () {
                          Navigator.pop(context);
                          AddEditTransactionSheet.show(
                            context,
                            initialType: TransactionType.income,
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildChoiceCard(
                        context: context,
                        title: 'تحويل',
                        color: const Color(0xFF3B82F6),
                        icon: Icons.swap_horiz_rounded,
                        isDark: isDark,
                        onTap: () {
                          Navigator.pop(context);
                          AddEditTransactionSheet.show(
                            context,
                            initialType: TransactionType.transfer,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildChoiceCard(
                        context: context,
                        title: 'دَين',
                        color: const Color(0xFF8B5CF6),
                        icon: Icons.handshake_rounded,
                        isDark: isDark,
                        onTap: () {
                          Navigator.pop(context);
                          AddEditDebtSheet.show(context);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceCard({
    required BuildContext context,
    required String title,
    required Color color,
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: color.withAlpha(isDark ? 28 : 20),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withAlpha(isDark ? 65 : 75),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withAlpha(80),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : color.withAlpha(240),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
