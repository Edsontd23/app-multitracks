
import 'dart:math' as math;
import 'package:flutter/material.dart';

class Waveform extends StatelessWidget {
  final List<double> samples;

  const Waveform({
    super.key,
    required this.samples,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: WaveformPainter(samples),
        size: Size.infinite,
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final List<double> samples;

  WaveformPainter(this.samples);

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty || size.width <= 0 || size.height <= 0) {
      return;
    }

    final center = size.height / 2;

    // Una barra por cada píxel horizontal disponible.
    final barCount = math.min(
      size.width.ceil(),
      samples.length,
    );

    final step = size.width / barCount;

    // Conservamos el pico máximo de cada grupo de muestras.
    final peaks = List<double>.filled(barCount, 0);

    for (int i = 0; i < samples.length; i++) {
      final barIndex = i * barCount ~/ samples.length;

      final amplitude = samples[i].abs().clamp(0.0, 1.0);

      if (amplitude > peaks[barIndex]) {
        peaks[barIndex] = amplitude;
      }
    }

    final paint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = math.min(1.5, step)
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < barCount; i++) {
      final x = (i + 0.5) * step;
      final amplitude = peaks[i] * center * 0.95;

      canvas.drawLine(
        Offset(x, center - amplitude),
        Offset(x, center + amplitude),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return !identical(oldDelegate.samples, samples);
  }
}
