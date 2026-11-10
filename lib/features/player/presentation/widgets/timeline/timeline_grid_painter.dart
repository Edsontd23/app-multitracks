
import 'package:flutter/material.dart';

class TimelineGridPainter extends CustomPainter {
  final Duration duration;

  TimelineGridPainter({
    required this.duration,
  });

  static double calculateInterval({
    required double durationSeconds,
    required double width,
  }) {
    if (durationSeconds <= 0 || width <= 0) return 1;

    const targetSpacing = 75.0;

    final rawInterval = durationSeconds * targetSpacing / width;

    final magnitude = _powerOfTen(rawInterval);
    final normalized = rawInterval / magnitude;

    if (normalized <= 1) return magnitude;
    if (normalized <= 2) return 2 * magnitude;
    if (normalized <= 5) return 5 * magnitude;

    return 10 * magnitude;
  }

  static double _powerOfTen(double value) {
    var magnitude = 1.0;

    while (magnitude * 10 <= value) {
      magnitude *= 10;
    }

    return magnitude;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final durationSeconds = duration.inMilliseconds / 1000.0;

    if (durationSeconds <= 0 ||
        size.width <= 0 ||
        size.height <= 0) {
      return;
    }

    final interval = calculateInterval(
      durationSeconds: durationSeconds,
      width: size.width,
    );

    final pixelsPerSecond = size.width / durationSeconds;

    final path = Path();

    // Divisiones verticales.
    for (double seconds = 0;
        seconds <= durationSeconds;
        seconds += interval) {
      final x = seconds * pixelsPerSecond;

      path.moveTo(x, 0);
      path.lineTo(x, size.height);
    }

    // Divisiones horizontales.
    for (double y = 0; y < size.height; y += 30) {
      path.moveTo(0, y);
      path.lineTo(size.width, y);
    }

    final paint = Paint()
      ..color = Colors.white12
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant TimelineGridPainter oldDelegate) {
    return oldDelegate.duration != duration;
  }
}
