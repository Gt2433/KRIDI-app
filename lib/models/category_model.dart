import 'package:flutter/material.dart';
import '../services/category_service.dart';

enum CategoryType { expense, income }

class CategoryIcons {
  static const Map<String, IconData> iconMap = {
    'restaurant': Icons.restaurant_rounded,
    'cafe': Icons.local_cafe_rounded,
    'fastfood': Icons.fastfood_rounded,
    'pizza': Icons.local_pizza_rounded,
    'car': Icons.directions_car_rounded,
    'gas': Icons.local_gas_station_rounded,
    'bus': Icons.directions_bus_rounded,
    'flight': Icons.flight_rounded,
    'shopping': Icons.shopping_bag_rounded,
    'cart': Icons.shopping_cart_rounded,
    'clothes': Icons.checkroom_rounded,
    'cut': Icons.cut_rounded,
    'fitness': Icons.fitness_center_rounded,
    'sports': Icons.sports_soccer_rounded,
    'medical': Icons.medical_services_rounded,
    'pharmacy': Icons.local_pharmacy_rounded,
    'home': Icons.home_rounded,
    'bills': Icons.receipt_long_rounded,
    'electricity': Icons.bolt_rounded,
    'wifi': Icons.wifi_rounded,
    'school': Icons.school_rounded,
    'laptop': Icons.laptop_chromebook_rounded,
    'work': Icons.work_outline_rounded,
    'savings': Icons.savings_rounded,
    'gift': Icons.card_giftcard_rounded,
    'pets': Icons.pets_rounded,
    'child': Icons.child_care_rounded,
    'games': Icons.sports_esports_rounded,
    'wallet': Icons.account_balance_wallet_rounded,
    'store': Icons.storefront_rounded,
    'trending': Icons.trending_up_rounded,
    'category': Icons.category_rounded,
  };

  static String getKey(IconData icon) {
    for (final entry in iconMap.entries) {
      if (entry.value.codePoint == icon.codePoint) {
        return entry.key;
      }
    }
    return 'category';
  }

  static IconData getIcon(String? key) {
    if (key == null) return Icons.category_rounded;
    return iconMap[key] ?? Icons.category_rounded;
  }
}

class CategoryModel {
  final String id;
  final String nameAr;
  final String nameEn;
  final IconData icon;
  final Color color;
  final CategoryType type;
  final bool isCustom;

  const CategoryModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.icon,
    required this.color,
    required this.type,
    this.isCustom = false,
  });

  String getName(String langCode) => langCode == 'ar' ? nameAr : nameEn;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nameAr': nameAr,
      'nameEn': nameEn,
      'iconKey': CategoryIcons.getKey(icon),
      'colorValue': color.toARGB32(),
      'type': type == CategoryType.income ? 'income' : 'expense',
      'isCustom': isCustom,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String,
      nameAr: map['nameAr'] as String,
      nameEn: map['nameEn'] as String? ?? map['nameAr'] as String,
      icon: CategoryIcons.getIcon(map['iconKey'] as String?),
      color: Color(map['colorValue'] as int? ?? 0xFF64748B),
      type: map['type'] == 'income' ? CategoryType.income : CategoryType.expense,
      isCustom: map['isCustom'] as bool? ?? false,
    );
  }

  CategoryModel copyWith({
    String? id,
    String? nameAr,
    String? nameEn,
    IconData? icon,
    Color? color,
    CategoryType? type,
    bool? isCustom,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  static const List<CategoryModel> defaultCategories = [
    // المصاريف (Expenses)
    CategoryModel(
      id: 'food',
      nameAr: 'طعام ومشروبات',
      nameEn: 'Food & Drinks',
      icon: Icons.restaurant_rounded,
      color: Color(0xFFF97316), // Orange
      type: CategoryType.expense,
    ),
    CategoryModel(
      id: 'shopping',
      nameAr: 'تسوق ومشتريات',
      nameEn: 'Shopping',
      icon: Icons.shopping_bag_rounded,
      color: Color(0xFF8B5CF6), // Purple
      type: CategoryType.expense,
    ),
    CategoryModel(
      id: 'bills',
      nameAr: 'فواتير واشتراكات',
      nameEn: 'Bills & Utilities',
      icon: Icons.receipt_long_rounded,
      color: Color(0xFFEF4444), // Red
      type: CategoryType.expense,
    ),
    CategoryModel(
      id: 'transport',
      nameAr: 'مواصلات وبنزين',
      nameEn: 'Transportation',
      icon: Icons.directions_car_rounded,
      color: Color(0xFF3B82F6), // Blue
      type: CategoryType.expense,
    ),
    CategoryModel(
      id: 'health',
      nameAr: 'صحة وعلاج',
      nameEn: 'Health & Medical',
      icon: Icons.medical_services_rounded,
      color: Color(0xFF10B981), // Green
      type: CategoryType.expense,
    ),
    CategoryModel(
      id: 'home',
      nameAr: 'المنزل والعائلة',
      nameEn: 'Home & Family',
      icon: Icons.home_rounded,
      color: Color(0xFF14B8A6), // Teal
      type: CategoryType.expense,
    ),
    CategoryModel(
      id: 'entertainment',
      nameAr: 'ترفيه وأنشطة',
      nameEn: 'Entertainment',
      icon: Icons.sports_esports_rounded,
      color: Color(0xFFEC4899), // Pink
      type: CategoryType.expense,
    ),
    CategoryModel(
      id: 'education',
      nameAr: 'تعليم وتطوير',
      nameEn: 'Education',
      icon: Icons.school_rounded,
      color: Color(0xFF6366F1), // Indigo
      type: CategoryType.expense,
    ),
    CategoryModel(
      id: 'other_exp',
      nameAr: 'مصاريف أخرى',
      nameEn: 'Other Expenses',
      icon: Icons.category_rounded,
      color: Color(0xFF64748B), // Slate
      type: CategoryType.expense,
    ),

    // المداخيل (Incomes)
    CategoryModel(
      id: 'salary',
      nameAr: 'راتب شهري',
      nameEn: 'Salary',
      icon: Icons.account_balance_wallet_rounded,
      color: Color(0xFF16A34A), // Emerald
      type: CategoryType.income,
    ),
    CategoryModel(
      id: 'freelance',
      nameAr: 'عمل حر وتجارة',
      nameEn: 'Business & Freelance',
      icon: Icons.storefront_rounded,
      color: Color(0xFF0D9488), // Teal
      type: CategoryType.income,
    ),
    CategoryModel(
      id: 'investments',
      nameAr: 'أرباح واستثمار',
      nameEn: 'Investments',
      icon: Icons.trending_up_rounded,
      color: Color(0xFF2563EB), // Blue
      type: CategoryType.income,
    ),
    CategoryModel(
      id: 'gift',
      nameAr: 'منحة أو هدية',
      nameEn: 'Gift & Bonus',
      icon: Icons.card_giftcard_rounded,
      color: Color(0xFFA855F7), // Purple
      type: CategoryType.income,
    ),
    CategoryModel(
      id: 'other_inc',
      nameAr: 'مداخيل أخرى',
      nameEn: 'Other Income',
      icon: Icons.add_circle_outline_rounded,
      color: Color(0xFF059669), // Green
      type: CategoryType.income,
    ),
  ];

  static CategoryModel getById(String id) {
    return CategoryService.getById(id);
  }
}
