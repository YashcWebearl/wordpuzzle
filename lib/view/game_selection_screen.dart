import 'dart:math' as math;
import 'dart:ui';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word_puzzle/view/ad_show.dart';
import 'package:word_puzzle/view/welcome_screen.dart';
import 'package:word_puzzle/widget/app_3d_button.dart';
import 'package:word_puzzle/widget/coin_container.dart';
import 'package:word_puzzle/widget/coin_service.dart';
import 'package:word_puzzle/widget/get_level.dart';
import 'package:word_puzzle/widget/sound.dart';
import 'package:word_puzzle/wordix/home_screen.dart';
import 'package:word_puzzle/crossword/crossword_splash.dart';
import 'package:word_puzzle/crossword/crossword_logo.dart';
import 'package:word_puzzle/crossword/crossword_level_service.dart';
import 'package:word_puzzle/widget/coin_grant_dialog.dart';
import 'package:word_puzzle/view/daily_rewards_tasks_screen.dart';

/// Game representation model for the Selection Hub
class _GameItemModel {
  final String id;
  final String title;
  final String category;
  final String subtitle;
  final String badgeText;
  final Color badgeColor;
  final Color primaryColor;
  final Color secondaryColor;
  final List<Color> cardGradient;
  final bool isPlayable;
  final String? imagePath;
  final IconData fallbackIcon;
  final List<String> tags;
  final Map<String, String> quickStats;
  final List<String> features;
  final List<Color> buttonGradient;
  final Color buttonShadowColor;
  final Color buttonGlowColor;
  final Color buttonTextColor;

  const _GameItemModel({
    required this.id,
    required this.title,
    required this.category,
    required this.subtitle,
    required this.badgeText,
    required this.badgeColor,
    required this.primaryColor,
    required this.secondaryColor,
    required this.cardGradient,
    required this.isPlayable,
    this.imagePath,
    required this.fallbackIcon,
    required this.tags,
    required this.quickStats,
    required this.features,
    required this.buttonGradient,
    required this.buttonShadowColor,
    required this.buttonGlowColor,
    required this.buttonTextColor,
  });
}

class GameSelectionScreen extends StatefulWidget {
  const GameSelectionScreen({super.key});

  @override
  State<GameSelectionScreen> createState() => _GameSelectionScreenState();
}

