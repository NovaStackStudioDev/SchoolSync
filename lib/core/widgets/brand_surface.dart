import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class BrandWaves extends StatelessWidget {
  const BrandWaves({super.key, this.height = 120});
  final double height;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: double.infinity,
    child: CustomPaint(painter: _WavePainter()),
  );
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    for (final layer in [
      (const Color(0xFFE7F9D4), .12, .30),
      (const Color(0xFFBBED80), .38, .08),
      (AppColors.gold, .68, .40),
      (AppColors.green, .82, .51),
    ]) {
      final path = Path()
        ..moveTo(0, size.height * layer.$2)
        ..cubicTo(
          size.width * .40,
          size.height * 1.12,
          size.width * .65,
          -size.height * .15,
          size.width,
          size.height * layer.$3,
        )
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(path, Paint()..color = layer.$1);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SchoolIllustration extends StatelessWidget {
  const SchoolIllustration({super.key});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 210,
    width: double.infinity,
    child: CustomPaint(painter: _SchoolPainter()),
  );
}

class _SchoolPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 360;
    canvas.save();
    canvas.translate((size.width - 320 * s) / 2, 20);
    canvas.scale(s);
    final paint = Paint();
    canvas.drawOval(
      const Rect.fromLTWH(0, 140, 320, 30),
      paint..color = const Color(0xFFD9F4BB),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(45, 60, 230, 100),
        const Radius.circular(4),
      ),
      paint..color = const Color(0xFFFFE76D),
    );
    canvas.drawPath(
      Path()
        ..moveTo(30, 62)
        ..lineTo(160, 0)
        ..lineTo(290, 62)
        ..close(),
      paint..color = AppColors.greenDark,
    );
    canvas.drawRect(
      const Rect.fromLTWH(123, 45, 74, 115),
      paint..color = const Color(0xFFFFF4A0),
    );
    canvas.drawPath(
      Path()
        ..moveTo(110, 47)
        ..lineTo(160, 10)
        ..lineTo(210, 47)
        ..close(),
      paint..color = AppColors.gold,
    );
    canvas.drawRect(
      const Rect.fromLTWH(145, 114, 30, 46),
      paint..color = AppColors.greenDeep,
    );
    for (final x in [65.0, 99.0, 210.0, 244.0]) {
      for (final y in [80.0, 118.0]) {
        canvas.drawRect(
          Rect.fromLTWH(x, y, 16, 22),
          paint..color = const Color(0xFF92DAD2),
        );
        canvas.drawLine(
          Offset(x + 8, y),
          Offset(x + 8, y + 22),
          paint
            ..color = Colors.white
            ..strokeWidth = 2,
        );
      }
    }
    canvas.drawCircle(const Offset(160, 72), 13, paint..color = Colors.white);
    canvas.drawCircle(
      const Offset(160, 72),
      10,
      paint..color = AppColors.greenDark,
    );
    canvas.drawLine(
      const Offset(160, 0),
      const Offset(160, -20),
      paint
        ..color = AppColors.greenDeep
        ..strokeWidth = 3,
    );
    canvas.drawPath(
      Path()
        ..moveTo(161, -20)
        ..lineTo(183, -16)
        ..lineTo(161, -9)
        ..close(),
      paint..color = AppColors.green,
    );
    for (final x in [15.0, 304.0]) {
      canvas.drawRect(
        Rect.fromLTWH(x - 3, 100, 6, 62),
        paint..color = const Color(0xFF785C35),
      );
      for (final offset in [
        const Offset(0, 80),
        const Offset(-8, 102),
        const Offset(9, 105),
      ]) {
        canvas.drawCircle(
          Offset(x + offset.dx, offset.dy),
          21,
          paint..color = AppColors.green,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
