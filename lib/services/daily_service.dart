import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../widget/base_url.dart'; // for LURL
import '../widget/top_task_snackbar.dart';

/// Unified Daily Streak Rewards, Tasks & Lucky Spin Hub Service for Word Puzzle
/// Compliant with WORD_PUZZLE_DAILY_SYSTEM_API_GUIDE.md
/// Game Name: 'Wordix'
class DailyService {
  static final DailyService _instance = DailyService._internal();
  factory DailyService() => _instance;
  DailyService._internal();

  static const List<int> defaultRewardsConfig = [
    100, // Day 1
    150, // Day 2
    200, // Day 3
    300, // Day 4
    450, // Day 5
    600, // Day 6
    1200, // Day 7 (MEGA CHEST)
  ];

  static const List<Map<String, dynamic>> defaultDailyTasks = [
    {
      'taskKey': 'play_wordix',
      'title': 'Word Finder',
      'description': 'Play 3 levels in Wordix Word Search',
      'target': 3,
      'total': 3,
      'coins': 100,
      'gameScope': 'wordix',
    },
    {
      'taskKey': 'win_wordix',
      'title': 'Grid Conqueror',
      'description': 'Complete 2 Wordix Word Search levels',
      'target': 2,
      'total': 2,
      'coins': 150,
      'gameScope': 'wordix',
    },
    {
      'taskKey': 'play_crossword',
      'title': 'Wheel Weaver',
      'description': 'Play 3 Crossword Word Connect levels',
      'target': 3,
      'total': 3,
      'coins': 100,
      'gameScope': 'crossword',
    },
    {
      'taskKey': 'win_crossword',
      'title': 'Crossword Maestro',
      'description': 'Solve 2 Crossword levels',
      'target': 2,
      'total': 2,
      'coins': 150,
      'gameScope': 'crossword',
    },
    {
      'taskKey': 'word_master_duo',
      'title': 'Dual Scholar',
      'description': 'Play both Wordix & Crossword today',
      'target': 2,
      'total': 2,
      'coins': 200,
      'gameScope': 'all',
    },
    {
      'taskKey': 'use_hint',
      'title': 'Clue Seeker',
      'description': 'Use 2 hints or shuffles in any game',
      'target': 2,
      'total': 2,
      'coins': 80,
      'gameScope': 'all',
    },
    {
      'taskKey': 'spin_wheel_task',
      'title': 'Fortune Seeker',
      'description': 'Spin the Lucky Wheel 1 time',
      'target': 1,
      'total': 1,
      'coins': 50,
      'gameScope': 'all',
    },
    {
      'taskKey': 'watch_ad',
      'title': 'Bonus Hunter',
      'description': 'Watch 2 rewarded ads',
      'target': 2,
      'total': 2,
      'coins': 80,
      'gameScope': 'all',
    },
  ];

