import 'package:flutter/material.dart';
import '../models/debt_model.dart';
import '../services/storage_service.dart';
import '../services/update_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_strings.dart';
import 'settings_screen.dart';
import '../widgets/add_edit_debt_sheet.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/debt_card.dart';
import '../widgets/filter_chips.dart';
import '../widgets/summary_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Debt> _debts = [];
  DebtFilter _filter = DebtFilter.unpaid;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDebts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkForUpdate(context, isManualCheck: false);
    });
  }

  Future<void> _loadDebts() async {
    final loaded = await StorageService.loadDebts();
    loaded.sort((a, b) {
      if (a.isPaid != b.isPaid) {
        return a.isPaid ? 1 : -1;
      }
      return b.date.compareTo(a.date);
    });

    if (mounted) {
      setState(() {
        _debts = loaded;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveDebts() async {
    await StorageService.saveDebts(_debts);
  }

  double get _totalUnpaidAmount {
    return _debts
        .where((d) => !d.isPaid)
        .fold(0.0, (sum, debt) => sum + debt.amount);
  }

  int get _unpaidCount {
    return _debts.where((d) => !d.isPaid).length;
  }

  List<Debt> get _filteredDebts {
    switch (_filter) {
      case DebtFilter.unpaid:
        return _debts.where((d) => !d.isPaid).toList();
      case DebtFilter.paid:
        return _debts.where((d) => d.isPaid).toList();
      case DebtFilter.all:
        return _debts;
    }
  }

  void _openAddDebtSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditDebtSheet(
        onSave: (newDebt) {
          setState(() {
            _debts.insert(0, newDebt);
          });
          _saveDebts();
        },
      ),
    );
  }

  void _openEditDebtSheet(Debt debt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditDebtSheet(
        initialDebt: debt,
        onSave: (updatedDebt) {
          setState(() {
            final index = _debts.indexWhere((d) => d.id == updatedDebt.id);
            if (index != -1) {
              _debts[index] = updatedDebt;
            }
          });
          _saveDebts();
        },
      ),
    );
  }

  void _togglePaid(Debt debt) {
    setState(() {
      final index = _debts.indexWhere((d) => d.id == debt.id);
      if (index != -1) {
        _debts[index] = debt.copyWith(isPaid: !debt.isPaid);
      }
    });
    _saveDebts();
  }

  Future<void> _deleteDebt(Debt debt) async {
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      personName: debt.personName,
    );

    if (confirmed == true) {
      setState(() {
        _debts.removeWhere((d) => d.id == debt.id);
      });
      _saveDebts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredDebts;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final secondaryTextColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.accent,
                ),
              )
            : CustomScrollView(
                slivers: [
                  // App Header with Settings Button & Slogan
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppStrings.tr(context, 'app_name'),
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accent.withAlpha(25),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.settings_outlined,
                                    color: AppTheme.accent,
                                    size: 22,
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const SettingsScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppStrings.tr(context, 'slogan'),
                            style: TextStyle(
                              fontSize: 13,
                              color: secondaryTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Main Summary Card
                          SummaryCard(
                            totalUnpaidAmount: _totalUnpaidAmount,
                            unpaidCount: _unpaidCount,
                          ),
                          const SizedBox(height: 20),

                          // Filter Selector
                          FilterChips(
                            currentFilter: _filter,
                            onFilterChanged: (newFilter) {
                              setState(() {
                                _filter = newFilter;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  // Debts List or Empty State
                  if (filtered.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final debt = filtered[index];
                            return DebtCard(
                              key: ValueKey(debt.id),
                              debt: debt,
                              onTogglePaid: () => _togglePaid(debt),
                              onEdit: () => _openEditDebtSheet(debt),
                              onDelete: () => _deleteDebt(debt),
                            );
                          },
                          childCount: filtered.length,
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 80),
                  ),
                ],
              ),
      ),

      // Bottom Floating Action Button to Add Debt
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _openAddDebtSheet,
            icon: const Icon(Icons.add_rounded, size: 22),
            label: Text(
              AppStrings.tr(context, 'add_debt_button'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String title;
    String subtitle;
    IconData icon;

    switch (_filter) {
      case DebtFilter.unpaid:
        title = AppStrings.tr(context, 'empty_unpaid_title');
        subtitle = AppStrings.tr(context, 'empty_unpaid_sub');
        icon = Icons.check_circle_outline_rounded;
        break;
      case DebtFilter.paid:
        title = AppStrings.tr(context, 'empty_paid_title');
        subtitle = AppStrings.tr(context, 'empty_paid_sub');
        icon = Icons.history_rounded;
        break;
      case DebtFilter.all:
        title = AppStrings.tr(context, 'empty_all_title');
        subtitle = AppStrings.tr(context, 'empty_all_sub');
        icon = Icons.receipt_long_outlined;
        break;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final secondaryTextColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.darkBorder.withAlpha(80)
                    : AppTheme.lightBorder.withAlpha(80),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: secondaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
