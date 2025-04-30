import 'package:flutter/material.dart';
import 'package:word_puzzle/view/homepage.dart';

void main() => runApp(const WordSearchApp());

class WordSearchApp extends StatelessWidget {
  const WordSearchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Word Search Puzzle',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFF4F7F9),
        fontFamily: 'Arial',
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}


// import 'dart:async';
// import 'dart:math';
// import 'package:flutter/material.dart';
//
// void main() => runApp(const WordSearchApp());
//
// class WordSearchApp extends StatelessWidget {
//   const WordSearchApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Word Search Puzzle',
//       theme: ThemeData(
//         primarySwatch: Colors.teal,
//         scaffoldBackgroundColor: const Color(0xFFF4F7F9),
//         fontFamily: 'Arial',
//       ),
//       home: const WordSearchPage(),
//       debugShowCheckedModeBanner: false,
//     );
//   }
// }
//
// class WordSearchPage extends StatefulWidget {
//   const WordSearchPage({Key? key}) : super(key: key);
//
//   @override
//   _WordSearchPageState createState() => _WordSearchPageState();
// }
//
// class _WordSearchPageState extends State<WordSearchPage> {
//   int level = 1;
//   int timeLeft = 60;
//   Timer? timer;
//   final int gridSize = 10;
//
//   final List<String> allWords = [
//     'FLUTTER', 'DART', 'CODE', 'GRID', 'PUZZLE',
//     'GAME', 'LEVEL', 'TIMER', 'BONUS', 'SOFTWARE',
//     'MOBILE', 'FUN', 'CHALLENGE', 'LOGIC', 'SOLVE',
//     'ALGORITHM', 'DEBUG', 'TEST', 'WIDGET', 'MATERIAL'
//   ];
//
//   late List<String> currentWords;
//   late List<List<String>> grid;
//
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
//     startLevel();
//   }
//
//   void startLevel() {
//     List<String> shuffledWords = List.from(allWords)..shuffle();
//     currentWords = shuffledWords.take(5 + level).toList();
//     grid = generateGridWithWords(currentWords);
//     timeLeft = 60;
//     foundWordPaths.clear();
//     startTimer();
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
//     } while (!success && attempts < 100);
//
//     if (!success) throw Exception("Failed to generate grid");
//
//     // Fill empty cells
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
//     for (int attempt = 0; attempt < 100; attempt++) {
//       final dir = directions[random.nextInt(directions.length)];
//       final dx = dir[0], dy = dir[1];
//
//       int maxRow = gridSize - (dx.abs() * (word.length - 1));
//       int maxCol = gridSize - (dy.abs() * (word.length - 1));
//       if (maxRow <= 0 || maxCol <= 0) continue;
//
//       int row = random.nextInt(maxRow);
//       int col = random.nextInt(maxCol);
//       if (dx < 0) row = gridSize - 1 - row;
//       if (dy < 0) col = gridSize - 1 - col;
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
//   void handleDragStart(DragStartDetails details, double cellSize) {
//     final position = details.localPosition;
//     final row = (position.dy ~/ cellSize).clamp(0, gridSize - 1);
//     final col = (position.dx ~/ cellSize).clamp(0, gridSize - 1);
//     start = Offset(row.toDouble(), col.toDouble());
//   }
//
//   void handleDragUpdate(DragUpdateDetails details, double cellSize) {
//     final position = details.localPosition;
//     final row = (position.dy ~/ cellSize).clamp(0, gridSize - 1);
//     final col = (position.dx ~/ cellSize).clamp(0, gridSize - 1);
//     end = Offset(row.toDouble(), col.toDouble());
//   }
//
//   void handleDragEnd() {
//     if (start != null && end != null) {
//       String selectedWord = _getSelectedWord(start!, end!);
//       String reversedWord = selectedWord.split('').reversed.join();
//
//       String? matchedWord;
//       if (currentWords.contains(selectedWord)) {
//         matchedWord = selectedWord;
//       } else if (currentWords.contains(reversedWord)) {
//         matchedWord = reversedWord;
//       }
//
//       if (matchedWord != null && !foundWordPaths.containsKey(matchedWord)) {
//         final path = _getHighlightedCells(start!, end!);
//         setState(() => foundWordPaths[matchedWord!] = path);
//
//         if (foundWordPaths.length == currentWords.length) {
//           timer?.cancel();
//           showSuccessDialog();
//         }
//       }
//     }
//     start = end = null;
//   }
//
//   String _getSelectedWord(Offset a, Offset b) {
//     final dx = b.dx.toInt() - a.dx.toInt();
//     final dy = b.dy.toInt() - a.dy.toInt();
//     final stepX = dx == 0 ? 0 : dx ~/ dx.abs();
//     final stepY = dy == 0 ? 0 : dy ~/ dy.abs();
//     int x = a.dx.toInt(), y = a.dy.toInt();
//     String word = '';
//
//     while (x >= 0 && y >= 0 && x < gridSize && y < gridSize) {
//       word += grid[x][y];
//       if (x == b.dx.toInt() && y == b.dy.toInt()) break;
//       x += stepX;
//       y += stepY;
//     }
//     return word;
//   }
//
//   List<Offset> _getHighlightedCells(Offset a, Offset b) {
//     final List<Offset> cells = [];
//     final dx = b.dx.toInt() - a.dx.toInt();
//     final dy = b.dy.toInt() - a.dy.toInt();
//     final stepX = dx == 0 ? 0 : dx ~/ dx.abs();
//     final stepY = dy == 0 ? 0 : dy ~/ dy.abs();
//     int x = a.dx.toInt(), y = a.dy.toInt();
//
//     while (true) {
//       cells.add(Offset(x.toDouble(), y.toDouble()));
//       if (x == b.dx.toInt() && y == b.dy.toInt()) break;
//       x += stepX;
//       y += stepY;
//     }
//     return cells;
//   }
//
//   Color? getCellColor(int row, int col) {
//     final current = Offset(row.toDouble(), col.toDouble());
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
//               setState(() {
//                 level = 1;
//                 startLevel();
//               });
//             },
//             child: const Text('Play Again'),
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
//     final cellSize = (MediaQuery.of(context).size.height * 0.55 - (gridSize - 1) * 4) / gridSize;
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Level $level — Time Left: $timeLeft"),
//         backgroundColor: Colors.teal.shade600,
//       ),
//       body: Column(
//         children: [
//           const SizedBox(height: 10),
//           GestureDetector(
//             onPanStart: (details) => handleDragStart(details, cellSize),
//             onPanUpdate: (details) => handleDragUpdate(details, cellSize),
//             onPanEnd: (_) => handleDragEnd(),
//             child: SizedBox(
//               height: cellSize * gridSize + (gridSize - 1) * 4,
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 12),
//                 child: GridView.builder(
//                   physics: const NeverScrollableScrollPhysics(),
//                   itemCount: gridSize * gridSize,
//                   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: gridSize,
//                     mainAxisSpacing: 4,
//                     crossAxisSpacing: 4,
//                   ),
//                   itemBuilder: (context, index) {
//                     final row = index ~/ gridSize;
//                     final col = index % gridSize;
//                     final color = getCellColor(row, col);
//
//                     return Container(
//                       decoration: BoxDecoration(
//                           color: color ?? Colors.white,
//                           borderRadius: BorderRadius.circular(8),
//                           boxShadow: [
//                           BoxShadow(
//                           color: Colors.black12,
//                           blurRadius: 3,
//                           offset: const Offset(1, 1),
//                           )],
//                       border: Border.all(color: Colors.grey.shade400),
//                     ),
//                     alignment: Alignment.center,
//                     child: Text(
//                     grid[row][col],
//                     style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: color != null ? Colors.white : Colors.black,
//                     ),
//                     ),
//                     );
//                   },
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 20),
//           const Text(
//             'Find the Words:',
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 10),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 12),
//             child: Wrap(
//               spacing: 8,
//               runSpacing: 8,
//               children: currentWords.map((word) {
//                 final found = foundWordPaths.containsKey(word);
//                 return Chip(
//                   label: Text(
//                     word,
//                     style: TextStyle(
//                       fontWeight: FontWeight.w600,
//                       decoration: found ? TextDecoration.lineThrough : null,
//                       color: found ? Colors.green.shade900 : Colors.black,
//                     ),
//                   ),
//                   backgroundColor: found ? Colors.green.shade200 : Colors.grey.shade300,
//                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                 );
//               }).toList(),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// import 'dart:async';
// import 'dart:math';
// import 'package:flutter/material.dart';
//
// void main() => runApp(const WordSearchApp());
//
// class WordSearchApp extends StatelessWidget {
//   const WordSearchApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Word Search Puzzle',
//       theme: ThemeData(
//         primarySwatch: Colors.teal,
//         scaffoldBackgroundColor: const Color(0xFFF4F7F9),
//         fontFamily: 'Arial',
//       ),
//       home: const WordSearchPage(),
//       debugShowCheckedModeBanner: false,
//     );
//   }
// }
//
// class WordSearchPage extends StatefulWidget {
//   const WordSearchPage({Key? key}) : super(key: key);
//
//   @override
//   _WordSearchPageState createState() => _WordSearchPageState();
// }
//
// class _WordSearchPageState extends State<WordSearchPage> {
//   int level = 1;
//   int timeLeft = 60;
//   Timer? timer;
//
//   final List<String> allWords = [
//     'WORD', 'SEARCH', 'JOURNEY', 'LOVE', 'ENJOY',
//     'CALL', 'PUZZLE', 'BACK', 'FUN', 'SACK'
//   ];
//
//   late List<String> currentWords;
//   late List<List<String>> grid;
//
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
//     startLevel();
//   }
//
//   void startLevel() {
//     currentWords = allWords.take(5 + level).toList();
//     grid = generateGridWithWords(currentWords, 10);
//     timeLeft = 60;
//     foundWordPaths.clear();
//     startTimer();
//   }
//
//   void startTimer() {
//     timer?.cancel();
//     timer = Timer.periodic(const Duration(seconds: 1), (t) {
//       setState(() {
//         timeLeft--;
//         if (timeLeft <= 0) {
//           t.cancel();
//           // Handle game over if desired
//         }
//       });
//     });
//   }
//
//   List<List<String>> generateGridWithWords(List<String> words, int size) {
//     final grid = List.generate(size, (_) => List.generate(size, (_) => ''));
//     final random = Random();
//
//     List<List<int>> directions = [
//       [0, 1],   // right
//       [1, 0],   // down
//       [1, 1],   // diagonal down-right
//       [-1, 1],  // diagonal up-right
//     ];
//
//     bool placeWord(String word) {
//       for (int attempt = 0; attempt < 100; attempt++) {
//         final dir = directions[random.nextInt(directions.length)];
//         final dx = dir[0], dy = dir[1];
//         int row = random.nextInt(size);
//         int col = random.nextInt(size);
//
//         int endRow = row + dx * (word.length - 1);
//         int endCol = col + dy * (word.length - 1);
//
//         if (endRow < 0 || endRow >= size || endCol < 0 || endCol >= size) continue;
//
//         bool fits = true;
//         for (int i = 0; i < word.length; i++) {
//           int r = row + dx * i;
//           int c = col + dy * i;
//           if (grid[r][c] != '' && grid[r][c] != word[i]) {
//             fits = false;
//             break;
//           }
//         }
//
//         if (!fits) continue;
//
//         for (int i = 0; i < word.length; i++) {
//           int r = row + dx * i;
//           int c = col + dy * i;
//           grid[r][c] = word[i];
//         }
//
//         return true;
//       }
//       print("Failed to place word: $word");
//       return false;
//     }
//
//     for (var word in words) {
//       placeWord(word);
//     }
//
//     for (int r = 0; r < size; r++) {
//       for (int c = 0; c < size; c++) {
//         if (grid[r][c] == '') {
//           grid[r][c] = String.fromCharCode(65 + random.nextInt(26));
//         }
//       }
//     }
//
//     return grid;
//   }
//
//   void handleDragStart(DragStartDetails details, double cellSize) {
//     final position = details.localPosition;
//     final row = (position.dy ~/ cellSize).clamp(0, 9);
//     final col = (position.dx ~/ cellSize).clamp(0, 9);
//     start = Offset(row.toDouble(), col.toDouble());
//   }
//
//   void handleDragUpdate(DragUpdateDetails details, double cellSize) {
//     final position = details.localPosition;
//     final row = (position.dy ~/ cellSize).clamp(0, 9);
//     final col = (position.dx ~/ cellSize).clamp(0, 9);
//     end = Offset(row.toDouble(), col.toDouble());
//   }
//
//   void handleDragEnd() {
//     if (start != null && end != null) {
//       final word = getSelectedWord(start!, end!);
//       if (currentWords.contains(word) && !foundWordPaths.containsKey(word)) {
//         final path = getHighlightedCells(start!, end!);
//         setState(() {
//           foundWordPaths[word] = path;
//         });
//
//         if (foundWordPaths.length == currentWords.length) {
//           timer?.cancel();
//           Future.delayed(const Duration(seconds: 1), () {
//             setState(() {
//               level++;
//               startLevel();
//             });
//           });
//         }
//       }
//     }
//     start = null;
//     end = null;
//   }
//
//   String getSelectedWord(Offset a, Offset b) {
//     final dx = b.dx.toInt() - a.dx.toInt();
//     final dy = b.dy.toInt() - a.dy.toInt();
//     final stepX = dx == 0 ? 0 : dx ~/ dx.abs();
//     final stepY = dy == 0 ? 0 : dy ~/ dy.abs();
//     int x = a.dx.toInt(), y = a.dy.toInt();
//     String word = '';
//
//     while (x >= 0 && y >= 0 && x < 10 && y < 10) {
//       word += grid[x][y];
//       if (x == b.dx.toInt() && y == b.dy.toInt()) break;
//       x += stepX;
//       y += stepY;
//     }
//     return word;
//   }
//
//   List<Offset> getHighlightedCells(Offset a, Offset b) {
//     final List<Offset> cells = [];
//     final dx = b.dx.toInt() - a.dx.toInt();
//     final dy = b.dy.toInt() - a.dy.toInt();
//     final stepX = dx == 0 ? 0 : dx ~/ dx.abs();
//     final stepY = dy == 0 ? 0 : dy ~/ dy.abs();
//     int x = a.dx.toInt(), y = a.dy.toInt();
//
//     while (true) {
//       cells.add(Offset(x.toDouble(), y.toDouble()));
//       if (x == b.dx.toInt() && y == b.dy.toInt()) break;
//       x += stepX;
//       y += stepY;
//     }
//     return cells;
//   }
//
//   Color? getCellColor(int row, int col) {
//     Offset current = Offset(row.toDouble(), col.toDouble());
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
//   @override
//   void dispose() {
//     timer?.cancel();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final screenHeight = MediaQuery.of(context).size.height;
//     final cellSize = (screenHeight * 0.55 - 9 * 4) / 10;
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Level $level — Time Left: $timeLeft"),
//         backgroundColor: Colors.teal.shade600,
//       ),
//       body: Column(
//         children: [
//           const SizedBox(height: 10),
//           GestureDetector(
//             onPanStart: (details) => handleDragStart(details, cellSize),
//             onPanUpdate: (details) => handleDragUpdate(details, cellSize),
//             onPanEnd: (_) => handleDragEnd(),
//             child: SizedBox(
//               height: screenHeight * 0.55,
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 12),
//                 child: GridView.builder(
//                   physics: const NeverScrollableScrollPhysics(),
//                   itemCount: 100,
//                   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: 10,
//                     mainAxisSpacing: 4,
//                     crossAxisSpacing: 4,
//                   ),
//                   itemBuilder: (context, index) {
//                     final row = index ~/ 10;
//                     final col = index % 10;
//                     final letter = grid[row][col];
//                     final color = getCellColor(row, col);
//
//                     return Container(
//                       decoration: BoxDecoration(
//                         color: color ?? Colors.white,
//                         borderRadius: BorderRadius.circular(8),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black12,
//                             blurRadius: 3,
//                             offset: const Offset(1, 1),
//                           ),
//                         ],
//                         border: Border.all(color: Colors.grey.shade400),
//                       ),
//                       alignment: Alignment.center,
//                       child: Text(
//                         letter,
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: color != null ? Colors.white : Colors.black,
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 20),
//           const Text(
//             'Find the Words:',
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 10),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 12),
//             child: Wrap(
//               spacing: 8,
//               runSpacing: 8,
//               children: currentWords.map((word) {
//                 final found = foundWordPaths.containsKey(word);
//                 return Chip(
//                   label: Text(
//                     word,
//                     style: TextStyle(
//                       fontWeight: FontWeight.w600,
//                       decoration: found ? TextDecoration.lineThrough : TextDecoration.none,
//                       color: found ? Colors.green.shade900 : Colors.black,
//                     ),
//                   ),
//                   backgroundColor:
//                   found ? Colors.green.shade200 : Colors.grey.shade300,
//                   padding:
//                   const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                 );
//               }).toList(),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
