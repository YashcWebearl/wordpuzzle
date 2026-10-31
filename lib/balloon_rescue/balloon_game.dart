import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:word_puzzle/view/ad_show.dart';
import 'package:word_puzzle/widget/app_3d_button.dart';
import 'package:word_puzzle/widget/coin_container.dart';
import 'package:word_puzzle/widget/coin_service.dart';
import 'package:word_puzzle/widget/hint_button.dart';
import 'package:word_puzzle/widget/sound.dart';
import 'balloon_background.dart';
import 'balloon_character_widget.dart';
import 'balloon_home.dart';
import 'balloon_level_data.dart';
import 'balloon_success.dart';

class BalloonGameScreen extends StatefulWidget {
  final int level;
  const BalloonGameScreen({super.key, required this.level});

  @override
  State<BalloonGameScreen> createState() => _BalloonGameScreenState();
}

class _BalloonGameScreenState extends State<BalloonGameScreen>
    with TickerProviderStateMixin {
  late BalloonPuzzle _puzzle;
  int _balloonsRemaining = 5;
  final Set<String> _revealedLetters = {};
  final Set<int> _revealedSlotIndices = {};
  final Set<int> _landingPopSlots = {};
  final Set<int> _usedTileIndices = {};
  final Set<int> _wrongTileIndices = {};
  final List<_FlyingBalloonTileData> _flyingTiles = [];
  final Map<int, GlobalKey> _tileKeys = {};
  final Map<int, GlobalKey> _slotKeys = {};

  String _boyExpression = 'idle';
  bool _isGameOver = false;
  int? _shakingTileIndex;

  // Praise & Combo Streak System
  int _correctStreak = 0;
  String? _praiseText;
  late final AnimationController _praiseController;
  late final Animation<double> _praiseScaleAnimation;
  late final Animation<double> _praiseOpacityAnimation;

  // Danger Warning Pulse (Triggered when only 1 balloon remains!)
  late final AnimationController _dangerPulseController;

  // Confetti Shower Overlay on Victory Lift-Off
  bool _showConfetti = false;
  late final AnimationController _confettiController;
  final List<_BalloonConfettiParticle> _confettiParticles = [];

  late final AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    AudioHelper().initialize();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _dangerPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _praiseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _praiseScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.25)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.25, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOutQuad)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 30,
      ),
    ]).animate(_praiseController);
    _praiseOpacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_praiseController);

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..addListener(() {
        if (_showConfetti) {
          setState(() {
            for (final p in _confettiParticles) {
              p.update();
            }
          });
        }
      });

    _loadPuzzle();
  }

  void _loadPuzzle() {
    _puzzle = BalloonLevelData.getPuzzleForLevel(widget.level);
    _balloonsRemaining = 5;
    _revealedLetters.clear();
    _revealedSlotIndices.clear();
    _landingPopSlots.clear();
    _usedTileIndices.clear();
    _wrongTileIndices.clear();
    _flyingTiles.clear();
    _tileKeys.clear();
    _slotKeys.clear();
    _correctStreak = 0;
    _showConfetti = false;
    _confettiParticles.clear();
    if (mounted) {
      _dangerPulseController.stop();
      _dangerPulseController.reset();
    }
    _boyExpression = 'idle';
    _isGameOver = false;
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _dangerPulseController.dispose();
    _praiseController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _onTileTapped(int index) async {
    if (_isGameOver || _usedTileIndices.contains(index)) return;

    final tappedLetter = _puzzle.letterPool[index].toUpperCase();
    final targetWord = _puzzle.word.toUpperCase();
    final chars = targetWord.split('');

    // Find the next unrevealed slot that matches this letter and is not already being targeted
    int? targetSlotIndex;
    for (int s = 0; s < chars.length; s++) {
      if (chars[s] == tappedLetter && !_revealedSlotIndices.contains(s)) {
        final isAlreadyFlyingToThis =
            _flyingTiles.any((f) => f.targetSlotIndex == s);
        if (!isAlreadyFlyingToThis) {
          targetSlotIndex = s;
          break;
        }
      }
    }

    if (targetSlotIndex != null) {
      // ✅ CORRECT LETTER GUESS -> Launch gorgeous flying animation to the top slot!
      HapticFeedback.mediumImpact();
      AudioHelper().playBalloonFly();

      // Combo / Streak escalation
      _correctStreak++;
      if (_correctStreak >= 2) {
        _praiseText = _correctStreak == 2
            ? 'NICE! ✨'
            : (_correctStreak == 3
                ? 'GREAT! 🌟'
                : (_correctStreak == 4 ? 'AMAZING! 🔥' : 'PERFECT! 💎'));
        _praiseController.forward(from: 0.0);
        AudioHelper().playBalloonPraise();
      }

      setState(() {
        _usedTileIndices.add(index);
        _boyExpression = 'happy';
      });

      // Spawn the flying tile in the next frame after layout
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _spawnFlyingTile(
          tileIndex: index,
          slotIndex: targetSlotIndex!,
          letter: tappedLetter,
        );
      });

      // Reset expression after delay
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted && _boyExpression == 'happy' && !_isGameOver) {
          setState(() => _boyExpression = 'idle');
        }
      });
    } else {
      // ❌ WRONG LETTER GUESS: POP 1 BALLOON!
      _correctStreak = 0;
      _praiseController.reset();

      HapticFeedback.heavyImpact();
      AudioHelper().playBalloonWrong();
      AudioHelper().playBalloonBurst();

      final newBalloons = (_balloonsRemaining - 1).clamp(0, 5);

      setState(() {
        _usedTileIndices.add(index);
        _wrongTileIndices.add(index);
        _balloonsRemaining = newBalloons;
        _boyExpression = 'shocked';
        _shakingTileIndex = index;
      });

      _shakeController.forward(from: 0.0);

      // Danger pulse when down to only 1 final balloon!
      if (newBalloons == 1) {
        _dangerPulseController.repeat(reverse: true);
        HapticFeedback.heavyImpact();
        AudioHelper().playBalloonDanger();
      } else {
        _dangerPulseController.stop();
        _dangerPulseController.reset();
      }

      // Reset expression after reaction
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted && _boyExpression == 'shocked' && !_isGameOver) {
          setState(() {
            _boyExpression = _balloonsRemaining <= 2 ? 'shocked' : 'idle';
            _shakingTileIndex = null;
          });
        }
      });

      // Check if all 5 balloons are popped
      if (_balloonsRemaining <= 0) {
        _dangerPulseController.stop();
        _dangerPulseController.reset();
        _handleDefeat();
      }
    }
  }

  void _spawnFlyingTile({
    required int tileIndex,
    required int slotIndex,
    required String letter,
  }) {
    if (!mounted) return;
    final tileBox =
        _tileKeys[tileIndex]?.currentContext?.findRenderObject() as RenderBox?;
    final slotBox =
        _slotKeys[slotIndex]?.currentContext?.findRenderObject() as RenderBox?;

    if (tileBox == null || !tileBox.attached || slotBox == null || !slotBox.attached) {
      // Fallback: reveal immediately if positions cannot be resolved
      _onFlyingTileArrived(slotIndex, letter);
      return;
    }

    final startOffset = tileBox.localToGlobal(Offset.zero);
    final endOffset = slotBox.localToGlobal(Offset.zero);
    final tileSize = tileBox.size;
    final slotSize = slotBox.size;

    final flyingTile = _FlyingBalloonTileData(
      key: UniqueKey(),
      letter: letter,
      startOffset: startOffset,
      endOffset: endOffset,
      startWidth: tileSize.width,
      startHeight: tileSize.height,
      endWidth: slotSize.width,
      endHeight: slotSize.height,
      targetSlotIndex: slotIndex,
    );

    setState(() {
      _flyingTiles.add(flyingTile);
    });
  }

  void _onFlyingTileArrived(int slotIndex, String letter) {
    if (!mounted) return;

    AudioHelper().playBalloonPop(_revealedSlotIndices.length);
    HapticFeedback.lightImpact();

    setState(() {
      _revealedSlotIndices.add(slotIndex);
      _revealedLetters.add(letter);
      _landingPopSlots.add(slotIndex);
      _flyingTiles.removeWhere((t) => t.targetSlotIndex == slotIndex);
    });

    // Remove landing pop state after 280ms
    Future.delayed(const Duration(milliseconds: 280), () {
      if (mounted) {
        setState(() {
          _landingPopSlots.remove(slotIndex);
        });
      }
    });

    // Check if ALL slots in the word are revealed
    if (_revealedSlotIndices.length >= _puzzle.word.length) {
      _handleVictory();
    }
  }

  void _handleVictory() {
    _isGameOver = true;
    _dangerPulseController.stop();
    _dangerPulseController.reset();

    setState(() {
      _boyExpression = 'win';
      _showConfetti = true;
      _initConfetti();
    });

    _confettiController.forward(from: 0.0);
    AudioHelper().playBalloonTakeoff();
    HapticFeedback.heavyImpact();

    // 1400ms delay: Boy waves happily, shoots UP into the stratosphere, confetti rains!
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BalloonSuccessScreen(
            isWin: true,
            level: widget.level,
            word: _puzzle.word,
            balloonsLeft: _balloonsRemaining,
          ),
        ),
      );
    });
  }

  void _initConfetti() {
    _confettiParticles.clear();
    final random = math.Random();
    final colors = [
      const Color(0xFFFF2A6D), // Vibrant Neon Pink
      const Color(0xFF05D9E8), // Electric Cyan
      const Color(0xFFFFD166), // Golden Yellow
      const Color(0xFF06D6A0), // Emerald Green
      const Color(0xFFB185DB), // Pastel Purple
      const Color(0xFFFF9F1C), // Bright Orange
      Colors.white,
    ];
    for (int i = 0; i < 55; i++) {
      _confettiParticles.add(_BalloonConfettiParticle(
        x: random.nextDouble(),
        y: -0.1 - (random.nextDouble() * 0.4),
        vx: (random.nextDouble() - 0.5) * 0.015,
        vy: 0.007 + random.nextDouble() * 0.014,
        rotation: random.nextDouble() * 2 * math.pi,
        rotationSpeed: (random.nextDouble() - 0.5) * 0.15,
        size: 7.0 + random.nextDouble() * 9.0,
        color: colors[random.nextInt(colors.length)],
        isCircle: random.nextBool(),
      ));
    }
  }

  void _handleDefeat() {
    _isGameOver = true;
    setState(() => _boyExpression = 'defeat');
    AudioHelper().playBalloonFall();

    // Give time for 5th balloon burst + comic pause + plummeting straight down off-screen
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BalloonSuccessScreen(
            isWin: false,
            level: widget.level,
            word: _puzzle.word,
            balloonsLeft: 0,
          ),
        ),
      );
    });
  }

  void _addExtraBalloon({bool useCoins = true}) async {
    if (_isGameOver) return;
    if (_balloonsRemaining >= 5) {
      Fluttertoast.showToast(msg: "All 5 balloons are already intact!");
      return;
    }

    final coinProvider = Provider.of<CoinProvider>(context, listen: false);
    if (useCoins && coinProvider.coins < 10) {
      _showInsufficientCoinsDialog();
      return;
    }

    if (useCoins) {
      await coinProvider.undoCoins(10);
      AudioHelper().playMoneySound();
    }
    HapticFeedback.mediumImpact();
    AudioHelper().playBalloonInflate();

    setState(() {
      _balloonsRemaining = (_balloonsRemaining + 1).clamp(1, 5);
      _boyExpression = 'happy';
    });

    if (_balloonsRemaining > 1) {
      _dangerPulseController.stop();
      _dangerPulseController.reset();
    }

    Fluttertoast.showToast(msg: "+1 Balloon life restored! 🎈");
  }

  void _useHint({bool useCoins = true}) async {
    if (_isGameOver) return;

    // Find first unrevealed slot in the word
    int? unrevealedSlotIndex;
    final chars = _puzzle.word.split('');
    for (int i = 0; i < chars.length; i++) {
      if (!_revealedSlotIndices.contains(i)) {
        unrevealedSlotIndex = i;
        break;
      }
    }

    if (unrevealedSlotIndex == null) {
      Fluttertoast.showToast(msg: "All letters already solved!");
      return;
    }

    final unrevealed = chars[unrevealedSlotIndex];

    final coinProvider = Provider.of<CoinProvider>(context, listen: false);
    if (useCoins && coinProvider.coins < 10) {
      _showInsufficientCoinsDialog();
      return;
    }

    if (useCoins) {
      await coinProvider.undoCoins(10);
      AudioHelper().playHintSound();
    }
    HapticFeedback.mediumImpact();

    // Find and auto-tap the tile containing this letter
    int tileIndex = -1;
    for (int i = 0; i < _puzzle.letterPool.length; i++) {
      if (!_usedTileIndices.contains(i) &&
          _puzzle.letterPool[i] == unrevealed) {
        tileIndex = i;
        break;
      }
    }

    if (tileIndex != -1) {
      _onTileTapped(tileIndex);
    } else {
      _onFlyingTileArrived(unrevealedSlotIndex, unrevealed);
    }
    Fluttertoast.showToast(
      msg: useCoins ? "Hint Revealed! -10 coins" : "Hint Revealed!",
    );
  }

  void _showPauseDialog() {
    if (_isGameOver) return;

    AudioHelper().playButtonSound();
    HapticFeedback.lightImpact();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: const Color(0xFF0F3057).withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pause Icon Header
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00E5FF), Color(0xFF0091EA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.pause_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'PAUSE GAME',
                    style: GoogleFonts.fredoka(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Do you want to continue playing or exit to menu?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      // RESUME BUTTON
                      Expanded(
                        child: App3DButton.green(
                          text: 'RESUME',
                          height: 44,
                          fontSize: 14,
                          borderRadius: 22.0,
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // MENU / QUIT BUTTON
                      Expanded(
                        child: App3DButton(
                          text: 'MENU',
                          height: 44,
                          fontSize: 14,
                          borderRadius: 22.0,
                          gradientColors: const [
                            Color(0xFFFF5252),
                            Color(0xFFC62828),
                          ],
                          shadowColor: const Color(0xFF8E0000),
                          glowColor: const Color(0xFFFF5252),
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BalloonHomeScreen(),
                              ),
                            );
                          },
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

  void _showConfirmationDialog(String actionType, VoidCallback onConfirm) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionType == 'extra_life' ? 'EXTRA LIFE' : 'GET HINT',
                    style: GoogleFonts.fredoka(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    actionType == 'extra_life'
                        ? 'Use 10 coins or watch an ad to restore 1 balloon life.'
                        : 'Use 10 coins or watch an ad to reveal a letter.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      Expanded(
                        child: App3DButton.amber(
                          text: '10 COINS',
                          height: 46,
                          fontSize: 13,
                          onPressed: () {
                            Navigator.pop(dialogCtx);
                            onConfirm();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: App3DButton.cyan(
                          text: 'WATCH AD',
                          height: 46,
                          fontSize: 13,
                          onPressed: () {
                            Navigator.pop(dialogCtx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AdPlaybackPage(
                                  isRewardAd: true,
                                  onAdComplete: () {
                                    if (actionType == 'extra_life') {
                                      _addExtraBalloon(useCoins: false);
                                    } else {
                                      _useHint(useCoins: false);
                                    }
                                  },
                                ),
                              ),
                            );
                          },
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

  void _showInsufficientCoinsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'NOT ENOUGH COINS',
                    style: GoogleFonts.fredoka(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'You need at least 10 coins or you can watch an ad.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 20),
                  App3DButton.cyan(
                    text: 'OK',
                    height: 44,
                    width: 120,
                    onPressed: () => Navigator.pop(ctx),
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
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _showPauseDialog();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            BalloonSkyBackground(
              child: SafeArea(
                child: Column(
                  children: [
                    // 1. Top Bar
                    _buildTopBar(),

                    const SizedBox(height: 6),

                    // 2. Category & Emoji Badge
                    _buildCategoryBadge(),

                    const SizedBox(height: 10),

                    // 3. Word Slots (e.g. [ G ] [ _ ] [ _ ] [ _ ])
                    _buildWordSlots(),

                    // 4. Center Area: Floating Boy with 5 Balloons
                    Expanded(
                      child: Center(
                        child: BalloonCharacterWidget(
                          balloonsRemaining: _balloonsRemaining,
                          expression: _boyExpression,
                        ),
                      ),
                    ),

                    // 5. Balloon Lives Indicator Pill
                    _buildLivesPill(),

                    const SizedBox(height: 16),

                    // 6. Bottom: The 10 or 12 Big 3D Letter Tiles
                    _buildLetterTileGrid(),

                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),

            // Danger Vignette Pulsing Warning (When only 1 balloon remains!)
            if (_balloonsRemaining == 1)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _dangerPulseController,
                    builder: (context, _) {
                      final val = _dangerPulseController.value;
                      return Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 1.0,
                            colors: [
                              Colors.transparent,
                              Colors.red.withValues(alpha: 0.08 + (val * 0.32)),
                            ],
                            stops: const [0.45, 1.0],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            // 7. Flying Letter Tiles Overlay Layer
            ..._flyingTiles.map((data) => _FlyingTileWidget(
                  key: data.key,
                  data: data,
                  onArrived: () => _onFlyingTileArrived(
                      data.targetSlotIndex, data.letter),
                )),

            // Combo & Praise Popup Badge
            if (_praiseText != null)
              Positioned(
                top: MediaQuery.of(context).size.height * 0.28,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _praiseController,
                      builder: (context, _) {
                        return Opacity(
                          opacity: _praiseOpacityAnimation.value.clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: _praiseScaleAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFB703),
                                    Color(0xFFFB8500),
                                    Color(0xFFFF007A),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFB703).withValues(alpha: 0.8),
                                    blurRadius: 20,
                                    spreadRadius: 3,
                                  ),
                                  const BoxShadow(
                                    color: Colors.black38,
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                _praiseText!,
                                style: GoogleFonts.fredoka(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 1.5,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black45,
                                      offset: Offset(1, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

            // Confetti Shower Layer on Victory
            if (_showConfetti)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _ConfettiPainter(particles: _confettiParticles),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isNarrow = screenWidth < 360;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isNarrow ? 10.0 : 16.0,
        vertical: 6.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: 3D Back + Level pill button (same style as Word Scramble & Crossword)
          App3DButton(
            height: isNarrow ? 38 : 44,
            borderRadius: 22.0,
            depth: 3.5,
            gradientColors: const [
              Color(0xFF0F3057),
              Color(0xFF00587A),
            ],
            shadowColor: const Color(0xFF002238),
            glowColor: const Color(0xFF00E5FF),
            onPressed: _showPauseDialog,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isNarrow ? 8 : 10,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: isNarrow ? 18.0 : 20.0,
                  ),
                  SizedBox(width: isNarrow ? 4.0 : 6.0),
                  Text(
                    isNarrow
                        ? 'Lvl ${widget.level}'
                        : 'Level ${widget.level}',
                    style: GoogleFonts.fredoka(
                      color: Colors.white,
                      fontSize: isNarrow ? 12.5 : 14.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Center: Coin balance
          const CoinBalanceWidget(),

          // Right: Hint and Extra Life Buttons (same circular 3D CustomHintButton as Crossword & Scramble)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomHintButton(
                icon: Icons.lightbulb_outline,
                value: 10,
                showCoin: true,
                onPressed: () => _showConfirmationDialog(
                  'hint',
                  () => _useHint(),
                ),
              ),
              SizedBox(width: isNarrow ? 6.0 : 8.0),
              CustomHintButton(
                icon: Icons.favorite_rounded,
                value: 10,
                showCoin: true,
                onPressed: () => _showConfirmationDialog(
                  'extra_life',
                  () => _addExtraBalloon(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_puzzle.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(
            '${_puzzle.category} • ${_puzzle.word.length} LETTERS',
            style: GoogleFonts.fredoka(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordSlots() {
    final chars = _puzzle.word.split('');
    final screenW = MediaQuery.of(context).size.width;
    // Dynamically calculate slot dimensions so 3 to 8 letter words fit neatly on a single row
    final horizontalPadding = 32.0;
    final availableW = screenW - horizontalPadding;
    final spacing = chars.length >= 7 ? 6.0 : (chars.length >= 6 ? 7.0 : 8.0);
    final totalSpacing = spacing * (chars.length - 1);
    final slotW = math.min(52.0, math.max(34.0, (availableW - totalSpacing) / chars.length));
    final slotH = (slotW * 1.08).clamp(42.0, 56.0);
    final fontSize = (slotW * 0.50).clamp(18.0, 26.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: chars.asMap().entries.map((entry) {
          final slotIdx = entry.key;
          final char = entry.value;
          final isRevealed = _revealedSlotIndices.contains(slotIdx);
          final isLanding = _landingPopSlots.contains(slotIdx);

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: spacing / 2),
            child: AnimatedScale(
              scale: isLanding ? 1.20 : 1.0,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              child: AnimatedContainer(
                key: _slotKeys.putIfAbsent(slotIdx, () => GlobalKey()),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                width: slotW,
                height: slotH,
                decoration: BoxDecoration(
                  gradient: isRevealed
                      ? const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF69F0AE),
                            Color(0xFF00E676),
                            Color(0xFF00C853),
                          ],
                        )
                      : LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.35),
                            Colors.black.withValues(alpha: 0.50),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(slotW * 0.26),
                  border: Border.all(
                    color: isRevealed
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.35),
                    width: isRevealed ? 2.5 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isRevealed
                          ? const Color(0xFF00E676).withValues(alpha: 0.5)
                          : Colors.black.withValues(alpha: 0.25),
                      blurRadius: isRevealed ? 12 : 4,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    isRevealed ? char : '',
                    style: GoogleFonts.fredoka(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w900,
                      color: isRevealed ? const Color(0xFF052B17) : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLivesPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: List.generate(5, (idx) {
              final active = idx < _balloonsRemaining;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Text(
                  active ? '🎈' : '💥',
                  style: TextStyle(
                    fontSize: 16,
                    color: active ? Colors.white : Colors.white24,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(width: 8),
          Text(
            '$_balloonsRemaining / 5 LIVES',
            style: GoogleFonts.fredoka(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLetterTileGrid() {
    final pool = _puzzle.letterPool;
    final row1Count = pool.length <= 10 ? 5 : 6;
    final row1 = pool.sublist(0, row1Count);
    final row2 = pool.sublist(row1Count);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: [
          _buildLetterRow(row1, startIndex: 0),
          const SizedBox(height: 10),
          _buildLetterRow(row2, startIndex: row1Count),
        ],
      ),
    );
  }

  Widget _buildLetterRow(List<String> letters, {required int startIndex}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(letters.length, (colIdx) {
        final actualIndex = startIndex + colIdx;
        final letter = letters[colIdx];
        final isUsed = _usedTileIndices.contains(actualIndex);
        final isWrong = _wrongTileIndices.contains(actualIndex);
        final isCorrect = isUsed && !isWrong;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: _build3DLetterTile(
            letter: letter,
            index: actualIndex,
            isUsed: isUsed,
            isWrong: isWrong,
            isCorrect: isCorrect,
          ),
        );
      }),
    );
  }

  Widget _build3DLetterTile({
    required String letter,
    required int index,
    required bool isUsed,
    required bool isWrong,
    required bool isCorrect,
  }) {
    final screenW = MediaQuery.of(context).size.width;
    final tileSize = math.min(52.0, (screenW - 56) / (_puzzle.poolSize == 10 ? 5 : 6));

    // Colors according to state
    Color topColor;
    Color highlightColor;
    Color shadowColor;
    Color textColor;

    if (isCorrect) {
      topColor = const Color(0xFF00E676);
      highlightColor = const Color(0xFF69F0AE);
      shadowColor = const Color(0xFF00C853);
      textColor = const Color(0xFF00331A);
    } else if (isWrong) {
      topColor = const Color(0xFF757575);
      highlightColor = const Color(0xFF9E9E9E);
      shadowColor = const Color(0xFF424242);
      textColor = Colors.white54;
    } else {
      // Chunky Amber/Orange 3D Tile
      topColor = const Color(0xFFFF9100);
      highlightColor = const Color(0xFFFFD54F);
      shadowColor = const Color(0xFFE65100);
      textColor = Colors.white;
    }

    final isShaking = _shakingTileIndex == index;

    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        double shakeX = 0.0;
        if (isShaking && _shakeController.isAnimating) {
          shakeX = math.sin(_shakeController.value * math.pi * 6) * 6.0;
        }

        return Transform.translate(
          offset: Offset(shakeX, 0),
          child: SizedBox(
            key: _tileKeys.putIfAbsent(index, () => GlobalKey()),
            width: tileSize,
            height: tileSize * 1.12,
            child: App3DButton(
              width: tileSize,
              height: tileSize * 1.12,
              borderRadius: 14,
              color: topColor,
              topHighlightColor: highlightColor,
              shadowColor: shadowColor,
              onPressed: isUsed ? null : () => _onTileTapped(index),
              child: Text(
                letter,
                style: GoogleFonts.fredoka(
                  fontSize: tileSize * 0.48,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      offset: const Offset(0, 1.5),
                      blurRadius: 1.5,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Data model for flying letters
class _FlyingBalloonTileData {
  final Key key;
  final String letter;
  final Offset startOffset;
  final Offset endOffset;
  final double startWidth;
  final double startHeight;
  final double endWidth;
  final double endHeight;
  final int targetSlotIndex;

  _FlyingBalloonTileData({
    required this.key,
    required this.letter,
    required this.startOffset,
    required this.endOffset,
    required this.startWidth,
    required this.startHeight,
    required this.endWidth,
    required this.endHeight,
    required this.targetSlotIndex,
  });
}

/// Smooth parabolic flying tile animation from bottom tile to top slot
class _FlyingTileWidget extends StatefulWidget {
  final _FlyingBalloonTileData data;
  final VoidCallback onArrived;

  const _FlyingTileWidget({
    super.key,
    required this.data,
    required this.onArrived,
  });

  @override
  State<_FlyingTileWidget> createState() => _FlyingTileWidgetState();
}

class _FlyingTileWidgetState extends State<_FlyingTileWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 65),
    ]).animate(_controller);

    _controller.forward().then((_) {
      if (mounted) {
        widget.onArrived();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _curve.value;
        final start = widget.data.startOffset;
        final end = widget.data.endOffset;

        final linearDx = lerpDouble(start.dx, end.dx, t)!;
        final linearDy = lerpDouble(start.dy, end.dy, t)!;

        // Graceful parabolic arc bowing slightly outward
        final arcOffset =
            math.sin(t * math.pi) * (start.dx > end.dx ? 22.0 : -22.0);
        final currentX = linearDx + arcOffset;
        final currentY = linearDy;

        final width =
            lerpDouble(widget.data.startWidth, widget.data.endWidth, t)!;
        final height =
            lerpDouble(widget.data.startHeight, widget.data.endHeight, t)!;

        return Positioned(
          left: currentX,
          top: currentY,
          child: IgnorePointer(
            child: Transform.scale(
              scale: _scale.value,
              child: Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF69F0AE),
                      Color(0xFF00E676),
                      Color(0xFF00C853),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(width * 0.26),
                  border: Border.all(
                    color: Colors.white,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E676).withValues(alpha: 0.85),
                      blurRadius: 18,
                      spreadRadius: 3,
                    ),
                    const BoxShadow(
                      color: Colors.black45,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.data.letter,
                    style: GoogleFonts.fredoka(
                      fontSize: width * 0.50,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF052B17),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BalloonConfettiParticle {
  double x;
  double y;
  double vx;
  double vy;
  double rotation;
  double rotationSpeed;
  double size;
  Color color;
  bool isCircle;

  _BalloonConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.rotation,
    required this.rotationSpeed,
    required this.size,
    required this.color,
    required this.isCircle,
  });

  void update() {
    x += vx;
    y += vy;
    rotation += rotationSpeed;
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_BalloonConfettiParticle> particles;

  _ConfettiPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = p.color
        ..style = PaintingStyle.fill;

      final px = p.x * size.width;
      final py = p.y * size.height;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(p.rotation);

      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.6,
          ),
          paint,
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
