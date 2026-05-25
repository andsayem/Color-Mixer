import 'dart:math';
import 'package:flutter/material.dart';
import '../ui/app_colors.dart';

/// Paints a rotating gradient background for the HomePage.
/// The animation controller drives a continuous sweep rotation.
class BgPainter extends CustomPainter {
  final Animation<double> rotateCtrl;

  const BgPainter(this.rotateCtrl) : super(repaint: rotateCtrl);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final sweep = SweepGradient(
      colors: AppColors.accentGradient.colors,
      stops: const [0.0, 0.5, 1.0],
      transform: GradientRotation(rotateCtrl.value * 2 * pi),
    );
    final paint = Paint()..shader = sweep.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant BgPainter oldDelegate) => true;
}
