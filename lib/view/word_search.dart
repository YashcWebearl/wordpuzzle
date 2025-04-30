import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    home: WordSearchPage(initialLevel: 1, gridSize: 6,),
  ));
}

class WordSearchPage extends StatefulWidget {
  final int initialLevel;
  final int gridSize;
  const WordSearchPage({Key? key, required this.initialLevel, required this.gridSize}) : super(key: key);

  @override
  _WordSearchPageState createState() => _WordSearchPageState();
}

class _WordSearchPageState extends State<WordSearchPage> {
  late int level;
  int timeLeft = 90;
  Timer? timer;
  // final int gridSize = 10;
  late int gridSize;
  // Dynamic word bank with categorized words
  final Map<String, List<String>> wordBank = {
    'tech': [
      'FLUTTER', 'DART', 'CODE', 'GRID', 'PUZZLE', 'GAME', 'LEVEL', 'TIMER',
      'BONUS', 'SOFTWARE', 'MOBILE', 'WIDGET', 'MATERIAL', 'ALGORITHM', 'DEBUG',
      'TEST', 'DATABASE', 'SERVER', 'CLOUD', 'API', 'FRAMEWORK', 'REACT', 'VUE',
      'ANGULAR', 'NODE', 'PYTHON', 'JAVA', 'KOTLIN', 'SWIFT', 'RUBY'
    ],
    'nature': [
      'FOREST', 'RIVER', 'MOUNTAIN', 'OCEAN', 'DESERT', 'VALLEY', 'CANYON',
      'LAKE', 'TREE', 'FLOWER', 'GRASS', 'SKY', 'CLOUD', 'SUNSET', 'MOON',
      'STAR', 'WIND', 'RAIN', 'SNOW', 'FOG', 'BEACH', 'ISLAND', 'REEF', 'CAVE',
      'GLACIER', 'MEADOW', 'HILL', 'STREAM', 'POND', 'BAY'
    ],
    'general': [
      'CHALLENGE', 'LOGIC', 'SOLVE', 'FUN', 'ADVENTURE', 'MYSTERY', 'QUEST',
      'JOURNEY', 'TRAVEL', 'DREAM', 'HOPE', 'PEACE', 'LOVE', 'JOY', 'SMILE',
      'FRIEND', 'FAMILY', 'HOME', 'CITY', 'VILLAGE', 'SCHOOL', 'BOOK', 'MUSIC',
      'ART', 'SPORT', 'HEALTH', 'FOOD', 'DRINK', 'TIME', 'WORK'
    ],
  };

  List<Offset> currentDragPath = [];
  late List<String> currentWords;
  late List<List<String>> grid;
  Offset? start;
  Offset? end;
  final Map<String, List<Offset>> foundWordPaths = {};
  final List<Color> highlightColors = [
    Colors.orange.shade300,
    Colors.teal.shade300,
    Colors.purple.shade300,
    Colors.blue.shade300,
    Colors.pink.shade300,
    Colors.green.shade300,
    Colors.red.shade300,
    Colors.amber.shade300,
    Colors.cyan.shade300,
    Colors.indigo.shade300,
  ];
  final Random random = Random();
  List<String> usedWords = []; // Track used words to avoid repetition

  // @override
  // void initState() {
  //   super.initState();
  //   level = widget.initialLevel;
  //   startLevel();
  // }
  @override
  void initState() {
    super.initState();
    level = widget.initialLevel;
    gridSize = widget.gridSize;
    startLevel();
  }

  void startLevel() {
    try {
      currentWords = _generateDynamicWords();
      grid = generateGridWithWords(currentWords);
      timeLeft = 90;
      foundWordPaths.clear();
      currentDragPath.clear();
      start = end = null;
      startTimer();
    } catch (e) {
      showGameOverDialog();
    }
  }

  List<String> _generateDynamicWords() {
    List<String> availableWords = wordBank.values.expand((words) => words).toList();
    availableWords.removeWhere((word) => usedWords.contains(word));

    if (availableWords.length < 5 + level) {
      usedWords.clear();
      availableWords = wordBank.values.expand((words) => words).toList();
    }

    availableWords.shuffle(random);
    List<String> selectedWords = availableWords.take(5 + level).toList();
    usedWords.addAll(selectedWords);

    return selectedWords
        .where((word) => word.length <= gridSize)
        .map((word) => word.toUpperCase())
        .toList();
  }

