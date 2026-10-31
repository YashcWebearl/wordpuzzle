import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Dynamic Animated Golden Honey & Balloon Background for Balloon Rescue
/// Matches the ScrambleCosmicBackground structure with rich warm yellow/amber backdrop,
/// gently floating stars (✨, ⭐), balloons (🎈), clouds (☁️), gold coins (🪙), and ambient bokeh.
/// Yellow theme: #FFD54F / #FF9100.
class BalloonSkyBackground extends StatefulWidget {
  final Widget? child;
  final bool showParticles;
  final double particleSpeed;

  const BalloonSkyBackground({
    super.key,
    this.child,
    this.showParticles = true,
    this.particleSpeed = 1.0,
  });

  @override
  State<BalloonSkyBackground> createState() => _BalloonSkyBackgroundState();
}

class _BalloonSkyBackgroundState extends State<BalloonSkyBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  final List<_BalloonAtmosphereParticle> _particles = [];
  final math.Random _random = math.Random(108);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();

    _initParticles();
  }

  void _initParticles() {
    const symbols = ['✨', '⭐', '🎈', '☁️', '🪙', '•'];
    _particles.clear();
    for (int i = 0; i < 24; i++) {
      final symbol = symbols[i % symbols.length];
      final isIcon = symbol != '•';
      _particles.add(
        _BalloonAtmosphereParticle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          speed: (0.3 + _random.nextDouble() * 0.7) * widget.particleSpeed,
          size: isIcon
              ? (14.0 + _random.nextDouble() * 10.0)
              : (5.0 + _random.nextDouble() * 6.0),
          rotation: _random.nextDouble() * math.pi * 2,
          rotationSpeed: (_random.nextDouble() - 0.5) * 1.6,
          drift: (_random.nextDouble() - 0.5) * 0.35,
          opacity: isIcon
              ? (0.40 + _random.nextDouble() * 0.45)
              : (0.20 + _random.nextDouble() * 0.35),
          symbol: symbol,
          color: [
            const Color(0xFFFFD54F), // Sunny yellow
            const Color(0xFFFFB300), // Rich amber
            const Color(0xFFFF9100), // Tangerine gold
            const Color(0xFFFFE082), // Soft cream yellow
            const Color(0xFFFF7043), // Warm coral
          ][_random.nextInt(5)],
        ),
      );
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Deep Warm Golden Amber Radial Gradient Backdrop
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.0, -0.3),
              radius: 1.35,
              colors: [
                Color(0xFF422800), // Glowing warm golden amber core
                Color(0xFF261600), // Deep honey twilight
                Color(0xFF0F0900), // Dark obsidian amber abyss
              ],
            ),
          ),
        ),

        // 2. Parallax Sky Clouds & Distant Hot-Air Balloon Layer
        AnimatedBuilder(
          animation: _animController,
          builder: (context, _) {
            return CustomPaint(
              painter: _SkyParallaxPainter(
                progress: _animController.value,
              ),
            );
          },
        ),

        // 3. Animated Floating Particles
        if (widget.showParticles)
          AnimatedBuilder(
            animation: _animController,
            builder: (context, _) {
              return CustomPaint(
                painter: _BalloonParticlePainter(
                  particles: _particles,
                  progress: _animController.value,
                ),
              );
            },
          ),

        // 3. Ambient Glowing Golden Yellow Bokeh Circles
        Positioned(
          top: -80,
          right: -60,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFD54F).withValues(alpha: 0.12),
            ),
          ),
        ),
        Positioned(
          bottom: -100,
          left: -80,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFF9100).withValues(alpha: 0.08),
            ),
          ),
        ),

        // 4. Foreground Child
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _BalloonAtmosphereParticle {
  double x;
  double y;
  final double speed;
  final double size;
  double rotation;
  final double rotationSpeed;
  final double drift;
  final double opacity;
  final String symbol;
  final Color color;

  _BalloonAtmosphereParticle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.drift,
    required this.opacity,
    required this.symbol,
    required this.color,
  });
}

class _BalloonParticlePainter extends CustomPainter {
  final List<_BalloonAtmosphereParticle> particles;
  final double progress;

  _BalloonParticlePainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      // Upward floating motion with gentle horizontal drift
      final currentY = ((p.y - (progress * p.speed * 0.4)) % 1.0) * size.height;
      final currentX =
          ((p.x + math.sin(progress * 2 * math.pi + p.rotation) * p.drift * 0.1) %
                  1.0) *
              size.width;

