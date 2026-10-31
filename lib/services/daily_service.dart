import 'dart:convert';
import 'dart:math' as math;
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
      'taskKey': 'play_scramble',
      'title': 'Letter Unscrambler',
      'description': 'Play 3 Word Scramble levels',
      'target': 3,
      'total': 3,
      'coins': 100,
      'gameScope': 'scramble',
    },
    {
      'taskKey': 'win_scramble',
      'title': 'Master Speller',
      'description': 'Complete 2 Word Scramble levels',
      'target': 2,
      'total': 2,
      'coins': 150,
      'gameScope': 'scramble',
    },
    {
      'taskKey': 'play_balloon',
      'title': 'Balloon Savior',
      'description': 'Play 3 Balloon Rescue levels',
      'target': 3,
      'total': 3,
      'coins': 100,
      'gameScope': 'balloon',
    },
    {
      'taskKey': 'win_balloon',
      'title': 'Sky Guardian',
      'description': 'Complete 2 Balloon Rescue levels',
      'target': 2,
      'total': 2,
      'coins': 150,
      'gameScope': 'balloon',
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

  Future<String> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('user_id') ?? prefs.getString('email') ?? '';
    if (uid.isNotEmpty) return uid.trim().toLowerCase();
    final token = prefs.getString('auth_token') ?? '';
    if (token.isNotEmpty) {
      return token.length > 20 ? token.substring(token.length - 20) : token;
    }
    return 'default_user';
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
  Future<Map<String, dynamic>> getDailyStatus(
      {String gameName = 'Wordix'}) async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = _getTodayString();
    final userId = await _getUserId();

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
            // First pass: gather actual Wordix & Crossword activity
            int wordixPlayedCount = (prefs.getInt(
                        'task_progress_${userId}_${todayStr}_play_wordix') ??
                    0) +
                (prefs.getInt(
                        'task_progress_${userId}_${todayStr}_win_wordix') ??
                    0);
            int crosswordPlayedCount = (prefs.getInt(
                        'task_progress_${userId}_${todayStr}_play_crossword') ??
                    0) +
                (prefs.getInt(
                        'task_progress_${userId}_${todayStr}_win_crossword') ??
                    0);

            for (var t in remoteTasks) {
              if (t is Map) {
                final key = t['taskKey']?.toString() ?? '';
                final remoteProg = (t['progress'] as num?)?.toInt() ?? 0;
                if (key == 'play_wordix' || key == 'win_wordix') {
                  if (remoteProg > wordixPlayedCount)
                    wordixPlayedCount = remoteProg;
                } else if (key == 'play_crossword' || key == 'win_crossword') {
                  if (remoteProg > crosswordPlayedCount)
                    crosswordPlayedCount = remoteProg;
                }
              }
            }

            final bool hasWordix = wordixPlayedCount > 0;
            final bool hasCross = crosswordPlayedCount > 0;
            final int trueDuoProg = (hasWordix ? 1 : 0) + (hasCross ? 1 : 0);
            final bool trueDuoCompleted = trueDuoProg >= 2;

            for (var t in remoteTasks) {
              if (t is Map) {
                final key = t['taskKey']?.toString() ?? '';
                int remoteProg = (t['progress'] as num?)?.toInt() ?? 0;
                final total = (t['total'] as num?)?.toInt() ?? 1;
                final isClaimed = t['isClaimed'] == true;
                bool isCompleted =
                    (t['isCompleted'] == true) || (remoteProg >= total);

                // Strictly enforce Dual Scholar (word_master_duo) rule:
                // Playing Wordix (regardless of how many levels) counts as 1.
                // Playing Crossword (regardless of how many levels) counts as 1.
                // Both must be played for progress to reach 2/2 and complete.
                if (key == 'word_master_duo') {
                  if (!isClaimed) {
                    remoteProg = trueDuoProg;
                    isCompleted = trueDuoCompleted;
                  } else {
                    remoteProg = 2;
                    isCompleted = true;
                  }
                }

                t['progress'] = remoteProg;
                t['total'] = total;
                t['isCompleted'] = isCompleted;
                t['isClaimed'] = isClaimed;

                // Sync to user-and-day scoped local cache
                await prefs.setInt(
                    'task_progress_${userId}_${todayStr}_$key', remoteProg);
                await prefs.setBool(
                    'task_claimed_${userId}_${todayStr}_$key', isClaimed);

                // If already completed or already claimed on backend, mark as notified so snackbar NEVER pops up again
                if (isCompleted || isClaimed) {
                  await prefs.setBool(
                      'task_top_notified_${userId}_${todayStr}_$key', true);
                  TopTaskSnackBar.markNotified(key, todayStr);
                } else if (key == 'word_master_duo') {
                  // Not completed yet, ensure flag is cleared so notification can fire when actually completed
                  await prefs.setBool(
                      'task_top_notified_${userId}_${todayStr}_$key', false);
                }
              }
            }
          }
          await _cacheBackendStatus(decoded,
              userId: userId, todayStr: todayStr);
          return decoded;
        }
      }
    } catch (e) {
      debugPrint(
          'DailyService: Backend status error: $e. Falling back to local cache.');
    }

    return await _getLocalDailyStatus(todayStr, userId: userId);
  }

  /// 2. POST /api/daily/claim-streak
  Future<Map<String, dynamic>> claimStreak({String gameName = 'Wordix'}) async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = _getTodayString();
    final userId = await _getUserId();

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

          final serverWallet = (data['newWalletBalance'] as int?);
          final updatedCoins = serverWallet ??
              ((prefs.getInt('user_coins_$userId') ??
                      prefs.getInt('user_coins') ??
                      0) +
                  coinsAwarded);
          await prefs.setInt('user_coins_$userId', updatedCoins);
          await prefs.setInt('user_coins', updatedCoins);
          await prefs.setString('daily_streak_claimed_date_$userId', todayStr);
          await prefs.setInt('daily_streak_current_day_$userId',
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
    final lastClaim = prefs.getString('daily_streak_claimed_date_$userId');
    if (lastClaim == todayStr) {
      return {
        'success': false,
        'message': 'Already claimed today! Come back tomorrow.',
      };
    }

    int currentDay = prefs.getInt('daily_streak_current_day_$userId') ?? 1;
    final rewardCoins = defaultRewardsConfig[(currentDay - 1).clamp(0, 6)];
    final currentCoins = prefs.getInt('user_coins') ?? 0;
    await prefs.setInt('user_coins', currentCoins + rewardCoins);
    await prefs.setString('daily_streak_claimed_date_$userId', todayStr);
    await prefs.setInt('daily_streak_current_day_$userId',
        currentDay >= 7 ? 1 : currentDay + 1);

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
    final match = defaultDailyTasks.firstWhere(
      (t) => t['taskKey'] == taskKey,
      orElse: () => <String, dynamic>{},
    );
    // Ignore invalid task keys that are not part of the official 12 daily tasks
    if (match.isEmpty) return null;

    final prefs = await SharedPreferences.getInstance();
    final todayStr = _getTodayString();
    final userId = await _getUserId();

    // 1. Update locally first (scoped to userId and date)
    final progKey = 'task_progress_${userId}_${todayStr}_$taskKey';
    final isAlreadyClaimed =
        prefs.getBool('task_claimed_${userId}_${todayStr}_$taskKey') ?? false;
    final isAlreadyNotified =
        prefs.getBool('task_top_notified_${userId}_${todayStr}_$taskKey') ??
            false;

    final int oldProg = prefs.getInt(progKey) ?? 0;
    final int localProg = oldProg + increment;
    await prefs.setInt(progKey, localProg);

    final target = (match['target'] as int?) ?? 2;
    final taskTitle = match['title']?.toString() ?? '';
    final coinsReward = (match['coins'] as int?) ?? 100;

    // A task was JUST completed on this increment IF:
    // oldProg was below target AND localProg reaches or exceeds target
    final bool justCompletedLocally = (oldProg < target && localProg >= target);

    Map<String, dynamic>? backendResult;
    bool backendJustCompleted = false;

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
          if (data['isCompleted'] == true || data['completed'] == true) {
            backendJustCompleted = true;
          }
        }
      }
    } catch (e) {
      debugPrint('DailyService: updateTaskProgress backend error: $e');
    }

    // 4. Trigger TOP SNACKBAR on any screen STRICTLY ONCE if just completed right now
    if ((justCompletedLocally || backendJustCompleted) &&
        !isAlreadyNotified &&
        !isAlreadyClaimed) {
      final notifiedKey = 'task_top_notified_${userId}_${todayStr}_$taskKey';
      await prefs.setBool(notifiedKey, true);
      TopTaskSnackBar.showTaskCompleted(
        taskKey: taskKey,
        title: taskTitle.isNotEmpty ? taskTitle : null,
        coins: coinsReward,
      );
    }

    // 5. Check Dual Scholar (word_master_duo) ONLY when playing Wordix or Crossword
    if (taskKey == 'play_wordix' ||
        taskKey == 'play_crossword' ||
        taskKey == 'win_wordix' ||
        taskKey == 'win_crossword') {
      final duoNotifiedKey =
          'task_top_notified_${userId}_${todayStr}_word_master_duo';
      final duoAlreadyNotified = prefs.getBool(duoNotifiedKey) ?? false;
      final duoAlreadyClaimed =
          prefs.getBool('task_claimed_${userId}_${todayStr}_word_master_duo') ??
              false;

      final bool wordixPlayed =
          (prefs.getInt('task_progress_${userId}_${todayStr}_play_wordix') ??
                      0) >
                  0 ||
              (prefs.getInt('task_progress_${userId}_${todayStr}_win_wordix') ??
                      0) >
                  0;
      final bool crossPlayed = (prefs.getInt(
                      'task_progress_${userId}_${todayStr}_play_crossword') ??
                  0) >
              0 ||
          (prefs.getInt('task_progress_${userId}_${todayStr}_win_crossword') ??
                  0) >
              0;

      final int duoProg = (wordixPlayed ? 1 : 0) + (crossPlayed ? 1 : 0);
      await prefs.setInt(
          'task_progress_${userId}_${todayStr}_word_master_duo', duoProg);

      // Only complete and notify when BOTH Wordix AND Crossword have been played!
      if (wordixPlayed &&
          crossPlayed &&
          !duoAlreadyNotified &&
          !duoAlreadyClaimed) {
        await prefs.setBool(duoNotifiedKey, true);
        TopTaskSnackBar.showTaskCompleted(
          taskKey: 'word_master_duo',
          title: 'Dual Scholar',
          coins: 200,
        );
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
    final todayStr = _getTodayString();
    final userId = await _getUserId();

    // 1. Mark claimed locally with user and date scope
    await prefs.setBool('task_claimed_${userId}_${todayStr}_$taskKey', true);

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
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic> && decoded['data'] != null) {
          final serverWallet = (decoded['data']['newWalletBalance'] as int?);
          if (serverWallet != null) {
            await prefs.setInt('user_coins_$userId', serverWallet);
            await prefs.setInt('user_coins', serverWallet);
          }
        }
        return decoded;
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
    final userId = await _getUserId();

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
            await prefs.setString('daily_last_spin_date_$userId', todayStr);
          }
          if (decoded['data'] != null) {
            final serverWallet = (decoded['data']['newWalletBalance'] as int?);
            if (serverWallet != null) {
              await prefs.setInt('user_coins_$userId', serverWallet);
              await prefs.setInt('user_coins', serverWallet);
            }
          }
          return decoded;
        }
      }
    } catch (e) {
      debugPrint('DailyService: spinWheel backend error: $e');
    }

    if (spinType == 'free') {
      await prefs.setString('daily_last_spin_date_$userId', todayStr);
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
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint('DailyService: getSpinStatus error: $e');
    }
    return null;
  }

  Future<void> _cacheBackendStatus(
    Map<String, dynamic> data, {
    required String userId,
    required String todayStr,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final streak = data['streak'] as Map<String, dynamic>?;
    if (streak != null) {
      final currentDay = (streak['currentDay'] as num?)?.toInt() ?? 1;
      final isClaimed = streak['isTodayClaimed'] == true;
      await prefs.setInt('daily_streak_current_day_$userId', currentDay);
      if (isClaimed) {
        await prefs.setString('daily_streak_claimed_date_$userId', todayStr);
      } else {
        final lastClaim = prefs.getString('daily_streak_claimed_date_$userId');
        if (lastClaim == todayStr) {
          await prefs.remove('daily_streak_claimed_date_$userId');
        }
      }
    }
  }

  Future<Map<String, dynamic>> getLocalCachedStatus() async {
    final userId = await _getUserId();
    return _getLocalDailyStatus(_getTodayString(), userId: userId);
  }

  Future<Map<String, dynamic>> _getLocalDailyStatus(
    String todayStr, {
    required String userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final currentDay = prefs.getInt('daily_streak_current_day_$userId') ?? 1;
    final isClaimed =
        prefs.getString('daily_streak_claimed_date_$userId') == todayStr;
    final hasFreeSpin =
        prefs.getString('daily_last_spin_date_$userId') != todayStr;
    final adSpins =
        prefs.getInt('spin_ad_spins_today_${userId}_$todayStr') ?? 3;

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
        int localProg =
            prefs.getInt('task_progress_${userId}_${todayStr}_$key') ?? 0;
        if (key == 'word_master_duo') {
          final wordixCount = (prefs.getInt(
                      'task_progress_${userId}_${todayStr}_play_wordix') ??
                  0) +
              (prefs.getInt('task_progress_${userId}_${todayStr}_win_wordix') ??
                  0);
          final crossCount = (prefs.getInt(
                      'task_progress_${userId}_${todayStr}_play_crossword') ??
                  0) +
              (prefs.getInt(
                      'task_progress_${userId}_${todayStr}_win_crossword') ??
                  0);
          localProg = (wordixCount > 0 ? 1 : 0) + (crossCount > 0 ? 1 : 0);
        }
        final target = (map['target'] as num?)?.toInt() ?? 1;
        final cappedProg = math.min(localProg, target);
        final isTaskClaimed =
            prefs.getBool('task_claimed_${userId}_${todayStr}_$key') ?? false;
        map['progress'] = cappedProg;
        map['isCompleted'] = cappedProg >= target;
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
