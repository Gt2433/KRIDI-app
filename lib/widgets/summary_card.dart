import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/app_strings.dart';
import '../utils/formatters.dart';

class SummaryCard extends StatelessWidget {
  final double totalUnpaidAmount;
  final int unpaidCount;

  const SummaryCard({
    super.key,
    required this.totalUnpaidAmount,
    required this.unpaidCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : AppTheme.primary,
        borderRadius: BorderRadius.circular(20),
        border: isDark ? Border.all(color: AppTheme.darkBorder) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 50 : 25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.tr(context, 'total_unpaid'),
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: unpaidCount > 0
                      ? const Color(0xFFE11D48).withAlpha(40)
                      : const Color(0xFF10B981).withAlpha(40),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  unpaidCount > 0
                      ? AppStrings.tr(context, 'unpaid_debts_count', unpaidCount.toString())
                      : AppStrings.tr(context, 'all_debts_cleared'),
                  style: TextStyle(
                    color: unpaidCount > 0 ? const Color(0xFFFDA4AF) : const Color(0xFF6EE7B7),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            Formatters.formatAmount(totalUnpaidAmount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
