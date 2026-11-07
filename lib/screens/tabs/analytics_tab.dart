import 'package:flutter/material.dart';
import '../../models/category_model.dart';
import '../../models/transaction_model.dart';
import '../../services/category_service.dart';
import '../../services/finance_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/custom_pie_chart.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/transaction_card.dart';

enum ReportPeriod { daily, monthly }

class AnalyticsTab extends StatefulWidget {
  const AnalyticsTab({super.key});

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  ReportPeriod _period = ReportPeriod.daily;
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime.now();

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

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  String _getMonthName(DateTime date) {
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  void _showSetBudgetDialog(BuildContext context, CategoryModel cat) {
    final finance = FinanceService.instance;
    final monthKey = '${_currentMonth.year}-${_currentMonth.month.toString().padLeft(2, '0')}';
    final currentBudget = finance.getBudgetForCategory(cat.id, monthKey);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final controller = TextEditingController(
      text: currentBudget != null ? currentBudget.limitAmount.toInt().toString() : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB)),
        ),
        title: Text('سقف: ${cat.nameAr}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'أدخل الحد الأقصى الشهري:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: '0.00',
                labelText: 'السقف الشهري',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          if (currentBudget != null)
            TextButton(
              onPressed: () {
                finance.setBudget(cat.id, 0, monthKey);
                Navigator.pop(ctx);
              },
              child: const Text('إلغاء السقف', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final limit = double.tryParse(controller.text.trim()) ?? 0.0;
              finance.setBudget(cat.id, limit, monthKey);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white : Colors.black,
              foregroundColor: isDark ? Colors.black : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final finance = FinanceService.instance;
    final isDaily = _period == ReportPeriod.daily;
    final isToday = Formatters.isToday(_selectedDate);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? Colors.white : Colors.black;
    final navBarBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderCol = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB);
    final toggleBg = isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6);
    final selectedTabBg = isDark ? Colors.white : Colors.black;
    final selectedTabText = isDark ? Colors.black : Colors.white;
    final unselectedTabText = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF4B5563);

    final monthKey = '${_currentMonth.year}-${_currentMonth.month.toString().padLeft(2, '0')}';

