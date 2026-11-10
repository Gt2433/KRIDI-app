import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/app_gate.dart';
import 'services/auth_service.dart';
import 'services/category_service.dart';
import 'services/finance_service.dart';
import 'services/settings_service.dart';
import 'services/sync_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AuthService.instance.init();
    await SyncService.instance.sync();
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }
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
          home: const AppGate(),
        );
      },
    );
  }
}
