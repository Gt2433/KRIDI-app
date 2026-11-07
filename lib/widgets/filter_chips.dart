import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/app_strings.dart';

enum DebtFilter { unpaid, all, paid }

class FilterChips extends StatelessWidget {
  final DebtFilter currentFilter;
  final ValueChanged<DebtFilter> onFilterChanged;

  const FilterChips({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildChip(
          context: context,
          label: AppStrings.tr(context, 'filter_unpaid'),
          filter: DebtFilter.unpaid,
        ),
        const SizedBox(width: 8),
        _buildChip(
          context: context,
          label: AppStrings.tr(context, 'filter_all'),
          filter: DebtFilter.all,
        ),
        const SizedBox(width: 8),
        _buildChip(
          context: context,
          label: AppStrings.tr(context, 'filter_paid'),
          filter: DebtFilter.paid,
        ),
      ],
    );
  }

  Widget _buildChip({
    required BuildContext context,
    required String label,
    required DebtFilter filter,
  }) {
    final isSelected = currentFilter == filter;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedBg = isDark ? AppTheme.accent : AppTheme.primary;
    final unselectedBg = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final unselectedBorder = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final unselectedText = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return Expanded(
      child: GestureDetector(
        onTap: () => onFilterChanged(filter),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : unselectedBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? selectedBg : unselectedBorder,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : unselectedText,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
