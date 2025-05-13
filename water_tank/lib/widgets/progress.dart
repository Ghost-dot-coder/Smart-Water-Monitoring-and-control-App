import 'package:flutter/material.dart';
import 'dart:math';

class SemiCircularProgress extends StatelessWidget {
  final double value; // Value should be between 0 and 1

  const SemiCircularProgress({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(200, 100), // Adjust size as needed
      painter: SemiCirclePainter(value),
    );
  }
}

class SemiCirclePainter extends CustomPainter {
  final double value;

  SemiCirclePainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint backgroundPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint progressPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2;
    final startAngle = pi;
    final sweepAngle = pi * value;

    // Draw background arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      pi,
      false,
      backgroundPaint,
    );

    // Draw progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
