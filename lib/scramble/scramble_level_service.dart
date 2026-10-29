import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScrambleLevelService {
  static final ValueNotifier<int> levelNotifier = ValueNotifier<int>(1);
  static const String _keyCurrentLevel = 'scramble_current_level';
  static const String _keyMaxUnlockedLevel = 'scramble_max_unlocked_level';
  static const String _keyStarsPrefix = 'scramble_stars_level_';

  /// Initialize and load saved level
  static Future<int> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLevel = prefs.getInt(_keyCurrentLevel) ?? 1;
    levelNotifier.value = savedLevel;
    return savedLevel;
  }

  /// Get max unlocked level
  static Future<int> getMaxUnlockedLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyMaxUnlockedLevel) ?? 1;
  }

  /// Get stars earned for a specific level (0 to 3)
  static Future<int> getStarsForLevel(int level) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_keyStarsPrefix$level') ?? 0;
  }

  /// Save completion of a level
  static Future<void> completeLevel(int level, {int stars = 3}) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save stars if better than before
    final oldStars = prefs.getInt('$_keyStarsPrefix$level') ?? 0;
    if (stars > oldStars) {
      await prefs.setInt('$_keyStarsPrefix$level', stars);
    }

    // Unlock next level
    final currentMax = prefs.getInt(_keyMaxUnlockedLevel) ?? 1;
    if (level >= currentMax) {
      await prefs.setInt(_keyMaxUnlockedLevel, level + 1);
    }

    // Advance current level pointer
    final nextLevel = level + 1;
    await prefs.setInt(_keyCurrentLevel, nextLevel);
    levelNotifier.value = nextLevel;
  }

  /// Set current active level
  static Future<void> setCurrentLevel(int level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCurrentLevel, level);
    levelNotifier.value = level;
  }
}
