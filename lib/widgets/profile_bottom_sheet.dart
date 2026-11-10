import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../screens/app_gate.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import 'bouncing_button.dart';
import 'user_avatar.dart';

class ProfileBottomSheet extends StatelessWidget {
  final User user;

  const ProfileBottomSheet({super.key, required this.user});

  static Future<void> show(BuildContext context, User user) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(90),
      builder: (_) => ProfileBottomSheet(user: user),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderCol = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB);
    final textCol = isDark ? Colors.white : Colors.black;
    final subTextCol = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);
    final cardBg = isDark ? const Color(0xFF27272A) : const Color(0xFFF9FAFB);

    final displayName = user.displayName?.isNotEmpty == true
        ? user.displayName!
        : (user.email?.split('@').first ?? 'مستخدم كريدي');

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(color: borderCol, width: 1.2),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: SafeArea(
        top: false,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          builder: (context, val, child) {
            return Opacity(
              opacity: val,
              child: Transform.translate(
                offset: Offset(0, (1 - val) * 14),
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // Handle bar
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: borderCol,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 22),

            // User Avatar (Interactive with picker)
            UserAvatar(
              size: 80,
              photoUrl: user.photoURL,
              name: displayName,
              showEditBadge: true,
              onTap: () async {
                final chosen = await UserAvatar.showAvatarPicker(
                  context,
                  currentAvatar: user.photoURL,
                );
                if (chosen != null && chosen.isNotEmpty) {
                  await AuthService.instance.updateProfile(photoURL: chosen);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                }
              },
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final chosen = await UserAvatar.showAvatarPicker(
                  context,
                  currentAvatar: user.photoURL,
                );
                if (chosen != null && chosen.isNotEmpty) {
                  await AuthService.instance.updateProfile(photoURL: chosen);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                }
              },
              child: const Text(
                'تغيير الشخصية الرمزية',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Name & Email
            Text(
              displayName,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: textCol,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_done_rounded, size: 15, color: Color(0xFF16A34A)),
                const SizedBox(width: 5),
                Text(
                  user.email ?? '',
                  style: TextStyle(fontSize: 13, color: subTextCol),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // Cloud Status & Sync Action Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderCol, width: 1.2),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.cloud_sync_rounded, color: Color(0xFF16A34A), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'المزامنة السحابية نشطة',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: textCol,
                              ),
                            ),
                            const SizedBox(height: 2),
                            ValueListenableBuilder<bool>(
                              valueListenable: SyncService.isSyncingNotifier,
                              builder: (context, isSyncing, _) {
                                return Text(
                                  isSyncing ? 'جارٍ رفع وتحديث بياناتك...' : 'تم حفظ كافة بياناتك وإعداداتك بأمان',
                                  style: TextStyle(fontSize: 12, color: subTextCol),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ValueListenableBuilder<bool>(
                    valueListenable: SyncService.isSyncingNotifier,
                    builder: (context, isSyncing, _) {
                      return SizedBox(
                        width: double.infinity,
                        child: BouncingButton(
                          scaleFactor: 0.96,
                          child: ElevatedButton.icon(
                            onPressed: isSyncing
                                ? null
                                : () async {
                                    final ok = await SyncService.instance.uploadToCloud();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(ok
                                              ? 'تمت مزامنة كافة البيانات والإعدادات مع السحابة بنجاح! ☁️'
                                              : 'حدث خطأ أثناء المزامنة'),
                                          backgroundColor: ok ? const Color(0xFF16A34A) : Colors.red,
                                        ),
                                      );
                                    }
                                  },
                            icon: isSyncing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.sync_rounded, size: 18),
                            label: Text(isSyncing ? 'جارٍ المزامنة...' : 'مزامنة الآن'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? Colors.white : Colors.black,
                              foregroundColor: isDark ? Colors.black : Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: sheetBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: borderCol),
                      ),
                      title: Text(
                        'تسجيل الخروج',
                        style: TextStyle(fontWeight: FontWeight.bold, color: textCol),
                      ),
                      content: Text(
                        'هل أنت متأكد من رغبتك في تسجيل الخروج؟ بياناتك ستظل محفوظة على جهازك وفي حسابك السحابي.',
                        style: TextStyle(color: subTextCol, height: 1.5),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text('إلغاء', style: TextStyle(color: subTextCol)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('تسجيل الخروج'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    if (context.mounted) {
                      Navigator.pop(context); // Close bottom sheet
                    }
                    AppGate.guestSessionActive = false;
                    await AuthService.instance.signOut();
                  }
                },
                icon: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 18),
                label: const Text(
                  'تسجيل الخروج',
                  style: TextStyle(
                    color: Color(0xFFDC2626),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: const Color(0xFFDC2626).withAlpha(50), width: 1.2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    ),
  );
}
}

