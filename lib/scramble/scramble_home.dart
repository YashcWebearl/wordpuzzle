// ignore_for_file: avoid_print
import 'dart:ui';
import 'package:confetti/confetti.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word_puzzle/view/ad_show.dart';
import 'package:word_puzzle/view/game_selection_screen.dart';
import 'package:word_puzzle/view/setting_screen.dart';
import 'package:word_puzzle/widget/app_3d_button.dart';
import 'package:word_puzzle/widget/checkinternet.dart';
import 'package:word_puzzle/widget/coin_container.dart';
import 'package:word_puzzle/widget/coin_grant_dialog.dart';
import 'package:word_puzzle/widget/coin_service.dart';
import 'package:word_puzzle/widget/sound.dart';
import 'scramble_background.dart';
import 'scramble_game.dart';
import 'scramble_level_service.dart';
import 'scramble_logo.dart';

class ScrambleHomeScreen extends StatefulWidget {
  const ScrambleHomeScreen({super.key});

  @override
  State<ScrambleHomeScreen> createState() => _ScrambleHomeScreenState();
}

class _ScrambleHomeScreenState extends State<ScrambleHomeScreen> {
  final ConfettiController _confettiController =
      ConfettiController(duration: const Duration(seconds: 2));
  final GlobalKey<CoinGrantOverlayState> _coinGrantKey = GlobalKey();
  final GlobalKey _topCoinKey = GlobalKey();

  int _currentLevel = 1;
  bool _isPlayButtonTapped = false;

  @override
  void initState() {
    super.initState();
    _currentLevel = ScrambleLevelService.levelNotifier.value;
    ScrambleLevelService.levelNotifier.addListener(_onLevelChanged);
    _loadState();
  }

  void _onLevelChanged() {
    if (mounted && _currentLevel != ScrambleLevelService.levelNotifier.value) {
      setState(() {
        _currentLevel = ScrambleLevelService.levelNotifier.value;
      });
    }
  }

