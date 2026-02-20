import 'package:flutter/material.dart';

class RadialGradientPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2; // Use half the shortest side for full coverage
    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 1.0, // Fill the entire area
      colors: [
        Colors.blue.withOpacity(0.25),
        Colors.blue.withOpacity(0.10),
        Colors.transparent,
      ],
      stops: [0.0, 0.5, 1.0],
    );
    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      );
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GridGradientPainter extends CustomPainter {
      @override
      void paint(Canvas canvas, Size size) {
        final center = Offset(size.width / 2, size.height / 2);
        final radius = size.shortestSide / 2;
        final gradient = RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            Colors.blue.withOpacity(0.25),
            Colors.blue.withOpacity(0.10),
            Colors.transparent,
          ],
          stops: [0.0, 0.5, 1.0],
        );
        final paint = Paint()
          ..shader = gradient.createShader(
            Rect.fromCircle(center: center, radius: radius),
          );
        canvas.drawCircle(center, radius, paint);
        // Optional: Draw a border
        final borderPaint = Paint()
          ..color = Colors.blue.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        canvas.drawCircle(center, radius, borderPaint);
      }

      @override
      bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
    }
