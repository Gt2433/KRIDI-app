import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category_model.dart';

class CategoryService {
  static const String _keyCustomCategories = 'kredi_custom_categories';
  static const String _keyDeletedCategoryIds = 'kredi_deleted_category_ids';

  static final ValueNotifier<List<CategoryModel>> categoriesNotifier = ValueNotifier<List<CategoryModel>>([]);

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Load custom categories
    final customJson = prefs.getStringList(_keyCustomCategories) ?? [];
    final List<CategoryModel> customList = [];
    for (final str in customJson) {
      try {
        final map = jsonDecode(str) as Map<String, dynamic>;
        customList.add(CategoryModel.fromMap(map));
      } catch (e) {
        debugPrint('Error parsing custom category: $e');
      }
    }

    // 2. Load deleted category IDs
    final deletedIds = prefs.getStringList(_keyDeletedCategoryIds) ?? [];

    // 3. Assemble active categories
    final List<CategoryModel> active = [];
    for (final def in CategoryModel.defaultCategories) {
      if (!deletedIds.contains(def.id)) {
        active.add(def);
      }
    }
    for (final c in customList) {
      if (!deletedIds.contains(c.id)) {
        active.add(c);
      }
    }

    categoriesNotifier.value = active;
  }

  static List<CategoryModel> get categories => categoriesNotifier.value;

  static List<CategoryModel> get expenseCategories =>
      categoriesNotifier.value.where((c) => c.type == CategoryType.expense).toList();

  static List<CategoryModel> get incomeCategories =>
      categoriesNotifier.value.where((c) => c.type == CategoryType.income).toList();

  static List<CategoryModel> getCategoriesForType(CategoryType type) {
    return categoriesNotifier.value.where((c) => c.type == type).toList();
  }

  static CategoryModel getById(String id) {
    // 1. Check in active categories
    for (final c in categoriesNotifier.value) {
      if (c.id == id) return c;
    }
    // 2. Check in default categories
    for (final def in CategoryModel.defaultCategories) {
      if (def.id == id) return def;
    }
    // 3. Safe fallback
    return CategoryModel.defaultCategories.first;
  }

  static CategoryModel? getByName(String name) {
    for (final c in categoriesNotifier.value) {
      if (c.nameAr == name || c.nameEn == name) return c;
    }
    for (final def in CategoryModel.defaultCategories) {
      if (def.nameAr == name || def.nameEn == name) return def;
    }
    return null;
  }

  static Future<CategoryModel> addCategory({
    required String name,
    required CategoryType type,
    required IconData icon,
    required Color color,
  }) async {
    final newId = 'cat_${DateTime.now().millisecondsSinceEpoch}';
    final newCat = CategoryModel(
      id: newId,
      nameAr: name.trim(),
      nameEn: name.trim(),
      icon: icon,
      color: color,
      type: type,
      isCustom: true,
    );

    final current = List<CategoryModel>.from(categoriesNotifier.value);
    current.add(newCat);
    categoriesNotifier.value = current;

    await _saveCustomCategories();
    return newCat;
  }

  static Future<void> deleteCategory(String id) async {
    final prefs = await SharedPreferences.getInstance();

    // Mark as deleted in deleted category IDs
    final deletedIds = prefs.getStringList(_keyDeletedCategoryIds) ?? [];
    if (!deletedIds.contains(id)) {
      deletedIds.add(id);
      await prefs.setStringList(_keyDeletedCategoryIds, deletedIds);
    }

    // Remove from active notifier
    final current = List<CategoryModel>.from(categoriesNotifier.value);
    current.removeWhere((c) => c.id == id);
    categoriesNotifier.value = current;

    await _saveCustomCategories();
  }

  static Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDeletedCategoryIds);

    // Keep custom categories
    final customJson = prefs.getStringList(_keyCustomCategories) ?? [];
    final List<CategoryModel> customList = [];
    for (final str in customJson) {
      try {
        final map = jsonDecode(str) as Map<String, dynamic>;
        customList.add(CategoryModel.fromMap(map));
      } catch (_) {}
    }

    categoriesNotifier.value = [...CategoryModel.defaultCategories, ...customList];
  }

  static Future<void> _saveCustomCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final customOnly = categoriesNotifier.value.where((c) => c.isCustom).toList();
    final listStr = customOnly.map((c) => jsonEncode(c.toMap())).toList();
    await prefs.setStringList(_keyCustomCategories, listStr);
  }
}
