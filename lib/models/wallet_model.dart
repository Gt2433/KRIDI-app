import 'package:flutter/material.dart';

class WalletModel {
  final String id;
  final String name;
  final double initialBalance;
  final String currency;
  final int iconCode;
  final int colorValue;
  final DateTime? createdAt;

  const WalletModel({
    required this.id,
    required this.name,
    this.initialBalance = 0.0,
    this.currency = 'DZD',
    required this.iconCode,
    required this.colorValue,
    this.createdAt,
  });

  static const List<String> supportedCurrencies = ['DZD', 'USD', 'EUR'];

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
      case 0xf05e0:
        return Icons.wallet_rounded;
      case 0xe318:
        return Icons.inventory_2_rounded;
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
      'currency': currency,
      'iconCode': iconCode,
      'colorValue': colorValue,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory WalletModel.fromMap(Map<String, dynamic> map) {
    return WalletModel(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'مساحة مالية',
      initialBalance: (map['initialBalance'] as num?)?.toDouble() ?? 0.0,
      currency: (map['currency'] as String?)?.trim().toUpperCase() ?? 'DZD',
      iconCode: map['iconCode'] as int? ?? 0xe040,
      colorValue: map['colorValue'] as int? ?? 0xFF0D9488,
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt'] as String) : null,
    );
  }

  WalletModel copyWith({
    String? id,
    String? name,
    double? initialBalance,
    String? currency,
    int? iconCode,
    int? colorValue,
    DateTime? createdAt,
  }) {
    return WalletModel(
      id: id ?? this.id,
      name: name ?? this.name,
      initialBalance: initialBalance ?? this.initialBalance,
      currency: currency ?? this.currency,
      iconCode: iconCode ?? this.iconCode,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static List<WalletModel> get defaultWallets => [
        WalletModel(
          id: 'cash',
          name: 'نقداً (كاش)',
          initialBalance: 0.0,
          currency: 'DZD',
          iconCode: 0xe040, // payments_rounded
          colorValue: 0xFF10B981, // Emerald green
          createdAt: DateTime.now(),
        ),
        WalletModel(
          id: 'baridimob',
          name: 'بريدي موب (CCP)',
          initialBalance: 0.0,
          currency: 'DZD',
          iconCode: 0xe048, // credit_card_rounded
          colorValue: 0xFFF59E0B, // Amber gold
          createdAt: DateTime.now(),
        ),
        WalletModel(
          id: 'bank',
          name: 'حساب بنكي',
          initialBalance: 0.0,
          currency: 'DZD',
          iconCode: 0xe000, // account_balance_rounded
          colorValue: 0xFF3B82F6, // Blue
          createdAt: DateTime.now(),
        ),
      ];
}
