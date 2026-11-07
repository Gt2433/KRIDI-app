import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../services/settings_service.dart';
import '../widgets/reveal_balance_auth_sheet.dart';

class SecurityService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Check if the device has biometric hardware / device lock capabilities
  static Future<bool> canCheckBiometrics() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (_) {
      return false;
    }
  }

  /// Check available biometric types (e.g. face, fingerprint)
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Whether device has Face recognition enrolled/supported
  static Future<bool> hasFaceBiometrics() async {
    final list = await getAvailableBiometrics();
    return list.contains(BiometricType.face);
  }

  /// Request biometric authentication (Face ID / Fingerprint / Device Passcode)
  static Future<bool> authenticateWithBiometrics({
    String reason = 'تأكيد الهوية ببصمة الوجه أو الإصبع للكشف عن الرصيد',
    bool biometricOnly = true,
  }) async {
    try {
      final canAuth = await canCheckBiometrics();
      if (!canAuth) return false;

      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: biometricOnly,
        sensitiveTransaction: false, // Instant Face Unlock recognition without extra tap
        persistAcrossBackgrounding: true,
      );
    } on PlatformException catch (e) {
      debugPrint('Biometric auth error: $e');
      if (biometricOnly) {
        // Fallback to allow device credentials if biometricOnly failed
        return await authenticateWithBiometrics(
          reason: reason,
          biometricOnly: false,
        );
      }
      return false;
    } catch (e) {
      debugPrint('Biometric general error: $e');
      return false;
    }
  }

  /// Complete authentication flow to reveal balance:
  /// If no security is set, reveals immediately. Otherwise shows the PIN & Biometric sheet.
  static Future<bool> authenticateToReveal(BuildContext context) async {
    if (!context.mounted) return false;
    if (!SettingsService.hasPin) {
      return true;
    }
    final result = await RevealBalanceAuthSheet.show(context);
    return result == true;
  }
}
