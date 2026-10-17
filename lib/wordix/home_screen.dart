import 'dart:ui';
import 'package:confetti/confetti.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word_puzzle/view/ad_show.dart';
import 'package:word_puzzle/view/game_selection_screen.dart';
import 'package:word_puzzle/view/setting_screen.dart';
import 'package:word_puzzle/widget/app_3d_button.dart';
import 'package:word_puzzle/widget/bg_container.dart';
import 'package:word_puzzle/widget/checkinternet.dart';
import 'package:word_puzzle/widget/coin_grant_dialog.dart';
import 'package:word_puzzle/widget/coin_container.dart';
import 'package:word_puzzle/widget/coin_service.dart';
import 'package:word_puzzle/widget/floating_words_background.dart';
import 'package:word_puzzle/widget/get_level.dart';
import 'package:word_puzzle/widget/sound.dart';
import 'package:word_puzzle/widget/voyage_container.dart';
import 'package:word_puzzle/wordix/word_search.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ConfettiController _confettiController =
      ConfettiController(duration: const Duration(seconds: 2));
  final GlobalKey<CoinGrantOverlayState> _coinGrantKey = GlobalKey();
  final GlobalKey _topCoinKey = GlobalKey();
  bool _isPlayButtonTapped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<GameLevelProvider>(context, listen: false).refresh();
      }
    });
    _checkAndGiveDailyReward();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _checkAndGiveDailyReward() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email')?.trim().toLowerCase() ?? '';
    final userId = prefs.getString('user_id')?.trim() ?? '';
    final identifier =
        email.isNotEmpty ? email : (userId.isNotEmpty ? userId : 'guest');

    final today = DateTime.now();
    final todayString = "${today.year}-${today.month}-${today.day}";

    final claimKey = 'daily_reward_$identifier';
    final lastClaimDate = prefs.getString(claimKey);

    if (lastClaimDate == todayString) {
      return;
    }

    await _addCoins(20, "Daily Reward");
    await prefs.setString(claimKey, todayString);
    await prefs.setString('last_claim_date', todayString);
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
      final coinProvider = Provider.of<CoinProvider>(context, listen: false);
      if (coinProvider.coins < 4) {
        _showInsufficientCoinsDialog();
        return;
      }

      await Future.delayed(const Duration(milliseconds: 350));
      await coinProvider.undoCoins(4);
      AudioHelper().playMoneySound();
      Fluttertoast.showToast(msg: "4 coins deducted to start the game");

      if (!mounted) return;
      final gameLevelProvider =
          Provider.of<GameLevelProvider>(context, listen: false);
      final gridSize = gameLevelProvider.currentGridSize;
      final maxLevel = gameLevelProvider.currentLevel;

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                WordSearchPage(gridSize: gridSize, initialLevel: maxLevel),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error starting game: $e');
    } finally {
      if (mounted) setState(() => _isPlayButtonTapped = false);
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
                  color: const Color(0xFF0F1B2B).withOpacity(0.95),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                      color: const Color(0xFFFF5252).withOpacity(0.5),
                      width: 1.5),
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
                      child: const Icon(Icons.monetization_on_rounded,
                          color: Color(0xFFFFD54F), size: 36),
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
                      "You need at least 4 coins to start a new word puzzle.",
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
                  color: const Color(0xFF071426).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.45),
                    width: 1.6,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.22),
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
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              const Color(0xFF00E5FF).withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                      ),
                      child: const Icon(
                        Icons.sports_esports_rounded,
                        color: Color(0xFF00E5FF),
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
                          child: App3DButton.cyan(
                            text: 'YES',
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
            // 1. Dynamic Wallpaper Background with Dark Cyber-Oceanic Scrim
            Positioned.fill(
              child: BackgroundContainer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF001428).withOpacity(0.78),
                        const Color(0xFF030D1B).withOpacity(0.85),
                        const Color(0xFF000814).withOpacity(0.92),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Top ambient cyan light beam
                      Positioned(
                        top: -100,
                        left: 0,
                        right: 0,
                        height: 350,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: const Alignment(0, -0.4),
                              radius: 0.9,
                              colors: [
                                const Color(0xFF00E5FF).withOpacity(0.20),
                                Colors.transparent,
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

            // 2. Floating Animated Words & Letters Overlay
            const FloatingWordsBackground(isWordix: true),

            // 3. Main Foreground Content
            SafeArea(
              child: Column(
                children: [
                  // Top HUD: Arcade Hub Button on Left & Coins on Right
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
                            Color(0xFF0F3057),
                            Color(0xFF002244),
                          ],
                          shadowColor: const Color(0xFF001122),
                          glowColor: const Color(0xFF00E5FF),
                          textColor: Colors.white,
                          iconColor: const Color(0xFF00E5FF),
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

                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            const SizedBox(height: 16),

                            // Wordix Hero Logo Display
                            Center(
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00E5FF)
                                          .withOpacity(0.3),
                                      blurRadius: 32,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  'assets/icon/icon3.png',
                                  width: 125,
                                  height: 125,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.extension_rounded,
                                    color: Color(0xFF00E5FF),
                                    size: 80,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 28),

                            // Level Display Dial
                            Consumer<GameLevelProvider>(
                              builder: (context, provider, child) {
                                return VoyageCounter(
                                    count: provider.currentLevel);
                              },
                            ),

                            const SizedBox(height: 34),

                            // Full Width 3D PLAY NOW Button (Electric Cyan)
                            App3DButton.cyan(
                              text: 'PLAY NOW',
                              icon: Icons.play_arrow_rounded,
                              isLoading: _isPlayButtonTapped,
                              height: 54,
                              fontSize: 17,
                              width: double.infinity,
                              onPressed: () async {
                                final connectivity =
                                    await Connectivity().checkConnectivity();
                                if (connectivity
                                    .contains(ConnectivityResult.none)) {
                                  Fluttertoast.showToast(msg: "You're offline");
                                } else {
                                  _handlePlayButton();
                                }
                              },
                            ),

                            const SizedBox(height: 14),

                            // Watch Ad & Earn Coins 3D Button (Full Width)
                            App3DButton.amber(
                              text: 'WATCH AD & EARN',
                              icon: Icons.play_circle_fill_rounded,
                              coinBadge: true,
                              height: 50,
                              fontSize: 15,
                              width: double.infinity,
                              onPressed: () {
                                checkInternetAndProceed(context, () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AdPlaybackPage(
                                        isRewardAd: true,
                                        onAdComplete: () =>
                                            _addCoins(5, 'Ad Reward'),
                                      ),
                                    ),
                                  );
                                });
                              },
                            ),

                            const SizedBox(height: 14),

                            // Full Width 3D Settings Button
                            App3DButton(
                              text: 'SETTINGS',
                              icon: Icons.settings_rounded,
                              height: 48,
                              fontSize: 14.5,
                              width: double.infinity,
                              color: const Color(0xFF0A2239),
                              topHighlightColor: const Color(0xFF1B4965),
                              shadowColor: const Color(0xFF02101E),
                              borderColor:
                                  const Color(0xFF00E5FF).withOpacity(0.35),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SettingsPage(),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Top Confetti Explosion
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
