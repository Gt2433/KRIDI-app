import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../services/category_service.dart';
import '../widgets/add_category_sheet.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  CategoryType _selectedType = CategoryType.expense;

  void _showAddCategorySheet() async {
    final newCat = await AddCategorySheet.show(
      context,
      defaultType: _selectedType,
    );
    if (newCat != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تمت إضافة تصنيف "${newCat.nameAr}" بنجاح!'),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
    }
  }

  void _confirmDelete(CategoryModel cat) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB)),
          ),
          title: Text(
            'حذف التصنيف',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: isDark ? Colors.white : Colors.black),
          ),
          content: Text(
            'هل أنت متأكد من حذف تصنيف "${cat.nameAr}"؟ لن يتم حذف المعاملات السابقة المرتبطة به.',
            style: TextStyle(fontSize: 14, color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF4B5563)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('إلغاء', style: TextStyle(color: isDark ? const Color(0xFFA1A1AA) : Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await CategoryService.deleteCategory(cat.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم حذف تصنيف "${cat.nameAr}"'),
                      backgroundColor: Colors.black,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE11D48),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF121212) : Colors.white;
    final textCol = isDark ? Colors.white : Colors.black;
    final toggleBg = isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6);
    final itemBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFAFAFA);
    final itemBorder = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFF3F4F6);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: textCol),
        title: Text(
          'التصنيفات',
          style: TextStyle(fontWeight: FontWeight.bold, color: textCol, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: textCol, size: 26),
            tooltip: 'إضافة تصنيف',
            onPressed: _showAddCategorySheet,
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: textCol),
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            onSelected: (val) async {
              if (val == 'reset') {
                await CategoryService.resetToDefaults();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تمت استعادة التصنيفات الافتراضية')),
                );
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'reset',
                child: Text('استعادة التصنيفات الافتراضية', style: TextStyle(color: textCol)),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Pills (مصاريف / مداخيل)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: toggleBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedType = CategoryType.expense),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: _selectedType == CategoryType.expense
                                ? (isDark ? Colors.white : Colors.black)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'المصاريف',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _selectedType == CategoryType.expense
                                  ? (isDark ? Colors.black : Colors.white)
                                  : (isDark ? const Color(0xFFA1A1AA) : const Color(0xFF4B5563)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedType = CategoryType.income),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: _selectedType == CategoryType.income
                                ? (isDark ? Colors.white : Colors.black)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'المداخيل',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _selectedType == CategoryType.income
                                  ? (isDark ? Colors.black : Colors.white)
                                  : (isDark ? const Color(0xFFA1A1AA) : const Color(0xFF4B5563)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Categories List
            Expanded(
              child: ValueListenableBuilder<List<CategoryModel>>(
                valueListenable: CategoryService.categoriesNotifier,
                builder: (context, allCategories, _) {
                  final list = allCategories.where((c) => c.type == _selectedType).toList();

                  if (list.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.category_outlined, size: 52, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'لا توجد تصنيفات',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _showAddCategorySheet,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('إضافة تصنيف جديد'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? Colors.white : Colors.black,
                              foregroundColor: isDark ? Colors.black : Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final cat = list[idx];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: itemBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: itemBorder),
                        ),
                        child: Row(
                          children: [
                            // Icon Box
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: cat.color.withAlpha(25),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: cat.color.withAlpha(60)),
                              ),
                              child: Icon(cat.icon, color: cat.color, size: 22),
                            ),
                            const SizedBox(width: 12),

                            // Name & Badge
                            Expanded(
                              child: Row(
                                children: [
                                  Text(
                                    cat.nameAr,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: textCol,
                                    ),
                                  ),
                                  if (cat.isCustom) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: itemBorder),
                                      ),
                                      child: Text(
                                        'مخصص',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Delete Action
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFE11D48)),
                              tooltip: 'حذف',
                              onPressed: () => _confirmDelete(cat),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _showAddCategorySheet,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'إضافة تصنيف جديد',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white : Colors.black,
                foregroundColor: isDark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
