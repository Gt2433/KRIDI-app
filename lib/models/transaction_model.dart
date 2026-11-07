enum TransactionType { expense, income, transfer }

class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final String walletId;
  final String? toWalletId;
  final DateTime date;
  final String? note;

  const TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.walletId,
    this.toWalletId,
    required this.date,
    this.note,
  });

  static String generateId() {
    return 'tx_${DateTime.now().millisecondsSinceEpoch}_${(100 + (DateTime.now().microsecond % 900))}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.name,
      'categoryId': categoryId,
      'walletId': walletId,
      'toWalletId': toWalletId,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      type: TransactionType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => TransactionType.expense,
      ),
      categoryId: map['categoryId'] as String? ?? 'other_exp',
      walletId: map['walletId'] as String? ?? 'cash',
      toWalletId: map['toWalletId'] as String?,
      date: map['date'] != null ? DateTime.parse(map['date'] as String) : DateTime.now(),
      note: map['note'] as String?,
    );
  }

  TransactionModel copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    String? categoryId,
    String? walletId,
    String? toWalletId,
    DateTime? date,
    String? note,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      walletId: walletId ?? this.walletId,
      toWalletId: toWalletId ?? this.toWalletId,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }
}

