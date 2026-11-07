import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/main_nav_screen.dart';
import 'services/category_service.dart';
import 'services/finance_service.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsService.init();
  await CategoryService.init();
  await FinanceService.instance.init();
  runApp(const KrediApp());
}

class KrediApp extends StatelessWidget {
  const KrediApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        SettingsService.localeNotifier,
        SettingsService.themeModeNotifier,
      ]),
      builder: (context, _) {
        final currentLocale = SettingsService.localeNotifier.value;
        final currentThemeMode = SettingsService.themeModeNotifier.value;

        return MaterialApp(
          title: 'أموالي & كريدي',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentThemeMode,
          locale: currentLocale,
          supportedLocales: const [Locale('ar'), Locale('fr'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const MainNavScreen(),
        );
      },
    );
  }
}
