import 'package:flutter/material.dart';
import '../services/security_service.dart';
import '../services/settings_service.dart';

class RevealBalanceAuthSheet extends StatefulWidget {
  const RevealBalanceAuthSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(90),
      builder: (context) => const RevealBalanceAuthSheet(),
    );
  }

  @override
  State<RevealBalanceAuthSheet> createState() => _RevealBalanceAuthSheetState();
}

class _RevealBalanceAuthSheetState extends State<RevealBalanceAuthSheet> {
  String _enteredPin = '';
  bool _isError = false;
  late bool _hasConfiguredPin;

  @override
  void initState() {
    super.initState();
    _hasConfiguredPin = SettingsService.pinEnabledNotifier.value;
  }

  void _onDigitPressed(String digit) {
    if (_enteredPin.length < 4) {
      setState(() {
        _isError = false;
        _enteredPin += digit;
      });

      if (_enteredPin.length == 4) {
        _handlePinComplete();
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

  void _handlePinComplete() async {
    if (_hasConfiguredPin) {
      if (SettingsService.checkPin(_enteredPin)) {
        Navigator.pop(context, true);
      } else {
        setState(() {
          _isError = true;
          _enteredPin = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('رمز PIN غير صحيح، حاول ثانية'),
            backgroundColor: Color(0xFFDC2626),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      await SettingsService.setPin(_enteredPin);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ رمز PIN بنجاح 🔒')),
        );
        Navigator.pop(context, true);
      }
    }
  }

  void _onFingerprintTap() async {
    final success = await SecurityService.authenticateWithBiometrics(
      reason: 'يرجى وضع بصمة الإصبع للكشف عن الرصيد',
    );
    if (success && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCol = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textCol = isDark ? Colors.white : Colors.black;
    final subTextCol = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);
    final keyBg = isDark ? const Color(0xFF27272A) : const Color(0xFFF9FAFB);
    final keyBorder = isDark ? const Color(0xFF3F3F46) : const Color(0xFFE5E7EB);
    final iconCircleBg = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFF3F4F6);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: bgCol,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB),
            width: 1.2,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Icon + Title (Fingerprint)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconCircleBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.fingerprint_rounded, color: textCol, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  _hasConfiguredPin ? 'تأكيد الهوية' : 'تعيين PIN',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: textCol,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _hasConfiguredPin ? 'أدخل الرمز أو استخدم بصمة الإصبع:' : 'أدخل 4 أرقام لتعيين رمز PIN',
              style: TextStyle(fontSize: 12, color: subTextCol),
              textAlign: TextAlign.center,
            ),

            // Fingerprint button (if enabled)
            if (_hasConfiguredPin) ...[
              Builder(
                builder: (context) {
                  final hasFingerprint = SettingsService.fingerprintEnabledNotifier.value;

                  if (!hasFingerprint) {
                    return const SizedBox(height: 12);
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 14, bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: _onFingerprintTap,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: keyBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: keyBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.fingerprint_rounded, size: 18, color: textCol),
                                const SizedBox(width: 6),
                                Text(
                                  'بصمة الإصبع',
                                  style: TextStyle(
                                    fontSize: 12,
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
            ],

            const SizedBox(height: 18),

            // PIN Dots Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < _enteredPin.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled
                        ? (_isError ? const Color(0xFFDC2626) : textCol)
                        : (isDark ? const Color(0xFF3F3F46) : const Color(0xFFE5E7EB)),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

            // Numeric Keypad
            _buildKeypad(isDark, textCol, keyBg, keyBorder, iconCircleBg),
            const SizedBox(height: 10),
          ],
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
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['4', '5', '6'].map((d) => _buildKey(d, textCol, keyBg, keyBorder)).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['7', '8', '9'].map((d) => _buildKey(d, textCol, keyBg, keyBorder)).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Fingerprint shortcut button
            Builder(
              builder: (context) {
                final hasFingerprint = SettingsService.fingerprintEnabledNotifier.value;

                if (hasFingerprint) {
                  return InkWell(
                    onTap: _onFingerprintTap,
                    borderRadius: BorderRadius.circular(32),
                    child: Container(
                      width: 64,
                      height: 64,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: iconCircleBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.fingerprint_rounded, size: 26, color: textCol),
                    ),
                  );
                }
                return const SizedBox(width: 64, height: 64);
              },
            ),
            _buildKey('0', textCol, keyBg, keyBorder),
            // Backspace Button
            InkWell(
              onTap: _onBackspace,
              borderRadius: BorderRadius.circular(32),
              child: Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                child: Icon(Icons.backspace_outlined, size: 22, color: textCol),
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
      borderRadius: BorderRadius.circular(32),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: keyBg,
          shape: BoxShape.circle,
          border: Border.all(color: keyBorder, width: 1.2),
        ),
        alignment: Alignment.center,
        child: Text(
          digit,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textCol),
        ),
      ),
    );
  }
}
