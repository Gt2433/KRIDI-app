import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';
import '../../services/finance_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/transaction_card.dart';

enum TxFilterType { all, expense, income, transfer }

class TransactionsTab extends StatefulWidget {
  const TransactionsTab({super.key});

  @override
  State<TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends State<TransactionsTab> {
  TxFilterType _filterType = TxFilterType.all;
  String _searchQuery = '';
  DateTime _selectedDate = DateTime.now();

  void _previousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
  }

  void _nextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
  }

  void _goToToday() {
    setState(() {
      _selectedDate = DateTime.now();
    });
  }

  Future<void> _pickDate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Colors.white,
                    onPrimary: Colors.black,
                    surface: Color(0xFF1E1E1E),
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: Colors.black,
                    onPrimary: Colors.white,
                  ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final finance = FinanceService.instance;
    final isToday = Formatters.isToday(_selectedDate);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBarBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderCol = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB);
    final textCol = isDark ? Colors.white : Colors.black;

    return ListenableBuilder(
      listenable: finance,
      builder: (context, _) {
        var list = finance.transactions;

        // 1. Filter by Selected Day (every 24h is a fresh day)
        list = list
            .where((t) =>
                t.date.year == _selectedDate.year &&
                t.date.month == _selectedDate.month &&
                t.date.day == _selectedDate.day)
            .toList();

        // 2. Filter by Type
        if (_filterType == TxFilterType.expense) {
          list = list.where((t) => t.type == TransactionType.expense).toList();
        } else if (_filterType == TxFilterType.income) {
          list = list.where((t) => t.type == TransactionType.income).toList();
        } else if (_filterType == TxFilterType.transfer) {
          list = list.where((t) => t.type == TransactionType.transfer).toList();
        }

        // 3. Filter by Search Query
        if (_searchQuery.trim().isNotEmpty) {
          final query = _searchQuery.trim().toLowerCase();
          list = list.where((t) {
            final titleMatch = t.title.toLowerCase().contains(query);
            final noteMatch = t.note?.toLowerCase().contains(query) ?? false;
            return titleMatch || noteMatch;
          }).toList();
        }

        // Calculate daily sums for filtered list
        double totalExpense = 0;
        double totalIncome = 0;
        for (final t in list) {
          if (t.type == TransactionType.expense) totalExpense += t.amount;
          if (t.type == TransactionType.income) totalIncome += t.amount;
        }

        return Column(
          children: [
            // Top Navigation & Filter Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Column(
                children: [
                  // Day Navigator Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: navBarBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: borderCol),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black.withAlpha(40) : Colors.black.withAlpha(5),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Previous Day Arrow (chevron_right points to earlier day in RTL)
                        IconButton(
                          icon: Icon(Icons.chevron_right_rounded, size: 24, color: textCol),
                          tooltip: 'اليوم السابق',
                          onPressed: _previousDay,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        ),

                        // Center Day Button (Tap to pick date)
                        Expanded(
                          child: InkWell(
                            onTap: _pickDate,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.calendar_today_rounded, size: 14, color: textCol),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      Formatters.formatDayHeader(_selectedDate),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: textCol,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Return to Today Shortcut (if looking at another day)
                        if (!isToday) ...[
                          InkWell(
                            onTap: _goToToday,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white : Colors.black,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'اليوم',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.black : Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],

                        // Next Day Arrow (chevron_left points to next day in RTL)
                        IconButton(
                          icon: Icon(Icons.chevron_left_rounded, size: 24, color: textCol),
                          tooltip: 'اليوم التالي',
                          onPressed: _nextDay,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Search Bar
                  GlassContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    borderRadius: BorderRadius.circular(18),
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'بحث في معاملات هذا اليوم...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () => setState(() => _searchQuery = ''),
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Type Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('الكل', TxFilterType.all, null),
                        const SizedBox(width: 8),
                        _buildFilterChip('مصاريف', TxFilterType.expense, const Color(0xFFEF4444)),
                        const SizedBox(width: 8),
                        _buildFilterChip('دخل', TxFilterType.income, const Color(0xFF10B981)),
                        const SizedBox(width: 8),
                        _buildFilterChip('تحويل', TxFilterType.transfer, const Color(0xFF3B82F6)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Daily Summary Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${list.length} معاملة ${isToday ? 'اليوم' : ''}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        if (totalIncome > 0) ...[
                          Text(
                            '+${Formatters.formatAmount(totalIncome)}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (totalExpense > 0)
                          Text(
                            '-${Formatters.formatAmount(totalExpense)}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Daily Transactions List or Clean Empty State
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isToday ? Icons.calendar_today_rounded : Icons.event_busy_rounded,
                              size: 52,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              isToday
                                  ? 'لا توجد معاملات مسجلة اليوم'
                                  : 'لا توجد معاملات مسجلة في هذا اليوم',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isToday
                                  ? 'يتجدد هذا القسم تلقائياً كل 24 ساعة لبدء يوم جديد'
                                  : 'يمكنك التنقل بين الأيام لرؤية معاملات كل يوم',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                              textAlign: TextAlign.center,
                            ),
                            if (!isToday) ...[
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _goToToday,
                                icon: const Icon(Icons.today_rounded, size: 16),
                                label: const Text('الرجوع لليوم'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? Colors.white : Colors.black,
                                  foregroundColor: isDark ? Colors.black : Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 0,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        return TransactionCard(transaction: list[index]);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(String label, TxFilterType type, Color? activeColor) {
    final isSelected = _filterType == type;
    final color = activeColor ?? AppTheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _filterType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color
              : (isDark ? Colors.white.withAlpha(15) : Colors.white.withAlpha(180)),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark ? Colors.white.withAlpha(20) : Colors.white.withAlpha(140)),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withAlpha(80),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }
}