  void startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        timeLeft--;
        if (timeLeft <= 0) {
          t.cancel();
          showGameOverDialog();
        }
      });
    });
  }

  List<List<String>> generateGridWithWords(List<String> words) {
    List<List<String>> grid;
    bool success;
    int attempts = 0;

    do {
      success = true;
      grid = List.generate(gridSize, (_) => List.filled(gridSize, ''));
      final directions = [
        [0, 1], [1, 0], [1, 1], [-1, 1],
        [0, -1], [-1, 0], [-1, -1], [1, -1]
      ];

      for (String word in words) {
        if (!_placeWord(word, grid, directions, random)) {
          success = false;
          break;
        }
      }
      attempts++;
    } while (!success && attempts < 200);

    if (!success) throw Exception("Failed to generate grid");

    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (grid[r][c] == '') {
          grid[r][c] = String.fromCharCode(65 + random.nextInt(26));
        }
      }
    }

    return grid;
  }

  bool _placeWord(String word, List<List<String>> grid, List<List<int>> directions, Random random) {
    for (int attempt = 0; attempt < 200; attempt++) {
      final dir = directions[random.nextInt(directions.length)];
      final dx = dir[0], dy = dir[1];

      int maxRow = gridSize - (dx.abs() * (word.length - 1));
      int maxCol = gridSize - (dy.abs() * (word.length - 1));
      if (maxRow <= 0 || maxCol <= 0) continue;

      int row = dx < 0 ? random.nextInt(maxRow) + (gridSize - maxRow) : random.nextInt(maxRow);
      int col = dy < 0 ? random.nextInt(maxCol) + (gridSize - maxCol) : random.nextInt(maxCol);

      bool fits = true;
      for (int i = 0; i < word.length; i++) {
        int r = row + dx * i;
        int c = col + dy * i;
        if (r < 0 || r >= gridSize || c < 0 || c >= gridSize ||
            (grid[r][c] != '' && grid[r][c] != word[i])) {
          fits = false;
          break;
        }
      }

      if (fits) {
        for (int i = 0; i < word.length; i++) {
          int r = row + dx * i;
          int c = col + dy * i;
          grid[r][c] = word[i];
        }
        return true;
      }
    }
    return false;
  }

  bool _isValidDirection(Offset a, Offset b) {
    int dx = (b.dx - a.dx).round().abs();
    int dy = (b.dy - a.dy).round().abs();
    return dx == 0 || dy == 0 || dx == dy;
  }

  void handleDragStart(DragStartDetails details, double cellSize) {
    final position = details.localPosition;
    final row = (position.dy / cellSize).floor().clamp(0, gridSize - 1);
    final col = (position.dx / cellSize).floor().clamp(0, gridSize - 1);
    start = Offset(row.toDouble(), col.toDouble());
    setState(() {
      currentDragPath = [start!];
    });
  }

  void handleDragUpdate(DragUpdateDetails details, double cellSize) {
    final position = details.localPosition;
    final row = (position.dy / cellSize).floor().clamp(0, gridSize - 1);
    final col = (position.dx / cellSize).floor().clamp(0, gridSize - 1);
    end = Offset(row.toDouble(), col.toDouble());

    if (start != null && _isValidDirection(start!, end!)) {
      setState(() {
        currentDragPath = _getHighlightedCells(start!, end!);
      });
    }
  }

  void handleDragEnd() {
    if (start != null && end != null && _isValidDirection(start!, end!)) {
      String selectedWord = _getSelectedWord(start!, end!);
      if (selectedWord.length < 3) {
        setState(() {
          currentDragPath.clear();
        });
        start = end = null;
        return;
      }

      String reversedWord = selectedWord.split('').reversed.join();
      String? matchedWord;

      if (currentWords.contains(selectedWord)) {
        matchedWord = selectedWord;
      } else if (currentWords.contains(reversedWord)) {
        matchedWord = reversedWord;
      }

      if (matchedWord != null && !foundWordPaths.containsKey(matchedWord)) {
        final path = _getHighlightedCells(start!, end!);
        setState(() {
          foundWordPaths[matchedWord!] = path;
          currentDragPath.clear();
        });

        if (foundWordPaths.length == currentWords.length) {
          timer?.cancel();
          showSuccessDialog();
        }
      } else {
        setState(() {
          currentDragPath.clear();
        });
      }
    } else {
      setState(() {
        currentDragPath.clear();
      });
    }
    start = end = null;
  }

  String _getSelectedWord(Offset a, Offset b) {
    final dx = (b.dx - a.dx).round();
    final dy = (b.dy - a.dy).round();
    final stepX = dx == 0 ? 0 : dx ~/ dx.abs();
    final stepY = dy == 0 ? 0 : dy ~/ dy.abs();
    int x = a.dx.round(), y = a.dy.round();
    String word = '';

    while (x >= 0 && y >= 0 && x < gridSize && y < gridSize) {
      word += grid[x][y];
      if (x == b.dx.round() && y == b.dy.round()) break;
      x += stepX;
      y += stepY;
    }
    return word;
  }

  List<Offset> _getHighlightedCells(Offset a, Offset b) {
    final List<Offset> cells = [];
    final dx = (b.dx - a.dx).round();
    final dy = (b.dy - a.dy).round();
    final stepX = dx == 0 ? 0 : dx ~/ dx.abs();
    final stepY = dy == 0 ? 0 : dy ~/ dy.abs();
    int x = a.dx.round(), y = a.dy.round();

    while (x >= 0 && y >= 0 && x < gridSize && y < gridSize) {
      cells.add(Offset(x.toDouble(), y.toDouble()));
      if (x == b.dx.round() && y == b.dy.round()) break;
      x += stepX;
      y += stepY;
    }
    return cells;
  }

  Color? getCellColor(int row, int col) {
    final current = Offset(row.toDouble(), col.toDouble());

    if (currentDragPath.contains(current)) {
      return Colors.yellow.withOpacity(0.5);
    }

    int index = 0;
    for (var entry in foundWordPaths.entries) {
      if (entry.value.contains(current)) {
        return highlightColors[index % highlightColors.length];
      }
      index++;
    }
    return null;
  }

  void showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Level Complete!'),
        content: Text('Proceeding to level ${level + 1}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                level++;
                startLevel();
              });
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Time Up!'),
        content: Text('You reached level $level.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Back to Levels'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                startLevel();
              });
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Responsive sizing based on the smaller dimension (width or height)
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    final maxGridWidth = isLandscape
        ? screenSize.height * 0.5
        : screenSize.width * 0.9;
    final cellSize = maxGridWidth / gridSize;
    final fontSizeFactor = screenSize.width / 360; // Base font size for 360px width

    return Scaffold(
      backgroundColor: const Color(0xFFDAAB5C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7A5821),
        title: Text(
          "Level $level — ⏱ $timeLeft",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 24 ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onPanStart: (details) => handleDragStart(details, cellSize),
                  onPanUpdate: (details) => handleDragUpdate(details, cellSize),
                  onPanEnd: (_) => handleDragEnd(),
                  child: Container(
                    width: cellSize * gridSize,
                    height: cellSize * gridSize,
                    padding: EdgeInsets.all(8),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: gridSize * gridSize,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: gridSize,
                        mainAxisSpacing: 4,
                        crossAxisSpacing: 4,
                      ),
                      itemBuilder: (context, index) {
                        final row = index ~/ gridSize;
                        final col = index % gridSize;
                        final color = getCellColor(row, col);

                        return Container(
                          decoration: BoxDecoration(
                            color: color ?? const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(8 * fontSizeFactor),
                            border: Border.all(color: const Color(0xFF7A5821), width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 2 * fontSizeFactor,
                                offset: Offset(1 * fontSizeFactor, 1 * fontSizeFactor),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            grid[row][col],
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Courier',
                              color: color != null ? Colors.white : const Color(0xFF7A5821),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20 * fontSizeFactor),
              Text(
                'Find the Words:',
                style: TextStyle(
                  fontSize: 20 * fontSizeFactor,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF7A5821),
                ),
              ),
              SizedBox(height: 10 * fontSizeFactor),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16 * fontSizeFactor),
                child: Wrap(
                  spacing: 8 * fontSizeFactor,
                  runSpacing: 8 * fontSizeFactor,
                  children: currentWords.map((word) {
                    final found = foundWordPaths.containsKey(word);
                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10 * fontSizeFactor,
                        vertical: 5 * fontSizeFactor,
                      ),
                      decoration: BoxDecoration(
                        color: found ? Colors.green.shade300 : Colors.white,
                        borderRadius: BorderRadius.circular(8 * fontSizeFactor),
                        border: Border.all(
                          color: const Color(0xFF7A5821),
                          width: 1 * fontSizeFactor,
                        ),
                        boxShadow: [
                          if (found)
                            BoxShadow(
                              color: Colors.green.shade900.withOpacity(0.3),
                              offset: Offset(1 * fontSizeFactor, 1 * fontSizeFactor),
                              blurRadius: 2 * fontSizeFactor,
                            ),
                        ],
                      ),
                      child: Text(
                        word,
                        style: TextStyle(
                          fontSize: 16 * fontSizeFactor,
                          fontWeight: FontWeight.w600,
                          color: found ? Colors.white : const Color(0xFF7A5821),
                          decoration: found ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 20 * fontSizeFactor),
            ],
          ),
        ),
      ),
    );
  }
}


