import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:word_puzzle/widget/sound.dart';

/// Unified 3D Tactile Game Button for Word Puzzle & Arcade screens.
/// Features physical press-down animation, depth bevel collapse,
/// haptic feedback, colored 3D bevel shadow, neon glow, and integrated click audio.
class App3DButton extends StatefulWidget {
  final String text;
  final Widget? child;
  final IconData? icon;
  final Widget? leading;
  final Widget? trailing;
  final List<Color>? gradientColors;
  final Color? color;
  final Color? topHighlightColor;
  final Color? borderColor;
  final Color textColor;
  final Color? iconColor;
  final Color? shadowColor;
  final Color? glowColor;
  final double? width;
  final double height;
  final double depth;
  final double fontSize;
  final dynamic borderRadius;
  final bool coinBadge;
  final bool isLoading;
  final VoidCallback? onPressed;

  const App3DButton({
    super.key,
    this.text = '',
    this.child,
    this.icon,
    this.leading,
    this.trailing,
    this.gradientColors,
    this.color,
    this.topHighlightColor,
    this.borderColor,
    this.textColor = Colors.white,
    this.iconColor,
    this.shadowColor,
    this.glowColor,
    this.width,
    this.height = 52,
    this.depth = 4.5,
    this.fontSize = 15,
    this.borderRadius = 26.0,
    this.coinBadge = false,
    this.isLoading = false,
    this.onPressed,
  });

  // Pre-configured preset: Emerald Green (Success / Play Now)
  factory App3DButton.green({
    Key? key,
    required String text,
    Widget? child,
    IconData? icon,
    Widget? leading,
    Widget? trailing,
    double? width,
    double height = 52,
    double fontSize = 15,
    dynamic borderRadius = 26.0,
    bool coinBadge = false,
    bool isLoading = false,
    VoidCallback? onPressed,
  }) {
    return App3DButton(
      key: key,
      text: text,
      child: child,
      icon: icon,
      leading: leading,
      trailing: trailing,
      gradientColors: const [Color(0xFF00E676), Color(0xFF00B0FF)],
      shadowColor: const Color(0xFF00796B),
      glowColor: const Color(0xFF00E676),
      textColor: const Color(0xFF041C2C),
      iconColor: const Color(0xFF041C2C),
      width: width,
      height: height,
      fontSize: fontSize,
      borderRadius: borderRadius,
      coinBadge: coinBadge,
      isLoading: isLoading,
      onPressed: onPressed,
    );
  }

  // Pre-configured preset: Sunset Gold / Amber (Rewards / Coming Soon)
  factory App3DButton.amber({
    Key? key,
    required String text,
    Widget? child,
    IconData? icon,
    Widget? leading,
    Widget? trailing,
    double? width,
    double height = 52,
    double fontSize = 15,
    dynamic borderRadius = 26.0,
    bool coinBadge = false,
    bool isLoading = false,
    VoidCallback? onPressed,
  }) {
    return App3DButton(
      key: key,
      text: text,
      child: child,
      icon: icon,
      leading: leading,
      trailing: trailing,
      gradientColors: const [Color(0xFFFFB300), Color(0xFFFF5252)],
      shadowColor: const Color(0xFFBF360C),
      glowColor: const Color(0xFFFF9100),
      textColor: const Color(0xFF1E0A00),
      iconColor: const Color(0xFF1E0A00),
      width: width,
      height: height,
      fontSize: fontSize,
      borderRadius: borderRadius,
      coinBadge: coinBadge,
      isLoading: isLoading,
      onPressed: onPressed,
    );
  }

  // Pre-configured preset: Electric Blue / Cyan
  factory App3DButton.cyan({
    Key? key,
    required String text,
    Widget? child,
    IconData? icon,
    Widget? leading,
    Widget? trailing,
    double? width,
    double height = 52,
    double fontSize = 15,
    dynamic borderRadius = 26.0,
    bool coinBadge = false,
    bool isLoading = false,
    VoidCallback? onPressed,
  }) {
    return App3DButton(
      key: key,
      text: text,
      child: child,
      icon: icon,
      leading: leading,
      trailing: trailing,
      gradientColors: const [Color(0xFF00E5FF), Color(0xFF0091EA)],
      shadowColor: const Color(0xFF01579B),
      glowColor: const Color(0xFF00E5FF),
      textColor: const Color(0xFF021B2D),
      iconColor: const Color(0xFF021B2D),
      width: width,
      height: height,
      fontSize: fontSize,
      borderRadius: borderRadius,
      coinBadge: coinBadge,
      isLoading: isLoading,
      onPressed: onPressed,
    );
  }