class _GameSelectionScreenState extends State<GameSelectionScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<CoinGrantOverlayState> _coinGrantKey = GlobalKey();
  final GlobalKey _topCoinKey = GlobalKey();
  late final PageController _pageController;
  late final ConfettiController _confettiController;
  late final AnimationController _floatingWordsAnimController;

  int _currentPage = 0;
  String _userName = 'Puzzle Master';
  String _userEmail = 'player@wordpuzzle.com';
  bool _isSoundOn = true;
  bool _isPlayButtonTapped = false;

  final List<_GameItemModel> _games = const [
    _GameItemModel(
      id: 'wordix',
      title: 'WORDIX',
      category: 'WORD SEARCH',
      subtitle: 'Classic & Timed Word Search Grid Challenge',
      badgeText: 'PLAYABLE NOW',
      badgeColor: Color(0xFF00E676),
      primaryColor: Color(0xFF00E5FF),
      secondaryColor: Color(0xFF1DE9B6),
      cardGradient: [
        Color(0xFF0F3057),
        Color(0xFF00587A),
        Color(0xFF008891),
      ],
      isPlayable: true,
      imagePath: 'assets/icon/icon3.png',
      fallbackIcon: Icons.spellcheck_rounded,
      tags: [
        '🔤 Word Search',
        '🏆 100+ Levels',
        '🪙 Win Coins',
        '⏱️ Timed Mode'
      ],
      quickStats: {
        'TYPE': 'Grid Search',
        'LEVELS': '100+',
        'STATUS': 'Live',
      },
      features: [
        'Find hidden words across rows, columns & diagonals',
        'Progressive grid sizes from 4x4 up to 10x10',
        'Earn coins and unlock voyage achievements',
        'Helpful hint tools to discover challenging words',
      ],
      buttonGradient: [
        Color(0xFF00E5FF),
        Color(0xFF0091EA),
      ],
      buttonShadowColor: Color(0xFF00587A),
      buttonGlowColor: Color(0xFF00E5FF),
      buttonTextColor: Color(0xFF071B2C),
    ),
    _GameItemModel(
      id: 'crossword',
      title: 'CROSSWORD',
      category: 'WORD CONNECT',
      subtitle: 'Nature Word Connect & Crossword Challenge',
      badgeText: 'PLAY NOW',
      badgeColor: Color(0xFFFF9100),
      primaryColor: Color(0xFFFF7043),
      secondaryColor: Color(0xFFFFA726),
      cardGradient: [
        Color(0xFF1B4332),
        Color(0xFF2D6A4F),
        Color(0xFF40916C),
      ],
      isPlayable: true,
      imagePath: null,
      fallbackIcon: Icons.grid_4x4_rounded,
      tags: [
        '🧩 Crossword Grid',
        '🍂 Nature Theme',
        '🔄 Letter Wheel',
        '🏆 Level Voyage'
      ],
      quickStats: {
        'TYPE': 'Word Connect',
        'LEVELS': 'Unlimited',
        'STATUS': 'Live',
      },
      features: [
        'Connect letters in the circle wheel to form valid words',
        'Watch solved words fly up and fill crossword slots',
        'Calming animated woodland nature background with autumn leaves',
        'Earn stars, level up, and unlock hint rewards',
      ],
      buttonGradient: [
        Color(0xFFFF9100),
        Color(0xFFFF5722),
      ],
      buttonShadowColor: Color(0xFFBF360C),
      buttonGlowColor: Color(0xFFFF9100),
      buttonTextColor: Colors.white,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.84);
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));

    // Continuous floating words ambient animation controller
    _floatingWordsAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();

    _loadUser();
    _loadSoundSetting();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<GameLevelProvider>(context, listen: false).refresh();
        Provider.of<CoinProvider>(context, listen: false).getCoin();
        CrosswordLevelService.fetchLevel();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _confettiController.dispose();
    _floatingWordsAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadSoundSetting() async {
    await AudioHelper().initialize();
    if (mounted) {
      setState(() {
        _isSoundOn = AudioHelper().isSoundOn;
      });
    }
  }

  Future<void> _toggleSound() async {
    await AudioHelper().toggleSound();
    if (mounted) {
      setState(() {
        _isSoundOn = AudioHelper().isSoundOn;
      });
    }
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email')?.trim();
    final name = prefs.getString('user_name')?.trim();

    if (mounted) {
      setState(() {
        if (email != null && email.isNotEmpty) {
          _userEmail = email;
          if (name != null && name.isNotEmpty) {
            _userName = name;
          } else {
            final raw = email.split('@').first;
            final clean = raw.replaceAll(RegExp(r'[0-9]'), '').trim();
            _userName = clean.isNotEmpty
                ? clean[0].toUpperCase() + clean.substring(1)
                : raw;
          }
        }
      });
    }
  }

  Future<void> _addCoins(int coins, String source) async {
    try {
      await _coinGrantKey.currentState?.showReward(
        coins: coins,
        source: source,
      );
    } catch (e) {
      debugPrint("Error adding coins from $source: $e");
    }
  }

  void _onGameSelected(int index) async {
    if (_isPlayButtonTapped) return;
    final game = _games[index];

    if (game.isPlayable) {
      setState(() => _isPlayButtonTapped = true);
      HapticFeedback.mediumImpact();

      // Tactile 3D press-down delay matching crossword_home
      await Future.delayed(const Duration(milliseconds: 250));

      if (!mounted) return;
      final Widget targetScreen = game.id == 'crossword'
          ? const CrosswordSplashScreen()
          : const HomePage();

      await Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 350),
          pageBuilder: (_, __, ___) => targetScreen,
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.96, end: 1.0).animate(
                  CurvedAnimation(
                      parent: animation, curve: Curves.easeOutCubic),
                ),
                child: child,
              ),
            );
          },
        ),
      );

      if (mounted) {
        setState(() => _isPlayButtonTapped = false);
      }
    } else {
      _showComingSoonModal(game);
    }
  }

  void _showComingSoonModal(_GameItemModel game) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: BoxDecoration(
                color: const Color(0xFF101B2B).withOpacity(0.96),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border.all(
                  color: game.primaryColor.withOpacity(0.4),
                  width: 1.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: game.primaryColor.withOpacity(0.2),
                    blurRadius: 30,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          game.primaryColor.withOpacity(0.3),
                          Colors.transparent
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: game.primaryColor, width: 2),
                    ),
                    child: Center(
                      child: Icon(
                        game.fallbackIcon,
                        size: 42,
                        color: game.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: game.badgeColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: game.badgeColor, width: 1.2),
                    ),
                    child: Text(
                      '⏳ RELEASING SOON',
                      style: GoogleFonts.outfit(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                        color: game.badgeColor,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    game.title,
                    style: GoogleFonts.outfit(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    game.subtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 13.sp,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'UPCOMING HIGHLIGHTS',
                      style: GoogleFonts.outfit(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        color: game.primaryColor,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...game.features.map(
                    (feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 18,
                            color: game.primaryColor,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              feature,
                              style: GoogleFonts.outfit(
                                fontSize: 13.sp,
                                color: Colors.white.withOpacity(0.9),
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  App3DButton(
                    text: 'GOT IT! STAY TUNED 👍',
                    gradientColors: [game.primaryColor, game.secondaryColor],
                    shadowColor: const Color(0xFF1B0033),
                    glowColor: game.primaryColor,
                    textColor: const Color(0xFF0F172A),
                    height: 48,
                    depth: 3.5,
                    width: double.infinity,
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openDailyRewardsScreen(int initialTabIndex) {
    AudioHelper().playButtonSound();
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (_, __, ___) =>
            DailyRewardsTasksScreen(initialTabIndex: initialTabIndex),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _handleWatchAndEarn() {
    AudioHelper().playButtonSound();
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdPlaybackPage(
          isRewardAd: true,
          onAdComplete: () async {
            if (!mounted) return;
            const rewardCoins = 100;
            await _addCoins(rewardCoins, 'Watch & Earn');
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFF1E033A),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(
                    color: Color(0xFFFFD700),
                    width: 1.6,
                  ),
                ),
                content: Row(
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Text(
                      'Watched Ad! +$rewardCoins Coins Added!',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withOpacity(0.92),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.2), width: 1.5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5252).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: Color(0xFFFF5252),
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "SIGN OUT?",
                      style: GoogleFonts.outfit(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Are you sure you want to sign out from your account?",
                      style: GoogleFonts.outfit(
                        fontSize: 13.5.sp,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white30),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              AudioHelper().playButtonSound();
                              Navigator.pop(dialogContext);
                            },
                            child: Text(
                              "CANCEL",
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF5252),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () async {
                              AudioHelper().playButtonSound();
                              final prefs =
                                  await SharedPreferences.getInstance();

                              // Preserve daily reward claim history, sound & locale
                              final rewardKeys = prefs
                                  .getKeys()
                                  .where((k) =>
                                      k.startsWith('daily_reward_') ||
                                      k.startsWith('last_claim_date'))
                                  .toList();
                              final Map<String, String> preservedRewards = {};
                              for (final key in rewardKeys) {
                                final val = prefs.getString(key);
                                if (val != null) preservedRewards[key] = val;
                              }
                              final soundOn = prefs.getBool('sound_on');
                              final locale = prefs.getString('locale');

                              await prefs.clear();

                              for (final entry in preservedRewards.entries) {
                                await prefs.setString(entry.key, entry.value);
                              }
                              if (soundOn != null) {
                                await prefs.setBool('sound_on', soundOn);
                              }
                              if (locale != null) {
                                await prefs.setString('locale', locale);
                              }

                              try {
                                final GoogleSignIn googleSignIn =
                                    GoogleSignIn();
                                await googleSignIn.signOut();
                              } catch (e) {
                                debugPrint('Google sign out error: $e');
                              }

                              if (context.mounted) {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const WelcomeScreen(),
                                  ),
                                  (route) => false,
                                );
                              }
                            },
                            child: Text(
                              "LOGOUT",
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showExitDialog() {
    AudioHelper().playButtonSound();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1726).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: const Color(0xFFFF5252).withValues(alpha: 0.45),
                  width: 1.6,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF5252).withValues(alpha: 0.25),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5252).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFF5252).withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                    ),
                    child: const Icon(
                      Icons.exit_to_app_rounded,
                      color: Color(0xFFFF5252),
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "EXIT APP?",
                    style: GoogleFonts.outfit(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Are you sure you want to exit?",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 14.sp,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: App3DButton(
                          text: 'CANCEL',
                          gradientColors: const [
                            Color(0xFF334155),
                            Color(0xFF1E293B),
                          ],
                          shadowColor: const Color(0xFF0F172A),
                          glowColor: Colors.white24,
                          textColor: Colors.white70,
                          height: 46,
                          fontSize: 13.5.sp,
                          borderRadius: 16.0,
                          onPressed: () {
                            AudioHelper().playButtonSound();
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: App3DButton(
                          text: "EXIT",
                          icon: Icons.power_settings_new_rounded,
                          gradientColors: const [
                            Color(0xFFFF5252),
                            Color(0xFFC62828),
                          ],
                          shadowColor: const Color(0xFF8E0000),
                          glowColor: const Color(0xFFFF5252),
                          textColor: Colors.white,
                          height: 46,
                          fontSize: 13.5.sp,
                          borderRadius: 16,
                          onPressed: () => SystemNavigator.pop(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // DYNAMIC REACTIVE AMBIENT GRADIENT BACKGROUND (BLUE FOR WORDIX, ORANGE/PURPLE FOR CROSSWORD)
  // ===========================================================================
  Widget _buildAtmosphericBackground(_GameItemModel activeGame) {
    final bool isWordix = activeGame.id == 'wordix';

    final List<Color> gradientColors = isWordix
        ? const [
            Color(0xFF002B4E), // Deep cyber ocean
            Color(0xFF08192F), // Midnight navy
            Color(0xFF030914), // Dark obsidian abyss
          ]
        : const [
            Color(0xFF380E4B), // Deep royal violet
            Color(0xFF220835), // Dark twilight velvet
            Color(0xFF0C0216), // Dark obsidian
          ];

    final Color auraColor = isWordix
        ? const Color(0xFF00E5FF) // Electric cyan glow
        : const Color(0xFFFF9100); // Warm sunset amber/orange glow

    final Color secondaryAuraColor =
        isWordix ? const Color(0xFF0077C2) : const Color(0xFF9C27B0);

    return Positioned.fill(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Top ambient glowing radiant aura
            Positioned(
              top: -80,
              left: 0,
              right: 0,
              height: 380,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.4),
                    radius: 0.95,
                    colors: [
                      auraColor.withOpacity(0.32),
                      secondaryAuraColor.withOpacity(0.14),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Bottom subtle corner aura
            Positioned(
              bottom: -90,
              right: isWordix ? -60 : null,
              left: isWordix ? null : -60,
              width: 320,
              height: 320,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      (isWordix
                              ? const Color(0xFF00E676)
                              : const Color(0xFFFF5252))
                          .withOpacity(0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context);
    final activeGame = _games[_currentPage];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _showExitDialog();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: _buildDrawer(),
        body: Stack(
          children: [
            // 1. Dynamic Reactive Gradient Background (Oceanic Blue for Wordix, Sunset Orange/Purple for Crossword)
            _buildAtmosphericBackground(activeGame),

            // 2. Ambient Floating Animated Words & Letters Overlay (Preserved & Theme-Harmonized)
            _FloatingWordsBackground(
              controller: _floatingWordsAnimController,
              isWordix: _currentPage == 0,
            ),

            // 3. Main Content
            SafeArea(
              child: Column(
                children: [
                  // Top App Bar: Game Logo on Left (opens Drawer) & Coins on Right
                  _buildTopBar(),

                  const SizedBox(height: 8),

                  // Quick Switch Tabs
                  _buildGameQuickTabs(),

                  const SizedBox(height: 12),

                  // Main Games Carousel
                  Expanded(
                    child: _buildGamesCarousel(),
                  ),

                  const SizedBox(height: 10),

                  // Page Dots Indicator
                  _buildPageIndicators(),

                  const SizedBox(height: 14),
                ],
              ),
            ),

            // ── Floating Action Badges on Left: Watch Ad & Daily Spin ──
            Positioned(
              left: 14,
              bottom: 12 + MediaQuery.of(context).padding.bottom,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CircularFloatingBadge(
                    label: "Watch Ad",
                    labelGradient: const [
                      Color(0xFFFFB300),
                      Color(0xFFFF6F00),
                    ],
                    icon: const _AnimatedWatchAdVideoIcon(),
                    onTap: _handleWatchAndEarn,
                  ),
                  const SizedBox(height: 6),
                  _CircularFloatingBadge(
                    label: "Daily Spin",
                    labelGradient: const [
                      Color(0xFFAB47BC),
                      Color(0xFF6A1B9A),
                    ],
                    icon: const _AnimatedSpinWheelIcon(),
                    onTap: () => _openDailyRewardsScreen(2),
                  ),
                ],
              ),
            ),

            // ── Floating Action Badges on Right: Daily Task & Daily Reward ──
            Positioned(
              right: 14,
              bottom: 12 + MediaQuery.of(context).padding.bottom,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CircularFloatingBadge(
                    label: "Daily Task",
                    labelGradient: const [
                      Color(0xFFFF5252),
                      Color(0xFFC62828),
                    ],
                    icon: const _AnimatedDailyTaskTargetIcon(),
                    onTap: () => _openDailyRewardsScreen(1),
                  ),
                  const SizedBox(height: 6),
                  _CircularFloatingBadge(
                    label: "Daily Reward",
                    labelGradient: const [
                      Color(0xFFFF9800),
                      Color(0xFFE65100),
                    ],
                    icon: const _AnimatedDailyRewardGiftIcon(),
                    onTap: () => _openDailyRewardsScreen(0),
                  ),
                ],
              ),
            ),

            // Confetti Overlay
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
                  Colors.white,
                ],
                numberOfParticles: 35,
              ),
            ),

            // Coin Grant & Flying Coins Overlay
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

  // ===========================================================================
  // TOP BAR: ROUND GAME ICON MENU (OPENS DRAWER) & COIN CAPSULE
  // ===========================================================================
  Widget _buildTopBar() {
    final activeColor = _games[_currentPage].primaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Game Logo Circular Button to open Drawer
          GestureDetector(
            onTap: () {
              AudioHelper().playButtonSound();
              _scaffoldKey.currentState?.openDrawer();
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: activeColor.withOpacity(0.7),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: activeColor.withOpacity(0.25),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0F3057),
                      border: Border.all(color: Colors.white38, width: 1),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/icon/icon3.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.extension_rounded,
                          color: activeColor,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Coins Display on right (Settings icon removed)
          CoinBalanceWidget(key: _topCoinKey),
        ],
      ),
    );
  }

  // ===========================================================================
  // SIDE DRAWER: USER PROFILE (NAME & EMAIL) + SETTINGS (SOUND & LOGOUT)
  // ===========================================================================
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0A192F),
                  Color(0xFF0F2B48),
                  Color(0xFF081426),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius:
                  const BorderRadius.horizontal(right: Radius.circular(32)),
              border: Border.all(
                color: const Color(0xFF00E5FF).withOpacity(0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 30,
                  offset: const Offset(6, 0),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // User Profile Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // Avatar
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00E5FF), Color(0xFF7C4DFF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(color: Colors.white, width: 2.2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00E5FF).withOpacity(0.4),
                                blurRadius: 18,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _userName.isNotEmpty
                                  ? _userName[0].toUpperCase()
                                  : 'P',
                              style: GoogleFonts.outfit(
                                fontSize: 36.sp,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // User Name
                        Text(
                          _userName,
                          style: GoogleFonts.outfit(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.6,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),

                        // Email ID
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Text(
                            _userEmail,
                            style: GoogleFonts.outfit(
                              fontSize: 12.sp,
                              color: Colors.white.withOpacity(0.85),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  Divider(color: Colors.white.withOpacity(0.12), height: 1),
                  const SizedBox(height: 12),

                  // Settings Section Heading
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'SETTINGS & PREFERENCES',
                        style: GoogleFonts.outfit(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF00E5FF),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),

                  // Settings Menu Items
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      children: [
                        // Sound Effects Switch
                        _buildDrawerTile(
                          icon: _isSoundOn
                              ? Icons.volume_up_rounded
                              : Icons.volume_off_rounded,
                          iconColor: _isSoundOn
                              ? const Color(0xFF00E676)
                              : Colors.white60,
                          title: 'Sound Effects',
                          subtitle: _isSoundOn ? 'Enabled' : 'Muted',
                          trailing: Switch(
                            value: _isSoundOn,
                            activeColor: const Color(0xFF00E676),
                            onChanged: (val) {
                              AudioHelper().playButtonSound();
                              _toggleSound();
                            },
                          ),
                          onTap: () {
                            AudioHelper().playButtonSound();
                            _toggleSound();
                          },
                        ),

                        const SizedBox(height: 10),
                        Divider(
                            color: Colors.white.withOpacity(0.12), height: 1),
                        const SizedBox(height: 10),

                        // Logout Tile
                        _buildDrawerTile(
                          icon: Icons.logout_rounded,
                          iconColor: const Color(0xFFFF5252),
                          title: 'Sign Out',
                          subtitle: 'Log out from this account',
                          titleColor: const Color(0xFFFF5252),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded,
                              size: 14, color: Color(0xFFFF5252)),
                          onTap: () {
                            AudioHelper().playButtonSound();
                            Navigator.pop(context); // Close drawer
                            _showLogoutConfirmationDialog();
                          },
                        ),
                      ],
                    ),
                  ),

                  // Footer Version Info
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Word Search Puzzle • v1.0.0',
                      style: GoogleFonts.outfit(
                        fontSize: 11.sp,
                        color: Colors.white38,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: titleColor ?? Colors.white,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 11.sp,
                  color: Colors.white54,
                ),
              )
            : null,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  Widget _buildGameQuickTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
      ),
      child: Row(
        children: List.generate(_games.length, (index) {
          final game = _games[index];
          final isSelected = _currentPage == index;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                AudioHelper().playButtonSound();
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            game.primaryColor.withOpacity(0.85),
                            game.secondaryColor.withOpacity(0.85),
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        game.isPlayable
                            ? Icons.play_circle_fill_rounded
                            : Icons.lock_clock_rounded,
                        color: isSelected
                            ? const Color(0xFF0D1B2A)
                            : Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        game.title,
                        style: GoogleFonts.outfit(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? const Color(0xFF0D1B2A)
                              : Colors.white70,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildGamesCarousel() {
    return PageView.builder(
      controller: _pageController,
      itemCount: _games.length,
      onPageChanged: (index) {
        setState(() => _currentPage = index);
      },
      itemBuilder: (context, index) {
        final game = _games[index];
        final isSelected = _currentPage == index;

        return AnimatedScale(
          scale: isSelected ? 1.0 : 0.94,
          duration: const Duration(milliseconds: 250),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: _buildGameCard(game, isSelected, index),
          ),
        );
      },
    );
  }

  Widget _buildGameCard(_GameItemModel game, bool isSelected, int index) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                game.cardGradient[0].withOpacity(0.88),
                game.cardGradient[1].withOpacity(0.82),
                game.cardGradient[2].withOpacity(0.88),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isSelected
                  ? game.primaryColor.withOpacity(0.8)
                  : Colors.white.withOpacity(0.2),
              width: isSelected ? 2.0 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: game.primaryColor.withOpacity(isSelected ? 0.35 : 0.15),
                blurRadius: isSelected ? 24 : 12,
                spreadRadius: isSelected ? 1 : 0,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Ambient background watermark icon
              Positioned(
                right: -20,
                top: -20,
                child: Icon(
                  game.fallbackIcon,
                  size: 160,
                  color: Colors.white.withOpacity(0.04),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row: Category & Status Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(10),
                            border:
                                Border.all(color: Colors.white24, width: 0.8),
                          ),
                          child: Text(
                            game.category,
                            style: GoogleFonts.outfit(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white70,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: game.badgeColor.withOpacity(0.22),
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: game.badgeColor, width: 1.2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: game.badgeColor,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                game.badgeText,
                                style: GoogleFonts.outfit(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w800,
                                  color: game.badgeColor,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Hero Art / Icon Display (Proper, prominent size & 3D Crossword Logo)
                    Center(
                      child: Container(
                        width: 140.w,
                        height: 140.h,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              game.primaryColor.withOpacity(0.35),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Center(
                          child: game.id == 'crossword'
                              ? const CrosswordLogo(
                                  size: 130,
                                  animate: true,
                                )
                              : (game.imagePath != null
                                  ? Image.asset(
                                      game.imagePath!,
                                      width: 125.w,
                                      height: 125.h,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => Icon(
                                        game.fallbackIcon,
                                        size: 80.sp,
                                        color: game.primaryColor,
                                      ),
                                    )
                                  : _buildCrosswordHeroArt(game)),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Title & Subtitle
                    Text(
                      game.title,
                      style: GoogleFonts.outfit(
                        fontSize: 26.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.5),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      game.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 12.sp,
                        color: Colors.white.withOpacity(0.8),
                        height: 1.25,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Feature Chips
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: game.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.15)),
                          ),
                          child: Text(
                            tag,
                            style: GoogleFonts.outfit(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // Primary 3D Tactile Interactive Button (Themed to game's color scheme)
                    App3DButton(
                      text: game.isPlayable ? 'PLAY NOW' : 'COMING SOON',
                      icon: game.isPlayable
                          ? Icons.play_arrow_rounded
                          : Icons.rocket_launch_rounded,
                      isLoading: _isPlayButtonTapped && isSelected,
                      gradientColors: game.isPlayable
                          ? game.buttonGradient
                          : const [Color(0xFFFFB300), Color(0xFFFF5252)],
                      shadowColor: game.isPlayable
                          ? game.buttonShadowColor
                          : const Color(0xFFBF360C),
                      glowColor: game.isPlayable
                          ? game.buttonGlowColor
                          : const Color(0xFFFF9100),
                      textColor:
                          game.isPlayable ? game.buttonTextColor : Colors.white,
                      iconColor:
                          game.isPlayable ? game.buttonTextColor : Colors.white,
                      height: 52,
                      depth: 4.5,
                      borderRadius: 26.0,
                      width: double.infinity,
                      onPressed: () => _onGameSelected(index),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCrosswordHeroArt(_GameItemModel game) {
    return Container(
      width: 88.w,
      height: 88.h,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: game.primaryColor.withOpacity(0.6), width: 1.6),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCrosswordCell('C', true),
                _buildCrosswordCell('R', false),
                _buildCrosswordCell('O', true),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCrosswordCell('', false, isBlack: true),
                _buildCrosswordCell('O', true),
                _buildCrosswordCell('', false, isBlack: true),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCrosswordCell('S', false),
                _buildCrosswordCell('S', true),
                _buildCrosswordCell('!', false),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCrosswordCell(String letter, bool highlight,
      {bool isBlack = false}) {
    return Container(
      width: 22.w,
      height: 22.h,
      margin: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        color: isBlack
            ? Colors.black54
            : (highlight
                ? const Color(0xFFFFB300).withOpacity(0.85)
                : Colors.white.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          letter,
          style: GoogleFonts.outfit(
            fontSize: 11.sp,
            fontWeight: FontWeight.w900,
            color: highlight ? const Color(0xFF1E033A) : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_games.length, (index) {
        final isSelected = _currentPage == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isSelected ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isSelected
                ? _games[index].primaryColor
                : Colors.white.withOpacity(0.35),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// =============================================================================
// AMBIENT FLOATING ANIMATED WORDS & LETTER PARTICLES BACKGROUND
// =============================================================================
class _FloatingWordsBackground extends StatelessWidget {
  final AnimationController controller;
  final bool isWordix;

  const _FloatingWordsBackground({
    required this.controller,
    this.isWordix = true,
  });

  static final List<_FloatingParticle> _particles = [
    _FloatingParticle(
        text: 'WORDIX',
        initialX: 0.12,
        initialY: 0.15,
        speed: 0.8,
        size: 22,
        rotationSpeed: 0.3,
        isWord: true),
    _FloatingParticle(
        text: 'PUZZLE',
        initialX: 0.78,
        initialY: 0.22,
        speed: 0.6,
        size: 20,
        rotationSpeed: -0.4,
        isWord: true),
    _FloatingParticle(
        text: 'SEARCH',
        initialX: 0.18,
        initialY: 0.48,
        speed: 0.9,
        size: 24,
        rotationSpeed: 0.5,
        isWord: true),
    _FloatingParticle(
        text: 'QUEST',
        initialX: 0.82,
        initialY: 0.55,
        speed: 0.7,
        size: 18,
        rotationSpeed: -0.3,
        isWord: true),
    _FloatingParticle(
        text: 'CROSS',
        initialX: 0.10,
        initialY: 0.82,
        speed: 0.75,
        size: 22,
        rotationSpeed: 0.4,
        isWord: true),
    _FloatingParticle(
        text: 'BRAIN',
        initialX: 0.75,
        initialY: 0.86,
        speed: 0.85,
        size: 20,
        rotationSpeed: -0.5,
        isWord: true),
    _FloatingParticle(
        text: 'FIND',
        initialX: 0.45,
        initialY: 0.08,
        speed: 0.65,
        size: 18,
        rotationSpeed: 0.2,
        isWord: true),
    _FloatingParticle(
        text: 'SOLVE',
        initialX: 0.50,
        initialY: 0.92,
        speed: 0.7,
        size: 20,
        rotationSpeed: -0.3,
        isWord: true),
    _FloatingParticle(
        text: 'W',
        initialX: 0.05,
        initialY: 0.35,
        speed: 1.1,
        size: 28,
        rotationSpeed: 0.8,
        isWord: false),
    _FloatingParticle(
        text: 'A',
        initialX: 0.90,
        initialY: 0.38,
        speed: 1.0,
        size: 24,
        rotationSpeed: -0.6,
        isWord: false),
    _FloatingParticle(
        text: 'P',
        initialX: 0.35,
        initialY: 0.30,
        speed: 0.9,
        size: 26,
        rotationSpeed: 0.7,
        isWord: false),
    _FloatingParticle(
        text: 'Z',
        initialX: 0.65,
        initialY: 0.40,
        speed: 1.2,
        size: 30,
        rotationSpeed: -0.8,
        isWord: false),
    _FloatingParticle(
        text: 'X',
        initialX: 0.28,
        initialY: 0.68,
        speed: 1.0,
        size: 28,
        rotationSpeed: 0.9,
        isWord: false),
    _FloatingParticle(
        text: 'Q',
        initialX: 0.60,
        initialY: 0.72,
        speed: 0.85,
        size: 26,
        rotationSpeed: -0.5,
        isWord: false),
    _FloatingParticle(
        text: 'S',
        initialX: 0.92,
        initialY: 0.70,
        speed: 1.1,
        size: 26,
        rotationSpeed: 0.6,
        isWord: false),
  ];

  @override
  Widget build(BuildContext context) {
    // Theme-harmonized glowing colors
    final Color wordBorderColor = isWordix
        ? const Color(0xFF00E5FF).withOpacity(0.55)
        : const Color(0xFFFFB300).withOpacity(0.55);

    final Color wordTextColor =
        isWordix ? const Color(0xFF80DEEA) : const Color(0xFFFFD54F);

    final Color tileBorderColor = isWordix
        ? const Color(0xFFFFD54F).withOpacity(0.55)
        : const Color(0xFFFF4081).withOpacity(0.55);

    final Color tileTextColor =
        isWordix ? const Color(0xFFFFE082) : const Color(0xFFFF80AB);

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final progress = controller.value;
          final size = MediaQuery.of(context).size;

          return Stack(
            fit: StackFit.expand,
            children: _particles.map((p) {
              // Gentle looping undulation
              final double offsetY =
                  ((p.initialY - (progress * p.speed)) % 1.0) * size.height;
              final double waveX =
                  math.sin((progress * 2 * math.pi) + (p.initialX * 10)) * 18;
              final double offsetX = (p.initialX * size.width) + waveX;
              final double rotation =
                  (progress * 2 * math.pi * p.rotationSpeed);

              // Fade in/out slightly near edges
              final double normalizedY = offsetY / size.height;
              final double opacityFade = (normalizedY < 0.1)
                  ? (normalizedY / 0.1)
                  : (normalizedY > 0.9 ? (1.0 - normalizedY) / 0.1 : 1.0);
              final double opacity =
                  (p.isWord ? 0.16 : 0.20) * opacityFade.clamp(0.0, 1.0);

              return Positioned(
                left: offsetX,
                top: offsetY,
                child: Transform.rotate(
                  angle: rotation,
                  child: Opacity(
                    opacity: opacity,
                    child: p.isWord
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: wordBorderColor,
                                width: 1.2,
                              ),
                            ),
                            child: Text(
                              p.text,
                              style: GoogleFonts.outfit(
                                fontSize: p.size.sp,
                                fontWeight: FontWeight.w900,
                                color: wordTextColor,
                                letterSpacing: 1.8,
                              ),
                            ),
                          )
                        : Container(
                            width: (p.size * 1.3).sp,
                            height: (p.size * 1.3).sp,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: tileBorderColor,
                                width: 1.2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                p.text,
                                style: GoogleFonts.outfit(
                                  fontSize: p.size.sp,
                                  fontWeight: FontWeight.w900,
                                  color: tileTextColor,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _FloatingParticle {
  final String text;
  final double initialX;
  final double initialY;
  final double speed;
  final double size;
  final double rotationSpeed;
  final bool isWord;

  const _FloatingParticle({
    required this.text,
    required this.initialX,
    required this.initialY,
    required this.speed,
    required this.size,
    required this.rotationSpeed,
    required this.isWord,
  });
}

// ═════════════════════════════════════════════════════════════════════════════
// 🔘 CIRCULAR FLOATING BADGE (BREATHING FLOAT, SCALE DOWN & GLOSS PILL)
// ═════════════════════════════════════════════════════════════════════════════
class _CircularFloatingBadge extends StatefulWidget {
  final Widget icon;
  final String? label;
  final List<Color>? labelGradient;
  final VoidCallback onTap;

  const _CircularFloatingBadge({
    required this.icon,
    this.label,
    this.labelGradient,
    required this.onTap,
  });

  @override
  State<_CircularFloatingBadge> createState() => _CircularFloatingBadgeState();
}

class _CircularFloatingBadgeState extends State<_CircularFloatingBadge>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: 0, end: -4.5).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.88 : 1.0,
          duration: const Duration(milliseconds: 80),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: widget.icon,
              ),
              if (widget.label != null) ...[
                Transform.translate(
                  offset: const Offset(0, -4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3.0,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: widget.labelGradient ??
                            const [Color(0xFFFF7043), Color(0xFFD84315)],
                      ),
                      border: Border.all(
                        color: Colors.white,
                        width: 1.4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.6),
                          offset: const Offset(0, 3),
                          blurRadius: 5,
                        ),
                        BoxShadow(
                          color: (widget.labelGradient?.first ?? Colors.orange)
                              .withOpacity(0.45),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Text(
                      widget.label!,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dynaPuff(
                        fontSize: 9.0,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.4,
                        shadows: const [
                          Shadow(
                            color: Colors.black87,
                            offset: Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 🎁 1. ANIMATED 3D DAILY REWARD GIFT CHEST (LID POP, LIGHT BEAMS & SPARKLES)
// ═════════════════════════════════════════════════════════════════════════════
class _AnimatedDailyRewardGiftIcon extends StatefulWidget {
  const _AnimatedDailyRewardGiftIcon();

  @override
  State<_AnimatedDailyRewardGiftIcon> createState() =>
      _AnimatedDailyRewardGiftIconState();
}

class _AnimatedDailyRewardGiftIconState
    extends State<_AnimatedDailyRewardGiftIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _giftController;

  @override
  void initState() {
    super.initState();
    _giftController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _giftController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _giftController,
      builder: (context, _) {
        return CustomPaint(
          size: const Size(56, 56),
          painter: _GiftBoxPainter(progress: _giftController.value),
        );
      },
    );
  }
}

class _GiftBoxPainter extends CustomPainter {
  final double progress;

  _GiftBoxPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2.0;
    final double cy = size.height / 2.0;
    final double t = progress;

    // 1. Rotating Golden Light Rays behind the gift box
    final double rayAngle = t * 2 * math.pi * 0.4;
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(rayAngle);

    final Paint rayPaint = Paint()
      ..color = const Color(0xFFFFD54F).withOpacity(0.16)
      ..style = PaintingStyle.fill;

    const int rayCount = 8;
    const double rayRadius = 24.0;
    for (int i = 0; i < rayCount; i++) {
      final double startAngle = (i * 2 * math.pi) / rayCount;
      final Path rayPath = Path()
        ..moveTo(0, 0)
        ..lineTo(
          rayRadius * math.cos(startAngle - 0.16),
          rayRadius * math.sin(startAngle - 0.16),
        )
        ..lineTo(
          rayRadius * math.cos(startAngle + 0.16),
          rayRadius * math.sin(startAngle + 0.16),
        )
        ..close();
      canvas.drawPath(rayPath, rayPaint);
    }
    canvas.restore();

    // 2. Drop Shadow under the gift box
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + 18.0),
        width: 32.0,
        height: 10.0,
      ),
      shadowPaint,
    );

    // 3. Anticipation Jiggle / Squish & Lid Pop Animation
    double tilt = 0.0;
    double lidLift = 0.0;
    double beamIntensity = 0.0;
    double bounceY = math.sin(t * 2 * math.pi) * 1.5;

    if (t >= 0.52 && t < 0.72) {
      final double jiggleT = (t - 0.52) / 0.20;
      tilt = math.sin(jiggleT * math.pi * 5.0) * 0.12;
      bounceY -= math.sin(jiggleT * math.pi) * 2.0;
    } else if (t >= 0.72 && t < 0.92) {
      final double popT = (t - 0.72) / 0.20;
      lidLift = math.sin(popT * math.pi) * -5.0;
      beamIntensity = math.sin(popT * math.pi);
      tilt = math.sin(popT * math.pi) * -0.08;
    }

    canvas.save();
    canvas.translate(cx, cy + bounceY);
    canvas.rotate(tilt);

    // 4. Golden light beam bursting from box when lid lifts
    if (beamIntensity > 0.05) {
      final Path beamPath = Path()
        ..moveTo(-9.0, 0.0)
        ..lineTo(9.0, 0.0)
        ..lineTo(16.0, -18.0)
        ..lineTo(-16.0, -18.0)
        ..close();

      final Paint beamFill = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            const Color(0xFFFFF9C4).withOpacity(0.85 * beamIntensity),
            const Color(0xFFFFD54F).withOpacity(0.45 * beamIntensity),
            Colors.transparent,
          ],
        ).createShader(const Rect.fromLTWH(-16, -18, 32, 18));
      canvas.drawPath(beamPath, beamFill);

      _drawSparkleStar(canvas, Offset(-7.0, -10.0 - 5.0 * beamIntensity), 2.8 * beamIntensity);
      _drawSparkleStar(canvas, Offset(8.0, -12.0 - 6.0 * beamIntensity), 3.2 * beamIntensity);
      _drawSparkleStar(canvas, Offset(0.0, -15.0 - 8.0 * beamIntensity), 4.0 * beamIntensity);
    }

    // 5. 3D Gift Box Body
    const double boxW = 28.0;
    const double boxH = 20.0;
    final Rect bodyRect = Rect.fromCenter(
      center: const Offset(0.0, 6.0),
      width: boxW,
      height: boxH,
    );

    final Paint bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFF3D00),
          Color(0xFFE53935),
          Color(0xFFB71C1C),
          Color(0xFF880E4F),
        ],
      ).createShader(bodyRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(5.0)),
      bodyPaint,
    );

    final Paint bodyBorder = Paint()
      ..color = const Color(0xFFFF8A80).withOpacity(0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(5.0)),
      bodyBorder,
    );

    // 6. Vertical Golden Ribbon on Box Body
    const double ribW = 6.2;
    final Rect vRibRect = Rect.fromLTWH(-ribW / 2.0, bodyRect.top, ribW, bodyRect.height);
    final Paint ribPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFFFFF59D),
          Color(0xFFFFD54F),
          Color(0xFFFFB300),
          Color(0xFFFF8F00),
        ],
      ).createShader(vRibRect);
    canvas.drawRect(vRibRect, ribPaint);

    final Paint ribBorder = Paint()
      ..color = const Color(0xFFFFFDE7).withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawLine(Offset(-ribW / 2.0, bodyRect.top), Offset(-ribW / 2.0, bodyRect.bottom), ribBorder);
    canvas.drawLine(Offset(ribW / 2.0, bodyRect.top), Offset(ribW / 2.0, bodyRect.bottom), ribBorder);

    // 7. Horizontal Golden Ribbon on Box Body
    final Rect hRibRect = Rect.fromLTWH(bodyRect.left, 6.0 - ribW / 2.0, bodyRect.width, ribW);
    canvas.drawRect(hRibRect, ribPaint);
    canvas.drawLine(Offset(bodyRect.left, 6.0 - ribW / 2.0), Offset(bodyRect.right, 6.0 - ribW / 2.0), ribBorder);
    canvas.drawLine(Offset(bodyRect.left, 6.0 + ribW / 2.0), Offset(bodyRect.right, 6.0 + ribW / 2.0), ribBorder);

    // 8. 3D Box Lid
    canvas.save();
    canvas.translate(0.0, lidLift);

    const double lidW = 32.0;
    const double lidH = 7.5;
    final Rect lidRect = Rect.fromCenter(
      center: const Offset(0.0, -3.5),
      width: lidW,
      height: lidH,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: const Offset(0.0, -1.8),
          width: lidW,
          height: lidH,
        ),
        const Radius.circular(4.0),
      ),
      Paint()..color = Colors.black.withOpacity(0.40),
    );

    final Paint lidPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFF5252),
          Color(0xFFE53935),
          Color(0xFFC62828),
        ],
      ).createShader(lidRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(lidRect, const Radius.circular(4.0)),
      lidPaint,
    );

    final Paint lidBorder = Paint()
      ..color = const Color(0xFFFFCDD2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    canvas.drawRRect(
      RRect.fromRectAndRadius(lidRect, const Radius.circular(4.0)),
      lidBorder,
    );

    final Rect lidRibRect = Rect.fromLTWH(-ribW / 2.0, lidRect.top, ribW, lidRect.height);
    canvas.drawRect(lidRibRect, ribPaint);
    canvas.drawLine(Offset(-ribW / 2.0, lidRect.top), Offset(-ribW / 2.0, lidRect.bottom), ribBorder);
    canvas.drawLine(Offset(ribW / 2.0, lidRect.top), Offset(ribW / 2.0, lidRect.bottom), ribBorder);

    // 9. 3D Golden Ribbon Bow atop Lid
    const double bowY = -8.0;

    final Path leftBow = Path()
      ..moveTo(0.0, bowY)
      ..cubicTo(-6.0, bowY - 7.5, -12.5, bowY - 5.5, -9.5, bowY)
      ..cubicTo(-7.0, bowY + 3.0, -2.5, bowY + 1.0, 0.0, bowY);
    canvas.drawPath(leftBow, ribPaint);
    canvas.drawPath(leftBow, ribBorder);

    final Path rightBow = Path()
      ..moveTo(0.0, bowY)
      ..cubicTo(6.0, bowY - 7.5, 12.5, bowY - 5.5, 9.5, bowY)
      ..cubicTo(7.0, bowY + 3.0, 2.5, bowY + 1.0, 0.0, bowY);
    canvas.drawPath(rightBow, ribPaint);
    canvas.drawPath(rightBow, ribBorder);

    final Rect knotRect = Rect.fromCircle(center: const Offset(0.0, bowY), radius: 3.5);
    final Paint knotPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFFDE7), Color(0xFFFFD54F), Color(0xFFFF8F00)],
      ).createShader(knotRect);
    canvas.drawCircle(const Offset(0.0, bowY), 3.5, knotPaint);
    canvas.drawCircle(
      const Offset(0.0, bowY),
      3.5,
      Paint()
        ..color = const Color(0xFFFFF9C4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9,
    );

    canvas.drawCircle(
      const Offset(-1.0, bowY - 1.0),
      1.0,
      Paint()..color = Colors.white,
    );

    canvas.restore(); // Lid restore

    final double starGlint = (math.sin(t * 2 * math.pi * 2.0) * 0.5 + 0.5);
    _drawSparkleStar(canvas, const Offset(-15.0, -10.0), 3.0 * starGlint);
    _drawSparkleStar(canvas, const Offset(15.0, 8.0), 2.5 * (1.0 - starGlint));

    canvas.restore(); // Box restore
  }

  void _drawSparkleStar(Canvas canvas, Offset center, double size) {
    if (size <= 0.4) return;
    final Path star = Path()
      ..moveTo(center.dx, center.dy - size)
      ..lineTo(center.dx + size * 0.32, center.dy)
      ..lineTo(center.dx, center.dy + size)
      ..lineTo(center.dx - size * 0.32, center.dy)
      ..close();
    canvas.drawPath(
      star,
      Paint()..color = const Color(0xFFFFF9C4).withOpacity(0.92),
    );
  }

  @override
  bool shouldRepaint(covariant _GiftBoxPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ═════════════════════════════════════════════════════════════════════════════
// 🎯 2. ANIMATED 3D DAILY TASK ARCHERY TARGET (ARROW FLIGHT, IMPACT & WOBBLE)
// ═════════════════════════════════════════════════════════════════════════════
class _AnimatedDailyTaskTargetIcon extends StatefulWidget {
  const _AnimatedDailyTaskTargetIcon();

  @override
  State<_AnimatedDailyTaskTargetIcon> createState() =>
      _AnimatedDailyTaskTargetIconState();
}

class _AnimatedDailyTaskTargetIconState
    extends State<_AnimatedDailyTaskTargetIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _arrowController;

  @override
  void initState() {
    super.initState();
    _arrowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _arrowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _arrowController,
      builder: (context, _) {
        return CustomPaint(
          size: const Size(56, 56),
          painter: _ArcheryTargetPainter(progress: _arrowController.value),
        );
      },
    );
  }
}

class _ArcheryTargetPainter extends CustomPainter {
  final double progress;

  _ArcheryTargetPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final Offset bullseye = Offset(size.width * 0.44, size.height * 0.50);
    const double targetR = 19.5;

    // Drop shadow behind target
    canvas.drawCircle(
      bullseye.translate(0, 2.5),
      targetR,
      Paint()
        ..color = Colors.black.withOpacity(0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0),
    );

    // Outer Red Ring
    final Rect targetRect = Rect.fromCircle(center: bullseye, radius: targetR);
    final Paint redRingPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFEF5350), Color(0xFFC62828)],
      ).createShader(targetRect);
    canvas.drawCircle(bullseye, targetR, redRingPaint);

    canvas.drawCircle(
      bullseye,
      targetR,
      Paint()
        ..color = const Color(0xFF7F0000).withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    // Middle White Ring
    final Paint whiteRingPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFECEFF1)],
      ).createShader(targetRect);
    canvas.drawCircle(bullseye, 14.2, whiteRingPaint);

    // Inner Red Ring
    final Paint innerRedPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
      ).createShader(targetRect);
    canvas.drawCircle(bullseye, 9.4, innerRedPaint);

    // White Bullseye
    canvas.drawCircle(bullseye, 4.8, Paint()..color = Colors.white);

    // Center Red Dot
    canvas.drawCircle(
      bullseye,
      2.0,
      Paint()..color = const Color(0xFFC62828),
    );

    // Glossy 3D Highlight Arc
    final Path glossPath = Path()
      ..addArc(
        Rect.fromCircle(center: bullseye, radius: targetR - 1.5),
        math.pi * 1.05,
        math.pi * 0.55,
      );
    canvas.drawPath(
      glossPath,
      Paint()
        ..color = Colors.white.withOpacity(0.38)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );

    // Animated Arrow
    final double t = progress;
    const double baseAngle = -0.42;
    const double arrowLen = 22.0;

    double arrowOpacity = 1.0;
    Offset tipPos = bullseye;
    double currentAngle = baseAngle;

    if (t < 0.16) {
      final double flightT = (t / 0.16).clamp(0.0, 1.0);
      final double flightDist = 55.0 * (1.0 - Curves.easeInQuad.transform(flightT));
      tipPos = Offset(
        bullseye.dx + flightDist * math.cos(baseAngle),
        bullseye.dy + flightDist * math.sin(baseAngle),
      );
    } else if (t < 0.42) {
      final double wobbleProgress = ((t - 0.16) / 0.26).clamp(0.0, 1.0);
      final double decay = math.exp(-wobbleProgress * 4.0);
      final double wobbleAngle =
          math.sin(wobbleProgress * math.pi * 5.0) * 0.16 * decay;
      currentAngle = baseAngle + wobbleAngle;

      final double shockT = ((t - 0.16) / 0.14).clamp(0.0, 1.0);
      if (shockT < 1.0) {
        canvas.drawCircle(
          bullseye,
          3.0 + 12.0 * shockT,
          Paint()
            ..color = Colors.white.withOpacity((1.0 - shockT) * 0.70)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8,
        );

        _drawImpactSparks(canvas, bullseye, shockT);
      }
    } else if (t > 0.85) {
      final double fadeT = ((t - 0.85) / 0.15).clamp(0.0, 1.0);
      arrowOpacity = (1.0 - fadeT).clamp(0.0, 1.0);
    }

    if (arrowOpacity > 0.01) {
      canvas.save();
      final tailPos = Offset(
        tipPos.dx + arrowLen * math.cos(currentAngle),
        tipPos.dy + arrowLen * math.sin(currentAngle),
      );

      final Paint shaftPaint = Paint()
        ..color = const Color(0xFF263238).withOpacity(arrowOpacity)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        tipPos.translate(0, 1.5),
        tailPos.translate(0, 1.5),
        Paint()
          ..color = Colors.black.withOpacity(0.25 * arrowOpacity)
          ..strokeWidth = 2.0,
      );

      canvas.drawLine(tipPos, tailPos, shaftPaint);

      canvas.drawCircle(
        tipPos,
        2.2,
        Paint()..color = const Color(0xFF263238).withOpacity(arrowOpacity),
      );
      canvas.drawCircle(
        tipPos,
        1.2,
        Paint()..color = const Color(0xFFB0BEC5).withOpacity(arrowOpacity),
      );

      _drawFeatherFletching(canvas, tailPos, currentAngle, arrowOpacity);

      if (t >= 0.42 && t <= 0.85) {
        final double glintT = ((t - 0.42) / 0.43).clamp(0.0, 1.0);
        final double glintScale = math.sin(glintT * math.pi);
        _drawDiamondStar(canvas, bullseye.translate(1.0, -1.0), 3.0 * glintScale);
      }

      canvas.restore();
    }
  }

  void _drawFeatherFletching(
    Canvas canvas,
    Offset tailPos,
    double angle,
    double opacity,
  ) {
    canvas.save();
    canvas.translate(tailPos.dx, tailPos.dy);
    canvas.rotate(angle);

    final Paint featherPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFF0288D1), Color(0xFF00E5FF)],
      ).createShader(const Rect.fromLTWH(-9, -5, 10, 10));

    final Path upperFeather = Path()
      ..moveTo(-8.5, -0.7)
      ..lineTo(-1.8, -4.6)
      ..lineTo(-0.6, -4.0)
      ..lineTo(-0.6, -0.7)
      ..close();
    canvas.drawPath(upperFeather, featherPaint);
    canvas.drawPath(
      upperFeather,
      Paint()
        ..color = Colors.white.withOpacity(0.65 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6,
    );

    final Path lowerFeather = Path()
      ..moveTo(-8.5, 0.7)
      ..lineTo(-1.8, 4.6)
      ..lineTo(-0.6, 4.0)
      ..lineTo(-0.6, 0.7)
      ..close();
    canvas.drawPath(lowerFeather, featherPaint);
    canvas.drawPath(
      lowerFeather,
      Paint()
        ..color = Colors.white.withOpacity(0.65 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6,
    );

    final Paint ribPaint = Paint()
      ..color = Colors.white.withOpacity(0.40 * opacity)
      ..strokeWidth = 0.6;
    for (int i = 0; i < 3; i++) {
      final double vx = -6.6 + i * 2.2;
      canvas.drawLine(
        Offset(vx, -0.7),
        Offset(vx + 1.1, -0.7 - (1.1 + i * 0.9)),
        ribPaint,
      );
      canvas.drawLine(
        Offset(vx, 0.7),
        Offset(vx + 1.1, 0.7 + (1.1 + i * 0.9)),
        ribPaint,
      );
    }

    canvas.drawLine(
      const Offset(-0.8, 0),
      const Offset(1.8, 0),
      Paint()
        ..color = const Color(0xFF263238).withOpacity(opacity)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      const Offset(-8.6, -1.1),
      const Offset(-8.6, 1.1),
      Paint()
        ..color = const Color(0xFFECEFF1).withOpacity(opacity)
        ..strokeWidth = 1.0,
    );

    canvas.drawCircle(
      const Offset(1.8, 0),
      1.1,
      Paint()..color = const Color(0xFF00E5FF).withOpacity(opacity),
    );

    canvas.restore();
  }

  void _drawImpactSparks(Canvas canvas, Offset center, double progress) {
    final double dist = 6.0 + 8.0 * progress;
    final double alpha = (1.0 - progress).clamp(0.0, 1.0);
    final Paint sparkPaint = Paint()
      ..color = const Color(0xFFFFD54F).withOpacity(alpha);

    for (int i = 0; i < 4; i++) {
      final double ang = i * (math.pi / 2.0) + (math.pi / 4.0);
      final Offset sparkPos = Offset(
        center.dx + dist * math.cos(ang),
        center.dy + dist * math.sin(ang),
      );
      canvas.drawCircle(sparkPos, 1.2 * (1.0 - progress * 0.5), sparkPaint);
    }
  }

  void _drawDiamondStar(Canvas canvas, Offset center, double size) {
    if (size <= 0.2) return;
    final Path star = Path()
      ..moveTo(center.dx, center.dy - size)
      ..lineTo(center.dx + size * 0.35, center.dy)
      ..lineTo(center.dx, center.dy + size)
      ..lineTo(center.dx - size * 0.35, center.dy)
      ..close();
    canvas.drawPath(star, Paint()..color = const Color(0xFFFFF9C4));
  }

  @override
  bool shouldRepaint(covariant _ArcheryTargetPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ═════════════════════════════════════════════════════════════════════════════
// 🎡 3. ANIMATED 3D LUCKY SPIN WHEEL (ROTATING 8-SECTOR WHEEL & NEEDLE QUIVER)
// ═════════════════════════════════════════════════════════════════════════════
class _AnimatedSpinWheelIcon extends StatefulWidget {
  const _AnimatedSpinWheelIcon();

  @override
  State<_AnimatedSpinWheelIcon> createState() => _AnimatedSpinWheelIconState();
}

class _AnimatedSpinWheelIconState extends State<_AnimatedSpinWheelIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wheelController;

  @override
  void initState() {
    super.initState();
    _wheelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _wheelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _wheelController,
      builder: (context, _) {
        return CustomPaint(
          size: const Size(56, 56),
          painter: _SpinWheelPainter(progress: _wheelController.value),
        );
      },
    );
  }
}

class _SpinWheelPainter extends CustomPainter {
  final double progress;

  _SpinWheelPainter({required this.progress});

  static const List<Color> _sectorColors = [
    Color(0xFFFF5252),
    Color(0xFFFFB300),
    Color(0xFF00E5FF),
    Color(0xFFE040FB),
    Color(0xFF00E676),
    Color(0xFFFF9100),
    Color(0xFF7C4DFF),
    Color(0xFF40C4FF),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2.0;
    final double cy = size.height / 2.0;
    const double radius = 21.0;
    final Offset center = Offset(cx, cy);

    canvas.drawCircle(
      center.translate(0, 3.0),
      radius,
      Paint()
        ..color = Colors.black.withOpacity(0.50)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0),
    );

    final double rotationAngle = progress * 2.0 * math.pi;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(rotationAngle);

    final Rect wheelRect = Rect.fromCircle(center: Offset.zero, radius: radius);
    const int sectorCount = 8;
    const double sweep = 2.0 * math.pi / sectorCount;

    for (int i = 0; i < sectorCount; i++) {
      final double startAngle = i * sweep;
      final Paint sectorPaint = Paint()
        ..color = _sectorColors[i]
        ..style = PaintingStyle.fill;

      canvas.drawArc(wheelRect, startAngle, sweep, true, sectorPaint);
    }

    final Paint spokePaint = Paint()
      ..color = Colors.white.withOpacity(0.65)
      ..strokeWidth = 1.0;

    for (int i = 0; i < sectorCount; i++) {
      final double ang = i * sweep;
      canvas.drawLine(
        Offset.zero,
        Offset(radius * math.cos(ang), radius * math.sin(ang)),
        spokePaint,
      );
    }

    final Paint bezelPaint = Paint()
      ..shader = const SweepGradient(
        colors: [
          Color(0xFFFFD54F),
          Color(0xFFFF8F00),
          Color(0xFFFFF9C4),
          Color(0xFFFF6D00),
          Color(0xFFFFD54F),
        ],
      ).createShader(wheelRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    canvas.drawCircle(Offset.zero, radius, bezelPaint);

    final Paint bulbPaint = Paint()..color = const Color(0xFFFFFDE7);
    for (int i = 0; i < sectorCount; i++) {
      final double ang = i * sweep + (sweep / 2.0);
      final Offset bulbPos = Offset((radius - 1.2) * math.cos(ang), (radius - 1.2) * math.sin(ang));
      canvas.drawCircle(bulbPos, 1.2, bulbPaint);
    }

    canvas.restore();

    // Center Golden Medallion
    const double hubR = 7.5;
    final Rect hubRect = Rect.fromCircle(center: center, radius: hubR);
    final Paint hubPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFFDE7), Color(0xFFFFD54F), Color(0xFFFF8F00)],
      ).createShader(hubRect);
    canvas.drawCircle(center, hubR, hubPaint);

    canvas.drawCircle(
      center,
      hubR,
      Paint()
        ..color = const Color(0xFFFFF9C4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    canvas.drawCircle(center, 3.2, Paint()..color = const Color(0xFF00E5FF));
    canvas.drawCircle(center.translate(-0.8, -0.8), 0.8, Paint()..color = Colors.white);

    // Top Pointer Needle
    final double tickProgress = (progress * sectorCount) % 1.0;
    final double needleQuiver = math.sin(tickProgress * math.pi) * 0.14;

    canvas.save();
    canvas.translate(cx, cy - radius + 1.5);
    canvas.rotate(needleQuiver);

    final Path pointerPath = Path()
      ..moveTo(0, 5.0)
      ..lineTo(-4.0, -4.5)
      ..lineTo(4.0, -4.5)
      ..close();

    canvas.drawPath(
      pointerPath.shift(const Offset(0, 1.5)),
      Paint()
        ..color = Colors.black45
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0),
    );

    final Paint pointerPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFD54F), Color(0xFFFF6D00)],
      ).createShader(const Rect.fromLTWH(-4, -4.5, 8, 9.5));
    canvas.drawPath(pointerPath, pointerPaint);

    canvas.drawPath(
      pointerPath,
      Paint()
        ..color = const Color(0xFFFFF9C4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    canvas.drawCircle(const Offset(0, -2.5), 1.4, Paint()..color = const Color(0xFFFFFDE7));
    canvas.restore();

    final double starPulse = math.sin(progress * 2.0 * math.pi * 3.0) * 0.5 + 0.5;
    _drawSparkle(canvas, Offset(cx - radius * 0.75, cy - radius * 0.75), 2.2 * starPulse);
    _drawSparkle(canvas, Offset(cx + radius * 0.80, cy + radius * 0.65), 1.8 * (1.0 - starPulse));
  }

  void _drawSparkle(Canvas canvas, Offset center, double size) {
    if (size <= 0.3) return;
    final Path star = Path()
      ..moveTo(center.dx, center.dy - size)
      ..lineTo(center.dx + size * 0.32, center.dy)
      ..lineTo(center.dx, center.dy + size)
      ..lineTo(center.dx - size * 0.32, center.dy)
      ..close();
    canvas.drawPath(
      star,
      Paint()..color = const Color(0xFFFFF9C4).withOpacity(0.9),
    );
  }

  @override
  bool shouldRepaint(covariant _SpinWheelPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ═════════════════════════════════════════════════════════════════════════════
// 🎬 4. ANIMATED 3D WATCH AD & EARN ICON (PULSING MONITOR, PLAY GLOW & COIN)
// ═════════════════════════════════════════════════════════════════════════════
class _AnimatedWatchAdVideoIcon extends StatefulWidget {
  const _AnimatedWatchAdVideoIcon();

  @override
  State<_AnimatedWatchAdVideoIcon> createState() =>
      _AnimatedWatchAdVideoIconState();
}

class _AnimatedWatchAdVideoIconState extends State<_AnimatedWatchAdVideoIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _adController;

  @override
  void initState() {
    super.initState();
    _adController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _adController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _adController,
      builder: (context, _) {
        return CustomPaint(
          size: const Size(56, 56),
          painter: _WatchAdVideoPainter(progress: _adController.value),
        );
      },
    );
  }
}

