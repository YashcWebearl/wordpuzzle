import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:word_puzzle/view/success_screen.dart';
import 'package:word_puzzle/db/prefs.dart';
import 'package:word_puzzle/widget/bg_container.dart';
import 'package:word_puzzle/widget/button.dart';
import 'package:word_puzzle/widget/coin_container.dart';
import 'package:word_puzzle/widget/coin_service.dart';
import 'package:word_puzzle/widget/found_word.dart';
import 'package:word_puzzle/widget/hint_button.dart';
import 'package:word_puzzle/widget/sound.dart';
import 'package:word_puzzle/widget/word_highliter.dart';
import 'package:word_puzzle/view/ad_show.dart';

class WordSearchPage extends StatefulWidget {
  final int initialLevel;
  final int gridSize;

  const WordSearchPage({
    super.key,
    required this.initialLevel,
    required this.gridSize,
  });

  @override
  WordSearchPageState createState() => WordSearchPageState();
}

class WordSearchPageState extends State<WordSearchPage>
    with TickerProviderStateMixin {
  late int level;
  late int timeLeft;
  late int gridSize;
  late int moveCount;
  bool _lastSecondSoundPlayed = false;

  int? maxMoves;
  late AnimationController _animationController;
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;
  bool _isDialogShowing = false;
  Timer? _timer;
  Timer? _hintTimer;
  List<Offset>? _hintedPath;
  List<Offset> _currentDragPath = [];
  List<String> _currentWords = [];
  late List<List<String>> _grid;
  Offset? _start;
  Offset? _end;
  final Map<String, List<Offset>> _foundWordPaths = {};
  final Random _random = Random();
  final List<String> _usedWords = [];

  static const _wordBank = {
    'tech': [
      'flutter',
      'dart',
      'code',
      'grid',
      'puzzle',
      'game',
      'level',
      'timer',
      'bonus',
      'software'
    ],
    'nature': [
      'forest',
      'river',
      'mountain',
      'ocean',
      'desert',
      'valley',
      'canyon',
      'lake',
      'tree',
      'flower'
    ],
    'general': [
      'challenge',
      'logic',
      'solve',
      'fun',
      'adventure',
      'mystery',
      'quest',
      'journey',
      'travel',
      'dream'
    ],
  };

  static const _directions = [
    [0, 1],
    [1, 0],
    [1, 1],
    [-1, 1],
    [0, -1],
    [-1, 0],
    [-1, -1],
    [1, -1]
  ];

  static const _highlightColors = [
    Color(0xFFFFB300),
    Color(0xFF4DB6AC),
    Color(0xFFCE93D8),
    Color(0xFF64B5F6),
    Color(0xFFF06292),
  ];

  @override
  void initState() {
    super.initState();
    AudioHelper().playScreenOpenSound();

    level = widget.initialLevel;
    gridSize = widget.gridSize;
    timeLeft = 90;
    moveCount = 0;
    maxMoves = 0; // Initialize early to avoid LateInitializationError
    _currentWords = []; // Initialize early
    _grid = List.generate(gridSize, (_) => List.filled(gridSize, ''));
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _blinkController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..repeat(reverse: true);
    _blinkAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startLevel();
      _animationController.forward();
    });
  }

  Future<void> _startLevel() async {
    try {
      final potentialWords = _generateDynamicWords();
      _grid = List.generate(gridSize, (_) => List.filled(gridSize, ''));
      _currentWords = [];

      for (final word in potentialWords) {
        if (_placeWord(word, _grid)) {
          _currentWords.add(word);
        }
      }

      // Fill remaining empty cells with random letters
      for (var r = 0; r < gridSize; r++) {
        for (var c = 0; c < gridSize; c++) {
          if (_grid[r][c].isEmpty)
            _grid[r][c] = String.fromCharCode(65 + _random.nextInt(26));
        }
      }

      moveCount = 0;
      maxMoves = _currentWords.length + 2;
      _foundWordPaths.clear();
      _currentDragPath.clear();
      _start = _end = null;
      _hintedPath = null;
      _hintTimer?.cancel();
      _timer?.cancel();
      timeLeft = 90;
      _lastSecondSoundPlayed = false;
      _startTimer();

      Prefs.incrementPlayCount().then((count) {
        if (count % 4 == 0 && count != 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted)
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          AdPlaybackPage(onAdComplete: () {})));
          });
        }
      });
      if (mounted) setState(() {});
    } catch (e) {
      print('Error starting level: $e');
    }
  }

  List<String> _generateDynamicWords() {
    final availableWords = _wordBank.values
        .expand((words) => words)
        .where((word) => word.length <= gridSize && !_usedWords.contains(word))
        .toList();
    if (availableWords.length < 5 + level) {
      _usedWords.clear();
      availableWords.addAll(_wordBank.values
          .expand((words) => words)
          .where((word) => word.length <= gridSize));
    }
    availableWords.shuffle(_random);
    final selectedWords = availableWords
        .take(min(availableWords.length, 4 + gridSize ~/ 2))
        .map((word) => word.toUpperCase())
        .toList();
    _usedWords.addAll(selectedWords);
    return selectedWords;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        timeLeft--;
        if (timeLeft <= 5 && !_lastSecondSoundPlayed) {
          AudioHelper().playLastSecond();
          _lastSecondSoundPlayed = true;
        }
        if (timeLeft <= 0) {
          t.cancel();
          AudioHelper().stopLastSecond();
          if (!_isDialogShowing) _showGameOverDialog(reason: 'time');
        }
      });
    });
  }

  void _showConfirmationDialog(String actionType, VoidCallback onConfirm) {
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
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                    color: Colors.white.withOpacity(0.2), width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionType == 'extra_move' ? 'EXTRA MOVE' : 'GET HINT',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    actionType == 'extra_move'
                        ? 'Use 10 coins or watch an ad to get an extra move.'
                        : 'Use 10 coins or watch an ad to reveal a word.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 16, color: Colors.white.withOpacity(0.9)),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                          child: AppButton(
                              label: '10 Coins',
                              onTap: () {
                                Navigator.pop(context);
                                onConfirm();
                              })),
                      const SizedBox(width: 10),
                      Expanded(
                          child: AppButton(
                              label: 'AD',
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            AdPlaybackPage(onAdComplete: () {
                                              if (actionType == 'extra_move')
                                                _addExtraMove(useCoins: false);
                                              else
                                                _showHint(useCoins: false);
                                            })));
                              })),
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

  bool _placeWord(String word, List<List<String>> grid) {
    for (var attempt = 0; attempt < 100; attempt++) {
      final dir = _directions[_random.nextInt(_directions.length)];
      final r = _random.nextInt(gridSize);
      final c = _random.nextInt(gridSize);
      if (r + dir[0] * (word.length - 1) < 0 ||
          r + dir[0] * (word.length - 1) >= gridSize ||
          c + dir[1] * (word.length - 1) < 0 ||
          c + dir[1] * (word.length - 1) >= gridSize) continue;

      var fits = true;
      for (var i = 0; i < word.length; i++) {
        final nr = r + dir[0] * i, nc = c + dir[1] * i;
        if (grid[nr][nc].isNotEmpty && grid[nr][nc] != word[i]) {
          fits = false;
          break;
        }
      }
      if (fits) {
        for (var i = 0; i < word.length; i++)
          grid[r + dir[0] * i][c + dir[1] * i] = word[i];
        return true;
      }
    }
    return false;
  }

  void _handleDragStart(DragStartDetails details, double cellSize) {
    final col =
        (details.localPosition.dx / cellSize).floor().clamp(0, gridSize - 1);
    final row =
        (details.localPosition.dy / cellSize).floor().clamp(0, gridSize - 1);
    _start = Offset(col.toDouble(), row.toDouble());
    setState(() => _currentDragPath = [_start!]);
    AudioHelper().playDragWordSound();
  }

  void _handleDragUpdate(DragUpdateDetails details, double cellSize) {
    final col =
        (details.localPosition.dx / cellSize).floor().clamp(0, gridSize - 1);
    final row =
        (details.localPosition.dy / cellSize).floor().clamp(0, gridSize - 1);
    final newEnd = Offset(col.toDouble(), row.toDouble());
    if (_start != null && _isValidDirection(_start!, newEnd)) {
      setState(() {
        _end = newEnd;
        _currentDragPath = _getPointsOnPath(_start!, newEnd);
      });
    }
  }

  bool _isValidDirection(Offset a, Offset b) {
    final dx = (b.dx - a.dx).abs(), dy = (b.dy - a.dy).abs();
    return dx == 0 || dy == 0 || dx == dy;
  }

  List<Offset> _getPointsOnPath(Offset a, Offset b) {
    final points = <Offset>[];
    final dx = (b.dx - a.dx), dy = (b.dy - a.dy);
    final steps = max(dx.abs(), dy.abs()).round();
    final stepX = steps == 0 ? 0 : dx / steps,
        stepY = steps == 0 ? 0 : dy / steps;
    for (var i = 0; i <= steps; i++)
      points.add(Offset(a.dx + i * stepX, a.dy + i * stepY));
    return points;
  }

  Future<void> _handleDragEnd() async {
    if (_start != null && _end != null) {
      final selectedWord = _getSelectedWord(_start!, _end!);
      if (_currentWords.contains(selectedWord) &&
          !_foundWordPaths.containsKey(selectedWord)) {
        setState(() => _foundWordPaths[selectedWord] = _currentDragPath);
        AudioHelper().playFoundSound();
        if (_foundWordPaths.length == _currentWords.length) {
          _timer?.cancel();
          await Prefs.saveMaxLevel(gridSize, level + 1);
          _showSuccessDialog();
        }
      } else {
        AudioHelper().playNotFoundSound();
      }
      moveCount++;
      if (moveCount >= (maxMoves ?? 0) &&
          _foundWordPaths.length < _currentWords.length)
        _showGameOverDialog(reason: 'moves');
    }
    setState(() {
      _start = _end = null;
      _currentDragPath = [];
    });
  }

  String _getSelectedWord(Offset a, Offset b) {
    final path = _getPointsOnPath(a, b);
    return path.map((p) => _grid[p.dy.round()][p.dx.round()]).join();
  }

  void _showHint({bool useCoins = true}) {
    final coinProvider = Provider.of<CoinProvider>(context, listen: false);
    if (useCoins && coinProvider.coins < 10) {
      _showInsufficientCoinsDialog();
      return;
    }
    if (useCoins) coinProvider.undoCoins(10);

    final unfinished =
        _currentWords.where((w) => !_foundWordPaths.containsKey(w)).toList();
    if (unfinished.isEmpty) return;
    final hintWord = unfinished[_random.nextInt(unfinished.length)];
    _hintedPath = _findWordPathInGrid(hintWord);
    setState(() {});
    _hintTimer = Timer(
        const Duration(seconds: 4), () => setState(() => _hintedPath = null));
  }

  List<Offset>? _findWordPathInGrid(String word) {
    for (var r = 0; r < gridSize; r++) {
      for (var c = 0; c < gridSize; c++) {
        for (final dir in _directions) {
          var found = true;
          for (var i = 0; i < word.length; i++) {
            final nr = r + dir[0] * i, nc = c + dir[1] * i;
            if (nr < 0 ||
                nr >= gridSize ||
                nc < 0 ||
                nc >= gridSize ||
                _grid[nr][nc] != word[i]) {
              found = false;
              break;
            }
          }
          if (found)
            return List.generate(
                word.length,
                (i) => Offset(
                    (c + dir[1] * i).toDouble(), (r + dir[0] * i).toDouble()));
        }
      }
    }
    return null;
  }

  void _addExtraMove({bool useCoins = true}) {
    final coinProvider = Provider.of<CoinProvider>(context, listen: false);
    if (useCoins && coinProvider.coins < 10) {
      _showInsufficientCoinsDialog();
      return;
    }
    if (useCoins) coinProvider.undoCoins(10);
    setState(() => maxMoves = (maxMoves ?? 0) + 5);
  }

  void _showSuccessDialog() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => SuccessScreen(
                  level: level,
                  coin: 20,
                  gridSize: gridSize,
                  onNextLevel: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => WordSearchPage(
                                initialLevel: level + 1,
                                gridSize: gridSize,
                              ))),
                  onBackToLevels: () => Navigator.pop(context),
                )));
  }

  void _showGameOverDialog({required String reason}) {
    if (_isDialogShowing) return;
    _isDialogShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                    color: Colors.white.withOpacity(0.2), width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(reason == 'time' ? "TIME'S UP!" : "OUT OF MOVES!",
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white)),
                  const SizedBox(height: 15),
                  reason == 'time' ? Image.asset('assets/time_out.png', width: 200, height: 200) : Image.asset('assets/out_of_moves.png', width: 200, height: 200) ,
                  SizedBox(height: 10),
                  const Text("Would you like to try again?",
                      style: TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                          child: AppButton(
                              label: 'EXIT',
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.pop(context);
                              })),
                      const SizedBox(width: 10),
                      Expanded(
                          child: AppButton(
                              label: 'RETRY',
                              onTap: () {
                                Navigator.pop(context);
                                _startLevel();
                              })),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).then((_) => _isDialogShowing = false);
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
                color: Colors.black.withOpacity(0.5),
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
                  AppButton(label: 'OK', onTap: () => Navigator.pop(context)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showExitConfirmationDialog(BuildContext context) {
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
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('EXIT GAME?',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white)),
                  const SizedBox(height: 15),
                  const Text('Your progress in this level will be lost.',
                      style: TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                          child: AppButton(
                              label: 'NO',
                              onTap: () => Navigator.pop(context))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: AppButton(
                              label: 'YES',
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.pop(context);
                              })),
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
  Widget build(BuildContext context) {
    if (_currentWords.isEmpty ||
        _grid.isEmpty ||
        _grid.any((row) => row.isEmpty)) {
      return WillPopScope(
        onWillPop: () async {
          _showExitConfirmationDialog(context);
          return false;
        },
        child: Scaffold(
          body: BackgroundContainer(
            child: const Center(
                child: CircularProgressIndicator(color: Colors.white)),
          ),
        ),
      );
    }
    final cellSize = (MediaQuery.of(context).size.width - 40) / gridSize;
    return WillPopScope(
      onWillPop: () async {
        _showExitConfirmationDialog(context);
        return false;
      },
      child: Scaffold(
        body: BackgroundContainer(
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => _showExitConfirmationDialog(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(20)),
                          child: Row(children: [
                            const Icon(Icons.arrow_back, color: Colors.white),
                            const SizedBox(width: 8),
                            Text('Level $level',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold))
                          ]),
                        ),
                      ),
                      const CoinBalanceWidget(),
                      Row(
                        children: [
                          CustomHintButton(
                              icon: Icons.lightbulb_outline,
                              value: 10,
                              onPressed: () => _showConfirmationDialog(
                                  'hint', () => _showHint())),
                          const SizedBox(width: 12),
                          CustomHintButton(
                              icon: Icons.auto_fix_high,
                              value: (maxMoves ?? 0) - moveCount,
                              showCoin: false,
                              onPressed: () => _showConfirmationDialog(
                                  'extra_move', () => _addExtraMove())),
                        ],
                      ),
                    ],
                  ),
                ),
          // Padding(
          //     padding:
          //     const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          //     child: Row(
          //       mainAxisAlignment: MainAxisAlignment.end,
          //       children: [
          //
          //       ],
          //     ),
          //   ),
                // Premium Glass Header for Word Category
                // Container(
                //   margin: const EdgeInsets.symmetric(horizontal: 20),
                //   padding:
                //       const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                //   decoration: BoxDecoration(
                //     gradient: const LinearGradient(
                //         colors: [Color(0xFF8BC34A), Color(0xFF388E3C)],
                //         begin: Alignment.topLeft,
                //         end: Alignment.bottomRight),
                //     borderRadius: BorderRadius.circular(20),
                //     boxShadow: [
                //       BoxShadow(
                //           color: Colors.black.withOpacity(0.3),
                //           blurRadius: 10,
                //           offset: const Offset(0, 4))
                //     ],
                //   ),
                //   child: const Text('SEARCH WORDS',
                //       style: TextStyle(
                //           color: Colors.white,
                //           fontSize: 22,
                //           fontWeight: FontWeight.w900,
                //           letterSpacing: 2)),
                // ),
                // const SizedBox(height: 15),
                // Moves Left Indicator
                // Text(
                //   'MOVES LEFT: ${(maxMoves ?? 0) - moveCount}',
                //   style: const TextStyle(
                //     color: Colors.white,
                //     fontSize: 18,
                //     fontWeight: FontWeight.w900,
                //     letterSpacing: 1.2,
                //   ),
                // ),
                const SizedBox(height: 30),
                // Found words indicator (Grouped in one dark glass container)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 10,
                          alignment: WrapAlignment.center,
                          children: _currentWords.map((word) {
                            final found = _foundWordPaths.containsKey(word);
                            return Text(
                              word,
                              style: TextStyle(
                                color: found
                                    ? Colors.white.withOpacity(0.3)
                                    : Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                decoration:
                                    found ? TextDecoration.lineThrough : null,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 40),
                // const Spacer(),
                // Game Board
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: GestureDetector(
                    onPanStart: (d) => _handleDragStart(d, cellSize),
                    onPanUpdate: (d) => _handleDragUpdate(d, cellSize),
                    onPanEnd: (_) => _handleDragEnd(),
                    child: Container(
                      width: cellSize * gridSize,
                      height: cellSize * gridSize,
                      decoration: BoxDecoration(
                          color: Colors.black
                              .withOpacity(0.4), // Darker background
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.2))),
                      child: Stack(
                        children: [
                          CustomPaint(
                              painter: WordLinePainter(
                                  foundWordPaths: _foundWordPaths,
                                  hintedPath: _hintedPath,
                                  cellSize: cellSize,
                                  colors: _highlightColors,
                                  blinkValue: _blinkAnimation.value)),
                          CustomPaint(
                              painter: DragLinePainter(
                                  start: _start,
                                  end: _end,
                                  cellSize: cellSize,
                                  gridSize: gridSize)),
                          GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: gridSize),
                            itemCount: gridSize * gridSize,
                            itemBuilder: (c, i) => Center(
                                child: Text(_grid[i ~/ gridSize][i % gridSize],
                                    style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white))),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Spacer(),

                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(15)),
                          child: Text('Time: $timeLeft',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900))),
                      //
                      // Container(
                      //     padding: const EdgeInsets.all(12),
                      //     decoration: BoxDecoration(
                      //         color: Colors.black.withOpacity(0.4),
                      //         borderRadius: BorderRadius.circular(15)),
                      //     child: Text('Moves: ${(maxMoves ?? 0) - moveCount}',
                      //         style: const TextStyle(
                      //             color: Colors.white,
                      //             fontWeight: FontWeight.w900))),
                      movesCircle((maxMoves ?? 0) - moveCount,maxMoves!)
                    ],
                  ),
                ),
                // Padding(
                //   padding:
                //   const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                //   child: Row(
                //     mainAxisAlignment: MainAxisAlignment.end,
                //     children: [
                //       const CoinBalanceWidget(),
                //     ],
                //   ),
                // ),
                SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget movesCircle(int remainingMoves, int totalMoves, {double size = 70}) {

    double progress = remainingMoves / totalMoves;

    Color ringColor;
    if (progress > 0.6) {
      // ringColor = Colors.cyanAccent;
      ringColor = Colors.yellowAccent;
    } else if (progress > 0.3) {
      ringColor = Colors.orangeAccent;
    } else {
      ringColor = Colors.red;
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [

          /// Outer glow
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ringColor.withOpacity(0.5),
                  blurRadius: 40,
                  spreadRadius: 5,
                )
              ],
            ),
          ),

          /// Progress ring
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation(ringColor),
            ),
          ),

          /// Inner glass circle
          Container(
            width: size * 0.80,
            height: size * 0.80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.black.withOpacity(0.4),
                  Colors.black.withOpacity(0.4),
                ],
              ),
              border: Border.all(
                color: Colors.white24,
                width: 1.5,
              ),
            ),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                const Text(
                  "MOVES",
                  style: TextStyle(
                    fontSize: 12,
                    // letterSpacing: 3,
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // const SizedBox(height: 4),

                Text(
                  "$remainingMoves",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ringColor,
                    shadows: [
                      Shadow(
                        color: ringColor,
                        blurRadius: 20,
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  @override
  void dispose() {
    _timer?.cancel();
    _hintTimer?.cancel();
    _animationController.dispose();
    _blinkController.dispose();
    super.dispose();
  }
}
