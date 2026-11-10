import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sync_service.dart';

class SettingsService {
  static const String _keyThemeMode = 'kredi_theme_mode';
  static const String _keyLocale = 'kredi_locale';
  static const String _keyCurrency = 'kredi_currency';
  static const String _keyHideBalance = 'kredi_hide_balance';
  static const String _keyPinCode = 'kredi_security_pin';
  static const String _keyPinEnabled = 'kredi_pin_enabled';
  static const String _keyFingerprintEnabled = 'kredi_fingerprint_enabled';

  static ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.light);
  static ValueNotifier<Locale> localeNotifier = ValueNotifier(const Locale('ar'));
  static ValueNotifier<String> currencyNotifier = ValueNotifier('د.ج');
  static ValueNotifier<bool> hideBalanceNotifier = ValueNotifier(false);
  static ValueNotifier<bool> pinEnabledNotifier = ValueNotifier(false);
  static ValueNotifier<bool> fingerprintEnabledNotifier = ValueNotifier(false);

  static String _savedPin = '';
  static bool isUnlockedThisSession = false;

  static bool get hasPin => pinEnabledNotifier.value && _savedPin.isNotEmpty;

  static const List<Map<String, String>> availableCurrencies = [
    {'code': 'DZD', 'symbol': 'د.ج', 'name': 'دينار جزائري (DZD)'},
    {'code': 'SAR', 'symbol': 'ر.س', 'name': 'ريال سعودي (SAR)'},
    {'code': 'AED', 'symbol': 'د.إ', 'name': 'درهم إماراتي (AED)'},
    {'code': 'MAD', 'symbol': 'د.م', 'name': 'درهم مغربي (MAD)'},
    {'code': 'TND', 'symbol': 'د.ت', 'name': 'دينار تونسي (TND)'},
    {'code': 'EGP', 'symbol': 'ج.م', 'name': 'جنيه مصري (EGP)'},
    {'code': 'USD', 'symbol': '\$', 'name': 'دولار أمريكي (USD)'},
    {'code': 'EUR', 'symbol': '€', 'name': 'يورو (EUR)'},
  ];

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // Load Theme Mode
    final themeStr = prefs.getString(_keyThemeMode) ?? 'light';
    themeModeNotifier.value = themeStr == 'dark' ? ThemeMode.dark : ThemeMode.light;

    // Load Locale
    final langStr = prefs.getString(_keyLocale) ?? 'ar';
    localeNotifier.value = Locale(langStr);

    // Load Currency
    final currStr = prefs.getString(_keyCurrency) ?? 'د.ج';
    currencyNotifier.value = currStr;

    // Load Hide Balance
    final hideBal = prefs.getBool(_keyHideBalance) ?? false;
    hideBalanceNotifier.value = hideBal;

    // Load PIN
    _savedPin = prefs.getString(_keyPinCode) ?? '';
    final pinEnabled = prefs.getBool(_keyPinEnabled) ?? false;
    pinEnabledNotifier.value = pinEnabled && _savedPin.isNotEmpty;

    // Load Fingerprint settings (only valid if PIN is configured)
    if (pinEnabledNotifier.value) {
      fingerprintEnabledNotifier.value = prefs.getBool(_keyFingerprintEnabled) ?? false;
    } else {
      fingerprintEnabledNotifier.value = false;
      isUnlockedThisSession = true;
    }
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    themeModeNotifier.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, mode == ThemeMode.dark ? 'dark' : 'light');
    _notifySettingsChanged();
  }

  static Future<void> toggleThemeMode() async {
    final next = themeModeNotifier.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(next);
  }

  static Future<void> setLocale(Locale locale) async {
    localeNotifier.value = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLocale, locale.languageCode);
    _notifySettingsChanged();
  }

  static Future<void> setCurrency(String symbol) async {
    currencyNotifier.value = symbol;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrency, symbol);
    _notifySettingsChanged();
  }

  static Future<void> toggleHideBalance() async {
    final newVal = !hideBalanceNotifier.value;
    hideBalanceNotifier.value = newVal;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHideBalance, newVal);
    _notifySettingsChanged();
  }

  /// Export user settings into a JSON-serializable Map for cloud sync
  static Map<String, dynamic> exportSettingsMap() {
    return {
      'themeMode': themeModeNotifier.value == ThemeMode.dark ? 'dark' : 'light',
      'locale': localeNotifier.value.languageCode,
      'currency': currencyNotifier.value,
      'hideBalance': hideBalanceNotifier.value,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Import user settings from cloud map and apply to preferences and active state
  static Future<void> importSettingsMap(Map<String, dynamic> map) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (map['themeMode'] is String) {
        final themeStr = map['themeMode'] as String;
        themeModeNotifier.value = themeStr == 'dark' ? ThemeMode.dark : ThemeMode.light;
        await prefs.setString(_keyThemeMode, themeStr);
      }

      if (map['locale'] is String) {
        final langStr = map['locale'] as String;
        localeNotifier.value = Locale(langStr);
        await prefs.setString(_keyLocale, langStr);
      }

      if (map['currency'] is String) {
        final curr = map['currency'] as String;
        currencyNotifier.value = curr;
        await prefs.setString(_keyCurrency, curr);
      }

      if (map['hideBalance'] is bool) {
        final hide = map['hideBalance'] as bool;
        hideBalanceNotifier.value = hide;
        await prefs.setBool(_keyHideBalance, hide);
      }
    } catch (e) {
      debugPrint('Error importing settings map: $e');
    }
  }

  static void _notifySettingsChanged() {
    try {
      SyncService.instance.saveSettingsToCloud(exportSettingsMap());
    } catch (_) {}
  }

  static bool checkPin(String enteredPin) {
    return _savedPin == enteredPin;
  }

  static Future<void> setPin(String newPin) async {
    final prefs = await SharedPreferences.getInstance();
    if (newPin.isEmpty) {
      _savedPin = '';
      pinEnabledNotifier.value = false;
      await prefs.remove(_keyPinCode);
      await prefs.setBool(_keyPinEnabled, false);
      await setFingerprintEnabled(false);
      isUnlockedThisSession = true;
    } else {
      _savedPin = newPin;
      pinEnabledNotifier.value = true;
      await prefs.setString(_keyPinCode, newPin);
      await prefs.setBool(_keyPinEnabled, true);
      isUnlockedThisSession = true;
    }
  }

  static Future<void> removePin() async {
    await setPin('');
  }

  static Future<void> setFingerprintEnabled(bool val) async {
    fingerprintEnabledNotifier.value = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFingerprintEnabled, val);
  }
}