class _WatchAdVideoPainter extends CustomPainter {
  final double progress;

  _WatchAdVideoPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2.0;
    final double cy = size.height / 2.0;
    final double t = progress;

    // 1. Rotating Golden / Amber Light Rays in background
    final double rayAngle = t * 2.0 * math.pi * 0.35;
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(rayAngle);

    final Paint rayPaint = Paint()
      ..color = const Color(0xFFFFB300).withOpacity(0.18)
      ..style = PaintingStyle.fill;

    const int rayCount = 8;
    const double rayRadius = 24.0;
    for (int i = 0; i < rayCount; i++) {
      final double startAngle = (i * 2 * math.pi) / rayCount;
      final Path rayPath = Path()
        ..moveTo(0, 0)
        ..lineTo(
          rayRadius * math.cos(startAngle - 0.16),
          rayRadius * math.sin(startAngle - 0.16),
        )
        ..lineTo(
          rayRadius * math.cos(startAngle + 0.16),
          rayRadius * math.sin(startAngle + 0.16),
        )
        ..close();
      canvas.drawPath(rayPath, rayPaint);
    }
    canvas.restore();

    // 2. Drop Shadow behind monitor
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, cy + 3.0),
          width: 38.0,
          height: 28.0,
        ),
        const Radius.circular(8.0),
      ),
      Paint()
        ..color = Colors.black.withOpacity(0.50)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0),
    );

    // 3. Monitor Bezel
    final Rect monitorRect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: 38.0,
      height: 28.0,
    );

    final Paint bezelPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFB300),
          Color(0xFFFF8F00),
          Color(0xFFFF6F00),
        ],
      ).createShader(monitorRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(monitorRect, const Radius.circular(8.0)),
      bezelPaint,
    );

    // Monitor Screen
    final Rect screenRect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: 32.0,
      height: 22.0,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(screenRect, const Radius.circular(5.0)),
      Paint()..color = const Color(0xFF1A0A00),
    );

    // 4. Play Triangle Button
    final Path playPath = Path()
      ..moveTo(cx - 3.5, cy - 6.0)
      ..lineTo(cx + 6.0, cy)
      ..lineTo(cx - 3.5, cy + 6.0)
      ..close();

    final Paint playPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFF9C4), Color(0xFFFFD54F)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 8));
    canvas.drawPath(playPath, playPaint);

    // 5. Coin Badge at top-right
    final Offset coinCenter = Offset(cx + 14.0, cy - 10.0);
    canvas.drawCircle(
      coinCenter,
      6.0,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFFFFDE7), Color(0xFFFFD54F), Color(0xFFFF8F00)],
        ).createShader(Rect.fromCircle(center: coinCenter, radius: 6)),
    );
    canvas.drawCircle(
      coinCenter,
      6.0,
      Paint()
        ..color = const Color(0xFFFFF9C4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Sparkle Glint
    final double starGlint = math.sin(t * 2 * math.pi * 2.0) * 0.5 + 0.5;
    _drawSparkle(canvas, Offset(cx - 14.0, cy + 10.0), 2.6 * starGlint);
  }

  void _drawSparkle(Canvas canvas, Offset center, double size) {
    if (size <= 0.3) return;
    final Path star = Path()
      ..moveTo(center.dx, center.dy - size)
      ..lineTo(center.dx + size * 0.35, center.dy)
      ..lineTo(center.dx, center.dy + size)
      ..lineTo(center.dx - size * 0.35, center.dy)
      ..close();
    canvas.drawPath(
      star,
      Paint()..color = const Color(0xFFFFF9C4).withOpacity(0.9),
    );
  }

  @override
  bool shouldRepaint(covariant _WatchAdVideoPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
