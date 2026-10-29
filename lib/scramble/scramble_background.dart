import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Dynamic Animated Cosmic Candy Background for Word Scramble
/// Features rich violet/magenta backdrop with gently floating stars,
/// sparkles (✨, ⭐), sweet candy treats (🍭, 🍬, 🐾), and ambient bokeh.
class ScrambleCosmicBackground extends StatefulWidget {
  final Widget? child;
  final bool showParticles;
  final double particleSpeed;

  const ScrambleCosmicBackground({
    super.key,
    this.child,
    this.showParticles = true,
    this.particleSpeed = 1.0,
  });

  @override
  State<ScrambleCosmicBackground> createState() =>
      _ScrambleCosmicBackgroundState();
}

class _ScrambleCosmicBackgroundState extends State<ScrambleCosmicBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  final List<_CosmicParticle> _particles = [];
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
    const symbols = ['✨', '⭐', '🐾', '🍭', '🍬', '•'];
    _particles.clear();
    for (int i = 0; i < 24; i++) {
      final symbol = symbols[i % symbols.length];
      final isIcon = symbol != '•';
      _particles.add(
        _CosmicParticle(
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
            const Color(0xFFFF4081),
            const Color(0xFFFF80AB),
            const Color(0xFFFFD54F),
            const Color(0xFF00E5FF),
            const Color(0xFFE040FB),
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
        // 1. Deep Cosmic Radial Gradient Backdrop
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.0, -0.3),
              radius: 1.35,
              colors: [
                Color(0xFF3B1266), // Glowing royal magenta core
                Color(0xFF220840), // Deep velvet purple
                Color(0xFF0F021D), // Obsidian cosmic abyss
              ],
            ),
          ),
        ),

        // 2. Animated Floating Particles
        if (widget.showParticles)
          AnimatedBuilder(
            animation: _animController,
            builder: (context, _) {
              return CustomPaint(
                painter: _CosmicParticlesPainter(
                  particles: _particles,
                  progress: _animController.value,
                ),
                size: Size.infinite,
              );
            },
          ),

        // 3. Child Screen Content
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _CosmicParticle {
  double x;
  double y;
  double speed;
  double size;
  double rotation;
  double rotationSpeed;
  double drift;
  double opacity;
  String symbol;
  Color color;

  _CosmicParticle({
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

class _CosmicParticlesPainter extends CustomPainter {
  final List<_CosmicParticle> particles;
  final double progress;

  _CosmicParticlesPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final currentY = (p.y - progress * p.speed) % 1.0;
      final currentX = (p.x + progress * p.drift) % 1.0;

      final px = currentX * size.width;
      final py = (currentY < 0 ? currentY + 1.0 : currentY) * size.height;

      final currentRotation = p.rotation + progress * p.rotationSpeed * math.pi * 2;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(currentRotation);

      if (p.symbol == '•') {
        final paint = Paint()
          ..color = p.color.withValues(alpha: p.opacity)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        final textPainter = TextPainter(
          text: TextSpan(
            text: p.symbol,
            style: TextStyle(
              fontSize: p.size,
              color: p.color.withValues(alpha: p.opacity),
            ),
          ),
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
  bool shouldRepaint(covariant _CosmicParticlesPainter oldDelegate) => true;
}
