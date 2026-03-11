import 'dart:convert';
import 'dart:ui';

import 'package:confetti/confetti.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../db/prefs.dart';
import '../widget/base_url.dart';
import '../widget/bg_container.dart';
import '../widget/coin_container.dart';
import '../widget/coin_service.dart';
import '../widget/button.dart';
import '../widget/get_level.dart';
import '../widget/level_button.dart';
import '../widget/sound.dart';
import '../widget/voyage_container.dart';
import 'ad_show.dart';
import 'home_screen.dart';

class SuccessScreen extends StatefulWidget {
  final int level;
  final int? coin;
  final int gridSize;
  final VoidCallback onNextLevel;
  final VoidCallback onBackToLevels;

  const SuccessScreen({
    super.key,
    required this.level,
    this.coin,
    required this.gridSize,
    required this.onNextLevel,
    required this.onBackToLevels,
  });

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _floatController;
  late AnimationController _bounceController;
  late Animation<double> _floatAnimation;
  late Animation<double> _bounceAnimation;

  // Yellow-Greenish Theme Colors (from commented code)
  static const Color primaryYellow = Color(0xFFFFD700); // Gold/Yellow
  static const Color lightYellow = Color(0xFFFFF59D);   // Light yellow
  static const Color greenAccent = Color(0xFFAEEA00);   // Lime green
  static const Color darkGreen = Color(0xFF64DD17);     // Green
  static const Color deepGreen = Color(0xFF33691E);     // Dark green for borders

