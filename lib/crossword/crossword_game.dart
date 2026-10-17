import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word_puzzle/db/prefs.dart';
import 'package:word_puzzle/view/ad_show.dart';
import 'package:word_puzzle/widget/app_3d_button.dart';
import 'package:word_puzzle/widget/hint_button.dart';
import 'package:word_puzzle/widget/coin_container.dart';
import 'package:word_puzzle/widget/coin_service.dart';
import 'package:word_puzzle/services/daily_service.dart';
import 'crossword_audio.dart';
import 'crossword_background.dart';
import 'crossword_generator.dart';
import 'crossword_home.dart';
import 'crossword_success.dart';

class CrosswordGameScreen extends StatefulWidget {
  final int level;
  final bool isDaily;

  const CrosswordGameScreen({
    super.key,
    required this.level,
    this.isDaily = false,
  });

  @override
  State<CrosswordGameScreen> createState() => _CrosswordGameScreenState();
}

class _CrosswordGameScreenState extends State<CrosswordGameScreen>
    with TickerProviderStateMixin {
  late CrosswordLevelData _levelData;
  late List<String> _wheelLetters;

  final Set<String> _foundWords = {};
  final Map<String, bool> _revealedCells = {}; // "row_col": true

  // Timer & Moves state
  Timer? _gameTimer;
  int _timeLeft = 90;
  int _remainingMoves = 0;
  int _totalMoves = 0;
  int _remainingShuffles = 5;
  bool _isGameOver = false;
  bool _isWatchingAd = false;

  // Current Pan gesture state
  final List<int> _selectedIndices = [];
  Offset? _currentDragPoint;
  final GlobalKey _wheelKey = GlobalKey();

  // Flying letter animation state
  final GlobalKey _previewBubbleKey = GlobalKey();
  final Map<String, GlobalKey> _gridCellKeys = {};
  final List<_FlyingTileData> _flyingTiles = [];
  final Set<String> _landingPopCells = {};
  String _displayedBubbleWord = '';
  double _currentCellSize = 42.0;

  // Shuffle animation state
  late AnimationController _shuffleController;
  late Animation<double> _shuffleAnimation;
  bool _isShuffling = false;
  bool _hasShuffledThisSpin = false;

  @override
  void initState() {
    super.initState();
    CrosswordAudioHelper().initialize();
    _loadSavedShuffles();
    _shuffleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shuffleAnimation = CurvedAnimation(
      parent: _shuffleController,
      curve: Curves.easeInOutCubic,
    );
    _shuffleController.addListener(() {
      if (_shuffleController.value >= 0.5 && !_hasShuffledThisSpin) {
        _hasShuffledThisSpin = true;
        setState(() {
          _wheelLetters.shuffle();
        });
      }
    });
    _loadLevel(widget.level);
  }

  Future<void> _loadSavedShuffles() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt('crossword_shuffles') ?? 5;
    if (mounted) {
      setState(() {
        _remainingShuffles = count;
      });
    }
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _shuffleController.dispose();
    CrosswordAudioHelper().stopCountdown();
    super.dispose();
  }

  void _onShuffleTapped() async {
    if (_isShuffling || _selectedIndices.isNotEmpty) return;

    if (_remainingShuffles > 0) {
      // Global Free Starting Shuffles stored in SharedPreferences (5 down to 0)
      final prefs = await SharedPreferences.getInstance();
      final newCount = math.max(0, _remainingShuffles - 1);
      await prefs.setInt('crossword_shuffles', newCount);
      if (mounted) {
        setState(() {
          _remainingShuffles = newCount;
        });
      }
      _performShuffleAnim();
      Fluttertoast.showToast(
        msg: newCount > 0
            ? "Free Shuffle used! ($newCount left)"
            : "Last free shuffle used! Next shuffles cost 5 coins.",
        toastLength: Toast.LENGTH_SHORT,
      );
    } else {
      // Free shuffles exhausted: 5 coins = 1 shuffle (or watch ad)
      _showConfirmationDialog(
        'shuffle',
        () => _performShuffleWithCoins(useCoins: true),
      );
    }
  }

  void _performShuffleAnim() {
    if (_isShuffling) return;
    _isShuffling = true;
    _hasShuffledThisSpin = false;
    HapticFeedback.mediumImpact();
    CrosswordAudioHelper().playShuffle();

    _shuffleController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() {
          _isShuffling = false;
        });
      }
    });
  }

  void _performShuffleWithCoins({bool useCoins = true}) async {
    final coinProvider = Provider.of<CoinProvider>(context, listen: false);
    if (useCoins && coinProvider.coins < 5) {
      _showInsufficientCoinsDialog();
      return;
    }

    if (useCoins) {
      await coinProvider.undoCoins(5);
      CrosswordAudioHelper().playCoin();
    }

    _performShuffleAnim();
    Fluttertoast.showToast(
      msg: useCoins ? "Wheel Shuffled! -5 coins" : "Wheel Shuffled!",
    );
  }

  void _loadLevel(int lvl) {
    DailyService().updateTaskProgress(
      taskKey: 'play_crossword',
      increment: 1,
      gameName: 'Crossword',
    );
    _levelData = CrosswordLevelGenerator.getLevelData(lvl);
    _wheelLetters = List.from(_levelData.wheelLetters);
    _foundWords.clear();
    _revealedCells.clear();
    _selectedIndices.clear();
    _currentDragPoint = null;
    _isGameOver = false;
    _timeLeft = 90;
    // Moves = double the number of words (e.g. 5 words -> 10 moves)
    _totalMoves = _levelData.targetWords.length * 2;
    _remainingMoves = _totalMoves;
    _loadSavedShuffles();
    _flyingTiles.clear();
    _landingPopCells.clear();
    _displayedBubbleWord = '';
    _gridCellKeys.clear();
    _gameTimer?.cancel();
    CrosswordAudioHelper().stopCountdown();

    // Wordix-style interstitial ad after every 4 games
    Prefs.incrementPlayCount().then((count) {
      if (!mounted) return;
      if (count % 4 == 0 && count != 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _gameTimer?.cancel();
            CrosswordAudioHelper().stopCountdown();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdPlaybackPage(
                  isRewardAd: false,
                  onAdComplete: () {},
                ),
              ),
            ).then((_) {
              if (mounted && !_isGameOver) {
                setState(() {
                  _timeLeft = 90;
                  _remainingMoves = _totalMoves;
                });
                _startTimer();
              }
            });
          }
        });
      } else {
        _startTimer();
      }
    });
  }

  void _startTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
        if (_timeLeft == 5) {
          CrosswordAudioHelper().playCountdown();
        }
      } else {
        timer.cancel();
        _handleGameOver(reason: 'time');
      }
    });
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
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2), width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionType == 'extra_move'
                        ? 'EXTRA MOVE'
                        : actionType == 'shuffle'
                            ? 'SHUFFLE WHEEL'
                            : 'GET HINT',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    actionType == 'extra_move'
                        ? 'Use 10 coins or watch an ad to get 5 extra moves.'
                        : actionType == 'shuffle'
                            ? 'Use 5 coins or watch an ad to shuffle wheel letters.'
                            : 'Use 10 coins or watch an ad to reveal a letter.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.9)),
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
                            CrosswordAudioHelper().stopCountdown();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AdPlaybackPage(onAdComplete: () {
                                  if (actionType == 'extra_move') {
                                    _addExtraMove(useCoins: false);
                                  } else if (actionType == 'shuffle') {
                                    _performShuffleWithCoins(useCoins: false);
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
                color: Colors.black.withValues(alpha: 0.5),
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
      CrosswordAudioHelper().playCoin();
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _remainingMoves += 5;
      _totalMoves += 5;
    });
    Fluttertoast.showToast(msg: "+5 Extra Moves added!");
  }

  void _useHint({bool useCoins = true}) async {
    final coinProvider = Provider.of<CoinProvider>(context, listen: false);
    if (useCoins && coinProvider.coins < 10) {
      _showInsufficientCoinsDialog();
      return;
    }

    // Find all unrevealed cells on the grid
    final unrevealed = <String>[];
    for (final placement in _levelData.gridPlacements) {
      if (!_foundWords.contains(placement.word)) {
        for (int i = 0; i < placement.word.length; i++) {
          final r = placement.startRow + (placement.isHorizontal ? 0 : i);
          final c = placement.startCol + (placement.isHorizontal ? i : 0);
          final key = "${r}_$c";
          if (!(_revealedCells[key] ?? false)) {
            unrevealed.add(key);
          }
        }
      }
    }

    if (unrevealed.isEmpty) {
      Fluttertoast.showToast(msg: "All visible cells already solved!");
      return;
    }

    if (useCoins) {
      await coinProvider.undoCoins(10);
      CrosswordAudioHelper().playCoin();
    }
    DailyService().updateTaskProgress(
      taskKey: 'use_hint',
      increment: 1,
      gameName: 'Crossword',
    );
    CrosswordAudioHelper().playHint();
    HapticFeedback.mediumImpact();

    final chosen = unrevealed[math.Random().nextInt(unrevealed.length)];
    setState(() {
      _revealedCells[chosen] = true;
    });

    // Check if any word has now become fully revealed
    for (final placement in _levelData.gridPlacements) {
      if (!_foundWords.contains(placement.word)) {
        bool wordComplete = true;
        for (int i = 0; i < placement.word.length; i++) {
          final r = placement.startRow + (placement.isHorizontal ? 0 : i);
          final c = placement.startCol + (placement.isHorizontal ? i : 0);
          if (!(_revealedCells["${r}_$c"] ?? false)) {
            wordComplete = false;
            break;
          }
        }
        if (wordComplete) {
          _foundWords.add(placement.word);
        }
      }
    }

    Fluttertoast.showToast(
        msg: useCoins ? "Hint Revealed! -10 coins" : "Hint Revealed!");

    if (_foundWords.length >= _levelData.targetWords.length) {
      CrosswordAudioHelper().playWordMatch();
      HapticFeedback.heavyImpact();
      // Wait 1.8s so the player clearly sees the revealed word on the grid before winning
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted && !_isGameOver) {
          _handleLevelWon();
        }
      });
    }
  }

  void _onPanStart(DragStartDetails details, Size wheelSize) {
    _handleTouch(details.localPosition, wheelSize);
  }

  void _onPanUpdate(DragUpdateDetails details, Size wheelSize) {
    _handleTouch(details.localPosition, wheelSize);
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isGameOver) return;

    if (_selectedIndices.isNotEmpty) {
      final formed = _selectedIndices.map((i) => _wheelLetters[i]).join();

      // Swipe attempt of 2 or more letters counts as 1 move
      if (_selectedIndices.length >= 2) {
        setState(() {
          if (_remainingMoves > 0) {
            _remainingMoves--;
          }
        });

        _validateFormedWord(formed);

        // Immediate check if out of moves on incorrect attempt
        if (_remainingMoves <= 0 &&
            !_levelData.targetWords.contains(formed.toUpperCase()) &&
            _foundWords.length < _levelData.targetWords.length &&
            !_isGameOver) {
          _handleGameOver(reason: 'moves');
        }
      }
    }

    setState(() {
      _selectedIndices.clear();
      _currentDragPoint = null;
    });
  }

  bool _isGameOverDialogShowing = false;

  void _handleGameOver({required String reason}) {
    if (_isGameOver) return;
    _isGameOver = true;
    _gameTimer?.cancel();
    CrosswordAudioHelper().stopCountdown();
    CrosswordAudioHelper().playGameOver();

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
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      reason == 'time' ? "TIME'S UP!" : "OUT OF MOVES!",
                      style: const TextStyle(
                        fontSize: 24,
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
                      width: 170,
                      height: 170,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Would you like to try again?",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 26),
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
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AdPlaybackPage(
                                          isRewardAd: false,
                                          onAdComplete: () {
                                            if (!mounted) return;
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    CrosswordSuccessScreen(
                                                  level: widget.level,
                                                  isWin: false,
                                                  coinsEarned: 0,
                                                ),
                                              ),
                                            );
                                          },
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

                                      // Smooth spinner delay matching crossword_home / crossword_success
                                      await Future.delayed(
                                          const Duration(milliseconds: 350));
                                      await coinProvider.undoCoins(4);
                                      CrosswordAudioHelper().playCoin();
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

  void _restartLevel() {
    _gameTimer?.cancel();
    CrosswordAudioHelper().stopCountdown();
    setState(() {
      _loadLevel(widget.level);
    });
  }

  // Dynamic rotating Level Themes for exciting visual variety across levels
  static final List<CrosswordLevelTheme> _levelThemes = [
    // Level 1, 9, 17... Sunset Coral Orange
    const CrosswordLevelTheme(
      primary: Color(0xFFFF7043),
      secondary: Color(0xFFE64A19),
      glow: Color(0xFFFF9100),
      darkShadow: Color(0xFFBF360C),
    ),
    // Level 2, 10, 18... Electric Ocean Blue
    const CrosswordLevelTheme(
      primary: Color(0xFF00B4D8),
      secondary: Color(0xFF0077B6),
      glow: Color(0xFF48CAE4),
      darkShadow: Color(0xFF03045E),
    ),
    // Level 3, 11, 19... Emerald Forest Green
    const CrosswordLevelTheme(
      primary: Color(0xFF2EC4B6),
      secondary: Color(0xFF0F9D58),
      glow: Color(0xFF52B788),
      darkShadow: Color(0xFF1B4332),
    ),
    // Level 4, 12, 20... Royal Amethyst Purple
    const CrosswordLevelTheme(
      primary: Color(0xFFAB47BC),
      secondary: Color(0xFF7B1FA2),
      glow: Color(0xFFCE93D8),
      darkShadow: Color(0xFF4A148C),
    ),
    // Level 5, 13, 21... Crimson Ruby Red
    const CrosswordLevelTheme(
      primary: Color(0xFFFF3366),
      secondary: Color(0xFFD81159),
      glow: Color(0xFFFF5376),
      darkShadow: Color(0xFF880026),
    ),
    // Level 6, 14, 22... Golden Amber
    const CrosswordLevelTheme(
      primary: Color(0xFFFFB703),
      secondary: Color(0xFFFB8500),
      glow: Color(0xFFFFD166),
      darkShadow: Color(0xFFBC6C25),
    ),
    // Level 7, 15, 23... Neon Berry Magenta
    const CrosswordLevelTheme(
      primary: Color(0xFFF72585),
      secondary: Color(0xFFB5179E),
      glow: Color(0xFFFF4D9E),
      darkShadow: Color(0xFF7209B7),
    ),
    // Level 8, 16, 24... Aqua Lagoon Teal
    const CrosswordLevelTheme(
      primary: Color(0xFF06D6A0),
      secondary: Color(0xFF118AB2),
      glow: Color(0xFF48CAE4),
      darkShadow: Color(0xFF073B4C),
    ),
  ];

  CrosswordLevelTheme get _currentTheme =>
      _levelThemes[(widget.level - 1) % _levelThemes.length];

  static double calculateWheelRadius(double size, int count) {
    final nodeSize = calculateNodeSize(size, count);
    // Outer circular wheel radius: size * 0.5
    // Outer border stroke width: 3.5
    // Inner boundary = (size * 0.5) - 3.5
    // Uniform side clearance from inner border to letter edge on ALL sides: exactly 15.0 px
    const double sideClearance = 15.0;
    return (size * 0.5) - 3.5 - sideClearance - (nodeSize / 2);
  }

  static double calculateNodeSize(double size, int count) {
    if (count <= 3) return 52.0;
    if (count == 4) return 50.0;
    if (count == 5) return 48.0;
    if (count == 6) return 44.0;
    return 40.0;
  }

  void _handleTouch(Offset localPos, Size wheelSize) {
    final center = Offset(wheelSize.width / 2, wheelSize.height / 2);
    final count = _wheelLetters.length;
    final radius = calculateWheelRadius(wheelSize.width, count);
    final nodeSize = calculateNodeSize(wheelSize.width, count);

    setState(() {
      _currentDragPoint = localPos;
    });

    for (int i = 0; i < count; i++) {
      final angle = (i * 2 * math.pi / count) - (math.pi / 2);
      final nodePos = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      final distance = (localPos - nodePos).distance;
      if (distance < nodeSize * 0.65) {
        if (!_selectedIndices.contains(i)) {
          setState(() {
            _selectedIndices.add(i);
          });
          CrosswordAudioHelper().playLetterTap(_selectedIndices.length - 1);
          HapticFeedback.selectionClick();
        } else if (_selectedIndices.length > 1 &&
            _selectedIndices[_selectedIndices.length - 2] == i) {
          // Backward backtrack
          setState(() {
            _selectedIndices.removeLast();
          });
          HapticFeedback.lightImpact();
        }
      }
    }
  }

  void _validateFormedWord(String word) {
    final upper = word.toUpperCase();

    // Check if it's one of the target crossword words
    if (_levelData.targetWords.contains(upper)) {
      if (!_foundWords.contains(upper)) {
        _foundWords.add(upper);
        setState(() {
          _displayedBubbleWord = upper;
        });

        // Keep bubble word visible while letters take flight, then dismiss bubble
        Future.delayed(const Duration(milliseconds: 250), () {
          if (mounted) {
            setState(() {
              _displayedBubbleWord = '';
            });
          }
        });

        // Find grid placement for this word
        CrosswordWordPlacement? placement;
        for (final p in _levelData.gridPlacements) {
          if (p.word == upper) {
            placement = p;
            break;
          }
        }

        if (placement != null) {
          _launchFlyingLetters(upper, placement);
        } else {
          // Fallback if placement not found
          setState(() {
            for (int i = 0; i < upper.length; i++) {
              _revealedCells["${i}_0"] = true;
            }
          });
          CrosswordAudioHelper().playWordMatch();
          if (_foundWords.length >= _levelData.targetWords.length) {
            _handleLevelWon();
          }
        }
      } else {
        Fluttertoast.showToast(msg: "Already solved!");
      }
    } else {
      CrosswordAudioHelper().playNotFound();
      HapticFeedback.lightImpact();
    }
  }

  Offset _getBubblePosition() {
    final ctx = _previewBubbleKey.currentContext;
    if (ctx != null) {
      final box = ctx.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        return box.localToGlobal(Offset.zero);
      }
    }
    final media = MediaQuery.of(context);
    return Offset(media.size.width / 2 - 70, media.size.height * 0.50);
  }

  Offset? _getCellPosition(String key) {
    final ctx = _gridCellKeys[key]?.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero);
  }

  void _launchFlyingLetters(String word, CrosswordWordPlacement placement) {
    final List<_FlyingTileData> newTiles = [];
    final bubbleOffset = _getBubblePosition();
    const bubbleWidth = 140.0;
    final bubbleCenter =
        Offset(bubbleOffset.dx + (bubbleWidth / 2), bubbleOffset.dy + 24.0);
    final tileSize = _currentCellSize > 0 ? _currentCellSize : 42.0;

    for (int i = 0; i < word.length; i++) {
      final ch = word[i];
      final r = placement.startRow + (placement.isHorizontal ? 0 : i);
      final c = placement.startCol + (placement.isHorizontal ? i : 0);
      final cellKey = "${r}_$c";

      final startOffset = Offset(
        bubbleCenter.dx + (i - (word.length - 1) / 2.0) * 22.0 - (tileSize / 2),
        bubbleCenter.dy - (tileSize / 2),
      );

      final targetPos = _getCellPosition(cellKey) ??
          Offset(bubbleCenter.dx, bubbleCenter.dy - 180.0);

      newTiles.add(_FlyingTileData(
        key: UniqueKey(),
        letter: ch,
        startOffset: startOffset,
        endOffset: targetPos,
        tileSize: tileSize,
        cellKey: cellKey,
        delayMs: i * 110,
        theme: _currentTheme,
        isLastOfWord: i == word.length - 1,
      ));
    }

    setState(() {
      _flyingTiles.addAll(newTiles);
    });
  }

  void _handleTileArrived(_FlyingTileData tile) {
    if (!mounted) return;

    setState(() {
      _revealedCells[tile.cellKey] = true;
      _landingPopCells.add(tile.cellKey);
      _flyingTiles.removeWhere((t) => t.key == tile.key);
    });

    HapticFeedback.selectionClick();
    CrosswordAudioHelper().playTileLand();

    Future.delayed(const Duration(milliseconds: 260), () {
      if (mounted) {
        setState(() {
          _landingPopCells.remove(tile.cellKey);
        });
      }
    });

    if (tile.isLastOfWord) {
      CrosswordAudioHelper().playWordMatch();
      HapticFeedback.heavyImpact();

      if (_foundWords.length >= _levelData.targetWords.length) {
        _handleLevelWon();
      } else if (_remainingMoves <= 0 && !_isGameOver) {
        _handleGameOver(reason: 'moves');
      }
    }
  }

  void _handleLevelWon() {
    if (_isGameOver) return;
    _isGameOver = true;
    DailyService().updateTaskProgress(
      taskKey: 'win_crossword',
      increment: 1,
      gameName: 'Crossword',
    );
    _gameTimer?.cancel();
    CrosswordAudioHelper().stopCountdown();
    CrosswordAudioHelper().playWinner();

    final movesUsed = math.max(0, _totalMoves - _remainingMoves);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdPlaybackPage(
            isRewardAd: false,
            onAdComplete: () {
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => CrosswordSuccessScreen(
                    level: widget.level,
                    coinsEarned: 3,
                    isWin: true,
                    movesUsed: movesUsed,
                  ),
                ),
              );
            },
          ),
        ),
      );
    });
  }

  void _showExitConfirmationDialog() {
    _gameTimer?.cancel();
    CrosswordAudioHelper().stopCountdown();

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
                color: const Color(0xFF1B4332).withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'PAUSE GAME?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Do you want to return to the Crossword menu?',
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
                                    const CrosswordHomeScreen(),
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

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isNarrow = screenWidth < 360;

    final currentWordText = _displayedBubbleWord.isNotEmpty
        ? _displayedBubbleWord
        : _selectedIndices.map((i) => _wheelLetters[i]).join();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _showExitConfirmationDialog();
        }
      },
      child: Scaffold(
        body: CrosswordNatureBackground(
          child: Stack(
            children: [
              SafeArea(
                child: Column(
                  children: [
                    // 1. Top HUD Bar (Wordix style: Back+Level on Left, Coins in Center, Hint & Extra Moves on Right)
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: isNarrow ? 10.0 : 16.0, vertical: 8.0),
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
                                  horizontal: isNarrow ? 8 : 10),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.arrow_back_rounded,
                                      color: Colors.white,
                                      size: isNarrow ? 18.0 : 20.0),
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
                                    'hint', () => _useHint()),
                              ),
                              SizedBox(width: isNarrow ? 6.0 : 10.0),
                              CustomHintButton(
                                icon: Icons.auto_fix_high,
                                value: 10,
                                showCoin: true,
                                onPressed: () => _showConfirmationDialog(
                                    'extra_move', () => _addExtraMove()),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // 2. Crossword Grid (Upper Box - Full space available)
                    Expanded(
                      flex: 5,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 6.0),
                          child: _buildCrosswordGrid(),
                        ),
                      ),
                    ),

                    // 3. Selected Word Preview Floating Bubble
                    SizedBox(
                      height: 48,
                      child: Center(
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 180),
                          scale: currentWordText.isNotEmpty ? 1.0 : 0.0,
                          child: Container(
                            key: _previewBubbleKey,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 26, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _currentTheme.primary,
                                  _currentTheme.secondary,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white,
                                width: 2.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _currentTheme.primary
                                      .withValues(alpha: 0.65),
                                  blurRadius: 18,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 4),
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              currentWordText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3.0,
                                shadows: [
                                  Shadow(
                                    color: Colors.black45,
                                    offset: Offset(0, 2),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 4. Circular Letter Wheel with Bottom Overlay Stats (Timer & Moves)
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.only(
                            bottom: 16.0, left: 16.0, right: 16.0),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Center: Letter Wheel
                            Center(
                              child: _buildLetterWheel(),
                            ),

                            // Top-Right: 3D Shuffle Button (located in the 2nd red mark position!)
                            Positioned(
                              top: 10,
                              right: 14,
                              child: _buildShuffleButton(),
                            ),

                            // Bottom Overlay: Timer on Left, Moves on Right (zero obstruction & maximum board space)
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildTimerBadge(),
                                  _buildMovesBadge(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Flying letters overlay on top of everything!
              ..._flyingTiles.map((tile) => _FlyingTileWidget(
                    key: tile.key,
                    data: tile,
                    onArrived: () => _handleTileArrived(tile),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // Crossword Grid Builder
  Widget _buildCrosswordGrid() {
    final cols = _levelData.calculatedCols;
    final rows = _levelData.calculatedRows;

    // Build 2D lookup of cells:
    // (r, c) -> target letter
    final Map<String, String> cellLetters = {};
    for (final p in _levelData.gridPlacements) {
      for (int i = 0; i < p.word.length; i++) {
        final r = p.startRow + (p.isHorizontal ? 0 : i);
        final c = p.startCol + (p.isHorizontal ? i : 0);
        cellLetters["${r}_$c"] = p.word[i];
      }
    }

    return LayoutBuilder(builder: (context, constraints) {
      final slotW = (constraints.maxWidth - 8.0) / cols;
      final slotH = (constraints.maxHeight - 8.0) / rows;
      final slotSize = math.min(slotW, slotH).clamp(36.0, 54.0);
      const cellMargin = 2.5;
      final innerCellSize = slotSize - (cellMargin * 2);
      _currentCellSize = innerCellSize;

      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(rows, (r) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(cols, (c) {
              final key = "${r}_$c";
              final hasCell = cellLetters.containsKey(key);

              if (!hasCell) {
                // Must have the exact same slot size so every row and column is 100% straight
                return SizedBox(
                  width: slotSize,
                  height: slotSize,
                );
              }

              final cellKey = _gridCellKeys.putIfAbsent(key, () => GlobalKey());
              final letter = cellLetters[key]!;
              final isRevealed = _revealedCells[key] ?? false;
              final isPopping = _landingPopCells.contains(key);

              return SizedBox(
                width: slotSize,
                height: slotSize,
                child: Center(
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 240),
                    scale: isPopping ? 1.25 : 1.0,
                    curve: Curves.elasticOut,
                    child: Container(
                      key: cellKey,
                      width: innerCellSize,
                      height: innerCellSize,
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(innerCellSize * 0.22),
                        gradient: isRevealed
                            ? LinearGradient(
                                colors: [
                                  _currentTheme.primary,
                                  _currentTheme.secondary,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isRevealed
                            ? null
                            : Colors.white.withValues(alpha: 0.18),
                        border: Border.all(
                          color: isRevealed
                              ? Colors.white.withValues(alpha: 0.85)
                              : Colors.white.withValues(alpha: 0.25),
                          width: isRevealed ? 1.8 : 1.2,
                        ),
                        boxShadow: isRevealed
                            ? [
                                BoxShadow(
                                  color: _currentTheme.darkShadow,
                                  offset: const Offset(0, 3.5),
                                  blurRadius: 0,
                                ),
                                BoxShadow(
                                  color: _currentTheme.primary
                                      .withValues(alpha: 0.45),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Center(
                        child: isRevealed
                            ? Text(
                                letter,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: innerCellSize * 0.55,
                                  fontWeight: FontWeight.w900,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black45,
                                      offset: Offset(0, 1.5),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      );
    });
  }

  // Interactive Circular Letter Wheel
  Widget _buildLetterWheel() {
    return LayoutBuilder(builder: (context, constraints) {
      final size = math.min(constraints.maxHeight, 220.0);
      final count = _wheelLetters.length;
      final nodeSize = calculateNodeSize(size, count);
      final radius = calculateWheelRadius(size, count);
      final center = Offset(size / 2, size / 2);

      return SizedBox(
        key: _wheelKey,
        width: size,
        height: size,
        child: GestureDetector(
          onPanStart: (d) => _onPanStart(d, Size(size, size)),
          onPanUpdate: (d) => _onPanUpdate(d, Size(size, size)),
          onPanEnd: _onPanEnd,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // 1. Concentric Outer Circular Wheel (Zero padding drift)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.50),
                      width: 3.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.15),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Custom Painter for connecting swipe lines
              Positioned.fill(
                child: CustomPaint(
                  painter: _WheelConnectPainter(
                    letters: _wheelLetters,
                    selectedIndices: _selectedIndices,
                    dragPoint: _currentDragPoint,
                    theme: _currentTheme,
                  ),
                ),
              ),

              // 3. Exactly centered letter nodes with 360° shuffle orbit animation
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _shuffleAnimation,
                  builder: (context, child) {
                    final spinAngle = _shuffleAnimation.value * 2 * math.pi;
                    final spinScale = 1.0 -
                        (0.20 * math.sin(_shuffleAnimation.value * math.pi));
                    return Transform.rotate(
                      angle: spinAngle,
                      child: Transform.scale(
                        scale: spinScale,
                        child: child,
                      ),
                    );
                  },
                  child: Stack(
                    children: List.generate(_wheelLetters.length, (i) {
                      final angle = (i * 2 * math.pi / count) - (math.pi / 2);
                      final nodePos = Offset(
                        center.dx + radius * math.cos(angle),
                        center.dy + radius * math.sin(angle),
                      );
                      final isSelected = _selectedIndices.contains(i);

                      return Positioned(
                        left: nodePos.dx - nodeSize / 2,
                        top: nodePos.dy - nodeSize / 2,
                        width: nodeSize,
                        height: nodeSize,
                        child: AnimatedBuilder(
                          animation: _shuffleAnimation,
                          builder: (context, letterChild) {
                            return Transform.rotate(
                              angle: -(_shuffleAnimation.value * 2 * math.pi),
                              child: letterChild,
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            width: nodeSize,
                            height: nodeSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: isSelected
                                  ? LinearGradient(
                                      colors: [
                                        _currentTheme.glow,
                                        _currentTheme.secondary,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: isSelected
                                  ? null
                                  : Colors.white.withValues(alpha: 0.88),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF2D6A4F)
                                        .withValues(alpha: 0.4),
                                width: isSelected ? 2.5 : 1.5,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: _currentTheme.primary
                                            .withValues(alpha: 0.75),
                                        blurRadius: 14,
                                        spreadRadius: 3,
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.25),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                            ),
                            child: Center(
                              child: Text(
                                _wheelLetters[i],
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF1B4332),
                                  fontSize: nodeSize * 0.52,
                                  fontWeight: FontWeight.w900,
                                  shadows: isSelected
                                      ? const [
                                          Shadow(
                                            color: Colors.black45,
                                            offset: Offset(0, 1.5),
                                            blurRadius: 3,
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // 3D Glassmorphic Radiant Shuffle Button
  Widget _buildShuffleButton() {
    return AnimatedBuilder(
      animation: _shuffleAnimation,
      builder: (context, child) {
        final scale =
            1.0 - (0.16 * math.sin(_shuffleAnimation.value * math.pi));
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: _onShuffleTapped,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                _currentTheme.primary,
                _currentTheme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.85),
              width: 2.2,
            ),
            boxShadow: [
              // 3D bottom dark shadow for tactile extrusion
              BoxShadow(
                color: _currentTheme.darkShadow,
                offset: const Offset(0, 4.0),
                blurRadius: 0,
              ),
              // Radiant theme glow
              BoxShadow(
                color: _currentTheme.glow.withValues(alpha: 0.6),
                blurRadius: 16,
                spreadRadius: 2,
                offset: const Offset(0, 2),
              ),
              // Ambient soft floor shadow
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 8,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Top-left shiny glass glare pill
              Positioned(
                top: 3,
                left: 8,
                child: Container(
                  width: 18,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              // Inside content: Shuffle Icon + value underneath
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RotationTransition(
                    turns: _shuffleAnimation,
                    child: const Icon(
                      Icons.shuffle_rounded,
                      color: Colors.white,
                      size: 22,
                      shadows: [
                        Shadow(
                          color: Colors.black45,
                          offset: Offset(0, 1.5),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 1),
                  if (_remainingShuffles <= 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/coin.png',
                          width: 11,
                          height: 11,
                        ),
                        const SizedBox(width: 2),
                        const Text(
                          '5',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            fontFamily: 'Inder',
                            height: 1.0,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                offset: Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      '$_remainingShuffles',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        fontFamily: 'Inder',
                        height: 1.0,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            offset: Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Level Theme Definition
class CrosswordLevelTheme {
  final Color primary;
  final Color secondary;
  final Color glow;
  final Color darkShadow;

  const CrosswordLevelTheme({
    required this.primary,
    required this.secondary,
    required this.glow,
    required this.darkShadow,
  });
}

/// Custom painter for letter wheel connecting lines
class _WheelConnectPainter extends CustomPainter {
  final List<String> letters;
  final List<int> selectedIndices;
  final Offset? dragPoint;
  final CrosswordLevelTheme theme;

  _WheelConnectPainter({
    required this.letters,
    required this.selectedIndices,
    required this.dragPoint,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (selectedIndices.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final count = letters.length;
    final radius =
        _CrosswordGameScreenState.calculateWheelRadius(size.width, count);

    final List<Offset> points = [];
    for (final idx in selectedIndices) {
      final angle = (idx * 2 * math.pi / count) - (math.pi / 2);
      points.add(Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      ));
    }

    final linePaint = Paint()
      ..color = theme.primary
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = theme.glow.withValues(alpha: 0.5)
      ..strokeWidth = 22.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    if (dragPoint != null) {
      path.lineTo(dragPoint!.dx, dragPoint!.dy);
    }

    // Draw glow and main orange connecting line
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(_WheelConnectPainter oldDelegate) => true;
}

/// Flying Letter Tile Data Model
class _FlyingTileData {
  final Key key;
  final String letter;
  final Offset startOffset;
  final Offset endOffset;
  final double tileSize;
  final String cellKey;
  final int delayMs;
  final CrosswordLevelTheme theme;
  final bool isLastOfWord;

  _FlyingTileData({
    required this.key,
    required this.letter,
    required this.startOffset,
    required this.endOffset,
    required this.tileSize,
    required this.cellKey,
    required this.delayMs,
    required this.theme,
    required this.isLastOfWord,
  });
}

/// Flying Letter Tile Animated Widget
class _FlyingTileWidget extends StatefulWidget {
  final _FlyingTileData data;
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
  late AnimationController _controller;
  late Animation<double> _curve;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.25), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 65),
    ]).animate(_controller);

    Future.delayed(Duration(milliseconds: widget.data.delayMs), () {
      if (mounted) {
        _controller.forward().then((_) {
          widget.onArrived();
        });
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
        if (_controller.value == 0 && widget.data.delayMs > 0) {
          return const SizedBox.shrink();
        }

        final t = _curve.value;
        final dx = lerpDouble(
            widget.data.startOffset.dx, widget.data.endOffset.dx, t)!;
        final linearDy = lerpDouble(
            widget.data.startOffset.dy, widget.data.endOffset.dy, t)!;
        // Parabolic arc displacement
        final arcOffset = math.sin(t * math.pi) * -28.0;
        final dy = linearDy + arcOffset;

        return Positioned(
          left: dx,
          top: dy,
          child: Transform.scale(
            scale: _scale.value,
            child: Container(
              width: widget.data.tileSize,
              height: widget.data.tileSize,
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(widget.data.tileSize * 0.22),
                gradient: LinearGradient(
                  colors: [
                    widget.data.theme.primary,
                    widget.data.theme.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Colors.white,
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.data.theme.glow.withValues(alpha: 0.85),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                  const BoxShadow(
                    color: Colors.black45,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.data.letter,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: widget.data.tileSize * 0.55,
                    fontWeight: FontWeight.w900,
                    shadows: const [
                      Shadow(
                        color: Colors.black45,
                        offset: Offset(0, 1.5),
                        blurRadius: 2,
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
