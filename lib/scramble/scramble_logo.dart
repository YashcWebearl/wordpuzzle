import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 3D Animated Logo for WORD SCRAMBLE
/// Features 3D tactile candy blocks for "WORD SCRAMBLE" (bouncy dual-tier tiles),
/// adorable Kitty Mascot with glowing halo, cosmic nebula glassmorphic disc,
/// magical sparkles (✨, ⭐), and gentle floating animation.
class ScrambleLogo extends StatefulWidget {
  final double size;
  final bool animate;

  const ScrambleLogo({
    super.key,
    this.size = 200,
    this.animate = true,
  });

  @override
  State<ScrambleLogo> createState() => _ScrambleLogoState();
}

class _ScrambleLogoState extends State<ScrambleLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _floatAnimation = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    if (widget.animate) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale:
          widget.animate ? _scaleAnimation : const AlwaysStoppedAnimation(1.0),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: FittedBox(
          fit: BoxFit.contain,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFD500F9).withValues(alpha: 0.35),
                  const Color(0xFF6A1B9A).withValues(alpha: 0.20),
                  Colors.transparent,
                ],
                radius: 0.85,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer Ambient Glowing Ring
                Container(
                  width: widget.size * 0.94,
                  height: widget.size * 0.94,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE040FB).withValues(alpha: 0.25),
                      width: 1.8,
                    ),
                  ),
                ),

                // Glassmorphic Cosmic Disc
                Container(
                  width: widget.size * 0.88,
                  height: widget.size * 0.88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      center: Alignment(0, -0.2),
                      radius: 0.9,
                      colors: [
                        Color(0xFF2A0A45),
                        Color(0xFF160424),
                        Color(0xFF0D0216),
                      ],
                    ),
                    border: Border.all(
                      color: const Color(0xFFEA80FC).withValues(alpha: 0.45),
                      width: 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD500F9).withValues(alpha: 0.35),
                        blurRadius: 28,
                        spreadRadius: 3,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.65),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                ),

                // Top-right magical sparkle ✨
                Positioned(
                  top: widget.size * 0.12,
                  right: widget.size * 0.14,
                  child: const Text(
                    '✨',
                    style: TextStyle(fontSize: 16),
                  ),
                ),

                // Bottom-left playful star ⭐
                Positioned(
                  bottom: widget.size * 0.14,
                  left: widget.size * 0.12,
                  child: const Text(
                    '⭐',
                    style: TextStyle(fontSize: 14),
                  ),
                ),

                // Floating Mascot + 3D Letter Blocks Stack
                AnimatedBuilder(
                  animation: _floatAnimation,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(0, _floatAnimation.value),
                    child: child,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Cute Kitty Mascot Badge with glowing aura
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFE040FB),
                              Color(0xFF7C4DFF),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.85),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD500F9)
                                  .withValues(alpha: 0.55),
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Text(
                          '🐱',
                          style: TextStyle(fontSize: widget.size * 0.22),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Row 1: W - O - R - D
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _build3DBlock(
                            'W',
                            const Color(0xFFE040FB),
                            const Color(0xFF8E24AA),
                            -3.5,
                            isLarge: true,
                          ),
                          _build3DBlock(
                            'O',
                            const Color(0xFF00E5FF),
                            const Color(0xFF0091EA),
                            2.0,
                            isLarge: true,
                          ),
                          _build3DBlock(
                            'R',
                            const Color(0xFFFFD600),
                            const Color(0xFFFF8F00),
                            -2.0,
                            isLarge: true,
                          ),
                          _build3DBlock(
                            'D',
                            const Color(0xFF00E676),
                            const Color(0xFF00A859),
                            3.5,
                            isLarge: true,
                          ),
                        ],
                      ),

                      const SizedBox(height: 5),

                      // Row 2: S - C - R - A - M - B - L - E
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _build3DBlock(
                            'S',
                            const Color(0xFFAB47BC),
                            const Color(0xFF4A148C),
                            2.5,
                          ),
                          _build3DBlock(
                            'C',
                            const Color(0xFF29B6F6),
                            const Color(0xFF0277BD),
                            -2.0,
                          ),
                          _build3DBlock(
                            'R',
                            const Color(0xFFFF4081),
                            const Color(0xFFC2185B),
                            3.0,
                          ),
                          _build3DBlock(
                            'A',
                            const Color(0xFF00E676),
                            const Color(0xFF00A859),
                            -2.0,
                          ),
                          _build3DBlock(
                            'M',
                            const Color(0xFFFFD54F),
                            const Color(0xFFFFA000),
                            2.0,
                          ),
                          _build3DBlock(
                            'B',
                            const Color(0xFF7C4DFF),
                            const Color(0xFF4527A0),
                            -3.0,
                          ),
                          _build3DBlock(
                            'L',
                            const Color(0xFFFF7043),
                            const Color(0xFFD84315),
                            2.0,
                          ),
                          _build3DBlock(
                            'E',
                            const Color(0xFFE040FB),
                            const Color(0xFF8E24AA),
                            -2.5,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _build3DBlock(
    String char,
    Color baseColor,
    Color shadowColor,
    double rotateAngleDeg, {
    bool isLarge = false,
  }) {
    // Large tiles for WORD (4 tiles across), compact tiles for SCRAMBLE (8 tiles across)
    final double blockSize =
        isLarge ? widget.size * 0.125 : widget.size * 0.088;
    final double depth = isLarge ? 3.0 : 2.2;

    return Transform.rotate(
      angle: rotateAngleDeg * (math.pi / 180),
      child: Container(
        width: blockSize,
        height: blockSize,
        margin: EdgeInsets.symmetric(horizontal: isLarge ? 2.5 : 1.2),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              baseColor,
              baseColor.withValues(alpha: 0.88),
            ],
          ),
          borderRadius: BorderRadius.circular(blockSize * 0.28),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.85),
            width: isLarge ? 1.4 : 1.1,
          ),
          boxShadow: [
            // 3D bottom drop bevel
            BoxShadow(
              color: shadowColor,
              offset: Offset(0, depth),
              blurRadius: 0,
            ),
            // Soft colored ambient glow
            BoxShadow(
              color: baseColor.withValues(alpha: 0.5),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Top-left gloss sheen reflection
            Positioned(
              top: 2,
              left: 2,
              child: Container(
                width: blockSize * 0.5,
                height: blockSize * 0.22,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(blockSize * 0.14),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.55),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

            // Letter character
            Text(
              char,
              style: GoogleFonts.fredoka(
                fontSize: isLarge ? blockSize * 0.68 : blockSize * 0.64,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    offset: const Offset(0, 1.5),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
