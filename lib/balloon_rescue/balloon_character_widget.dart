import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:word_puzzle/widget/sound.dart';

class BalloonCharacterWidget extends StatefulWidget {
  final int balloonsRemaining; // 0 to 5
  final String expression; // 'idle', 'happy', 'shocked', 'win', 'defeat'
  final VoidCallback? onPopComplete;

  const BalloonCharacterWidget({
    super.key,
    required this.balloonsRemaining,
    this.expression = 'idle',
    this.onPopComplete,
  });

  @override
  State<BalloonCharacterWidget> createState() => BalloonCharacterWidgetState();
}

class BalloonCharacterWidgetState extends State<BalloonCharacterWidget>
    with TickerProviderStateMixin {
  late final AnimationController _bobController;
  late final AnimationController _burstController;
  late final AnimationController _fallController;
  late final Animation<double> _fallAnimation;

  // Celebratory Sky Take-off on victory!
  late final AnimationController _takeOffController;
  late final Animation<double> _takeOffAnimation;
  bool _isTakingOff = false;

  // Interactive Elastic Drag & Spring Snap-back controllers
  late final AnimationController _snapBackController;
  Animation<Offset>? _snapBackAnimation;
  late final AnimationController _trembleController;

  final List<_BalloonDebrisParticle> _burstParticles = [];

  Offset _dragOffset = Offset.zero;
  bool _isHolding = false;
  bool _isFalling = false;
  bool _isScared = false;
  bool _hasDragged = false;

  // 5 Symmetrically positioned Balloons fanning out right above the boy.
  // Order is set so that as lives decrease (5 -> 0), balloons burst from bottom-outer to top-center:
  // 1st pop: Pink (left bottom - user's red mark)
  // 2nd pop: Green (right bottom - user's yellow mark)
  // 3rd pop: Sky Blue (left mid - user's dark blue mark)
  // 4th pop: Orange (right mid - user's light blue mark)
  // 5th pop (last): Ruby Red (top center - user's white mark)
  final List<_BalloonDef> _balloonDefs = const [
    _BalloonDef(
      id: 0,
      color: Color(0xFFFF1744), // Ruby Red (top center - 5th & LAST to pop)
      highlight: Color(0xFFFF8A80),
      normalizedPos: Offset(0.50, 0.12),
      radius: 28,
    ),
    _BalloonDef(
      id: 1,
      color: Color(0xFFFF9100), // Tangerine Orange (right mid - 4th to pop)
      highlight: Color(0xFFFFE57F),
      normalizedPos: Offset(0.65, 0.26),
      radius: 25,
    ),
    _BalloonDef(
      id: 2,
      color: Color(0xFF2979FF), // Sky Blue (left mid - 3rd to pop)
      highlight: Color(0xFF82B1FF),
      normalizedPos: Offset(0.35, 0.26),
      radius: 25,
    ),
    _BalloonDef(
      id: 3,
      color: Color(0xFF00E676), // Emerald Green (right bottom - 2nd to pop)
      highlight: Color(0xFFB9F6CA),
      normalizedPos: Offset(0.76, 0.44),
      radius: 22,
    ),
    _BalloonDef(
      id: 4,
      color: Color(0xFFE91E63), // Pink (left bottom - 1st to pop)
      highlight: Color(0xFFFF80AB),
      normalizedPos: Offset(0.24, 0.44),
      radius: 22,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _burstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..addListener(() {
        setState(() {
          for (final p in _burstParticles) {
            p.update();
          }
        });
      });

    // Accelerated gravity free-fall when all balloons pop
    _fallController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..addListener(() {
        setState(() {});
      });

    _fallAnimation = CurvedAnimation(
      parent: _fallController,
      curve: Curves.easeInCubic, // Realistic acceleration under gravity!
    );

    // Celebratory Take-off into the sky on victory!
    _takeOffController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..addListener(() {
        setState(() {});
      });

    _takeOffAnimation = CurvedAnimation(
      parent: _takeOffController,
      curve: Curves.easeInBack, // Pre-dips slightly then accelerates into the clouds!
    );

    // Continuous comic tremor while held by the player
    _trembleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..repeat();

    // Elastic spring snap-back when finger is released
    _snapBackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (mounted) {
            setState(() {
              _isScared = false;
              _dragOffset = Offset.zero;
            });
          }
        }
      });

    if (widget.balloonsRemaining <= 0) {
      _isFalling = true;
      _fallController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _bobController.dispose();
    _burstController.dispose();
    _fallController.dispose();
    _takeOffController.dispose();
    _snapBackController.dispose();
    _trembleController.dispose();
    AudioHelper().stopBalloonHoldScared();
    super.dispose();
  }

  void _onDragStart(Offset localPosition) {
    if (_isFalling || widget.balloonsRemaining <= 0 || _isHolding) return;

    _snapBackController.stop();
    HapticFeedback.lightImpact();
    AudioHelper().playBalloonScared();

    setState(() {
      _isHolding = true;
      _isScared = true;
      _hasDragged = false;
      _dragOffset = Offset.zero;
      _snapBackAnimation = null;
    });
  }

  void _onDragUpdate(Offset delta) {
    if (_isFalling || widget.balloonsRemaining <= 0 || !_isHolding) return;

    final newOffset = _dragOffset + delta;
    if (!_hasDragged && newOffset.distance < 4.0) {
      // Don't shift position on simple finger touch / tap jitter
      return;
    }
    _hasDragged = true;

    const double maxRadius = 60.0;
    final double dist = newOffset.distance;

    setState(() {
      if (dist > maxRadius) {
        // Soft rubber-band elasticity beyond maxRadius
        final excess = dist - maxRadius;
        final resisted = maxRadius + excess * 0.22;
        _dragOffset = Offset.fromDirection(newOffset.direction, resisted);
      } else {
        _dragOffset = newOffset;
      }
    });
  }

  void _onDragRelease() {
    if (!_isHolding) return;

    // Immediately silence any active scared hold vocalization
    AudioHelper().stopBalloonHoldScared();

    setState(() {
      _isHolding = false;
    });

    if (_hasDragged && _dragOffset.distance > 4.0) {
      // Release after actually dragging: elastic spring bounce back to center!
      HapticFeedback.mediumImpact();
      _snapBackAnimation = Tween<Offset>(
        begin: _dragOffset,
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _snapBackController,
        curve: Curves.elasticOut,
      ));
      _snapBackController.forward(from: 0.0);
      Future.delayed(const Duration(milliseconds: 320), () {
        if (mounted && !_isHolding) {
          AudioHelper().playBalloonRelief();
        }
      });
    } else {
      // Simple touch/tap without drag: Stay strictly in place, no jump!
      _dragOffset = Offset.zero;
      _snapBackAnimation = null;
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted && !_isHolding) {
          setState(() {
            _isScared = false;
          });
          AudioHelper().playBalloonRelief();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant BalloonCharacterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.balloonsRemaining < oldWidget.balloonsRemaining) {
      final poppedIndex = oldWidget.balloonsRemaining - 1;
      if (poppedIndex >= 0 && poppedIndex < _balloonDefs.length) {
        _spawnPopBurst(_balloonDefs[poppedIndex]);
      }
    }

    // When 0 balloons remain -> Trigger dramatic straight plunge off-screen!
    if (widget.balloonsRemaining <= 0 && !_isFalling) {
      _isFalling = true;
      _isHolding = false;
      AudioHelper().playBalloonFall();
      // Brief 120ms comedic pause, then plummet straight down fast!
      Future.delayed(const Duration(milliseconds: 120), () {
        if (mounted && widget.balloonsRemaining <= 0) {
          _fallController.forward(from: 0.0);
        }
      });
    } else if (widget.balloonsRemaining > 0 && _isFalling) {
      // Extra life restored
      _isFalling = false;
      _fallController.reset();
    }

    // When victory triggered -> Glorious lift-off into the sky!
    if (widget.expression == 'win' && !_isTakingOff) {
      _isTakingOff = true;
      _isHolding = false;
      AudioHelper().playBalloonWoohoo();
      _takeOffController.forward(from: 0.0);
    } else if (widget.expression != 'win' && _isTakingOff) {
      _isTakingOff = false;
      _takeOffController.reset();
    }
  }

  void _spawnPopBurst(_BalloonDef def) {
    AudioHelper().playBalloonBurst();
    final rand = math.Random();
    _burstParticles.clear();
    const widgetSize = 240.0;
    final originX = widgetSize * def.normalizedPos.dx;
    final originY = widgetSize * def.normalizedPos.dy;

    for (int i = 0; i < 24; i++) {
      final angle = rand.nextDouble() * 2 * math.pi;
      final speed = rand.nextDouble() * 5.5 + 2.5;
      _burstParticles.add(
        _BalloonDebrisParticle(
          x: originX,
          y: originY,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed,
          color: i % 2 == 0 ? def.color : def.highlight,
          radius: rand.nextDouble() * 3.5 + 2.0,
        ),
      );
    }

    _burstController.forward(from: 0.0).then((_) {
      widget.onPopComplete?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _bobController,
        _fallController,
        _takeOffController,
        _trembleController,
        _snapBackController,
      ]),
      builder: (context, _) {
        final bobY =
            _isFalling ? 0.0 : math.sin(_bobController.value * math.pi) * 6.0;
        final weightDrop =
            _isFalling ? 0.0 : (5 - widget.balloonsRemaining) * 7.0;
        // Gravity drop: plummets straight down 950px past the screen bottom
        final fallY = _fallAnimation.value * 950.0;
        // Celebratory Lift-Off: shoots 950px up off the screen on win!
        final takeOffY = _takeOffAnimation.value * -950.0;

        // Current interactive offset (either finger drag or elastic spring return)
        final activeOffset = _isHolding
            ? _dragOffset
            : (_snapBackAnimation?.value ?? Offset.zero);

        // While being held: subtle horizontal shivering tremble only (NO vertical jump!)
        final trembleX = _isHolding
            ? math.sin(_trembleController.value * math.pi * 2) * 2.2
            : 0.0;
        final trembleY = 0.0;

        // Dynamic tilt based on drag direction & spring inertia
        final tiltAngle = (activeOffset.dx / 160.0).clamp(-0.25, 0.25);
        final balloonWobble = (activeOffset.dx / 25.0).clamp(-1.0, 1.0);

        final currentExpression = _isFalling
            ? 'defeat'
            : ((_isHolding || _isScared) ? 'shocked' : widget.expression);

        return GestureDetector(
          onPanStart: (details) => _onDragStart(details.localPosition),
          onPanUpdate: (details) => _onDragUpdate(details.delta),
          onPanEnd: (_) => _onDragRelease(),
          onPanCancel: () => _onDragRelease(),
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: 240,
            height: 250,
            child: Transform.translate(
              offset: activeOffset,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // 1. Balloon Strings & Floating Balloons (Layered behind the boy)
                  if (widget.balloonsRemaining > 0)
                    Positioned(
                      top: bobY + weightDrop + takeOffY,
                      left: 0,
                      right: 0,
                      child: Transform.rotate(
                        angle: tiltAngle,
                        alignment: Alignment.bottomCenter,
                        child: CustomPaint(
                          size: const Size(240, 240),
                          painter: _BalloonStringsPainter(
                            balloonsRemaining: widget.balloonsRemaining,
                            balloonDefs: _balloonDefs,
                            bobProgress: _bobController.value,
                            scaredWobble: balloonWobble,
                          ),
                        ),
                      ),
                    ),

                  // 2. Popping Particles Explosion
                  if (_burstController.isAnimating)
                    Positioned(
                      top: bobY + weightDrop + takeOffY,
                      left: 0,
                      right: 0,
                      child: CustomPaint(
                        size: const Size(240, 240),
                        painter: _BurstPainter(particles: _burstParticles),
                      ),
                    ),

                  // 3. The Realistic Animated Mascot Boy Character
                  Positioned(
                    top: 130 + bobY + weightDrop + fallY + takeOffY,
                    child: Transform.translate(
                      offset: Offset(trembleX, trembleY),
                      child: SizedBox(
                        width: 100,
                        height: 130,
                        child: CustomPaint(
                          painter: _BoyMascotPainter(
                            expression: currentExpression,
                            isFalling: _isFalling,
                            fallProgress: _fallAnimation.value,
                            bobProgress: _bobController.value,
                          ),
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

class _BalloonDef {
  final int id;
  final Color color;
  final Color highlight;
  final Offset normalizedPos;
  final double radius;

  const _BalloonDef({
    required this.id,
    required this.color,
    required this.highlight,
    required this.normalizedPos,
    required this.radius,
  });
}

class _BalloonStringsPainter extends CustomPainter {
  final int balloonsRemaining;
  final List<_BalloonDef> balloonDefs;
  final double bobProgress;
  final double scaredWobble;

  _BalloonStringsPainter({
    required this.balloonsRemaining,
    required this.balloonDefs,
    required this.bobProgress,
    this.scaredWobble = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Strings converge directly at the boy's upraised hands (x = 120, y = 140)
    final handPos = Offset(size.width * 0.5, size.height * 0.58);

    final stringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    // Draw active strings and balloons
    for (int i = 0; i < balloonsRemaining; i++) {
      final def = balloonDefs[i];
      final sway = math.sin(bobProgress * 2 * math.pi + i) * 3.5 +
          scaredWobble * 14.0 * (i % 2 == 0 ? 1.0 : -1.0);
      final balloonCenter = Offset(
        size.width * def.normalizedPos.dx + sway,
        size.height * def.normalizedPos.dy,
      );

      // String line curving gracefully to hands
      final path = Path()
        ..moveTo(balloonCenter.dx, balloonCenter.dy + def.radius * 1.15)
        ..quadraticBezierTo(
          (balloonCenter.dx + handPos.dx) / 2 +
              (def.normalizedPos.dx - 0.5) * 16,
          (balloonCenter.dy + handPos.dy) / 2,
          handPos.dx,
          handPos.dy,
        );
      canvas.drawPath(path, stringPaint);

      // Balloon Body (Glossy 3D Oval)
      final rect = Rect.fromCenter(
        center: balloonCenter,
        width: def.radius * 2.0,
        height: def.radius * 2.35,
      );

      final bodyPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 0.95,
          colors: [
            Colors.white.withValues(alpha: 0.95),
            def.highlight,
            def.color,
            def.color.withValues(alpha: 0.85),
          ],
          stops: const [0.0, 0.25, 0.75, 1.0],
        ).createShader(rect);

      canvas.drawOval(rect, bodyPaint);

      // Balloon Knot
      final knot = Path()
        ..moveTo(balloonCenter.dx - 3, balloonCenter.dy + def.radius * 1.15)
        ..lineTo(balloonCenter.dx + 3, balloonCenter.dy + def.radius * 1.15)
        ..lineTo(balloonCenter.dx, balloonCenter.dy + def.radius * 1.15 + 4)
        ..close();
      canvas.drawPath(knot, Paint()..color = def.color);

      // Specular highlight
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(
            balloonCenter.dx - def.radius * 0.35,
            balloonCenter.dy - def.radius * 0.45,
          ),
          width: def.radius * 0.45,
          height: def.radius * 0.24,
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.7),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BalloonStringsPainter oldDelegate) =>
      oldDelegate.balloonsRemaining != balloonsRemaining ||
      oldDelegate.bobProgress != bobProgress ||
      oldDelegate.scaredWobble != scaredWobble;
}

class _BalloonDebrisParticle {
  double x;
  double y;
  double vx;
  double vy;
  Color color;
  double radius;
  double opacity = 1.0;

  _BalloonDebrisParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.radius,
  });

  void update() {
    x += vx;
    y += vy;
    vy += 0.25; // gravity
    opacity = (opacity - 0.035).clamp(0.0, 1.0);
  }
}

class _BurstPainter extends CustomPainter {
  final List<_BalloonDebrisParticle> particles;

  _BurstPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      if (p.opacity <= 0) continue;
      final paint = Paint()
        ..color = p.color.withValues(alpha: p.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(p.x, p.y), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) => true;
}

/// Rich, realistic vector illustration of the Mascot Boy character
class _BoyMascotPainter extends CustomPainter {
  final String expression; // 'idle', 'happy', 'shocked', 'win', 'defeat'
  final bool isFalling;
  final double fallProgress;
  final double bobProgress;

  _BoyMascotPainter({
    required this.expression,
    required this.isFalling,
    required this.fallProgress,
    required this.bobProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2; // 50.0

    // 0. Vertical speed/wind lines rushing upwards when falling
    if (isFalling) {
      final windPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.65)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      final speeds = [-35.0, -20.0, -5.0, 12.0, 26.0, 38.0];
      for (int i = 0; i < speeds.length; i++) {
        final lineX = cx + speeds[i];
        final startY = -15.0 - (i % 3) * 18.0;
        final endY = startY - 45.0;
        canvas.drawLine(Offset(lineX, startY), Offset(lineX, endY), windPaint);
      }
    }

    // 1. Dangling Legs & 3D High-top Sneakers
    _drawLegsAndShoes(canvas, cx);

    // 2. Hoodie / Torso
    _drawTorso(canvas, cx);

    // 3. Arm Sleeves (drawn behind head so ears and cheeks are crisp and clear)
    _drawArmSleeves(canvas, cx);

    // 4. Head, Ears, Hair, Cap, Face & Eyebrows (eyebrows cleanly on forehead below cap)
    _drawHeadAndFace(canvas, cx);

    // 5. Hands & Rope Knot (gripping balloon strings right above cap)
    _drawHandsAndKnot(canvas, cx);

    // 6. Tears flying upwards if falling
    if (isFalling) {
      final tearPaint = Paint()..color = const Color(0xFF40C4FF);
      canvas.drawCircle(
          Offset(cx - 16, 26 - fallProgress * 30), 3.2, tearPaint);
      canvas.drawCircle(
          Offset(cx + 18, 22 - fallProgress * 38), 3.8, tearPaint);
      canvas.drawCircle(
          Offset(cx - 22, 10 - fallProgress * 45), 2.5, tearPaint);
      canvas.drawCircle(Offset(cx + 24, 8 - fallProgress * 50), 2.8, tearPaint);
    }
  }

  void _drawArmSleeves(Canvas canvas, double cx) {
    final sleevePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFF8A65), Color(0xFFE64A19)],
      ).createShader(Rect.fromLTWH(cx - 35, 0, 70, 80))
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = const Color(0xFFBF360C).withValues(alpha: 0.35)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final cuffPaint = Paint()
      ..color = const Color(0xFFFFCC80)
      ..style = PaintingStyle.fill;

    if (!isFalling) {
      // Normal state: Arms curve outward from hoodie shoulders, elbows beside ears
      // Left arm sleeve
      final leftSleeve = Path()
        ..moveTo(cx - 16, 72)
        ..lineTo(cx - 22, 68)
        ..quadraticBezierTo(cx - 34, 44, cx - 15, 14)
        ..lineTo(cx - 9, 16)
        ..quadraticBezierTo(cx - 25, 44, cx - 12, 73)
        ..close();
      canvas.drawPath(leftSleeve, sleevePaint);
      canvas.drawPath(leftSleeve, outlinePaint);

      // Left wrist cuff
      canvas.save();
      canvas.translate(cx - 12, 15);
      canvas.rotate(0.5);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-4.5, -2.5, 9, 5), const Radius.circular(2)),
        cuffPaint,
      );
      canvas.restore();

      // Right arm sleeve
      final rightSleeve = Path()
        ..moveTo(cx + 16, 72)
        ..lineTo(cx + 22, 68)
        ..quadraticBezierTo(cx + 34, 44, cx + 15, 14)
        ..lineTo(cx + 9, 16)
        ..quadraticBezierTo(cx + 25, 44, cx + 12, 73)
        ..close();
      canvas.drawPath(rightSleeve, sleevePaint);
      canvas.drawPath(rightSleeve, outlinePaint);

      // Right wrist cuff
      canvas.save();
      canvas.translate(cx + 12, 15);
      canvas.rotate(-0.5);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-4.5, -2.5, 9, 5), const Radius.circular(2)),
        cuffPaint,
      );
      canvas.restore();
    } else {
      // Falling state: Arms flailing straight UP and OUT in panic!
      final leftArm = Path()
        ..moveTo(cx - 15, 72)
        ..lineTo(cx - 22, 68)
        ..lineTo(cx - 32, 2)
        ..lineTo(cx - 24, 0)
        ..close();
      canvas.drawPath(leftArm, sleevePaint);
      canvas.drawPath(leftArm, outlinePaint);

      final rightArm = Path()
        ..moveTo(cx + 15, 72)
        ..lineTo(cx + 22, 68)
        ..lineTo(cx + 32, 2)
        ..lineTo(cx + 24, 0)
        ..close();
      canvas.drawPath(rightArm, sleevePaint);
      canvas.drawPath(rightArm, outlinePaint);
    }
  }

  void _drawHandsAndKnot(Canvas canvas, double cx) {
    final handPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFF8E1), Color(0xFFFFB74D)],
      ).createShader(Rect.fromLTWH(cx - 20, 0, 40, 25))
      ..style = PaintingStyle.fill;

    if (!isFalling) {
      // Rope knot connector where balloon strings meet (Y = 9.2)
      final ropeKnotPaint = Paint()..color = const Color(0xFFD7CCC8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, 9.2), width: 10, height: 6),
          const Radius.circular(3),
        ),
        ropeKnotPaint,
      );
      final ringPaint = Paint()
        ..color = const Color(0xFF8D6E63)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(Offset(cx, 9.2), 3.5, ringPaint);

      // Hands gripping the knot together
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx - 6, 9.2), width: 10, height: 9),
        handPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx - 2, 9.2), width: 5.5, height: 5),
        handPaint,
      );

      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx + 6, 9.2), width: 10, height: 9),
        handPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx + 2, 9.2), width: 5.5, height: 5),
        handPaint,
      );

      final handOutline = Paint()
        ..color = const Color(0xFFE65100).withValues(alpha: 0.35)
        ..strokeWidth = 0.9
        ..style = PaintingStyle.stroke;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx - 6, 9.2), width: 10, height: 9),
        handOutline,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx + 6, 9.2), width: 10, height: 9),
        handOutline,
      );
    } else {
      // Splayed panic hands when falling
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx - 28, -2), width: 14, height: 14),
        handPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx + 28, -2), width: 14, height: 14),
        handPaint,
      );
    }
  }

  void _drawLegsAndShoes(Canvas canvas, double cx) {
    final legSway = isFalling ? 0.0 : math.sin(bobProgress * 2 * math.pi) * 2.0;

    final jeansPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1976D2), Color(0xFF0D47A1)],
      ).createShader(const Rect.fromLTWH(30, 92, 40, 25));

    final cuffPaint = Paint()..color = const Color(0xFF90CAF9);

    // Left leg
    final leftLegRect = Rect.fromLTWH(cx - 16 + legSway, 92, 12, 19);
    canvas.drawRRect(
        RRect.fromRectAndRadius(leftLegRect, const Radius.circular(4)),
        jeansPaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(cx - 16 + legSway, 107, 12, 4),
            const Radius.circular(2)),
        cuffPaint);

    // Right leg
    final rightLegRect = Rect.fromLTWH(cx + 4 - legSway, 92, 12, 19);
    canvas.drawRRect(
        RRect.fromRectAndRadius(rightLegRect, const Radius.circular(4)),
        jeansPaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(cx + 4 - legSway, 107, 12, 4),
            const Radius.circular(2)),
        cuffPaint);

    // 3D Sneakers
    _drawSneaker(canvas, Offset(cx - 11 + legSway, 116), isLeft: true);
    _drawSneaker(canvas, Offset(cx + 11 - legSway, 116), isLeft: false);
  }

  void _drawSneaker(Canvas canvas, Offset center, {required bool isLeft}) {
    final shoeRect = Rect.fromCenter(center: center, width: 17, height: 12);

    // Red canvas upper
    final redPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF5252), Color(0xFFD32F2F)],
      ).createShader(shoeRect);
    canvas.drawRRect(
        RRect.fromRectAndRadius(shoeRect, const Radius.circular(5)), redPaint);

    // White rubber toe bumper
    final toeRect = Rect.fromLTWH(
      isLeft ? shoeRect.left - 2 : shoeRect.right - 5,
      shoeRect.top + 2,
      7,
      8,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(toeRect, const Radius.circular(4)),
        Paint()..color = Colors.white);

    // White thick rubber sole with tread line
    final soleRect = Rect.fromLTWH(
        shoeRect.left - 2, shoeRect.bottom - 4, shoeRect.width + 4, 5);
    canvas.drawRRect(
        RRect.fromRectAndRadius(soleRect, const Radius.circular(2.5)),
        Paint()..color = Colors.white);

    // Tread stripe
    final treadPaint = Paint()
      ..color = const Color(0xFF424242)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(soleRect.left + 2, soleRect.center.dy),
      Offset(soleRect.right - 2, soleRect.center.dy),
      treadPaint,
    );

    // Laces
    final lacePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(center.dx - 3, center.dy - 2),
        Offset(center.dx + 3, center.dy - 2), lacePaint);
    canvas.drawLine(Offset(center.dx - 2, center.dy + 1),
        Offset(center.dx + 2, center.dy + 1), lacePaint);
  }

  void _drawTorso(Canvas canvas, double cx) {
    // 3D Sunset Orange Hoodie
    final torsoRect = Rect.fromLTWH(cx - 21, 66, 42, 30);
    final hoodiePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFF7043), Color(0xFFD84315)],
      ).createShader(torsoRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(torsoRect, const Radius.circular(11)),
      hoodiePaint,
    );

    // Subtle edge highlight
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(torsoRect, const Radius.circular(11)),
      borderPaint,
    );

    // Kangaroo front pocket
    final pocketPaint = Paint()
      ..color = const Color(0xFFBF360C).withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    final pocketRect = Rect.fromLTWH(cx - 14, 80, 28, 12);
    canvas.drawRRect(
        RRect.fromRectAndRadius(pocketRect, const Radius.circular(4)),
        pocketPaint);

    // White drawstring cords
    final cordPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx - 5, 68), Offset(cx - 5, 78), cordPaint);
    canvas.drawLine(Offset(cx + 5, 68), Offset(cx + 5, 78), cordPaint);

    // Folded collar around neck
    final collarPaint = Paint()
      ..color = const Color(0xFFFFAB91)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, 65), width: 22, height: 8),
      collarPaint,
    );
  }

  void _drawHeadAndFace(Canvas canvas, double cx) {
    // Neck
    canvas.drawRect(
      Rect.fromLTWH(cx - 6, 58, 12, 9),
      Paint()..color = const Color(0xFFFFB74D),
    );

    // Ears
    final earPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFE0B2), Color(0xFFFFB74D)],
      ).createShader(const Rect.fromLTWH(20, 36, 60, 16));
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx - 24, 42), width: 10, height: 12),
        earPaint);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx + 24, 42), width: 10, height: 12),
        earPaint);

    // Inner ear shadows
    final innerEarPaint = Paint()
      ..color = const Color(0xFFFF8A80).withValues(alpha: 0.5);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx - 24, 42), width: 5, height: 7),
        innerEarPaint);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx + 24, 42), width: 5, height: 7),
        innerEarPaint);

    // Head base (Cute chibi rounded shape with soft skin gradient)
    final headRect =
        Rect.fromCenter(center: Offset(cx, 40), width: 48, height: 46);
    final skinPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0.0, -0.2),
        radius: 0.9,
        colors: [Color(0xFFFFF8E1), Color(0xFFFFE0B2), Color(0xFFFFCC80)],
        stops: [0.0, 0.65, 1.0],
      ).createShader(headRect);

    canvas.drawOval(headRect, skinPaint);

    // Soft Rosy Cheeks (Blush)
    final blushPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFF8A80).withValues(alpha: 0.55),
          Colors.transparent
        ],
      ).createShader( Rect.fromLTWH(cx - 20, 42, 40, 14));
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx - 14, 46), width: 11, height: 7),
        blushPaint);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx + 14, 46), width: 11, height: 7),
        blushPaint);

    // 3D Baseball Cap (Sporty Cobalt & Navy snapback) sitting higher at Y = 12..25
    final capRect = Rect.fromLTWH(cx - 23, 12, 46, 15);
    final capPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF039BE5), Color(0xFF0277BD), Color(0xFF01579B)],
      ).createShader(capRect);

    canvas.drawRRect(
      RRect.fromRectAndCorners(
        capRect,
        topLeft: const Radius.circular(22),
        topRight: const Radius.circular(22),
        bottomLeft: const Radius.circular(4),
        bottomRight: const Radius.circular(4),
      ),
      capPaint,
    );

    // Cap crown top button
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, 12), width: 7, height: 4),
      Paint()..color = const Color(0xFF00E5FF),
    );

    // Cap 3D Visor (Brim) sitting at Y = 24..28
    final visorPath = Path()
      ..moveTo(cx - 24, 24)
      ..quadraticBezierTo(cx, 27, cx + 24, 24)
      ..lineTo(cx + 23, 26)
      ..quadraticBezierTo(cx, 29, cx - 23, 26)
      ..close();
    final visorPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0288D1), Color(0xFF01579B)],
      ).createShader(Rect.fromLTWH(cx - 25, 24, 50, 7));
    canvas.drawPath(visorPath, visorPaint);

    // Visor edge highlight
    final visorHighlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(visorPath, visorHighlight);

    // Chestnut Brown Hair bangs peeking naturally under the cap visor
    final hairPaint = Paint()..color = const Color(0xFF4E342E);
    final hairPath = Path()
      ..moveTo(cx - 22, 27)
      ..quadraticBezierTo(cx - 15, 31, cx - 10, 27)
      ..quadraticBezierTo(cx - 4, 32, cx + 2, 26)
      ..quadraticBezierTo(cx + 10, 32, cx + 18, 26)
      ..quadraticBezierTo(cx + 22, 29, cx + 24, 26)
      ..lineTo(cx + 22, 22)
      ..lineTo(cx - 22, 22)
      ..close();
    canvas.drawPath(hairPath, hairPaint);

    // Nose
    final nosePaint = Paint()
      ..color = const Color(0xFFD84315).withValues(alpha: 0.6)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, 45), width: 3.5, height: 2.5),
      0,
      math.pi,
      false,
      nosePaint,
    );

    // Eyebrows (Positioned cleanly on forehead skin at Y = 35, well below the cap!)
    _drawEyebrows(canvas, cx);

    // Eyes
    _drawEyes(canvas, cx);

    // Mouth
    _drawMouth(canvas, cx);
  }

  void _drawEyebrows(Canvas canvas, double cx) {
    final browPaint = Paint()
      ..color = const Color(0xFF3E2723)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (expression == 'shocked') {
      // Raised high in surprise
      canvas.drawLine(Offset(cx - 15, 33), Offset(cx - 5, 32), browPaint);
      canvas.drawLine(Offset(cx + 5, 32), Offset(cx + 15, 33), browPaint);
    } else if (expression == 'defeat' || isFalling) {
      // Slanted inward in sadness/panic (/ \)
      canvas.drawLine(Offset(cx - 15, 36), Offset(cx - 5, 33), browPaint);
      canvas.drawLine(Offset(cx + 5, 33), Offset(cx + 15, 36), browPaint);
    } else {
      // Friendly arched eyebrows sitting naturally on the forehead
      canvas.drawArc(
        Rect.fromCenter(center: Offset(cx - 10, 35), width: 9, height: 4),
        math.pi * 1.1,
        math.pi * 0.8,
        false,
        browPaint,
      );
      canvas.drawArc(
        Rect.fromCenter(center: Offset(cx + 10, 35), width: 9, height: 4),
        math.pi * 1.1,
        math.pi * 0.8,
        false,
        browPaint,
      );
    }
  }

  void _drawEyes(Canvas canvas, double cx) {
    if (expression == 'happy' || expression == 'win') {
      // Cheerful laughing eye crescents (^ ^)
      final happyEyePaint = Paint()
        ..color = const Color(0xFF263238)
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawArc(
        Rect.fromCenter(center: Offset(cx - 10, 42), width: 11, height: 9),
        math.pi * 1.15,
        math.pi * 0.7,
        false,
        happyEyePaint,
      );
      canvas.drawArc(
        Rect.fromCenter(center: Offset(cx + 10, 42), width: 11, height: 9),
        math.pi * 1.15,
        math.pi * 0.7,
        false,
        happyEyePaint,
      );
    } else if (expression == 'shocked') {
      // Big wide white eyes with small shaking dark pupils
      final whitePaint = Paint()..color = Colors.white;
      final borderPaint = Paint()
        ..color = const Color(0xFF263238)
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke;

      canvas.drawOval(
          Rect.fromCenter(center: Offset(cx - 10, 42), width: 13, height: 13),
          whitePaint);
      canvas.drawOval(
          Rect.fromCenter(center: Offset(cx - 10, 42), width: 13, height: 13),
          borderPaint);

      canvas.drawOval(
          Rect.fromCenter(center: Offset(cx + 10, 42), width: 13, height: 13),
          whitePaint);
      canvas.drawOval(
          Rect.fromCenter(center: Offset(cx + 10, 42), width: 13, height: 13),
          borderPaint);

      // Trembling pupils
      canvas.drawCircle(
          Offset(cx - 10, 42), 2.2, Paint()..color = Colors.black);
      canvas.drawCircle(
          Offset(cx + 10, 42), 2.2, Paint()..color = Colors.black);

      // Blue sweat drop on temple
      final sweatPaint = Paint()..color = const Color(0xFF00E5FF);
      canvas.drawOval(
          Rect.fromCenter(center: Offset(cx + 19, 32), width: 4.5, height: 7),
          sweatPaint);
    } else if (expression == 'defeat' || isFalling) {
      // Crying wide panic eyes
      final whitePaint = Paint()..color = Colors.white;
      canvas.drawOval(
          Rect.fromCenter(center: Offset(cx - 10, 42), width: 13, height: 13),
          whitePaint);
      canvas.drawOval(
          Rect.fromCenter(center: Offset(cx + 10, 42), width: 13, height: 13),
          whitePaint);

      // Pupils
      canvas.drawCircle(
          Offset(cx - 10, 43), 2.5, Paint()..color = Colors.black);
      canvas.drawCircle(
          Offset(cx + 10, 43), 2.5, Paint()..color = Colors.black);

      // Tear streaks
      final tearPaint = Paint()
        ..color = const Color(0xFF40C4FF)
        ..strokeWidth = 2.0;
      canvas.drawLine(Offset(cx - 10, 45), Offset(cx - 11, 53), tearPaint);
      canvas.drawLine(Offset(cx + 10, 45), Offset(cx + 11, 53), tearPaint);
    } else {
      // Idle: Gorgeous big anime/cartoon sparkly eyes!
      _drawSparkleEye(canvas, Offset(cx - 10, 42));
      _drawSparkleEye(canvas, Offset(cx + 10, 42));
    }
  }

  void _drawSparkleEye(Canvas canvas, Offset center) {
    // Sclera
    final scleraRect = Rect.fromCenter(center: center, width: 11, height: 13);
    canvas.drawRRect(
        RRect.fromRectAndRadius(scleraRect, const Radius.circular(5.5)),
        Paint()..color = Colors.white);

    // Deep rich Iris
    final irisRect = Rect.fromCenter(
        center: Offset(center.dx, center.dy + 0.5), width: 8.5, height: 10);
    final irisPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF004D40), Color(0xFF00ACC1), Color(0xFF80DEEA)],
      ).createShader(irisRect);
    canvas.drawRRect(
        RRect.fromRectAndRadius(irisRect, const Radius.circular(4)), irisPaint);

    // Dark Pupil
    canvas.drawCircle(Offset(center.dx, center.dy + 0.5), 2.6,
        Paint()..color = const Color(0xFF002228));

    // Big top-left shine reflection
    canvas.drawCircle(Offset(center.dx - 1.8, center.dy - 1.8), 1.7,
        Paint()..color = Colors.white);

    // Small bottom-right sparkle
    canvas.drawCircle(Offset(center.dx + 1.6, center.dy + 2.0), 0.9,
        Paint()..color = Colors.white);

    // Soft delicate eye boundary (no harsh straight eyeliner line!)
    canvas.drawRRect(
      RRect.fromRectAndRadius(scleraRect, const Radius.circular(5.5)),
      Paint()
        ..color = const Color(0xFF263238).withValues(alpha: 0.22)
        ..strokeWidth = 0.9
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawMouth(Canvas canvas, double cx) {
    if (expression == 'happy' || expression == 'win') {
      // Big open cheerful laughing mouth with teeth & tongue
      final mouthPath = Path()
        ..moveTo(cx - 7, 49)
        ..quadraticBezierTo(cx, 58, cx + 7, 49)
        ..close();
      canvas.drawPath(mouthPath, Paint()..color = const Color(0xFF880E4F));

      // White teeth
      final teethRect = Rect.fromLTWH(cx - 5, 49, 10, 3);
      canvas.drawRRect(
          RRect.fromRectAndRadius(teethRect, const Radius.circular(1.5)),
          Paint()..color = Colors.white);

      // Pink tongue
      final tonguePath = Path()
        ..moveTo(cx - 4, 55)
        ..quadraticBezierTo(cx, 51, cx + 4, 55)
        ..close();
      canvas.drawPath(tonguePath, Paint()..color = const Color(0xFFFF4081));
    } else if (expression == 'shocked') {
      // Surprised small 'O' mouth
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, 50.5), width: 6, height: 7.5),
        Paint()..color = const Color(0xFF3E2723),
      );
    } else if (expression == 'defeat' || isFalling) {
      // Screaming panic open mouth (D:)
      final screamPath = Path()
        ..moveTo(cx - 8, 49)
        ..lineTo(cx + 8, 49)
        ..quadraticBezierTo(cx, 60, cx - 8, 49)
        ..close();
      canvas.drawPath(screamPath, Paint()..color = const Color(0xFFB71C1C));

      // White trembling teeth
      canvas.drawRect(
          Rect.fromLTWH(cx - 6, 49, 12, 2.5), Paint()..color = Colors.white);
    } else {
      // Cheerful friendly smile curve
      final smilePaint = Paint()
        ..color = const Color(0xFF3E2723)
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final smilePath = Path()
        ..moveTo(cx - 6, 49)
        ..quadraticBezierTo(cx, 53, cx + 6, 49);
      canvas.drawPath(smilePath, smilePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BoyMascotPainter oldDelegate) =>
      oldDelegate.expression != expression ||
      oldDelegate.isFalling != isFalling ||
      oldDelegate.fallProgress != fallProgress ||
      oldDelegate.bobProgress != bobProgress;
}
