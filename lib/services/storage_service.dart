import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/debt_model.dart';

class StorageService {
  static const String _keyDebts = 'kredi_debts_v1';

  /// Save list of debts to local storage
  static Future<bool> saveDebts(List<Debt> debts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encodedList = json.encode(debts.map((d) => d.toMap()).toList());
      return await prefs.setString(_keyDebts, encodedList);
    } catch (e) {
      return false;
    }
  }

  /// Load list of debts from local storage
  static Future<List<Debt>> loadDebts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? encodedList = prefs.getString(_keyDebts);
      if (encodedList == null || encodedList.isEmpty) {
        return [];
      }
      final List<dynamic> decodedList = json.decode(encodedList) as List<dynamic>;
      return decodedList
          .map((item) => Debt.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
