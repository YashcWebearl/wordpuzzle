import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'success_screen.dart';
import 'package:word_puzzle/db/prefs.dart';
import 'package:word_puzzle/widget/app_3d_button.dart';
import 'package:word_puzzle/widget/bg_container.dart';
import 'package:word_puzzle/widget/coin_container.dart';
import 'package:word_puzzle/widget/coin_service.dart';
import 'package:word_puzzle/widget/floating_words_background.dart';
import 'package:word_puzzle/widget/found_word.dart';
import 'package:word_puzzle/widget/hint_button.dart';
import 'package:word_puzzle/widget/sound.dart';
import 'package:word_puzzle/widget/word_highliter.dart';
import 'package:word_puzzle/view/ad_show.dart';
import 'package:word_puzzle/services/daily_service.dart';
import 'package:word_puzzle/widget/get_level.dart';

class _FlyingLetterInfo {
  final String char;
  final Offset startOffset;
  final Offset targetOffset;
  final Color color;
  final double delay;

  _FlyingLetterInfo({
    required this.char,
    required this.startOffset,
    required this.targetOffset,
    required this.color,
    required this.delay,
  });
}

class _WordSparkleParticle {
  final Offset origin;
  final double angle;
  final double speed;
  final double radius;
  final Color color;
  final String icon;

