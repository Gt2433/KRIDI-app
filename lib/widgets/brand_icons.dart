import 'package:flutter/material.dart';

/// Pixel-perfect vector Brand Icons for WhatsApp, Instagram, and TikTok
class WhatsAppIcon extends StatelessWidget {
  final double size;
  final Color color;

  const WhatsAppIcon({
    super.key,
    this.size = 20,
    this.color = const Color(0xFF25D366),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _WhatsAppPainter(color),
    );
  }
}

class _WhatsAppPainter extends CustomPainter {
  final Color color;

  _WhatsAppPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final scaleX = size.width / 24.0;
    final scaleY = size.height / 24.0;

    canvas.scale(scaleX, scaleY);

    // Speech bubble path
    final path = Path();
    path.moveTo(12, 2);
    path.cubicTo(6.48, 2, 2, 6.48, 2, 12);
    path.cubicTo(2, 13.84, 2.5, 15.56, 3.37, 17.04);
    path.lineTo(2.05, 21.95);
    path.lineTo(7.08, 20.64);
    path.cubicTo(8.52, 21.51, 10.21, 22, 12, 22);
    path.cubicTo(17.52, 22, 22, 17.52, 22, 12);
    path.cubicTo(22, 6.48, 17.52, 2, 12, 2);
    path.close();

    canvas.drawPath(path, paint);

    // Inner Phone Receiver cutout
    final cutoutPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final phonePath = Path();
    phonePath.moveTo(16.5, 14.15);
    phonePath.cubicTo(16.2, 14, 14.75, 13.29, 14.48, 13.19);
    phonePath.cubicTo(14.21, 13.09, 14.02, 13.04, 13.82, 13.34);
    phonePath.cubicTo(13.63, 13.63, 13.08, 14.28, 12.91, 14.48);
    phonePath.cubicTo(12.74, 14.67, 12.57, 14.7, 12.28, 14.55);
    phonePath.cubicTo(11.98, 14.4, 11.03, 14.09, 9.9, 13.08);
    phonePath.cubicTo(9.02, 12.3, 8.42, 11.34, 8.25, 11.04);
    phonePath.cubicTo(8.08, 10.75, 8.23, 10.59, 8.38, 10.44);
    phonePath.cubicTo(8.51, 10.31, 8.67, 10.1, 8.82, 9.93);
    phonePath.cubicTo(8.97, 9.76, 9.02, 9.63, 9.12, 9.44);
    phonePath.cubicTo(9.22, 9.24, 9.17, 9.07, 9.09, 8.93);
    phonePath.cubicTo(9.02, 8.78, 8.47, 7.43, 8.24, 6.88);
    phonePath.cubicTo(8.02, 6.34, 7.79, 6.42, 7.62, 6.41);
    phonePath.lineTo(7.1, 6.4);
    phonePath.cubicTo(6.9, 6.4, 6.61, 6.47, 6.36, 6.74);
    phonePath.cubicTo(6.11, 7.01, 5.4, 7.67, 5.4, 9.02);
    phonePath.cubicTo(5.4, 10.37, 6.39, 11.67, 6.53, 11.86);
    phonePath.cubicTo(6.67, 12.05, 8.48, 14.83, 11.25, 16.03);
    phonePath.cubicTo(11.91, 16.31, 12.42, 16.48, 12.82, 16.61);
    phonePath.cubicTo(13.48, 16.82, 14.08, 16.79, 14.56, 16.72);
    phonePath.cubicTo(15.09, 16.64, 16.19, 16.05, 16.42, 15.4);
    phonePath.cubicTo(16.65, 14.75, 16.65, 14.2, 16.58, 14.08);
    phonePath.close();

    canvas.drawPath(phonePath, cutoutPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class InstagramIcon extends StatelessWidget {
  final double size;
  final Color color;

  const InstagramIcon({
    super.key,
    this.size = 20,
    this.color = const Color(0xFFE1306C),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _InstagramPainter(color),
    );
  }
}

class _InstagramPainter extends CustomPainter {
  final Color color;

  _InstagramPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..isAntiAlias = true;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final scaleX = size.width / 24.0;
    final scaleY = size.height / 24.0;
    canvas.scale(scaleX, scaleY);

    // Outer rounded square
    final rect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(3, 3, 18, 18),
      const Radius.circular(5.5),
    );
    canvas.drawRRect(rect, strokePaint);

    // Inner circle (lens)
    canvas.drawCircle(const Offset(12, 12), 4.5, strokePaint);

    // Flash dot
    canvas.drawCircle(const Offset(17, 7), 1.2, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TikTokIcon extends StatelessWidget {
  final double size;
  final Color color;

  const TikTokIcon({
    super.key,
    this.size = 20,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _TikTokPainter(color),
    );
  }
}

class _TikTokPainter extends CustomPainter {
  final Color color;

  _TikTokPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final scaleX = size.width / 24.0;
    final scaleY = size.height / 24.0;
    canvas.scale(scaleX, scaleY);

    final path = Path();
    path.moveTo(16.6, 5.82);
    path.cubicTo(15.43, 5.01, 14.62, 3.66, 14.47, 2);
    path.lineTo(11.53, 2);
    path.lineTo(11.53, 14.39);
    path.cubicTo(11.53, 16.05, 10.18, 17.4, 8.52, 17.4);
    path.cubicTo(6.86, 17.4, 5.51, 16.05, 5.51, 14.39);
    path.cubicTo(5.51, 12.73, 6.86, 11.38, 8.52, 11.38);
    path.cubicTo(8.93, 11.38, 9.32, 11.47, 9.68, 11.62);
    path.lineTo(9.68, 8.61);
    path.cubicTo(9.3, 8.52, 8.91, 8.47, 8.52, 8.47);
    path.cubicTo(5.25, 8.47, 2.6, 11.12, 2.6, 14.39);
    path.cubicTo(2.6, 17.66, 5.25, 20.31, 8.52, 20.31);
    path.cubicTo(11.79, 20.31, 14.44, 17.66, 14.44, 14.39);
    path.lineTo(14.44, 8.65);
    path.cubicTo(15.78, 9.62, 17.43, 10.2, 19.2, 10.24);
    path.lineTo(19.2, 7.3);
    path.cubicTo(18.23, 7.29, 17.31, 6.74, 16.6, 5.82);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
