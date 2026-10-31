// ignore_for_file: avoid_print
import 'dart:ui';
import 'package:confetti/confetti.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:word_puzzle/view/ad_show.dart';
import 'package:word_puzzle/view/game_selection_screen.dart';
import 'package:word_puzzle/view/setting_screen.dart';
import 'package:word_puzzle/widget/app_3d_button.dart';
import 'package:word_puzzle/widget/checkinternet.dart';
import 'package:word_puzzle/widget/coin_container.dart';
import 'package:word_puzzle/widget/coin_grant_dialog.dart';
import 'package:word_puzzle/widget/coin_service.dart';
import 'package:word_puzzle/widget/sound.dart';

/// Reusable 3D Animated Home Screen for all 4 games
/// (Wordix, Crossword, Word Scramble, Balloon Rescue)
/// Matches the clean, unboxed, circular-level-dial design with zero ScreenUtil dependencies.
class CommonGameHomeScreen extends StatefulWidget {
  final String gameTagline;
  final String gameSubtitle;
  final Widget logoWidget;
  final Widget background;
  final int currentLevel;
  final Color primaryColor;
  final Color accentColor;
  final List<Color>? arcadeHubGradient;
  final Color? arcadeHubShadow;
  final List<Color>? settingsGradient;
  final Color? settingsShadow;
  final List<Color>? playButtonGradient;
  final Color? playButtonShadow;
  final Color? playButtonTextColor;
  final VoidCallback onPlay;
  final VoidCallback? onSelectLevel;
  final int requiredCoins;

  const CommonGameHomeScreen({
    super.key,
    required this.gameTagline,
    required this.gameSubtitle,
    required this.logoWidget,
    required this.background,
    required this.currentLevel,
    required this.primaryColor,
    required this.accentColor,
    this.arcadeHubGradient,
    this.arcadeHubShadow,
    this.settingsGradient,
    this.settingsShadow,
    this.playButtonGradient,
    this.playButtonShadow,
    this.playButtonTextColor,
    required this.onPlay,
    this.onSelectLevel,
    this.requiredCoins = 4,
  });

  @override
  State<CommonGameHomeScreen> createState() => _CommonGameHomeScreenState();
}

class _CommonGameHomeScreenState extends State<CommonGameHomeScreen> {
  final ConfettiController _confettiController =
      ConfettiController(duration: const Duration(seconds: 2));
  final GlobalKey<CoinGrantOverlayState> _coinGrantKey = GlobalKey();
  final GlobalKey _topCoinKey = GlobalKey();
  bool _isPlayButtonTapped = false;

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  List<Color> get _effectiveArcadeHubGradient {
    if (widget.arcadeHubGradient != null) return widget.arcadeHubGradient!;
    final HSLColor hsl = HSLColor.fromColor(widget.primaryColor);
    final dark1 =
        hsl.withLightness((hsl.lightness * 0.32).clamp(0.12, 0.28)).toColor();
    final dark2 =
        hsl.withLightness((hsl.lightness * 0.18).clamp(0.06, 0.16)).toColor();
    return [dark1, dark2];
  }

  Color get _effectiveArcadeHubShadow {
    if (widget.arcadeHubShadow != null) return widget.arcadeHubShadow!;
    final HSLColor hsl = HSLColor.fromColor(widget.primaryColor);
    return hsl
        .withLightness((hsl.lightness * 0.10).clamp(0.03, 0.10))
        .toColor();
  }

  List<Color> get _effectiveSettingsGradient {
    if (widget.settingsGradient != null) return widget.settingsGradient!;
    return [
      const Color(0xFF1B2A38),
      const Color(0xFF0F1B24),
    ];
  }

  Color get _effectiveSettingsShadow {
    if (widget.settingsShadow != null) return widget.settingsShadow!;
    return const Color(0xFF080F14);
  }

  Future<void> _addCoins(int coins, String source) async {
    try {
      await _coinGrantKey.currentState?.showReward(
        coins: coins,
        source: source,
      );
    } catch (e) {
      debugPrint("Error in addCoins: $e");
    }
  }