      final currentRotation = p.rotation + (progress * p.rotationSpeed * 2 * math.pi);

      canvas.save();
      canvas.translate(currentX, currentY);
      canvas.rotate(currentRotation);

      if (p.symbol == '•') {
        // Glowing dot
        final paint = Paint()
          ..color = p.color.withValues(alpha: p.opacity)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        // Icon / Emoji Text
        final textSpan = TextSpan(
          text: p.symbol,
          style: TextStyle(
            fontSize: p.size,
            color: p.color.withValues(alpha: p.opacity),
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        )..layout();

        textPainter.paint(
          canvas,
          Offset(-textPainter.width / 2, -textPainter.height / 2),
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BalloonParticlePainter oldDelegate) => true;
}

/// Parallax Painter rendering soft drifting clouds and a distant hot-air balloon
class _SkyParallaxPainter extends CustomPainter {
  final double progress;

  _SkyParallaxPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Far Upper Sky Cloud 1 (slow, delicate)
    final cloud1X = ((1.2 - (progress * 0.25)) % 1.4 - 0.2) * w;
    _drawSoftCloud(canvas, Offset(cloud1X, h * 0.16), 55, 0.12);

    // 2. Distant Hot-Air Balloon drifting slowly in upper sky
    final balloonX = ((progress * 0.35 + 0.1) % 1.3 - 0.15) * w;
    final balloonBob = math.sin(progress * 4 * math.pi) * 4.0;
    _drawDistantHotAirBalloon(
        canvas, Offset(balloonX, h * 0.22 + balloonBob), 0.35);

    // 3. Mid Sky Cloud 2 (medium speed)
    final cloud2X = ((1.3 - (progress * 0.45)) % 1.5 - 0.25) * w;
    _drawSoftCloud(canvas, Offset(cloud2X, h * 0.48), 70, 0.08);

    // 4. Lower Sky Cloud 3 (gentle backdrop drift)
    final cloud3X = ((1.1 - (progress * 0.30)) % 1.4 - 0.2) * w;
    _drawSoftCloud(canvas, Offset(cloud3X, h * 0.72), 60, 0.10);
  }

  void _drawSoftCloud(
      Canvas canvas, Offset center, double baseRadius, double opacity) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, baseRadius * 0.55, paint);
    canvas.drawCircle(
        Offset(center.dx - baseRadius * 0.45, center.dy + baseRadius * 0.1),
        baseRadius * 0.38,
        paint);
    canvas.drawCircle(
        Offset(center.dx + baseRadius * 0.45, center.dy + baseRadius * 0.1),
        baseRadius * 0.42,
        paint);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + baseRadius * 0.2),
        width: baseRadius * 1.5,
        height: baseRadius * 0.55,
      ),
      paint,
    );
  }

  void _drawDistantHotAirBalloon(Canvas canvas, Offset center, double opacity) {
    canvas.save();
    canvas.translate(center.dx, center.dy);

    const r = 14.0;
    // Balloon envelope (cute pastel orange & coral stripes)
    final balloonPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFF9100), Color(0xFFFF5252)],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r))
      ..color = Colors.white.withValues(alpha: opacity);

    final path = Path()
      ..moveTo(0, -r)
      ..cubicTo(r * 1.2, -r, r * 1.1, r * 0.4, 0, r * 1.1)
      ..cubicTo(-r * 1.1, r * 0.4, -r * 1.2, -r, 0, -r)
      ..close();
    canvas.drawPath(path, balloonPaint);

    // Decorative white stripe
    final stripePaint = Paint()
      ..color = Colors.white.withValues(alpha: opacity * 0.6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(0, -r), const Offset(0, r * 1.05), stripePaint);

    // Basket ropes
    final ropePaint = Paint()
      ..color = Colors.white.withValues(alpha: opacity * 0.5)
      ..strokeWidth = 0.8;
    canvas.drawLine(const Offset(-3, r * 1.1), const Offset(-2, r * 1.45), ropePaint);
    canvas.drawLine(const Offset(3, r * 1.1), const Offset(2, r * 1.45), ropePaint);

    // Woven basket
    final basketPaint = Paint()
      ..color = const Color(0xFF8D6E63).withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-3.5, r * 1.45, 7, 5),
        const Radius.circular(1.5),
      ),
      basketPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SkyParallaxPainter oldDelegate) => true;
}

