import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class UpdateService {
  /// GitHub Releases / raw update JSON URL
  /// Change this URL when you publish your GitHub Repository
  static const String updateJsonUrl =
      'https://raw.githubusercontent.com/Gt2433/KRIDI-app/refs/heads/main/update.json';

  /// Check for updates
  static Future<void> checkForUpdate(
    BuildContext context, {
    bool isManualCheck = false,
  }) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final response = await http.get(Uri.parse(updateJsonUrl)).timeout(
            const Duration(seconds: 8),
          );

      if (response.statusCode != 200) {
        if (isManualCheck && context.mounted) {
          _showSnackBar(context, 'تعذر الفحص حالياً، تحقق من الاتصال بالإنترنت');
        }
        return;
      }

      final Map<String, dynamic> data =
          json.decode(utf8.decode(response.bodyBytes));
      final String latestVersion = (data['version'] ?? '').toString().trim();
      final String downloadUrl = (data['downloadUrl'] ?? '').toString().trim();
      final String changelog = (data['changelog'] ?? '').toString().trim();

      if (latestVersion.isEmpty || downloadUrl.isEmpty) {
        if (isManualCheck && context.mounted) {
          _showSnackBar(context, 'لا تتوفر معلومات تحديث حالياً');
        }
        return;
      }

      if (_isVersionGreaterThan(latestVersion, currentVersion)) {
        if (context.mounted) {
          _showUpdateDialog(
            context,
            latestVersion: latestVersion,
            downloadUrl: downloadUrl,
            changelog: changelog,
          );
        }
      } else {
        if (isManualCheck && context.mounted) {
          _showSnackBar(
            context,
            'أنت تستخدم أحدث إصدار من كريدي (v$currentVersion) 🎉',
          );
        }
      }
    } catch (e) {
      if (isManualCheck && context.mounted) {
        _showSnackBar(context, 'تعذر الاتصال بالخادم للفحص');
      }
      // Fail silently on automatic check as requested
    }
  }

  /// Helper to compare semver strings like "1.0.1" > "1.0.0"
  static bool _isVersionGreaterThan(String v1, String v2) {
    try {
      final List<int> p1 = v1
          .replaceAll('v', '')
          .split('.')
          .map((e) => int.tryParse(e) ?? 0)
          .toList();
      final List<int> p2 = v2
          .replaceAll('v', '')
          .split('.')
          .map((e) => int.tryParse(e) ?? 0)
          .toList();

      final maxLength = p1.length > p2.length ? p1.length : p2.length;
      for (int i = 0; i < maxLength; i++) {
        final val1 = i < p1.length ? p1[i] : 0;
        final val2 = i < p2.length ? p2[i] : 0;
        if (val1 > val2) return true;
        if (val1 < val2) return false;
      }
    } catch (_) {}
    return false;
  }

  static void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontSize: 13),
        ),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show clean RTL Update BottomSheet
  static void _showUpdateDialog(
    BuildContext context, {
    required String latestVersion,
    required String downloadUrl,
    required String changelog,
  }) {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _UpdateDialogWidget(
          latestVersion: latestVersion,
          downloadUrl: downloadUrl,
          changelog: changelog,
        );
      },
    );
  }
}

class _UpdateDialogWidget extends StatefulWidget {
  final String latestVersion;
  final String downloadUrl;
  final String changelog;

  const _UpdateDialogWidget({
    required this.latestVersion,
    required this.downloadUrl,
    required this.changelog,
  });

  @override
  State<_UpdateDialogWidget> createState() => _UpdateDialogWidgetState();
}

class _UpdateDialogWidgetState extends State<_UpdateDialogWidget> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusText = '';

  Future<void> _startDownloadAndInstall() async {
    setState(() {
      _isDownloading = true;
      _progress = 0.0;
      _statusText = 'جاري بدء التحميل...';
    });

    try {
      final request = http.Request('GET', Uri.parse(widget.downloadUrl));
      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        throw Exception('Server returned code ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? 0;
      final Directory dir = await getTemporaryDirectory();
      final File apkFile = File('${dir.path}/kredi_update.apk');

      List<int> bytes = [];
      int downloaded = 0;

      await for (var chunk in response.stream) {
        bytes.addAll(chunk);
        downloaded += chunk.length;
        if (contentLength > 0 && mounted) {
          setState(() {
            _progress = downloaded / contentLength;
            _statusText =
                'جاري التحميل... ${(_progress * 100).toStringAsFixed(0)}%';
          });
        }
      }

      await apkFile.writeAsBytes(bytes);

      if (mounted) {
        setState(() {
          _statusText = 'جاري التثبيت...';
        });
      }

      // Open Android Package Installer
      final result = await OpenFilex.open(
        apkFile.path,
        type: 'application/vnd.android.package-archive',
      );

      if (result.type != ResultType.done) {
        // Fallback: Open URL in browser if package installer fails
        final uri = Uri.parse(widget.downloadUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Fallback to browser download if direct stream fails
      final uri = Uri.parse(widget.downloadUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final textColor = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final secondaryTextColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle Bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.system_update_rounded,
                  color: AppTheme.accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'تحديث جديد متوفر 🎉',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'v${widget.latestVersion}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'نسخة جديدة من تطبيق كريدي جاهزة للتحميل.',
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 14),

          // Changelog Box
          if (widget.changelog.isNotEmpty) ...[
            Text(
              'المميزات والتحسينات الجديده:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Text(
                widget.changelog,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: secondaryTextColor,
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],

          // Download Progress Bar
          if (_isDownloading) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progress > 0 ? _progress : null,
                minHeight: 8,
                backgroundColor:
                    isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                color: AppTheme.accent,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _statusText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accent,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            // Action Buttons Row
            Row(
              children: [
                // "تحديث الآن" Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: _startDownloadAndInstall,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'تحديث الآن',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // "لاحقًا" Button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'لاحقًا',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