  @override
  void dispose() {
    ScrambleLevelService.levelNotifier.removeListener(_onLevelChanged);
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    await AudioHelper().initialize();
    final localLevel =
        prefs.getInt('scramble_current_level') ?? ScrambleLevelService.levelNotifier.value;
    if (mounted) {
      setState(() {
        _currentLevel = localLevel;
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
      debugPrint("Error adding coins: $e");
    }
  }

  void _handlePlayButton() async {
    if (_isPlayButtonTapped) return;

    setState(() => _isPlayButtonTapped = true);

    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (!mounted) return;
      if (connectivity.contains(ConnectivityResult.none)) {
        Fluttertoast.showToast(msg: "You're offline");
        setState(() => _isPlayButtonTapped = false);
        return;
      }

      final coinProvider = Provider.of<CoinProvider>(context, listen: false);
      if (coinProvider.coins < 4) {
        setState(() => _isPlayButtonTapped = false);
        _showInsufficientCoinsDialog();
        return;
      }

      // Smooth spinner delay matching Crossword & Wordix so circular indicator is properly visible
      await Future.delayed(const Duration(milliseconds: 350));
      await coinProvider.undoCoins(4);
      AudioHelper().playMoneySound();
      Fluttertoast.showToast(msg: "4 coins deducted to start the game");

      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ScrambleGameScreen(
              level: _currentLevel,
            ),
          ),
        );
        _loadState();
      }
    } catch (e) {
      debugPrint('Error starting scramble game: $e');
    } finally {
      if (mounted) {
        setState(() => _isPlayButtonTapped = false);
      }
    }
  }

  void _showInsufficientCoinsDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF230838).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: const Color(0xFFD500F9).withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD500F9).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.monetization_on_rounded,
                        color: Color(0xFFFFD54F),
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      "NEED 4 COINS",
                      style: GoogleFonts.outfit(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "You need at least 4 coins to start a new word puzzle.\nWatch a quick ad to claim free bonus coins!",
                      style: GoogleFonts.outfit(
                        fontSize: 13.5.sp,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 22),
                    App3DButton.amber(
                      text: 'WATCH AD FOR +5 COINS',
                      height: 48,
                      fontSize: 13.5,
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdPlaybackPage(
                              isRewardAd: true,
                              onAdComplete: () => _addCoins(5, 'Ad Reward'),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'CANCEL',
                        style: GoogleFonts.outfit(
                          color: Colors.white60,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

  void _returnToGameSelection() {
    AudioHelper().playButtonSound();
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const GameSelectionScreen()),
      );
    }
  }

  void _showReturnToHubDialog() {
    AudioHelper().playButtonSound();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B072C).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: const Color(0xFFD500F9).withValues(alpha: 0.45),
                    width: 1.6,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD500F9).withValues(alpha: 0.22),
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
                        color: const Color(0xFFD500F9).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFD500F9).withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                      ),
                      child: const Icon(
                        Icons.sports_esports_rounded,
                        color: Color(0xFFE040FB),
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "RETURN TO HUB?",
                      style: GoogleFonts.outfit(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Are you sure you want to return to Arcade Hub?",
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
                            text: 'NO',
                            gradientColors: const [
                              Color(0xFF334155),
                              Color(0xFF1E293B),
                            ],
                            shadowColor: const Color(0xFF0F172A),
                            glowColor: Colors.white24,
                            textColor: Colors.white70,
                            height: 46,
                            fontSize: 14.sp,
                            borderRadius: 16.0,
                            onPressed: () => Navigator.pop(dialogContext),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: App3DButton(
                            text: 'YES',
                            gradientColors: const [
                                Color(0xFFE040FB),
                                Color(0xFF7C4DFF),
                              ],
                            shadowColor: const Color(0xFF38006B),
                            glowColor: const Color(0xFFD500F9),
                            textColor: Colors.white,
                            height: 46,
                            fontSize: 14.sp,
                            borderRadius: 16.0,
                            onPressed: () {
                              Navigator.pop(dialogContext);
                              _returnToGameSelection();
                            },
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

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _showReturnToHubDialog();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Background
            Positioned.fill(
              child: ScrambleCosmicBackground(
                child: SafeArea(
                  child: Column(
                    children: [
                      // Top HUD: Arcade Hub Button on Left & Coins on Right (Identical to Crossword)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // 3D "ARCADE HUB" Button
                            App3DButton(
                              text: 'ARCADE HUB',
                              icon: Icons.arrow_back_ios_new_rounded,
                              gradientColors: const [
                                Color(0xFF4A148C),
                                Color(0xFF260845),
                              ],
                              shadowColor: const Color(0xFF16032A),
                              glowColor: const Color(0xFFD500F9),
                              textColor: Colors.white,
                              iconColor: const Color(0xFFE040FB),
                              height: 42,
                              depth: 3.5,
                              fontSize: 12.sp,
                              borderRadius: 20,
                              onPressed: _showReturnToHubDialog,
                            ),

                            // Coins Capsule
                            CoinBalanceWidget(key: _topCoinKey),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Center Logo & Level Stage Card
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Animated 3D Scramble Logo
                                const ScrambleLogo(size: 190),

                                const SizedBox(height: 24),

                                // Current Level Capsule Card
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(28),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                        sigmaX: 14, sigmaY: 14),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 20),
                                      decoration: BoxDecoration(
                                        color: Colors.black
                                            .withValues(alpha: 0.45),
                                        borderRadius: BorderRadius.circular(28),
                                        border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.22),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFFF4081)
                                                .withValues(alpha: 0.25),
                                            blurRadius: 20,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 14, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFF4081)
                                                  .withValues(alpha: 0.25),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
                                                color: const Color(0xFFFF4081)
                                                    .withValues(alpha: 0.5),
                                                width: 1,
                                              ),
                                            ),
                                            child: const Text(
                                              'KITTY STACK & SPELL',
                                              style: TextStyle(
                                                color: Color(0xFFEA80FC),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 2.0,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            'LEVEL $_currentLevel',
                                            style: const TextStyle(
                                              fontSize: 32,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                              letterSpacing: 2.0,
                                              shadows: [
                                                Shadow(
                                                  color: Color(0xFFD500F9),
                                                  blurRadius: 18,
                                                ),
                                                Shadow(
                                                  color: Colors.black54,
                                                  offset: Offset(0, 2),
                                                  blurRadius: 4,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Stack & spell letters to uncover secret words',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.white
                                                  .withValues(alpha: 0.75),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 24),

                                          // 1. PLAY NOW (with circular loader when clicked)
                                          App3DButton(
                                            text: 'PLAY NOW',
                                            icon: Icons.play_arrow_rounded,
                                            isLoading: _isPlayButtonTapped,
                                            height: 54,
                                            fontSize: 17,
                                            borderRadius: 27.0,
                                            width: double.infinity,
                                            gradientColors: const [
                                Color(0xFFE040FB),
                                Color(0xFF7C4DFF),
                              ],
                                            shadowColor: const Color(0xFF38006B),
                                            glowColor: const Color(0xFFD500F9),
                                            textColor: Colors.white,
                                            iconColor: Colors.white,
                                            onPressed: () async {
                                              final connectivity =
                                                  await Connectivity()
                                                      .checkConnectivity();
                                              if (connectivity.contains(
                                                  ConnectivityResult.none)) {
                                                Fluttertoast.showToast(
                                                    msg: "You're offline");
                                                return;
                                              }
                                              _handlePlayButton();
                                            },
                                          ),

                                          const SizedBox(height: 14),

                                          // 2. WATCH & EARN (3D Amber Button with coin badge)
                                          App3DButton.amber(
                                            text: 'WATCH AD & EARN',
                                            icon:
                                                Icons.play_circle_fill_rounded,
                                            coinBadge: true,
                                            height: 50,
                                            fontSize: 15,
                                            width: double.infinity,
                                            borderRadius: 25.0,
                                            onPressed: () {
                                              checkInternetAndProceed(context,
                                                  () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        AdPlaybackPage(
                                                      isRewardAd: true,
                                                      onAdComplete: () =>
                                                          _addCoins(
                                                              5, 'Ad Reward'),
                                                    ),
                                                  ),
                                                );
                                              });
                                            },
                                          ),

                                          const SizedBox(height: 14),

                                          // 3. SETTINGS
                                          App3DButton(
                                            text: 'SETTINGS',
                                            icon: Icons.settings_rounded,
                                            height: 48,
                                            fontSize: 14.5,
                                            width: double.infinity,
                                            borderRadius: 24.0,
                                            gradientColors: const [
                                              Color(0xFF512DA8),
                                              Color(0xFF311B92),
                                            ],
                                            shadowColor:
                                                const Color(0xFF1A0A38),
                                            glowColor: const Color(0xFF7E57C2),
                                            textColor: Colors.white,
                                            iconColor: Colors.white,
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const SettingsPage(),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const Spacer(),
                    ],
                  ),
                ),
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
                  Color(0xFFFF4081),
                  Color(0xFF00E5FF),
                  Color(0xFF00E676),
                  Colors.white,
                ],
                numberOfParticles: 40,
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
}
