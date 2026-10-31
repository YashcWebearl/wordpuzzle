import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:word_puzzle/crossword/crossword_splash.dart';
import 'package:word_puzzle/scramble/scramble_home.dart';
import 'package:word_puzzle/balloon_rescue/balloon_home.dart';
import 'package:word_puzzle/services/daily_service.dart';
import 'package:word_puzzle/view/ad_show.dart';
import 'package:word_puzzle/widget/app_3d_button.dart';
import 'package:word_puzzle/widget/coin_service.dart';
import 'package:word_puzzle/widget/sound.dart';
import 'package:word_puzzle/widget/floating_words_background.dart';
import 'package:word_puzzle/wordix/home_screen.dart';

/// 🎮 Word Puzzle Hub - Daily Rewards, Tactical Tasks & Lucky Spin Wheel Screen
/// Implements full AAA game visual aesthetics with neon glow, metallic bevels,
/// 3D physics-based spinning wheel, 7-day streak calendar, and daily quests.
/// Designed for Wordix, Crossword, Word Scramble & Balloon Rescue.
class DailyRewardsTasksScreen extends StatefulWidget {
  final int initialTabIndex;
  final String gameName;

  const DailyRewardsTasksScreen({
    super.key,
    this.initialTabIndex = 0,
    this.gameName = 'Wordix',
  });

  @override
  State<DailyRewardsTasksScreen> createState() =>
      _DailyRewardsTasksScreenState();
}

