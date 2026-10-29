import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:word_puzzle/services/daily_service.dart';
import 'package:word_puzzle/view/ad_show.dart';
import 'package:word_puzzle/widget/app_3d_button.dart';
import 'package:word_puzzle/widget/coin_container.dart';
import 'package:word_puzzle/widget/coin_service.dart';
import 'package:word_puzzle/widget/hint_button.dart';
import 'package:word_puzzle/widget/sound.dart';
import 'scramble_background.dart';
import 'scramble_home.dart';
import 'scramble_level_data.dart';
import 'scramble_success.dart';

class ScrambleGameScreen extends StatefulWidget {
  final int level;

  const ScrambleGameScreen({
    super.key,
    required this.level,
  });

  @override
  State<ScrambleGameScreen> createState() => _ScrambleGameScreenState();
}

class _ScrambleGameScreenState extends State<ScrambleGameScreen>
    with TickerProviderStateMixin {
  late ScrambleLevelData _levelData;

  // Active columns of tiles: index 0 is bottom tile
  List<List<ScrambleTile>> _columns = [];
  final Set<String> _solvedWords = {};
  final List<ScrambleTile> _selectedTiles = [];
  String _currentFormedWord = '';
  Offset? _dragDirection;

  // GlobalKeys for flying animation
  final GlobalKey _gridAreaKey = GlobalKey();
  final Map<String, GlobalKey> _wordSlotKeys = {};

  // Flying word animation state
  bool _isWordFlying = false;
  String _flyingWordText = '';
  Offset _flyingWordStart = Offset.zero;
  Offset _flyingWordEnd = Offset.zero;
  late AnimationController _flyingWordController;
  late Animation<double> _flyingWordAnimation;

  // Connecting laser trail live touch point
  Offset? _currentDragPoint;

  // Single-character hint highlight state (does NOT solve the full word)
  String? _hintedTileId;
  Timer? _hintTimer;

  // Praise popup state
  String? _currentPraiseText;
  late AnimationController _praiseAnimController;
  late Animation<double> _praiseScaleAnimation;
  late Animation<double> _praiseOpacityAnimation;
  late Animation<double> _praiseFloatAnimation;

  // Solve burst particle explosion
  late AnimationController _burstAnimController;
  final List<_ScrambleBurstParticle> _burstParticles = [];

  // Reactive Kitty Mascot State
  String _kittyMood = 'idle'; // 'idle', 'happy', 'sad'
  late AnimationController _kittyAnimController;
  late Animation<double> _kittyBounceAnimation;
  late Animation<double> _kittyRotateAnimation;

  // Timer & Moves state
  Timer? _gameTimer;
  int _timeLeft = 90;
  int _remainingMoves = 15;
  int _totalMoves = 15;
  int _remainingShuffles = 5;
  bool _isGameOver = false;
  bool _isGameOverDialogShowing = false;
  bool _isWatchingAd = false;
  bool _isProcessingSolve = false;

  // Shake animation controller for wrong word
  late AnimationController _shakeAnimController;
  late Animation<double> _shakeAnimation;

  // Shuffle rotation animation
  late AnimationController _shuffleAnimController;
  late Animation<double> _shuffleAnimation;

  @override
  void initState() {
    super.initState();
    AudioHelper().initialize();
    _loadLevel(widget.level);

    _shakeAnimController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 12)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeAnimController);

    _shuffleAnimController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shuffleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shuffleAnimController, curve: Curves.easeInOut),
    );

    _flyingWordController = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );
    _flyingWordAnimation = CurvedAnimation(
      parent: _flyingWordController,
      curve: Curves.easeInOutCubic,
    );

    // Praise banner pop & float animation
    _praiseAnimController = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    );
    _praiseScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.25)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.25, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 45,
      ),
    ]).animate(_praiseAnimController);

    _praiseOpacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 25,
      ),
    ]).animate(_praiseAnimController);

    _praiseFloatAnimation = Tween<double>(begin: 0, end: -40)
        .chain(CurveTween(curve: Curves.easeOutCubic))
        .animate(_praiseAnimController);

    // Solve burst particles controller
    _burstAnimController = AnimationController(
      duration: const Duration(milliseconds: 850),
      vsync: this,
    );
    _burstAnimController.addListener(() {
      if (mounted) setState(() {});
    });

    // Reactive Kitty idle breathing animation
    _kittyAnimController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat(reverse: true);

    _kittyBounceAnimation = Tween<double>(begin: 0.0, end: -4.0)
        .chain(CurveTween(curve: Curves.easeInOutSine))
        .animate(_kittyAnimController);

    _kittyRotateAnimation = Tween<double>(begin: -0.04, end: 0.04)
        .chain(CurveTween(curve: Curves.easeInOutSine))
        .animate(_kittyAnimController);

    _startTimer();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _hintTimer?.cancel();
    _shakeAnimController.dispose();
    _shuffleAnimController.dispose();
    _flyingWordController.dispose();
    _praiseAnimController.dispose();
    _burstAnimController.dispose();
    _kittyAnimController.dispose();
    super.dispose();
  }

  void _loadLevel(int level) {
    _levelData = ScrambleLevelCatalog.getLevelData(level);
    _solvedWords.clear();
    _selectedTiles.clear();
    _currentFormedWord = '';
    _dragDirection = null;
    _isGameOver = false;
    _isProcessingSolve = false;
    _isWordFlying = false;

    // Deep copy initial columns so tiles can collapse independently
    _columns = _levelData.initialColumns.map((col) {
      return col.map((t) => t.copyWith()).toList();
    }).toList();

    _wordSlotKeys.clear();
    for (final word in _levelData.targetWords) {
      _wordSlotKeys[word] = GlobalKey();
    }

    _timeLeft = 90;
    _totalMoves = math.max(12, _levelData.targetWords.length * 3 + 4);
    _remainingMoves = _totalMoves;
    _remainingShuffles = 5;
  }

  void _startTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isGameOver) {
        timer.cancel();
        return;
      }
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        timer.cancel();
        _handleGameOver(reason: 'time');
      }
    });
  }

  void _handleGameOver({required String reason}) {
    if (_isGameOver) return;
    _isGameOver = true;
    _gameTimer?.cancel();
    AudioHelper().playTimeOutSound();

    _showGameOverDialog(reason: reason);
  }

  void _showGameOverDialog({required String reason}) {
    if (_isGameOverDialogShowing) return;
    _isGameOverDialogShowing = true;
    bool isRetrying = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B0733).withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      reason == 'time' ? "TIME'S UP!" : "OUT OF MOVES!",
                      style: GoogleFonts.fredoka(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Image.asset(
                      reason == 'time'
                          ? 'assets/time_out.png'
                          : 'assets/out_of_moves.png',
                      width: 150,
                      height: 150,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        reason == 'time'
                            ? Icons.timer_off_rounded
                            : Icons.touch_app_rounded,
                        size: 90,
                        color: const Color(0xFFFF5252),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      "Would you like to try again?",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: App3DButton.amber(
                            text: 'GIVE UP',
                            height: 46,
                            fontSize: 14,
                            onPressed: isRetrying
                                ? null
                                : () {
                                    Navigator.pop(dialogContext);
                                    final movesUsed = math.max(
                                        0, _totalMoves - _remainingMoves);
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ScrambleSuccessScreen(
                                          level: widget.level,
                                          isWin: false,
                                          coinsEarned: 0,
                                          movesUsed: movesUsed,
                                        ),
                                      ),
                                    );
                                  },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: App3DButton.green(
                            text: 'RETRY',
                            height: 46,
                            fontSize: 14,
                            isLoading: isRetrying,
                            onPressed: isRetrying
                                ? null
                                : () async {
                                    final coinProvider =
                                        Provider.of<CoinProvider>(
                                      context,
                                      listen: false,
                                    );
                                    setDialogState(() => isRetrying = true);

                                    try {
                                      final connectivity = await Connectivity()
                                          .checkConnectivity();
                                      if (connectivity
                                          .contains(ConnectivityResult.none)) {
                                        Fluttertoast.showToast(
                                            msg: "You're offline");
                                        setDialogState(
                                            () => isRetrying = false);
                                        return;
                                      }

                                      if (coinProvider.coins < 4) {
                                        setDialogState(
                                            () => isRetrying = false);
                                        _showInsufficientCoinsDialog();
                                        return;
                                      }

                                      await Future.delayed(
                                          const Duration(milliseconds: 300));
                                      await coinProvider.undoCoins(4);
                                      AudioHelper().playMoneySound();
                                      Fluttertoast.showToast(
                                        msg: "4 coins deducted to retry",
                                      );

                                      if (!dialogContext.mounted) return;
                                      Navigator.pop(dialogContext);
                                      _restartLevel();
                                    } catch (e) {
                                      debugPrint("Retry error: $e");
                                      if (dialogContext.mounted) {
                                        setDialogState(
                                            () => isRetrying = false);
                                      }
                                    }
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
      ),
    ).then((_) {
      _isGameOverDialogShowing = false;
    });
  }

  void _spawnSolveParticles(Offset center) {
    final rand = math.Random();
    _burstParticles.clear();
    final colors = [
      const Color(0xFFFFD54F),
      const Color(0xFF00E5FF),
      const Color(0xFFFF4081),
      const Color(0xFFB388FF),
      const Color(0xFF69F0AE),
      const Color(0xFFFF9100),
      Colors.white,
    ];

    for (int i = 0; i < 24; i++) {
      final angle = (i / 24) * 2 * math.pi + (rand.nextDouble() - 0.5) * 0.4;
      final speed = 120.0 + rand.nextDouble() * 220.0;
      _burstParticles.add(
        _ScrambleBurstParticle(
          x: center.dx,
          y: center.dy,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed - 60.0,
          size: 6.0 + rand.nextDouble() * 8.0,
          color: colors[i % colors.length],
          isStar: i.isEven,
          rotationSpeed: (rand.nextDouble() - 0.5) * 8.0,
        ),
      );
    }
    _burstAnimController.forward(from: 0.0);
  }

  void _restartLevel() {
    _gameTimer?.cancel();
    setState(() {
      _loadLevel(widget.level);
    });
    _startTimer();
  }

  /// Touch & Drag detection across the tile grid
  void _handleTouch(Offset localPos, double tileSize, double spacing) {
    if (_isProcessingSolve || _isGameOver) return;
    _currentDragPoint = localPos;

    final numCols = _columns.length;
    int maxRows = 0;
    for (final col in _columns) {
      if (col.length > maxRows) maxRows = col.length;
    }
    if (maxRows == 0) return;

    final step = tileSize + spacing;
    final int colIdx = (localPos.dx ~/ step).clamp(0, numCols - 1);
    final int rowIdx = (localPos.dy ~/ step).clamp(0, maxRows - 1);

    final colTiles = _columns[colIdx];
    final int k = maxRows - 1 - rowIdx;

    if (k < 0 || k >= colTiles.length) return;
    final ScrambleTile touchedTile = colTiles[k];

    if (touchedTile.isSolved) return;

    // 1. Initial touch on first tile
    if (_selectedTiles.isEmpty) {
      setState(() {
        touchedTile.isSelected = true;
        _selectedTiles.add(touchedTile);
        _currentFormedWord = touchedTile.letter;
        _dragDirection = null;
      });
      AudioHelper().playButtonSound();
      HapticFeedback.selectionClick();
      return;
    }

    // 2. Same tile: ignore
    if (touchedTile.id == _selectedTiles.last.id) return;

    // 3. Backtracking: user dragged back to previous tile
    if (_selectedTiles.length >= 2 &&
        touchedTile.id == _selectedTiles[_selectedTiles.length - 2].id) {
      setState(() {
        final last = _selectedTiles.removeLast();
        last.isSelected = false;
        if (_selectedTiles.length == 1) {
          _dragDirection = null;
        }
        _currentFormedWord = _selectedTiles.map((t) => t.letter).join('');
      });
      AudioHelper().playButtonSound();
      HapticFeedback.selectionClick();
      return;
    }

    // 4. Moving to new tile: must be adjacent and in a straight line
    if (!_selectedTiles.any((t) => t.id == touchedTile.id)) {
      final lastTile = _selectedTiles.last;
      final dRow = rowIdx - lastTile.row;
      final dCol = colIdx - lastTile.col;

      final isAdjacent = (dRow.abs() + dCol.abs() == 1);
      if (!isAdjacent) return;

      if (_selectedTiles.length == 1) {
        // Establish straight direction
        setState(() {
          _dragDirection = Offset(dCol.toDouble(), dRow.toDouble());
          touchedTile.isSelected = true;
          _selectedTiles.add(touchedTile);
          _currentFormedWord = _selectedTiles.map((t) => t.letter).join('');
        });
        AudioHelper().playButtonSound();
        HapticFeedback.selectionClick();
      } else if (_dragDirection != null) {
        // Must continue in the exact same straight line!
        if (dCol.toDouble() == _dragDirection!.dx &&
            dRow.toDouble() == _dragDirection!.dy) {
          setState(() {
            touchedTile.isSelected = true;
            _selectedTiles.add(touchedTile);
            _currentFormedWord = _selectedTiles.map((t) => t.letter).join('');
          });
          AudioHelper().playButtonSound();
          HapticFeedback.selectionClick();
        }
      }
    }
  }

  /// Finger lifted: check if formed word is a target word
  void _handleTouchEnd() {
    setState(() {
      _currentDragPoint = null;
    });
    if (_selectedTiles.isEmpty || _isProcessingSolve || _isGameOver) return;

    final formed = _currentFormedWord.toUpperCase();

    String? matchedWord;
    for (final word in _levelData.targetWords) {
      if (!_solvedWords.contains(word)) {
        // Strict forward matching only: words must be swiped in proper spelling order!
        if (word == formed) {
          matchedWord = word;
          break;
        }
      }
    }

    if (matchedWord != null) {
      _onWordSolved(matchedWord, List.from(_selectedTiles));
    } else {
      _onWordWrong();
    }
  }

  /// Handles correct word submission with flying animation and gravity collapse!
  void _onWordSolved(String word, List<ScrambleTile> solvedTiles) async {
    _isProcessingSolve = true;
    HapticFeedback.heavyImpact();
    AudioHelper().playFoundSound();

    // Kitty joy reaction!
    setState(() {
      if (_remainingMoves > 0) _remainingMoves--;
      _kittyMood = 'happy';
    });
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted && _kittyMood == 'happy') {
        setState(() => _kittyMood = 'idle');
      }
    });

    // Combo praise popup
    final praises = [
      'PURR-FECT! 🐾',
      'SWEET! 🍬',
      'AWESOME! ✨',
      'FANTASTIC! 🌟',
      'GENIUS! 🧠',
      'SUPERB! 🎯',
      'BRILLIANT! 💎',
    ];
    setState(() {
      _currentPraiseText = praises[math.Random().nextInt(praises.length)];
    });
    _praiseAnimController.forward(from: 0.0);

    // Solve sparkles & star burst particles
    final RenderBox? gBox =
        _gridAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (gBox != null) {
      final center = Offset(gBox.size.width / 2, gBox.size.height / 2);
      _spawnSolveParticles(center);
    }

    // Calculate start offset for flying word animation from center of selected tiles
    final RenderBox? gridBox =
        _gridAreaKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? slotBox =
        _wordSlotKeys[word]?.currentContext?.findRenderObject() as RenderBox?;

    if (gridBox != null && slotBox != null) {
      final gridOrigin = gridBox.localToGlobal(Offset.zero);
      final slotOrigin = slotBox.localToGlobal(Offset.zero);

      _flyingWordStart = Offset(
        gridOrigin.dx + (gridBox.size.width / 2),
        gridOrigin.dy + 20,
      );
      _flyingWordEnd = Offset(
        slotOrigin.dx + (slotBox.size.width / 2),
        slotOrigin.dy + (slotBox.size.height / 2),
      );
      _flyingWordText = word;

      setState(() {
        _isWordFlying = true;
      });

      _flyingWordController.forward(from: 0.0);
    }

    await Future.delayed(const Duration(milliseconds: 380));

    // Remove solved tiles from their columns (GRAVITY COLLAPSE!)
    setState(() {
      _solvedWords.add(word);
      _isWordFlying = false;

      final solvedIds = solvedTiles.map((t) => t.id).toSet();
      for (final col in _columns) {
        col.removeWhere((t) => solvedIds.contains(t.id));
      }

      // Update remaining tiles rows based on new column heights
      int newMaxRows = 0;
      for (final col in _columns) {
        if (col.length > newMaxRows) newMaxRows = col.length;
      }
      for (int c = 0; c < _columns.length; c++) {
        final col = _columns[c];
        for (int k = 0; k < col.length; k++) {
          col[k].row = newMaxRows - 1 - k;
          col[k].isSelected = false;
        }
      }

      _selectedTiles.clear();
      _currentFormedWord = '';
      _dragDirection = null;
    });

    await Future.delayed(const Duration(milliseconds: 200));
    _isProcessingSolve = false;

    // Check if entire level is cleared
    if (_solvedWords.length == _levelData.targetWords.length) {
      _gameTimer?.cancel();
      AudioHelper().playWinnerSound();

      final movesUsed = math.max(0, _totalMoves - _remainingMoves);

      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ScrambleSuccessScreen(
            level: widget.level,
            coinsEarned: 3,
            isWin: true,
            movesUsed: movesUsed,
          ),
        ),
      );
    } else if (_remainingMoves <= 0) {
      _handleGameOver(reason: 'moves');
    }
  }

  /// Triggers invalid word shake and sound
  void _onWordWrong() async {
    if (_selectedTiles.length >= 2) {
      setState(() {
        if (_remainingMoves > 0) _remainingMoves--;
        _kittyMood = 'sad';
      });
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted && _kittyMood == 'sad') {
          setState(() => _kittyMood = 'idle');
        }
      });
      AudioHelper().playNotFoundSound();
      HapticFeedback.vibrate();

      try {
        await _shakeAnimController.forward(from: 0);
      } catch (_) {}

      if (_remainingMoves <= 0 && !_isGameOver) {
        _handleGameOver(reason: 'moves');
      }
    }

    if (mounted) {
      setState(() {
        for (final t in _selectedTiles) {
          t.isSelected = false;
        }
        _selectedTiles.clear();
        _currentFormedWord = '';
        _dragDirection = null;
      });
    }
  }

  void _showConfirmationDialog(String actionType, VoidCallback onConfirm) {
    _gameTimer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: const Color(0xFF1B0733).withValues(alpha: 0.90),
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
                    actionType == 'extra_move'
                        ? 'EXTRA MOVE'
                        : actionType == 'shuffle'
                            ? 'SHUFFLE LETTERS'
                            : 'GET HINT',
                    style: GoogleFonts.fredoka(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    actionType == 'extra_move'
                        ? 'Use 10 coins or watch an ad to get 5 extra moves.'
                        : actionType == 'shuffle'
                            ? 'Use 5 coins or watch an ad to shuffle letter tiles.'
                            : 'Use 10 coins or watch an ad to solve an unsolved word.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: App3DButton.amber(
                          text:
                              actionType == 'shuffle' ? '5 COINS' : '10 COINS',
                          height: 46,
                          fontSize: 13,
                          onPressed: () {
                            Navigator.pop(context);
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
                            _isWatchingAd = true;
                            Navigator.pop(context);
                            _gameTimer?.cancel();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AdPlaybackPage(onAdComplete: () {
                                  if (actionType == 'extra_move') {
                                    _addExtraMove(useCoins: false);
                                  } else if (actionType == 'shuffle') {
                                    _performShuffle(useCoins: false);
                                  } else {
                                    _useHint(useCoins: false);
                                  }
                                }),
                              ),
                            ).then((_) {
                              _isWatchingAd = false;
                              if (mounted && !_isGameOver) {
                                _startTimer();
                              }
                            });
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
    ).then((_) {
      if (mounted && !_isGameOver && !_isWatchingAd) {
        _startTimer();
      }
    });
  }

  void _showInsufficientCoinsDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: const Color(0xFF1B0733).withValues(alpha: 0.90),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('NOT ENOUGH COINS',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white)),
                  const SizedBox(height: 20),
                  App3DButton.cyan(
                    text: 'OK',
                    height: 44,
                    width: 120,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _addExtraMove({bool useCoins = true}) async {
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
    setState(() {
      _remainingMoves += 5;
      _totalMoves += 5;
    });
    Fluttertoast.showToast(msg: "+5 Extra Moves added!");
  }

  /// Hint: Highlights the starting character of an unsolved word to guide the player (does not auto-solve)
  void _useHint({bool useCoins = true}) async {
    final coinProvider = Provider.of<CoinProvider>(context, listen: false);
    if (useCoins && coinProvider.coins < 10) {
      _showInsufficientCoinsDialog();
      return;
    }

    String? unsolvedWord;
    for (final w in _levelData.targetWords) {
      if (!_solvedWords.contains(w)) {
        unsolvedWord = w;
        break;
      }
    }

    if (unsolvedWord == null) {
      Fluttertoast.showToast(msg: "All words already solved!");
      return;
    }

    // Find the first letter of this unsolved word currently available on the board
    final firstChar = unsolvedWord[0];
    ScrambleTile? hintTile;
    for (final col in _columns) {
      for (final tile in col) {
        if (!tile.isSolved && tile.letter == firstChar) {
          hintTile = tile;
          break;
        }
      }
      if (hintTile != null) break;
    }

    // Fallback: any letter of the unsolved word currently on the board
    if (hintTile == null) {
      for (final char in unsolvedWord.split('')) {
        for (final col in _columns) {
          for (final tile in col) {
            if (!tile.isSolved && tile.letter == char) {
              hintTile = tile;
              break;
            }
          }
          if (hintTile != null) break;
        }
        if (hintTile != null) break;
      }
    }

    if (hintTile == null) {
      Fluttertoast.showToast(msg: "Clear other tiles to reveal '$unsolvedWord'!");
      return;
    }

    if (useCoins) {
      await coinProvider.undoCoins(10);
      AudioHelper().playMoneySound();
    }

    DailyService().updateTaskProgress(
      taskKey: 'use_hint',
      increment: 1,
      gameName: 'Scramble',
    );
    AudioHelper().playHintSound();
    HapticFeedback.mediumImpact();

    // Highlight only this single character with an electric cyan neon glow!
    setState(() {
      _hintedTileId = hintTile!.id;
    });

    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _hintedTileId != null) {
        setState(() {
          _hintedTileId = null;
        });
      }
    });

    Fluttertoast.showToast(
      msg: "Hint: Starts with '${hintTile.letter}' for '$unsolvedWord'!",
    );
  }

  void _onShuffleTapped() {
    if (_remainingShuffles > 0) {
      _performShuffle(useCoins: false);
    } else {
      _showConfirmationDialog('shuffle', () => _performShuffle(useCoins: true));
    }
  }

  void _performShuffle({bool useCoins = true}) async {
    final remainingWords =
        _levelData.targetWords.where((w) => !_solvedWords.contains(w)).toList();

    if (remainingWords.isEmpty) return;

    if (useCoins) {
      final coinProvider = Provider.of<CoinProvider>(context, listen: false);
      if (coinProvider.coins < 5) {
        _showInsufficientCoinsDialog();
        return;
      }
      await coinProvider.undoCoins(5);
      AudioHelper().playMoneySound();
    }

    _shuffleAnimController.forward(from: 0.0);
    HapticFeedback.lightImpact();
    AudioHelper().playButtonSound();

    setState(() {
      if (_remainingShuffles > 0 && !useCoins) {
        _remainingShuffles--;
      }

      // Re-pack remaining unsolved words into a fresh, 100% verified solvable layout!
      _columns = ScramblePuzzleEngine.repackRemainingWords(
        remainingWords: remainingWords,
        cols: _columns.length,
        seed: widget.level * 1000 +
            _remainingShuffles * 47 +
            DateTime.now().millisecond,
      );

      _selectedTiles.clear();
      _currentFormedWord = '';
      _dragDirection = null;
    });

    Fluttertoast.showToast(msg: "Board shuffled!");
  }

  void _showExitConfirmationDialog() {
    _gameTimer?.cancel();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: const Color(0xFF230D42).withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'PAUSE GAME?',
                    style: GoogleFonts.fredoka(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Do you want to return to the Word Scramble menu?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
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
                            _gameTimer?.cancel();
                            Navigator.pop(ctx);
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ScrambleHomeScreen(),
                              ),
                              (route) => route.isFirst,
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
    ).then((_) {
      if (mounted && !_isGameOver) {
        _startTimer();
      }
    });
  }

  Widget _buildTimerBadge() {
    final isLowTime = _timeLeft <= 15;
    final ringColor =
        isLowTime ? const Color(0xFFFF5252) : const Color(0xFF00E5FF);
    final minutes = (_timeLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_timeLeft % 60).toString().padLeft(2, '0');

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0F3057).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ringColor.withValues(alpha: isLowTime ? 0.9 : 0.45),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: ringColor.withValues(alpha: isLowTime ? 0.45 : 0.2),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            color: ringColor,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            "$minutes:$seconds",
            style: TextStyle(
              color: isLowTime ? const Color(0xFFFF5252) : Colors.white,
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovesBadge() {
    final isLowMoves = _remainingMoves <= 3;
    final ringColor =
        isLowMoves ? const Color(0xFFFF5252) : const Color(0xFFFFD700);

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0F3057).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ringColor.withValues(alpha: isLowMoves ? 0.9 : 0.45),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: ringColor.withValues(alpha: isLowMoves ? 0.45 : 0.2),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.touch_app_rounded,
            color: ringColor,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            "Moves: $_remainingMoves",
            style: TextStyle(
              color: isLowMoves ? const Color(0xFFFF5252) : Colors.white,
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShuffleButton() {
    return GestureDetector(
      onTap: _onShuffleTapped,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFAB47BC), Color(0xFF7B1FA2)],
          ),
          borderRadius: BorderRadius.circular(21),
          border: Border.all(
            color: const Color(0xFFCE93D8),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7B1FA2).withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RotationTransition(
              turns: _shuffleAnimation,
              child: const Icon(
                Icons.shuffle_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 6),
            if (_remainingShuffles > 0)
              Text(
                '$_remainingShuffles',
                style: GoogleFonts.fredoka(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/coin.png', width: 14, height: 14),
                  const SizedBox(width: 2),
                  Text(
                    '5',
                    style: GoogleFonts.fredoka(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isNarrow = screenWidth < 360;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _showExitConfirmationDialog();
        }
      },
      child: Scaffold(
        body: ScrambleCosmicBackground(
          child: Stack(
            children: [
              SafeArea(
                child: Column(
                  children: [
                    // 1. Top HUD Bar (< Level X, Coins, Hint & Extra Moves)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isNarrow ? 10.0 : 16.0,
                        vertical: 6.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Left: 3D Back + Level Button
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
                            onPressed: _showExitConfirmationDialog,
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
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isNarrow ? 12.5 : 14.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Center: Coin Balance
                          const CoinBalanceWidget(),

                          // Right: Hint and Extra Moves Buttons
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
                              SizedBox(width: isNarrow ? 6.0 : 10.0),
                              CustomHintButton(
                                icon: Icons.auto_fix_high,
                                value: 10,
                                showCoin: true,
                                onPressed: () => _showConfirmationDialog(
                                  'extra_move',
                                  () => _addExtraMove(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // 2. Top Clue Card with Word Slots (Dot slots turning into Blue Pills!)
                    _buildTopClueArea(),

                    // 3 & 4. Centered Playing Arena inside Expanded with LayoutBuilder & FittedBox to prevent ANY RenderFlex overflow
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final double availableHeight = constraints.maxHeight;
                          return Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildFloatingPreviewPill(),
                                  SizedBox(height: 6.h),
                                  _buildLetterBlockStack(
                                    maxAvailableHeight: availableHeight,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // 5. Bottom Overlay: Timer on Left, Shuffle in Center, Moves on Right
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 10.h,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTimerBadge(),
                          _buildShuffleButton(),
                          _buildMovesBadge(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 6. Flying Word Animation Overlay (flies from grid to top card - Image 3)
              if (_isWordFlying) _buildFlyingWordOverlay(),

              // 7. Solve Burst Confetti & Sparkles Overlay
              if (_burstAnimController.isAnimating)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _ScrambleBurstPainter(
                        particles: _burstParticles,
                        progress: _burstAnimController.value,
                      ),
                    ),
                  ),
                ),

              // 8. Juicy Combo Praise Popups Overlay (PURR-FECT!, SWEET!, etc.)
              if (_currentPraiseText != null)
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.31,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Center(
                      child: _buildPraisePopup(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Top Clue & Word Slots Box (matching Image 1, 3, 4)
  Widget _buildTopClueArea() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 3.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFF180833).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Theme Title + Animated Kitty Mascot
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildKittyMascotWidget(),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_levelData.emoji, style: TextStyle(fontSize: 17.sp)),
                      SizedBox(width: 6.w),
                      Text(
                        _levelData.themeTitle,
                        style: GoogleFonts.fredoka(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Find all  hidden words',
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      color: const Color(0xFFCE93D8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 8.h),

          // Word slots: Dot circles for unsolved, vibrant blue pills for solved!
          Wrap(
            spacing: 12.w,
            runSpacing: 10.h,
            alignment: WrapAlignment.center,
            children: _levelData.targetWords.map((word) {
              final isSolved = _solvedWords.contains(word);
              return Container(
                key: _wordSlotKeys[word],
                child: isSolved
                    ? _buildSolvedWordPill(word)
                    : _buildUnsolvedWordDots(word),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Dot slots for hidden word (Image 1)
  Widget _buildUnsolvedWordDots(String word) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: const Color(0xFF28104E).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(word.length, (index) {
          return Container(
            width: 14.w,
            height: 14.w,
            margin: EdgeInsets.symmetric(horizontal: 2.5.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF3F1B78),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  /// Solved vibrant Blue 3D Pill (Image 3 & 4)
  Widget _buildSolvedWordPill(String word) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 5.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF29B6F6),
            Color(0xFF0288D1),
          ],
        ),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: const Color(0xFFE1F5FE),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF01579B),
            offset: const Offset(0, 3),
            blurRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFF0288D1).withValues(alpha: 0.45),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        word,
        style: GoogleFonts.fredoka(
          fontSize: 16.sp,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 1.5,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.35),
              offset: const Offset(0, 1.5),
              blurRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  /// Floating Orange Word Preview Capsule (Image 2)
  Widget _buildFloatingPreviewPill() {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (_, child) => Transform.translate(
        offset: Offset(_shakeAnimation.value, 0),
        child: child,
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: _currentFormedWord.isNotEmpty ? 1.0 : 0.0,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 8.h),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFE040FB),
                Color(0xFFBA68C8),
                Color(0xFF7C4DFF),
              ],
            ),
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(
              color: const Color(0xFFF3E5F5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF38006B),
                offset: const Offset(0, 4),
                blurRadius: 0,
              ),
              BoxShadow(
                color: const Color(0xFFD500F9).withValues(alpha: 0.5),
                blurRadius: 14,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Text(
            _currentFormedWord,
            style: GoogleFonts.fredoka(
              fontSize: 22.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2.0,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  offset: const Offset(0, 1.5),
                  blurRadius: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Grounded 2.5D Letter Blocks Stack with Slide Detection (Image 1, 2, 3, 4)
  Widget _buildLetterBlockStack({double? maxAvailableHeight}) {
    final numCols = _columns.length;
    int maxRows = 0;
    for (final col in _columns) {
      if (col.length > maxRows) maxRows = col.length;
    }
    if (maxRows == 0) return const SizedBox.shrink();

    // Dynamically calculate tileSize to guarantee it fits inside available vertical & horizontal space
    final double spacing = 2.0.w;
    final double maxGridH = (maxAvailableHeight != null && maxAvailableHeight > 100)
        ? (maxAvailableHeight - 52.h)
        : (MediaQuery.of(context).size.height * 0.42);
    final double maxTileFromHeight =
        (maxGridH - ((maxRows - 1) * spacing)) / maxRows;
    final double desiredWidthTile =
        (numCols >= 6 ? 48.w : numCols == 5 ? 52.w : 58.w);
    final double tileSize =
        math.min(desiredWidthTile, maxTileFromHeight).clamp(32.0, 58.0);
    final step = tileSize + spacing;

    final totalWidth = numCols * step - spacing;
    final totalHeight = maxRows * step - spacing;

    // Calculate center points of currently selected tiles for glowing laser beam
    final List<Offset> selectedCenters = [];
    for (final tile in _selectedTiles) {
      final double left = tile.col * step;
      final double top = tile.row * step;
      selectedCenters.add(Offset(left + tileSize / 2, top + tileSize / 2));
    }

    return Center(
      child: GestureDetector(
        key: _gridAreaKey,
        onPanStart: (details) =>
            _handleTouch(details.localPosition, tileSize, spacing),
        onPanUpdate: (details) =>
            _handleTouch(details.localPosition, tileSize, spacing),
        onPanEnd: (_) => _handleTouchEnd(),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: totalWidth,
          height: totalHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Subtle grounded shelf/shadow beneath the block structure
              Positioned(
                bottom: -5.h,
                left: -3.w,
                right: -3.w,
                child: Container(
                  height: 8.h,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(4.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),

              // 1. Glowing Laser Trail connecting selected tiles and following finger
              if (_selectedTiles.isNotEmpty)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ScrambleLaserTrailPainter(
                      points: selectedCenters,
                      currentPoint: _currentDragPoint,
                      color: const Color(0xFFFFD54F),
                    ),
                  ),
                ),

              // 2. Solid 2.5D Extruded Blocks with top highlight & bottom depth bevel
              for (int c = 0; c < numCols; c++)
                for (int k = 0; k < _columns[c].length; k++)
                  _buildAnimatedTileItem(
                    tile: _columns[c][k],
                    c: c,
                    k: k,
                    maxRows: maxRows,
                    tileSize: tileSize,
                    spacing: spacing,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  /// Single solid 2.5D chunky block with top highlight, front face, and extruded bottom depth
  Widget _buildAnimatedTileItem({
    required ScrambleTile tile,
    required int c,
    required int k,
    required int maxRows,
    required double tileSize,
    required double spacing,
  }) {
    final step = tileSize + spacing;
    final double left = c * step;
    final int row = maxRows - 1 - k;
    final double top = row * step;

    final bool isSelected = tile.isSelected;

    // 2.5D Physical Depth & Corner Chamfer
    final double depth = 5.0.h;
    final double cornerRadius = 8.0.r;

    return AnimatedPositioned(
      key: ValueKey(tile.id),
      duration: const Duration(milliseconds: 320),
      curve: Curves.bounceOut,
      left: left,
      top: top,
      child: AnimatedScale(
        scale: isSelected ? 1.06 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutBack,
        child: Container(
          width: tileSize,
          height: tileSize,
          decoration: BoxDecoration(
            // Extruded 2.5D base color (solid bottom shelf)
            color: isSelected
                ? const Color(0xFFC76A00)
                : const Color(0xFF14520A),
            borderRadius: BorderRadius.circular(cornerRadius),
            boxShadow: [
              // Bottom drop shadow on the table/floor
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.38),
                offset: const Offset(0, 3.5),
                blurRadius: 3.0,
              ),
              // Radiant golden aura when actively selected
              if (isSelected)
                BoxShadow(
                  color: const Color(0xFFFFB300).withValues(alpha: 0.65),
                  blurRadius: 14,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Column(
            children: [
              // 2.5D Top/Front Face
              Container(
                height: tileSize - depth,
                width: tileSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(cornerRadius),
                    topRight: Radius.circular(cornerRadius),
                    bottomLeft: Radius.circular(cornerRadius * 0.75),
                    bottomRight: Radius.circular(cornerRadius * 0.75),
                  ),
                  gradient: isSelected
                      ? const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFFFF176),
                            Color(0xFFFFD54F),
                            Color(0xFFFF9800),
                          ],
                        )
                      : const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF5CD834),
                            Color(0xFF38B81E),
                            Color(0xFF289914),
                          ],
                        ),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFFFFDE7).withValues(alpha: 0.85)
                        : const Color(0xFF9EFF6B).withValues(alpha: 0.65),
                    width: isSelected ? 1.5 : 1.2,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Top highlight bevel line
                    Positioned(
                      top: 2.h,
                      left: 5.w,
                      right: 5.w,
                      child: Container(
                        height: 3.h,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.7)
                              : const Color(0xFFB9FF8F).withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),
                    Text(
                      tile.letter,
                      style: GoogleFonts.fredoka(
                        fontSize: 29.sp,
                        fontWeight: FontWeight.w900,
                        color: isSelected
                            ? const Color(0xFF3E2723)
                            : Colors.white,
                        shadows: [
                          Shadow(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.45)
                                : const Color(0xFF114207),
                            offset: const Offset(0, 2.2),
                            blurRadius: 1.0,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // The remaining bottom height is filled by the parent container's solid 2.5D base color!
            ],
          ),
        ),
      ),
    );
  }

  /// Flying word pill animation layer (Image 3)
  Widget _buildFlyingWordOverlay() {
    return AnimatedBuilder(
      animation: _flyingWordAnimation,
      builder: (context, _) {
        final progress = _flyingWordAnimation.value;
        final curX = _flyingWordStart.dx +
            (_flyingWordEnd.dx - _flyingWordStart.dx) * progress;
        final curY = _flyingWordStart.dy +
            (_flyingWordEnd.dy - _flyingWordStart.dy) * progress;
        final scale = 1.15 - (0.25 * progress);

        return Positioned(
          left: curX - 50.w,
          top: curY - 20.h,
          child: Transform.scale(
            scale: scale,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 7.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF29B6F6), Color(0xFF0288D1)],
                ),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0288D1).withValues(alpha: 0.6),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Text(
                _flyingWordText,
                style: GoogleFonts.fredoka(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Interactive Kitty Mascot with dynamic emotional animations
  Widget _buildKittyMascotWidget() {
    return AnimatedBuilder(
      animation: _kittyAnimController,
      builder: (context, child) {
        final double dy = _kittyMood == 'happy'
            ? math.sin(_kittyAnimController.value * math.pi * 3) * 6
            : _kittyBounceAnimation.value;
        final double angle = _kittyMood == 'sad'
            ? math.sin(_kittyAnimController.value * math.pi * 4) * 0.08
            : _kittyRotateAnimation.value;

        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.rotate(
            angle: angle,
            child: child,
          ),
        );
      },
      child: Container(
        width: 44.w,
        height: 44.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _kittyMood == 'happy'
                ? const [Color(0xFFFF80AB), Color(0xFFFF4081)]
                : _kittyMood == 'sad'
                    ? const [Color(0xFF78909C), Color(0xFF546E7A)]
                    : const [Color(0xFFFFB74D), Color(0xFFFF9800)],
          ),
          border: Border.all(
            color: Colors.white,
            width: 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: (_kittyMood == 'happy'
                      ? const Color(0xFFFF4081)
                      : const Color(0xFFFF9800))
                  .withValues(alpha: 0.5),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            _kittyMood == 'happy'
                ? '😻'
                : _kittyMood == 'sad'
                    ? '😿'
                    : '🐱',
            style: TextStyle(fontSize: 24.sp),
          ),
        ),
      ),
    );
  }

  /// Juicy Combo / Praise Popups (PURR-FECT!, SWEET!, etc.)
  Widget _buildPraisePopup() {
    return AnimatedBuilder(
      animation: _praiseAnimController,
      builder: (context, child) {
        if (_praiseAnimController.value == 0 ||
            _praiseAnimController.value == 1) {
          return const SizedBox.shrink();
        }
        return Transform.translate(
          offset: Offset(0, _praiseFloatAnimation.value),
          child: Transform.scale(
            scale: _praiseScaleAnimation.value,
            child: Opacity(
              opacity: _praiseOpacityAnimation.value.clamp(0.0, 1.0),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 10.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFD54F),
                      Color(0xFFFF9800),
                      Color(0xFFFF5722),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28.r),
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF9800).withValues(alpha: 0.7),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Text(
                  _currentPraiseText ?? '',
                  style: GoogleFonts.fredoka(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
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

/// Particle model for word solve starbursts
class _ScrambleBurstParticle {
  final double x;
  final double y;
  final double vx;
  final double vy;
  final double size;
  final Color color;
  final bool isStar;
  final double rotationSpeed;

  _ScrambleBurstParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.isStar,
    required this.rotationSpeed,
  });
}

/// CustomPainter for sparkling confetti and stars burst
class _ScrambleBurstPainter extends CustomPainter {
  final List<_ScrambleBurstParticle> particles;
  final double progress;

  _ScrambleBurstPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (particles.isEmpty) return;
    final alpha = (1.0 - progress).clamp(0.0, 1.0);
    final gravity = 280.0 * progress * progress;

    for (final p in particles) {
      final curX = p.x + p.vx * progress;
      final curY = p.y + p.vy * progress + gravity;
      final paint = Paint()
        ..color = p.color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(curX, curY);
      canvas.rotate(progress * p.rotationSpeed * math.pi);

      if (p.isStar) {
        final path = Path();
        final s = p.size;
        path.moveTo(0, -s);
        path.quadraticBezierTo(0, 0, s, 0);
        path.quadraticBezierTo(0, 0, 0, s);
        path.quadraticBezierTo(0, 0, -s, 0);
        path.quadraticBezierTo(0, 0, 0, -s);
        canvas.drawPath(path, paint);
      } else {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ScrambleBurstPainter oldDelegate) => true;
}

/// Glowing neon laser beam trail connecting tiles while swiping
class _ScrambleLaserTrailPainter extends CustomPainter {
  final List<Offset> points;
  final Offset? currentPoint;
  final Color color;

  _ScrambleLaserTrailPainter({
    required this.points,
    required this.currentPoint,
    this.color = const Color(0xFFFFD54F),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final allPoints = List<Offset>.from(points);
    if (currentPoint != null) {
      allPoints.add(currentPoint!);
    }

    if (allPoints.length < 2) return;

    final path = Path();
    path.moveTo(allPoints.first.dx, allPoints.first.dy);
    for (int i = 1; i < allPoints.length; i++) {
      path.lineTo(allPoints[i].dx, allPoints[i].dy);
    }

    // Outer neon glow
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(path, glowPaint);

    // Medium vivid core
    final midPaint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, midPaint);

    // Inner bright white laser core
    final corePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, corePaint);

    // Live touch point halo
    if (currentPoint != null) {
      final pointGlow = Paint()
        ..color = const Color(0xFFFFE082).withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(currentPoint!, 10, pointGlow);
      final pointDot = Paint()..color = Colors.white;
      canvas.drawCircle(currentPoint!, 5, pointDot);
    }
  }

  @override
  bool shouldRepaint(covariant _ScrambleLaserTrailPainter oldDelegate) => true;
}