  String _getTodayString() {
    final now = DateTime.now();
    return "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      if (token.isNotEmpty)
        'Authorization': token.startsWith('Bearer ') ? token : 'Bearer $token',
    };
  }

  /// 1. GET /api/daily/status
  Future<Map<String, dynamic>> getDailyStatus({String gameName = 'Wordix'}) async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = _getTodayString();

    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$LURL/api/daily/status?gameName=$gameName');
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic> && decoded['success'] == true) {
          final remoteTasks = decoded['dailyTasks'] as List<dynamic>?;
          if (remoteTasks != null) {
            for (var t in remoteTasks) {
              if (t is Map) {
                final key = t['taskKey']?.toString() ?? '';
                final remoteProg = (t['progress'] as num?)?.toInt() ?? 0;
                final localProg = prefs.getInt('task_progress_$key') ?? 0;
                final effectiveProg =
                    localProg > remoteProg ? localProg : remoteProg;
                t['progress'] = effectiveProg;

                final total = (t['total'] as num?)?.toInt() ?? 1;
                final isClaimed = (t['isClaimed'] == true) ||
                    (prefs.getBool('task_claimed_$key') ?? false);
                t['isCompleted'] = effectiveProg >= total;
                t['isClaimed'] = isClaimed;
              }
            }
          }
          await _cacheBackendStatus(decoded);
          return decoded;
        }
      }
    } catch (e) {
      debugPrint('DailyService: Backend status error: $e. Falling back to local cache.');
    }

    return await _getLocalDailyStatus(todayStr);
  }

  /// 2. POST /api/daily/claim-streak
  Future<Map<String, dynamic>> claimStreak({String gameName = 'Wordix'}) async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = _getTodayString();

    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$LURL/api/daily/claim-streak');
      final body = json.encode({'gameName': gameName});

      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic> && decoded['success'] == true) {
          final data = decoded['data'] ?? {};
          final int claimedDay = (data['claimedDay'] as int?) ?? 1;
          final coinsAwarded = (data['coinsAwarded'] as int?) ??
              defaultRewardsConfig[(claimedDay - 1).clamp(0, 6)];

          final currentCoins = prefs.getInt('user_coins') ?? 0;
          await prefs.setInt('user_coins', currentCoins + coinsAwarded);
          await prefs.setString('daily_streak_claimed_date', todayStr);
          await prefs.setInt('daily_streak_current_day',
              claimedDay >= 7 ? 1 : claimedDay + 1);

          return decoded;
        }
      } else {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic> && decoded['message'] != null) {
          return {
            'success': false,
            'message': decoded['message'],
          };
        }
      }
    } catch (e) {
      debugPrint('DailyService: claimStreak error: $e. Using local fallback.');
    }

    // Local Fallback
    final lastClaim = prefs.getString('daily_streak_claimed_date');
    if (lastClaim == todayStr) {
      return {
        'success': false,
        'message': 'Already claimed today! Come back tomorrow.',
      };
    }

    int currentDay = prefs.getInt('daily_streak_current_day') ?? 1;
    final rewardCoins = defaultRewardsConfig[(currentDay - 1).clamp(0, 6)];
    final currentCoins = prefs.getInt('user_coins') ?? 0;
    await prefs.setInt('user_coins', currentCoins + rewardCoins);
    await prefs.setString('daily_streak_claimed_date', todayStr);
    await prefs.setInt('daily_streak_current_day', currentDay >= 7 ? 1 : currentDay + 1);

    return {
      'success': true,
      'message': '🎉 Day $currentDay Reward Claimed Successfully!',
      'data': {
        'claimedDay': currentDay,
        'coinsAwarded': rewardCoins,
        'nextDay': currentDay >= 7 ? 1 : currentDay + 1,
      },
    };
  }

  /// 3. POST /api/daily/task-progress
  Future<Map<String, dynamic>?> updateTaskProgress({
    required String taskKey,
    int increment = 1,
    String gameName = 'Wordix',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = _getTodayString();

    // 1. Update locally first
    int localProg = prefs.getInt('task_progress_$taskKey') ?? 0;
    localProg += increment;
    await prefs.setInt('task_progress_$taskKey', localProg);

    Map<String, dynamic>? backendResult;
    bool isCompleted = false;
    int coinsReward = 100;
    String taskTitle = '';

    // 2. Sync to Backend
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$LURL/api/daily/task-progress');
      final body = json.encode({
        'taskKey': taskKey,
        'increment': increment,
        'gameName': gameName,
      });

      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        backendResult = json.decode(response.body);
        if (backendResult != null && backendResult['data'] != null) {
          final data = backendResult['data'] as Map<String, dynamic>;
          if (data['completed'] == true) {
            isCompleted = true;
            coinsReward = (data['reward'] as int?) ?? 100;
          }
        }
      }
    } catch (e) {
      debugPrint('DailyService: updateTaskProgress backend error: $e');
    }

    // 3. Fallback / Catalog check for title and target
    final match = defaultDailyTasks.firstWhere(
      (t) => t['taskKey'] == taskKey,
      orElse: () => <String, dynamic>{},
    );
    if (match.isNotEmpty) {
      taskTitle = match['title']?.toString() ?? '';
      coinsReward = (match['coins'] as int?) ?? coinsReward;
      final target = (match['target'] as int?) ?? 2;
      if (localProg >= target) {
        isCompleted = true;
      }
    }

    // 4. Trigger TOP SNACKBAR on any screen if just completed and not notified yet today
    if (isCompleted) {
      final notifiedKey = 'task_top_notified_${todayStr}_$taskKey';
      final alreadyNotified = prefs.getBool(notifiedKey) ?? false;
      if (!alreadyNotified) {
        await prefs.setBool(notifiedKey, true);
        TopTaskSnackBar.showTaskCompleted(
          taskKey: taskKey,
          title: taskTitle.isNotEmpty ? taskTitle : null,
          coins: coinsReward,
        );
      }
    }

    // 5. Check Dual Game Master (word_master_duo)
    if (taskKey == 'play_wordix' || taskKey == 'play_crossword') {
      final wordixPlayed = (prefs.getInt('task_progress_play_wordix') ?? 0) > 0;
      final crossPlayed = (prefs.getInt('task_progress_play_crossword') ?? 0) > 0;
      if (wordixPlayed && crossPlayed) {
        final duoNotifiedKey = 'task_top_notified_${todayStr}_word_master_duo';
        final duoAlreadyNotified = prefs.getBool(duoNotifiedKey) ?? false;
        if (!duoAlreadyNotified) {
          await prefs.setBool(duoNotifiedKey, true);
          TopTaskSnackBar.showTaskCompleted(
            taskKey: 'word_master_duo',
            title: 'Dual Scholar',
            coins: 200,
          );
        }
      }
    }

    return backendResult;
  }

  /// 4. POST /api/daily/claim-task
  Future<Map<String, dynamic>> claimTask({
    required String taskKey,
    int coins = 100,
    String gameName = 'Wordix',
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Mark claimed locally
    await prefs.setBool('task_claimed_$taskKey', true);

    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$LURL/api/daily/claim-task');
      final body = json.encode({
        'taskKey': taskKey,
        'gameName': gameName,
      });

      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint('DailyService: claimTask backend error: $e');
    }

    // Local Fallback
    final currentCoins = prefs.getInt('user_coins') ?? 0;
    await prefs.setInt('user_coins', currentCoins + coins);

    return {
      'success': true,
      'message': '🎉 Task reward claimed!',
      'data': {
        'taskKey': taskKey,
        'coinsAwarded': coins,
        'newWalletBalance': currentCoins + coins,
        'isClaimed': true,
      },
    };
  }

  /// 5. POST /api/daily/spin-wheel
  Future<Map<String, dynamic>> spinWheel({
    required String spinType, // 'free' | 'ad' | 'coins'
    String gameName = 'Wordix',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = _getTodayString();

    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$LURL/api/daily/spin-wheel');
      final body = json.encode({
        'spinType': spinType,
        'gameName': gameName,
      });

      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic> && decoded['success'] == true) {
          if (spinType == 'free') {
            await prefs.setString('daily_last_spin_date', todayStr);
          }
          return decoded;
        }
      }
    } catch (e) {
      debugPrint('DailyService: spinWheel backend error: $e');
    }

    if (spinType == 'free') {
      await prefs.setString('daily_last_spin_date', todayStr);
    }

    return {
      'success': false,
      'message': 'Failed to execute spin on server.',
    };
  }

  /// 6. GET /api/daily/spin-status
  Future<Map<String, dynamic>?> getSpinStatus() async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$LURL/api/daily/spin-status');
      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint('DailyService: getSpinStatus error: $e');
    }
    return null;
  }

  Future<void> _cacheBackendStatus(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final streak = data['streak'] as Map<String, dynamic>?;
    if (streak != null) {
      final currentDay = (streak['currentDay'] as num?)?.toInt() ?? 1;
      final isClaimed = streak['isTodayClaimed'] == true;
      await prefs.setInt('daily_streak_current_day', currentDay);
      if (isClaimed) {
        await prefs.setString('daily_streak_claimed_date', _getTodayString());
      } else {
        final lastClaim = prefs.getString('daily_streak_claimed_date');
        if (lastClaim == _getTodayString()) {
          await prefs.remove('daily_streak_claimed_date');
        }
      }
    }
  }

  Future<Map<String, dynamic>> getLocalCachedStatus() async {
    return _getLocalDailyStatus(_getTodayString());
  }

  Future<Map<String, dynamic>> _getLocalDailyStatus(String todayStr) async {
    final prefs = await SharedPreferences.getInstance();
    final currentDay = prefs.getInt('daily_streak_current_day') ?? 1;
    final isClaimed = prefs.getString('daily_streak_claimed_date') == todayStr;
    final hasFreeSpin = prefs.getString('spin_last_free_date') != todayStr;
    final adSpins = prefs.getInt('spin_ad_spins_today_$todayStr') ?? 3;

    return {
      'success': true,
      'date': todayStr,
      'gameName': 'Wordix',
      'streak': {
        'currentDay': currentDay,
        'currentStreak': currentDay,
        'isTodayClaimed': isClaimed,
        'canClaim': !isClaimed,
        'cycle': 1,
        'totalDaysClaimed': currentDay - (isClaimed ? 0 : 1),
      },
      'rewardsCatalog': List.generate(7, (index) {
        final dayNum = index + 1;
        String status = 'locked';
        if (dayNum < currentDay || (dayNum == currentDay && isClaimed)) {
          status = 'claimed';
        } else if (dayNum == currentDay && !isClaimed) {
          status = 'available';
        }
        return {
          'day': dayNum,
          'title': 'Day $dayNum',
          'coins': defaultRewardsConfig[index],
          'status': status,
        };
      }),
      'dailyTasks': defaultDailyTasks.map((t) {
        final map = Map<String, dynamic>.from(t);
        final key = map['taskKey']?.toString() ?? '';
        final localProg = prefs.getInt('task_progress_$key') ?? 0;
        final target = (map['target'] as num?)?.toInt() ?? 1;
        final isTaskClaimed = prefs.getBool('task_claimed_$key') ?? false;
        map['progress'] = localProg;
        map['isCompleted'] = localProg >= target;
        map['isClaimed'] = isTaskClaimed;
        return map;
      }).toList(),
      'spin': {
        'hasFreeSpin': hasFreeSpin,
        'freeSpinsRemaining': hasFreeSpin ? 1 : 0,
        'adSpinsRemaining': adSpins,
        'coinSpinCost': 100,
      },
    };
  }
}