  // Pre-configured preset: Royal Violet / Purple
  factory App3DButton.purple({
    Key? key,
    required String text,
    Widget? child,
    IconData? icon,
    Widget? leading,
    Widget? trailing,
    double? width,
    double height = 52,
    double fontSize = 15,
    dynamic borderRadius = 26.0,
    bool coinBadge = false,
    bool isLoading = false,
    VoidCallback? onPressed,
  }) {
    return App3DButton(
      key: key,
      text: text,
      child: child,
      icon: icon,
      leading: leading,
      trailing: trailing,
      gradientColors: const [Color(0xFFAB47BC), Color(0xFF673AB7)],
      shadowColor: const Color(0xFF311B92),
      glowColor: const Color(0xFFAB47BC),
      textColor: Colors.white,
      iconColor: Colors.white,
      width: width,
      height: height,
      fontSize: fontSize,
      borderRadius: borderRadius,
      coinBadge: coinBadge,
      isLoading: isLoading,
      onPressed: onPressed,
    );
  }

  // Pre-configured preset: Tactical Slate / Grey (Disabled / Already Claimed)
  factory App3DButton.grey({
    Key? key,
    required String text,
    Widget? child,
    IconData? icon,
    Widget? leading,
    Widget? trailing,
    double? width,
    double height = 52,
    double fontSize = 15,
    dynamic borderRadius = 26.0,
    bool coinBadge = false,
    bool isLoading = false,
    VoidCallback? onPressed,
  }) {
    return App3DButton(
      key: key,
      text: text,
      child: child,
      icon: icon,
      leading: leading,
      trailing: trailing,
      gradientColors: const [Color(0xFF4A4E5A), Color(0xFF2C303B)],
      shadowColor: const Color(0xFF181B22),
      glowColor: Colors.transparent,
      borderColor: const Color(0xFF5E6577),
      textColor: const Color(0xFF9EA7B8),
      iconColor: const Color(0xFF9EA7B8),
      width: width,
      height: height,
      fontSize: fontSize,
      borderRadius: borderRadius,
      coinBadge: coinBadge,
      isLoading: isLoading,
      onPressed: onPressed,
    );
  }

  @override
  State<App3DButton> createState() => _App3DButtonState();
}

class _App3DButtonState extends State<App3DButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.isLoading || widget.onPressed == null) return;
    HapticFeedback.lightImpact();
    AudioHelper().playButtonSound();
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.isLoading || widget.onPressed == null) return;
    HapticFeedback.mediumImpact();
    setState(() => _isPressed = false);
    widget.onPressed?.call();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  BorderRadius get _effectiveBorderRadius {
    if (widget.borderRadius is BorderRadius) {
      return widget.borderRadius as BorderRadius;
    }
    if (widget.borderRadius is double) {
      return BorderRadius.circular(widget.borderRadius as double);
    }
    if (widget.borderRadius is int) {
      return BorderRadius.circular((widget.borderRadius as int).toDouble());
    }
    return BorderRadius.circular(26.0);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColors = widget.gradientColors ??
        (widget.color != null
            ? [widget.topHighlightColor ?? widget.color!, widget.color!]
            : const [Color(0xFF00E5FF), Color(0xFF0091EA)]);

    final effectiveShadow = widget.shadowColor ??
        (widget.color != null
            ? widget.color!.withValues(alpha: 0.85)
            : effectiveColors.last.withValues(alpha: 0.85));

    final effectiveGlow =
        widget.glowColor ?? (widget.color ?? effectiveColors.first);

    final currentDepth = _isPressed ? 1.0 : widget.depth;
    final translateY = _isPressed ? (widget.depth - 1.0) : 0.0;
    final radius = _effectiveBorderRadius;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 75),
        curve: Curves.easeOutQuad,
        width: widget.width,
        height: widget.height,
        transform: Matrix4.translationValues(0, translateY, 0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: effectiveColors,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: radius,
          border: Border.all(
            color: widget.borderColor ??
                Colors.white.withValues(alpha: _isPressed ? 0.25 : 0.45),
            width: 1.4,
          ),
          boxShadow: [
            // Solid 3D bevel depth
            BoxShadow(
              color: effectiveShadow,
              offset: Offset(0, currentDepth),
              blurRadius: 0,
            ),
            // Ambient neon aura
            BoxShadow(
              color: effectiveGlow.withValues(alpha: _isPressed ? 0.2 : 0.4),
              offset: Offset(0, currentDepth + 2),
              blurRadius: _isPressed ? 6 : 14,
            ),
          ],
        ),
        child: Center(
          child: widget.isLoading
              ? SizedBox(
                  width: (widget.height * 0.45).clamp(16.0, 24.0),
                  height: (widget.height * 0.45).clamp(16.0, 24.0),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(widget.textColor),
                  ),
                )
              : (widget.child ??
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.leading != null) ...[
                            widget.leading!,
                            const SizedBox(width: 8),
                          ] else if (widget.icon != null) ...[
                            Icon(
                              widget.icon,
                              color: widget.iconColor ?? widget.textColor,
                              size: (widget.fontSize * 1.35).clamp(16.0, 26.0),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            widget.text,
                            style: GoogleFonts.outfit(
                              fontSize: widget.fontSize,
                              fontWeight: FontWeight.w900,
                              color: widget.textColor,
                              letterSpacing: 0.9,
                            ),
                          ),
                          if (widget.trailing != null) ...[
                            const SizedBox(width: 8),
                            widget.trailing!,
                          ] else if (widget.coinBadge) ...[
                            const SizedBox(width: 8),
                            Image.asset(
                              'assets/coin.png',
                              width: widget.height < 45 ? 18 : 22,
                              height: widget.height < 45 ? 18 : 22,
                              errorBuilder: (_, __, ___) => const Text('🪙',
                                  style: TextStyle(fontSize: 16)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )),
        ),
      ),
    );
  }
}