// import 'dart:async';
// import 'dart:math';
// import 'package:flutter/material.dart';
//
// void main() {
//   runApp(const MaterialApp(
//     home: WordSearchPage(initialLevel: 1),
//   ));
// }
//
// class WordSearchPage extends StatefulWidget {
//   final int initialLevel;
//   const WordSearchPage({Key? key, required this.initialLevel}) : super(key: key);
//
//   @override
//   _WordSearchPageState createState() => _WordSearchPageState();
// }
//
// class _WordSearchPageState extends State<WordSearchPage> {
//   late int level;
//   int timeLeft = 90;
//   Timer? timer;
//   final int gridSize = 10;
//
//   final List<String> allWords = [
//     'FLUTTER', 'DART', 'CODE', 'GRID', 'PUZZLE',
//     'GAME', 'LEVEL', 'TIMER', 'BONUS', 'SOFTWARE',
//     'MOBILE', 'FUN', 'CHALLENGE', 'LOGIC', 'SOLVE',
//     'ALGORITHM', 'DEBUG', 'TEST', 'WIDGET', 'MATERIAL'
//   ];
//   List<Offset> currentDragPath = [];
//
//   late List<String> currentWords;
//   late List<List<String>> grid;
//   Offset? start;
//   Offset? end;
//   final Map<String, List<Offset>> foundWordPaths = {};
//   final List<Color> highlightColors = [
//     Colors.orange.shade300,
//     Colors.teal.shade300,
//     Colors.purple.shade300,
//     Colors.blue.shade300,
//     Colors.pink.shade300,
//     Colors.green.shade300,
//     Colors.red.shade300,
//     Colors.amber.shade300,
//     Colors.cyan.shade300,
//     Colors.indigo.shade300,
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     level = widget.initialLevel;
//     startLevel();
//   }
//
//   void startLevel() {
//     try {
//       List<String> shuffledWords = List.from(allWords)..shuffle();
//       currentWords = shuffledWords.take(5 + level).toList();
//       grid = generateGridWithWords(currentWords);
//       timeLeft = 90;
//       foundWordPaths.clear();
//       currentDragPath.clear();
//       start = end = null;
//       startTimer();
//     } catch (e) {
//       showGameOverDialog();
//     }
//   }
//
//   void startTimer() {
//     timer?.cancel();
//     timer = Timer.periodic(const Duration(seconds: 1), (t) {
//       setState(() {
//         timeLeft--;
//         if (timeLeft <= 0) {
//           t.cancel();
//           showGameOverDialog();
//         }
//       });
//     });
//   }
//
//   List<List<String>> generateGridWithWords(List<String> words) {
//     final random = Random();
//     List<List<String>> grid;
//     bool success;
//     int attempts = 0;
//
//     do {
//       success = true;
//       grid = List.generate(gridSize, (_) => List.filled(gridSize, ''));
//       final directions = [
//         [0, 1], [1, 0], [1, 1], [-1, 1],
//         [0, -1], [-1, 0], [-1, -1], [1, -1]
//       ];
//
//       for (String word in words) {
//         if (!_placeWord(word, grid, directions, random)) {
//           success = false;
//           break;
//         }
//       }
//       attempts++;
//     } while (!success && attempts < 200);
//
//     if (!success) throw Exception("Failed to generate grid");
//
//     for (int r = 0; r < gridSize; r++) {
//       for (int c = 0; c < gridSize; c++) {
//         if (grid[r][c] == '') {
//           grid[r][c] = String.fromCharCode(65 + random.nextInt(26));
//         }
//       }
//     }
//
//     return grid;
//   }
//
//   bool _placeWord(String word, List<List<String>> grid, List<List<int>> directions, Random random) {
//     for (int attempt = 0; attempt < 200; attempt++) {
//       final dir = directions[random.nextInt(directions.length)];
//       final dx = dir[0], dy = dir[1];
//
//       int maxRow = gridSize - (dx.abs() * (word.length - 1));
//       int maxCol = gridSize - (dy.abs() * (word.length - 1));
//       if (maxRow <= 0 || maxCol <= 0) continue;
//
//       int row = dx < 0 ? random.nextInt(maxRow) + (gridSize - maxRow) : random.nextInt(maxRow);
//       int col = dy < 0 ? random.nextInt(maxCol) + (gridSize - maxCol) : random.nextInt(maxCol);
//
//       bool fits = true;
//       for (int i = 0; i < word.length; i++) {
//         int r = row + dx * i;
//         int c = col + dy * i;
//         if (r < 0 || r >= gridSize || c < 0 || c >= gridSize ||
//             (grid[r][c] != '' && grid[r][c] != word[i])) {
//           fits = false;
//           break;
//         }
//       }
//
//       if (fits) {
//         for (int i = 0; i < word.length; i++) {
//           int r = row + dx * i;
//           int c = col + dy * i;
//           grid[r][c] = word[i];
//         }
//         return true;
//       }
//     }
//     return false;
//   }
//
//   bool _isValidDirection(Offset a, Offset b) {
//     int dx = (b.dx - a.dx).round().abs();
//     int dy = (b.dy - a.dy).round().abs();
//     return dx == 0 || dy == 0 || dx == dy;
//   }
//
//   void handleDragStart(DragStartDetails details, double cellSize) {
//     final position = details.localPosition;
//     final row = (position.dy / cellSize).floor().clamp(0, gridSize - 1);
//     final col = (position.dx / cellSize).floor().clamp(0, gridSize - 1);
//     start = Offset(row.toDouble(), col.toDouble());
//     setState(() {
//       currentDragPath = [start!];
//     });
//   }
//
//   void handleDragUpdate(DragUpdateDetails details, double cellSize) {
//     final position = details.localPosition;
//     final row = (position.dy / cellSize).floor().clamp(0, gridSize - 1);
//     final col = (position.dx / cellSize).floor().clamp(0, gridSize - 1);
//     end = Offset(row.toDouble(), col.toDouble());
//
//     if (start != null && _isValidDirection(start!, end!)) {
//       setState(() {
//         currentDragPath = _getHighlightedCells(start!, end!);
//       });
//     }
//   }
//
//   void handleDragEnd() {
//     if (start != null && end != null && _isValidDirection(start!, end!)) {
//       String selectedWord = _getSelectedWord(start!, end!);
//       if (selectedWord.length < 3) {
//         setState(() {
//           currentDragPath.clear();
//         });
//         start = end = null;
//         return;
//       }
//
//       String reversedWord = selectedWord.split('').reversed.join();
//       String? matchedWord;
//
//       if (currentWords.contains(selectedWord)) {
//         matchedWord = selectedWord;
//       } else if (currentWords.contains(reversedWord)) {
//         matchedWord = reversedWord;
//       }
//
//       if (matchedWord != null && !foundWordPaths.containsKey(matchedWord)) {
//         final path = _getHighlightedCells(start!, end!);
//         setState(() {
//           foundWordPaths[matchedWord!] = path;
//           currentDragPath.clear();
//         });
//
//         if (foundWordPaths.length == currentWords.length) {
//           timer?.cancel();
//           showSuccessDialog();
//         }
//       } else {
//         setState(() {
//           currentDragPath.clear();
//         });
//       }
//     } else {
//       setState(() {
//         currentDragPath.clear();
//       });
//     }
//     start = end = null;
//   }
//
//   String _getSelectedWord(Offset a, Offset b) {
//     final dx = (b.dx - a.dx).round();
//     final dy = (b.dy - a.dy).round();
//     final stepX = dx == 0 ? 0 : dx ~/ dx.abs();
//     final stepY = dy == 0 ? 0 : dy ~/ dy.abs();
//     int x = a.dx.round(), y = a.dy.round();
//     String word = '';
//
//     while (x >= 0 && y >= 0 && x < gridSize && y < gridSize) {
//       word += grid[x][y];
//       if (x == b.dx.round() && y == b.dy.round()) break;
//       x += stepX;
//       y += stepY;
//     }
//     return word;
//   }
//
//   List<Offset> _getHighlightedCells(Offset a, Offset b) {
//     final List<Offset> cells = [];
//     final dx = (b.dx - a.dx).round();
//     final dy = (b.dy - a.dy).round();
//     final stepX = dx == 0 ? 0 : dx ~/ dx.abs();
//     final stepY = dy == 0 ? 0 : dy ~/ dy.abs();
//     int x = a.dx.round(), y = a.dy.round();
//
//     while (x >= 0 && y >= 0 && x < gridSize && y < gridSize) {
//       cells.add(Offset(x.toDouble(), y.toDouble()));
//       if (x == b.dx.round() && y == b.dy.round()) break;
//       x += stepX;
//       y += stepY;
//     }
//     return cells;
//   }
//
//   Color? getCellColor(int row, int col) {
//     final current = Offset(row.toDouble(), col.toDouble());
//
//     if (currentDragPath.contains(current)) {
//       return Colors.yellow.withOpacity(0.5);
//     }
//
//     int index = 0;
//     for (var entry in foundWordPaths.entries) {
//       if (entry.value.contains(current)) {
//         return highlightColors[index % highlightColors.length];
//       }
//       index++;
//     }
//     return null;
//   }
//
//   void showSuccessDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         title: const Text('Level Complete!'),
//         content: Text('Proceeding to level ${level + 1}'),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               setState(() {
//                 level++;
//                 startLevel();
//               });
//             },
//             child: const Text('Continue'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void showGameOverDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         title: const Text('Time Up!'),
//         content: Text('You reached level $level.'),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               Navigator.pop(context);
//             },
//             child: const Text('Back to Levels'),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               setState(() {
//                 startLevel();
//               });
//             },
//             child: const Text('Retry'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     timer?.cancel();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final cellSize = (MediaQuery.of(context).size.width * 0.9) / gridSize;
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFDAAB5C),
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF7A5821),
//         title: Text(
//           "Level $level — ⏱ $timeLeft",
//           style: const TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         centerTitle: true,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             const SizedBox(height: 20),
//             Center(
//               child: GestureDetector(
//                 onPanStart: (details) => handleDragStart(details, cellSize),
//                 onPanUpdate: (details) => handleDragUpdate(details, cellSize),
//                 onPanEnd: (_) => handleDragEnd(),
//                 child: Container(
//                   width: cellSize * gridSize,
//                   height: cellSize * gridSize,
//                   padding: const EdgeInsets.all(8),
//                   child: GridView.builder(
//                     physics: const NeverScrollableScrollPhysics(),
//                     itemCount: gridSize * gridSize,
//                     gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                       crossAxisCount: gridSize,
//                       mainAxisSpacing: 4,
//                       crossAxisSpacing: 4,
//                     ),
//                     itemBuilder: (context, index) {
//                       final row = index ~/ gridSize;
//                       final col = index % gridSize;
//                       final color = getCellColor(row, col);
//
//                       return Container(
//                         decoration: BoxDecoration(
//                           color: color ?? const Color(0xFFFFF8E1),
//                           borderRadius: BorderRadius.circular(8),
//                           border: Border.all(color: const Color(0xFF7A5821), width: 1),
//                           boxShadow: const [
//                             BoxShadow(
//                               color: Colors.black12,
//                               blurRadius: 2,
//                               offset: Offset(1, 1),
//                             ),
//                           ],
//                         ),
//                         alignment: Alignment.center,
//                         child: Text(
//                           grid[row][col],
//                           style: TextStyle(
//                             fontSize: 20,
//                             fontWeight: FontWeight.bold,
//                             fontFamily: 'Courier',
//                             color: color != null ? Colors.white : const Color(0xFF7A5821),
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 40),
//             const Text(
//               'Find the Words:',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF7A5821),
//               ),
//             ),
//             const SizedBox(height: 10),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: Wrap(
//                 spacing: 8,
//                 runSpacing: 8,
//                 children: currentWords.map((word) {
//                   final found = foundWordPaths.containsKey(word);
//                   return Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//                     decoration: BoxDecoration(
//                       color: found ? Colors.green.shade300 : Colors.white,
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: const Color(0xFF7A5821)),
//                       boxShadow: [
//                         if (found)
//                           BoxShadow(
//                             color: Colors.green.shade900.withOpacity(0.3),
//                             offset: const Offset(1, 1),
//                             blurRadius: 2,
//                           ),
//                       ],
//                     ),
//                     child: Text(
//                       word,
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                         color: found ? Colors.white : const Color(0xFF7A5821),
//                         decoration: found ? TextDecoration.lineThrough : null,
//                       ),
//                     ),
//                   );
//                 }).toList(),
//               ),
//             ),
//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // import 'dart:async';
// // import 'dart:math';
// // import 'package:flutter/material.dart';
// //
// // class WordSearchPage extends StatefulWidget {
// //   final int initialLevel;
// //   const WordSearchPage({Key? key, required this.initialLevel}) : super(key: key);
// //
// //   @override
// //   _WordSearchPageState createState() => _WordSearchPageState();
// // }
// //
// // class _WordSearchPageState extends State<WordSearchPage> {
// //   late int level;
// //   int timeLeft = 90;
// //   Timer? timer;
// //   final int gridSize = 10;
// //
// //   final List<String> allWords = [
// //     'FLUTTER', 'DART', 'CODE', 'GRID', 'PUZZLE',
// //     'GAME', 'LEVEL', 'TIMER', 'BONUS', 'SOFTWARE',
// //     'MOBILE', 'FUN', 'CHALLENGE', 'LOGIC', 'SOLVE',
// //     'ALGORITHM', 'DEBUG', 'TEST', 'WIDGET', 'MATERIAL'
// //   ];
// //   List<Offset> currentDragPath = [];
// //
// //   late List<String> currentWords;
// //   late List<List<String>> grid;
// //
// //   Offset? start;
// //   Offset? end;
// //   final Map<String, List<Offset>> foundWordPaths = {};
// //   final List<Color> highlightColors = [
// //     Colors.orange.shade300,
// //     Colors.teal.shade300,
// //     Colors.purple.shade300,
// //     Colors.blue.shade300,
// //     Colors.pink.shade300,
// //     Colors.green.shade300,
// //     Colors.red.shade300,
// //     Colors.amber.shade300,
// //     Colors.cyan.shade300,
// //     Colors.indigo.shade300,
// //   ];
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     level = widget.initialLevel;
// //     startLevel();
// //   }
// //
// //   void startLevel() {
// //     try {
// //       List<String> shuffledWords = List.from(allWords)..shuffle();
// //       currentWords = shuffledWords.take(5 + level).toList();
// //       grid = generateGridWithWords(currentWords);
// //       timeLeft = 90;
// //       foundWordPaths.clear();
// //       startTimer();
// //     } catch (e) {
// //       // Handle grid generation failure
// //       showGameOverDialog();
// //     }
// //   }
// //
// //   void startTimer() {
// //     timer?.cancel();
// //     timer = Timer.periodic(const Duration(seconds: 1), (t) {
// //       setState(() {
// //         timeLeft--;
// //         if (timeLeft <= 0) {
// //           t.cancel();
// //           showGameOverDialog();
// //         }
// //       });
// //     });
// //   }
// //
// //   List<List<String>> generateGridWithWords(List<String> words) {
// //     final random = Random();
// //     List<List<String>> grid;
// //     bool success;
// //     int attempts = 0;
// //
// //     do {
// //       success = true;
// //       grid = List.generate(gridSize, (_) => List.filled(gridSize, ''));
// //       final directions = [
// //         [0, 1], [1, 0], [1, 1], [-1, 1],
// //         [0, -1], [-1, 0], [-1, -1], [1, -1]
// //       ];
// //
// //       for (String word in words) {
// //         if (!_placeWord(word, grid, directions, random)) {
// //           success = false;
// //           break;
// //         }
// //       }
// //       attempts++;
// //     } while (!success && attempts < 100);
// //
// //     if (!success) throw Exception("Failed to generate grid");
// //
// //     for (int r = 0; r < gridSize; r++) {
// //       for (int c = 0; c < gridSize; c++) {
// //         if (grid[r][c] == '') {
// //           grid[r][c] = String.fromCharCode(65 + random.nextInt(26));
// //         }
// //       }
// //     }
// //
// //     return grid;
// //   }
// //
// //   // bool _placeWord(String word, List<List<String>> grid, List<List<int>> directions, Random random) {
// //   //   for (int attempt = 0; attempt < 100; attempt++) {
// //   //     final dir = directions[random.nextInt(directions.length)];
// //   //     final dx = dir[0], dy = dir[1];
// //   //
// //   //     int maxRow = gridSize - (dx.abs() * (word.length - 1));
// //   //     int maxCol = gridSize - (dy.abs() * (word.length - 1));
// //   //     if (maxRow <= 0 || maxCol <= 0) continue;
// //   //
// //   //     int row = random.nextInt(maxRow);
// //   //     int col = random.nextInt(maxCol);
// //   //     if (dx < 0) row = gridSize - 1 - row;
// //   //     if (dy < 0) col = gridSize - 1 - col;
// //   //
// //   //     bool fits = true;
// //   //     for (int i = 0; i < word.length; i++) {
// //   //       int r = row + dx * i;
// //   //       int c = col + dy * i;
// //   //       if (r < 0 || r >= gridSize || c < 0 || c >= gridSize ||
// //   //           (grid[r][c] != '' && grid[r][c] != word[i])) {
// //   //         fits = false;
// //   //         break;
// //   //       }
// //   //     }
// //   //
// //   //     if (fits) {
// //   //       for (int i = 0; i < word.length; i++) {
// //   //         int r = row + dx * i;
// //   //         int c = col + dy * i;
// //   //         grid[r][c] = word[i];
// //   //       }
// //   //       return true;
// //   //     }
// //   //   }
// //   //   return false;
// //   // }
// //   bool _placeWord(String word, List<List<String>> grid, List<List<int>> directions, Random random) {
// //     for (int attempt = 0; attempt < 200; attempt++) { // Increased attempts
// //       final dir = directions[random.nextInt(directions.length)];
// //       final dx = dir[0], dy = dir[1];
// //
// //       int maxRow = gridSize - (dx.abs() * (word.length - 1));
// //       int maxCol = gridSize - (dy.abs() * (word.length - 1));
// //       if (maxRow <= 0 || maxCol <= 0) continue;
// //
// //       // Ensure starting position is within valid range
// //       int row = dx < 0 ? random.nextInt(maxRow) + (gridSize - maxRow) : random.nextInt(maxRow);
// //       int col = dy < 0 ? random.nextInt(maxCol) + (gridSize - maxCol) : random.nextInt(maxCol);
// //
// //       bool fits = true;
// //       for (int i = 0; i < word.length; i++) {
// //         int r = row + dx * i;
// //         int c = col + dy * i;
// //         if (r < 0 || r >= gridSize || c < 0 || c >= gridSize ||
// //             (grid[r][c] != '' && grid[r][c] != word[i])) {
// //           fits = false;
// //           break;
// //         }
// //       }
// //
// //       if (fits) {
// //         for (int i = 0; i < word.length; i++) {
// //           int r = row + dx * i;
// //           int c = col + dy * i;
// //           grid[r][c] = word[i];
// //         }
// //         return true;
// //       }
// //     }
// //     return false;
// //   }
// //
// //   bool _isValidDirection(Offset a, Offset b) {
// //     int dx = (b.dx - a.dx).toInt().abs();
// //     int dy = (b.dy - a.dy).toInt().abs();
// //     return dx == 0 || dy == 0 || dx == dy;
// //   }
// //
// //   void handleDragStart(DragStartDetails details, double cellSize) {
// //     final position = details.localPosition;
// //     final row = (position.dy ~/ cellSize).clamp(0, gridSize - 1);
// //     final col = (position.dx ~/ cellSize).clamp(0, gridSize - 1);
// //     start = Offset(row.toDouble(), col.toDouble());
// //     setState(() {
// //       currentDragPath = [start!];
// //     });
// //   }
// //
// //   void handleDragUpdate(DragUpdateDetails details, double cellSize) {
// //     final position = details.localPosition;
// //     final row = (position.dy ~/ cellSize).clamp(0, gridSize - 1);
// //     final col = (position.dx ~/ cellSize).clamp(0, gridSize - 1);
// //     end = Offset(row.toDouble(), col.toDouble());
// //     setState(() {
// //       currentDragPath = _getHighlightedCells(start!, end!);
// //     });
// //   }
// //
// //   void handleDragEnd() {
// //     if (start != null && end != null) {
// //       if (!_isValidDirection(start!, end!)) {
// //         setState(() {
// //           currentDragPath.clear();
// //         });
// //         start = end = null;
// //         return;
// //       }
// //
// //       String selectedWord = _getSelectedWord(start!, end!);
// //       if (selectedWord.length < 3) {
// //         setState(() {
// //           currentDragPath.clear();
// //         });
// //         start = end = null;
// //         return;
// //       }
// //
// //       String reversedWord = selectedWord.split('').reversed.join();
// //       String? matchedWord;
// //
// //       if (currentWords.contains(selectedWord)) {
// //         matchedWord = selectedWord;
// //       } else if (currentWords.contains(reversedWord)) {
// //         matchedWord = reversedWord;
// //       }
// //
// //       if (matchedWord != null && !foundWordPaths.containsKey(matchedWord)) {
// //         final path = _getHighlightedCells(start!, end!);
// //         setState(() {
// //           foundWordPaths[matchedWord!] = path;
// //           currentDragPath.clear();
// //         });
// //
// //         if (foundWordPaths.length == currentWords.length) {
// //           timer?.cancel();
// //           showSuccessDialog();
// //         }
// //       } else {
// //         setState(() {
// //           currentDragPath.clear();
// //         });
// //       }
// //     }
// //     start = end = null;
// //   }
// //
// //   String _getSelectedWord(Offset a, Offset b) {
// //     final dx = b.dx.toInt() - a.dx.toInt();
// //     final dy = b.dy.toInt() - a.dy.toInt();
// //     final stepX = dx == 0 ? 0 : dx ~/ dx.abs();
// //     final stepY = dy == 0 ? 0 : dy ~/ dy.abs();
// //     int x = a.dx.toInt(), y = a.dy.toInt();
// //     String word = '';
// //
// //     while (x >= 0 && y >= 0 && x < gridSize && y < gridSize) {
// //       word += grid[x][y];
// //       if (x == b.dx.toInt() && y == b.dy.toInt()) break;
// //       x += stepX;
// //       y += stepY;
// //     }
// //     return word;
// //   }
// //
// //   List<Offset> _getHighlightedCells(Offset a, Offset b) {
// //     final List<Offset> cells = [];
// //     final dx = b.dx.toInt() - a.dx.toInt();
// //     final dy = b.dy.toInt() - a.dy.toInt();
// //     final stepX = dx == 0 ? 0 : dx ~/ dx.abs();
// //     final stepY = dy == 0 ? 0 : dy ~/ dy.abs();
// //     int x = a.dx.toInt(), y = a.dy.toInt();
// //
// //     while (true) {
// //       cells.add(Offset(x.toDouble(), y.toDouble()));
// //       if (x == b.dx.toInt() && y == b.dy.toInt()) break;
// //       x += stepX;
// //       y += stepY;
// //     }
// //     return cells;
// //   }
// //
// //   Color? getCellColor(int row, int col) {
// //     final current = Offset(row.toDouble(), col.toDouble());
// //
// //     if (currentDragPath.contains(current)) {
// //       return Colors.yellow.withOpacity(0.5);
// //     }
// //
// //     int index = 0;
// //     for (var entry in foundWordPaths.entries) {
// //       if (entry.value.contains(current)) {
// //         return highlightColors[index % highlightColors.length];
// //       }
// //       index++;
// //     }
// //     return null;
// //   }
// //
// //   void showSuccessDialog() {
// //     showDialog(
// //       context: context,
// //       barrierDismissible: false,
// //       builder: (context) => AlertDialog(
// //         title: const Text('Level Complete!'),
// //         content: Text('Proceeding to level ${level + 1}'),
// //         actions: [
// //           TextButton(
// //             onPressed: () {
// //               Navigator.pop(context);
// //               setState(() {
// //                 level++;
// //                 startLevel();
// //               });
// //             },
// //             child: const Text('Continue'),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   void showGameOverDialog() {
// //     showDialog(
// //       context: context,
// //       barrierDismissible: false,
// //       builder: (context) => AlertDialog(
// //         title: const Text('Time Up!'),
// //         content: Text('You reached level $level.'),
// //         actions: [
// //           TextButton(
// //             onPressed: () {
// //               Navigator.pop(context);
// //               Navigator.pop(context);
// //             },
// //             child: const Text('Back to Levels'),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   @override
// //   void dispose() {
// //     timer?.cancel();
// //     super.dispose();
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final cellSize = (MediaQuery.of(context).size.height * 0.55 - (gridSize - 1) * 4) / gridSize;
// //
// //     return Scaffold(
// //       backgroundColor: const Color(0xFFDAAB5C),
// //       appBar: AppBar(
// //         backgroundColor: const Color(0xFF7A5821),
// //         title: Text(
// //           "Level $level — ⏱ $timeLeft",
// //           style: const TextStyle(
// //             color: Colors.white,
// //             fontWeight: FontWeight.bold,
// //           ),
// //         ),
// //         centerTitle: true,
// //         leading: BackButton(color: Colors.white),
// //       ),
// //       body: Column(
// //         children: [
// //           const SizedBox(height: 10),
// //           GestureDetector(
// //             onPanStart: (details) => handleDragStart(details, cellSize),
// //             onPanUpdate: (details) => handleDragUpdate(details, cellSize),
// //             onPanEnd: (_) => handleDragEnd(),
// //             child: Container(
// //               height: cellSize * gridSize + (gridSize - 1) * 4,
// //               padding: const EdgeInsets.symmetric(horizontal: 12),
// //               child: GridView.builder(
// //                 physics: const NeverScrollableScrollPhysics(),
// //                 itemCount: gridSize * gridSize,
// //                 gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
// //                   crossAxisCount: gridSize,
// //                   mainAxisSpacing: 4,
// //                   crossAxisSpacing: 4,
// //                 ),
// //                 itemBuilder: (context, index) {
// //                   final row = index ~/ gridSize;
// //                   final col = index % gridSize;
// //                   final color = getCellColor(row, col);
// //
// //                   return Container(
// //                     decoration: BoxDecoration(
// //                       color: color ?? const Color(0xFFFFF8E1),
// //                       borderRadius: BorderRadius.circular(10),
// //                       border: Border.all(color: const Color(0xFF7A5821), width: 1.2),
// //                       boxShadow: [
// //                         BoxShadow(
// //                           color: Colors.black26,
// //                           blurRadius: 2,
// //                           offset: Offset(2, 2),
// //                         ),
// //                       ],
// //                     ),
// //                     alignment: Alignment.center,
// //                     child: Text(
// //                       grid[row][col],
// //                       style: TextStyle(
// //                         fontSize: 22,
// //                         fontWeight: FontWeight.bold,
// //                         fontFamily: 'Courier',
// //                         color: color != null ? Colors.white : const Color(0xFF7A5821),
// //                       ),
// //                     ),
// //                   );
// //                 },
// //               ),
// //             ),
// //           ),
// //           const SizedBox(height: 20),
// //           const Text(
// //             'Find the Words:',
// //             style: TextStyle(
// //               fontSize: 20,
// //               fontWeight: FontWeight.bold,
// //               color: Color(0xFF7A5821),
// //               letterSpacing: 1.2,
// //             ),
// //           ),
// //           const SizedBox(height: 10),
// //           Padding(
// //             padding: const EdgeInsets.symmetric(horizontal: 12),
// //             child: Wrap(
// //               spacing: 10,
// //               runSpacing: 10,
// //               children: currentWords.map((word) {
// //                 final found = foundWordPaths.containsKey(word);
// //                 return Container(
// //                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
// //                   decoration: BoxDecoration(
// //                     color: found ? Colors.green.shade300 : Colors.white,
// //                     borderRadius: BorderRadius.circular(6),
// //                     border: Border.all(color: const Color(0xFF7A5821), width: 1.5),
// //                     boxShadow: [
// //                       if (found)
// //                         BoxShadow(
// //                           color: Colors.green.shade900.withOpacity(0.4),
// //                           offset: Offset(1, 1),
// //                           blurRadius: 3,
// //                         ),
// //                     ],
// //                   ),
// //                   child: Text(
// //                     word,
// //                     style: TextStyle(
// //                       fontSize: 16,
// //                       fontWeight: FontWeight.w700,
// //                       color: found ? Colors.white : const Color(0xFF7A5821),
// //                       decoration: found ? TextDecoration.lineThrough : null,
// //                       letterSpacing: 1,
// //                     ),
// //                   ),
// //                 );
// //               }).toList(),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
