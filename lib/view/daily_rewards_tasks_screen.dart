import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
import 'package:word_puzzle/widget/coin_grant_dialog.dart';
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
  final GlobalKey<CoinGrantOverlayState> _coinGrantKey =
      GlobalKey<CoinGrantOverlayState>();
  final GlobalKey _topCoinKey = GlobalKey();

  late final TabController _tabController;
  late final ConfettiController _confettiController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  // ── Wheel Spin Controller & State ──
  late final AnimationController _wheelController;
  late final AnimationController _fastSpinController;
  late final AnimationController _flapperController;
  late final Animation<double> _flapperAnimation;
  Animation<double>? _wheelAnimation;
  double _currentWheelAngle = 0.0;
  String? _spinningButton; // null | 'free' | 'ad' | 'coin'
  bool get _isSpinning => _spinningButton != null;
  bool get _isBusy =>
      _isSpinning ||
      _isRewardDialogActive ||
      _isClaimingStreak ||
      _claimingTaskId != null;
  bool _hasFreeSpinToday = true;
  int _adSpinsRemaining = 3;

  // ── Streak State (UI) ──
  int _currentStreak = 1; // Default Day 1
  int _streakCycle = 1;
  bool _isTodayClaimed = false;
  bool _isClaimingStreak = false;
  String? _claimingTaskId;
  bool _isRewardDialogActive = false;

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

  // ── Wheel Slices Configuration (8 Slices - ALL COINS) ──
  final List<Map<String, dynamic>> _wheelSectors = [
    {
      'label': '50',
      'valueText': '+50',
      'icon': Icons.monetization_on_rounded,
      'coins': 50,
      'color': const Color(0xFFFF5252),
      'colors': [const Color(0xFFFF8A80), const Color(0xFFD50000)], // Coral Crimson
      'type': 'coins',
    },
    {
      'label': '100',
      'valueText': '+100',
      'icon': Icons.monetization_on_rounded,
      'coins': 100,
      'color': const Color(0xFFFFB300),
      'colors': [const Color(0xFFFFE082), const Color(0xFFFF8F00)], // Vibrant Gold
      'type': 'coins',
    },
    {
      'label': '150',
      'valueText': '+150',
      'icon': Icons.monetization_on_rounded,
      'coins': 150,
      'color': const Color(0xFF00E5FF),
      'colors': [const Color(0xFF80D8FF), const Color(0xFF0091EA)], // Electric Sapphire
      'type': 'coins',
    },
    {
      'label': '250',
      'valueText': '+250',
      'icon': Icons.monetization_on_rounded,
      'coins': 250,
      'color': const Color(0xFFE040FB),
      'colors': [const Color(0xFFEA80FC), const Color(0xFFAA00FF)], // Royal Amethyst
      'type': 'coins',
    },
    {
      'label': '400',
      'valueText': '+400',
      'icon': Icons.monetization_on_rounded,
      'coins': 400,
      'color': const Color(0xFF00E676),
      'colors': [const Color(0xFFB9F6CA), const Color(0xFF00C853)], // Emerald Mint
      'type': 'coins',
    },
    {
      'label': '600',
      'valueText': '+600',
      'icon': Icons.monetization_on_rounded,
      'coins': 600,
      'color': const Color(0xFFFF9100),
      'colors': [const Color(0xFFFFD180), const Color(0xFFFF6D00)], // Sunset Amber
      'type': 'coins',
    },
    {
      'label': '800',
      'valueText': '+800',
      'icon': Icons.military_tech_rounded,
      'coins': 800,
      'color': const Color(0xFF1DE9B6),
      'colors': [const Color(0xFF64FFDA), const Color(0xFF00897B)], // Tropical Jade (replaced 2 HINTS)
      'type': 'coins',
    },
    {
      'label': '1,200',
      'valueText': '1200★',
      'icon': Icons.stars_rounded,
      'coins': 1200,
      'color': const Color(0xFFFF1744),
      'colors': [const Color(0xFFFF5252), const Color(0xFF880E4F)], // Brilliant Ruby Jackpot
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
      duration: const Duration(milliseconds: 2200),
    );
    _fastSpinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _flapperController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _flapperAnimation = Tween<double>(begin: 0.0, end: -0.28).animate(
      CurvedAnimation(parent: _flapperController, curve: Curves.easeOutBack),
    );
    _wheelAnimation =
        Tween<double>(begin: 0.0, end: 0.0).animate(_wheelController);

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

    // Handle nested `data` wrapper if present
    final Map<String, dynamic> root = (data['data'] is Map<String, dynamic>)
        ? Map<String, dynamic>.from(data['data'] as Map)
        : data;

    final streak = (root['streak'] ?? data['streak']) as Map<String, dynamic>? ?? {};
    final rawTasksList = (root['dailyTasks'] ??
        root['tasks'] ??
        data['dailyTasks'] ??
        data['tasks']) as List<dynamic>?;
    final spin = (root['spin'] ?? data['spin']) as Map<String, dynamic>? ?? {};
    final catalog = ((root['rewardsCatalog'] ?? data['rewardsCatalog'])
            as List<dynamic>?)
        ?.map((e) => Map<String, dynamic>.from(e as Map))
        .toList() ??
        [];

    final int currentDay = (streak['currentDay'] as num?)?.toInt() ?? 1;
    final int cycle = (streak['cycle'] as num?)?.toInt() ?? 1;
    final bool isTodayClaimed =
        _isTodayClaimed || ((streak['isTodayClaimed'] as bool?) ?? false);

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

    List<Map<String, dynamic>> tasks = [];
    if (rawTasksList != null && rawTasksList.isNotEmpty) {
      tasks = rawTasksList
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    // Assign appropriate icons to tasks and clamp progress to total
    if (tasks.isNotEmpty) {
      // Gather whether Wordix and Crossword have been played today
      int wordixProg = 0;
      int crossProg = 0;
      for (var task in tasks) {
        final k = (task['taskKey'] ?? task['key'])?.toString() ?? '';
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
        final key = (task['taskKey'] ?? task['key'])?.toString() ?? '';
        task['taskKey'] = key;
        final int total = (task['total'] as num?)?.toInt() ??
            (task['target'] as num?)?.toInt() ??
            1;

        // 🛡️ Lock: If task was already claimed locally in current state, never reset to unclaimed!
        final existingTask = _dailyTasks.firstWhere(
          (t) => (t['taskKey'] ?? t['key'])?.toString() == key,
          orElse: () => {},
        );
        final bool wasAlreadyClaimedLocally =
            existingTask['isClaimed'] == true;
        final isClaimed = wasAlreadyClaimedLocally ||
            task['isClaimed'] == true ||
            task['claimed'] == true;
        int rawProg = (task['progress'] as num?)?.toInt() ?? 0;

        if (isClaimed) {
          rawProg = total;
          task['isCompleted'] = true;
          task['isClaimed'] = true;
        } else if (key == 'word_master_duo') {
          rawProg = duoCalculatedProg;
          task['isCompleted'] = duoCalculatedProg >= 2;
          task['isClaimed'] = false;
        } else {
          task['isCompleted'] = (task['isCompleted'] == true) ||
              (task['completed'] == true) ||
              (rawProg >= total);
          task['isClaimed'] = false;
        }

        task['total'] = total;
        task['target'] = total;
        task['progress'] = math.min<int>(rawProg, total);
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
    // Fill title/desc/coins/gameScope fallback if missing from backend
    for (var def in _dailyTasks) {
      if (def['taskKey'] == key) {
        task['title'] ??= def['title'];
        task['description'] ??= def['description'];
        task['coins'] ??= def['coins'];
        task['gameScope'] ??= def['gameScope'];
        break;
      }
    }
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

  void _triggerFlapperWobble() {
    _flapperController.forward(from: 0.0).then((_) {
      if (mounted) _flapperController.reverse();
    });
  }

  @override
  void dispose() {
    _fastSpinController.dispose();
    _flapperController.dispose();
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
    if (_isTodayClaimed || _isClaimingStreak || _isRewardDialogActive) return;

    // Synchronously lock immediately so rapid double clicks do nothing
    setState(() {
      _isClaimingStreak = true;
      _isRewardDialogActive = true;
    });
    AudioHelper().playButtonSound();
    HapticFeedback.heavyImpact();

    try {
      final res = await DailyService().claimStreak(gameName: widget.gameName);

      if (!mounted) return;

      if (res['success'] == true) {
        final data = res['data'] ?? {};
        final claimedDay = (data['claimedDay'] as int?) ?? _currentStreak;
        final rewardCoins = (data['coinsAwarded'] as int?) ??
            _streakRewards[(claimedDay - 1).clamp(0, 6)]['coins'] as int;
        final newBalance = (data['newWalletBalance'] as num?)?.toInt();

        setState(() {
          _isTodayClaimed = true;
          _streakRewards[(claimedDay - 1).clamp(0, 6)]['status'] = 'claimed';
        });

        // Show unified reward dialog with COLLECT button and flying coins animation
        await _coinGrantKey.currentState?.showReward(
          coins: rewardCoins,
          source: 'Daily Streak',
          title: "DAY $claimedDay STREAK CLAIMED!",
          subtitle: "You've earned +$rewardCoins bonus coins!",
          newWalletBalance: newBalance,
        );

        // 🛡️ Await fresh data while keeping button locked until refresh finishes
        await _loadData();
      } else {
        if (res['message']?.toString().toLowerCase().contains('already') == true) {
          setState(() {
            _isTodayClaimed = true;
            _streakRewards[(_currentStreak - 1).clamp(0, 6)]['status'] = 'claimed';
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Already claimed today.'),
            backgroundColor: const Color(0xFFFF5252),
          ),
        );
        await _loadData();
      }
    } catch (e) {
      debugPrint("Error claiming streak: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isClaimingStreak = false;
          _isRewardDialogActive = false;
        });
      }
    }
  }

  void _claimTask(int index) async {
    if (_isRewardDialogActive || _claimingTaskId != null) return;

    final task = _dailyTasks[index];
    final taskKey = task['taskKey']?.toString() ?? '';
    if (task['isClaimed'] == true || task['isCompleted'] == false) {
      return;
    }

    // 🛡️ Synchronously lock this specific task AND lock all claims immediately
    // Keep task['isClaimed'] false until server responds so the button displays the circular loading spinner!
    setState(() {
      _claimingTaskId = taskKey;
      _isRewardDialogActive = true;
    });
    AudioHelper().playButtonSound();
    HapticFeedback.mediumImpact();

    try {
      final rewardCoins = (task['coins'] as int?) ?? 100;
      final res = await DailyService().claimTask(
        taskKey: taskKey,
        coins: rewardCoins,
        gameName: widget.gameName,
      );

      if (!mounted) return;

      if (res['success'] == true) {
        final data = res['data'] ?? {};
        final actualCoins = (data['coinsAwarded'] as int?) ?? rewardCoins;
        final newBalance = (data['newWalletBalance'] as num?)?.toInt();

        setState(() {
          task['isClaimed'] = true;
        });

        // Show unified reward dialog with COLLECT button and flying coins animation
        await _coinGrantKey.currentState?.showReward(
          coins: actualCoins,
          source: 'Daily Quest',
          title: "QUEST COMPLETED!",
          subtitle: "${task['title']}: +$actualCoins Coins added!",
          newWalletBalance: newBalance,
        );

        // 🛡️ Await fresh data before releasing lock
        await _loadData();
      } else {
        final msg = res['message']?.toString() ?? '';
        final bool isAlready = msg.toLowerCase().contains('already');
        setState(() {
          task['isClaimed'] = isAlready; // If already claimed, stay claimed; otherwise revert
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg.isNotEmpty ? msg : 'Task already claimed.'),
            backgroundColor: const Color(0xFFFF5252),
          ),
        );
        await _loadData();
      }
    } catch (e) {
      debugPrint("Error claiming task $taskKey: $e");
    } finally {
      if (mounted) {
        setState(() {
          _claimingTaskId = null;
          _isRewardDialogActive = false;
        });
      }
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
    else if (key == 'play_crossword' ||
        key == 'win_crossword' ||
        scope == 'crossword') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CrosswordSplashScreen()),
      );
    }
    // 3. Word Scramble tasks: Letter Unscrambler (play_scramble) & Master Speller (win_scramble)
    else if (key == 'play_scramble' ||
        key == 'win_scramble' ||
        scope == 'scramble') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ScrambleHomeScreen()),
      );
    }
    // 4. Balloon Rescue tasks: Balloon Savior (play_balloon) & Sky Guardian (win_balloon)
    else if (key == 'play_balloon' ||
        key == 'win_balloon' ||
        scope == 'balloon') {
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
      final wordixPlayed =
          (((wordixPlayTask['progress'] as num?)?.toInt() ?? 0) > 0) ||
              (((wordixWinTask['progress'] as num?)?.toInt() ?? 0) > 0);

      final crossPlayTask = _dailyTasks.firstWhere(
        (t) => t['taskKey'] == 'play_crossword',
        orElse: () => <String, dynamic>{},
      );
      final crossWinTask = _dailyTasks.firstWhere(
        (t) => t['taskKey'] == 'win_crossword',
        orElse: () => <String, dynamic>{},
      );
      final crossPlayed =
          (((crossPlayTask['progress'] as num?)?.toInt() ?? 0) > 0) ||
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
          updateWatchAdTask: true,
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
    if (_isBusy) return;

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
      // Deduct 100 coins locally (the backend spin endpoint '/api/daily/spin-wheel' deducts on server)
      coinProvider.creditCoinsLocally(-100);
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
    if (_isBusy) return;

    AudioHelper().playButtonSound();
    HapticFeedback.heavyImpact();

    setState(() {
      _spinningButton = buttonType;
      if (buttonType == 'free') {
        _hasFreeSpinToday = false;
      }
    });

    // 🚀 INSTANT 0ms SPIN: Wheel starts fast spinning immediately!
    _fastSpinController.repeat();

    // Concurrently request spin outcome from backend API in background
    final spinFuture = DailyService().spinWheel(
      spinType: buttonType == 'coin' ? 'coins' : buttonType,
      gameName: widget.gameName,
    );

    // Guarantee at least 1200ms of fast spin so it looks natural & exciting
    final results = await Future.wait([
      spinFuture,
      Future.delayed(const Duration(milliseconds: 1200)),
    ]);

    // Freeze current angle at the exact moment fast spin transitions to deceleration
    _currentWheelAngle =
        (_currentWheelAngle + _fastSpinController.value * 2 * math.pi) %
            (2 * math.pi);
    _fastSpinController.stop();
    _fastSpinController.reset();

    final spinRes = results[0] as Map<String, dynamic>;
    debugPrint('🎡 [SpinWheel] Backend response: $spinRes');

    int targetIndex = 1;
    int winCoins = 100;
    if (spinRes['success'] == true && spinRes['data'] != null) {
      final data = spinRes['data'] as Map<String, dynamic>;
      targetIndex = (data['sliceIndex'] as int?)?.clamp(0, 7) ?? 1;
      winCoins = (data['coinsAwarded'] as int?) ??
          (_wheelSectors[targetIndex]['coins'] as int);
      debugPrint('🎡 [SpinWheel] Server decided slice $targetIndex ($winCoins coins)');
    } else {
      debugPrint('🎡 [SpinWheel] Server error or offline, fallback to local RNG');
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
    const double arcAngle = 2 * math.pi / totalSectors;
    final double targetSectorAngle = (targetIndex * arcAngle) + (arcAngle / 2.0);

    final double targetOffset =
        ((2 * math.pi) - (targetSectorAngle % (2 * math.pi))) % (2 * math.pi);

    double currentMod = _currentWheelAngle % (2 * math.pi);
    if (currentMod < 0) currentMod += 2 * math.pi;

    double additionalAngle = (targetOffset - currentMod) % (2 * math.pi);
    if (additionalAngle < 0) additionalAngle += 2 * math.pi;

    // Add 4 full rotations for smooth, dramatic deceleration
    const double extraRotations = 4 * 2 * math.pi;
    final double totalRotation = extraRotations + additionalAngle;

    int lastTickSector = -1;
    _wheelAnimation = Tween<double>(
      begin: _currentWheelAngle,
      end: _currentWheelAngle + totalRotation,
    ).animate(
      CurvedAnimation(
        parent: _wheelController,
        curve: Curves.easeOutCubic,
      ),
    )..addListener(() {
        final currentRot = _wheelAnimation?.value ?? 0.0;
        final currentSector =
            ((currentRot / arcAngle).floor()) % totalSectors;
        if (currentSector != lastTickSector) {
          lastTickSector = currentSector;
          _triggerFlapperWobble();
          HapticFeedback.selectionClick();
        }
      });

    _wheelController.reset();
    _wheelController.forward().then((_) async {
      _currentWheelAngle = (_currentWheelAngle + totalRotation) % (2 * math.pi);

      if (!mounted) return;
      final spinData = spinRes['data'] as Map<String, dynamic>? ?? {};
      final newBalance = (spinData['newWalletBalance'] as num?)?.toInt();

      setState(() {
        _isRewardDialogActive = true;
      });

      // Report spin wheel task completion asynchronously in background (instant 0ms popup!)
      DailyService().updateTaskProgress(
        taskKey: 'spin_wheel_task',
        increment: 1,
        gameName: widget.gameName,
      ).then((_) {
        if (mounted) _loadData();
      });

      // Show unified reward dialog IMMEDIATELY with COLLECT button & flying coins animation
      try {
        await _coinGrantKey.currentState?.showReward(
          coins: winCoins,
          source: targetIndex == 7 ? 'Mega Jackpot' : 'Lucky Wheel',
          title: targetIndex == 7 ? "🏆 MEGA JACKPOT!" : "YOU WON!",
          subtitle: "+$winCoins Coins added to your wallet!",
          newWalletBalance: newBalance,
        );
      } finally {
        if (mounted) {
          setState(() {
            _spinningButton = null;
            _isRewardDialogActive = false;
          });
          _loadData();
        }
      }
    });
  }

  void _showRewardCelebrationDialog({
    required String title,
    required String subtitle,
    required int coins,
    required String iconEmoji,
    int? newWalletBalance,
  }) {
    _coinGrantKey.currentState?.showReward(
      coins: coins,
      source: 'Reward',
      title: title,
      subtitle: subtitle,
      newWalletBalance: newWalletBalance,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎨 BUILD METHOD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isBusy,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isSpinning) {
          Fluttertoast.showToast(
            msg: "Wheel is spinning! Please wait...",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
          );
        }
      },
      child: Scaffold(
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
                      physics: _isBusy
                          ? const NeverScrollableScrollPhysics()
                          : const BouncingScrollPhysics(),
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

            // 4. Coin Grant & Flying Coins Overlay
            Positioned.fill(
              child: CoinGrantOverlay(
                key: _coinGrantKey,
                targetKey: _topCoinKey,
                confettiController: _confettiController,
              ),
            ),
          ],
        ),
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
              if (_isBusy) return;
              AudioHelper().playButtonSound();
              Navigator.pop(context);
            },
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isBusy ? 0.35 : 1.0,
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
                key: _topCoinKey,
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
    return IgnorePointer(
      ignoring: _isBusy,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _isBusy ? 0.6 : 1.0,
        child: Container(
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
    ),
  ),
);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎁 TAB 0: 7-DAY STREAK REWARDS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStreakRewardsTab() {
    final currentDayCoins =
        _streakRewards[(_currentStreak - 1).clamp(0, 6)]['coins'] as int? ??
            100;

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
                              color: const Color(0xFFFFD54F)
                                  .withValues(alpha: 0.2),
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
                  onPressed: (_isTodayClaimed || _isClaimingStreak || _isRewardDialogActive) ? null : _claimStreakReward,
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
        return '🪙';
      case 3:
        return '🪙';
      case 4:
        return '🪙';
      case 5:
        return '🪙';
      case 6:
        return '🪙';
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
        if (isAvailable && !_isTodayClaimed && !_isClaimingStreak && !_isRewardDialogActive) {
          _claimStreakReward();
        } else if (isTomorrow) {
          Fluttertoast.showToast(
            msg:
                "🔒 Day $day unlocks tomorrow! Come back to claim +$coins Coins!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
          );
        } else if (isLocked) {
          Fluttertoast.showToast(
            msg:
                "🔒 Day $day reward: +$coins Coins! Keep your daily streak going!",
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
                                  colors: [
                                    Color(0xFF00E5FF),
                                    Color(0xFF0091EA)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFFFFD54F),
                                    Color(0xFFFF8F00)
                                  ],
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
                              color: (isTomorrow
                                      ? const Color(0xFF00E5FF)
                                      : Colors.amber)
                                  .withValues(alpha: 0.5),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.lock_rounded,
                            size: 11,
                            color: isTomorrow
                                ? Colors.black
                                : const Color(0xFF2E1500),
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
          color: isTomorrow ? const Color(0xFF00E5FF) : const Color(0xFFFFD700),
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
                          color: isTomorrow
                              ? const Color(0xFF00E5FF)
                              : Colors.redAccent,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        isTomorrow ? 'NEXT' : 'VIP',
                        style: GoogleFonts.dynaPuff(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          color: isTomorrow
                              ? const Color(0xFF00E5FF)
                              : Colors.redAccent,
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

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 360;
    final double titleFontSize = isSmallScreen ? 11.5 : 12.5;
    final double buttonWidth = isSmallScreen ? 76 : 82;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: iconColor, width: 1.4),
            ),
            child: Icon(task['icon'] as IconData, color: iconColor, size: 20),
          ),

          const SizedBox(width: 10),

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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                        style: GoogleFonts.dynaPuff(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 11)),
                        const SizedBox(width: 3),
                        Text(
                          '+$coins',
                          style: GoogleFonts.dynaPuff(
                            fontSize: isSmallScreen ? 11 : 12,
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: isSmallScreen ? 10 : 11,
                    color: Colors.white.withValues(alpha: 0.7),
                    height: 1.2,
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

          const SizedBox(width: 10),

          // Action Button with Responsive Width
          SizedBox(
            width: buttonWidth,
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
                          size: 14,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'CLAIMED',
                          style: GoogleFonts.dynaPuff(
                            fontSize: 9.5,
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
                        width: buttonWidth,
                        fontSize: isSmallScreen ? 10 : 10.5,
                        height: 36,
                        isLoading: _claimingTaskId == task['taskKey'],
                        onPressed: (isClaimed || _isRewardDialogActive || _claimingTaskId != null || _isSpinning)
                            ? null
                            : () => _claimTask(index),
                      )
                    : App3DButton.cyan(
                        text: 'GO',
                        icon: Icons.play_arrow_rounded,
                        width: buttonWidth,
                        fontSize: 11,
                        height: 36,
                        onPressed: () => _handleTaskNavigation(task),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildWheelSegmentCoin(int index, int itemCount, double size) {
    final anglePerItem = 2 * math.pi / itemCount;
    final midAngle = index * anglePerItem - math.pi / 2 + anglePerItem / 2;
    final wheelRadius = size / 2;
    final contentRadius = (wheelRadius - 11) * 0.38;

    return Transform.translate(
      offset: Offset(
        contentRadius * math.cos(midAngle),
        contentRadius * math.sin(midAngle),
      ),
      child: Image.asset(
        'assets/coin.png',
        width: 20,
        height: 20,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎡 TAB 2: LUCKY SPIN WHEEL (3D ARCADE CABINET DESIGN)
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

          // ── Animated 3D Wheel Assembly (Stand + Extrusion Base + Wheel + Mechanical Pointer) ──
          SizedBox(
            width: 284,
            height: 298,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                // 1. 3D Pedestal Stand behind the wheel
                Positioned(
                  bottom: 0,
                  child: CustomPaint(
                    size: const Size(284, 60),
                    painter: _Wheel3DStandPainter(),
                  ),
                ),

                // 2. 3D Cylindrical Extruded Base Ring (Bottom thickness)
                Positioned(
                  top: 14,
                  child: Container(
                    width: 270,
                    height: 270,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF8A2E00),
                          Color(0xFF521500),
                          Color(0xFF260800),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.65),
                          offset: const Offset(0, 10),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. Rotating 3D Wheel Drum Housing
                Positioned(
                  top: 8,
                  child: AnimatedBuilder(
                    animation: Listenable.merge(
                        [_wheelController, _fastSpinController]),
                    builder: (context, _) {
                      final double angle;
                      if (_wheelController.isAnimating &&
                          _wheelAnimation != null) {
                        angle = _wheelAnimation!.value;
                      } else if (_fastSpinController.isAnimating) {
                        angle = _currentWheelAngle +
                            _fastSpinController.value * 2 * math.pi;
                      } else {
                        angle = _currentWheelAngle;
                      }

                      return Transform.rotate(
                        angle: angle,
                        child: SizedBox(
                          width: 264,
                          height: 264,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                size: const Size(264, 264),
                                painter: _Wheel3DPainter(sectors: _wheelSectors),
                              ),
                              for (int i = 0; i < _wheelSectors.length; i++)
                                _buildWheelSegmentCoin(
                                    i, _wheelSectors.length, 264),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 4. Center Gold Hub (Stationary Center with 3D metallic bevel)
                Positioned(
                  top: 111,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _isBusy
                        ? null
                        : () => _spinWheel(
                              buttonType: _hasFreeSpinToday ? 'free' : 'ad',
                            ),
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [
                            Color(0xFFFFF9C4),
                            Color(0xFFFFEE58),
                            Color(0xFFFFB300),
                            Color(0xFFE65100),
                          ],
                        ),
                        border: Border.all(color: Colors.white, width: 2.6),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFB300).withValues(alpha: 0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                          const BoxShadow(
                            color: Colors.black54,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _isSpinning ? "..." : "SPIN",
                          style: GoogleFonts.dynaPuff(
                            color: const Color(0xFF2E1500),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 5. Heavy 3D Mechanical Pointer with Flapper Wobble at Top
                Positioned(
                  top: -6,
                  child: AnimatedBuilder(
                    animation: _flapperAnimation,
                    builder: (context, _) {
                      return CustomPaint(
                        size: const Size(40, 46),
                        painter: _PointerPainter(
                          deflectionAngle: _flapperAnimation.value,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
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
                        onPressed: _isBusy
                            ? null
                            : () => _spinWheel(buttonType: 'free'),
                      )
                    : App3DButton.green(
                        text: 'AD SPIN ($_adSpinsRemaining/3)',
                        icon: Icons.play_circle_fill_rounded,
                        height: 48,
                        fontSize: 11.5,
                        isLoading: _spinningButton == 'ad',
                        onPressed: (_isBusy || _adSpinsRemaining <= 0)
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
                  onPressed:
                      _isBusy ? null : () => _spinWheel(buttonType: 'coin'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Fair RNG & Prize Highlights with Icons (ALL COINS)
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
                _buildPrizeChip(icon: '⭐', label: '800 Super Win'),
                Container(width: 1, height: 16, color: Colors.white24),
                _buildPrizeChip(
                    icon: '👑', label: '1,200 Jackpot', isGold: true),
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
// 🎡 3D ARCADE PEDESTAL STAND PAINTER
// ═════════════════════════════════════════════════════════════════════════════

/// Sturdy 3D Arcade Pedestal Stand supporting the wheel from underneath
class _Wheel3DStandPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double bottomY = size.height;

    // 1. Drop shadow of the pedestal base
    final shadowPath = Path()
      ..moveTo(cx - 75, bottomY - 3)
      ..lineTo(cx + 75, bottomY - 3)
      ..lineTo(cx + 85, bottomY + 5)
      ..lineTo(cx - 85, bottomY + 5)
      ..close();
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.65)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // 2. Twin Angled Support Legs
    final leftLeg = Path()
      ..moveTo(cx - 36, bottomY - 48)
      ..lineTo(cx - 16, bottomY - 48)
      ..lineTo(cx - 42, bottomY - 8)
      ..lineTo(cx - 68, bottomY - 8)
      ..close();

    final rightLeg = Path()
      ..moveTo(cx + 16, bottomY - 48)
      ..lineTo(cx + 36, bottomY - 48)
      ..lineTo(cx + 68, bottomY - 8)
      ..lineTo(cx + 42, bottomY - 8)
      ..close();

    final legPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF380868), Color(0xFF1E0438), Color(0xFF0E011A)],
      ).createShader(Rect.fromLTWH(cx - 70, bottomY - 55, 140, 55))
      ..style = PaintingStyle.fill;
    canvas.drawPath(leftLeg, legPaint);
    canvas.drawPath(rightLeg, legPaint);

    final legBorderPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFD54F), Color(0xFFFFA000)],
      ).createShader(Rect.fromLTWH(cx - 70, bottomY - 55, 140, 55))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawPath(leftLeg, legBorderPaint);
    canvas.drawPath(rightLeg, legBorderPaint);

    // 3. Foot Platform Plate
    final footRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, bottomY - 8), width: 140, height: 14),
      const Radius.circular(7),
    );

    // Foot extrusion shadow
    canvas.drawRRect(
      footRect.shift(const Offset(0, 2.5)),
      Paint()..color = const Color(0xFF0A0014),
    );

    // Foot body
    canvas.drawRRect(
      footRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF501278), Color(0xFF260442)],
        ).createShader(footRect.outerRect),
    );

    // Foot gold rim
    canvas.drawRRect(
      footRect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFEE58), Color(0xFFFFA000), Color(0xFFFFD54F)],
        ).createShader(footRect.outerRect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Screws on foot plate
    final screwPaint = Paint()..color = const Color(0xFFFFD54F);
    canvas.drawCircle(Offset(cx - 52, bottomY - 8), 2.5, screwPaint);
    canvas.drawCircle(Offset(cx + 52, bottomY - 8), 2.5, screwPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═════════════════════════════════════════════════════════════════════════════
// 🎡 3D WHEEL DRUM PAINTER (8 COIN SECTORS, 3D MEDALLIONS & ARCADE BULBS)
// ═════════════════════════════════════════════════════════════════════════════

/// Custom painter to render the 8 sectors with 3D depth, arcade bulbs, and recessed badges
class _Wheel3DPainter extends CustomPainter {
  final List<Map<String, dynamic>> sectors;

  _Wheel3DPainter({required this.sectors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final arcAngle = 2 * math.pi / sectors.length;

    // 1. Deep 3D Outer Rim Casing
    final outerRingPaint = Paint()
      ..shader = const SweepGradient(
        colors: [
          Color(0xFFFFF9C4),
          Color(0xFFFFD54F),
          Color(0xFFFFA000),
          Color(0xFFE65100),
          Color(0xFFFFF9C4),
          Color(0xFFFFD54F),
          Color(0xFFFFA000),
          Color(0xFFFFF9C4),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    canvas.drawCircle(center, radius - 5, outerRingPaint);

    // Inner dark recessed groove behind the rim
    final groovePaint = Paint()
      ..color = const Color(0xFF0F001E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, radius - 10, groovePaint);

    // 2. 16 Illuminated Arcade Bulbs between sectors
    for (int i = 0; i < 16; i++) {
      final dotAngle = i * (2 * math.pi / 16) - math.pi / 2;
      final dotX = center.dx + (radius - 5) * math.cos(dotAngle);
      final dotY = center.dy + (radius - 5) * math.sin(dotAngle);
      final dotCenter = Offset(dotX, dotY);

      canvas.drawCircle(
        dotCenter,
        2.8,
        Paint()..color = const Color(0xFF381000),
      );
      final isGold = i % 2 == 0;
      final bulbPaint = Paint()
        ..shader = RadialGradient(
          colors: isGold
              ? [Colors.white, const Color(0xFFFFD54F), const Color(0xFFFF8F00)]
              : [Colors.white, const Color(0xFF80D8FF), const Color(0xFF0091EA)],
        ).createShader(Rect.fromCircle(center: dotCenter, radius: 2.0))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(dotCenter, 2.0, bulbPaint);
      canvas.drawCircle(
        Offset(dotX - 0.5, dotY - 0.5),
        0.6,
        Paint()..color = Colors.white,
      );
    }

    // 3. Sector Wedges with Radial Vignette Depth & Vibrant Jewel Palette
    final innerRadius = radius - 11;

    for (int i = 0; i < sectors.length; i++) {
      final startAngle = (i * arcAngle) - (math.pi / 2);
      final midAngle = startAngle + (arcAngle / 2);
      final sector = sectors[i];
      final List<Color> colors = (sector['colors'] as List<Color>?) ??
          [sector['color'] as Color, (sector['color'] as Color).withValues(alpha: 0.7)];

      // 3A. Radial shader: bright glossy luminous center, deep outer rim
      final segmentPaint = Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.95,
          colors: [
            Color.lerp(colors.first, Colors.white, 0.35)!,
            colors.first,
            colors.last,
          ],
          stops: const [0.0, 0.48, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: innerRadius));

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: innerRadius),
          startAngle,
          arcAngle,
          false,
        )
        ..close();
      canvas.drawPath(path, segmentPaint);

      // Inner Ambient Occlusion Shadow Arc near the outer rim (sunken compartment 3D depth)
      final shadowArc = Path()
        ..arcTo(
          Rect.fromCircle(center: center, radius: innerRadius),
          startAngle,
          arcAngle,
          false,
        );
      canvas.drawPath(
        shadowArc,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.black.withValues(alpha: 0.45),
              Colors.black.withValues(alpha: 0.0),
            ],
            stops: const [0.85, 1.0],
          ).createShader(Rect.fromCircle(center: center, radius: innerRadius))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8,
      );

      // 3B. 3D Metallic Golden Divider Rails along spoke boundaries
      final lineEndX = center.dx + innerRadius * math.cos(startAngle);
      final lineEndY = center.dy + innerRadius * math.sin(startAngle);

      // Deep Shadow line
      canvas.drawLine(
        center,
        Offset(lineEndX, lineEndY),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.55)
          ..strokeWidth = 3.2,
      );
      // Bright Golden Rail
      canvas.drawLine(
        center,
        Offset(lineEndX, lineEndY),
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFFFF9C4), Color(0xFFFFEE58), Color(0xFFFFA000)],
          ).createShader(Rect.fromPoints(center, Offset(lineEndX, lineEndY)))
          ..strokeWidth = 1.8,
      );
      // Specular highlight line
      canvas.drawLine(
        center,
        Offset(lineEndX, lineEndY),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.85)
          ..strokeWidth = 0.8,
      );

      // Brass peg stud on outer rim of each sector separator
      canvas.drawCircle(
        Offset(lineEndX, lineEndY),
        2.5,
        Paint()
          ..shader = const RadialGradient(
            colors: [Colors.white, Color(0xFFFFD54F), Color(0xFF6D2600)],
          ).createShader(
              Rect.fromCircle(center: Offset(lineEndX, lineEndY), radius: 2.5)),
      );

      // 3C. LOCAL ROTATION ALONG SPOKE: Aligns Token and Number Pill perfectly inside wedge!
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(midAngle);

      // 3C-1. 3D Golden Medallion Socket for the Coin at x = innerRadius * 0.38
      final double tokenX = innerRadius * 0.38;
      // Soft drop shadow
      canvas.drawCircle(
        Offset(tokenX, 1.5),
        14,
        Paint()..color = Colors.black.withValues(alpha: 0.45),
      );
      // Outer stepped golden bezel ring
      canvas.drawCircle(
        Offset(tokenX, 0),
        13.5,
        Paint()
          ..shader = const SweepGradient(
            colors: [
              Color(0xFFFFF9C4),
              Color(0xFFFFEE58),
              Color(0xFFFFA000),
              Color(0xFFE65100),
              Color(0xFFFFF9C4),
            ],
          ).createShader(Rect.fromCircle(center: Offset(tokenX, 0), radius: 13.5))
          ..style = PaintingStyle.fill,
      );
      // Inner deep glossy velvet medallion base
      canvas.drawCircle(
        Offset(tokenX, 0),
        11,
        Paint()
          ..shader = const RadialGradient(
            colors: [Color(0xFF280645), Color(0xFF10011C)],
          ).createShader(Rect.fromCircle(center: Offset(tokenX, 0), radius: 11)),
      );

      // 3C-2. 3D Prize Pill Badge at x = innerRadius * 0.67
      final double badgeX = innerRadius * 0.67;
      canvas.save();
      canvas.translate(badgeX, 0);
      canvas.rotate(math.pi / 2); // Facing the outer rim

      final badgeRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 42, height: 18),
        const Radius.circular(9),
      );

      // Badge drop shadow
      canvas.drawRRect(
        badgeRect.shift(const Offset(0, 2)),
        Paint()..color = Colors.black.withValues(alpha: 0.50),
      );

      // Badge deep glossy container body
      canvas.drawRRect(
        badgeRect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xEE1C0736), Color(0xFF0B0117)],
          ).createShader(badgeRect.outerRect)
          ..style = PaintingStyle.fill,
      );

      // Badge 3D golden bevel border
      canvas.drawRRect(
        badgeRect,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFFFF9C4), Color(0xFFFFD54F), Color(0xFFFFA000)],
          ).createShader(badgeRect.outerRect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3,
      );

      // Embossed Value Text
      final bool isJackpot = sector['type'] == 'jackpot';
      final String valText =
          (sector['valueText'] as String?) ?? (sector['label'] as String);
      final textSpan = TextSpan(
        text: valText,
        style: TextStyle(
          color: isJackpot ? const Color(0xFFFFD54F) : Colors.white,
          fontSize: isJackpot ? 10.0 : 11.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
          shadows: const [
            Shadow(color: Colors.black, offset: Offset(0, 1.5), blurRadius: 2),
          ],
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );

      canvas.restore(); // restore badge rotation
      canvas.restore(); // restore slice spoke rotation
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═════════════════════════════════════════════════════════════════════════════
// 🔻 3D MECHANICAL POINTER PAINTER WITH DYNAMIC FLAPPER HINGE
// ═════════════════════════════════════════════════════════════════════════════

/// Heavy 3D Mechanical Pointer Assembly with dynamic spring deflection angle
class _PointerPainter extends CustomPainter {
  final double deflectionAngle;

  const _PointerPainter({this.deflectionAngle = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double tipY = size.height;

    // 1. Golden Mounting Bracket Plate at top (y = 0 to 14)
    final bracketRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, 7), width: 38, height: 14),
      const Radius.circular(5),
    );

    // Bracket 3D extrusion
    canvas.drawRRect(
      bracketRect.shift(const Offset(0, 2)),
      Paint()..color = const Color(0xFF6B1B00),
    );

    // Bracket metallic gold body
    final bracketPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFF9C4),
          Color(0xFFFFEE58),
          Color(0xFFFFA000),
          Color(0xFFE65100),
        ],
      ).createShader(bracketRect.outerRect)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(bracketRect, bracketPaint);

    // Bracket 2 Screws
    for (final screwX in [cx - 13.0, cx + 13.0]) {
      final sCenter = Offset(screwX, 7);
      canvas.drawCircle(
        sCenter,
        2.2,
        Paint()..color = const Color(0xFF455A64),
      );
    }

    // 2. Dynamic Spring Hinge: Needle rotates around (cx, 14) with deflectionAngle
    canvas.save();
    canvas.translate(cx, 14);
    canvas.rotate(deflectionAngle);
    canvas.translate(-cx, -14);

    // Drop shadow onto wheel
    final shadowPath = Path()
      ..moveTo(cx + 2, tipY + 3)
      ..lineTo(cx - 14, 16)
      ..arcToPoint(Offset(cx + 14, 16),
          radius: const Radius.circular(14), clockwise: true)
      ..close();
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Left Facet (Light-facing Bright Emerald)
    final leftFacet = Path()
      ..moveTo(cx, tipY)
      ..lineTo(cx - 12, 16)
      ..arcToPoint(Offset(cx, 4),
          radius: const Radius.circular(12), clockwise: true)
      ..lineTo(cx, tipY)
      ..close();

    final leftPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFB9F6CA), Color(0xFF00E676), Color(0xFF00C853)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(leftFacet, leftPaint);

    // Right Facet (Shadow-facing Deep Emerald)
    final rightFacet = Path()
      ..moveTo(cx, tipY)
      ..lineTo(cx, 4)
      ..arcToPoint(Offset(cx + 12, 16),
          radius: const Radius.circular(12), clockwise: true)
      ..lineTo(cx, tipY)
      ..close();

    final rightPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomRight,
        colors: [Color(0xFF00A340), Color(0xFF00752E), Color(0xFF004D1E)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(rightFacet, rightPaint);

    // Center Crease Highlight
    canvas.drawLine(
      Offset(cx, tipY),
      Offset(cx, 4),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..strokeWidth = 0.9,
    );

    // Center Gold Pivot Stud on Hinge
    final pivotCenter = Offset(cx, 14);
    canvas.drawCircle(
      pivotCenter,
      4.2,
      Paint()
        ..shader = const RadialGradient(
          colors: [Colors.white, Color(0xFFFFD54F), Color(0xFFE65100)],
        ).createShader(Rect.fromCircle(center: pivotCenter, radius: 4.2)),
    );

    canvas.restore(); // restore deflection rotation
  }

  @override
  bool shouldRepaint(covariant _PointerPainter oldDelegate) =>
      oldDelegate.deflectionAngle != deflectionAngle;
}
