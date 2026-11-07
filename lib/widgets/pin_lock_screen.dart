import 'package:flutter/material.dart';
import '../services/security_service.dart';
import '../services/settings_service.dart';
import 'face_scanner_dialog.dart';

class PinLockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;

  const PinLockScreen({super.key, required this.onUnlocked});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  String _enteredPin = '';
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    // Do not auto-launch biometrics; directly show the PIN keypad screen.
  }

  void _onFaceUnlockTap() async {
    final success = await FaceScannerDialog.show(context, mode: FaceScannerMode.unlock);
    if (success == true && mounted) {
      SettingsService.isUnlockedThisSession = true;
      widget.onUnlocked();
    }
  }

  void _onFingerprintTap() async {
    final success = await SecurityService.authenticateWithBiometrics(
      reason: 'يرجى وضع بصمة الإصبع لفتح التطبيق',
    );
    if (success && mounted) {
      SettingsService.isUnlockedThisSession = true;
      widget.onUnlocked();
    }
  }

  void _onDigitPressed(String digit) {
    if (_enteredPin.length < 4) {
      setState(() {
        _isError = false;
        _enteredPin += digit;
      });

      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _isError = false;
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  void _verifyPin() {
    if (SettingsService.checkPin(_enteredPin)) {
      SettingsService.isUnlockedThisSession = true;
      widget.onUnlocked();
    } else {
      setState(() {
        _isError = true;
        _enteredPin = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('رمز PIN غير صحيح، حاول مجدداً'),
          backgroundColor: Color(0xFFDC2626),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCol = isDark ? const Color(0xFF121212) : Colors.white;
    final textCol = isDark ? Colors.white : Colors.black;
    final subTextCol = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);
    final keyBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF9FAFB);
    final keyBorder = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB);
    final iconCircleBg = isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6);

    return Scaffold(
      backgroundColor: bgCol,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: iconCircleBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock_outline_rounded, size: 40, color: textCol),
              ),
              const SizedBox(height: 16),
              Text(
                'تطبيق أموالي محمي',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textCol),
              ),
              const SizedBox(height: 6),
              Text(
                'أدخل رمز PIN أو اختر وسيلة الدخول:',
                style: TextStyle(fontSize: 13, color: subTextCol),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Face & Fingerprint buttons (only shown if configured)
              Builder(
                builder: (context) {
                  final hasFace = SettingsService.faceEnrolledNotifier.value &&
                      SettingsService.faceAuthEnabledNotifier.value;
                  final hasFingerprint = SettingsService.fingerprintEnabledNotifier.value;

                  if (!hasFace && !hasFingerprint) {
                    return const SizedBox(height: 12);
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (hasFace)
                          InkWell(
                            onTap: _onFaceUnlockTap,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: keyBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: keyBorder),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.face_unlock_rounded, size: 20, color: textCol),
                                  const SizedBox(width: 8),
                                  Text(
                                    'بصمة الوجه',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: textCol,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (hasFace && hasFingerprint) const SizedBox(width: 12),
                        if (hasFingerprint)
                          InkWell(
                            onTap: _onFingerprintTap,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: keyBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: keyBorder),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.fingerprint_rounded, size: 20, color: textCol),
                                  const SizedBox(width: 8),
                                  Text(
                                    'بصمة الإصبع',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: textCol,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // PIN Indicator Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < _enteredPin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled
                          ? (_isError ? const Color(0xFFDC2626) : textCol)
                          : (isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB)),
                    ),
                  );
                }),
              ),
              const Spacer(),

              // Numeric Keypad
              _buildKeypad(isDark, textCol, keyBg, keyBorder, iconCircleBg),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad(bool isDark, Color textCol, Color keyBg, Color keyBorder, Color iconCircleBg) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['1', '2', '3'].map((d) => _buildKey(d, textCol, keyBg, keyBorder)).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['4', '5', '6'].map((d) => _buildKey(d, textCol, keyBg, keyBorder)).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['7', '8', '9'].map((d) => _buildKey(d, textCol, keyBg, keyBorder)).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Face or Fingerprint shortcut icon (if enabled)
            Builder(
              builder: (context) {
                final hasFace = SettingsService.faceEnrolledNotifier.value &&
                    SettingsService.faceAuthEnabledNotifier.value;
                final hasFingerprint = SettingsService.fingerprintEnabledNotifier.value;

                if (hasFace) {
                  return InkWell(
                    onTap: _onFaceUnlockTap,
                    borderRadius: BorderRadius.circular(36),
                    child: Container(
                      width: 72,
                      height: 72,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: iconCircleBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.face_unlock_rounded, size: 28, color: textCol),
                    ),
                  );
                } else if (hasFingerprint) {
                  return InkWell(
                    onTap: _onFingerprintTap,
                    borderRadius: BorderRadius.circular(36),
                    child: Container(
                      width: 72,
                      height: 72,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: iconCircleBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.fingerprint_rounded, size: 28, color: textCol),
                    ),
                  );
                }
                return const SizedBox(width: 72, height: 72);
              },
            ),
            _buildKey('0', textCol, keyBg, keyBorder),
            // Backspace button
            InkWell(
              onTap: _onBackspace,
              borderRadius: BorderRadius.circular(36),
              child: Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                child: Icon(Icons.backspace_outlined, size: 24, color: textCol),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKey(String digit, Color textCol, Color keyBg, Color keyBorder) {
    return InkWell(
      onTap: () => _onDigitPressed(digit),
      borderRadius: BorderRadius.circular(36),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: keyBg,
          shape: BoxShape.circle,
          border: Border.all(color: keyBorder, width: 1.2),
        ),
        alignment: Alignment.center,
        child: Text(
          digit,
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textCol),
        ),
      ),
    );
  }
}
