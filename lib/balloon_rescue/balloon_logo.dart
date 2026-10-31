import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BalloonRescueLogo extends StatefulWidget {
  final double size;
  final bool animate;

  const BalloonRescueLogo({
    super.key,
    this.size = 200,
    this.animate = true,
  });

  @override
  State<BalloonRescueLogo> createState() => _BalloonRescueLogoState();
}

class _BalloonRescueLogoState extends State<BalloonRescueLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _floatAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOutSine),
    );

    if (widget.animate) {
      _animController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final floatY = widget.animate ? _floatAnimation.value : 0.0;
        final scale = widget.animate ? _scaleAnimation.value : 1.0;

        return Transform.translate(
          offset: Offset(0, floatY),
          child: Transform.scale(
            scale: scale,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Outer glowing cloud disc
                  Container(
                    width: widget.size * 0.95,
                    height: widget.size * 0.95,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF40C4FF).withValues(alpha: 0.45),
                          const Color(0xFF00E5FF).withValues(alpha: 0.20),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00B0FF).withValues(alpha: 0.35),
                          blurRadius: 35,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                  ),

                  // 3D Balloon Cluster Illustration
                  Positioned(
                    top: widget.size * 0.02,
                    child: CustomPaint(
                      size: Size(widget.size * 0.85, widget.size * 0.65),
                      painter: _LogoBalloonClusterPainter(),
                    ),
                  ),

                  // Mascot Boy Face / Clinging Icon
                  Positioned(
                    bottom: widget.size * 0.18,
                    child: Container(
                      width: widget.size * 0.32,
                      height: widget.size * 0.32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFFD54F), Color(0xFFFF9800)],
                        ),
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '👦',
                          style: TextStyle(fontSize: widget.size * 0.18),
                        ),
                      ),
                    ),
                  ),

                  // 3D "BALLOON RESCUE" Banner Pill
                  Positioned(
                    bottom: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: widget.size * 0.08,
                        vertical: widget.size * 0.03,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFFB300),
                            Color(0xFFFF6D00),
                            Color(0xFFFF3D00),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6D00).withValues(alpha: 0.5),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        'BALLOON RESCUE',
                        style: GoogleFonts.fredoka(
                          fontSize: widget.size * 0.082,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.2,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              offset: const Offset(0, 2),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LogoBalloonClusterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 5 Glossy Balloons with 3D Radial Highlights & Knots
    final balloons = [
      _MiniBalloon(const Offset(0.24, 0.40), 22, const Color(0xFFE91E63), const Color(0xFFFF4081)), // Pink
      _MiniBalloon(const Offset(0.76, 0.40), 22, const Color(0xFF00C853), const Color(0xFF69F0AE)), // Green
      _MiniBalloon(const Offset(0.35, 0.24), 26, const Color(0xFF2979FF), const Color(0xFF82B1FF)), // Blue
      _MiniBalloon(const Offset(0.65, 0.24), 26, const Color(0xFFFF9100), const Color(0xFFFFD180)), // Orange
      _MiniBalloon(const Offset(0.50, 0.14), 30, const Color(0xFFFF1744), const Color(0xFFFF8A80)), // Ruby Red Center
    ];

    final stringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    final handTarget = Offset(size.width * 0.5, size.height * 0.95);

    // Draw strings connecting to the boy's hand
    for (final b in balloons) {
      final bCenter = Offset(size.width * b.pos.dx, size.height * b.pos.dy);
      final path = Path()
        ..moveTo(bCenter.dx, bCenter.dy + b.radius)
        ..quadraticBezierTo(
          (bCenter.dx + handTarget.dx) / 2 + (b.pos.dx - 0.5) * 15,
          (bCenter.dy + handTarget.dy) / 2,
          handTarget.dx,
          handTarget.dy,
        );
      canvas.drawPath(path, stringPaint);
    }

    // Draw 3D Balloons
    for (final b in balloons) {
      final center = Offset(size.width * b.pos.dx, size.height * b.pos.dy);

      // Balloon Body (Oval)
      final balloonRect = Rect.fromCenter(
        center: center,
        width: b.radius * 2.0,
        height: b.radius * 2.4,
      );

      final bodyPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 0.95,
          colors: [
            Colors.white.withValues(alpha: 0.9),
            b.highlightColor,
            b.baseColor,
            b.baseColor.withValues(alpha: 0.85),
          ],
          stops: const [0.0, 0.28, 0.75, 1.0],
        ).createShader(balloonRect);

      canvas.drawOval(balloonRect, bodyPaint);

      // Bottom Knot (Triangle)
      final knotPath = Path()
        ..moveTo(center.dx - 3, center.dy + b.radius * 1.2)
        ..lineTo(center.dx + 3, center.dy + b.radius * 1.2)
        ..lineTo(center.dx, center.dy + b.radius * 1.2 + 4)
        ..close();
      canvas.drawPath(knotPath, Paint()..color = b.baseColor);

      // Specular Reflection (White gloss spot)
      final glossPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.65)
        ..style = PaintingStyle.fill;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx - b.radius * 0.35, center.dy - b.radius * 0.45),
          width: b.radius * 0.42,
          height: b.radius * 0.22,
        ),
        glossPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MiniBalloon {
  final Offset pos;
  final double radius;
  final Color baseColor;
  final Color highlightColor;
  const _MiniBalloon(this.pos, this.radius, this.baseColor, this.highlightColor);
}
