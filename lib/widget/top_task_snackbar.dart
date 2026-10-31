import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:word_puzzle/view/daily_rewards_tasks_screen.dart';
import 'package:word_puzzle/widget/sound.dart';

class TopTaskSnackBar {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;
  static final Set<String> _shownKeys = {};

  /// Mark task as already notified so it never shows again
  static void markNotified(String taskKey, String date) {
    _shownKeys.add('${taskKey}_$date');
  }

  /// Official 12 Daily Tasks catalog metadata
  static const Map<String, Map<String, dynamic>> taskCatalog = {
    'play_wordix': {'title': 'Word Finder', 'coins': 100},
    'win_wordix': {'title': 'Grid Conqueror', 'coins': 150},
    'play_crossword': {'title': 'Wheel Weaver', 'coins': 100},
    'win_crossword': {'title': 'Crossword Maestro', 'coins': 150},
    'play_scramble': {'title': 'Letter Unscrambler', 'coins': 100},
    'win_scramble': {'title': 'Master Speller', 'coins': 150},
    'play_balloon': {'title': 'Balloon Savior', 'coins': 100},
    'win_balloon': {'title': 'Sky Guardian', 'coins': 150},
    'word_master_duo': {'title': 'Dual Scholar', 'coins': 200},
    'use_hint': {'title': 'Clue Seeker', 'coins': 80},
    'spin_wheel_task': {'title': 'Fortune Seeker', 'coins': 50},
    'watch_ad': {'title': 'Bonus Hunter', 'coins': 80},
  };

  /// Show Top Snackbar when a daily task is completed (Guaranteed exactly 1 time)
  static void showTaskCompleted({
    required String taskKey,
    String? title,
    int? coins,
  }) {
    final now = DateTime.now();
    final todayStr =
        "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final debounceKey = '${taskKey}_$todayStr';

    // Strictly enforce: ONLY ONCE per task per day!
    if (_shownKeys.contains(debounceKey)) {
      return;
    }
    _shownKeys.add(debounceKey);

    final info = taskCatalog[taskKey];
    final displayTitle = title ?? info?['title'] as String? ?? 'Daily Quest Complete';
    final rewardCoins = coins ?? info?['coins'] as int? ?? 100;

    show(
      title: '🏆 DAILY TASK COMPLETED!',
      message: displayTitle,
      coinReward: rewardCoins,
      onTap: () {
        dismiss();
        final context = navigatorKey.currentContext;
        if (context != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const DailyRewardsTasksScreen(),
            ),
          );
        }
      },
    );
  }

  /// Show custom top snackbar
  static void show({
    required String title,
    required String message,
    int? coinReward,
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 4),
  }) {
    // Sound & Haptic
    try {
      AudioHelper().playWinnerSound();
      HapticFeedback.heavyImpact();
    } catch (_) {}

    final overlayState = navigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    // Dismiss existing snackbar cleanly
    dismiss();

    _currentEntry = OverlayEntry(
      builder: (context) => _TopSnackBarWidget(
        title: title,
        message: message,
        coinReward: coinReward,
        onTap: onTap,
        onDismiss: dismiss,
        duration: duration,
      ),
    );

    overlayState.insert(_currentEntry!);

    _dismissTimer = Timer(duration + const Duration(milliseconds: 400), () {
      dismiss();
    });
  }

  static void dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

class _TopSnackBarWidget extends StatefulWidget {
  final String title;
  final String message;
  final int? coinReward;
  final VoidCallback? onTap;
  final VoidCallback onDismiss;
  final Duration duration;

  const _TopSnackBarWidget({
    required this.title,
    required this.message,
    this.coinReward,
    this.onTap,
    required this.onDismiss,
    required this.duration,
  });

  @override
  State<_TopSnackBarWidget> createState() => _TopSnackBarWidgetState();
}

class _TopSnackBarWidgetState extends State<_TopSnackBarWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
      reverseDuration: const Duration(milliseconds: 300),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    ));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
  }

  void _hide() {
    if (mounted) {
      _controller.reverse().then((_) {
        widget.onDismiss();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top > 0 ? mediaQuery.padding.top : 24.0;

    return Positioned(
      top: topPadding + 8,
      left: 14,
      right: 14,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onVerticalDragUpdate: (details) {
            if (details.primaryDelta != null && details.primaryDelta! < -4) {
              _hide();
            }
          },
          onTap: () {
            _hide();
            widget.onTap?.call();
          },
          child: SlideTransition(
            position: _offsetAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF2E0854),
                        Color(0xFF16032B),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.8),
                      width: 1.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.35),
                        blurRadius: 18,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Glowing Trophy / Icon Badge
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFE082), Color(0xFFFFB300)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFB300).withValues(alpha: 0.6),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.emoji_events_rounded,
                            color: Color(0xFF3E1A00),
                            size: 26,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Text Info
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFFFFD54F),
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.message,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'Tap to claim your reward in Quests!',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Reward Badge / Claim Action
                      if (widget.coinReward != null && widget.coinReward! > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00E676), Color(0xFF00B0FF)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00E676).withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.monetization_on_rounded,
                                color: Color(0xFFFFD700),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '+${widget.coinReward}',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
