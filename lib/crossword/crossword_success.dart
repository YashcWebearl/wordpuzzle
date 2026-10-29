// ignore_for_file: avoid_print
import 'dart:ui';
import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:word_puzzle/view/ad_show.dart';
import 'package:word_puzzle/widget/app_3d_button.dart';
import 'package:word_puzzle/widget/coin_container.dart';
import 'package:word_puzzle/widget/coin_service.dart';
import 'crossword_audio.dart';
import 'crossword_background.dart';
import 'crossword_game.dart';
import 'crossword_home.dart';
import 'crossword_level_service.dart';

class CrosswordSuccessScreen extends StatefulWidget {
  final int level;
  final int coinsEarned;
  final bool isWin;
  final int movesUsed;

  const CrosswordSuccessScreen({
    super.key,
    required this.level,
    this.coinsEarned = 3,
    this.isWin = true,
    this.movesUsed = 0,
  });

  @override
  State<CrosswordSuccessScreen> createState() => _CrosswordSuccessScreenState();
}

class _CrosswordSuccessScreenState extends State<CrosswordSuccessScreen>
    with TickerProviderStateMixin {
  late final ConfettiController _confettiController;
  late final AnimationController _floatController;
  late final AnimationController _bounceController;
  late final AnimationController _flyCoinController;
  late final Animation<double> _floatAnimation;
  late final Animation<double> _bounceAnimation;

  final GlobalKey _topCoinKey = GlobalKey();
  final GlobalKey _rewardBadgeKey = GlobalKey();
  List<_FlyingCoinParticle> _flyingCoins = [];
  bool _isCoinFlying = false;
  bool _coinsAwarded = false;
  bool _isNextButtonTapped = false;

  @override
  void initState() {
    super.initState();

    // Confetti Controller
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 4));
    if (widget.isWin) {
      _confettiController.play();
    }

    // Float Animation for 3D Coin Badge
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: 0, end: -14).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Bounce Animation for Reward Badge
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    // Flying Coins Animation Controller (Exact ref from Wordix & xoxo)
    _flyCoinController = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    );

    // Save and advance crossword level ONLY IF WON (Syncs to SharedPreferences and Backend API)
    if (widget.isWin) {
      print(
          '🏆 [CrosswordSuccessScreen] Level ${widget.level} WON! Advancing level in SharedPreferences and Backend...');
      CrosswordLevelService.completeLevel(
        level: widget.level,
        stars: 3,
        score: (widget.coinsEarned * 100) + 150,
        moves: widget.movesUsed,
      );
    } else {
      print(
          '❌ [CrosswordSuccessScreen] Level ${widget.level} LOST. Level will not be advanced.');
    }

    if (widget.isWin) {
      CrosswordAudioHelper().playWinner();

      // Trigger flying coins animation from +X COINS badge up into topbar
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted && !_coinsAwarded) {
            _triggerFlyingCoinsAnimation();
          }
        });
      });
    } else {
      CrosswordAudioHelper().playNotFound();
    }
  }

  void _triggerFlyingCoinsAnimation() {
    final RenderBox? coinBox =
        _topCoinKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? badgeBox =
        _rewardBadgeKey.currentContext?.findRenderObject() as RenderBox?;
    final screenSize = MediaQuery.of(context).size;

    final Offset target = coinBox != null
        ? coinBox.localToGlobal(Offset.zero) +
            Offset(coinBox.size.width / 2, coinBox.size.height / 2)
        : Offset(screenSize.width - 55, 45);

    final Offset start = badgeBox != null
        ? badgeBox.localToGlobal(Offset.zero) +
            Offset(badgeBox.size.width / 2, badgeBox.size.height / 2)
        : Offset(screenSize.width / 2, screenSize.height * 0.48);

    final random = math.Random();
    _flyingCoins = List.generate(8, (index) {
      return _FlyingCoinParticle(
        start: start,
        target: target,
        delay: index * 0.055,
        curveFactor: (random.nextDouble() - 0.5) * 85,
      );
    });

    setState(() {
      _isCoinFlying = true;
    });

    CrosswordAudioHelper().playCoin();
    HapticFeedback.mediumImpact();

    _flyCoinController.forward(from: 0.0).then((_) async {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      _coinsAwarded = true;
      _checkConnectivityAndAddCoins();
      setState(() {
        _isCoinFlying = false;
      });
    });
  }

  Future<void> _checkConnectivityAndAddCoins() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      Fluttertoast.showToast(msg: "You're offline, coins couldn't be added");
    } else {
      _addCoins();
    }
  }

  Future<void> _addCoins() async {
    try {
      final coinProvider = Provider.of<CoinProvider>(context, listen: false);
      await coinProvider.addCoins(widget.coinsEarned, isWinner: true);
      CrosswordAudioHelper().playCoin();
    } catch (e) {
      debugPrint("Error adding coins: $e");
    }
  }

  void _handleNextLevel() async {
    if (_isNextButtonTapped) return;
    setState(() => _isNextButtonTapped = true);

    try {
      final coinProvider = Provider.of<CoinProvider>(context, listen: false);
      if (coinProvider.coins < 4) {
        _showInsufficientCoinsDialog();
        return;
      }

      await coinProvider.undoCoins(4);
      CrosswordAudioHelper().playCoin();
      Fluttertoast.showToast(msg: "4 coins deducted to start the game");

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CrosswordGameScreen(
              level: widget.isWin ? widget.level + 1 : widget.level,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error starting next level: $e");
    } finally {
      if (mounted) {
        setState(() => _isNextButtonTapped = false);
      }
    }
  }

  void _showInsufficientCoinsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        contentPadding: EdgeInsets.zero,
        content: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: const Color(0xFF0D2818).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: const Color(0xFF00E676).withValues(alpha: 0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E676).withValues(alpha: 0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFF9100)],
                      ),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E676).withValues(alpha: 0.5),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.monetization_on_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'NOT ENOUGH COINS!',
                    style: GoogleFonts.fredoka(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'You need 4 coins to start the next puzzle.\nWatch a quick ad to claim free bonus coins!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: App3DButton(
                          height: 48,
                          color: const Color(0xFF1B4332),
                          topHighlightColor: const Color(0xFF2D6A4F),
                          shadowColor: const Color(0xFF081C15),
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'RETURN',
                            style: GoogleFonts.fredoka(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: App3DButton(
                          height: 48,
                          color: const Color(0xFFFF9100),
                          topHighlightColor: const Color(0xFFFFB74D),
                          shadowColor: const Color(0xFFC76A00),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AdPlaybackPage(
                                  isRewardAd: true,
                                  onAdComplete: () {
                                    Provider.of<CoinProvider>(context,
                                            listen: false)
                                        .addCoins(5);
                                  },
                                ),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.ondemand_video_rounded,
                                  color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                '+5 COINS',
                                style: GoogleFonts.fredoka(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _floatController.dispose();
    _bounceController.dispose();
    _flyCoinController.dispose();
    super.dispose();
  }

  Widget _buildFlyingCoinsOverlay() {
    if (!_isCoinFlying || _flyingCoins.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _flyCoinController,
      builder: (context, _) {
        final t = _flyCoinController.value;
        return IgnorePointer(
          child: Stack(
            children: _flyingCoins.map((coin) {
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
                                  .withValues(alpha: 0.65),
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent accidental hardware back dismissal
      child: Scaffold(
        body: CrosswordNatureBackground(
          child: Stack(
            children: [
              // 1. Confetti Top Cannon Layer
              if (widget.isWin)
                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    shouldLoop: false,
                    colors: const [
                      Color(0xFFFFD700), // Gold
                      Color(0xFFFF9100), // Orange
                      Color(0xFFFF5722), // Coral
                      Color(0xFF00E676), // Lime Green
                      Color(0xFF00E5FF), // Cyan
                      Colors.white,
                    ],
                    numberOfParticles: 55,
                    maxBlastForce: 65,
                    minBlastForce: 25,
                    gravity: 0.28,
                  ),
                ),

              // 2. Main Foreground UI
              SafeArea(
                child: Column(
                  children: [
                    // Top Bar: Coin Balance Widget on Top-Right with GlobalKey
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            key: _topCoinKey,
                            child: const CoinBalanceWidget(),
                          ),
                        ],
                      ),
                    ),

                    // Middle Content (Scrollable for smaller screens)
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 10),

                            // CONGRATS! 3D Stacked Header
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                // Deep glowing shadow
                                Text(
                                  widget.isWin ? 'CONGRATS!' : 'TRY AGAIN!',
                                  style: GoogleFonts.fredoka(
                                    fontSize: 46,
                                    fontWeight: FontWeight.w900,
                                    color: widget.isWin
                                        ? const Color(0xFFFF9100)
                                        : const Color(0xFFFF5252),
                                    shadows: [
                                      BoxShadow(
                                        color: (widget.isWin
                                                ? const Color(0xFFFF7043)
                                                : const Color(0xFFFF5252))
                                            .withValues(alpha: 0.7),
                                        blurRadius: 24,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                ),
                                // Front Golden/White text
                                Text(
                                  widget.isWin ? 'CONGRATS!' : 'TRY AGAIN!',
                                  style: GoogleFonts.fredoka(
                                    fontSize: 46,
                                    fontWeight: FontWeight.w900,
                                    color: widget.isWin
                                        ? const Color(0xFFFFD700)
                                        : Colors.white,
                                    shadows: const [
                                      Shadow(
                                        color: Color(0xFFB78103),
                                        offset: Offset(0, 4),
                                        blurRadius: 0,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Level Completed Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 6),
                              decoration: BoxDecoration(
                                color: (widget.isWin
                                        ? const Color(0xFFFF9100)
                                        : const Color(0xFFFF5252))
                                    .withValues(alpha: 0.20),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: (widget.isWin
                                          ? const Color(0xFFFF9100)
                                          : const Color(0xFFFF5252))
                                      .withValues(alpha: 0.55),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (widget.isWin
                                            ? const Color(0xFFFF9100)
                                            : const Color(0xFFFF5252))
                                        .withValues(alpha: 0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    widget.isWin
                                        ? Icons.check_circle_rounded
                                        : Icons.refresh_rounded,
                                    color: widget.isWin
                                        ? const Color(0xFF00E676)
                                        : const Color(0xFFFF5252),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.isWin
                                        ? 'LEVEL ${widget.level} COMPLETE'
                                        : 'LEVEL ${widget.level} INCOMPLETE',
                                    style: GoogleFonts.fredoka(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.5,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Central 3D Floating Coin
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                // Radial Amber Aura
                                Container(
                                  width: 180,
                                  height: 180,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFFFD700)
                                        .withValues(alpha: 0.12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFFD700)
                                            .withValues(alpha: 0.3),
                                        blurRadius: 50,
                                        spreadRadius: 10,
                                      ),
                                    ],
                                  ),
                                ),

                                // Floating Coin
                                AnimatedBuilder(
                                  animation: _floatAnimation,
                                  builder: (context, child) {
                                    return Transform.translate(
                                      offset: Offset(0, _floatAnimation.value),
                                      child: child,
                                    );
                                  },
                                  child: Container(
                                    width: 130,
                                    height: 130,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const RadialGradient(
                                        center: Alignment(-0.3, -0.3),
                                        radius: 0.8,
                                        colors: [
                                          Color(0xFFFFF176),
                                          Color(0xFFFFD700),
                                          Color(0xFFFF8F00),
                                        ],
                                      ),
                                      border: Border.all(
                                        color: const Color(0xFFFFE082),
                                        width: 5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.5),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                        BoxShadow(
                                          color: const Color(0xFFFFB300)
                                              .withValues(alpha: 0.6),
                                          blurRadius: 24,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Image.asset(
                                        'assets/coin.png',
                                        width: 68,
                                        height: 68,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                          Icons.monetization_on_rounded,
                                          color: Colors.white,
                                          size: 64,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Reward Badge (+X COINS) with GlobalKey for flying coin start
                            AnimatedBuilder(
                              animation: _bounceAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _bounceAnimation.value,
                                  child: child,
                                );
                              },
                              child: Container(
                                key: _rewardBadgeKey,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 28, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1B4332),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: const Color(0xFFFFD700),
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFFD700)
                                          .withValues(alpha: 0.35),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.add_rounded,
                                      color: Color(0xFFFFD700),
                                      size: 24,
                                    ),
                                    Text(
                                      '${widget.coinsEarned} COINS',
                                      style: GoogleFonts.fredoka(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFFFFD700),
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 36),

                            // 3D NEXT LEVEL Primary Action Button
                            App3DButton(
                              height: 58,
                              color: const Color(0xFF00E676),
                              topHighlightColor: const Color(0xFF69F0AE),
                              shadowColor: const Color(0xFF0B532E),
                              isLoading: _isNextButtonTapped,
                              onPressed: () async {
                                final connectivity =
                                    await Connectivity().checkConnectivity();
                                if (connectivity
                                    .contains(ConnectivityResult.none)) {
                                  Fluttertoast.showToast(msg: "You're offline");
                                  return;
                                }
                                _handleNextLevel();
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    widget.isWin
                                        ? Icons.play_arrow_rounded
                                        : Icons.replay_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.isWin ? 'NEXT LEVEL' : 'TRY AGAIN',
                                    style: GoogleFonts.fredoka(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 14),

                            // 3D HOME Button
                            App3DButton(
                              height: 50,
                              color: const Color(0xFF1B4332),
                              topHighlightColor: const Color(0xFF2D6A4F),
                              shadowColor: const Color(0xFF081C15),
                              borderColor: const Color(0xFFFFD54F)
                                  .withValues(alpha: 0.4),
                              onPressed: () {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const CrosswordHomeScreen(),
                                  ),
                                  (route) => route.isFirst,
                                );
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.home_rounded,
                                    color: Color(0xFFFFD54F),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'HOME',
                                    style: GoogleFonts.fredoka(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Flying Coins Animation Overlay (Coins fly up to topbar widget)
              _buildFlyingCoinsOverlay(),
            ],
          ),
        ),
      ),
    );
  }
}

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
