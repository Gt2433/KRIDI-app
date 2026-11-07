enum DebtType { fromMe, toMe } // fromMe = دين عليّ (أنا مدين), toMe = دين لي (الآخر مدين لي)

class DebtVersement {
  final String id;
  final double amount;
  final DateTime date;
  final String? note;

  const DebtVersement({
    required this.id,
    required this.amount,
    required this.date,
    this.note,
  });

  static String generateId() {
    return 'vers_${DateTime.now().millisecondsSinceEpoch}_${(100 + (DateTime.now().microsecond % 900))}';
  }

  DebtVersement copyWith({
    String? id,
    double? amount,
    DateTime? date,
    String? note,
  }) {
    return DebtVersement(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory DebtVersement.fromMap(Map<String, dynamic> map) {
    return DebtVersement(
      id: map['id'] as String? ?? generateId(),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: map['date'] != null
          ? DateTime.parse(map['date'] as String)
          : DateTime.now(),
      note: map['note'] as String?,
    );
  }
}

class Debt {
  final String id;
  final String personName;
  final double amount;
  final String? note;
  final DateTime date;
  final bool isPaid;
  final DebtType type;
  final String? phoneNumber;
  final List<DebtVersement> versements;

  const Debt({
    required this.id,
    required this.personName,
    required this.amount,
    this.note,
    required this.date,
    this.isPaid = false,
    this.type = DebtType.fromMe,
    this.phoneNumber,
    this.versements = const [],
  });

  /// Total sum of all versements / payments made
  double get totalPaid {
    if (versements.isEmpty && isPaid) {
      return amount;
    }
    return versements.fold<double>(0.0, (sum, v) => sum + v.amount);
  }

  /// Remaining amount of debt
  double get remainingAmount {
    if (isPaid && versements.isEmpty) return 0.0;
    final rem = amount - totalPaid;
    return rem < 0.001 ? 0.0 : rem;
  }

  /// Has the debt been settled completely?
  bool get isFullyPaid => isPaid || remainingAmount <= 0.001;

  /// Has partial payment (versement) been made?
  bool get isPartiallyPaid => totalPaid > 0 && remainingAmount > 0.001;

  /// Generate a unique ID using timestamp and fallback randomizer
  static String generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${(100 + (DateTime.now().microsecond % 900))}';
  }

  Debt copyWith({
    String? id,
    String? personName,
    double? amount,
    String? note,
    DateTime? date,
    bool? isPaid,
    DebtType? type,
    String? phoneNumber,
    List<DebtVersement>? versements,
  }) {
    return Debt(
      id: id ?? this.id,
      personName: personName ?? this.personName,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      date: date ?? this.date,
      isPaid: isPaid ?? this.isPaid,
      type: type ?? this.type,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      versements: versements ?? this.versements,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'personName': personName,
      'amount': amount,
      'note': note,
      'date': date.toIso8601String(),
      'isPaid': isPaid,
      'type': type.name,
      'phoneNumber': phoneNumber,
      'versements': versements.map((v) => v.toMap()).toList(),
    };
  }

  factory Debt.fromMap(Map<String, dynamic> map) {
    final List<dynamic>? versList = map['versements'] as List<dynamic>?;
    final versements = versList != null
        ? versList
            .map((item) => DebtVersement.fromMap(Map<String, dynamic>.from(item as Map)))
            .toList()
        : <DebtVersement>[];

    final bool legacyIsPaid = map['isPaid'] as bool? ?? false;
    final double amount = (map['amount'] as num?)?.toDouble() ?? 0.0;
    final double paidSum = versements.fold<double>(0.0, (sum, v) => sum + v.amount);
    final bool isNowPaid = legacyIsPaid || (versements.isNotEmpty && paidSum >= amount);

    return Debt(
      id: map['id'] as String,
      personName: map['personName'] as String? ?? '',
      amount: amount,
      note: map['note'] as String?,
      date: map['date'] != null
          ? DateTime.parse(map['date'] as String)
          : DateTime.now(),
      isPaid: isNowPaid,
      type: map['type'] == 'toMe' ? DebtType.toMe : DebtType.fromMe,
      phoneNumber: map['phoneNumber'] as String?,
      versements: versements,
    );
  }
}