class _DailyRewardsTasksScreenState extends State<DailyRewardsTasksScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  late final ConfettiController _confettiController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  // ── Wheel Spin Controller & State ──
  late final AnimationController _wheelController;
  Animation<double>? _wheelAnimation;
  double _currentWheelAngle = 0.0;
  String? _spinningButton; // null | 'free' | 'ad' | 'coin'
  bool get _isSpinning => _spinningButton != null;
  bool _hasFreeSpinToday = true;
  int _adSpinsRemaining = 3;

  // ── Streak State (UI) ──
  int _currentStreak = 1; // Default Day 1
  int _streakCycle = 1;
  bool _isTodayClaimed = false;
  bool _isClaimingStreak = false;
  String? _claimingTaskId;

  // 7-Day Rewards Config from DAILY_REWARDS_TASKS_AND_SPIN_BACKEND_GUIDE.md
  final List<Map<String, dynamic>> _streakRewards = [
    {
      'day': 1,
      'title': 'Word Explorer',
      'coins': 100,
      'isMega': false,
      'status': 'available', // initial default Day 1 available
    },
    {
      'day': 2,
      'title': 'Lexicon Novice',
      'coins': 150,
      'isMega': false,
      'status': 'locked',
    },
    {
      'day': 3,
      'title': 'Vocabulary Cadet',
      'coins': 200,
      'isMega': false,
      'status': 'locked',
    },
    {
      'day': 4,
      'title': 'Letter Artisan',
      'coins': 300,
      'isMega': false,
      'status': 'locked',
    },
    {
      'day': 5,
      'title': 'Word Master Vault',
      'coins': 450,
      'isMega': false,
      'status': 'locked',
    },
    {
      'day': 6,
      'title': 'Grid Sage Jackpot',
      'coins': 600,
      'isMega': false,
      'status': 'locked',
    },
    {
      'day': 7,
      'title': 'Grand Champion Chest',
      'coins': 1200,
      'isMega': true,
      'status': 'locked',
    },
  ];

  // ── Daily Tasks Catalog (Tailored for Wordix & Crossword) ──
  List<Map<String, dynamic>> _dailyTasks = [
    {
      'taskKey': 'play_wordix',
      'title': 'Word Finder',
      'description': 'Play 3 levels in Wordix Word Search',
      'progress': 0,
      'total': 3,
      'coins': 100,
      'gameScope': 'wordix',
      'icon': Icons.search_rounded,
      'iconColor': const Color(0xFF00E5FF),
      'isCompleted': false,
      'isClaimed': false,
    },
    {
      'taskKey': 'win_wordix',
      'title': 'Grid Conqueror',
      'description': 'Complete 2 Wordix Word Search levels',
      'progress': 0,
      'total': 2,
      'coins': 150,
      'gameScope': 'wordix',
      'icon': Icons.grid_view_rounded,
      'iconColor': const Color(0xFF00E676),
      'isCompleted': false,
      'isClaimed': false,
    },
    {
      'taskKey': 'play_crossword',
      'title': 'Wheel Weaver',
      'description': 'Play 3 Crossword Word Connect levels',
      'progress': 0,
      'total': 3,
      'coins': 100,
      'gameScope': 'crossword',
      'icon': Icons.blur_circular_rounded,
      'iconColor': const Color(0xFFFFB300),
      'isCompleted': false,
      'isClaimed': false,
    },
    {
      'taskKey': 'win_crossword',
      'title': 'Crossword Maestro',
      'description': 'Solve 2 Crossword levels',
      'progress': 0,
      'total': 2,
      'coins': 150,
      'gameScope': 'crossword',
      'icon': Icons.emoji_events_rounded,
      'iconColor': const Color(0xFFFF9100),
      'isCompleted': false,
      'isClaimed': false,
    },
    {
      'taskKey': 'play_scramble',
      'title': 'Letter Unscrambler',
      'description': 'Play 3 Word Scramble levels',
      'progress': 0,
      'total': 3,
      'coins': 100,
      'gameScope': 'scramble',
      'icon': Icons.spellcheck_rounded,
      'iconColor': const Color(0xFFAB47BC),
      'isCompleted': false,
      'isClaimed': false,
    },
    {
      'taskKey': 'win_scramble',
      'title': 'Master Speller',
      'description': 'Complete 2 Word Scramble levels',
      'progress': 0,
      'total': 2,
      'coins': 150,
      'gameScope': 'scramble',
      'icon': Icons.military_tech_rounded,
      'iconColor': const Color(0xFFFFD700),
      'isCompleted': false,
      'isClaimed': false,
    },
    {
      'taskKey': 'play_balloon',
      'title': 'Balloon Savior',
      'description': 'Play 3 Balloon Rescue levels',
      'progress': 0,
      'total': 3,
      'coins': 100,
      'gameScope': 'balloon',
      'icon': Icons.air_rounded,
      'iconColor': const Color(0xFFFF7043),
      'isCompleted': false,
      'isClaimed': false,
    },
    {
      'taskKey': 'win_balloon',
      'title': 'Sky Guardian',
      'description': 'Complete 2 Balloon Rescue levels',
      'progress': 0,
      'total': 2,
      'coins': 150,
      'gameScope': 'balloon',
      'icon': Icons.shield_rounded,
      'iconColor': const Color(0xFF26A69A),
      'isCompleted': false,
      'isClaimed': false,
    },
    {
      'taskKey': 'word_master_duo',
      'title': 'Dual Scholar',
      'description': 'Play both Wordix & Crossword today',
      'progress': 0,
      'total': 2,
      'coins': 200,
      'gameScope': 'all',
      'icon': Icons.auto_awesome_rounded,
      'iconColor': const Color(0xFFE040FB),
      'isCompleted': false,
      'isClaimed': false,
    },
    {
      'taskKey': 'use_hint',
      'title': 'Clue Seeker',
      'description': 'Use 2 hints or shuffles in any game',
      'progress': 0,
      'total': 2,
      'coins': 80,
      'gameScope': 'all',
      'icon': Icons.lightbulb_outline_rounded,
      'iconColor': const Color(0xFFFFD54F),
      'isCompleted': false,
      'isClaimed': false,
    },
    {
      'taskKey': 'spin_wheel_task',
      'title': 'Fortune Seeker',
      'description': 'Spin the Lucky Wheel 1 time',
      'progress': 0,
      'total': 1,
      'coins': 50,
      'gameScope': 'all',
      'icon': Icons.change_circle_rounded,
      'iconColor': const Color(0xFF7C4DFF),
      'isCompleted': false,
      'isClaimed': false,
    },
    {
      'taskKey': 'watch_ad',
      'title': 'Bonus Hunter',
      'description': 'Watch 2 rewarded ads',
      'progress': 0,
      'total': 2,
      'coins': 80,
      'gameScope': 'all',
      'icon': Icons.play_circle_fill_rounded,
      'iconColor': const Color(0xFFFF5252),
      'isCompleted': false,
      'isClaimed': false,
    },
  ];

  // ── Wheel Slices Configuration (8 Slices) ──
  final List<Map<String, dynamic>> _wheelSectors = [
    {
      'label': '50',
      'icon': '🪙',
      'coins': 50,
      'color': const Color(0xFFFF5252),
      'type': 'coins',
    },
    {
      'label': '100',
      'icon': '🪙',
      'coins': 100,
      'color': const Color(0xFFFFB300),
      'type': 'coins',
    },
    {
      'label': '150',
      'icon': '🪙',
      'coins': 150,
      'color': const Color(0xFF00E5FF),
      'type': 'coins',
    },
    {
      'label': '250',
      'icon': '💎',
      'coins': 250,
      'color': const Color(0xFFE040FB),
      'type': 'coins',
    },
    {
      'label': '400',
      'icon': '💰',
      'coins': 400,
      'color': const Color(0xFF00E676),
      'type': 'coins',
    },
    {
      'label': '600',
      'icon': '🏆',
      'coins': 600,
      'color': const Color(0xFFFF9100),
      'type': 'coins',
    },
    {
      'label': '2 HINTS',
      'icon': '💡',
      'coins': 60,
      'color': const Color(0xFF7C4DFF),
      'type': 'hint',
    },
    {
      'label': '1,200',
      'icon': '👑',
      'coins': 1200,
      'color': const Color(0xFFFFD700),
      'type': 'jackpot',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );

    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _wheelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );
    _wheelAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(_wheelController);

    _initAndLoadData();
  }

  Future<void> _initAndLoadData() async {
    // 1. Immediately apply cached local status (0ms delay - eliminates the 1-second flash!)
    try {
      final cached = await DailyService().getLocalCachedStatus();
      if (mounted) {
        _applyDailyData(cached);
      }
    } catch (_) {}

    // 2. Fetch fresh status from backend in background
    await _loadData();
  }

  Future<void> _loadData() async {
    final data = await DailyService().getDailyStatus(gameName: widget.gameName);
    if (!mounted) return;
    _applyDailyData(data);
  }

  void _applyDailyData(Map<String, dynamic> data) {
    if (!mounted) return;

    final streak = data['streak'] as Map<String, dynamic>? ?? {};
    final tasks = (data['dailyTasks'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
    final spin = data['spin'] as Map<String, dynamic>? ?? {};
    final catalog = (data['rewardsCatalog'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];

    final int currentDay = (streak['currentDay'] as int?) ?? 1;
    final int cycle = (streak['cycle'] as int?) ?? 1;
    final bool isTodayClaimed = (streak['isTodayClaimed'] as bool?) ?? false;

    // Update 7-day rewards calendar status
    if (catalog.isNotEmpty && catalog.length >= 7) {
      for (int i = 0; i < 7; i++) {
        final catItem = catalog[i];
        final dayNum = i + 1;
        String status = 'locked';
        if (dayNum < currentDay || (dayNum == currentDay && isTodayClaimed)) {
          status = 'claimed';
        } else if (dayNum == currentDay && !isTodayClaimed) {
          status = 'available';
        }
        _streakRewards[i]['status'] = status;
        if (catItem['coins'] != null) {
          _streakRewards[i]['coins'] = catItem['coins'];
        }
      }
    } else {
      for (int i = 0; i < 7; i++) {
        final dayNum = i + 1;
        if (dayNum < currentDay || (dayNum == currentDay && isTodayClaimed)) {
          _streakRewards[i]['status'] = 'claimed';
        } else if (dayNum == currentDay && !isTodayClaimed) {
          _streakRewards[i]['status'] = 'available';
        } else {
          _streakRewards[i]['status'] = 'locked';
        }
      }
    }

    // Assign appropriate icons to tasks and clamp progress to total
    if (tasks.isNotEmpty) {
      // Gather whether Wordix and Crossword have been played today
      int wordixProg = 0;
      int crossProg = 0;
      for (var task in tasks) {
        final k = task['taskKey']?.toString() ?? '';
        final p = (task['progress'] as num?)?.toInt() ?? 0;
        if (k == 'play_wordix' || k == 'win_wordix') {
          if (p > wordixProg) wordixProg = p;
        } else if (k == 'play_crossword' || k == 'win_crossword') {
          if (p > crossProg) crossProg = p;
        }
      }

      final bool hasWordix = wordixProg > 0;
      final bool hasCross = crossProg > 0;
      final int duoCalculatedProg = (hasWordix ? 1 : 0) + (hasCross ? 1 : 0);

      for (var task in tasks) {
        final key = task['taskKey']?.toString() ?? '';
        final total = (task['total'] as num?)?.toInt() ?? 1;
        int rawProg = (task['progress'] as num?)?.toInt() ?? 0;

        // Strictly enforce Dual Scholar rule:
        // Wordix played = 1, Crossword played = 1, total = 2.
        // Playing multiple levels in only one game must NEVER complete it!
        if (key == 'word_master_duo') {
          final isClaimed = task['isClaimed'] == true;
          if (!isClaimed) {
            rawProg = duoCalculatedProg;
            task['isCompleted'] = duoCalculatedProg >= 2;
          } else {
            rawProg = 2;
            task['isCompleted'] = true;
          }
        } else {
          task['isCompleted'] = (task['isCompleted'] == true) || (rawProg >= total);
        }

        task['total'] = total;
        task['progress'] = math.min(rawProg, total);
        _assignTaskIconAndDetails(task, key);
      }
    }

    setState(() {
      _currentStreak = currentDay;
      _streakCycle = cycle;
      _isTodayClaimed = isTodayClaimed;
      if (tasks.isNotEmpty) {
        _dailyTasks = tasks;
      }
      _hasFreeSpinToday = (spin['hasFreeSpin'] as bool?) ?? true;
      _adSpinsRemaining = (spin['adSpinsRemaining'] as int?) ?? 3;
    });
  }

  void _assignTaskIconAndDetails(Map<String, dynamic> task, String key) {
    if (key == 'play_wordix') {
      task['icon'] = Icons.search_rounded;
      task['iconColor'] = const Color(0xFF00E5FF);
    } else if (key == 'win_wordix') {
      task['icon'] = Icons.grid_view_rounded;
      task['iconColor'] = const Color(0xFF00E676);
    } else if (key == 'play_crossword') {
      task['icon'] = Icons.blur_circular_rounded;
      task['iconColor'] = const Color(0xFFFFB300);
    } else if (key == 'win_crossword') {
      task['icon'] = Icons.emoji_events_rounded;
      task['iconColor'] = const Color(0xFFFF9100);
    } else if (key == 'play_scramble') {
      task['icon'] = Icons.spellcheck_rounded;
      task['iconColor'] = const Color(0xFFAB47BC);
    } else if (key == 'win_scramble') {
      task['icon'] = Icons.military_tech_rounded;
      task['iconColor'] = const Color(0xFFFFD700);
    } else if (key == 'play_balloon') {
      task['icon'] = Icons.air_rounded;
      task['iconColor'] = const Color(0xFFFF7043);
    } else if (key == 'win_balloon') {
      task['icon'] = Icons.shield_rounded;
      task['iconColor'] = const Color(0xFF26A69A);
    } else if (key == 'word_master_duo') {
      task['icon'] = Icons.auto_awesome_rounded;
      task['iconColor'] = const Color(0xFFE040FB);
    } else if (key == 'use_hint') {
      task['icon'] = Icons.lightbulb_outline_rounded;
      task['iconColor'] = const Color(0xFFFFD54F);
    } else if (key == 'spin_wheel_task') {
      task['icon'] = Icons.change_circle_rounded;
      task['iconColor'] = const Color(0xFF7C4DFF);
    } else if (key == 'watch_ad') {
      task['icon'] = Icons.play_circle_fill_rounded;
      task['iconColor'] = const Color(0xFFFF5252);
    } else {
      task['icon'] = Icons.stars_rounded;
      task['iconColor'] = const Color(0xFF00E5FF);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _confettiController.dispose();
    _pulseController.dispose();
    _wheelController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎯 ACTIONS & LOGIC (CONNECTED TO BACKEND API WITH INSTANT LOCAL FEEDBACK)
  // ═══════════════════════════════════════════════════════════════════════════

  void _claimStreakReward() async {
    if (_isTodayClaimed || _isClaimingStreak) return;

    // Synchronously lock immediately so rapid double clicks do nothing
    setState(() => _isClaimingStreak = true);
    AudioHelper().playButtonSound();
    HapticFeedback.heavyImpact();

    final res = await DailyService().claimStreak(gameName: widget.gameName);

    if (!mounted) return;
    setState(() => _isClaimingStreak = false);

    if (res['success'] == true) {
      final data = res['data'] ?? {};
      final rewardCoins = (data['coinsAwarded'] as int?) ??
          _streakRewards[(_currentStreak - 1).clamp(0, 6)]['coins'] as int;
      final serverWallet = (data['newWalletBalance'] as int?);

      // Set wallet balance directly or add locally without duplicate server increment
      final coinProvider = Provider.of<CoinProvider>(context, listen: false);
      if (serverWallet != null) {
        await coinProvider.setCoins(serverWallet);
      } else {
        await coinProvider.addCoins(rewardCoins, instant: true, syncServer: false);
      }

      setState(() {
        _isTodayClaimed = true;
        _streakRewards[(_currentStreak - 1).clamp(0, 6)]['status'] = 'claimed';
      });

      AudioHelper().playMoneySound();
      _confettiController.play();

      _showRewardCelebrationDialog(
        title: "DAY $_currentStreak STREAK CLAIMED!",
        subtitle: "You've earned +$rewardCoins bonus coins!",
        coins: rewardCoins,
        iconEmoji: "🔥",
      );

      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Already claimed today.'),
          backgroundColor: const Color(0xFFFF5252),
        ),
      );
    }
  }

  void _claimTask(int index) async {
    final task = _dailyTasks[index];
    final taskKey = task['taskKey']?.toString() ?? '';
    if (_claimingTaskId != null ||
        task['isClaimed'] == true ||
        task['isCompleted'] == false) {
      return;
    }

    // Synchronously lock this specific task immediately
    setState(() => _claimingTaskId = taskKey);
    AudioHelper().playButtonSound();
    HapticFeedback.mediumImpact();

    final rewardCoins = (task['coins'] as int?) ?? 100;
    final res = await DailyService().claimTask(
      taskKey: taskKey,
      coins: rewardCoins,
      gameName: widget.gameName,
    );

    if (!mounted) return;
    setState(() => _claimingTaskId = null);

    if (res['success'] == true) {
      final data = res['data'] ?? {};
      final serverWallet = (data['newWalletBalance'] as int?);

      // Set wallet balance directly or add locally without duplicate server increment
      final coinProvider = Provider.of<CoinProvider>(context, listen: false);
      if (serverWallet != null) {
        await coinProvider.setCoins(serverWallet);
      } else {
        await coinProvider.addCoins(rewardCoins, instant: true, syncServer: false);
      }

      setState(() {
        task['isClaimed'] = true;
      });

      AudioHelper().playMoneySound();
      _confettiController.play();

      _showRewardCelebrationDialog(
        title: "TASK REWARD CLAIMED!",
        subtitle: "${task['title']}: +$rewardCoins Coins added!",
        coins: rewardCoins,
        iconEmoji: "🎯",
      );

      _loadData();
    }
  }

  void _handleTaskNavigation(Map<String, dynamic> task) {
    AudioHelper().playButtonSound();
    final key = task['taskKey']?.toString() ?? '';
    final scope = task['gameScope'] as String? ?? 'all';

    // 1. Wordix tasks: Word Finder (play_wordix) & Grid Conqueror (win_wordix)
    if (key == 'play_wordix' || key == 'win_wordix' || scope == 'wordix') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
    // 2. Crossword tasks: Wheel Weaver (play_crossword) & Crossword Maestro (win_crossword)
    else if (key == 'play_crossword' || key == 'win_crossword' || scope == 'crossword') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CrosswordSplashScreen()),
      );
    }
    // 3. Word Scramble tasks: Letter Unscrambler (play_scramble) & Master Speller (win_scramble)
    else if (key == 'play_scramble' || key == 'win_scramble' || scope == 'scramble') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ScrambleHomeScreen()),
      );
    }
    // 4. Balloon Rescue tasks: Balloon Savior (play_balloon) & Sky Guardian (win_balloon)
    else if (key == 'play_balloon' || key == 'win_balloon' || scope == 'balloon') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BalloonHomeScreen()),
      );
    }
    // 5. Dual Scholar (word_master_duo)
    // First goes to Wordix. When Wordix is played (1/2), goes to Crossword for the 2nd game!
    else if (key == 'word_master_duo') {
      final wordixPlayTask = _dailyTasks.firstWhere(
        (t) => t['taskKey'] == 'play_wordix',
        orElse: () => <String, dynamic>{},
      );
      final wordixWinTask = _dailyTasks.firstWhere(
        (t) => t['taskKey'] == 'win_wordix',
        orElse: () => <String, dynamic>{},
      );
      final wordixPlayed = (((wordixPlayTask['progress'] as num?)?.toInt() ?? 0) > 0) ||
                           (((wordixWinTask['progress'] as num?)?.toInt() ?? 0) > 0);

      final crossPlayTask = _dailyTasks.firstWhere(
        (t) => t['taskKey'] == 'play_crossword',
        orElse: () => <String, dynamic>{},
      );
      final crossWinTask = _dailyTasks.firstWhere(
        (t) => t['taskKey'] == 'win_crossword',
        orElse: () => <String, dynamic>{},
      );
      final crossPlayed = (((crossPlayTask['progress'] as num?)?.toInt() ?? 0) > 0) ||
                          (((crossWinTask['progress'] as num?)?.toInt() ?? 0) > 0);

      if (!wordixPlayed) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else if (!crossPlayed) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CrosswordSplashScreen()),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    }
    // 6. Clue Seeker (use_hint) -> Open Wordix game home
    else if (key == 'use_hint') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
    // 7. Fortune Seeker (spin_wheel_task) -> Switch to Lucky Spin wheel tab
    else if (key == 'spin_wheel_task') {
      _tabController.animateTo(2);
    }
    // 8. Bonus Hunter (watch_ad) -> Directly open rewarded ad
    else if (key == 'watch_ad') {
      _handleWatchAdForTask(task);
    }
    // Fallback
    else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
  }

  void _handleWatchAdForTask(Map<String, dynamic> task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdPlaybackPage(
          isRewardAd: true,
          onAdComplete: () async {
            if (!mounted) return;
            _loadData();
            AudioHelper().playMoneySound();
          },
        ),
      ),
    );
  }

  void _spinWheel({required String buttonType}) async {
    if (_isSpinning) return;

    if (buttonType == 'coin') {
      final coinProvider = Provider.of<CoinProvider>(context, listen: false);
      if (coinProvider.coins < 100) {
        AudioHelper().playButtonSound();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF260845),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFFF5252), width: 1.2),
            ),
            content: Text(
              '⚠️ Not enough coins! Need 100 coins to spin.',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
        return;
      }
      // INSTANT COIN DEDUCTION (tarat cut thay jay)
      await coinProvider.undoCoins(100, instant: true);
      _executeWheelSpin('coin');
      return;
    }

    if (buttonType == 'ad') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdPlaybackPage(
            isRewardAd: true,
            onAdComplete: () async {
              if (mounted) {
                _executeWheelSpin('ad');
              }
            },
          ),
        ),
      );
      return;
    }

    _executeWheelSpin('free');
  }

  void _executeWheelSpin(String buttonType) async {
    if (_isSpinning) return;

    AudioHelper().playButtonSound();
    HapticFeedback.heavyImpact();

    setState(() {
      _spinningButton = buttonType;
      if (buttonType == 'free') {
        _hasFreeSpinToday = false;
      }
    });

    // 1. Request spin outcome from backend API
    final spinRes = await DailyService().spinWheel(
      spinType: buttonType == 'coin' ? 'coins' : buttonType,
      gameName: widget.gameName,
    );

    int targetIndex = 1;
    int winCoins = 100;
    if (spinRes['success'] == true && spinRes['data'] != null) {
      final data = spinRes['data'] as Map<String, dynamic>;
      targetIndex = (data['sliceIndex'] as int?)?.clamp(0, 7) ?? 1;
      winCoins = (data['coinsAwarded'] as int?) ??
          (_wheelSectors[targetIndex]['coins'] as int);
    } else {
      // Local fallback weighted RNG
      final rand = math.Random();
      final p = rand.nextDouble() * 100;
      if (p < 30) {
        targetIndex = 0;
      } else if (p < 55) {
        targetIndex = 1;
      } else if (p < 73) {
        targetIndex = 2;
      } else if (p < 85) {
        targetIndex = 3;
      } else if (p < 93) {
        targetIndex = 4;
      } else if (p < 97.5) {
        targetIndex = 5;
      } else if (p < 99.5) {
        targetIndex = 6;
      } else {
        targetIndex = 7;
      }
      winCoins = _wheelSectors[targetIndex]['coins'] as int;
    }

    const int totalSectors = 8;
    const double sweep = 2 * math.pi / totalSectors;
    final double targetSectorMid = targetIndex * sweep + (sweep / 2.0);

    // Top needle is at 12 o'clock, which in Canvas coordinates is 3*pi/2 (270 degrees).
    // When wheel rotates by totalRotation clockwise, slice at targetSectorMid moves to
    // (targetSectorMid + totalRotation). We want that to land at 3*pi/2.
    double desiredFinalMod = (3 * math.pi / 2 - targetSectorMid) % (2 * math.pi);
    if (desiredFinalMod < 0) desiredFinalMod += 2 * math.pi;

    double currentMod = _currentWheelAngle % (2 * math.pi);
    if (currentMod < 0) currentMod += 2 * math.pi;

    double additionalAngle = (desiredFinalMod - currentMod) % (2 * math.pi);
    if (additionalAngle < 0) additionalAngle += 2 * math.pi;

    final rand = math.Random();
    final double extraRotations = (5 + rand.nextInt(3)) * 2 * math.pi;
    final double totalRotation = extraRotations + additionalAngle;

    _wheelAnimation = Tween<double>(
      begin: _currentWheelAngle,
      end: _currentWheelAngle + totalRotation,
    ).animate(
      CurvedAnimation(
        parent: _wheelController,
        curve: Curves.easeOutCubic,
      ),
    );

    _wheelController.reset();
    _wheelController.forward().then((_) async {
      _currentWheelAngle = (_currentWheelAngle + totalRotation) % (2 * math.pi);

      final winningSector = _wheelSectors[targetIndex];

      if (!mounted) return;
      final coinProvider = Provider.of<CoinProvider>(context, listen: false);
      final serverWallet = (spinRes['data']?['newWalletBalance'] as int?);
      if (serverWallet != null) {
        await coinProvider.setCoins(serverWallet);
      } else {
        await coinProvider.addCoins(winCoins, instant: true, syncServer: false);
      }

      // Report spin wheel task completion
      await DailyService().updateTaskProgress(
        taskKey: 'spin_wheel_task',
        increment: 1,
        gameName: widget.gameName,
      );

      AudioHelper().playMoneySound();
      _confettiController.play();

      setState(() {
        _spinningButton = null;
      });

      _showRewardCelebrationDialog(
        title: targetIndex == 7 ? "🏆 MEGA JACKPOT!" : "YOU WON!",
        subtitle: winningSector['type'] == 'hint'
            ? "2 Free In-Game Hints + $winCoins Coins!"
            : "+$winCoins Coins added to your wallet!",
        coins: winCoins,
        iconEmoji: targetIndex == 7 ? "👑" : "🎡",
      );

      _loadData();
    });
  }

  void _showRewardCelebrationDialog({
    required String title,
    required String subtitle,
    required int coins,
    required String iconEmoji,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF220845), Color(0xFF0F0221)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: const Color(0xFFFFD54F),
                width: 2.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD54F).withValues(alpha: 0.35),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
                const BoxShadow(
                  color: Colors.black,
                  offset: Offset(0, 12),
                  blurRadius: 18,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Floating Emoji / Badge
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.5),
                        blurRadius: 18,
                      ),
                    ],
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                  child: Center(
                    child: Text(
                      iconEmoji,
                      style: const TextStyle(fontSize: 38),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dynaPuff(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 20),

                // Coins Amount Chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFFFD54F).withValues(alpha: 0.7),
                      width: 1.4,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🪙', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      Text(
                        '+$coins COINS',
                        style: GoogleFonts.dynaPuff(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFFFD54F),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                App3DButton.amber(
                  text: 'AWESOME!',
                  width: double.infinity,
                  height: 48,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎨 BUILD METHOD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D1E),
      body: Stack(
        children: [
          // 1. Atmospheric Reactive Cyber Aura Background
          _buildAtmosphericBackground(),

          // 2. Animated Floating Words & Letter Particles Overlay
          const Positioned.fill(
            child: FloatingWordsBackground(
              isWordix: true,
              opacityMultiplier: 0.75,
              baseColor: Color(0xFF00E5FF),
              accentColor: Color(0xFFFFD54F),
            ),
          ),

          // 3. Main Content
          SafeArea(
            child: Column(
              children: [
                // Top App Bar
                _buildTopHeader(),

                const SizedBox(height: 6),

                // Tab Selector
                _buildTabBar(),

                const SizedBox(height: 10),

                // Content View for the 3 Tabs
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildStreakRewardsTab(),
                      _buildDailyTasksTab(),
                      _buildLuckyWheelTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Confetti Overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Color(0xFFFFD54F),
                Color(0xFF00E5FF),
                Color(0xFF00E676),
                Color(0xFFFF5252),
                Color(0xFFE040FB),
                Colors.white,
              ],
              numberOfParticles: 40,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🌌 ATMOSPHERIC BACKGROUND
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAtmosphericBackground() {
    return Stack(
      children: [
        // Base dark cosmic gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0C1026),
                Color(0xFF080B1A),
                Color(0xFF04060E),
              ],
            ),
          ),
        ),

        // Cyan ambient glow (top left)
        Positioned(
          top: -80,
          left: -80,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF00E5FF).withValues(alpha: 0.18),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Purple ambient glow (center right)
        Positioned(
          top: 220,
          right: -80,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF7C4DFF).withValues(alpha: 0.18),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Warm amber glow (bottom center)
        Positioned(
          bottom: -100,
          left: 40,
          right: 40,
          child: Container(
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFFFB300).withValues(alpha: 0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📱 TOP HEADER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () {
              AudioHelper().playButtonSound();
              Navigator.pop(context);
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.2,
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ARCADE REWARDS',
                  style: GoogleFonts.dynaPuff(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.6,
                  ),
                ),
                Text(
                  'Daily Streaks, Quests & Wheel',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Coin Wallet Balance Pill
          Consumer<CoinProvider>(
            builder: (context, coinProvider, _) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2A1B02), Color(0xFF191001)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFFD54F),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      '${coinProvider.coins}',
                      style: GoogleFonts.dynaPuff(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFFFD54F),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📑 TAB BAR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1.2,
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFFFFB300), Color(0xFFFF6F00)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.65),
        labelStyle: GoogleFonts.dynaPuff(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.3,
        ),
        unselectedLabelStyle: GoogleFonts.dynaPuff(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        tabs: const [
          Tab(
            icon: Text('🎁', style: TextStyle(fontSize: 16)),
            text: 'Streak',
          ),
          Tab(
            icon: Text('🎯', style: TextStyle(fontSize: 16)),
            text: 'Quests',
          ),
          Tab(
            icon: Text('🎡', style: TextStyle(fontSize: 16)),
            text: 'Lucky Spin',
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎁 TAB 0: 7-DAY STREAK REWARDS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStreakRewardsTab() {
    final currentDayCoins =
        _streakRewards[(_currentStreak - 1).clamp(0, 6)]['coins'] as int? ?? 100;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
      child: Column(
        children: [
          // Hero Streak Status Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFF261048), Color(0xFF130628)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: const Color(0xFFFFB300).withValues(alpha: 0.7),
                width: 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFB300).withValues(alpha: 0.2),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Row(
              children: [
                // Animated Flame Avatar
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFB300), Color(0xFFFF3D00)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.4),
                          blurRadius: 12,
                        ),
                      ],
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Center(
                      child: Text('🔥', style: TextStyle(fontSize: 28)),
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            'DAY $_currentStreak STREAK',
                            style: GoogleFonts.dynaPuff(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD54F).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFFFD54F),
                                width: 1.2,
                              ),
                            ),
                            child: Text(
                              'CYCLE $_streakCycle',
                              style: GoogleFonts.dynaPuff(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFFFD54F),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _isTodayClaimed
                            ? '✅ Today claimed! Come back tomorrow for Day ${_currentStreak >= 7 ? 1 : _currentStreak + 1}!'
                            : '⚡ Claim your Day $_currentStreak reward (+$currentDayCoins Coins)!',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: _isTodayClaimed
                              ? const Color(0xFF00E676)
                              : const Color(0xFFFFD54F),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 7-Day Rewards Calendar Grid
          // Days 1-6 in a 3-column Grid, and Day 7 as a full-width Mega Chest!
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio:
                  MediaQuery.of(context).size.width < 360 ? 0.76 : 0.82,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              final item = _streakRewards[index];
              return _buildStreakDayCard(item);
            },
          ),

          const SizedBox(height: 10),

          // Day 7 Mega Chest VIP Card
          _buildDay7MegaChestCard(_streakRewards[6]),

          const SizedBox(height: 18),

          // Big Claim Button - Responsive & Clean on all screens
          _isTodayClaimed
              ? App3DButton.grey(
                  text: 'ALREADY CLAIMED TODAY',
                  width: double.infinity,
                  height: 54,
                  onPressed: null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF00E676),
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'ALREADY CLAIMED TODAY',
                              style: GoogleFonts.dynaPuff(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFFCFD8DC),
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'Come back tomorrow for Day ${_currentStreak >= 7 ? 1 : _currentStreak + 1} reward',
                              style: GoogleFonts.outfit(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF90A4AE),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : App3DButton.amber(
                  text: 'CLAIM DAY $_currentStreak REWARD',
                  width: double.infinity,
                  height: 54,
                  isLoading: _isClaimingStreak,
                  onPressed: _isClaimingStreak ? null : _claimStreakReward,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🎁', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'CLAIM DAY $_currentStreak REWARD (+$currentDayCoins 🪙)',
                            style: GoogleFonts.dynaPuff(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF1E0A00),
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  String _getDayRewardIcon(int day) {
    switch (day) {
      case 1:
        return '🪙';
      case 2:
        return '💰';
      case 3:
        return '💎';
      case 4:
        return '🎁';
      case 5:
        return '🏆';
      case 6:
        return '🧰';
      case 7:
        return '👑';
      default:
        return '🪙';
    }
  }

  Widget _buildStreakDayCard(Map<String, dynamic> item) {
    final int day = item['day'] as int;
    final int coins = item['coins'] as int;
    final String status = item['status'] as String;
    final bool isAvailable = status == 'available';
    final bool isClaimed = status == 'claimed';
    final bool isLocked = status == 'locked';

    // Determine if this card is tomorrow's upcoming reward
    final int nextDay = _isTodayClaimed
        ? (_currentStreak >= 7 ? 1 : _currentStreak + 1)
        : (_currentStreak >= 7 ? 1 : _currentStreak + 1);
    final bool isTomorrow = isLocked && (day == nextDay);

    final String dayIcon = _getDayRewardIcon(day);

    return GestureDetector(
      onTap: () {
        if (isAvailable && !_isClaimingStreak) {
          _claimStreakReward();
        } else if (isTomorrow) {
          Fluttertoast.showToast(
            msg: "🔒 Day $day unlocks tomorrow! Come back to claim +$coins Coins!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
          );
        } else if (isLocked) {
          Fluttertoast.showToast(
            msg: "🔒 Day $day reward: +$coins Coins! Keep your daily streak going!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isAvailable
                ? [const Color(0xFF381504), const Color(0xFF1E0A00)]
                : isClaimed
                    ? [const Color(0xFF06331C), const Color(0xFF031A0E)]
                    : isTomorrow
                        ? [const Color(0xFF280B45), const Color(0xFF140326)]
                        : [
                            Colors.white.withValues(alpha: 0.08),
                            Colors.white.withValues(alpha: 0.03),
                          ],
          ),
          border: Border.all(
            color: isAvailable
                ? const Color(0xFFFFD54F)
                : isClaimed
                    ? const Color(0xFF00E676)
                    : isTomorrow
                        ? const Color(0xFF00E5FF).withValues(alpha: 0.8)
                        : Colors.white.withValues(alpha: 0.14),
            width: isAvailable ? 2.2 : (isTomorrow ? 1.6 : 1.2),
          ),
          boxShadow: isAvailable
              ? [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.35),
                    blurRadius: 10,
                  ),
                ]
              : isTomorrow
                  ? [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Day Header Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isAvailable
                    ? const Color(0xFFFFD54F)
                    : isClaimed
                        ? const Color(0xFF00E676)
                        : isTomorrow
                            ? const Color(0xFF00E5FF)
                            : Colors.white12,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isTomorrow ? 'TOMORROW' : 'DAY $day',
                style: GoogleFonts.dynaPuff(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  color: (isAvailable || isClaimed || isTomorrow)
                      ? Colors.black
                      : Colors.white,
                ),
              ),
            ),

            // Central Reward Item with Lock indicator for excitement!
            SizedBox(
              width: 54,
              height: 48,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // The actual exciting reward icon!
                  Center(
                    child: Text(
                      dayIcon,
                      style: TextStyle(
                        fontSize: 28,
                        shadows: isTomorrow || isAvailable
                            ? [
                                Shadow(
                                  color: isTomorrow
                                      ? const Color(0xFF00E5FF)
                                      : Colors.amber,
                                  blurRadius: 10,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),

                  // If claimed, show checkmark badge
                  if (isClaimed)
                    Positioned(
                      right: 1,
                      bottom: 1,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E676),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 1.5),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x6600E676),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.check,
                            size: 11,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),

                  // If locked (or tomorrow), show lock badge so user knows it's locked but can see the reward!
                  if (isLocked)
                    Positioned(
                      right: 1,
                      top: 1,
                      child: Container(
                        width: 19,
                        height: 19,
                        decoration: BoxDecoration(
                          gradient: isTomorrow
                              ? const LinearGradient(
                                  colors: [Color(0xFF00E5FF), Color(0xFF0091EA)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : const LinearGradient(
                                  colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF16032B),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isTomorrow ? const Color(0xFF00E5FF) : Colors.amber)
                                  .withValues(alpha: 0.5),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.lock_rounded,
                            size: 11,
                            color: isTomorrow ? Colors.black : const Color(0xFF2E1500),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Coin Amount & Status Text
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 3),
                    Text(
                      '$coins',
                      style: GoogleFonts.dynaPuff(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: isAvailable
                            ? const Color(0xFFFFD54F)
                            : isClaimed
                                ? const Color(0xFF00E676)
                                : isTomorrow
                                    ? const Color(0xFF00E5FF)
                                    : Colors.white70,
                      ),
                    ),
                  ],
                ),
                Text(
                  isClaimed
                      ? 'Claimed'
                      : isAvailable
                          ? 'READY!'
                          : isTomorrow
                              ? 'TOMORROW'
                              : 'Locked',
                  style: GoogleFonts.outfit(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: isClaimed
                        ? const Color(0xFF00E676)
                        : isAvailable
                            ? const Color(0xFFFFD54F)
                            : isTomorrow
                                ? const Color(0xFF00E5FF)
                                : Colors.white38,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDay7MegaChestCard(Map<String, dynamic> item) {
    final String status = item['status'] as String? ?? 'locked';
    final bool isClaimed = status == 'claimed';
    final bool isAvailable = status == 'available';
    final bool isTomorrow = !isClaimed && !isAvailable && (_currentStreak == 6);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: isTomorrow
              ? const [Color(0xFF450D59), Color(0xFF1A0326)]
              : const [Color(0xFF380845), Color(0xFF1E0329)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isTomorrow
              ? const Color(0xFF00E5FF)
              : const Color(0xFFFFD700),
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isTomorrow
                ? const Color(0xFF00E5FF).withValues(alpha: 0.3)
                : const Color(0xFFFFD700).withValues(alpha: 0.25),
            blurRadius: 18,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isTomorrow
                    ? const [Color(0xFF00E5FF), Color(0xFF7C4DFF)]
                    : const [Color(0xFFFFD700), Color(0xFFFF8F00)],
              ),
              boxShadow: [
                BoxShadow(
                  color: isTomorrow
                      ? const Color(0xFF00E5FF).withValues(alpha: 0.4)
                      : Colors.amber.withValues(alpha: 0.4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Center(
              child: Text('👑', style: TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'DAY 7 • MEGA CHEST',
                        style: GoogleFonts.dynaPuff(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: isTomorrow
                              ? const Color(0xFF00E5FF)
                              : const Color(0xFFFFD700),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: isTomorrow
                            ? const Color(0xFF00E5FF).withValues(alpha: 0.2)
                            : Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isTomorrow ? const Color(0xFF00E5FF) : Colors.redAccent,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        isTomorrow ? 'NEXT' : 'VIP',
                        style: GoogleFonts.dynaPuff(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          color: isTomorrow ? const Color(0xFF00E5FF) : Colors.redAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  isClaimed
                      ? '🎉 Grand Champion Chest Claimed!'
                      : isAvailable
                          ? '🔥 Day 7 Ready! Tap below to claim 1,200 Coins!'
                          : isTomorrow
                              ? '⭐ Unlocks Tomorrow! Get ready for +1,200 Coins!'
                              : '${7 - _currentStreak} days streak remaining to unlock!',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: isTomorrow ? FontWeight.w700 : FontWeight.w500,
                    color: isTomorrow
                        ? const Color(0xFF00E5FF)
                        : Colors.white.withValues(alpha: 0.75),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Big Prize Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isTomorrow
                    ? const Color(0xFF00E5FF)
                    : const Color(0xFFFFD700),
                width: 1.4,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isClaimed
                      ? Icons.check_circle_rounded
                      : isAvailable
                          ? Icons.lock_open_rounded
                          : Icons.lock_rounded,
                  color: isTomorrow
                      ? const Color(0xFF00E5FF)
                      : const Color(0xFFFFD700),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  isTomorrow ? 'TOMORROW' : '+1,200 🪙',
                  style: GoogleFonts.dynaPuff(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: isTomorrow
                        ? const Color(0xFF00E5FF)
                        : const Color(0xFFFFD700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎯 TAB 1: COMBINED DAILY TASKS (BOUNTY BOARD)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDailyTasksTab() {
    final completedCount =
        _dailyTasks.where((t) => t['isCompleted'] == true).length;
    final totalCount = _dailyTasks.length;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
      child: Column(
        children: [
          // Tactical Quests Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                colors: [Color(0xFF00384D), Color(0xFF001B26)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.7),
                width: 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00E5FF), Color(0xFF0091EA)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                        blurRadius: 12,
                      ),
                    ],
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.track_changes_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DAILY PUZZLE BOUNTIES',
                        style: GoogleFonts.dynaPuff(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Completed $completedCount / $totalCount Daily Quests',
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF80D8FF),
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: totalCount > 0
                              ? (completedCount / totalCount)
                              : 0.0,
                          minHeight: 6,
                          backgroundColor: Colors.white12,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF00E5FF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Quests List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _dailyTasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final task = _dailyTasks[index];
              return _buildTaskCard(task, index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task, int index) {
    final bool isCompleted = task['isCompleted'] as bool;
    final bool isClaimed = task['isClaimed'] as bool;
    final int total = (task['total'] as num?)?.toInt() ?? 1;
    final int rawProgress = (task['progress'] as num?)?.toInt() ?? 0;
    final int progress = math.min(rawProgress, total);
    final int coins = task['coins'] as int;
    final Color iconColor = task['iconColor'] as Color;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isClaimed
              ? const Color(0xFF00E676).withValues(alpha: 0.6)
              : isCompleted
                  ? const Color(0xFFFFD54F).withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.12),
          width: (isCompleted && !isClaimed) ? 1.8 : 1.2,
        ),
      ),
      child: Row(
        children: [
          // Icon Box
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: iconColor, width: 1.4),
            ),
            child: Icon(task['icon'] as IconData, color: iconColor, size: 22),
          ),

          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task['title'] as String,
                        style: GoogleFonts.dynaPuff(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text(
                          '+$coins',
                          style: GoogleFonts.dynaPuff(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFFFD54F),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  task['description'] as String,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 6),
                // Progress Bar & Count
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (progress / total).clamp(0.0, 1.0),
                          minHeight: 5,
                          backgroundColor: Colors.white12,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isCompleted
                                ? const Color(0xFF00E676)
                                : const Color(0xFF00E5FF),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$progress / $total',
                      style: GoogleFonts.dynaPuff(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Action Button with Fixed Width to prevent shrinking when loading
          SizedBox(
            width: 96,
            height: 36,
            child: isClaimed
                ? Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E676).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFF00E676), width: 1.2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF00E676),
                          size: 15,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'CLAIMED',
                          style: GoogleFonts.dynaPuff(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF00E676),
                          ),
                        ),
                      ],
                    ),
                  )
                : isCompleted
                    ? App3DButton.amber(
                        text: 'CLAIM',
                        icon: Icons.card_giftcard_rounded,
                        width: 96,
                        fontSize: 11,
                        height: 36,
                        isLoading: _claimingTaskId == task['taskKey'],
                        onPressed: (_claimingTaskId != null || _isSpinning)
                            ? null
                            : () => _claimTask(index),
                      )
                    : App3DButton.cyan(
                        text: 'GO',
                        icon: Icons.play_arrow_rounded,
                        width: 96,
                        fontSize: 11,
                        height: 36,
                        onPressed: () => _handleTaskNavigation(task),
                      ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎡 TAB 2: LUCKY SPIN WHEEL
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLuckyWheelTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 28),
      child: Column(
        children: [
          // Status Pill Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _hasFreeSpinToday
                    ? [const Color(0xFF421C00), const Color(0xFF240E00)]
                    : [Colors.white12, Colors.white10],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _hasFreeSpinToday
                    ? const Color(0xFFFFD54F)
                    : Colors.white24,
                width: 1.4,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.stars_rounded,
                  color: _hasFreeSpinToday
                      ? const Color(0xFFFFD54F)
                      : Colors.white60,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  _hasFreeSpinToday
                      ? '1 FREE DAILY SPIN READY!'
                      : 'FREE SPIN CONSUMED TODAY',
                  style: GoogleFonts.dynaPuff(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: _hasFreeSpinToday
                        ? const Color(0xFFFFD54F)
                        : Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 3D Spinning Wheel Canvas & Pointer
          Builder(
            builder: (context) {
              final double wheelSize =
                  (MediaQuery.of(context).size.width - 64).clamp(240.0, 290.0);
              return SizedBox(
                width: wheelSize,
                height: wheelSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Wheel Rotation
                    AnimatedBuilder(
                      animation: _wheelController,
                      builder: (context, _) {
                        final angle = (_wheelController.isAnimating &&
                                _wheelAnimation != null)
                            ? _wheelAnimation!.value
                            : _currentWheelAngle;

                        return Transform.rotate(
                          angle: angle,
                          child: CustomPaint(
                            size: Size(wheelSize - 10, wheelSize - 10),
                            painter: _InteractiveWheelPainter(
                              sectors: _wheelSectors,
                            ),
                          ),
                        );
                      },
                    ),

                // Center Spin Medallion with Rotary Icon
                GestureDetector(
                  onTap: _isSpinning
                      ? null
                      : () => _spinWheel(
                            buttonType: _hasFreeSpinToday ? 'free' : 'ad',
                          ),
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [
                          Color(0xFFFFFDE7),
                          Color(0xFFFFD54F),
                          Color(0xFFFF8F00),
                        ],
                      ),
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.rotate_right_rounded,
                            size: 19,
                            color: Color(0xFF2E1500),
                          ),
                          Text(
                            'SPIN',
                            style: GoogleFonts.dynaPuff(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF2E1500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Top Pointer Needle
                Positioned(
                  top: 0,
                  child: CustomPaint(
                    size: const Size(24, 28),
                    painter: _WheelPointerPainter(),
                  ),
                ),
              ],
            ),
          );
        },
      ),

          const SizedBox(height: 20),

          // Spin Buttons Stack with Icons
          Row(
            children: [
              // Free Spin / Ad Spin Button
              Expanded(
                child: _hasFreeSpinToday
                    ? App3DButton.amber(
                        text: 'FREE SPIN',
                        icon: Icons.auto_awesome_rounded,
                        height: 48,
                        fontSize: 12.5,
                        isLoading: _spinningButton == 'free',
                        onPressed: _isSpinning
                            ? null
                            : () => _spinWheel(buttonType: 'free'),
                      )
                    : App3DButton.green(
                        text: 'AD SPIN ($_adSpinsRemaining/3)',
                        icon: Icons.play_circle_fill_rounded,
                        height: 48,
                        fontSize: 11.5,
                        isLoading: _spinningButton == 'ad',
                        onPressed: (_isSpinning || _adSpinsRemaining <= 0)
                            ? null
                            : () => _spinWheel(buttonType: 'ad'),
                      ),
              ),

              const SizedBox(width: 12),

              // Spin for 100 Coins Button
              Expanded(
                child: App3DButton.purple(
                  text: 'SPIN 100',
                  icon: Icons.monetization_on_rounded,
                  coinBadge: true,
                  height: 48,
                  fontSize: 12.5,
                  isLoading: _spinningButton == 'coin',
                  onPressed: _isSpinning
                      ? null
                      : () => _spinWheel(buttonType: 'coin'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Fair RNG & Prize Highlights with Icons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPrizeChip(icon: '🪙', label: '50-600 Coins'),
                Container(width: 1, height: 16, color: Colors.white24),
                _buildPrizeChip(icon: '💡', label: 'Free Hints'),
                Container(width: 1, height: 16, color: Colors.white24),
                _buildPrizeChip(icon: '👑', label: '1,200 Jackpot', isGold: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrizeChip({
    required String icon,
    required String label,
    bool isGold = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.dynaPuff(
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
            color: isGold ? const Color(0xFFFFD54F) : Colors.white70,
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 🎡 INTERACTIVE WHEEL PAINTER
// ═════════════════════════════════════════════════════════════════════════════

class _InteractiveWheelPainter extends CustomPainter {
  final List<Map<String, dynamic>> sectors;

  _InteractiveWheelPainter({required this.sectors});

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2.0;
    final double cy = size.height / 2.0;
    final double radius = size.width / 2.0 - 6.0;
    final Offset center = Offset(cx, cy);

    // Drop shadow
    canvas.drawCircle(
      center.translate(0, 4),
      radius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    final Rect wheelRect = Rect.fromCircle(center: center, radius: radius);
    final int sectorCount = sectors.length;
    final double sweep = 2.0 * math.pi / sectorCount;

    // Draw Slices
    for (int i = 0; i < sectorCount; i++) {
      final double startAngle = i * sweep;
      final Color color = sectors[i]['color'] as Color;

      final Paint sectorPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawArc(wheelRect, startAngle, sweep, true, sectorPaint);
    }

    // Spokes
    final Paint spokePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.65)
      ..strokeWidth = 1.4;

    for (int i = 0; i < sectorCount; i++) {
      final double ang = i * sweep;
      canvas.drawLine(
        center,
        Offset(cx + radius * math.cos(ang), cy + radius * math.sin(ang)),
        spokePaint,
      );
    }

    // Outer Bezel Rim
    final Paint bezelPaint = Paint()
      ..shader = SweepGradient(
        colors: const [
          Color(0xFFFFD54F),
          Color(0xFFFF8F00),
          Color(0xFFFFF9C4),
          Color(0xFFFF6D00),
          Color(0xFFFFD54F),
        ],
      ).createShader(wheelRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.6;
    canvas.drawCircle(center, radius, bezelPaint);

    // Light Bulbs on Bezel
    final Paint bulbPaint = Paint()..color = const Color(0xFFFFFDE7);
    for (int i = 0; i < sectorCount; i++) {
      final double ang = i * sweep + (sweep / 2.0);
      final Offset bulbPos = Offset(
        cx + (radius - 1.8) * math.cos(ang),
        cy + (radius - 1.8) * math.sin(ang),
      );
      canvas.drawCircle(bulbPos, 2.0, bulbPaint);
    }

    // Slice Text, Icons & Badges
    for (int i = 0; i < sectorCount; i++) {
      final double midAngle = i * sweep + (sweep / 2.0);
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(midAngle + math.pi / 2);

      final sector = sectors[i];
      final String label = sector['label'] as String;
      final String icon = (sector['icon'] as String?) ?? '🪙';
      final bool isJackpot = sector['type'] == 'jackpot';

      // 1. Draw Icon / Emoji near outer rim
      final iconTp = TextPainter(
        text: TextSpan(
          text: icon,
          style: TextStyle(
            fontSize: isJackpot ? 15.0 : 13.0,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      iconTp.paint(canvas, Offset(-iconTp.width / 2, -radius * 0.81));

      // 2. Draw Text Label below icon
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: GoogleFonts.dynaPuff(
            fontSize: isJackpot ? 8.5 : 9.5,
            fontWeight: FontWeight.w900,
            color: isJackpot ? const Color(0xFF2E1500) : Colors.white,
            shadows: isJackpot
                ? null
                : const [
                    Shadow(
                      color: Colors.black87,
                      offset: Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 55);

      tp.paint(canvas, Offset(-tp.width / 2, -radius * 0.58));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _InteractiveWheelPainter oldDelegate) => false;
}

// ═════════════════════════════════════════════════════════════════════════════
// 🔻 WHEEL POINTER PAINTER
// ═════════════════════════════════════════════════════════════════════════════

class _WheelPointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    // Shadow
    canvas.drawPath(
      path.shift(const Offset(0, 2)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    // Gold Needle
    final Paint paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFD54F), Color(0xFFFF6D00)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(path, paint);

    // Border
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFFFF9C4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _WheelPointerPainter oldDelegate) => false;
}
