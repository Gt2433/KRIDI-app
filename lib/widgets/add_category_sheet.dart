import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../services/category_service.dart';

class AddCategorySheet extends StatefulWidget {
  final CategoryType defaultType;

  const AddCategorySheet({
    super.key,
    this.defaultType = CategoryType.expense,
  });

  static Future<CategoryModel?> show(
    BuildContext context, {
    CategoryType defaultType = CategoryType.expense,
  }) {
    return showModalBottomSheet<CategoryModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(80),
      builder: (_) => AddCategorySheet(defaultType: defaultType),
    );
  }

  @override
  State<AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<AddCategorySheet> {
  final _nameController = TextEditingController();
  late CategoryType _type;
  late Color _selectedColor;
  late IconData _selectedIcon;

  static const List<Color> _paletteColors = [
    Color(0xFF0F172A), // Black / Slate dark
    Color(0xFF3B82F6), // Blue
    Color(0xFF10B981), // Green
    Color(0xFFF97316), // Orange
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEF4444), // Red
    Color(0xFF06B6D4), // Cyan
    Color(0xFFEC4899), // Pink
    Color(0xFF14B8A6), // Teal
    Color(0xFFF59E0B), // Amber
    Color(0xFF6366F1), // Indigo
    Color(0xFF64748B), // Slate Grey
  ];

  static const List<IconData> _availableIcons = [
    // Food & Coffee
    Icons.restaurant_rounded,
    Icons.local_cafe_rounded,
    Icons.fastfood_rounded,
    Icons.local_pizza_rounded,
    // Transport
    Icons.directions_car_rounded,
    Icons.local_gas_station_rounded,
    Icons.directions_bus_rounded,
    Icons.flight_rounded,
    // Shopping & Personal
    Icons.shopping_bag_rounded,
    Icons.shopping_cart_rounded,
    Icons.checkroom_rounded,
    Icons.cut_rounded,
    // Health & Fitness
    Icons.fitness_center_rounded,
    Icons.sports_soccer_rounded,
    Icons.medical_services_rounded,
    Icons.local_pharmacy_rounded,
    // Home & Bills
    Icons.home_rounded,
    Icons.receipt_long_rounded,
    Icons.bolt_rounded,
    Icons.wifi_rounded,
    // Work & Tech & Education
    Icons.school_rounded,
    Icons.laptop_chromebook_rounded,
    Icons.work_outline_rounded,
    Icons.savings_rounded,
    Icons.card_giftcard_rounded,
    Icons.pets_rounded,
    Icons.child_care_rounded,
    Icons.category_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _type = widget.defaultType;
    _selectedColor = _paletteColors[1]; // Blue
    _selectedIcon = _availableIcons.first; // restaurant
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال اسم التصنيف'),
          backgroundColor: Color(0xFFE11D48),
        ),
      );
      return;
    }

    final newCat = await CategoryService.addCategory(
      name: name,
      type: _type,
      icon: _selectedIcon,
      color: _selectedColor,
    );

    if (mounted) {
      Navigator.of(context).pop(newCat);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderCol = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB);
    final textCol = isDark ? Colors.white : Colors.black;
    final toggleBg = isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: borderCol, width: 1.2)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: borderCol,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'تصنيف جديد',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textCol,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, size: 20, color: textCol),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Type Toggle (مصروف / دخل)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: toggleBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _type = CategoryType.expense),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: _type == CategoryType.expense
                              ? (isDark ? Colors.white : Colors.black)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'مصروف',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _type == CategoryType.expense
                                ? (isDark ? Colors.black : Colors.white)
                                : (isDark ? const Color(0xFFA1A1AA) : const Color(0xFF4B5563)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _type = CategoryType.income),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: _type == CategoryType.income
                              ? (isDark ? Colors.white : Colors.black)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'دخل',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _type == CategoryType.income
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
            const SizedBox(height: 16),

            // Name Input Field
            TextField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'اسم التصنيف',
                hintText: 'مثال: قهوة، رياضة، صيانة...',
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _selectedColor.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_selectedIcon, color: _selectedColor, size: 20),
                ),
                filled: true,
                fillColor: const Color(0xFFFAFAFA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.black, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Color Selection
            const Text(
              'اللون',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _paletteColors.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final col = _paletteColors[idx];
                  final isSelected = col == _selectedColor;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = col),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: col,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.black : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: col.withAlpha(120),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                          : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),

            // Icon Selection
            const Text(
              'الأيقونة',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Container(
              height: 150,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: GridView.builder(
                itemCount: _availableIcons.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemBuilder: (context, idx) {
                  final icon = _availableIcons[idx];
                  final isSelected = icon.codePoint == _selectedIcon.codePoint;
                  return InkWell(
                    onTap: () => setState(() => _selectedIcon = icon),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? _selectedColor.withAlpha(35) : (isDark ? const Color(0xFF27272A) : Colors.white),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? _selectedColor : borderCol,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: 22,
                        color: isSelected ? _selectedColor : (isDark ? const Color(0xFFA1A1AA) : const Color(0xFF4B5563)),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'حفظ التصنيف',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