    return ListenableBuilder(
      listenable: finance,
      builder: (context, _) {
        final double totalIncome;
        final double totalExpense;
        final Map<String, double> categoryExpenses;
        final List<TransactionModel> dayTransactions;

        if (isDaily) {
          totalIncome = finance.getDailyIncome(_selectedDate);
          totalExpense = finance.getDailyExpense(_selectedDate);
          categoryExpenses = finance.getDailyCategoryExpenses(_selectedDate);
          dayTransactions = finance.transactions
              .where((t) =>
                  t.date.year == _selectedDate.year &&
                  t.date.month == _selectedDate.month &&
                  t.date.day == _selectedDate.day)
              .toList();
        } else {
          totalIncome = finance.getMonthlyIncome(_currentMonth);
          totalExpense = finance.getMonthlyExpense(_currentMonth);
          categoryExpenses = finance.getCategoryExpenses(_currentMonth);
          dayTransactions = const [];
        }

        final netSavings = totalIncome - totalExpense;

        // Prepare pie chart slices
        final slices = <PieSliceData>[];
        categoryExpenses.forEach((catId, amount) {
          final cat = CategoryModel.getById(catId);
          slices.add(PieSliceData(
            label: cat.nameAr,
            value: amount,
            color: cat.color,
            icon: cat.icon,
          ));
        });
        slices.sort((a, b) => b.value.compareTo(a.value));

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Period Toggle (يومي / شهري)
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
                        onTap: () => setState(() => _period = ReportPeriod.daily),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isDaily ? selectedTabBg : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'تقرير يومي',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDaily ? selectedTabText : unselectedTabText,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _period = ReportPeriod.monthly),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: !isDaily ? selectedTabBg : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'تقرير شهري',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: !isDaily ? selectedTabText : unselectedTabText,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Date / Month Navigation Bar
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
                    // Back / Earlier Arrow (chevron_right in RTL)
                    IconButton(
                      icon: Icon(Icons.chevron_right_rounded, size: 24, color: textCol),
                      tooltip: isDaily ? 'اليوم السابق' : 'الشهر السابق',
                      onPressed: isDaily ? _previousDay : _previousMonth,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),

                    // Center Date/Month Label
                    Expanded(
                      child: InkWell(
                        onTap: isDaily ? _pickDate : null,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isDaily ? Icons.calendar_today_rounded : Icons.calendar_month_rounded,
                                size: 15,
                                color: textCol,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  isDaily
                                      ? Formatters.formatDayHeader(_selectedDate)
                                      : _getMonthName(_currentMonth),
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

                    // Shortcut to Today (Daily mode only)
                    if (isDaily && !isToday) ...[
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

                    // Forward / Later Arrow (chevron_left in RTL)
                    IconButton(
                      icon: Icon(Icons.chevron_left_rounded, size: 24, color: textCol),
                      tooltip: isDaily ? 'اليوم التالي' : 'الشهر التالي',
                      onPressed: isDaily ? _nextDay : _nextMonth,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Summary Stats (3 cards)
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'الدخل',
                      Formatters.formatAmount(totalIncome),
                      const Color(0xFF16A34A),
                      Icons.arrow_downward_rounded,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'المصروف',
                      Formatters.formatAmount(totalExpense),
                      const Color(0xFFDC2626),
                      Icons.arrow_upward_rounded,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'الصافي',
                      Formatters.formatAmount(netSavings),
                      netSavings >= 0 ? const Color(0xFF2563EB) : const Color(0xFFDC2626),
                      Icons.savings_rounded,
                      isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Donut Chart Card
              GlassContainer(
                padding: const EdgeInsets.all(20),
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  children: [
                    Text(
                      isDaily
                          ? (isToday ? 'مصاريف اليوم' : 'مصاريف هذا اليوم')
                          : 'مصاريف الشهر',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    CustomPieChart(
                      data: slices,
                      totalAmount: totalExpense,
                      centerTitle: 'المصاريف',
                      centerSubtitle: Formatters.formatAmount(totalExpense),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Categories Breakdown
              Text(
                isDaily ? 'تصنيفات هذا اليوم' : 'التصنيفات والسقوف',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              if (slices.isEmpty)
                GlassContainer(
                  padding: const EdgeInsets.all(24),
                  borderRadius: BorderRadius.circular(20),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.pie_chart_outline_rounded, size: 40, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          isDaily
                              ? (isToday
                                  ? 'لا توجد مصاريف مسجلة اليوم حتى الآن'
                                  : 'لا توجد مصاريف مسجلة في هذا اليوم')
                              : 'لا توجد مصاريف مسجلة في هذا الشهر',
                          style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...slices.map((slice) {
                  final cat = CategoryService.getByName(slice.label) ?? CategoryModel.getById('other_exp');
                  final budget = !isDaily ? finance.getBudgetForCategory(cat.id, monthKey) : null;
                  final percentage = totalExpense > 0 ? (slice.value / totalExpense) : 0.0;

                  return GlassContainer(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    borderRadius: BorderRadius.circular(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: cat.color.withAlpha(25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(cat.icon, size: 18, color: cat.color),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cat.nameAr,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                  if (budget != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'السقف: ${Formatters.formatAmount(budget.limitAmount)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: slice.value > budget.limitAmount ? Colors.red : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  Formatters.formatAmount(slice.value),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${(percentage * 100).toStringAsFixed(1)}%',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                            if (!isDaily) ...[
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.speed_rounded, size: 18, color: Colors.grey),
                                tooltip: 'تحديد سقف مالي',
                                onPressed: () => _showSetBudgetDialog(context, cat),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: budget != null
                                ? (slice.value / budget.limitAmount).clamp(0.0, 1.0)
                                : percentage.clamp(0.0, 1.0),
                            backgroundColor: Colors.grey.withAlpha(30),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              budget != null && slice.value > budget.limitAmount
                                  ? Colors.red
                                  : cat.color,
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  );
                }),

              // In Daily mode: show the list of transactions for that day
              if (isDaily && dayTransactions.isNotEmpty) ...[
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'معاملات هذا اليوم (${dayTransactions.length})',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...dayTransactions.map((tx) => TransactionCard(transaction: tx)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String amount, Color color, IconData icon, bool isDark) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB), width: 1.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            amount,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
