import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kredi/main.dart';

void main() {
  testWidgets('Kredi app renders title after loading', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const KrediApp());
    await tester.pumpAndSettle();
    expect(find.text('كريدي'), findsOneWidget);
    expect(find.text('إجمالي ما عليك'), findsOneWidget);
  });
}
