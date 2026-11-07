import 'dart:math';
import 'package:flutter/material.dart';

class PieSliceData {
  final String label;
  final double value;
  final Color color;
  final IconData? icon;

  const PieSliceData({
    required this.label,
    required this.value,
    required this.color,
    this.icon,
  });
}

class CustomPieChart extends StatelessWidget {
  final List<PieSliceData> data;
  final double totalAmount;
  final String centerTitle;
  final String centerSubtitle;

  const CustomPieChart({
    super.key,
    required this.data,
    required this.totalAmount,
    this.centerTitle = 'المجموع',
    this.centerSubtitle = '',
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty || totalAmount <= 0) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart_outline_rounded, size: 56, color: Colors.grey.withAlpha(100)),
            const SizedBox(height: 8),
            const Text(
              'لا توجد بيانات لهذا الشهر بعد',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 220,
          width: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(200, 200),
                painter: _PieChartPainter(data: data, total: totalAmount),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    centerTitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withAlpha(160),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    centerSubtitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Legend items
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: data.map((slice) {
            final percentage = (slice.value / totalAmount * 100).toStringAsFixed(1);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: slice.color.withAlpha(25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: slice.color.withAlpha(80)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: slice.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    slice.label,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '($percentage%)',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final List<PieSliceData> data;
  final double total;

  _PieChartPainter({required this.data, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    const strokeWidth = 28.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    double startAngle = -pi / 2;

    for (final slice in data) {
      final sweepAngle = (slice.value / total) * 2 * pi;
      paint.color = slice.color;

      // Draw arc
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle - 0.03, // Tiny gap between slices
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.total != total;
  }
}

