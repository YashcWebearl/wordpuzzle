import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:word_puzzle/widget/sound.dart';

class CustomHintButton extends StatefulWidget {
  final IconData icon;
  final int value;
  final bool showCoin;
  final VoidCallback onPressed;

  const CustomHintButton({
    Key? key,
    required this.icon,
    required this.value,
    this.showCoin = true,
    required this.onPressed,
  }) : super(key: key);

  @override
  State<CustomHintButton> createState() => _CustomHintButtonState();
}

class _CustomHintButtonState extends State<CustomHintButton> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails details) {
    HapticFeedback.lightImpact();
    AudioHelper().playButtonSound();
    setState(() => _isPressed = true);
  }

  void _onTapUp(TapUpDetails details) {
    HapticFeedback.mediumImpact();
    setState(() => _isPressed = false);
    widget.onPressed();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isNarrow = screenWidth < 360;

    final double btnSize = isNarrow ? 42.0 : 48.0;
    final double iconSize = isNarrow ? 18.0 : 22.0;
    final double fontSize = isNarrow ? 10.5 : 12.0;
    final double depth = isNarrow ? 3.0 : 4.0;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        width: btnSize,
        height: btnSize,
        margin: EdgeInsets.only(
          top: _isPressed ? depth : 0.0,
          bottom: _isPressed ? 0.0 : depth,
        ),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFCCFF00), Color(0xFF64DD17)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(
            color: const Color(0xFFDCEDC8),
            width: 1.2,
          ),
          boxShadow: [
            // 3D bottom bevel shadow
            BoxShadow(
              color: const Color(0xFF1B5E20),
              offset: Offset(0, _isPressed ? 1.0 : depth),
              blurRadius: 0.5,
            ),
            // Soft ambient ground shadow
            BoxShadow(
              color: Colors.black.withOpacity(_isPressed ? 0.25 : 0.45),
              offset: Offset(0, _isPressed ? 2.0 : depth + 3),
              blurRadius: _isPressed ? 4 : 8,
              spreadRadius: 0,
            ),
            // Top neon glow
            BoxShadow(
              color: const Color(0xFF76FF03).withOpacity(0.4),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Top glossy glass highlight arc
            Positioned(
              top: 2,
              left: 6,
              right: 6,
              height: btnSize * 0.38,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(btnSize / 2),
                    bottom: const Radius.elliptical(30, 10),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.65),
                      Colors.white.withOpacity(0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // Content (Icon + value)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  color: const Color(0xFF263238),
                  size: iconSize,
                ),
                const SizedBox(height: 1),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.showCoin) ...[
                      Image.asset(
                        'assets/coin.png',
                        width: isNarrow ? 9.5 : 11.5,
                        height: isNarrow ? 9.5 : 11.5,
                      ),
                      const SizedBox(width: 2.5),
                    ],
                    Text(
                      '${widget.value}',
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF1B5E20),
                        fontFamily: 'Inder',
                        height: 1.0,
                        shadows: [
                          Shadow(
                            color: Colors.white.withOpacity(0.6),
                            offset: const Offset(0, 1),
                            blurRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
