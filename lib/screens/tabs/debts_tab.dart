import 'package:flutter/material.dart';
import '../../models/debt_model.dart';
import '../../services/finance_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/add_edit_debt_sheet.dart';
import '../../widgets/confirm_delete_dialog.dart';
import '../../widgets/debt_card.dart';
import '../../widgets/glass_container.dart';

enum DebtFilterStatus { all, unpaid, paid }
enum DebtFilterDirection { all, toMe, fromMe }

class DebtsTab extends StatefulWidget {
  const DebtsTab({super.key});

  @override
  State<DebtsTab> createState() => _DebtsTabState();
}

class _DebtsTabState extends State<DebtsTab> {
  DebtFilterStatus _statusFilter = DebtFilterStatus.unpaid;
  DebtFilterDirection _directionFilter = DebtFilterDirection.all;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final finance = FinanceService.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final toMeBg = isDark ? const Color(0xFF064E3B).withAlpha(80) : const Color(0xFFF0FDF4);
    final toMeBorder = isDark ? const Color(0xFF065F46) : const Color(0xFFBBF7D0);
    final fromMeBg = isDark ? const Color(0xFF7F1D1D).withAlpha(80) : const Color(0xFFFEF2F2);
    final fromMeBorder = isDark ? const Color(0xFF991B1B) : const Color(0xFFFECACA);

    return ListenableBuilder(
      listenable: finance,
      builder: (context, _) {
        var list = finance.debts;

        // Status Filter
        if (_statusFilter == DebtFilterStatus.unpaid) {
          list = list.where((d) => !d.isPaid).toList();
        } else if (_statusFilter == DebtFilterStatus.paid) {
          list = list.where((d) => d.isPaid).toList();
        }

        // Direction Filter
        if (_directionFilter == DebtFilterDirection.toMe) {
          list = list.where((d) => d.type == DebtType.toMe).toList();
        } else if (_directionFilter == DebtFilterDirection.fromMe) {
          list = list.where((d) => d.type == DebtType.fromMe).toList();
        }

        // Search Filter
        if (_searchQuery.trim().isNotEmpty) {
          final query = _searchQuery.trim().toLowerCase();
          list = list.where((d) =>
              d.personName.toLowerCase().contains(query) ||
              (d.note?.toLowerCase().contains(query) ?? false)).toList();
        }

        // Calculate Totals
        final totalUnpaidToMe = finance.totalDebtsToMeUnpaid;
        final totalUnpaidFromMe = finance.totalDebtsFromMeUnpaid;

        return Column(
          children: [
            // Top Controls Area (Transparent for ambient background)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Column(
                children: [
                  // Dual summary row
                  Row(
                    children: [
                      Expanded(
                        child: GlassContainer(
                          padding: const EdgeInsets.all(12),
                          borderRadius: BorderRadius.circular(18),
                          color: toMeBg,
                          border: Border.all(color: toMeBorder, width: 1.2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.call_made_rounded, size: 14, color: Color(0xFF16A34A)),
                                  SizedBox(width: 4),
                                  Text('لك', style: TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                Formatters.formatAmount(totalUnpaidToMe),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GlassContainer(
                          padding: const EdgeInsets.all(12),
                          borderRadius: BorderRadius.circular(18),
                          color: fromMeBg,
                          border: Border.all(color: fromMeBorder, width: 1.2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.call_received_rounded, size: 14, color: Color(0xFFDC2626)),
                                  SizedBox(width: 4),
                                  Text('عليك', style: TextStyle(fontSize: 11, color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                Formatters.formatAmount(totalUnpaidFromMe),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Glass Search Field + Add Debt Button
                  Row(
                    children: [
                      Expanded(
                        child: GlassContainer(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                          borderRadius: BorderRadius.circular(18),
                          child: TextField(
                            onChanged: (val) => setState(() => _searchQuery = val),
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'بحث...',
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
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => AddEditDebtSheet.show(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white : Colors.black,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_rounded, color: isDark ? Colors.black : Colors.white, size: 20),
                                const SizedBox(width: 4),
                                Text(
                                  'إضافة',
                                  style: TextStyle(
                                    color: isDark ? Colors.black : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Status Chips
                  Row(
                    children: [
                      _buildChip('غير مسدد', _statusFilter == DebtFilterStatus.unpaid, isDark, () {
                        setState(() => _statusFilter = DebtFilterStatus.unpaid);
                      }),
                      const SizedBox(width: 6),
                      _buildChip('مسدد', _statusFilter == DebtFilterStatus.paid, isDark, () {
                        setState(() => _statusFilter = DebtFilterStatus.paid);
                      }),
                      const SizedBox(width: 6),
                      _buildChip('الكل', _statusFilter == DebtFilterStatus.all, isDark, () {
                        setState(() => _statusFilter = DebtFilterStatus.all);
                      }),
                      const Spacer(),
                      // Direction Filter Dropdown
                      DropdownButton<DebtFilterDirection>(
                        value: _directionFilter,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.tune_rounded, size: 18),
                        items: const [
                          DropdownMenuItem(value: DebtFilterDirection.all, child: Text('الكل', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: DebtFilterDirection.toMe, child: Text('لك', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: DebtFilterDirection.fromMe, child: Text('عليك', style: TextStyle(fontSize: 12))),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _directionFilter = v);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Debts List
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: GlassContainer(
                        margin: const EdgeInsets.all(24),
                        padding: const EdgeInsets.all(24),
                        borderRadius: BorderRadius.circular(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.handshake_outlined, size: 48, color: Colors.grey.withAlpha(120)),
                            const SizedBox(height: 10),
                            const Text(
                              'لا توجد ديون',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton.icon(
                              onPressed: () => AddEditDebtSheet.show(context),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('إضافة'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? Colors.white : Colors.black,
                                foregroundColor: isDark ? Colors.black : Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 90),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final debt = list[index];
                        return DebtCard(
                          debt: debt,
                          onTogglePaid: () => finance.toggleDebtPaid(debt.id),
                          onEdit: () => AddEditDebtSheet.show(context, initialDebt: debt),
                          onDelete: () async {
                            final confirmed = await ConfirmDeleteDialog.show(
                              context,
                              personName: debt.personName,
                            );
                            if (confirmed == true) {
                              finance.deleteDebt(debt.id);
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChip(String label, bool isSelected, bool isDark, VoidCallback onTap) {
    final activeBg = isDark ? Colors.white : Colors.black;
    final activeText = isDark ? Colors.black : Colors.white;
    final inactiveBg = isDark ? const Color(0xFF27272A) : const Color(0xFFF9FAFB);
    final inactiveText = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF374151);
    final borderCol = isSelected
        ? activeBg
        : (isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB));

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: borderCol,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? activeText : inactiveText,
          ),
        ),
      ),
    );
  }
}