  void _showReturnToHubDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          content: ClipRRect(
            borderRadius: BorderRadius.circular(24.0),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 24.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E).withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(
                    color: widget.primaryColor.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 28,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 58.0,
                      height: 58.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            widget.accentColor,
                            widget.primaryColor,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.primaryColor.withValues(alpha: 0.4),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.videogame_asset_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      'RETURN TO HUB?',
                      style: GoogleFonts.fredoka(
                        fontSize: 20.0,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Are you sure you want to exit to the Arcade Game Hub?',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fredoka(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w400,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 22.0),
                    Row(
                      children: [
                        Expanded(
                          child: App3DButton(
                            height: 44.0,
                            borderRadius: 14.0,
                            gradientColors: const [
                              Color(0xFF37474F),
                              Color(0xFF263238),
                            ],
                            shadowColor: const Color(0xFF102027),
                            textColor: Colors.white70,
                            text: 'CANCEL',
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: App3DButton(
                            height: 44.0,
                            borderRadius: 14.0,
                            gradientColors: [
                              widget.accentColor,
                              widget.primaryColor,
                            ],
                            shadowColor:
                                widget.primaryColor.withValues(alpha: 0.5),
                            textColor: Colors.white,
                            text: 'EXIT HUB',
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const GameSelectionScreen(),
                                ),
                                (route) => false,
                              );
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

  void _showInsufficientCoinsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        contentPadding: EdgeInsets.zero,
        content: ClipRRect(
          borderRadius: BorderRadius.circular(28.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(26.0),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(28.0),
                border: Border.all(
                  color: widget.primaryColor.withValues(alpha: 0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.primaryColor.withValues(alpha: 0.25),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64.0,
                    height: 64.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD54F), Color(0xFFFF9100)],
                      ),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: widget.primaryColor.withValues(alpha: 0.5),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.monetization_on_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 18.0),
                  Text(
                    'NOT ENOUGH COINS!',
                    style: GoogleFonts.fredoka(
                      fontSize: 22.0,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  Text(
                    'You need ${widget.requiredCoins} coins to play this level.\nWatch a quick ad to claim free bonus coins!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 14.0,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  Row(
                    children: [
                      Expanded(
                        child: App3DButton(
                          height: 48.0,
                          color: Colors.white.withValues(alpha: 0.15),
                          topHighlightColor:
                              Colors.white.withValues(alpha: 0.25),
                          shadowColor: Colors.black45,
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'RETURN',
                            style: GoogleFonts.fredoka(
                              fontSize: 14.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: App3DButton(
                          height: 48.0,
                          color: widget.primaryColor,
                          topHighlightColor: widget.accentColor,
                          shadowColor:
                              widget.primaryColor.withValues(alpha: 0.4),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AdPlaybackPage(
                                  isRewardAd: true,
                                  onAdComplete: () {
                                    Provider.of<CoinProvider>(context,
                                            listen: false)
                                        .addCoins(5);
                                  },
                                ),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.ondemand_video_rounded,
                                  color: Colors.white, size: 16),
                              const SizedBox(width: 6.0),
                              Text(
                                '+5 COINS',
                                style: GoogleFonts.fredoka(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ],
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
      ),
    );
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
      if (coinProvider.coins < widget.requiredCoins) {
        setState(() => _isPlayButtonTapped = false);
        _showInsufficientCoinsDialog();
        return;
      }

      // Smooth spinner delay
      await Future.delayed(const Duration(milliseconds: 350));
      await coinProvider.undoCoins(widget.requiredCoins);
      AudioHelper().playMoneySound();
      Fluttertoast.showToast(
          msg: "${widget.requiredCoins} coins deducted to start the game");

      if (mounted) {
        widget.onPlay();
      }
    } catch (e) {
      debugPrint("Error starting game: $e");
    } finally {
      if (mounted) {
        setState(() => _isPlayButtonTapped = false);
      }
    }
  }

  /// Circular Level Dial (Ditto to Wordix VoyageCounter style shown in target design)
  Widget _buildCircularLevelDial(double size) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Outer Neon Aura Ring
          Container(
            width: size * 0.95,
            height: size * 0.95,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.accentColor.withValues(alpha: 0.25),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.accentColor.withValues(alpha: 0.15),
                  blurRadius: 36,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),

          // 2. Rotating Arc Accent
          ShaderMask(
            shaderCallback: (rect) => SweepGradient(
              startAngle: 0.0,
              endAngle: 3.14159 * 2,
              stops: const [0.72, 1.0],
              colors: [
                Colors.transparent,
                widget.accentColor,
              ],
            ).createShader(rect),
            child: Container(
              width: size * 0.88,
              height: size * 0.88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
              ),
            ),
          ),

          // 3. Central Frosted Glass Circle
          ClipRRect(
            borderRadius: BorderRadius.circular(size),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                width: size * 0.78,
                height: size * 0.78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.45),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.primaryColor.withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Accent Line
                    Container(
                      width: 36,
                      height: 2.5,
                      decoration: BoxDecoration(
                        color: widget.accentColor,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: widget.accentColor,
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'LVL',
                      style:TextStyle(
                        fontSize: 14,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          '${widget.currentLevel}',
                          style:TextStyle(
                            fontSize: widget.currentLevel > 99 ? 52 : 62,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.05,
                            shadows: [
                              Shadow(
                                color: widget.accentColor,
                                blurRadius: 18,
                              ),
                              const Shadow(
                                color: Colors.black54,
                                offset: Offset(0, 2),
                                blurRadius: 4,
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

          // 4. Circular Tech Tick Marks
          ...List.generate(8, (index) {
            return Transform.rotate(
              angle: (index * 45) * 3.14159 / 180,
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: 2,
                  height: index % 2 == 0 ? 10 : 6,
                  margin: EdgeInsets.only(top: size * 0.02),
                  decoration: BoxDecoration(
                    color: index % 2 == 0
                        ? widget.accentColor
                        : Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isCompact = screenSize.height < 700;
    final double dialSize = isCompact ? 170.0 : 200.0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _showReturnToHubDialog();
        }
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Dynamic Atmosphere Background
            widget.background,

            // 2. Confetti Cannon Layer
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  Color(0xFFFFD54F),
                  Color(0xFFFF9100),
                  Color(0xFF00E676),
                  Color(0xFF00E5FF),
                  Color(0xFFE040FB),
                  Colors.white,
                ],
                numberOfParticles: 40,
                maxBlastForce: 45,
                minBlastForce: 15,
                gravity: 0.3,
              ),
            ),

            // 3. Foreground Content
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
                        App3DButton(
                          text: 'ARCADE HUB',
                          icon: Icons.arrow_back_ios_new_rounded,
                          gradientColors: _effectiveArcadeHubGradient,
                          shadowColor: _effectiveArcadeHubShadow,
                          glowColor: null,
                          textColor: Colors.white,
                          iconColor: widget.accentColor,
                          height: 42,
                          depth: 3.5,
                          fontSize: 12.5,
                          borderRadius: 20.0,
                          onPressed: _showReturnToHubDialog,
                        ),
                        CoinBalanceWidget(key: _topCoinKey),
                      ],
                    ),
                  ),

                  // Middle Content: Fully Unboxed Design matching Target Image 1
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: isCompact ? 8.0 : 16.0),

                          // Game Hero Logo
                          widget.logoWidget,

                          SizedBox(height: isCompact ? 14.0 : 24.0),

                          // Circular Level Dial (No ugly box!)
                          _buildCircularLevelDial(dialSize),

                          SizedBox(height: isCompact ? 20.0 : 32.0),
                          SizedBox(height: 25),

                          // 1. PLAY NOW (3D Pill Button)
                          App3DButton(
                            text: 'PLAY NOW',
                            icon: Icons.play_arrow_rounded,
                            isLoading: _isPlayButtonTapped,
                            height: 52,
                            fontSize: 17,
                            borderRadius: 26.0,
                            width: double.infinity,
                            gradientColors: widget.playButtonGradient ??
                                [
                                  widget.accentColor,
                                  widget.primaryColor,
                                ],
                            shadowColor: widget.playButtonShadow ??
                                widget.primaryColor.withValues(alpha: 0.6),
                            glowColor: widget.accentColor,
                            textColor:
                                widget.playButtonTextColor ?? Colors.white,
                            iconColor:
                                widget.playButtonTextColor ?? Colors.white,
                            onPressed: _handlePlayButton,
                          ),

                          const SizedBox(height: 14.0),

                          // 2. WATCH & EARN (3D Pill Button with Coin)
                          App3DButton.amber(
                            text: 'WATCH & EARN',
                            icon: Icons.play_circle_fill_rounded,
                            coinBadge: true,
                            height: 50,
                            fontSize: 15,
                            width: double.infinity,
                            borderRadius: 25.0,
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

                          const SizedBox(height: 14.0),

                          // 3. SETTINGS (3D Pill Button with Cog)
                          App3DButton(
                            text: 'SETTINGS',
                            icon: Icons.settings_rounded,
                            height: 48,
                            fontSize: 14.5,
                            width: double.infinity,
                            borderRadius: 24.0,
                            gradientColors: _effectiveSettingsGradient,
                            shadowColor: _effectiveSettingsShadow,
                            textColor: Colors.white,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SettingsPage(),
                                ),
                              );
                            },
                          ),

                          // 4. (Optional) SELECT LEVEL
                          if (widget.onSelectLevel != null) ...[
                            const SizedBox(height: 14.0),
                            App3DButton(
                              text: 'SELECT LEVEL',
                              icon: Icons.grid_view_rounded,
                              height: 48,
                              fontSize: 14.5,
                              width: double.infinity,
                              borderRadius: 24.0,
                              gradientColors: [
                                widget.accentColor,
                                widget.primaryColor,
                              ],
                              shadowColor: widget.primaryColor
                                  .withValues(alpha: 0.6),
                              textColor: Colors.white,
                              onPressed: widget.onSelectLevel,
                            ),
                          ],

                          const SizedBox(height: 24.0),
                        ],
                      ),
                    ),
                  ),
                ],
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
}
