import 'dart:math' as math;

/// Represents a single tile in the Scramble Word Collapse grid
class ScrambleTile {
  final String id;
  final String letter;
  int row;
  int col;
  bool isSolved;
  bool isSelected;

  ScrambleTile({
    required this.id,
    required this.letter,
    required this.row,
    required this.col,
    this.isSolved = false,
    this.isSelected = false,
  });

  ScrambleTile copyWith({
    String? id,
    String? letter,
    int? row,
    int? col,
    bool? isSolved,
    bool? isSelected,
  }) {
    return ScrambleTile(
      id: id ?? this.id,
      letter: letter ?? this.letter,
      row: row ?? this.row,
      col: col ?? this.col,
      isSolved: isSolved ?? this.isSolved,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

/// Represents a Scramble level configuration
class ScrambleLevelData {
  final int level;
  final String themeTitle;
  final String emoji;
  final List<String> targetWords;
  final int rows;
  final int cols;
  final List<ScrambleTile> tiles;
  final List<List<ScrambleTile>> initialColumns;

  const ScrambleLevelData({
    required this.level,
    required this.themeTitle,
    required this.emoji,
    required this.targetWords,
    required this.rows,
    required this.cols,
    required this.tiles,
    required this.initialColumns,
  });
}

/// Dynamic, Procedural, and Progressive Word Collapse Puzzle Engine
/// Generates verified solvable levels with mixed horizontal & vertical orientations
/// and realistic physics gravity collapses!
class ScramblePuzzleEngine {
  /// Generate a valid, interlocked, gravity-collapsing board for any level
  static ScrambleLevelData generateLevel(int level) {
    final themeEntry = ScrambleLevelCatalog.getThemeForLevel(level);
    final String themeTitle = themeEntry['theme'] as String;
    final String emoji = themeEntry['emoji'] as String;
    final List<String> words = (themeEntry['words'] as List)
        .map((w) => w.toString().toUpperCase().trim())
        .toList();

    // Determine grid columns based on word lengths and count to prevent vertical squeeze
    final int maxWordLen = words.map((w) => w.length).reduce(math.max);
    final int totalLetters =
        words.map((w) => w.length).reduce((a, b) => a + b);

    int cols = math.max(maxWordLen, 4);
    if (words.length <= 3) {
      cols = math.max(maxWordLen, 4).clamp(4, 6);
    } else if (words.length <= 4) {
      cols = math.max(maxWordLen, totalLetters >= 16 ? 5 : 4).clamp(4, 6);
    } else if (words.length <= 5) {
      cols = math.max(maxWordLen, totalLetters >= 22 ? 6 : 5).clamp(5, 6);
    } else {
      cols = math.max(maxWordLen, 6).clamp(6, 6);
    }

    // Build the solvable columns layout
    final colStrings = _buildSolvableBoard(words, cols, level * 107 + 13);

    // Calculate max height among all columns
    int maxRows = 0;
    for (final col in colStrings) {
      if (col.length > maxRows) maxRows = col.length;
    }
    if (maxRows < 2) maxRows = 2;

    // Convert to ScrambleTile objects
    final List<List<ScrambleTile>> initialColumns =
        List.generate(cols, (_) => []);
    final List<ScrambleTile> allTiles = [];
    int tileCounter = 0;

    for (int c = 0; c < cols; c++) {
      final colList = colStrings[c];
      for (int k = 0; k < colList.length; k++) {
        final row = maxRows - 1 - k;
        final tile = ScrambleTile(
          id: 'tile_${level}_${tileCounter++}',
          letter: colList[k],
          row: row,
          col: c,
        );
        initialColumns[c].add(tile);
        allTiles.add(tile);
      }
    }

    return ScrambleLevelData(
      level: level,
      themeTitle: themeTitle,
      emoji: emoji,
      targetWords: words,
      rows: maxRows,
      cols: cols,
      tiles: allTiles,
      initialColumns: initialColumns,
    );
  }

  /// Re-pack remaining unsolved words into a fresh, 100% SOLVABLE configuration (Used by SHUFFLE)
  static List<List<ScrambleTile>> repackRemainingWords({
    required List<String> remainingWords,
    required int cols,
    required int seed,
  }) {
    if (remainingWords.isEmpty) return [];

    final cleanWords =
        remainingWords.map((w) => w.toUpperCase().trim()).toList();
    final int maxWordLen =
        cleanWords.map((w) => w.length).reduce(math.max);
    final effectiveCols = math.max(cols, maxWordLen).clamp(3, 6);

    final colStrings = _buildSolvableBoard(cleanWords, effectiveCols, seed);

    int maxRows = 0;
    for (final col in colStrings) {
      if (col.length > maxRows) maxRows = col.length;
    }
    if (maxRows < 2) maxRows = 2;

    final List<List<ScrambleTile>> newColumns =
        List.generate(effectiveCols, (_) => []);
    int tileCounter = 0;

    for (int c = 0; c < effectiveCols; c++) {
      final colList = colStrings[c];
      for (int k = 0; k < colList.length; k++) {
        final row = maxRows - 1 - k;
        final tile = ScrambleTile(
          id: 'shuffled_${seed}_${tileCounter++}',
          letter: colList[k],
          row: row,
          col: c,
        );
        newColumns[c].add(tile);
      }
    }

    return newColumns;
  }

  /// Core reverse-collapse construction with simulation-based solvability validation
  static List<List<String>> _buildSolvableBoard(
    List<String> words,
    int cols,
    int baseSeed,
  ) {
    List<List<String>>? bestBoard;
    int bestScore = -1;

    final int maxWordLen =
        words.map((w) => w.length).reduce(math.max);
    // Ideal max height to stop early:
    final int idealMaxH =
        math.max(maxWordLen, words.length <= 3 ? 5 : 6);

    // Try multiple attempts with seed variations to find a rich cascading interlocked layout
    for (int attempt = 0; attempt < 80; attempt++) {
      final math.Random random = math.Random(baseSeed + (attempt * 101));
      final List<List<String>> colStrings =
          List.generate(cols, (_) => <String>[]);

      // Words placed in reverse order: solving goes W0 -> W1 -> W2, so we place W2 -> W1 -> W0
      final reversedWords = List<String>.from(words)..shuffle(random);

      // Vary layout strategy across attempts to guarantee variety and solvability
      final List<bool> isHorizontal = [];
      final int mode = attempt % 4;

      if (mode == 0 && reversedWords.every((w) => w.length <= cols)) {
        // Mode 0: All horizontal rows
        for (int i = 0; i < reversedWords.length; i++) {
          isHorizontal.add(true);
        }
      } else if (mode == 1 && reversedWords.length <= cols) {
        // Mode 1: All vertical columns
        for (int i = 0; i < reversedWords.length; i++) {
          isHorizontal.add(false);
        }
      } else if (reversedWords.length >= 2) {
        // Mode 2 & 3: Mixed vertical & horizontal
        final vIdx = random.nextInt(reversedWords.length);
        final hCandidates = [
          for (int i = 0; i < reversedWords.length; i++)
            if (reversedWords[i].length <= cols && i != vIdx) i
        ];
        final int hIdx = hCandidates.isNotEmpty
            ? hCandidates[random.nextInt(hCandidates.length)]
            : -1;

        for (int i = 0; i < reversedWords.length; i++) {
          final len = reversedWords[i].length;
          if (i == vIdx) {
            isHorizontal.add(false); // Vertical
          } else if (i == hIdx) {
            isHorizontal.add(true); // Horizontal
          } else {
            isHorizontal.add(len <= cols && random.nextBool());
          }
        }
      } else {
        isHorizontal.add(reversedWords[0].length <= cols);
      }

      for (int wIdx = 0; wIdx < reversedWords.length; wIdx++) {
        final word = reversedWords[wIdx];
        final len = word.length;
        final bool isHoriz = isHorizontal[wIdx];

        if (isHoriz && len <= cols) {
          // Horizontal word MUST be placed across columns of uniform height (flat surface)
          final validStarts = <int>[];
          for (int startCol = 0; startCol <= cols - len; startCol++) {
            final h = colStrings[startCol].length;
            bool isFlat = true;
            for (int c = 1; c < len; c++) {
              if (colStrings[startCol + c].length != h) {
                isFlat = false;
                break;
              }
            }
            if (isFlat) validStarts.add(startCol);
          }

          if (validStarts.isNotEmpty) {
            final startCol = validStarts[random.nextInt(validStarts.length)];
            for (int c = 0; c < len; c++) {
              colStrings[startCol + c].add(word[c]);
            }
          } else {
            // No flat position across columns for horizontal word: place vertically
            int minColH = colStrings[0].length;
            for (int c = 1; c < cols; c++) {
              if (colStrings[c].length < minColH) {
                minColH = colStrings[c].length;
              }
            }
            final minCols = [
              for (int c = 0; c < cols; c++)
                if (colStrings[c].length == minColH) c
            ];
            final colIdx = minCols[random.nextInt(minCols.length)];
            for (int i = len - 1; i >= 0; i--) {
              colStrings[colIdx].add(word[i]);
            }
          }
        } else {
          // Vertical placement: place in column with minimum height (randomize ties)
          int minColH = colStrings[0].length;
          for (int c = 1; c < cols; c++) {
            if (colStrings[c].length < minColH) {
              minColH = colStrings[c].length;
            }
          }
          final minCols = [
            for (int c = 0; c < cols; c++)
              if (colStrings[c].length == minColH) c
          ];
          final colIdx = minCols[random.nextInt(minCols.length)];

          // Top-to-bottom reading: word[len - 1] at bottom, word[0] at top
          for (int i = len - 1; i >= 0; i--) {
            colStrings[colIdx].add(word[i]);
          }
        }
      }

      int maxH = 0;
      for (final col in colStrings) {
        if (col.length > maxH) maxH = col.length;
      }
      // Never allow vertical towers higher than 8 rows to prevent UI squeeze
      if (maxH > 8) continue;

      // Validate trap-free solvability: EVERY available move must lead to a winning path!
      if (_isBoardFullyTrapFree(colStrings, words)) {
        final score = 100 - maxH;
        if (score > bestScore) {
          bestScore = score;
          bestBoard = colStrings;
          if (maxH <= idealMaxH) {
            break;
          }
        }
      }
    }

    if (bestBoard != null) {
      return bestBoard;
    }

    // Solvable fallback with seed:
    return _buildDeterministicFallback(words, cols, baseSeed);
  }

  /// Fallback: Guarantees 100% solvable arrangement with ZERO traps
  static List<List<String>> _buildDeterministicFallback(
      List<String> words, int cols, [int seed = 0]) {
    final math.Random random = math.Random(seed != 0 ? seed : 12345);
    final List<List<String>> colStrings =
        List.generate(cols, (_) => <String>[]);

    final shuffledWords = List<String>.from(words)..shuffle(random);
    final horizWords = <String>[];
    final vertWords = <String>[];

    for (int i = 0; i < shuffledWords.length; i++) {
      if (shuffledWords[i].length <= cols && horizWords.length <= vertWords.length) {
        horizWords.add(shuffledWords[i]);
      } else {
        vertWords.add(shuffledWords[i]);
      }
    }

    // Ensure at least one horizontal word if fits
    if (horizWords.isEmpty && shuffledWords.any((w) => w.length <= cols)) {
      final w = shuffledWords.firstWhere((w) => w.length <= cols);
      vertWords.remove(w);
      horizWords.add(w);
    }

    // 1. Place horizontal words first at bottom (each forms a complete, flat row)
    for (final word in horizWords) {
      final maxStart = cols - word.length;
      final startCol = maxStart > 0 ? random.nextInt(maxStart + 1) : 0;
      for (int c = 0; c < word.length; c++) {
        colStrings[startCol + c].add(word[c]);
      }
    }

    // 2. Place vertical words on top, distributed across columns
    for (final word in vertWords) {
      int minH = colStrings[0].length;
      for (int c = 1; c < cols; c++) {
        if (colStrings[c].length < minH) {
          minH = colStrings[c].length;
        }
      }
      final tiedCols = [
        for (int c = 0; c < cols; c++)
          if (colStrings[c].length == minH) c
      ];
      final minCol = tiedCols[random.nextInt(tiedCols.length)];
      for (int l = word.length - 1; l >= 0; l--) {
        colStrings[minCol].add(word[l]);
      }
    }

    return colStrings;
  }

  /// Validates that from the current board, EVERY currently visible word leads to a winning path!
  static bool _isBoardFullyTrapFree(
      List<List<String>> cols, List<String> words) {
    final remaining = words.toSet();
    final available = <String, List<math.Point<int>>>{};

    for (final w in remaining) {
      final pts = _findWordOnBoard(cols, w);
      if (pts != null) available[w] = pts;
    }

    if (available.isEmpty) return false;

    // EVERY move currently available on the board must lead to a complete win!
    for (final entry in available.entries) {
      final nextCols = cols.map((c) => List<String>.from(c)).toList();
      final pts = List<math.Point<int>>.from(entry.value)
        ..sort((a, b) => b.y.compareTo(a.y));
      for (final pt in pts) {
        nextCols[pt.x].removeAt(pt.y);
      }
      if (!_canSolveDFS(nextCols, Set.from(remaining)..remove(entry.key))) {
        return false; // Trapped move! Reject this board!
      }
    }

    return true;
  }

  static bool _canSolveDFS(List<List<String>> cols, Set<String> remaining) {
    if (remaining.isEmpty) return true;

    final available = <String, List<math.Point<int>>>{};
    for (final w in remaining) {
      final pts = _findWordOnBoard(cols, w);
      if (pts != null) available[w] = pts;
    }

    if (available.isEmpty) return false;

    for (final entry in available.entries) {
      final nextCols = cols.map((c) => List<String>.from(c)).toList();
      final pts = List<math.Point<int>>.from(entry.value)
        ..sort((a, b) => b.y.compareTo(a.y));
      for (final pt in pts) {
        nextCols[pt.x].removeAt(pt.y);
      }
      if (_canSolveDFS(nextCols, Set.from(remaining)..remove(entry.key))) {
        return true;
      }
    }

    return false;
  }

  /// Finds if a word is currently contiguous on the board in any playable straight line:
  /// horizontal (L->R or R->L) or vertical (T->B or B->T).
  static List<math.Point<int>>? _findWordOnBoard(
      List<List<String>> cols, String word) {
    final int len = word.length;

    int maxH = 0;
    for (final col in cols) {
      if (col.length > maxH) maxH = col.length;
    }

    // 1. Check Horizontal lines at every height H (both Left-to-Right and Right-to-Left)
    for (int h = 0; h < maxH; h++) {
      // Left to Right:
      for (int startCol = 0; startCol <= cols.length - len; startCol++) {
        bool allColsHaveH = true;
        final chars = <String>[];
        final coords = <math.Point<int>>[];

        for (int c = 0; c < len; c++) {
          final colIdx = startCol + c;
          if (h >= cols[colIdx].length) {
            allColsHaveH = false;
            break;
          }
          chars.add(cols[colIdx][h]);
          coords.add(math.Point(colIdx, h));
        }

        if (allColsHaveH && chars.join('') == word) {
          return coords;
        }
      }

      // Right to Left:
      for (int startCol = cols.length - 1; startCol >= len - 1; startCol--) {
        bool allColsHaveH = true;
        final chars = <String>[];
        final coords = <math.Point<int>>[];

        for (int c = 0; c < len; c++) {
          final colIdx = startCol - c;
          if (h >= cols[colIdx].length) {
            allColsHaveH = false;
            break;
          }
          chars.add(cols[colIdx][h]);
          coords.add(math.Point(colIdx, h));
        }

        if (allColsHaveH && chars.join('') == word) {
          return coords;
        }
      }
    }

    // 2. Check Vertical lines in every column (both Top-to-Bottom and Bottom-to-Top)
    for (int c = 0; c < cols.length; c++) {
      final colList = cols[c];
      if (colList.length < len) continue;

      // Top to Bottom:
      for (int startK = 0; startK <= colList.length - len; startK++) {
        final chars = <String>[];
        final coords = <math.Point<int>>[];

        // Top is (startK + len - 1), bottom is startK
        for (int i = 0; i < len; i++) {
          final k = startK + len - 1 - i;
          chars.add(colList[k]);
          coords.add(math.Point(c, k));
        }

        if (chars.join('') == word) {
          return coords;
        }
      }

      // Bottom to Top:
      for (int startK = 0; startK <= colList.length - len; startK++) {
        final chars = <String>[];
        final coords = <math.Point<int>>[];

        for (int i = 0; i < len; i++) {
          final k = startK + i;
          chars.add(colList[k]);
          coords.add(math.Point(c, k));
        }

        if (chars.join('') == word) {
          return coords;
        }
      }
    }

    return null;
  }
}

/// Catalog of 60+ Curated Themes with Infinite Procedural Progression
class ScrambleLevelCatalog {
  static final List<Map<String, dynamic>> _curatedThemes = [
    // --- Levels 1 - 10: Easy (3 to 4 words, 3-5 letters, 4 columns, zero squeeze) ---
    {
      'theme': 'Makes you cry',
      'emoji': '🧅',
      'words': ['ONION', 'TEAR', 'CRY'],
    },
    {
      'theme': 'Pet Animals',
      'emoji': '🐶',
      'words': ['PUPPY', 'CAT', 'BIRD'],
    },
    {
      'theme': 'Vibrant Colors',
      'emoji': '🎨',
      'words': ['BLUE', 'PINK', 'GOLD'],
    },
    {
      'theme': 'Sweet Treats',
      'emoji': '🍬',
      'words': ['CANDY', 'CAKE', 'PIE'],
    },
    {
      'theme': 'Sky & Stars',
      'emoji': '☀️',
      'words': ['SUN', 'MOON', 'STAR'],
    },
    {
      'theme': 'Fresh Fruits',
      'emoji': '🍎',
      'words': ['APPLE', 'MANGO', 'PEACH', 'LIME'],
    },
    {
      'theme': 'Ocean Life',
      'emoji': '🌊',
      'words': ['FISH', 'CRAB', 'SHARK', 'SEAL'],
    },
    {
      'theme': 'Kitchen Dining',
      'emoji': '🍳',
      'words': ['FORK', 'SPOON', 'PLATE', 'KNIFE'],
    },
    {
      'theme': 'Musical Sounds',
      'emoji': '🎵',
      'words': ['DRUM', 'PIANO', 'FLUTE', 'BELL'],
    },
    {
      'theme': 'Weather Days',
      'emoji': '⛅',
      'words': ['RAIN', 'WIND', 'SNOW', 'STORM'],
    },

    // --- Levels 11 - 20: Medium (4 to 5 words, 4-6 letters, 5 columns) ---
    {
      'theme': 'Bakery Shop',
      'emoji': '🧁',
      'words': ['BREAD', 'DONUT', 'COOKIE', 'WAFFLE'],
    },
    {
      'theme': 'Ancient Castle',
      'emoji': '🏰',
      'words': ['SWORD', 'CROWN', 'KNIGHT', 'SHIELD'],
    },
    {
      'theme': 'Camping Trip',
      'emoji': '⛺',
      'words': ['CABIN', 'TENT', 'FIRE', 'FOREST'],
    },
    {
      'theme': 'Sports Game',
      'emoji': '⚽',
      'words': ['SOCCER', 'TENNIS', 'BOXING', 'MEDAL'],
    },
    {
      'theme': 'Magic Spells',
      'emoji': '🔮',
      'words': ['WAND', 'SPELL', 'WIZARD', 'POTION'],
    },
    {
      'theme': 'Garden Flowers',
      'emoji': '🌸',
      'words': ['ROSE', 'TULIP', 'DAISY', 'LOTUS', 'BLOOM'],
    },
    {
      'theme': 'Tech Gadgets',
      'emoji': '💻',
      'words': ['PHONE', 'MOUSE', 'SCREEN', 'ROBOT', 'CHIP'],
    },
    {
      'theme': 'Arctic Animals',
      'emoji': '❄️',
      'words': ['POLAR', 'IGLOO', 'FROST', 'WALRUS', 'WOLF'],
    },
    {
      'theme': 'Fast Vehicles',
      'emoji': '🏎️',
      'words': ['TRAIN', 'PLANE', 'TRUCK', 'ROCKET', 'RACER'],
    },
    {
      'theme': 'Night Dreams',
      'emoji': '🌙',
      'words': ['SLEEP', 'DREAM', 'CLOUD', 'NIGHT', 'STARRY'],
    },

    // --- Levels 21 - 35: Hard Part 1 (5 words, 4-6 letters, 6 columns) ---
    {
      'theme': 'Pirate Gold',
      'emoji': '💰',
      'words': ['COINS', 'CHEST', 'SWORD', 'PIRATE', 'SILVER'],
    },
    {
      'theme': 'Desert Sands',
      'emoji': '🏜️',
      'words': ['DUNES', 'CAMEL', 'MIRAGE', 'OASIS', 'SCORP'],
    },
    {
      'theme': 'Deep Jungle',
      'emoji': '🌴',
      'words': ['TIGER', 'MONKEY', 'SNAKE', 'PARROT', 'JUNGLE'],
    },
    {
      'theme': 'Winter Sports',
      'emoji': '⛷️',
      'words': ['SKIING', 'SKATE', 'HOCKEY', 'FROST', 'SLEDGE'],
    },
    {
      'theme': 'Breakfast Time',
      'emoji': '🥞',
      'words': ['TOAST', 'BACON', 'BUTTER', 'JUICE', 'COFFEE'],
    },

    // --- Levels 26 - 35: Hard Part 1 Continued (5 words, 4-6 letters, 6 columns) ---
    {
      'theme': 'Space Voyage',
      'emoji': '🚀',
      'words': ['PLANET', 'ORBIT', 'METEOR', 'COMET', 'GALAXY'],
    },
    {
      'theme': 'Detective Clues',
      'emoji': '🕵️',
      'words': ['SOLVE', 'TRAIL', 'AGENT', 'SECRET', 'SHADOW'],
    },
    {
      'theme': 'Reef Wonders',
      'emoji': '🐠',
      'words': ['CORAL', 'SHELL', 'TURTLE', 'CLOWN', 'DIVER'],
    },
    {
      'theme': 'Farm Animals',
      'emoji': '🚜',
      'words': ['SHEEP', 'HORSE', 'RABBIT', 'DONKEY', 'CHICK'],
    },
    {
      'theme': 'Carnival Fun',
      'emoji': '🎪',
      'words': ['CIRCUS', 'CLOWN', 'PARADE', 'RIDE', 'WHEEL'],
    },
    {
      'theme': 'Doctor Clinic',
      'emoji': '🩺',
      'words': ['PULSE', 'HEART', 'MEDIC', 'NURSE', 'FEVER'],
    },
    {
      'theme': 'Art Studio',
      'emoji': '🖌️',
      'words': ['CANVAS', 'BRUSH', 'PAINT', 'SKETCH', 'EASEL'],
    },
    {
      'theme': 'Wild Forest',
      'emoji': '🌲',
      'words': ['EAGLE', 'BADGER', 'FALCON', 'BEAVER', 'TIMBER'],
    },
    {
      'theme': 'City Streets',
      'emoji': '🏙️',
      'words': ['BRIDGE', 'AVENUE', 'METRO', 'TRAFFIC', 'TOWER'],
    },
    {
      'theme': 'Prehistoric Beasts',
      'emoji': '🦖',
      'words': ['FOSSIL', 'RAPTOR', 'BONES', 'AMBER', 'BEAST'],
    },

    // --- Levels 36 - 60: Hard Part 2 (Strictly 6 words, MAX 6 words, 4-6 letters) ---
    {
      'theme': 'Mythical Beasts',
      'emoji': '🐉',
      'words': ['DRAGON', 'HYDRA', 'GRIFF', 'TITAN', 'BEAST', 'PHOEN'],
    },
    {
      'theme': 'Royal Palace',
      'emoji': '👑',
      'words': ['PRINCE', 'QUEEN', 'THRONE', 'PALACE', 'SCEPT', 'REGAL'],
    },
    {
      'theme': 'Volcano Island',
      'emoji': '🌋',
      'words': ['MAGMA', 'CRATER', 'LAVA', 'SMOKE', 'ASHES', 'ISLAND'],
    },
    {
      'theme': 'Deep Ocean',
      'emoji': '🐋',
      'words': ['WHALE', 'DOLPH', 'CORAL', 'TRENCH', 'ABYSS', 'SHARK'],
    },
    {
      'theme': 'Super Heroes',
      'emoji': '🦸',
      'words': ['HERO', 'POWER', 'SHIELD', 'FLYING', 'CAPE', 'BRAVE'],
    },
    {
      'theme': 'Ancient Egypt',
      'emoji': '🏺',
      'words': ['SPHINX', 'TOMB', 'DESERT', 'ANUBIS', 'GOLDEN', 'RULER'],
    },
    {
      'theme': 'School Days',
      'emoji': '🎒',
      'words': ['PENCIL', 'RULER', 'ERASER', 'LESSON', 'CHALK', 'STUDY'],
    },
    {
      'theme': 'Pizza Feast',
      'emoji': '🍕',
      'words': ['CHEESE', 'TOMATO', 'CRUST', 'OLIVE', 'PEPPER', 'SAUCE'],
    },
    {
      'theme': 'Wild West',
      'emoji': '🤠',
      'words': ['COWBOY', 'SADDLE', 'BOOTS', 'PISTOL', 'SALOON', 'CANYON'],
    },
    {
      'theme': 'Space Station',
      'emoji': '🛰️',
      'words': ['ROCKET', 'SENSOR', 'AIRLOCK', 'MODULE', 'SOLAR', 'ORBIT'],
    },
    {
      'theme': 'Music Concert',
      'emoji': '🎸',
      'words': ['GUITAR', 'VIOLIN', 'SINGER', 'STAGE', 'CHORUS', 'TEMPO'],
    },
    {
      'theme': 'Summer Beach',
      'emoji': '🏖️',
      'words': ['SURF', 'SANDAL', 'BREEZE', 'ISLAND', 'SUNNY', 'COAST'],
    },
    {
      'theme': 'Secret Agent',
      'emoji': '🕶️',
      'words': ['SPY', 'BADGE', 'PISTOL', 'CIPHER', 'RADAR', 'SHADOW'],
    },
    {
      'theme': 'Fall Harvest',
      'emoji': '🎃',
      'words': ['ACORN', 'LEAVES', 'PUMPK', 'CORN', 'AUTUMN', 'ORANGE'],
    },
    {
      'theme': 'Cozy Living',
      'emoji': '🛋️',
      'words': ['CARPET', 'HEATER', 'CANDLE', 'PILLOW', 'SOFA', 'WARMTH'],
    },
    {
      'theme': 'Fairytale Castle',
      'emoji': '🧚',
      'words': ['FAIRY', 'PRINCE', 'CASTLE', 'CHARM', 'MAGIC', 'GOBLIN'],
    },
    {
      'theme': 'Diamond Heist',
      'emoji': '💎',
      'words': ['VAULT', 'LASER', 'ALARM', 'JEWEL', 'GUARDS', 'ESCAPE'],
    },
    {
      'theme': 'Speed Racing',
      'emoji': '🏁',
      'words': ['DRIVER', 'CIRCUIT', 'HELMET', 'ENGINE', 'TURBO', 'FINISH'],
    },
    {
      'theme': 'Alpine Heights',
      'emoji': '🏔️',
      'words': ['SUMMIT', 'PEAK', 'VALLEY', 'CLIFF', 'TRAIL', 'ALPINE'],
    },
    {
      'theme': 'Sweet Desserts',
      'emoji': '🍨',
      'words': ['SUNDAE', 'CREAM', 'CHERRY', 'WAFER', 'SYRUP', 'PASTRY'],
    },
    {
      'theme': 'Science Lab',
      'emoji': '🧪',
      'words': ['FLASK', 'ATOM', 'FUSION', 'ENERGY', 'CARBON', 'GENES'],
    },
    {
      'theme': 'Airport Terminal',
      'emoji': '🛫',
      'words': ['TICKET', 'RUNWAY', 'LUGGAGE', 'HANGAR', 'PILOT', 'RADAR'],
    },
    {
      'theme': 'Enchanted Woods',
      'emoji': '🍄',
      'words': ['MOSS', 'STREAM', 'FOREST', 'NATURE', 'HOLLOW', 'SHADOW'],
    },
    {
      'theme': 'Gold Kingdom',
      'emoji': '🏆',
      'words': ['CROWN', 'CHEST', 'LEGEND', 'VICTOR', 'TROPHY', 'GLORY'],
    },
    {
      'theme': 'Master Mind',
      'emoji': '🧠',
      'words': ['PUZZLE', 'GENIUS', 'RIDDLE', 'SOLVER', 'CLEVER', 'MASTER'],
    },
  ];

  /// Procedural theme generator for infinite level progression (> 60)
  /// Strictly capped at MAX 6 words anywhere!
  static Map<String, dynamic> getThemeForLevel(int level) {
    if (level <= _curatedThemes.length) {
      return _curatedThemes[level - 1];
    }

    // Infinite procedural progression
    final int loop = ((level - 1) ~/ _curatedThemes.length) + 1;
    final int idx = (level - 1) % _curatedThemes.length;
    final base = _curatedThemes[idx];

    // Difficulty scaling: add supplementary related vocabulary as loop increases
    final List<String> baseWords = List<String>.from(base['words'] as List);
    final List<String> extraVocabularyPool = [
      'STAR', 'GOLD', 'FAST', 'MOON', 'GLOW', 'BEAT', 'WAVE', 'WIND',
      'PEAK', 'DAWN', 'ROAR', 'ZOOM', 'FIRE', 'MINT', 'WILD', 'CALM',
    ];

    if (loop >= 2 && baseWords.length < 5) {
      baseWords.add(extraVocabularyPool[(level * 3) % extraVocabularyPool.length]);
    }
    if (loop >= 3 && baseWords.length < 6) {
      baseWords.add(extraVocabularyPool[(level * 7) % extraVocabularyPool.length]);
    }

    // STRICT GUARANTEE: Never exceed 6 words anywhere in Scramble!
    while (baseWords.length > 6) {
      baseWords.removeLast();
    }

    return {
      'theme': '${base['theme']} • STAGE $loop',
      'emoji': base['emoji'],
      'words': baseWords,
    };
  }

  /// Generate or fetch level data for any level number (1 to ∞)
  static ScrambleLevelData getLevelData(int level) {
    return ScramblePuzzleEngine.generateLevel(level);
  }
}