/// Tactical square / rounded 3D tactile icon button
class App3DIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final VoidCallback? onPressed;
  final double size;
  final double depth;
  final List<Color>? gradientColors;
  final Color? color;
  final Color? topHighlightColor;
  final Color? shadowColor;
  final Color? glowColor;
  final Color iconColor;
  final double iconSize;
  final double borderRadius;

  const App3DIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.onPressed,
    this.size = 46.0,
    this.depth = 3.5,
    this.gradientColors,
    this.color,
    this.topHighlightColor,
    this.shadowColor,
    this.glowColor,
    this.iconColor = Colors.white,
    this.iconSize = 22.0,
    this.borderRadius = 16.0,
  });

  @override
  State<App3DIconButton> createState() => _App3DIconButtonState();
}

class _App3DIconButtonState extends State<App3DIconButton> {
  bool _isPressed = false;

  VoidCallback? get _effectiveAction => widget.onPressed ?? widget.onTap;

  void _handleTapDown(TapDownDetails details) {
    if (_effectiveAction == null) return;
    HapticFeedback.lightImpact();
    AudioHelper().playButtonSound();
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    if (_effectiveAction == null) return;
    HapticFeedback.mediumImpact();
    setState(() => _isPressed = false);
    _effectiveAction?.call();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final currentDepth = _isPressed ? 1.0 : widget.depth;
    final translateY = _isPressed ? (widget.depth - 1.0) : 0.0;

    final effectiveColors = widget.gradientColors ??
        (widget.color != null
            ? [widget.topHighlightColor ?? widget.color!, widget.color!]
            : const [Color(0xFF0F3057), Color(0xFF00587A)]);

    final effectiveShadow = widget.shadowColor ??
        (widget.color != null
            ? widget.color!.withValues(alpha: 0.85)
            : const Color(0xFF003852));

    final effectiveGlow =
        widget.glowColor ?? (widget.color ?? const Color(0xFF00E5FF));

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 75),
        curve: Curves.easeOutQuad,
        width: widget.size,
        height: widget.size,
        transform: Matrix4.translationValues(0, translateY, 0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: effectiveColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: Colors.white.withValues(alpha: _isPressed ? 0.2 : 0.45),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: effectiveShadow,
              offset: Offset(0, currentDepth),
              blurRadius: 0,
            ),
            BoxShadow(
              color: effectiveGlow.withValues(alpha: _isPressed ? 0.15 : 0.35),
              offset: Offset(0, currentDepth + 1.5),
              blurRadius: _isPressed ? 4 : 10,
            ),
          ],
        ),
        child: Center(
          child: Icon(
            widget.icon,
            color: widget.iconColor,
            size: widget.iconSize,
          ),
        ),
      ),
    );
  }
}
