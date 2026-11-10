import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kredi/main.dart';
import 'package:kredi/services/settings_service.dart';
import 'package:kredi/services/category_service.dart';
import 'package:kredi/services/finance_service.dart';

void main() {
  testWidgets('Kredi app renders title after loading', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.init();
    await CategoryService.init();
    await FinanceService.instance.init();

    await tester.pumpWidget(const KrediApp());
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('كريدي'), findsWidgets);
  });
}
