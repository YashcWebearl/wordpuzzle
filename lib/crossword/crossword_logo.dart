import 'package:flutter/material.dart';

/// 3D Crossword Game Logo Widget
/// Renders interlocking 3D tactile crossword tiles in vibrant sunset orange
/// matching the exact tile style from the game reference, with shiny bevels,
/// autumn leaf accents, and gentle breathing animation.
class CrosswordLogo extends StatefulWidget {
  final double size;
  final bool animate;

  const CrosswordLogo({
    super.key,
    this.size = 200,
    this.animate = true,
  });

  @override
  State<CrosswordLogo> createState() => _CrosswordLogoState();
}

class _CrosswordLogoState extends State<CrosswordLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;

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
    // 5 tiles across with 3px spacing between each tile
    // Total width required = 5 * tileSize + 4 * 3.
    // Setting tileSize to size * 0.14 ensures total width is 0.70 * size + 12, well within the disc.
    final double tileSize = widget.size * 0.14;
    const double tileGap = 3.0;

    return ScaleTransition(
      scale: widget.animate ? _scaleAnimation : const AlwaysStoppedAnimation(1.0),
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
                  const Color(0xFFFF9100).withValues(alpha: 0.35),
                  const Color(0xFF2E7D32).withValues(alpha: 0.20),
                  Colors.transparent,
                ],
                radius: 0.75,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Ambient Backdrop Glow Disc
                Container(
                  width: widget.size * 0.92,
                  height: widget.size * 0.92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.45),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6D00).withValues(alpha: 0.35),
                        blurRadius: 28,
                        spreadRadius: 4,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                ),

                // Intersecting 3D Crossword Tiles
                // CROSS (Across): C R O S S
                // WORD (Down intersecting at O):
                //       W
                //   C R O S S
                //       R
                //       D
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top row: W
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(width: tileSize * 2 + tileGap * 2),
                        _build3DTile('W', tileSize, isEmerald: true),
                        SizedBox(width: tileSize * 2 + tileGap * 2),
                      ],
                    ),
                    const SizedBox(height: tileGap),

                    // Middle row: C R O S S
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _build3DTile('C', tileSize),
                        const SizedBox(width: tileGap),
                        _build3DTile('R', tileSize),
                        const SizedBox(width: tileGap),
                        _build3DTile('O', tileSize, isGold: true),
                        const SizedBox(width: tileGap),
                        _build3DTile('S', tileSize),
                        const SizedBox(width: tileGap),
                        _build3DTile('S', tileSize),
                      ],
                    ),
                    const SizedBox(height: tileGap),

                    // Row below: R
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(width: tileSize * 2 + tileGap * 2),
                        _build3DTile('R', tileSize, isEmerald: true),
                        SizedBox(width: tileSize * 2 + tileGap * 2),
                      ],
                    ),
                    const SizedBox(height: tileGap),

                    // Bottom row: D
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(width: tileSize * 2 + tileGap * 2),
                        _build3DTile('D', tileSize, isEmerald: true),
                        SizedBox(width: tileSize * 2 + tileGap * 2),
                      ],
                    ),
                  ],
                ),

                // Autumn Leaf Emblem in Corner (🍁)
                Positioned(
                  right: widget.size * 0.15,
                  top: widget.size * 0.14,
                  child: Transform.rotate(
                    angle: -0.25,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.2),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: const Text('🍁', style: TextStyle(fontSize: 14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _build3DTile(String letter, double size,
      {bool isEmerald = false, bool isGold = false}) {
    final List<Color> gradientColors = isGold
        ? const [Color(0xFFFFD54F), Color(0xFFFF9100)]
        : isEmerald
            ? const [Color(0xFF66BB6A), Color(0xFF2E7D32)]
            : const [Color(0xFFFF7043), Color(0xFFE64A19)];

    final Color shadowColor = isGold
        ? const Color(0xFFE65100)
        : isEmerald
            ? const Color(0xFF1B5E20)
            : const Color(0xFFBF360C);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.24),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.6),
          width: 1.4,
        ),
        boxShadow: [
          // 3D bottom bevel depth
          BoxShadow(
            color: shadowColor,
            offset: const Offset(0, 3.5),
            blurRadius: 0,
          ),
          // Ambient soft glow
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.45),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            color: isGold ? const Color(0xFF201000) : Colors.white,
            fontSize: size * 0.62,
            fontWeight: FontWeight.w900,
            height: 1.0,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.45),
                offset: const Offset(0, 1.5),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
