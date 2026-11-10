import 'package:flutter_test/flutter_test.dart';
import 'package:kredi/models/debt_model.dart';
import 'package:kredi/utils/formatters.dart';

void main() {
  group('Debt Model Tests', () {
    test('Debt initialization and default values', () {
      final debt = Debt(
        id: '123',
        personName: 'محمد',
        amount: 2500,
        date: DateTime(2026, 10, 5),
      );

      expect(debt.id, '123');
      expect(debt.personName, 'محمد');
      expect(debt.amount, 2500);
      expect(debt.isPaid, false);
      expect(debt.note, null);
    });

    test('Debt JSON serialization and deserialization', () {
      final debt = Debt(
        id: '123_456',
        personName: 'علي',
        amount: 12500,
        note: 'ثمن جهاز هاتف',
        date: DateTime(2026, 10, 5),
        isPaid: true,
      );

      final map = debt.toMap();
      final restored = Debt.fromMap(map);

      expect(restored.id, debt.id);
      expect(restored.personName, debt.personName);
      expect(restored.amount, debt.amount);
      expect(restored.note, debt.note);
      expect(restored.isPaid, true);
    });
  });

  group('Formatters Tests', () {
    test('formatAmount adds DZD currency suffix', () {
      final formatted = Formatters.formatAmount(2000);
      expect(formatted.contains('د.ج') || formatted.contains('دج'), true);
    });
  });
}
