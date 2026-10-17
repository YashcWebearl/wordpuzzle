import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word_puzzle/widget/base_url.dart';

/// Backend & SharedPreferences integration for Wordix Crossword level progression.
/// Handles fetching progress, completing levels, and offline fallback with comprehensive logging.
class CrosswordLevelService {
  static const String _gameName = "Wordix";
  static const String _subGame = "crossword";
  static const String _prefKey = "crossword_level";

  /// Real-time notifier for crossword level updates across screens
  static final ValueNotifier<int> levelNotifier = ValueNotifier<int>(1);

  /// In-flight fetch request deduplication
  static Future<int>? _activeFetchFuture;

  /// Helper to get formatted Authorization header with Bearer token
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final authHeader = token.isNotEmpty
        ? (token.startsWith('Bearer ') ? token : 'Bearer $token')
        : '';

    print('🔑 [CrosswordLevelService] Token present: ${token.isNotEmpty}');
    if (token.isNotEmpty) {
      final preview = token.length > 20 ? '${token.substring(0, 20)}...' : token;
      print('🔑 [CrosswordLevelService] Token Preview: $preview');
    } else {
      print('⚠️ [CrosswordLevelService] No auth_token found in SharedPreferences!');
    }

    return {
      'Content-Type': 'application/json',
      if (authHeader.isNotEmpty) 'Authorization': authHeader,
    };
  }

  /// Get current level from SharedPreferences (instant synchronous/local access)
  static Future<int> getLocalLevel() async {
    final prefs = await SharedPreferences.getInstance();
    final lvl = prefs.getInt(_prefKey) ?? 1;
    if (levelNotifier.value != lvl) {
      levelNotifier.value = lvl;
    }
    print('📂 [CrosswordLevelService] getLocalLevel(): $lvl');
    return lvl;
  }

  /// Ensure latest level is loaded, awaiting any in-flight backend fetch if present
  static Future<int> ensureLatestLevel({Duration timeout = const Duration(seconds: 3)}) async {
    if (_activeFetchFuture != null) {
      try {
        print('⏳ [CrosswordLevelService] ensureLatestLevel: awaiting active backend fetch...');
        return await _activeFetchFuture!.timeout(timeout);
      } catch (e) {
        print('⚠️ [CrosswordLevelService] ensureLatestLevel timeout/error: $e');
      }
    }
    return await getLocalLevel();
  }

  /// Fetch user level progress from backend API and sync with SharedPreferences
  /// Endpoint: GET /api/gameLevel/data?gameName=Wordix&subGame=crossword
  static Future<int> fetchLevel({bool force = false}) {
    if (!force && _activeFetchFuture != null) {
      print('🔄 [CrosswordLevelService] Reusing active fetchLevel() request');
      return _activeFetchFuture!;
    }

    final future = _performFetchLevel();
    _activeFetchFuture = future;
    return future;
  }

  static Future<int> _performFetchLevel() async {
    print('======================================================');
    print('🔄 [CrosswordLevelService] fetchLevel() START');
    final prefs = await SharedPreferences.getInstance();
    final int localLevel = prefs.getInt(_prefKey) ?? 1;
    if (levelNotifier.value != localLevel) {
      levelNotifier.value = localLevel;
    }
    print('📂 [CrosswordLevelService] Local SharedPreferences Level: $localLevel');

    try {
      final headers = await _getHeaders();
      if (!headers.containsKey('Authorization')) {
        print('⚠️ [CrosswordLevelService] Skipping API call: No Authorization header');
        print('======================================================');
        return localLevel;
      }

      final url = Uri.parse(
          '$LURL/api/gameLevel/data?gameName=$_gameName&subGame=$_subGame');
      print('🌐 [CrosswordLevelService] GET Request URL: $url');

      final response = await http.get(url, headers: headers).timeout(
            const Duration(seconds: 8),
          );

      print('📡 [CrosswordLevelService] Response Status: ${response.statusCode}');
      print('📦 [CrosswordLevelService] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true && decoded['data'] != null) {
          final data = decoded['data'];
          final int backendLevel = (data['highestLevelUnlocked'] ??
                  data['gameLevel'] ??
                  1) as int;
          print('🎯 [CrosswordLevelService] Backend level: $backendLevel (highestUnlocked)');

          // Never decrease level (local might have offline completed progress)
          final resolvedLevel = math.max(localLevel, backendLevel);
          await prefs.setInt(_prefKey, resolvedLevel);
          levelNotifier.value = resolvedLevel;
          print('✅ [CrosswordLevelService] Saved to SharedPreferences: $resolvedLevel');
          print('======================================================');
          return resolvedLevel;
        } else {
          print('⚠️ [CrosswordLevelService] Unexpected data format in response');
        }
      } else {
        print('❌ [CrosswordLevelService] API returned non-200 status: ${response.statusCode}');
      }
    } catch (e, stack) {
      print('❌ [CrosswordLevelService] fetchLevel error (fallback to local $localLevel): $e');
      print('Stacktrace: $stack');
    } finally {
      _activeFetchFuture = null;
    }

    print('======================================================');
    return localLevel;
  }

  /// Complete a level and unlock the next level
  /// 1. Updates SharedPreferences immediately (guaranteed offline progression)
  /// 2. Calls POST /api/gameLevel/completeLevel to record completion & advance highest unlocked
  /// 3. Secondary POST /api/gameLevel/update for dual compatibility
  static Future<int> completeLevel({
    required int level,
    int stars = 3,
    int score = 350,
    int moves = 0,
  }) async {
    print('======================================================');
    print('🏆 [CrosswordLevelService] completeLevel() START');
    print('🎯 Completed Level: $level | Stars: $stars | Score: $score | Moves: $moves');

    final prefs = await SharedPreferences.getInstance();
    final int currentStored = prefs.getInt(_prefKey) ?? 1;
    final int nextLevel = math.max(currentStored, level + 1);

    // 1. Immediately store in SharedPreferences
    await prefs.setInt(_prefKey, nextLevel);
    levelNotifier.value = nextLevel;
    print('💾 [CrosswordLevelService] Immediate SharedPreferences update -> Level $nextLevel');

    // 2. Call backend completeLevel API in background
    try {
      final headers = await _getHeaders();
      if (headers.containsKey('Authorization')) {
        // Complete Level API
        final completeUrl = Uri.parse('$LURL/api/gameLevel/completeLevel');
        final requestBody = jsonEncode({
          "gameName": _gameName,
          "subGame": _subGame,
          "level": level,
          "stars": stars,
          "score": score,
          "moves": moves,
        });

        print('🌐 [CrosswordLevelService] POST completeLevel URL: $completeUrl');
        print('📤 [CrosswordLevelService] Request Payload: $requestBody');

        final response = await http
            .post(
              completeUrl,
              headers: headers,
              body: requestBody,
            )
            .timeout(const Duration(seconds: 8));

        print('📡 [CrosswordLevelService] completeLevel Response Status: ${response.statusCode}');
        print('📦 [CrosswordLevelService] completeLevel Response Body: ${response.body}');

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (decoded['success'] == true && decoded['data'] != null) {
            final data = decoded['data'];
            final int backendUnlocked = (data['highestLevelUnlocked'] ??
                    data['nextUnlockedLevel'] ??
                    nextLevel) as int;
            final finalLevel = math.max(nextLevel, backendUnlocked);
            await prefs.setInt(_prefKey, finalLevel);
            levelNotifier.value = finalLevel;
            print('🎉 [CrosswordLevelService] completeLevel SUCCESS! Final Level in SharedPreferences: $finalLevel');
            print('======================================================');
            return finalLevel;
          }
        }

        // Secondary update call
        final updateUrl = Uri.parse('$LURL/api/gameLevel/update');
        final updateBody = jsonEncode({
          "gameName": _gameName,
          "subGame": _subGame,
          "gameLevel": nextLevel,
        });
        print('🔄 [CrosswordLevelService] Calling Secondary update URL: $updateUrl');
        print('📤 [CrosswordLevelService] Secondary Update Payload: $updateBody');

        final updateResponse = await http
            .post(
              updateUrl,
              headers: headers,
              body: updateBody,
            )
            .timeout(const Duration(seconds: 6));

        print('📡 [CrosswordLevelService] Secondary Update Response: ${updateResponse.statusCode} | body: ${updateResponse.body}');
      } else {
        print('⚠️ [CrosswordLevelService] No Authorization header, saved locally only.');
      }
    } catch (e, stack) {
      print('❌ [CrosswordLevelService] completeLevel backend sync error: $e');
      print('Stacktrace: $stack');
    }

    print('======================================================');
    return nextLevel;
  }

  /// Reset level back to 1 (for testing & QA)
  static Future<void> resetLevel() async {
    print('======================================================');
    print('⚠️ [CrosswordLevelService] resetLevel() START');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKey, 1);
    levelNotifier.value = 1;
    print('💾 [CrosswordLevelService] Reset SharedPreferences level to: 1');

    try {
      final headers = await _getHeaders();
      if (headers.containsKey('Authorization')) {
        final url = Uri.parse('$LURL/api/gameLevel/reset');
        print('🌐 [CrosswordLevelService] POST reset URL: $url');
        final response = await http.post(
          url,
          headers: headers,
          body: jsonEncode({
            "gameName": _gameName,
            "subGame": _subGame,
          }),
        );
        print('📡 [CrosswordLevelService] reset Response: ${response.statusCode} | body: ${response.body}');
      }
    } catch (e) {
      print('❌ [CrosswordLevelService] reset error: $e');
    }
    print('======================================================');
  }
}
