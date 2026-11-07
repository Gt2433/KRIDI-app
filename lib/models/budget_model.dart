class BudgetModel {
  final String categoryId;
  final double limitAmount;
  final String monthKey; // e.g. "2026-11"

  const BudgetModel({
    required this.categoryId,
    required this.limitAmount,
    required this.monthKey,
  });

  Map<String, dynamic> toMap() {
    return {
      'categoryId': categoryId,
      'limitAmount': limitAmount,
      'monthKey': monthKey,
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      categoryId: map['categoryId'] as String,
      limitAmount: (map['limitAmount'] as num?)?.toDouble() ?? 0.0,
      monthKey: map['monthKey'] as String? ?? '',
    );
  }
}

