import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Dynamic Animated Nature & Forest Background for Crossword Connect
/// Features rich forest backdrop with gently swaying & falling autumn leaves (🍁, 🍂),
/// floating ambient sunbeam bokeh, and golden sparkle particles.
class CrosswordNatureBackground extends StatefulWidget {
  final Widget? child;
  final bool showParticles;
  final double particleSpeed;

  const CrosswordNatureBackground({
    super.key,
    this.child,
    this.showParticles = true,
    this.particleSpeed = 1.0,
  });

  @override
  State<CrosswordNatureBackground> createState() =>
      _CrosswordNatureBackgroundState();
}

class _CrosswordNatureBackgroundState extends State<CrosswordNatureBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  final List<_NatureParticle> _particles = [];
  final math.Random _random = math.Random(42);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();

    _initParticles();
  }

  void _initParticles() {
    const leafSymbols = ['🍁', '🍂', '🍃', '✨', '•'];
    _particles.clear();
    for (int i = 0; i < 22; i++) {
      final symbol = leafSymbols[i % leafSymbols.length];
      final isLeaf = symbol == '🍁' || symbol == '🍂' || symbol == '🍃';
      _particles.add(
        _NatureParticle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          speed: (0.35 + _random.nextDouble() * 0.65) * widget.particleSpeed,
          size: isLeaf ? (16.0 + _random.nextDouble() * 12.0) : (6.0 + _random.nextDouble() * 8.0),
          rotation: _random.nextDouble() * math.pi * 2,
          rotationSpeed: (_random.nextDouble() - 0.5) * 1.5,
          drift: (_random.nextDouble() - 0.5) * 0.35,
          opacity: isLeaf ? (0.45 + _random.nextDouble() * 0.45) : (0.25 + _random.nextDouble() * 0.4),
          symbol: symbol,
          color: isLeaf
              ? [
                  const Color(0xFFFF7043),
                  const Color(0xFFFFA726),
                  const Color(0xFFFFB74D),
                  const Color(0xFF81C784),
                ][_random.nextInt(4)]
              : const Color(0xFFFFD54F),
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
        // 1. Lush Emerald Forest Base Gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF1B4332), // Deep forest pine
                Color(0xFF2D6A4F), // Lush emerald green
                Color(0xFF40916C), // Vibrant meadow green
                Color(0xFF1B4332), // Deep woodland base
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.35, 0.70, 1.0],
            ),
          ),
        ),

        // 2. Sunlight Flare & Golden Meadow Radial Overlay
        Positioned(
          top: -60,
          right: -40,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFFFE082).withValues(alpha: 0.35),
                  const Color(0xFF81C784).withValues(alpha: 0.15),
                  Colors.transparent,
                ],
                radius: 0.8,
              ),
            ),
          ),
        ),

        // 3. Gentle Dark Woodland Vignette for Card Contrast
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withValues(alpha: 0.35),
                Colors.black.withValues(alpha: 0.15),
                Colors.black.withValues(alpha: 0.45),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        // 4. Animated Drifting Autumn Leaves & Sunlight Particles
        if (widget.showParticles)
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, _) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: _NatureParticlePainter(
                    particles: _particles,
                    progress: _animController.value,
                  ),
                );
              },
            ),
          ),

        // 5. Foreground Content
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _NatureParticle {
  final double x;
  final double y;
  final double speed;
  final double size;
  final double rotation;
  final double rotationSpeed;
  final double drift;
  final double opacity;
  final String symbol;
  final Color color;

  _NatureParticle({
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

class _NatureParticlePainter extends CustomPainter {
  final List<_NatureParticle> particles;
  final double progress;

  _NatureParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      // Calculate continuous drifting and falling
      final currentY = ((p.y + progress * p.speed) % 1.1) * size.height - 20;
      final sway = math.sin(progress * math.pi * 4 + p.x * 10) * 22.0 * p.drift;
      final currentX = (p.x * size.width + sway) % size.width;
      final currentRot = p.rotation + progress * math.pi * 2 * p.rotationSpeed;

      canvas.save();
      canvas.translate(currentX, currentY);
      canvas.rotate(currentRot);

      final textPainter = TextPainter(
        text: TextSpan(
          text: p.symbol,
          style: TextStyle(
            fontSize: p.size,
            color: p.color.withValues(alpha: p.opacity),
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_NatureParticlePainter oldDelegate) => true;
}