  @override
  void initState() {
    super.initState();

    // Confetti Controller
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 5));
    _confettiController.play();

    // Float Animation for Coin
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: 0, end: -15).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Bounce Animation for Reward Badge
    _bounceController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    // Update level and add coins (original functionality)
    int nextLevel = widget.level + 1;
    Future.microtask(() {
      if (mounted) {
        final gameProvider = Provider.of<GameLevelProvider>(context, listen: false);
        gameProvider.updateGameLevel(widget.level + 1, widget.gridSize);
      }
    });

    AudioHelper().playWinnerSound();
    _checkConnectivityAndAddCoins();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _floatController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _checkConnectivityAndAddCoins() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      Fluttertoast.showToast(msg: "You're offline, coins couldn't be added");
    } else {
      _addCoins();
    }
  }

  Future<void> _addCoins() async {
    try {
      final coinProvider = Provider.of<CoinProvider>(context, listen: false);
      await coinProvider.addCoins(widget.coin ?? 0, isWinner: true);
      AudioHelper().playMoneySound();
    } catch (e) {
      print("Error adding coins: $e");
    }
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
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                    color: lightYellow.withOpacity(0.8), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: primaryYellow.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [greenAccent, darkGreen],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(
                      Icons.monetization_on_outlined,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Not Enough Coins!',
                    style: GoogleFonts.fredoka(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: deepGreen,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'You need 2 coins to start a game.\nWatch an ad to earn coins or return to the home screen.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: PillButton3D(
                          onTap: () {
                            AudioHelper().playButtonSound();
                            Navigator.pop(context);
                          },
                          color: Colors.white,
                          shadowColor: const Color(0xFFD1D5DB),
                          child: Text(
                            'RETURN',
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: darkGreen,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PillButton3D(
                          onTap: () {
                            AudioHelper().playButtonSound();
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AdPlaybackPage(
                                  onAdComplete: () {
                                    Provider.of<CoinProvider>(context,
                                        listen: false)
                                        .addCoins(5);
                                  },
                                ),
                              ),
                            );
                          },
                          color: primaryYellow,
                          shadowColor: const Color(0xFFFFA000),
                          child: Text(
                            'WATCH AD',
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Android back disable
      child: Scaffold(
        body: Stack(
          children: [
            // Yellow-Green Gradient Background (from commented code theme)
            Container(
              decoration:  BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    // Color(0xFFFFFDE7), // Very light yellow top
                    // Color(0xFFF1F8E9), // Light greenish bottom
                    Color(0xFF388E3C).withValues(alpha: 0.5),Color(0xFFFFFDE7)
                  ],
                ),
              ),
            ),

            // Confetti Background Layer
            const ConfettiBackground(),

            // Main Content
            SafeArea(
              child: Column(
                children: [
                  // Header with Home & Coin Balance
                  _buildHeader(),

                  // Main Success Content
                  Expanded(
                    child: SingleChildScrollView(
                      child: _buildMainContent(),
                    ),
                  ),

                  // Footer Buttons
                  // _buildFooter(),
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
                  Color(0xFFFFD700), // Gold
                  Color(0xFFAEEA00), // Lime
                  Color(0xFF64DD17), // Green
                  Color(0xFFFFEB3B), // Yellow
                  Color(0xFF8BC34A), // Light green
                ],
                numberOfParticles: 50,
                maxBlastForce: 60,
                minBlastForce: 20,
                gravity: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============== HEADER ==============
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Home Button - Yellow-Green Gradient (from commented code)
          GestureDetector(
            onTap: () {
              AudioHelper().playButtonSound();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
                    (route) => false,
              );
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [greenAccent, darkGreen],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border(
                  bottom: BorderSide(color: deepGreen, width: 4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    offset: const Offset(0, 4),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const Icon(
                Icons.home,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),

          // Coin Balance Display (Using your CoinBalanceWidget)
          const CoinBalanceWidget(),
        ],
      ),
    );
  }

  // ============== MAIN CONTENT ==============
  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),

          // Victory Heading
          Column(
            children: [
              // CONGRATS! Text with 3D effect - Yellow-Green Theme
              Stack(
                alignment: Alignment.center,
                children: [
                  // Shadow layer (bottom-most)
                  Text(
                    'CONGRATS!',
                    style: GoogleFonts.fredoka(
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      color: darkGreen,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                  ),

                  // Stroke/Border layer (white outline)
                  Text(
                    'CONGRATS!',
                    style: GoogleFonts.fredoka(
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 4
                        ..color = Colors.white,
                    ),
                  ),

                  // Fill layer (main color - Gold/Yellow)
                  Text(
                    'CONGRATS!',
                    style: GoogleFonts.fredoka(
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      color: primaryYellow,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Level Badge - Green theme
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: greenAccent, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: darkGreen.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Text(
                  'LEVEL ${widget.level} COMPLETE',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: deepGreen,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // Central Reward Display
          Stack(
            alignment: Alignment.center,
            children: [
              // Glow effect behind coin - Yellow
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryYellow.withOpacity(0.3),
                  boxShadow: [
                    BoxShadow(
                      color: primaryYellow.withOpacity(0.4),
                      blurRadius: 60,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),

              // Animated 3D Coin
              AnimatedBuilder(
                animation: _floatAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _floatAnimation.value),
                    child: child,
                  );
                },
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      center: Alignment(-0.3, -0.3),
                      radius: 0.8,
                      colors: [
                        Color(0xFFFFF59D), // Light yellow
                        primaryYellow,     // Gold
                      ],
                    ),
                    border: Border.all(
                      color: const Color(0xFFFFA000), // Darker gold border
                      width: 6,
                    ),
                    boxShadow: [
                      // Inner shadow effect
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 0,
                        offset: const Offset(-4, -4),
                        spreadRadius: -2,
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        blurRadius: 0,
                        offset: const Offset(4, 4),
                        spreadRadius: -2,
                      ),
                      // Outer shadow
                      BoxShadow(
                        color: const Color(0xFFFFA000).withOpacity(0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/coin.png',
                      width: 70,
                      height: 70,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Reward Amount Badge - Yellow/Gold
          AnimatedBuilder(
            animation: _bounceAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _bounceAnimation.value,
                child: child,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: primaryYellow,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryYellow.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Text(
                '+${widget.coin ?? 0} COINS',
                style: GoogleFonts.fredoka(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFFA000), // Darker gold text
                  letterSpacing: -1,
                ),
              ),
            ),
          ),

          const SizedBox(height: 140),
          AppButton(
            // label: 'LEVEL ${widget.level + 1}',
            label: 'NEXT LEVEL',
            onTap: () async {
              AudioHelper().playButtonSound();
              final coinProvider =
              Provider.of<CoinProvider>(context, listen: false);
              if (coinProvider.coins < 2) {
                _showInsufficientCoinsDialog();
                return;
              }
              await coinProvider.undoCoins(2);
              AudioHelper().playMoneySound();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('2 coins deducted to start the game'),
                    backgroundColor: deepGreen,
                  ),
                );
                Navigator.pop(context);
                widget.onNextLevel();
              }
            },
            width: 200,
            // width: double.infinity, // Full width
          ),
          // Voyage Counter (Using your existing widget)
          // FutureBuilder<int>(
          //   future: Prefs.getMaxLevel(widget.gridSize),
          //   builder: (context, snapshot) {
          //     return VoyageCounter(count: snapshot.data ?? widget.level);
          //   },
          // ),
          //
          // const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ============== FOOTER ==============
  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Primary Action Button (Next Level) - Yellow-Green Gradient
          // PillButton3D(
          //   onTap: () async {
          //     AudioHelper().playButtonSound();
          //     final coinProvider =
          //     Provider.of<CoinProvider>(context, listen: false);
          //     if (coinProvider.coins < 2) {
          //       _showInsufficientCoinsDialog();
          //       return;
          //     }
          //     await coinProvider.undoCoins(2);
          //     AudioHelper().playMoneySound();
          //     if (mounted) {
          //       ScaffoldMessenger.of(context).showSnackBar(
          //         const SnackBar(
          //           content: Text('2 coins deducted to start the game'),
          //           backgroundColor: darkGreen,
          //         ),
          //       );
          //       Navigator.pop(context);
          //       widget.onNextLevel();
          //     }
          //   },
          //   // Gradient effect using container decoration in button
          //   color: greenAccent,
          //   shadowColor: deepGreen,
          //   child: Text(
          //     'LEVEL ${widget.level + 1}',
          //     style: GoogleFonts.fredoka(
          //       fontSize: 28,
          //       color: Colors.white,
          //       letterSpacing: 2,
          //       shadows: [
          //         Shadow(
          //           color: deepGreen.withOpacity(0.5),
          //           blurRadius: 4,
          //           offset: const Offset(0, 2),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
          AppButton(
            label: 'LEVEL ${widget.level + 1}',
            onTap: () async {
              AudioHelper().playButtonSound();
              final coinProvider =
              Provider.of<CoinProvider>(context, listen: false);
              if (coinProvider.coins < 2) {
                _showInsufficientCoinsDialog();
                return;
              }
              await coinProvider.undoCoins(2);
              AudioHelper().playMoneySound();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('2 coins deducted to start the game'),
                    backgroundColor: deepGreen,
                  ),
                );
                Navigator.pop(context);
                widget.onNextLevel();
              }
            },
            width: 200,
            // width: double.infinity, // Full width
          ),
          // const SizedBox(height: 16),

          // Secondary Action Button (Replay) - Light yellow/green
        ],
      ),
    );
  }
}

// ============== CUSTOM WIDGETS ==============

// Confetti Background Animation
class ConfettiBackground extends StatefulWidget {
  const ConfettiBackground({super.key});

  @override
  State<ConfettiBackground> createState() => _ConfettiBackgroundState();
}

class _ConfettiBackgroundState extends State<ConfettiBackground>
    with SingleTickerProviderStateMixin {
  late List<ConfettiPiece> _confettiPieces;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _confettiPieces = List.generate(20, (index) => ConfettiPiece.random());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: _confettiPieces.map((piece) {
            final progress = (_controller.value + piece.delay) % 1.0;
            return Positioned(
              left: piece.x * MediaQuery.of(context).size.width,
              top: -20 + (progress * (MediaQuery.of(context).size.height + 100)),
              child: Transform.rotate(
                angle: progress * 6.28 * piece.rotationSpeed,
                child: Container(
                  width: piece.size,
                  height: piece.size,
                  decoration: BoxDecoration(
                    color: piece.color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class ConfettiPiece {
  final double x;
  final double delay;
  final double size;
  final double rotationSpeed;
  final Color color;

  ConfettiPiece({
    required this.x,
    required this.delay,
    required this.size,
    required this.rotationSpeed,
    required this.color,
  });

  factory ConfettiPiece.random() {
    // Yellow-Greenish confetti colors
    final colors = [
      const Color(0xFFFFD700), // Gold
      const Color(0xFFAEEA00), // Lime
      const Color(0xFF64DD17), // Green
      const Color(0xFFFFF59D), // Light yellow
      const Color(0xFF8BC34A), // Light green
      const Color(0xFFFFEB3B), // Yellow
    ];

    return ConfettiPiece(
      x: 0.1 + (0.8 * (DateTime.now().microsecond % 1000) / 1000),
      delay: (DateTime.now().millisecond % 5000) / 5000,
      size: 6 + (DateTime.now().microsecond % 8).toDouble(),
      rotationSpeed: 0.5 + (DateTime.now().millisecond % 1000) / 1000,
      color: colors[DateTime.now().microsecond % colors.length],
    );
  }
}

// 3D Pill Button
class PillButton3D extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  final Color color;
  final Color shadowColor;
  final Color? borderColor;

  const PillButton3D({
    super.key,
    required this.onTap,
    required this.child,
    required this.color,
    required this.shadowColor,
    this.borderColor,
  });

  @override
  State<PillButton3D> createState() => _PillButton3DState();
}

class _PillButton3DState extends State<PillButton3D> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(32),
          border: Border(
            bottom: BorderSide(
              color: widget.borderColor ?? widget.shadowColor,
              width: _isPressed ? 2 : 6,
            ),
          ),
          boxShadow: [
            if (!_isPressed)
              BoxShadow(
                color: widget.shadowColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
          ],
        ),
        transform: _isPressed
            ? Matrix4.translationValues(0, 4, 0)
            : Matrix4.identity(),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Glossy highlight
            Positioned(
              top: 4,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.6,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            Center(child: widget.child),
          ],
        ),
      ),
    );
  }
}



















































































// import 'dart:convert';
// import 'dart:ui';
//
// import 'package:confetti/confetti.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:http/http.dart' as http;
//
// import '../db/prefs.dart';
// import '../widget/base_url.dart';
// import '../widget/bg_container.dart';
// import '../widget/coin_container.dart';
// import '../widget/coin_service.dart';
// import '../widget/button.dart';
// import '../widget/get_level.dart';
// import '../widget/level_button.dart';
// import '../widget/sound.dart';
// import '../widget/voyage_container.dart';
// import 'ad_show.dart';
// import 'home_screen.dart';
//
// class SuccessScreen extends StatefulWidget {
//   final int level;
//   final int? coin;
//   final int gridSize;
//   final VoidCallback onNextLevel;
//   final VoidCallback onBackToLevels;
//
//   const SuccessScreen({
//     super.key,
//     required this.level,
//     this.coin,
//     required this.gridSize,
//     required this.onNextLevel,
//     required this.onBackToLevels,
//   });
//
//   @override
//   State<SuccessScreen> createState() => _SuccessScreenState();
// }
//
// class _SuccessScreenState extends State<SuccessScreen> {
//   late ConfettiController _confettiController;
//
//   @override
//   void initState() {
//     super.initState();
//     _confettiController =
//         ConfettiController(duration: const Duration(seconds: 5));
//     _confettiController.play();
//
//     int nextLevel = widget.level + 1;
//     // _updateGameLevel(nextLevel, widget.gridSize);
//     Future.microtask(() {
//       if (mounted) {
//         final gameProvider = Provider.of<GameLevelProvider>(context, listen: false);
//         gameProvider.updateGameLevel(widget.level + 1, widget.gridSize);
//       }
//     });
//     AudioHelper().playWinnerSound();
//     _checkConnectivityAndAddCoins();
//   }
//
//   @override
//   void dispose() {
//     _confettiController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _checkConnectivityAndAddCoins() async {
//     final connectivity = await Connectivity().checkConnectivity();
//     if (connectivity.contains(ConnectivityResult.none)) {
//       Fluttertoast.showToast(msg: "You're offline, coins couldn't be added");
//     } else {
//       _addCoins();
//     }
//   }
//
//   Future<void> _addCoins() async {
//     try {
//       final coinProvider = Provider.of<CoinProvider>(context, listen: false);
//       await coinProvider.addCoins(widget.coin ?? 0, isWinner: true);
//       AudioHelper().playMoneySound();
//     } catch (e) {
//       print("Error adding coins: $e");
//     }
//   }
//
//   // Future<void> _updateGameLevel(int level, int gridSize) async {
//   //   String apiUrl = '$LURL/api/gameLevel/update';
//   //   final prefs = await SharedPreferences.getInstance();
//   //   final token = prefs.getString('auth_token');
//   //
//   //   final body = {
//   //     "gameName": "Word Puzzle",
//   //     "gameLevel": level,
//   //     "gridSize": "$gridSize",
//   //   };
//   //
//   //   try {
//   //     final response = await http.post(
//   //       Uri.parse(apiUrl),
//   //       headers: {
//   //         'Content-Type': 'application/json',
//   //         'Authorization': '$token',
//   //       },
//   //       body: jsonEncode(body),
//   //     );
//   //     if (response.statusCode != 200) {
//   //       print('Failed to update game level: ${response.body}');
//   //     }
//   //   } catch (e) {
//   //     print('Error updating game level: $e');
//   //   }
//   // }
//
//   void _showInsufficientCoinsDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         contentPadding: EdgeInsets.zero,
//         content: ClipRRect(
//           borderRadius: BorderRadius.circular(30),
//           child: BackdropFilter(
//             filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//             child: Container(
//               padding: const EdgeInsets.all(30),
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.15),
//                 borderRadius: BorderRadius.circular(30),
//                 border: Border.all(
//                     color: Colors.white.withOpacity(0.2), width: 1.5),
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const Text(
//                     'Not Enough Coins!',
//                     style: TextStyle(
//                       fontSize: 24,
//                       fontWeight: FontWeight.w900,
//                       color: Colors.white,
//                       shadows: [
//                         Shadow(
//                             color: Colors.black45,
//                             offset: Offset(0, 2),
//                             blurRadius: 4),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 15),
//                   Text(
//                     'You need 2 coins to start a game.\nWatch an ad to earn coins or return to the home screen.',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       fontSize: 16,
//                       color: Colors.white.withOpacity(0.9),
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   const SizedBox(height: 30),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     children: [
//                       Expanded(
//                         child: AppButton(
//                           label: 'RETURN',
//                           onTap: () {
//                             AudioHelper().playButtonSound();
//                             Navigator.pop(context);
//                           },
//                         ),
//                       ),
//                       const SizedBox(width: 10),
//                       Expanded(
//                         child: AppButton(
//                           label: 'WATCH AD',
//                           onTap: () {
//                             AudioHelper().playButtonSound();
//                             Navigator.pop(context);
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => AdPlaybackPage(
//                                   onAdComplete: () {
//                                     Provider.of<CoinProvider>(context,
//                                             listen: false)
//                                         .addCoins(5);
//                                   },
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: () async {
//         return false; // Android back disable
//       },
//       child: Scaffold(
//         body: Stack(
//           children: [
//             BackgroundContainer(
//               child: SafeArea(
//                 child: SingleChildScrollView(
//                   child: Column(
//                     children: [
//                       const SizedBox(height: 60),
//                       const Text(
//                         'CONGRATS!',
//                         style: TextStyle(
//                           fontSize: 48,
//                           fontWeight: FontWeight.w900,
//                           color: Colors.white,
//                           letterSpacing: 2,
//                           shadows: [
//                             Shadow(
//                                 color: Colors.black45,
//                                 offset: Offset(0, 4),
//                                 blurRadius: 8),
//                           ],
//                         ),
//                       ),
//                       const Text(
//                         'You Win',
//                         style: TextStyle(
//                           fontSize: 28,
//                           fontWeight: FontWeight.w500,
//                           color: Colors.white,
//                           shadows: [
//                             Shadow(
//                                 color: Colors.black45,
//                                 offset: Offset(0, 2),
//                                 blurRadius: 4),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 20),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Image.asset('assets/coin.png', width: 40, height: 40),
//                           const SizedBox(width: 12),
//                           Text(
//                             '+ ${widget.coin}',
//                             style: const TextStyle(
//                               fontSize: 32,
//                               fontWeight: FontWeight.w900,
//                               color: Color(0xFFFFD700),
//                               shadows: [
//                                 Shadow(
//                                     color: Colors.black45,
//                                     offset: Offset(0, 2),
//                                     blurRadius: 4),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 50),
//                       FutureBuilder<int>(
//                         future: Prefs.getMaxLevel(widget.gridSize),
//                         builder: (context, snapshot) {
//                           return VoyageCounter(
//                               count: snapshot.data ?? widget.level);
//                         },
//                       ),
//                       const SizedBox(height: 60),
//                       LevelButton(
//                         label: 'LEVEL ${widget.level + 1}',
//                         onPressed: () async {
//                           AudioHelper().playButtonSound();
//                           final coinProvider =
//                               Provider.of<CoinProvider>(context, listen: false);
//                           if (coinProvider.coins < 2) {
//                             _showInsufficientCoinsDialog();
//                             return;
//                           }
//                           await coinProvider.undoCoins(2);
//                           AudioHelper().playMoneySound();
//                           if (mounted) {
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               const SnackBar(
//                                   content:
//                                       Text('2 coins deducted to start the game')),
//                             );
//                             Navigator.pop(context);
//                             widget.onNextLevel();
//                           }
//                         },
//                       ),
//                       const SizedBox(height: 40),
//                       Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 30.0),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             GestureDetector(
//                               onTap: () {
//                                 AudioHelper().playButtonSound();
//                                 Navigator.pushAndRemoveUntil(
//                                   context,
//                                   MaterialPageRoute(
//                                       builder: (context) => const HomePage()),
//                                   (route) => false,
//                                 );
//                               },
//                               child: Container(
//                                 padding: const EdgeInsets.all(12),
//                                 // decoration: const BoxDecoration(
//                                 //   shape: BoxShape.circle,
//                                 //   color: Color(0xFF3700FF),
//                                 //   boxShadow: [
//                                 //     BoxShadow(
//                                 //         color: Colors.black38,
//                                 //         blurRadius: 8,
//                                 //         offset: Offset(0, 4)),
//                                 //   ],
//                                 // ),
//                                 decoration: BoxDecoration(
//                                   gradient: const LinearGradient(
//                                     colors: [Color(0xFFAEEA00), Color(0xFF64DD17)],
//                                     begin: Alignment.topCenter,
//                                     end: Alignment.bottomCenter,
//                                   ),
//                                   borderRadius: BorderRadius.circular(30),
//                                   border: Border(
//                                     bottom: BorderSide(
//                                         color: const Color(0xFF33691E), width: 4),
//                                   ),
//                                   boxShadow: [
//                                     BoxShadow(
//                                       color: Colors.black.withOpacity(0.2),
//                                       offset: const Offset(0, 4),
//                                       blurRadius: 6,
//                                     ),
//                                   ],
//                                 ),
//                                 child: const Icon(Icons.home,
//                                     color: Colors.white, size: 28),
//                               ),
//                             ),
//                             const CoinBalanceWidget(),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//             Align(
//               alignment: Alignment.topCenter,
//               child: ConfettiWidget(
//                 confettiController: _confettiController,
//                 blastDirectionality: BlastDirectionality.explosive,
//                 shouldLoop: false,
//                 colors: const [
//                   Colors.blue,
//                   Colors.red,
//                   Colors.yellow,
//                   Colors.green,
//                   Colors.purple
//                 ],
//                 numberOfParticles: 50,
//                 maxBlastForce: 60,
//                 minBlastForce: 20,
//                 gravity: 0.3,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
