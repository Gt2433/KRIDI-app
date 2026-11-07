import 'package:flutter/material.dart';

class WalletModel {
  final String id;
  final String name;
  final double initialBalance;
  final int iconCode;
  final int colorValue;

  const WalletModel({
    required this.id,
    required this.name,
    this.initialBalance = 0.0,
    required this.iconCode,
    required this.colorValue,
  });

  IconData get icon {
    switch (iconCode) {
      case 0xe040:
        return Icons.payments_rounded;
      case 0xe048:
        return Icons.credit_card_rounded;
      case 0xe000:
        return Icons.account_balance_rounded;
      case 0xe571:
        return Icons.savings_rounded;
      case 0xe59c:
        return Icons.shopping_bag_rounded;
      default:
        return Icons.account_balance_wallet_rounded;
    }
  }

  Color get color => Color(colorValue);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'initialBalance': initialBalance,
      'iconCode': iconCode,
      'colorValue': colorValue,
    };
  }

  factory WalletModel.fromMap(Map<String, dynamic> map) {
    return WalletModel(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'محفظة',
      initialBalance: (map['initialBalance'] as num?)?.toDouble() ?? 0.0,
      iconCode: map['iconCode'] as int? ?? 0xe040,
      colorValue: map['colorValue'] as int? ?? 0xFF0D9488,
    );
  }

  WalletModel copyWith({
    String? id,
    String? name,
    double? initialBalance,
    int? iconCode,
    int? colorValue,
  }) {
    return WalletModel(
      id: id ?? this.id,
      name: name ?? this.name,
      initialBalance: initialBalance ?? this.initialBalance,
      iconCode: iconCode ?? this.iconCode,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  static List<WalletModel> get defaultWallets => [
        const WalletModel(
          id: 'cash',
          name: 'نقداً (كاش)',
          initialBalance: 0.0,
          iconCode: 0xe040, // payments_rounded
          colorValue: 0xFF10B981, // Emerald green
        ),
        const WalletModel(
          id: 'baridimob',
          name: 'بريدي موب (CCP)',
          initialBalance: 0.0,
          iconCode: 0xe048, // credit_card_rounded
          colorValue: 0xFFF59E0B, // Amber gold
        ),
        const WalletModel(
          id: 'bank',
          name: 'حساب بنكي',
          initialBalance: 0.0,
          iconCode: 0xe000, // account_balance_rounded
          colorValue: 0xFF3B82F6, // Blue
        ),
      ];
}
