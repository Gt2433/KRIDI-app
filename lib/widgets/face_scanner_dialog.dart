import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/settings_service.dart';

enum FaceScannerMode { unlock, enroll }

class FaceScannerDialog extends StatefulWidget {
  final FaceScannerMode mode;

  const FaceScannerDialog({
    super.key,
    this.mode = FaceScannerMode.unlock,
  });

  static Future<bool?> show(
    BuildContext context, {
    FaceScannerMode mode = FaceScannerMode.unlock,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(100),
      builder: (context) => FaceScannerDialog(mode: mode),
    );
  }

  @override
  State<FaceScannerDialog> createState() => _FaceScannerDialogState();
}

class _FaceScannerDialogState extends State<FaceScannerDialog>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];

  bool _isInitialized = false;
  bool _isPermissionDenied = false;
  bool _isScanning = false;
  bool _isSuccess = false;
  double _scanProgress = 0.0;
  String _statusMessage = 'جارٍ تجهيز الكاميرا...';

  late AnimationController _laserController;
  Timer? _scanTimer;

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _initCamera();
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _laserController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (!mounted) return;
        setState(() {
          _isPermissionDenied = true;
          _statusMessage = 'يرجى منح إذن استخدام الكاميرا لمسح الوجه';
        });
        return;
      }

      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isPermissionDenied = true;
          _statusMessage = 'لا توجد كاميرا متوفرة في الجهاز';
        });
        return;
      }

      // Find the front-facing camera
      final frontCamera = _cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );

      final controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      _cameraController = controller;
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _isInitialized = true;
        _isPermissionDenied = false;
      });

      // Start the scan once the camera preview is ready
      _startScan();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isPermissionDenied = true;
        _statusMessage = 'تعذر تشغيل الكاميرا: $e';
      });
    }
  }

  void _startScan() {
    _scanTimer?.cancel();
    setState(() {
      _isScanning = true;
      _isSuccess = false;
      _scanProgress = 0.0;
      _statusMessage = widget.mode == FaceScannerMode.enroll
          ? 'انظر مباشرة إلى الكاميرا...'
          : 'جارٍ مسح ملامح الوجه للتحقق...';
    });

    final durationMs = widget.mode == FaceScannerMode.enroll ? 2400 : 1500;
    const intervalMs = 40;
    final totalSteps = durationMs ~/ intervalMs;
    int currentStep = 0;

    _scanTimer = Timer.periodic(const Duration(milliseconds: intervalMs), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      currentStep++;
      final progress = (currentStep / totalSteps).clamp(0.0, 1.0);

      setState(() {
        _scanProgress = progress;
        if (widget.mode == FaceScannerMode.enroll) {
          if (progress < 0.35) {
            _statusMessage = 'جارٍ تحديد موقع الوجه وتثبيت الإطار...';
          } else if (progress < 0.75) {
            _statusMessage = 'جارٍ قراءة ملامح الوجه وتحليلها...';
          } else if (progress < 1.0) {
            _statusMessage = 'جارٍ حفظ بصمة الوجه المشفرة بأمان...';
          }
        } else {
          if (progress < 0.5) {
            _statusMessage = 'جارٍ تحليل الوجه...';
          } else {
            _statusMessage = 'جارٍ مطابقة بصمة الوجه...';
          }
        }
      });

      if (progress >= 1.0) {
        timer.cancel();
        HapticFeedback.heavyImpact();

        setState(() {
          _isScanning = false;
          _isSuccess = true;
          _statusMessage = widget.mode == FaceScannerMode.enroll
              ? 'تم تسجيل بصمة وجهك بنجاح! ✓'
              : 'تم التعرف على الوجه بنجاح! ✓';
        });

        if (widget.mode == FaceScannerMode.enroll) {
          await SettingsService.setFaceEnrolled(true);
          await SettingsService.setFaceAuthEnabled(true);
        }

        await Future.delayed(const Duration(milliseconds: 700));
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCol = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderCol = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB);
    final textCol = isDark ? Colors.white : Colors.black;
    final subTextCol = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);

    return Container(
      decoration: BoxDecoration(
        color: bgCol,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(
            color: borderCol,
            width: 1.2,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 18),

          // Title
          Text(
            widget.mode == FaceScannerMode.enroll
                ? 'تسجيل بصمة الوجه'
                : 'التحقق ببصمة الوجه',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textCol,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.mode == FaceScannerMode.enroll
                ? 'انظر للكاميرا الأمامية لمسح ملامح وجهك'
                : 'وجّه الكاميرا إلى وجهك لفتح القفل تلقائياً',
            style: TextStyle(
              fontSize: 13,
              color: subTextCol,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Viewfinder / Camera View
          _buildViewfinder(),

          const SizedBox(height: 20),

          // Progress indicator & percent
          if (_isInitialized && !_isPermissionDenied) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _scanProgress,
                  minHeight: 6,
                  backgroundColor: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFF3F4F6),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _isSuccess ? const Color(0xFF16A34A) : (isDark ? Colors.white : Colors.black),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${(_scanProgress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _isSuccess ? const Color(0xFF16A34A) : textCol,
              ),
            ),
            const SizedBox(height: 4),
          ],

          // Status message
          Text(
            _statusMessage,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _isSuccess
                  ? const Color(0xFF16A34A)
                  : (_isPermissionDenied ? const Color(0xFFDC2626) : textCol),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Actions
          if (_isPermissionDenied) ...[
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => openAppSettings(),
                child: const Text(
                  'فتح إعدادات الأذونات',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ] else if (!_isScanning && !_isSuccess && _isInitialized) ...[
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _startScan,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.refresh_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('إعادة المسح', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'إلغاء',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: subTextCol,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewfinder() {
    const width = 220.0;
    const height = 260.0;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer decorative border
          Container(
            width: width + 16,
            height: height + 16,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(36),
              border: Border.all(
                color: _isSuccess
                    ? const Color(0xFF16A34A)
                    : (_isScanning ? Colors.black : const Color(0xFFE5E7EB)),
                width: 2,
              ),
            ),
          ),

          // Camera frame
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Container(
              width: width,
              height: height,
              color: const Color(0xFFF3F4F6),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_isInitialized && _cameraController != null)
                    FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _cameraController!.value.previewSize?.height ?? width,
                        height: _cameraController!.value.previewSize?.width ?? height,
                        child: CameraPreview(_cameraController!),
                      ),
                    )
                  else
                    const Center(
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2,
                      ),
                    ),

                  // Scanning laser beam
                  if (_isScanning)
                    AnimatedBuilder(
                      animation: _laserController,
                      builder: (context, child) {
                        return Positioned(
                          top: _laserController.value * (height - 10),
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  _isSuccess ? const Color(0xFF16A34A) : Colors.black,
                                  Colors.transparent,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (_isSuccess ? const Color(0xFF16A34A) : Colors.black).withAlpha(140),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  // Success checkmark overlay
                  if (_isSuccess)
                    Container(
                      color: Colors.black.withAlpha(60),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Color(0xFF16A34A),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 44,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 4 Face-ID Style Brackets on corners
          Positioned(
            top: 0,
            left: 0,
            child: _buildCornerBracket(isTop: true, isLeft: true),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: _buildCornerBracket(isTop: true, isLeft: false),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: _buildCornerBracket(isTop: false, isLeft: true),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: _buildCornerBracket(isTop: false, isLeft: false),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerBracket({required bool isTop, required bool isLeft}) {
    const size = 26.0;
    const border = BorderSide(color: Colors.black, width: 3.5);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? border : BorderSide.none,
          bottom: !isTop ? border : BorderSide.none,
          left: isLeft ? border : BorderSide.none,
          right: !isLeft ? border : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft: isTop && isLeft ? const Radius.circular(12) : Radius.zero,
          topRight: isTop && !isLeft ? const Radius.circular(12) : Radius.zero,
          bottomLeft: !isTop && isLeft ? const Radius.circular(12) : Radius.zero,
          bottomRight: !isTop && !isLeft ? const Radius.circular(12) : Radius.zero,
        ),
      ),
    );
  }
}
