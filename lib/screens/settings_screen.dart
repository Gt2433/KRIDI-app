import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/finance_service.dart';
import '../services/security_service.dart';
import '../services/settings_service.dart';
import '../services/update_service.dart';
import '../utils/app_strings.dart';
import '../widgets/ambient_background.dart';
import '../widgets/brand_icons.dart';
import '../widgets/face_scanner_dialog.dart';
import '../widgets/glass_container.dart';
import 'categories_screen.dart';
import 'wallets_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _launchUrl(String urlString) async {
    final Uri uri = Uri.parse(urlString);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // Fallback
    }
  }

  Future<void> _launchWhatsApp(String phone) async {
    final String cleanPhone = phone.replaceAll(' ', '');
    final String formatted = cleanPhone.startsWith('0')
        ? '213${cleanPhone.substring(1)}'
        : cleanPhone;
    final Uri uri = Uri.parse('https://wa.me/$formatted');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // Fallback
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri uri = Uri(scheme: 'mailto', path: email);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // Fallback
    }
  }

  void _showCurrencyBottomSheet(BuildContext context) {
    final currentCurrency = SettingsService.currencyNotifier.value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderCol = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB);
    final textCol = isDark ? Colors.white : Colors.black;
    final dividerCol = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFF3F4F6);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(80),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: borderCol,
                width: 1.2,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: borderCol,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'اختر عملة الحساب',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textCol),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: SettingsService.availableCurrencies.length,
                  separatorBuilder: (_, _) => Divider(height: 1, color: dividerCol),
                  itemBuilder: (context, index) {
                    final curr = SettingsService.availableCurrencies[index];
                    final isSelected = curr['symbol'] == currentCurrency;
                    return ListTile(
                      title: Text(curr['name']!, style: TextStyle(fontWeight: FontWeight.w600, color: textCol)),
                      trailing: Text(
                        curr['symbol']!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? (isDark ? Colors.white : Colors.black) : Colors.grey,
                        ),
                      ),
                      leading: isSelected
                          ? Icon(Icons.check_circle_rounded, color: isDark ? Colors.white : Colors.black)
                          : const SizedBox(width: 24),
                      onTap: () {
                        SettingsService.setCurrency(curr['symbol']!);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPinDialog(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    final controller = TextEditingController();
    final isAlreadyEnabled = SettingsService.pinEnabledNotifier.value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderCol = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB);
    final textCol = isDark ? Colors.white : Colors.black;

    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(80),
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: borderCol,
            width: 1.2,
          ),
        ),
        title: Text(isAlreadyEnabled ? 'رمز PIN' : 'تعيين رمز PIN', style: TextStyle(color: textCol, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAlreadyEnabled
                  ? 'التطبيق مقفل حالياً برمز. هل ترغب بإلغائه أو كتابة رمز جديد؟'
                  : 'أدخل 4 أرقام لحماية التطبيق برمز سري عند كل فتح:',
              style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFFA1A1AA) : Colors.grey),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              autofocus: true,
              style: TextStyle(color: textCol),
              onSubmitted: (val) async {
                final pin = val.trim();
                if (pin.length != 4) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('يرجى إدخال 4 أرقام')),
                  );
                  return;
                }
                Navigator.pop(ctx);
                await SettingsService.setPin(pin);
                messenger.showSnackBar(
                  const SnackBar(content: Text('تم تفعيل رمز PIN بنجاح 🔒')),
                );
              },
              decoration: const InputDecoration(
                hintText: '••••',
                labelText: 'رمز PIN الجديد',
              ),
            ),
          ],
        ),
        actions: [
          if (isAlreadyEnabled)
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await SettingsService.removePin();
                messenger.showSnackBar(
                  const SnackBar(content: Text('تم إلغاء رمز PIN وتعطيل خيارات الأمان')),
                );
              },
              child: const Text('إلغاء القفل', style: TextStyle(color: Color(0xFFDC2626))),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: TextStyle(color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () async {
              final pin = controller.text.trim();
              if (pin.length != 4) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('يرجى إدخال 4 أرقام')),
                );
                return;
              }
              Navigator.pop(ctx);
              await SettingsService.setPin(pin);
              messenger.showSnackBar(
                const SnackBar(content: Text('تم تفعيل رمز PIN بنجاح 🔒')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white : Colors.black,
              foregroundColor: isDark ? Colors.black : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _promptPinRequired(BuildContext context, String featureName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderCol = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB);
    final textCol = isDark ? Colors.white : Colors.black;

    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(80),
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: borderCol, width: 1.2),
        ),
        title: Row(
          children: [
            Icon(Icons.shield_outlined, color: textCol, size: 24),
            const SizedBox(width: 8),
            Text('رمز PIN مطلوب أولاً', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textCol)),
          ],
        ),
        content: Text(
          'لا يمكن تفعيل $featureName بدون تعيين رمز PIN أولاً. يعتبر رمز PIN هو وسيلة الأمان الأساسية والبديلة دائماً.',
          style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF4B5563), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: TextStyle(color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white : Colors.black,
              foregroundColor: isDark ? Colors.black : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Future.microtask(() {
                if (context.mounted) {
                  _showPinDialog(context);
                }
              });
            },
            child: const Text('تعيين رمز PIN الآن'),
          ),
        ],
      ),
    );
  }

  void _exportReport(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('جارٍ تصدير تقرير Excel / CSV...')),
    );
    final path = await FinanceService.instance.exportCsvReport();
    if (path != null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('تم تصدير التقرير وفتحه بنجاح! 📊')),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ أثناء تصدير التقرير'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showLanguageBottomSheet(BuildContext context, String currentLangCode) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderCol = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB);
    final textCol = isDark ? Colors.white : Colors.black;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(80),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: borderCol,
                width: 1.2,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: borderCol,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.tr(context, 'select_language'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textCol),
              ),
              const SizedBox(height: 16),
              _buildBottomSheetOption(
                context,
                title: AppStrings.tr(context, 'language_arabic'),
                isSelected: currentLangCode == 'ar',
                isDark: isDark,
                onTap: () {
                  SettingsService.setLocale(const Locale('ar'));
                  Navigator.of(context).pop();
                },
              ),
              _buildBottomSheetOption(
                context,
                title: AppStrings.tr(context, 'language_french'),
                isSelected: currentLangCode == 'fr',
                isDark: isDark,
                onTap: () {
                  SettingsService.setLocale(const Locale('fr'));
                  Navigator.of(context).pop();
                },
              ),
              _buildBottomSheetOption(
                context,
                title: AppStrings.tr(context, 'language_english'),
                isSelected: currentLangCode == 'en',
                isDark: isDark,
                onTap: () {
                  SettingsService.setLocale(const Locale('en'));
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomSheetOption(
    BuildContext context, {
    required String title,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final activeTextCol = isDark ? Colors.white : Colors.black;
    final inactiveTextCol = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF4B5563);

    return Material(
      color: Colors.transparent,
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? activeTextCol : inactiveTextCol,
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        trailing: isSelected
            ? Icon(
                Icons.check_circle_rounded,
                color: activeTextCol,
                size: 22,
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  String _getLanguageText(BuildContext context, String code) {
    switch (code) {
      case 'fr':
        return AppStrings.tr(context, 'language_french');
      case 'en':
        return AppStrings.tr(context, 'language_english');
      case 'ar':
      default:
        return AppStrings.tr(context, 'language_arabic');
    }
  }

  void _showDeveloperProfileBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderCol = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB);
    final textCol = isDark ? Colors.white : Colors.black;
    final chipBg = isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(80),
      builder: (context) {
        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: borderCol,
                width: 1.2,
              ),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    SizedBox(
                      height: 160,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            'cover.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.black,
                              );
                            },
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.black.withAlpha(60), Colors.black.withAlpha(10), Colors.transparent],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Material(
                        color: Colors.black.withAlpha(120),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => Navigator.of(context).pop(),
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.close_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -46,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: sheetBg,
                          shape: BoxShape.circle,
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                        ),
                        child: ClipOval(
                          child: SizedBox(
                            width: 88,
                            height: 88,
                            child: Image.asset(
                              'profile.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.black,
                                  child: const Center(
                                    child: Text('MB', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 54),
                Text(
                  AppStrings.tr(context, 'developer_name'),
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textCol),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: chipBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderCol),
                  ),
                  child: Text(
                    AppStrings.tr(context, 'developer_title'),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textCol),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showContactUsBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderCol = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB);
    final textCol = isDark ? Colors.white : Colors.black;
    final subTextCol = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(80),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: borderCol,
                width: 1.2,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: borderCol,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.tr(context, 'contact_dialog_title'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textCol),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.chat_rounded, color: Color(0xFF25D366)),
                title: Text('واتساب (WhatsApp)', style: TextStyle(color: textCol)),
                subtitle: Text('0655603829', style: TextStyle(color: subTextCol)),
                onTap: () => _launchWhatsApp('0655603829'),
              ),
              ListTile(
                leading: const Icon(Icons.email_outlined, color: Colors.red),
                title: Text('البريد الإلكتروني', style: TextStyle(color: textCol)),
                subtitle: Text('hhcgjvhcnk1@gmail.com', style: TextStyle(color: subTextCol)),
                onTap: () => _launchEmail('hhcgjvhcnk1@gmail.com'),
              ),
              ListTile(
                leading: const InstagramIcon(size: 22),
                title: Text('Instagram', style: TextStyle(color: textCol)),
                subtitle: Text('@moh_bah_dev', style: TextStyle(color: subTextCol)),
                onTap: () => _launchUrl('https://www.instagram.com/moh_bah_dev/'),
              ),
              ListTile(
                leading: TikTokIcon(size: 22, color: textCol),
                title: Text('TikTok', style: TextStyle(color: textCol)),
                subtitle: Text('@mbd_dev1', style: TextStyle(color: subTextCol)),
                onTap: () => _launchUrl('https://www.tiktok.com/@mbd_dev1'),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? Colors.white : Colors.black;
    final dividerCol = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFF3F4F6);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        iconTheme: IconThemeData(color: textCol),
        title: Text(
          AppStrings.tr(context, 'settings_title'),
          style: TextStyle(color: textCol, fontWeight: FontWeight.bold),
        ),
      ),
      body: AmbientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SECTION 1: المالية
                _buildSectionTitle(context, 'المالية'),
                const SizedBox(height: 10),
                GlassContainer(
                  padding: EdgeInsets.zero,
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    children: [
                      // Currency
                      ValueListenableBuilder<String>(
                        valueListenable: SettingsService.currencyNotifier,
                        builder: (context, curr, _) {
                          return _buildSettingTile(
                            context,
                            icon: Icons.monetization_on_outlined,
                            title: 'العملة',
                            subtitle: curr,
                            onTap: () => _showCurrencyBottomSheet(context),
                          );
                        },
                      ),
                      Divider(height: 1, indent: 56, endIndent: 16, color: dividerCol),

                      // Wallets Management
                      _buildSettingTile(
                        context,
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'المحافظ',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const WalletsScreen()),
                          );
                        },
                      ),
                      Divider(height: 1, indent: 56, endIndent: 16, color: dividerCol),

                      // Categories Management
                      _buildSettingTile(
                        context,
                        icon: Icons.category_outlined,
                        title: 'التصنيفات',
                        subtitle: 'إدارة تصنيفات المصاريف والمداخيل',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                          );
                        },
                      ),
                      Divider(height: 1, indent: 56, endIndent: 16, color: dividerCol),

                      // Export to Excel / CSV
                      _buildSettingTile(
                        context,
                        icon: Icons.table_chart_outlined,
                        title: 'تصدير البيانات',
                        subtitle: 'Excel / CSV',
                        onTap: () => _exportReport(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // SECTION 2: الأمان (Security & Codes)
                _buildSectionTitle(context, 'الأمان'),
                const SizedBox(height: 10),
                GlassContainer(
                  padding: EdgeInsets.zero,
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    children: [
                      // Security PIN Lock
                      ValueListenableBuilder<bool>(
                        valueListenable: SettingsService.pinEnabledNotifier,
                        builder: (context, pinEnabled, _) {
                          return _buildSettingTile(
                            context,
                            icon: Icons.lock_outline_rounded,
                            title: 'رمز PIN',
                            subtitle: pinEnabled ? 'مفعّل 🔒' : 'معطل',
                            onTap: () => _showPinDialog(context),
                          );
                        },
                      ),
                      Divider(height: 1, indent: 56, endIndent: 16, color: dividerCol),

                      // Face Unlock (سكان وإضافة وجهك بالكاميرا)
                      ValueListenableBuilder<bool>(
                        valueListenable: SettingsService.pinEnabledNotifier,
                        builder: (context, pinEnabled, _) {
                          return ValueListenableBuilder<bool>(
                            valueListenable: SettingsService.faceEnrolledNotifier,
                            builder: (context, isEnrolled, _) {
                              final subtitle = !pinEnabled
                                  ? 'يتطلب رمز PIN أولاً'
                                  : (isEnrolled ? 'تم تسجيل الوجه ✓' : 'إضافة وجهك (مسح الكاميرا)');
                              return _buildSettingTile(
                                context,
                                icon: Icons.face_unlock_rounded,
                                title: 'بصمة الوجه',
                                subtitle: subtitle,
                                onTap: () async {
                                  if (!SettingsService.hasPin) {
                                    _promptPinRequired(context, 'بصمة الوجه');
                                    return;
                                  }
                                  final enrolled = await FaceScannerDialog.show(
                                    context,
                                    mode: FaceScannerMode.enroll,
                                  );
                                  if (enrolled == true && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('تمت إضافة بصمة وجهك بنجاح بالكاميرا! ✓'),
                                        backgroundColor: Color(0xFF16A34A),
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                          );
                        },
                      ),
                      Divider(height: 1, indent: 56, endIndent: 16, color: dividerCol),

                      // Fingerprint
                      ValueListenableBuilder<bool>(
                        valueListenable: SettingsService.pinEnabledNotifier,
                        builder: (context, pinEnabled, _) {
                          return ValueListenableBuilder<bool>(
                            valueListenable: SettingsService.fingerprintEnabledNotifier,
                            builder: (context, fpEnabled, _) {
                              final subtitle = !pinEnabled
                                  ? 'يتطلب رمز PIN أولاً'
                                  : (fpEnabled ? 'مفعلة ✓' : 'معطلة');
                              return _buildSettingTile(
                                context,
                                icon: Icons.fingerprint_rounded,
                                title: 'بصمة الإصبع',
                                subtitle: subtitle,
                                onTap: () async {
                                  if (!SettingsService.hasPin) {
                                    _promptPinRequired(context, 'بصمة الإصبع');
                                    return;
                                  }
                                  if (fpEnabled) {
                                    await SettingsService.setFingerprintEnabled(false);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('تم تعطيل الدخول ببصمة الإصبع')),
                                      );
                                    }
                                  } else {
                                    final success = await SecurityService.authenticateWithBiometrics(
                                      reason: 'تأكيد بصمة الإصبع للتفعيل',
                                    );
                                    if (success) {
                                      await SettingsService.setFingerprintEnabled(true);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('تم تفعيل بصمة الإصبع بنجاح ✓'),
                                            backgroundColor: Color(0xFF16A34A),
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // SECTION 3: PREFERENCES (Theme & Language)
                _buildSectionTitle(context, AppStrings.tr(context, 'section_preferences')),
                const SizedBox(height: 10),
                GlassContainer(
                  padding: EdgeInsets.zero,
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    children: [
                      // Theme Switch (Dark / Light Mode)
                      ValueListenableBuilder<ThemeMode>(
                        valueListenable: SettingsService.themeModeNotifier,
                        builder: (context, themeMode, _) {
                          final isDarkMode = themeMode == ThemeMode.dark;
                          return _buildSettingTile(
                            context,
                            icon: isDarkMode ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                            title: 'المظهر',
                            subtitle: isDarkMode ? 'الوضع المظلم 🌙' : 'الوضع المضيء ☀️',
                            trailing: Switch.adaptive(
                              value: isDarkMode,
                              activeThumbColor: Colors.white,
                              activeTrackColor: const Color(0xFF3B82F6),
                              onChanged: (val) {
                                SettingsService.setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
                              },
                            ),
                            onTap: () {
                              SettingsService.toggleThemeMode();
                            },
                          );
                        },
                      ),
                      Divider(height: 1, indent: 56, endIndent: 16, color: dividerCol),

                      // Language
                      ValueListenableBuilder<Locale>(
                        valueListenable: SettingsService.localeNotifier,
                        builder: (context, currentLocale, _) {
                          return _buildSettingTile(
                            context,
                            icon: Icons.language_rounded,
                            title: AppStrings.tr(context, 'language'),
                            subtitle: _getLanguageText(context, currentLocale.languageCode),
                            onTap: () => _showLanguageBottomSheet(context, currentLocale.languageCode),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // SECTION 4: ABOUT KREDI
                _buildSectionTitle(context, AppStrings.tr(context, 'section_about')),
                const SizedBox(height: 10),
                GlassContainer(
                  padding: const EdgeInsets.all(18),
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.account_balance_wallet_outlined,
                              color: textCol,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'أموالي',
                                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textCol),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'الإصدار 2.0',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Divider(height: 1, color: dividerCol),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => UpdateService.checkForUpdate(context, isManualCheck: true),
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          child: Row(
                            children: [
                              Icon(Icons.sync_rounded, size: 18, color: textCol),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'فحص التحديثات',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textCol),
                                ),
                              ),
                              const Icon(Icons.chevron_left_rounded, size: 18, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // SECTION 5: DEVELOPER & CONTACT
                _buildSectionTitle(context, AppStrings.tr(context, 'section_developer')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: GlassContainer(
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                        borderRadius: BorderRadius.circular(22),
                        onTap: () => _showDeveloperProfileBottomSheet(context),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.person_rounded, color: textCol, size: 26),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              AppStrings.tr(context, 'developer_button'),
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textCol),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GlassContainer(
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                        borderRadius: BorderRadius.circular(22),
                        onTap: () => _showContactUsBottomSheet(context),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.headset_mic_rounded, color: textCol, size: 26),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              AppStrings.tr(context, 'contact_us_button'),
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textCol),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Color(0xFF6B7280),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? Colors.white : Colors.black;
    final iconBg = isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6);
    final subTextCol = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: textCol, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textCol,
                ),
              ),
            ),
            if (subtitle != null && subtitle.isNotEmpty) ...[
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: subTextCol,
                ),
              ),
              const SizedBox(width: 6),
            ],
            if (trailing != null)
              trailing
            else
              Icon(
                Icons.chevron_left_rounded,
                size: 20,
                color: isDark ? const Color(0xFF71717A) : const Color(0xFF9CA3AF),
              ),
          ],
        ),
      ),
    );
  }
}