  _WordSparkleParticle({
    required this.origin,
    required this.angle,
    required this.speed,
    required this.radius,
    required this.color,
    required this.icon,
  });
}

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
  late AnimationController _flightController;
  late AnimationController _sparkleController;
  List<_FlyingLetterInfo> _flyingLetters = [];
  List<_WordSparkleParticle> _sparkles = [];
  final Set<String> _struckWords = {};
  final Map<String, double> _strikethroughProgress = {};
  final Map<String, GlobalKey> _wordChipKeys = {};
  final GlobalKey _gridKey = GlobalKey();
  final GlobalKey _stackKey = GlobalKey();
  bool _isDialogShowing = false;
  bool _isWatchingAd = false;
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
  //
  // static const _wordBank = {
  //   'tech': [
  //     'flutter',
  //     'dart',
  //     'code',
  //     'grid',
  //     'puzzle',
  //     'game',
  //     'level',
  //     'timer',
  //     'bonus',
  //     'software'
  //   ],
  //   'nature': [
  //     'forest',
  //     'river',
  //     'mountain',
  //     'ocean',
  //     'desert',
  //     'valley',
  //     'canyon',
  //     'lake',
  //     'tree',
  //     'flower'
  //   ],
  //   'general': [
  //     'challenge',
  //     'logic',
  //     'solve',
  //     'fun',
  //     'adventure',
  //     'mystery',
  //     'quest',
  //     'journey',
  //     'travel',
  //     'dream'
  //   ],
  // };
  static const Map<String, List<String>> _wordBank = {
    'tech': [
      'flutter',
      'dart',
      'code',
      'debug',
      'widget',
      'state',
      'async',
      'future',
      'stream',
      'build',
      'context',
      'material',
      'scaffold',
      'container',
      'column',
      'row',
      'stack',
      'button',
      'gesture',
      'animation',
      'provider',
      'firebase',
      'api',
      'json',
      'database',
      'server',
      'client',
      'network',
      'http',
      'url',
      'error',
      'class',
      'object',
      'method',
      'function',
      'variable',
      'constant',
      'constructor',
      'inheritance',
      'polymorphism',
      'encapsulation'
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
      'flower',
      'rainforest',
      'waterfall',
      'volcano',
      'glacier',
      'meadow',
      'prairie',
      'savanna',
      'tundra',
      'wetland',
      'coral',
      'reef',
      'island',
      'delta',
      'estuary',
      'fjord',
      'geyser',
      'lagoon',
      'marsh',
      'oasis',
      'jungle',
      'beach',
      'coast',
      'cliff',
      'dune',
      'field',
      'garden',
      'grass',
      'hill',
      'leaf',
      'moon',
      'planet',
      'rain',
      'rock',
      'sand',
      'sky',
      'snow',
      'star',
      'stone',
      'sun',
      'thunder',
      'wind',
      'wood',
      'cloud',
      'storm',
      'breeze',
      'mist',
      'fog',
      'dew',
      'ice',
      'branch',
      'root',
      'seed',
      'petal',
      'bloom',
      'vine',
      'bush',
      'herb',
      'moss',
      'fern',
      'shore',
      'bay',
      'creek',
      'pond',
      'spring',
      'summit',
      'ridge',
      'plateau',
      'basin',
      'cave',
      'grove',
      'orchard',
      'rainfall',
      'sunrise',
      'sunset',
      'twilight',
      'horizon',
      'galaxy',
      'comet',
      'asteroid',
      'meteor',
      'nebula'
    ],
    'animals': [
      'lion',
      'tiger',
      'leopard',
      'cheetah',
      'panther',
      'wolf',
      'fox',
      'bear',
      'panda',
      'elephant',
      'rhino',
      'hippo',
      'giraffe',
      'zebra',
      'camel',
      'horse',
      'donkey',
      'monkey',
      'gorilla',
      'chimp',
      'kangaroo',
      'koala',
      'otter',
      'deer',
      'moose',
      'buffalo',
      'bison',
      'antelope',
      'yak',
      'goat',
      'sheep',
      'dog',
      'cat',
      'rabbit',
      'squirrel',
      'rat',
      'mouse',
      'hamster',
      'hedgehog',
      'bat',
      'whale',
      'dolphin',
      'shark',
      'seal',
      'walrus',
      'octopus',
      'squid',
      'crab',
      'lobster',
      'turtle',
      'crocodile',
      'alligator',
      'snake',
      'lizard',
      'frog',
      'toad',
      'eagle',
      'falcon',
      'hawk',
      'owl',
      'parrot',
      'sparrow',
      'crow',
      'pigeon',
      'peacock',
      'flamingo',
      'penguin',
      'ostrich'
    ],
    'food': [
      'apple',
      'banana',
      'orange',
      'mango',
      'grape',
      'pineapple',
      'papaya',
      'pear',
      'peach',
      'plum',
      'kiwi',
      'melon',
      'watermelon',
      'strawberry',
      'blueberry',
      'raspberry',
      'cherry',
      'coconut',
      'lemon',
      'lime',
      'tomato',
      'potato',
      'onion',
      'garlic',
      'carrot',
      'cabbage',
      'broccoli',
      'spinach',
      'lettuce',
      'pepper',
      'chili',
      'corn',
      'peas',
      'beans',
      'rice',
      'wheat',
      'bread',
      'pasta',
      'noodle',
      'pizza',
      'burger',
      'sandwich',
      'cheese',
      'butter',
      'cream',
      'milk',
      'yogurt',
      'egg',
      'chicken',
      'beef',
      'fish',
      'shrimp',
      'soup',
      'salad',
      'cake',
      'cookie',
      'chocolate',
      'candy',
      'honey',
      'sugar'
    ],
    'travel': [
      'travel',
      'journey',
      'trip',
      'voyage',
      'tour',
      'explore',
      'adventure',
      'destination',
      'map',
      'compass',
      'guide',
      'ticket',
      'passport',
      'visa',
      'airport',
      'station',
      'platform',
      'luggage',
      'baggage',
      'hotel',
      'resort',
      'hostel',
      'camp',
      'tent',
      'mountain',
      'beach',
      'island',
      'forest',
      'city',
      'village',
      'street',
      'bridge',
      'tunnel',
      'road',
      'highway',
      'train',
      'metro',
      'bus',
      'taxi',
      'car',
      'bicycle',
      'motorbike',
      'airplane',
      'helicopter',
      'ship',
      'boat',
      'cruise'
    ],
    'science': [
      'science',
      'physics',
      'chemistry',
      'biology',
      'atom',
      'molecule',
      'cell',
      'energy',
      'force',
      'motion',
      'gravity',
      'mass',
      'volume',
      'density',
      'temperature',
      'pressure',
      'reaction',
      'element',
      'compound',
      'electron',
      'proton',
      'neutron',
      'nucleus',
      'magnet',
      'electric',
      'circuit',
      'battery',
      'voltage',
      'current',
      'resistance',
      'wave',
      'light',
      'sound',
      'heat',
      'radiation',
      'laser',
      'microscope',
      'telescope',
      'experiment',
      'theory'
    ],
    'space': [
      'space',
      'planet',
      'mercury',
      'venus',
      'earth',
      'mars',
      'jupiter',
      'saturn',
      'uranus',
      'neptune',
      'pluto',
      'sun',
      'moon',
      'star',
      'galaxy',
      'nebula',
      'asteroid',
      'meteor',
      'comet',
      'orbit',
      'rocket',
      'satellite',
      'spaceship',
      'astronaut',
      'cosmos',
      'universe',
      'gravity',
      'eclipse',
      'crater',
      'telescope'
    ],
    'sports': [
      'sport',
      'football',
      'cricket',
      'tennis',
      'basketball',
      'baseball',
      'volleyball',
      'badminton',
      'hockey',
      'golf',
      'rugby',
      'boxing',
      'wrestling',
      'swimming',
      'running',
      'cycling',
      'skating',
      'skiing',
      'archery',
      'karate',
      'judo',
      'taekwondo',
      'gymnastics',
      'marathon',
      'stadium',
      'coach',
      'player',
      'team',
      'match',
      'score',
      'goal',
      'winner',
      'trophy',
      'medal',
      'league'
    ],
    'general': [
      'challenge',
      'logic',
      'solve',
      'fun',
      'dream',
      'strategy',
      'victory',
      'treasure',
      'castle',
      'kingdom',
      'dragon',
      'wizard',
      'knight',
      'puzzle',
      'riddle',
      'secret',
      'ancient',
      'magical',
      'legend',
      'epic',
      'heroic',
      'bravery',
      'courage',
      'wisdom',
      'power',
      'spell',
      'sword',
      'shield',
      'battle',
      'peace',
      'hope',
      'faith',
      'love',
      'joy',
      'smile',
      'laugh',
      'friend',
      'family',
      'world',
      'life',
      'time',
      'space',
      'light',
      'dark',
      'fire',
      'shadow',
      'echo',
      'story',
      'memory',
      'moment',
      'future',
      'past'
    ]
  };
  // static const _wordBank = {
  //   'tech': [
  //     'flutter', 'dart', 'code', 'grid', 'puzzle', 'game', 'level', 'timer',
  //     'bonus', 'software', 'widget', 'state', 'async', 'future', 'stream',
  //     'build', 'context', 'material', 'scaffold', 'appbar', 'container',
  //     'column', 'row', 'stack', 'listview', 'textfield', 'button', 'gesture',
  //     'animation', 'provider', 'bloc', 'redux', 'firebase', 'api', 'json',
  //     'database', 'server', 'client', 'network', 'http', 'url', 'debug',
  //     'error', 'exception', 'class', 'object', 'function', 'method', 'variable',
  //     'constant', 'constructor', 'inheritance', 'polymorphism', 'encapsulation'
  //   ],
  //   'nature': [
  //     'forest', 'river', 'mountain', 'ocean', 'desert', 'valley', 'canyon',
  //     'lake', 'tree', 'flower', 'rainforest', 'waterfall', 'volcano', 'glacier',
  //     'meadow', 'prairie', 'savanna', 'tundra', 'wetland', 'coral', 'reef',
  //     'island', 'peninsula', 'delta', 'estuary', 'fjord', 'geyser', 'lagoon',
  //     'marsh', 'oasis', 'jungle', 'beach', 'coast', 'cliff', 'dune', 'field',
  //     'garden', 'grass', 'hill', 'leaf', 'moon', 'planet', 'rain', 'rock',
  //     'sand', 'sky', 'snow', 'star', 'stone', 'sun', 'thunder', 'wind', 'wood'
  //   ],
  //   'general': [
  //     'challenge', 'logic', 'solve', 'fun', 'adventure', 'mystery', 'quest',
  //     'journey', 'travel', 'dream', 'strategy', 'victory', 'defeat', 'treasure',
  //     'dungeon', 'castle', 'kingdom', 'dragon', 'wizard', 'knight', 'puzzle',
  //     'riddle', 'secret', 'hidden', 'ancient', 'magical', 'legend', 'mythical',
  //     'epic', 'heroic', 'bravery', 'courage', 'wisdom', 'power', 'magic',
  //     'spell', 'sword', 'shield', 'armor', 'battle', 'war', 'peace', 'hope',
  //     'faith', 'love', 'joy', 'happy', 'smile', 'laugh', 'friend', 'family',
  //     'world', 'earth', 'life', 'time', 'space', 'light', 'dark', 'fire'
  //   ],
  // };
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
    DailyService().updateTaskProgress(
      taskKey: 'play_wordix',
      increment: 1,
      gameName: 'Wordix',
    );
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
    _flightController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650));
    _sparkleController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
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
      for (var r = 0; r < gridSize; r++) {
        for (var c = 0; c < gridSize; c++) {
          if (_grid[r][c].isEmpty)
            _grid[r][c] = String.fromCharCode(65 + _random.nextInt(26));
        }
      }
      if (mounted) {
        setState(() {
          moveCount = 0;
          maxMoves = _currentWords.length + 2;
          _foundWordPaths.clear();
          _currentDragPath.clear();
          _flyingLetters.clear();
          _sparkles.clear();
          _struckWords.clear();
          _strikethroughProgress.clear();
          _wordChipKeys.clear();
          _start = _end = null;
          _hintedPath = null;
          timeLeft = 90;
          _lastSecondSoundPlayed = false;
        });
      }
      _hintTimer?.cancel();
      _timer?.cancel();
      AudioHelper().stopLastSecond();

      final count = await Prefs.incrementPlayCount();
      if (!mounted) return;

      if (count % 4 == 0 && count != 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _timer?.cancel();
            _hintTimer?.cancel();
            AudioHelper().stopLastSecond();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdPlaybackPage(
                  isRewardAd: false,
                  onAdComplete: () {},
                ),
              ),
            ).then((_) {
              if (mounted && !_isDialogShowing) {
                setState(() {
                  timeLeft = 90;
                  moveCount = 0;
                  maxMoves = _currentWords.length + 2;
                  _lastSecondSoundPlayed = false;
                });
                _startTimer();
              }
            });
          }
        });
      } else {
        _startTimer();
      }
    } catch (e) {
      print('Error starting level: $e');
    }
  }

  void _restartLevel() {
    _timer?.cancel();
    _hintTimer?.cancel();
    AudioHelper().stopLastSecond();
    if (mounted) {
      setState(() {
        timeLeft = 90;
        moveCount = 0;
        _lastSecondSoundPlayed = false;
      });
    }
    _startLevel();
  }

  // List<String> _generateDynamicWords() {
  //   final availableWords = _wordBank.values
  //       .expand((words) => words)
  //       .where((word) => word.length <= gridSize && !_usedWords.contains(word))
  //       .toList();
  //   if (availableWords.length < 5 + level) {
  //     _usedWords.clear();
  //     availableWords.addAll(_wordBank.values
  //         .expand((words) => words)
  //         .where((word) => word.length <= gridSize));
  //   }
  //   availableWords.shuffle(_random);
  //   final selectedWords = availableWords
  //       .take(min(availableWords.length, 4 + gridSize ~/ 2))
  //       .map((word) => word.toUpperCase())
  //       .toList();
  //   _usedWords.addAll(selectedWords);
  //   return selectedWords;
  // }
  List<String> _generateDynamicWords() {
    final availableWords = _wordBank.values
        .expand((words) => words)
        .where((word) => word.length <= gridSize && !_usedWords.contains(word))
        .toList();
    if (availableWords.length < 5 + level) {
      _usedWords.clear(); // Clear kariye
      availableWords.addAll(_wordBank.values.expand((words) => words).where(
          (word) => word.length <= gridSize && !_usedWords.contains(word)));
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
    _timer?.cancel();
    _hintTimer?.cancel();
    AudioHelper().stopLastSecond();
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
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.9)),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: App3DButton.amber(
                          text: '10 COINS',
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
                            _timer?.cancel();
                            _hintTimer?.cancel();
                            AudioHelper().stopLastSecond();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AdPlaybackPage(onAdComplete: () {
                                  if (actionType == 'extra_move')
                                    _addExtraMove(useCoins: false);
                                  else
                                    _showHint(useCoins: false);
                                }),
                              ),
                            ).then((_) {
                              _isWatchingAd = false;
                              if (mounted && !_isDialogShowing) {
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
      if (mounted && !_isDialogShowing && !_isWatchingAd) {
        _startTimer();
      }
    });
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
    HapticFeedback.lightImpact();
  }

  void _handleDragUpdate(DragUpdateDetails details, double cellSize) {
    final col =
        (details.localPosition.dx / cellSize).floor().clamp(0, gridSize - 1);
    final row =
        (details.localPosition.dy / cellSize).floor().clamp(0, gridSize - 1);
    final newEnd = Offset(col.toDouble(), row.toDouble());
    if (_start != null && _isValidDirection(_start!, newEnd)) {
      final newPath = _getPointsOnPath(_start!, newEnd);
      if (newPath.length != _currentDragPath.length) {
        HapticFeedback.selectionClick();
      }
      setState(() {
        _end = newEnd;
        _currentDragPath = newPath;
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

  Color _getGridLetterColor(int r, int col) {
    final cellOffset = Offset(col.toDouble(), r.toDouble());
    if (_currentDragPath.contains(cellOffset)) {
      return const Color(0xFF00E5FF);
    }
    if (_hintedPath != null && _hintedPath!.contains(cellOffset)) {
      return Colors.amberAccent;
    }
    return Colors.white;
  }

  Future<void> _handleDragEnd() async {
    if (_start != null && _end != null) {
      final forwardWord = _getSelectedWord(_start!, _end!);
      String? matchedWord;
      if (_currentWords.contains(forwardWord) &&
          !_foundWordPaths.containsKey(forwardWord)) {
        matchedWord = forwardWord;
      }

      if (matchedWord != null) {
        final foundWord = matchedWord;
        final currentPath = List<Offset>.from(_currentDragPath);
        setState(() => _foundWordPaths[foundWord] = currentPath);
        AudioHelper().playFoundSound();
        HapticFeedback.heavyImpact();

        _launchWordFlight(foundWord, currentPath);
      } else {
        AudioHelper().playNotFoundSound();
        HapticFeedback.lightImpact();
      }
      moveCount++;
      if (moveCount >= (maxMoves ?? 0) &&
          _foundWordPaths.length < _currentWords.length) {
        _timer?.cancel();
        AudioHelper().stopLastSecond();
        _showGameOverDialog(reason: 'moves');
      }
    }
    setState(() {
      _start = _end = null;
      _currentDragPath = [];
    });
  }

  void _launchWordFlight(String word, List<Offset> path) {
    final RenderBox? stackBox =
        _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? gridBox =
        _gridKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? chipBox =
        _wordChipKeys[word]?.currentContext?.findRenderObject() as RenderBox?;

    final double cellSize = (gridBox != null && gridBox.hasSize)
        ? gridBox.size.width / gridSize
        : (MediaQuery.of(context).size.width - 36) / gridSize;

    // Calculate reliable target center on the word's chip
    Offset targetOffset = const Offset(180, 240);
    if (chipBox != null && chipBox.hasSize) {
      final chipGlobal = chipBox.localToGlobal(
          Offset(chipBox.size.width / 2, chipBox.size.height / 2));
      targetOffset =
          stackBox != null ? stackBox.globalToLocal(chipGlobal) : chipGlobal;
    }

    final wordIndex = _currentWords.indexOf(word);
    final wordColor = _highlightColors[wordIndex % _highlightColors.length];

    // Build each flying letter starting at its exact grid tile
    final List<_FlyingLetterInfo> letters = [];
    final int count = path.length;

    for (int i = 0; i < count; i++) {
      final p = path[i];
      final r = p.dy.round().clamp(0, gridSize - 1);
      final c = p.dx.round().clamp(0, gridSize - 1);
      final char = _grid[r][c];

      Offset cellCenter = Offset((c + 0.5) * cellSize, (r + 0.5) * cellSize);
      if (gridBox != null && gridBox.hasSize) {
        final globalCell = gridBox.localToGlobal(cellCenter);
        cellCenter =
            stackBox != null ? stackBox.globalToLocal(globalCell) : globalCell;
      }

      // Stagger delay from 0.0 to 0.32 so letters launch in a beautiful stream
      final double delay = count > 1 ? (i / (count - 1)) * 0.32 : 0.0;

      letters.add(_FlyingLetterInfo(
        char: char,
        startOffset: cellCenter,
        targetOffset: targetOffset,
        color: wordColor,
        delay: delay,
      ));
    }

    setState(() {
      _flyingLetters = letters;
    });

    _flightController.forward(from: 0.0).then((_) {
      if (!mounted) return;
      AudioHelper().playButtonSound();
      HapticFeedback.heavyImpact();

      _triggerStrikethrough(word);
      _triggerSparkles(targetOffset, wordColor);

      setState(() {
        _flyingLetters = [];
      });

      if (_foundWordPaths.length == _currentWords.length) {
        _timer?.cancel();
        Future.delayed(const Duration(milliseconds: 800), () async {
          if (!mounted) return;
          await Prefs.saveMaxLevel(gridSize, level + 1);
          _showSuccessDialog();
        });
      }
    });
  }

  void _triggerStrikethrough(String word) {
    _struckWords.add(word);
    const steps = 15;
    const stepDuration = Duration(milliseconds: 20);
    int currentStep = 0;
    Timer.periodic(stepDuration, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      currentStep++;
      final progress = (currentStep / steps).clamp(0.0, 1.0);
      setState(() {
        _strikethroughProgress[word] = progress;
      });
      if (progress >= 1.0) {
        timer.cancel();
      }
    });
  }

  void _triggerSparkles(Offset origin, Color color) {
    final rnd = Random();
    final symbols = ['⭐', '✨', '✦', '🌟', '•'];
    _sparkles = List.generate(14, (i) {
      final angle = (i * (2 * pi / 14)) + (rnd.nextDouble() * 0.3 - 0.15);
      final speed = 35.0 + rnd.nextDouble() * 45.0;
      return _WordSparkleParticle(
        origin: origin,
        angle: angle,
        speed: speed,
        radius: 4.0 + rnd.nextDouble() * 4.0,
        color: [
          color,
          Colors.amber,
          Colors.cyanAccent,
          Colors.pinkAccent
        ][rnd.nextInt(4)],
        icon: symbols[rnd.nextInt(symbols.length)],
      );
    });
    _sparkleController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() {
          _sparkles.clear();
        });
      }
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
    DailyService().updateTaskProgress(
      taskKey: 'use_hint',
      increment: 1,
      gameName: 'Wordix',
    );
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
    DailyService().updateTaskProgress(
      taskKey: 'win_wordix',
      increment: 1,
      gameName: 'Wordix',
    );
    try {
      Provider.of<GameLevelProvider>(context, listen: false)
          .updateGameLevel(level + 1, gridSize);
    } catch (e) {
      print('Wordix updateGameLevel error: $e');
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdPlaybackPage(
          isRewardAd: false,
          onAdComplete: () {
            if (!mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SuccessScreen(
                  level: level,
                  coin: 3,
                  gridSize: gridSize,
                  onNextLevel: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WordSearchPage(
                        initialLevel: level + 1,
                        gridSize: gridSize,
                      ),
                    ),
                  ),
                  onBackToLevels: () => Navigator.pop(context),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // void _showGameOverDialog({required String reason}) {
  //   if (_isDialogShowing) return;
  //   _isDialogShowing = true;
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (context) => Dialog(
  //       backgroundColor: Colors.transparent,
  //       child: ClipRRect(
  //         borderRadius: BorderRadius.circular(30),
  //         child: BackdropFilter(
  //           filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
  //           child: Container(
  //             padding: const EdgeInsets.all(30),
  //             decoration: BoxDecoration(
  //               color: Colors.black.withValues(alpha: 0.5),
  //               borderRadius: BorderRadius.circular(30),
  //               border: Border.all(
  //                   color: Colors.white.withValues(alpha: 0.2), width: 1.5),
  //             ),
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 Text(reason == 'time' ? "TIME'S UP!" : "OUT OF MOVES!",
  //                     style: const TextStyle(
  //                         fontSize: 24,
  //                         fontWeight: FontWeight.w900,
  //                         color: Colors.white)),
  //                 const SizedBox(height: 15),
  //                 reason == 'time' ? Image.asset('assets/time_out.png', width: 200, height: 200) : Image.asset('assets/out_of_moves.png', width: 200, height: 200) ,
  //                 SizedBox(height: 10),
  //                 const Text("Would you like to try again?",
  //                     style: TextStyle(color: Colors.white70),
  //                     textAlign: TextAlign.center),
  //                 const SizedBox(height: 30),
  //                 Row(
  //                   children: [
  //                     Expanded(
  //                         child: AppButton(
  //                             label: 'EXIT',
  //                             onTap: () {
  //                               Navigator.pop(context);
  //                               Navigator.pop(context);
  //                             })),
  //                     const SizedBox(width: 10),
  //                     Expanded(
  //                         child: AppButton(
  //                             label: 'RETRY',
  //                             onTap: () {
  //                               Navigator.pop(context);
  //                               _startLevel();
  //                             })),
  //                   ],
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //   ).then((_) => _isDialogShowing = false);
  // }
  void _showGameOverDialog({required String reason}) {
    if (_isDialogShowing) return;
    _isDialogShowing = true;
    _timer?.cancel();
    _hintTimer?.cancel();
    AudioHelper().stopLastSecond();
    bool isRetrying = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: StatefulBuilder(
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
                                                  builder: (context) =>
                                                      SuccessScreen(
                                                    level: level,
                                                    coin: 0,
                                                    isWin: false,
                                                    gridSize: gridSize,
                                                    onNextLevel: () => Navigator
                                                        .pushReplacement(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            WordSearchPage(
                                                          initialLevel: level,
                                                          gridSize: gridSize,
                                                        ),
                                                      ),
                                                    ),
                                                    onBackToLevels: () =>
                                                        Navigator.pop(context),
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
                                        final connectivity =
                                            await Connectivity()
                                                .checkConnectivity();
                                        if (connectivity.contains(
                                            ConnectivityResult.none)) {
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
                                            const Duration(milliseconds: 350));
                                        await coinProvider.undoCoins(4);
                                        AudioHelper().playMoneySound();
                                        Fluttertoast.showToast(
                                          msg: "4 coins deducted to retry",
                                        );

                                        if (!dialogContext.mounted) return;
                                        Navigator.pop(dialogContext);
                                        setState(() {
                                          if (reason == 'time') {
                                            timeLeft = 45;
                                          } else {
                                            maxMoves = (maxMoves ?? 0) + 5;
                                          }
                                        });
                                        _startTimer();
                                      } catch (e) {
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
      ),
    ).then((_) => _isDialogShowing = false);
  }

  void _showInsufficientCoinsDialog() {
    _timer?.cancel();
    _hintTimer?.cancel();
    AudioHelper().stopLastSecond();
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
    ).then((_) {
      if (mounted && !_isDialogShowing && !_isWatchingAd) {
        _startTimer();
      }
    });
  }

  void _showExitConfirmationDialog(BuildContext context) {
    _timer?.cancel();
    _hintTimer?.cancel();
    AudioHelper().stopLastSecond();
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
                  const Text('PAUSED / EXIT?',
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
                        child: App3DButton.cyan(
                          text: 'PLAY ON',
                          height: 46,
                          fontSize: 14,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: App3DButton.amber(
                          text: 'EXIT',
                          height: 46,
                          fontSize: 14,
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pop(context);
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
      if (mounted && !_isDialogShowing && !_isWatchingAd) {
        _startTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentWords.isEmpty ||
        _grid.isEmpty ||
        _grid.any((row) => row.isEmpty)) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _showExitConfirmationDialog(context);
        },
        child: Scaffold(
          body: BackgroundContainer(
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
        ),
      );
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isNarrow = screenWidth < 360;

    // Constrain grid size to fit width, height, and maximum limits
    double gridDisplaySize = screenWidth - (isNarrow ? 24 : 36);
    if (gridDisplaySize > screenHeight * 0.44) {
      gridDisplaySize = screenHeight * 0.44;
    }
    if (gridDisplaySize > 440.0) {
      gridDisplaySize = 440.0;
    }
    final cellSize = gridDisplaySize / gridSize;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showExitConfirmationDialog(context);
      },
      child: Scaffold(
        body: BackgroundContainer(
          child: Stack(
            key: _stackKey,
            children: [
              // 1. Dark Cyber-Oceanic Scrim
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF001428).withOpacity(0.85),
                        const Color(0xFF030D1B).withOpacity(0.90),
                        const Color(0xFF000814).withOpacity(0.95),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              // 2. Floating Words Overlay
              const FloatingWordsBackground(isWordix: true),

              // 3. Main Foreground Content
              SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 550),
                    child: Column(
                      children: [
                        // Top HUD Bar (Restored layout with 3D Level/Back Button)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isNarrow ? 10 : 16,
                            vertical: isNarrow ? 8 : 12,
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
                                  Color(0xFF00587A)
                                ],
                                shadowColor: const Color(0xFF002238),
                                glowColor: const Color(0xFF00E5FF),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.arrow_back_rounded,
                                          color: Colors.white,
                                          size: isNarrow ? 18.0 : 20.0),
                                      SizedBox(width: isNarrow ? 5.0 : 8.0),
                                      Text(
                                        isNarrow
                                            ? 'Lvl $level'
                                            : 'Level $level',
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
                                onPressed: () =>
                                    _showExitConfirmationDialog(context),
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
                                        'hint', () => _showHint()),
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

                        SizedBox(height: isNarrow ? 6 : 14),

                        // Target Words List Container ("FIND THE WORDS")
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: isNarrow ? 12 : 18),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isNarrow ? 10 : 14,
                              vertical: isNarrow ? 10 : 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.45),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.18),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00E5FF)
                                            .withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.search_rounded,
                                          color: Color(0xFF00E5FF), size: 15),
                                    ),
                                    const SizedBox(width: 7),
                                    const Text(
                                      "FIND THE WORDS",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _struckWords.length ==
                                                    _currentWords.length &&
                                                _currentWords.isNotEmpty
                                            ? const Color(0xFF00E676)
                                                .withOpacity(0.25)
                                            : Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: _struckWords.length ==
                                                      _currentWords.length &&
                                                  _currentWords.isNotEmpty
                                              ? const Color(0xFF00E676)
                                              : Colors.white24,
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        "${_struckWords.length}/${_currentWords.length}",
                                        style: TextStyle(
                                          color: _struckWords.length ==
                                                      _currentWords.length &&
                                                  _currentWords.isNotEmpty
                                              ? const Color(0xFF00E676)
                                              : Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 7,
                                  alignment: WrapAlignment.center,
                                  children: _currentWords.map((word) {
                                    final key = _wordChipKeys.putIfAbsent(
                                        word, () => GlobalKey());
                                    final isFound =
                                        _foundWordPaths.containsKey(word);
                                    final isStruck =
                                        _struckWords.contains(word);
                                    final strikeProgress =
                                        _strikethroughProgress[word] ??
                                            (isStruck ? 1.0 : 0.0);
                                    final wordIndex =
                                        _currentWords.indexOf(word);
                                    final wordColor = _highlightColors[
                                        wordIndex % _highlightColors.length];

                                    return _WordChip(
                                      key: key,
                                      word: word,
                                      isFound: isFound,
                                      isStruck: isStruck,
                                      strikeProgress: strikeProgress,
                                      color: wordColor,
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: isNarrow ? 10 : 20),

                        // Clean Word Search Grid (No individual tile boxes, clean letters like Image 3)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Center(
                            child: GestureDetector(
                              onPanStart: (d) => _handleDragStart(d, cellSize),
                              onPanUpdate: (d) =>
                                  _handleDragUpdate(d, cellSize),
                              onPanEnd: (_) => _handleDragEnd(),
                              child: Container(
                                key: _gridKey,
                                width: cellSize * gridSize,
                                height: cellSize * gridSize,
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF071424).withOpacity(0.70),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: const Color(0xFF00E5FF)
                                        .withOpacity(0.35),
                                    width: 1.8,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00E5FF)
                                          .withOpacity(0.12),
                                      blurRadius: 20,
                                      spreadRadius: 1,
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.5),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(22),
                                  child: Stack(
                                    children: [
                                      // Rounded capsule highlight lines for found words
                                      Positioned.fill(
                                        child: CustomPaint(
                                          painter: WordLinePainter(
                                            foundWordPaths: _foundWordPaths,
                                            hintedPath: _hintedPath,
                                            cellSize: cellSize,
                                            colors: _highlightColors,
                                            blinkValue: _blinkAnimation.value,
                                          ),
                                        ),
                                      ),
                                      // Drag selection line
                                      Positioned.fill(
                                        child: CustomPaint(
                                          painter: DragLinePainter(
                                            start: _start,
                                            end: _end,
                                            cellSize: cellSize,
                                            gridSize: gridSize,
                                          ),
                                        ),
                                      ),
                                      // Clean letters grid precisely centered on cell coordinates (zero drift)
                                      for (int r = 0; r < gridSize; r++)
                                        for (int col = 0; col < gridSize; col++)
                                          Positioned(
                                            left: col * cellSize,
                                            top: r * cellSize,
                                            width: cellSize,
                                            height: cellSize,
                                            child: Center(
                                              child: Text(
                                                _grid[r][col],
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: (cellSize * 0.48)
                                                      .clamp(16.0, 28.0),
                                                  fontWeight: FontWeight.w900,
                                                  height: 1.0,
                                                  color: _getGridLetterColor(
                                                      r, col),
                                                  shadows: [
                                                    Shadow(
                                                      color: Colors.black
                                                          .withOpacity(0.7),
                                                      offset:
                                                          const Offset(0, 1.5),
                                                      blurRadius: 3,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Bottom Gauges: Time & Moves
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: isNarrow ? 6 : 12,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              timeCircle(timeLeft, 90),
                              movesCircle(
                                  (maxMoves ?? 0) - moveCount, maxMoves ?? 1),
                            ],
                          ),
                        ),

                        SizedBox(height: isNarrow ? 8 : 16),
                      ],
                    ),
                  ),
                ),
              ),

              // 4. Flying Letters Animation Layer (staggered flight from each grid tile to chip)
              if (_flyingLetters.isNotEmpty)
                IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _flightController,
                    builder: (context, child) {
                      final globalT = _flightController.value;

                      return Stack(
                        children: _flyingLetters.map((letter) {
                          final double letterT = letter.delay >= 1.0
                              ? 1.0
                              : ((globalT - letter.delay) /
                                      (1.0 - letter.delay))
                                  .clamp(0.0, 1.0);

                          if (letterT <= 0.0) {
                            return const SizedBox.shrink();
                          }

                          final start = letter.startOffset;
                          final target = letter.targetOffset;

                          // Smooth arched flight curve towards the chip
                          final midX = (start.dx + target.dx) / 2.0;
                          final midY = min(start.dy, target.dy) - 50.0;

                          final oneMinusT = 1.0 - letterT;
                          final curX = oneMinusT * oneMinusT * start.dx +
                              2 * oneMinusT * letterT * midX +
                              letterT * letterT * target.dx;
                          final curY = oneMinusT * oneMinusT * start.dy +
                              2 * oneMinusT * letterT * midY +
                              letterT * letterT * target.dy;

                          // Pop scale up on launch and smooth merge into the chip
                          final scale = letterT < 0.25
                              ? 1.0 + (letterT / 0.25) * 0.35
                              : 1.35 - ((letterT - 0.25) / 0.75) * 0.45;

                          final rotation = sin(letterT * pi * 2) * 0.15;
                          final alpha = letterT > 0.90
                              ? (1.0 - (letterT - 0.90) / 0.10).clamp(0.0, 1.0)
                              : 1.0;

                          final circleSize =
                              (cellSize * 0.78).clamp(32.0, 48.0);

                          return Positioned(
                            left: curX,
                            top: curY,
                            child: FractionalTranslation(
                              translation: const Offset(-0.5, -0.5),
                              child: Opacity(
                                opacity: alpha,
                                child: Transform.rotate(
                                  angle: rotation,
                                  child: Transform.scale(
                                    scale: scale,
                                    child: Container(
                                      width: circleSize,
                                      height: circleSize,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            letter.color,
                                            letter.color
                                                .withValues(alpha: 0.85),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: letter.color
                                                .withValues(alpha: 0.7),
                                            blurRadius: 12,
                                            spreadRadius: 2,
                                            offset: const Offset(0, 3),
                                          ),
                                          BoxShadow(
                                            color: Colors.white
                                                .withValues(alpha: 0.5),
                                            blurRadius: 5,
                                            offset: const Offset(0, -1),
                                          ),
                                        ],
                                        border: Border.all(
                                            color: Colors.white, width: 2),
                                      ),
                                      child: Center(
                                        child: Text(
                                          letter.char,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 17,
                                            fontWeight: FontWeight.w900,
                                            height: 1.0,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black54,
                                                offset: Offset(0, 1.5),
                                                blurRadius: 3,
                                              ),
                                            ],
                                          ),
                                        ),
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
                ),

              // 5. Celebration Sparkle Particle Explosion Layer (wrapped in IgnorePointer)
              if (_sparkles.isNotEmpty)
                IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _sparkleController,
                    builder: (context, child) {
                      return CustomPaint(
                        size: Size.infinite,
                        painter: _SparklePainter(
                          sparkles: _sparkles,
                          progress: _sparkleController.value,
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget timeCircle(int timeLeft, int totalTime, {double size = 72}) {
    double progress = (timeLeft / totalTime).clamp(0.0, 1.0);
    Color ringColor;
    if (progress > 0.6) {
      ringColor = const Color(0xFF00E676);
    } else if (progress > 0.25) {
      ringColor = const Color(0xFFFFB300);
    } else {
      ringColor = const Color(0xFFFF5252);
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ringColor.withOpacity(0.35),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ],
            ),
          ),
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 7,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation(ringColor),
            ),
          ),
          Container(
            width: size * 0.78,
            height: size * 0.78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0F2B48).withOpacity(0.8),
                  const Color(0xFF051324).withOpacity(0.9),
                ],
              ),
              border: Border.all(
                color: Colors.white24,
                width: 1.4,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "TIME",
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white70,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  "$timeLeft",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: ringColor,
                    shadows: [
                      Shadow(
                        color: ringColor.withOpacity(0.6),
                        blurRadius: 8,
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

  Widget movesCircle(int remainingMoves, int totalMoves, {double size = 72}) {
    final safeTotal = totalMoves <= 0 ? 1 : totalMoves;
    double progress = (remainingMoves / safeTotal).clamp(0.0, 1.0);
    Color ringColor;
    if (progress > 0.5) {
      ringColor = const Color(0xFF00E5FF);
    } else if (progress > 0.25) {
      ringColor = const Color(0xFFFFB300);
    } else {
      ringColor = const Color(0xFFFF5252);
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ringColor.withOpacity(0.35),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ],
            ),
          ),
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 7,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation(ringColor),
            ),
          ),
          Container(
            width: size * 0.78,
            height: size * 0.78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0F2B48).withOpacity(0.8),
                  const Color(0xFF051324).withOpacity(0.9),
                ],
              ),
              border: Border.all(
                color: Colors.white24,
                width: 1.4,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "MOVES",
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white70,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  "$remainingMoves",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: ringColor,
                    shadows: [
                      Shadow(
                        color: ringColor.withOpacity(0.6),
                        blurRadius: 8,
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
    // Ensure last 5-second countdown audio stops immediately on screen exit
    AudioHelper().stopLastSecond();
    _animationController.dispose();
    _blinkController.dispose();
    _flightController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Kid-Friendly Word Search Helper Widgets & Painters
// ---------------------------------------------------------------------------

class _WordChip extends StatelessWidget {
  final String word;
  final bool isFound;
  final bool isStruck;
  final double strikeProgress;
  final Color color;

  const _WordChip({
    super.key,
    required this.word,
    required this.isFound,
    required this.isStruck,
    required this.strikeProgress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveFound = isStruck;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      padding: EdgeInsets.symmetric(
        horizontal: effectiveFound ? 9 : 11,
        vertical: 5.5,
      ),
      decoration: BoxDecoration(
        color: effectiveFound
            ? color.withOpacity(0.22)
            : Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: effectiveFound ? color : Colors.white.withOpacity(0.22),
          width: effectiveFound ? 1.8 : 1.2,
        ),
        boxShadow: effectiveFound
            ? [
                BoxShadow(
                  color: color.withOpacity(0.35),
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(
            foregroundPainter: effectiveFound
                ? _StrikeThroughPainter(
                    progress: strikeProgress,
                    color: color,
                  )
                : null,
            child: Text(
              word,
              style: TextStyle(
                color: effectiveFound
                    ? Colors.white.withOpacity(0.7)
                    : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.6),
                    offset: const Offset(0, 1.5),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
          ),
          if (effectiveFound) ...[
            const SizedBox(width: 5),
            AnimatedScale(
              duration: const Duration(milliseconds: 300),
              curve: Curves.elasticOut,
              scale: isStruck ? 1.0 : 0.0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.6),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 11,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StrikeThroughPainter extends CustomPainter {
  final double progress;
  final Color color;

  _StrikeThroughPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const startX = -3.0;
    final totalWidth = size.width + 6.0;
    final endX = startX + totalWidth * progress;
    final y = size.height / 2.0;

    canvas.drawLine(Offset(startX, y), Offset(endX, y), paint);
  }

  @override
  bool shouldRepaint(_StrikeThroughPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _SparklePainter extends CustomPainter {
  final List<_WordSparkleParticle> sparkles;
  final double progress;

  _SparklePainter({required this.sparkles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1.0) return;
    final alpha = (1.0 - progress).clamp(0.0, 1.0);

    for (final s in sparkles) {
      final currentDist = s.speed * progress * 1.5;
      final x = s.origin.dx + cos(s.angle) * currentDist;
      final y = s.origin.dy + sin(s.angle) * currentDist;

      final textPainter = TextPainter(
        text: TextSpan(
          text: s.icon,
          style: TextStyle(
            color: s.color.withOpacity(alpha),
            fontSize: s.radius * 2.2 * (1.2 - progress * 0.4),
            shadows: [
              Shadow(
                color: s.color.withOpacity(alpha * 0.7),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(_SparklePainter oldDelegate) => true;
}
