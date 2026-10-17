import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Unified Ambient Floating Animated Words & Letter Particles Background
/// Displays gently floating and rotating words/letters that give an alive,
/// magical, puzzle-themed atmosphere.
class FloatingWordsBackground extends StatefulWidget {
  final bool isWordix;
  final double opacityMultiplier;
  final AnimationController? controller;
  final Color? baseColor;
  final Color? accentColor;
  final int? particleCount;

  const FloatingWordsBackground({
    super.key,
    this.isWordix = true,
    this.opacityMultiplier = 1.0,
    this.controller,
    this.baseColor,
    this.accentColor,
    this.particleCount,
  });

  @override
  State<FloatingWordsBackground> createState() => _FloatingWordsBackgroundState();
}

class _FloatingWordsBackgroundState extends State<FloatingWordsBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _internalController;
  AnimationController get _effectiveController =>
      widget.controller ?? _internalController;

  static final List<_FloatingParticleData> _particles = [
    _FloatingParticleData(text: 'WORDIX', initialX: 0.10, initialY: 0.15, speed: 0.75, size: 22, rotationSpeed: 0.3, isWord: true),
    _FloatingParticleData(text: 'PUZZLE', initialX: 0.76, initialY: 0.22, speed: 0.60, size: 20, rotationSpeed: -0.4, isWord: true),
    _FloatingParticleData(text: 'SEARCH', initialX: 0.16, initialY: 0.46, speed: 0.85, size: 24, rotationSpeed: 0.5, isWord: true),
    _FloatingParticleData(text: 'QUEST', initialX: 0.82, initialY: 0.52, speed: 0.68, size: 18, rotationSpeed: -0.3, isWord: true),
    _FloatingParticleData(text: 'CROSS', initialX: 0.08, initialY: 0.80, speed: 0.72, size: 22, rotationSpeed: 0.4, isWord: true),
    _FloatingParticleData(text: 'BRAIN', initialX: 0.74, initialY: 0.84, speed: 0.80, size: 20, rotationSpeed: -0.5, isWord: true),
    _FloatingParticleData(text: 'FIND', initialX: 0.44, initialY: 0.08, speed: 0.62, size: 18, rotationSpeed: 0.2, isWord: true),
    _FloatingParticleData(text: 'SOLVE', initialX: 0.48, initialY: 0.90, speed: 0.68, size: 20, rotationSpeed: -0.3, isWord: true),
    _FloatingParticleData(text: 'W', initialX: 0.05, initialY: 0.33, speed: 1.05, size: 28, rotationSpeed: 0.8, isWord: false),
    _FloatingParticleData(text: 'A', initialX: 0.88, initialY: 0.36, speed: 0.95, size: 24, rotationSpeed: -0.6, isWord: false),
    _FloatingParticleData(text: 'P', initialX: 0.33, initialY: 0.28, speed: 0.88, size: 26, rotationSpeed: 0.7, isWord: false),
    _FloatingParticleData(text: 'Z', initialX: 0.64, initialY: 0.38, speed: 1.15, size: 30, rotationSpeed: -0.8, isWord: false),
    _FloatingParticleData(text: 'X', initialX: 0.26, initialY: 0.66, speed: 0.98, size: 28, rotationSpeed: 0.9, isWord: false),
    _FloatingParticleData(text: 'Q', initialX: 0.58, initialY: 0.70, speed: 0.82, size: 26, rotationSpeed: -0.5, isWord: false),
    _FloatingParticleData(text: 'S', initialX: 0.90, initialY: 0.68, speed: 1.05, size: 26, rotationSpeed: 0.6, isWord: false),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 24),
      )..repeat();
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _internalController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color wordBorderColor = widget.baseColor?.withOpacity(0.45) ??
        (widget.isWordix
            ? const Color(0xFF00E5FF).withOpacity(0.45)
            : const Color(0xFFFFB300).withOpacity(0.45));

    final Color wordTextColor = widget.baseColor ??
        (widget.isWordix
            ? const Color(0xFF80DEEA)
            : const Color(0xFFFFD54F));

    final Color tileBorderColor = widget.accentColor?.withOpacity(0.45) ??
        (widget.isWordix
            ? const Color(0xFFFFD54F).withOpacity(0.45)
            : const Color(0xFFFF4081).withOpacity(0.45));

    final Color tileTextColor = widget.accentColor ??
        (widget.isWordix
            ? const Color(0xFFFFE082)
            : const Color(0xFFFF80AB));

    final effectiveParticles = widget.particleCount != null
        ? _particles.take(widget.particleCount!).toList()
        : _particles;

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _effectiveController,
        builder: (context, child) {
          final progress = _effectiveController.value;
          final size = MediaQuery.of(context).size;

          return Stack(
            fit: StackFit.expand,
            children: effectiveParticles.map((p) {
              final double offsetY = ((p.initialY - (progress * p.speed)) % 1.0) * size.height;
              final double waveX = math.sin((progress * 2 * math.pi) + (p.initialX * 10)) * 18;
              final double offsetX = (p.initialX * size.width) + waveX;
              final double rotation = (progress * 2 * math.pi * p.rotationSpeed);

              final double normalizedY = offsetY / size.height;
              final double opacityFade = (normalizedY < 0.1)
                  ? (normalizedY / 0.1)
                  : (normalizedY > 0.9 ? (1.0 - normalizedY) / 0.1 : 1.0);
              final double opacity = (p.isWord ? 0.14 : 0.18) *
                  opacityFade.clamp(0.0, 1.0) *
                  widget.opacityMultiplier;

              return Positioned(
                left: offsetX,
                top: offsetY,
                child: Transform.rotate(
                  angle: rotation,
                  child: Opacity(
                    opacity: opacity,
                    child: p.isWord
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: wordBorderColor,
                                width: 1.2,
                              ),
                            ),
                            child: Text(
                              p.text,
                              style: GoogleFonts.outfit(
                                fontSize: p.size.sp,
                                fontWeight: FontWeight.w900,
                                color: wordTextColor,
                                letterSpacing: 1.8,
                              ),
                            ),
                          )
                        : Container(
                            width: (p.size * 1.3).sp,
                            height: (p.size * 1.3).sp,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: tileBorderColor,
                                width: 1.2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                p.text,
                                style: GoogleFonts.outfit(
                                  fontSize: p.size.sp,
                                  fontWeight: FontWeight.w900,
                                  color: tileTextColor,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _FloatingParticleData {
  final String text;
  final double initialX;
  final double initialY;
  final double speed;
  final double size;
  final double rotationSpeed;
  final bool isWord;

  const _FloatingParticleData({
    required this.text,
    required this.initialX,
    required this.initialY,
    required this.speed,
    required this.size,
    required this.rotationSpeed,
    required this.isWord,
  });
}
