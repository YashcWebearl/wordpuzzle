import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:word_puzzle/widget/base_url.dart';

/// Backend & SharedPreferences integration for Balloon Rescue level progression.
/// Follows unified Wordix game level architecture with gameName="Wordix" & subGame="balloon".
class BalloonLevelService {
  static const String _gameName = "Wordix";
  static const String _subGame = "balloon";
  static const String _keyCurrentLevel = 'balloon_current_level';
  static const String _keyMaxUnlockedLevel = 'balloon_max_unlocked_level';
  static const String _keyStarsPrefix = 'balloon_stars_level_';

  static final ValueNotifier<int> levelNotifier = ValueNotifier<int>(1);
  static Future<int>? _activeFetchFuture;

  /// Helper to get formatted Authorization header with Bearer token
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final authHeader = token.isNotEmpty
        ? (token.startsWith('Bearer ') ? token : 'Bearer $token')
        : '';

    return {
      'Content-Type': 'application/json',
      if (authHeader.isNotEmpty) 'Authorization': authHeader,
    };
  }

  /// Initialize and load saved level, triggers background backend fetch
  static Future<int> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLevel = prefs.getInt(_keyCurrentLevel) ?? 1;
    levelNotifier.value = savedLevel;
    // Asynchronously refresh from backend
    fetchLevel();
    return savedLevel;
  }

  /// Fetch user level progress from backend API and sync with SharedPreferences
  /// Endpoint: GET /api/gameLevel/data?gameName=Wordix&subGame=balloon
  static Future<int> fetchLevel({bool force = false}) {
    if (!force && _activeFetchFuture != null) {
      return _activeFetchFuture!;
    }
    final future = _performFetchLevel();
    _activeFetchFuture = future;
    return future;
  }

  static Future<int> _performFetchLevel() async {
    print('======================================================');
    print('🔄 [BalloonLevelService] fetchLevel() START');
    final prefs = await SharedPreferences.getInstance();
    final int localLevel = prefs.getInt(_keyMaxUnlockedLevel) ??
        prefs.getInt(_keyCurrentLevel) ??
        1;

    try {
      final headers = await _getHeaders();
      if (!headers.containsKey('Authorization')) {
        print('⚠️ [BalloonLevelService] Skipping API call: No Authorization header');
        return localLevel;
      }

      final url = Uri.parse(
          '$LURL/api/gameLevel/data?gameName=$_gameName&subGame=$_subGame');
      print('🌐 [BalloonLevelService] GET Request URL: $url');

      final response = await http.get(url, headers: headers);
      print('📡 [BalloonLevelService] Response Status: ${response.statusCode}');
      print('📦 [BalloonLevelService] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true && decoded['data'] != null) {
          final data = decoded['data'];
          final int backendLevel = (data['highestLevelUnlocked'] ??
                  data['gameLevel'] ??
                  1) as int;

          // Parse completedLevels array to sync stars
          if (data['completedLevels'] is List) {
            for (final item in data['completedLevels']) {
              if (item is Map) {
                final lvlNum = (item['level'] as num?)?.toInt() ?? 0;
                final starsEarned = (item['stars'] as num?)?.toInt() ?? 0;
                if (lvlNum > 0) {
                  final oldStars = prefs.getInt('$_keyStarsPrefix$lvlNum') ?? 0;
                  if (starsEarned > oldStars) {
                    await prefs.setInt('$_keyStarsPrefix$lvlNum', starsEarned);
                  }
                }
              }
            }
          }

          final resolvedLevel = math.max(localLevel, backendLevel);
          await prefs.setInt(_keyMaxUnlockedLevel, resolvedLevel);
          await prefs.setInt(_keyCurrentLevel, resolvedLevel);
          levelNotifier.value = resolvedLevel;
          print('✅ [BalloonLevelService] Synced Balloon Level: $resolvedLevel');
          return resolvedLevel;
        }
      }
    } catch (e) {
      print('❌ [BalloonLevelService] fetchLevel error: $e');
    } finally {
      _activeFetchFuture = null;
    }
    return localLevel;
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

  /// Save completion of a level and sync with backend
  static Future<void> completeLevel(
    int level, {
    int stars = 3,
    int score = 350,
    int moves = 0,
  }) async {
    print('======================================================');
    print('🏆 [BalloonLevelService] completeLevel() START');
    print('🎯 Completed Level: $level | Stars: $stars | Score: $score | Moves: $moves');

    final prefs = await SharedPreferences.getInstance();

    // 1. Save stars if better than before
    final oldStars = prefs.getInt('$_keyStarsPrefix$level') ?? 0;
    if (stars > oldStars) {
      await prefs.setInt('$_keyStarsPrefix$level', stars);
    }

    // 2. Unlock next level
    final currentMax = prefs.getInt(_keyMaxUnlockedLevel) ?? 1;
    final nextLevel = math.max(currentMax, level + 1);
    await prefs.setInt(_keyMaxUnlockedLevel, nextLevel);
    await prefs.setInt(_keyCurrentLevel, nextLevel);
    levelNotifier.value = nextLevel;

    // 3. Call backend completeLevel API
    try {
      final headers = await _getHeaders();
      if (headers.containsKey('Authorization')) {
        final completeUrl = Uri.parse('$LURL/api/gameLevel/completeLevel');
        final requestBody = jsonEncode({
          "gameName": _gameName,
          "subGame": _subGame,
          "level": level,
          "stars": stars,
          "score": score,
          "moves": moves,
        });

        print('🌐 [BalloonLevelService] POST completeLevel URL: $completeUrl');
        print('📤 [BalloonLevelService] Request Payload: $requestBody');

        final response = await http
            .post(
              completeUrl,
              headers: headers,
              body: requestBody,
            )
            .timeout(const Duration(seconds: 8));

        print('📡 [BalloonLevelService] completeLevel Response: ${response.statusCode} | ${response.body}');

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (decoded['success'] == true && decoded['data'] != null) {
            final data = decoded['data'];
            final int backendUnlocked = (data['highestLevelUnlocked'] ??
                    data['nextUnlockedLevel'] ??
                    nextLevel) as int;
            final finalLevel = math.max(nextLevel, backendUnlocked);
            await prefs.setInt(_keyMaxUnlockedLevel, finalLevel);
            await prefs.setInt(_keyCurrentLevel, finalLevel);
            levelNotifier.value = finalLevel;
            print('🎉 [BalloonLevelService] completeLevel SUCCESS! Final Level: $finalLevel');
          }
        }

        // Secondary update call for dual compatibility
        final updateUrl = Uri.parse('$LURL/api/gameLevel/update');
        final updateBody = jsonEncode({
          "gameName": _gameName,
          "subGame": _subGame,
          "gameLevel": nextLevel,
        });
        await http.post(
          updateUrl,
          headers: headers,
          body: updateBody,
        );
      }
    } catch (e) {
      print('❌ [BalloonLevelService] completeLevel backend sync error: $e');
    }
  }

  /// Set current active level
  static Future<void> setCurrentLevel(int level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCurrentLevel, level);
    levelNotifier.value = level;
  }
}

