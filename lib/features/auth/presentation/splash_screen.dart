import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Decorative background elements to match the mockup
            Positioned.fill(
              child: CustomPaint(
                painter: SplashBackgroundPainter(),
              ),
            ),
            // Central content
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  // easeOutBack bisa menghasilkan nilai > 1.0 (overshoot),
                  // clamp agar opacity tetap dalam range yang valid (0.0 – 1.0)
                  final clampedOpacity = value.clamp(0.0, 1.0);
                  return Opacity(
                    opacity: clampedOpacity,
                    child: Transform.scale(
                      scale: 0.8 + (value * 0.2),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/logo_myStudyMate.png',
                      height: 75,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Study Together Better',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Loading indicator at the bottom
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    backgroundColor: AppColors.primary.withAlpha(26),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter to draw the decorative background circles/rectangles from the mockup
class SplashBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = AppColors.primary.withAlpha(8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Solid faint circle in the background
    canvas.drawCircle(center, 120, paint);

    // Another larger solid faint circle offset
    canvas.drawCircle(Offset(center.dx + 60, center.dy + 80), 160, paint);

    // A dotted circle decoration
    final dottedPaint = Paint()
      ..color = AppColors.primary.withAlpha(12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    _drawDottedCircle(canvas, center, 140, dottedPaint);

    // Draw some subtle faint rounded rectangles (cards) in the background
    final rectPaint = Paint()
      ..color = AppColors.primary.withAlpha(4)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx - 80, center.dy - 120),
          width: 70,
          height: 90,
        ),
        const Radius.circular(12),
      ),
      rectPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx + 90, center.dy - 80),
          width: 50,
          height: 35,
        ),
        const Radius.circular(8),
      ),
      rectPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx - 80, center.dy + 120),
          width: 45,
          height: 65,
        ),
        const Radius.circular(8),
      ),
      rectPaint,
    );
  }

  void _drawDottedCircle(Canvas canvas, Offset center, double radius, Paint paint) {
    const double dashWidth = 5.0;
    const double spaceWidth = 10.0;
    
    final double circumference = 2 * 3.1415926535 * radius;
    final double dashAngle = (dashWidth / circumference) * 2 * 3.1415926535;
    final double spaceAngle = (spaceWidth / circumference) * 2 * 3.1415926535;

    double currentAngle = 0;
    while (currentAngle < 2 * 3.1415926535) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentAngle,
        dashAngle,
        false,
        paint,
      );
      currentAngle += dashAngle + spaceAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


