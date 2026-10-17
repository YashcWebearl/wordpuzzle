import 'dart:math' as math;
import 'dart:ui';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:word_puzzle/widget/app_3d_button.dart';
import 'package:word_puzzle/widget/coin_service.dart';
import 'package:word_puzzle/widget/sound.dart';

class _FlyingCoinParticle {
  final Offset start;
  final Offset target;
  final double delay;
  final double curveFactor;

  _FlyingCoinParticle({
    required this.start,
    required this.target,
    required this.delay,
    required this.curveFactor,
  });
}

/// Unified Coin Grant Overlay & Dialog
/// Matches the xoxo start_screen & game_selection_screen reward dialog
/// and triggers the level-completion-style flying coin animation into the topbar.
class CoinGrantOverlay extends StatefulWidget {
  final GlobalKey targetKey;
  final ConfettiController confettiController;

  const CoinGrantOverlay({
    super.key,
    required this.targetKey,
    required this.confettiController,
  });

  @override
  State<CoinGrantOverlay> createState() => CoinGrantOverlayState();
}

class CoinGrantOverlayState extends State<CoinGrantOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flyAnimController;
  List<_FlyingCoinParticle> _particles = [];
  bool _isCoinFlying = false;

  @override
  void initState() {
    super.initState();
    _flyAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
  }

  @override
  void dispose() {
    _flyAnimController.dispose();
    super.dispose();
  }

  /// Shows the xoxo-style reward popup, blasts confetti, and on collect flies coins into the topbar
  Future<void> showReward({
    required int coins,
    String source = 'Ad Reward',
  }) async {
    if (!mounted) return;

    AudioHelper().playMoneySound();
    widget.confettiController.play();

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    width: 330,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 26),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F2B48), Color(0xFF051324)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: const Color(0xFFFFD54F).withValues(alpha: 0.8),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFFFFD54F).withValues(alpha: 0.35),
                          blurRadius: 28,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Badge Header
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD54F), Color(0xFFFF9100)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD54F)
                                    .withValues(alpha: 0.4),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Text(
                            source.toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF2C004C),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Luminous 3D Coin Badge
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFFFFD54F).withValues(alpha: 0.28),
                                Colors.transparent,
                              ],
                            ),
                            border: Border.all(
                              color: const Color(0xFFFFD54F)
                                  .withValues(alpha: 0.65),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD54F)
                                    .withValues(alpha: 0.25),
                                blurRadius: 22,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Image.asset(
                              'assets/coin.png',
                              width: 54,
                              height: 54,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.monetization_on_rounded,
                                color: Color(0xFFFFD54F),
                                size: 48,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Reward Amount
                        Text(
                          '+$coins COINS',
                          style: GoogleFonts.outfit(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFFFD700),
                            shadows: [
                              Shadow(
                                color: const Color(0xFFFF9100)
                                    .withValues(alpha: 0.8),
                                blurRadius: 18,
                              ),
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.6),
                                offset: const Offset(0, 3),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),

                        Text(
                          'Coins added to your balance!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 13.5.sp,
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 22),

                        // Collect 3D Button
                        App3DButton(
                          width: 190,
                          height: 48,
                          depth: 3.5,
                          fontSize: 14.sp,
                          text: 'COLLECT',
                          icon: Icons.check_circle_rounded,
                          gradientColors: const [
                            Color(0xFF00E676),
                            Color(0xFF00B0FF),
                          ],
                          shadowColor: const Color(0xFF004D40),
                          glowColor: const Color(0xFF00E676),
                          textColor: const Color(0xFF052115),
                          onPressed: () {
                            Navigator.pop(dialogContext);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    _triggerFlyingCoins(coins);
  }

  void _triggerFlyingCoins(int coins) {
    final RenderBox? coinBox =
        widget.targetKey.currentContext?.findRenderObject() as RenderBox?;
    final screenSize = MediaQuery.of(context).size;

    final Offset target = coinBox != null
        ? coinBox.localToGlobal(Offset.zero) +
            Offset(coinBox.size.width / 2, coinBox.size.height / 2)
        : Offset(screenSize.width - 55, 45);

    final Offset start = Offset(screenSize.width / 2, screenSize.height * 0.45);

    final random = math.Random();
    _particles = List.generate(9, (index) {
      return _FlyingCoinParticle(
        start: start,
        target: target,
        delay: index * 0.05,
        curveFactor: (random.nextDouble() - 0.5) * 85,
      );
    });

    setState(() {
      _isCoinFlying = true;
    });

    AudioHelper().playMoneySound();
    HapticFeedback.mediumImpact();

    _flyAnimController.forward(from: 0.0).then((_) async {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      final coinProvider = Provider.of<CoinProvider>(context, listen: false);
      await coinProvider.addCoins(coins);
      widget.confettiController.play();
      setState(() {
        _isCoinFlying = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCoinFlying || _particles.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _flyAnimController,
      builder: (context, _) {
        final t = _flyAnimController.value;
        return IgnorePointer(
          child: Stack(
            children: _particles.map((coin) {
              final progress =
                  ((t - coin.delay) / (1.0 - coin.delay)).clamp(0.0, 1.0);
              if (progress <= 0.0 || progress >= 1.0) {
                return const SizedBox.shrink();
              }

              final curvedP = Curves.easeInOutCubic.transform(progress);
              final arc = math.sin(progress * math.pi) * coin.curveFactor;

              final curX = coin.start.dx +
                  (coin.target.dx - coin.start.dx) * curvedP +
                  arc;
              final curY =
                  coin.start.dy + (coin.target.dy - coin.start.dy) * curvedP;

              final scale = (1.35 - progress * 0.55).clamp(0.6, 1.4);
              final opacity = (progress < 0.85)
                  ? 1.0
                  : ((1.0 - progress) / 0.15).clamp(0.0, 1.0);
              final rotation = progress * math.pi * 3;

              return Positioned(
                left: curX - 16,
                top: curY - 16,
                child: Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: Transform.rotate(
                      angle: rotation,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700)
                                  .withValues(alpha: 0.75),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/coin.png',
                          width: 32,
                          height: 32,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.monetization_on_rounded,
                            color: Color(0xFFFFD700),
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
