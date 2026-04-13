import 'dart:convert';
import 'dart:ui';

import 'package:confetti/confetti.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../widget/base_url.dart';
import '../widget/bg_container.dart';
import '../widget/button.dart';
import '../widget/checkinternet.dart';
import '../widget/coin_container.dart';
import '../widget/coin_service.dart';
import '../widget/get_level.dart';
import '../widget/level_button.dart';
import '../widget/sound.dart';
import '../widget/voyage_container.dart';
import 'ad_show.dart';
import 'setting_screen.dart';
import 'word_search.dart';
import '../db/prefs.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ConfettiController _confettiController =
      ConfettiController(duration: const Duration(seconds: 2));
  bool _isPlayButtonTapped = false;
  int? _apiGameLevel;
  int? _apiGridSize;

  @override
  void initState() {
    super.initState();
    _getGameLevel();
    _checkAndGiveDailyReward();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _checkAndGiveDailyReward() async {
    final prefs = await SharedPreferences.getInstance();
    final lastClaimDate = prefs.getString('last_claim_date');
    final today = DateTime.now();
    final todayString = "${today.year}-${today.month}-${today.day}";

    if (lastClaimDate != todayString) {
      await _addCoins(20, "Daily Reward");
      await prefs.setString('last_claim_date', todayString);
    }
  }

  Future<void> _getGameLevel() async {
    String apiUrl = '$LURL/api/gameLevel/data?gameName=Wordix';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': '$token',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        setState(() {
          _apiGameLevel = data['gameLevel'];
          _apiGridSize = int.tryParse(data['gridSize'] ?? '');
        });

        if (_apiGameLevel != null) {
          await prefs.setInt('maxLevel_${_apiGridSize ?? 6}', _apiGameLevel!);
        }
      }
    } catch (e) {
      print('Error getting game level: $e');
    }
  }

  Future<void> _addCoins(int coins, String source) async {
    try {
      final coinProvider = Provider.of<CoinProvider>(context, listen: false);
      await coinProvider.addCoins(coins);
      _confettiController.play();
      _showCoinReceivedDialog(coins, source);
      AudioHelper().playMoneySound();
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
      });
    } catch (e) {
      print("Error adding coins: $e");
    }
  }

  void _handlePlayButton() async {
    if (_isPlayButtonTapped) return;

    setState(() => _isPlayButtonTapped = true);

    try {
      AudioHelper().playButtonSound();
      final coinProvider = Provider.of<CoinProvider>(context, listen: false);
      if (coinProvider.coins < 4) {
        _showInsufficientCoinsDialog();
        return;
      }

      await coinProvider.undoCoins(4);
      AudioHelper().playMoneySound();
      Fluttertoast.showToast(msg: "4 coins deducted to start the game");

      final gridSize = _apiGridSize ?? 6;
      final maxLevel = await Prefs.getMaxLevel(gridSize);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                WordSearchPage(gridSize: gridSize, initialLevel: maxLevel),
          ),
        );
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => AdPlaybackPage(
        //       onAdComplete: () {
        //         Navigator.pushReplacement(
        //           context,
        //             MaterialPageRoute(
        //                   builder: (context) =>
        //                       WordSearchPage(gridSize: gridSize, initialLevel: maxLevel),
        //                 ),
        //         );
        //       },
        //     ),
        //   ),
        // );
      }
    } catch (e) {
      print('Error starting game: $e');
    } finally {
      if (mounted) setState(() => _isPlayButtonTapped = false);
    }
  }

  void _showCoinReceivedDialog(int coins, String title) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Stack(
          children: [
            Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: 300,
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.2), width: 1.5),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                  color: Colors.black45,
                                  offset: Offset(0, 2),
                                  blurRadius: 4),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/coin.png',
                                width: 40, height: 40),
                            const SizedBox(width: 15),
                            Text(
                              '+$coins',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFFFD700),
                                shadows: [
                                  Shadow(
                                      color: Colors.black45,
                                      offset: Offset(0, 2),
                                      blurRadius: 4),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        AppButton(
                          label: 'OKAY',
                          onTap: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  colors: const [
                    Colors.blue,
                    Colors.red,
                    Colors.yellow,
                    Colors.green,
                    Colors.purple
                  ],
                  numberOfParticles: 30,
                  gravity: 0.3,
                ),
              ),
            ),
          ],
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
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                    color: Colors.white.withOpacity(0.2), width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Not Enough Coins!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                            color: Colors.black45,
                            offset: Offset(0, 2),
                            blurRadius: 4),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'You need 2 coins to start a game.\nWatch an ad to earn coins or return to the home screen.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'RETURN',
                          onTap: () {
                            AudioHelper().playButtonSound();
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppButton(
                          label: 'WATCH AD',
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

  void _showExitConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.2), width: 1.5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "EXIT GAME?",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                              color: Colors.black45,
                              offset: Offset(0, 2),
                              blurRadius: 4),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      "Are you sure you want to exit the application?",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'NO',
                            onTap: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppButton(
                            label: 'YES',
                            onTap: () => SystemNavigator.pop(),
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

    return WillPopScope(
      onWillPop: () async {
        _showExitConfirmationDialog();
        return false;
      },
      child: Scaffold(
        body: BackgroundContainer(
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const CoinBalanceWidget(),
                      GestureDetector(
                        onTap: () {
                          AudioHelper().playButtonSound();
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SettingsPage()));
                        },
                        child: const Icon(Icons.settings,
                            color: Colors.white, size: 28),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
                Image.asset('assets/icon/icon3.png', width: 200),
                const SizedBox(height: 20),
                // Premium glass Search container
                // ClipRRect(
                //   borderRadius: BorderRadius.circular(30),
                //   child: BackdropFilter(
                //     filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                //     child: Container(
                //       padding: const EdgeInsets.symmetric(
                //           horizontal: 50, vertical: 15),
                //       decoration: BoxDecoration(
                //         color: Colors.black.withOpacity(0.4),
                //         borderRadius: BorderRadius.circular(30),
                //         border: Border.all(
                //             color: Colors.white.withOpacity(0.3), width: 1.5),
                //         boxShadow: [
                //           BoxShadow(
                //               color: Colors.black.withOpacity(0.1),
                //               blurRadius: 10),
                //         ],
                //       ),
                //       child: const Text(
                //         'SEARCH',
                //         style: TextStyle(
                //           color: Colors.white,
                //           fontSize: 24,
                //           letterSpacing: 8,
                //           fontWeight: FontWeight.w900,
                //           shadows: [
                //             Shadow(
                //                 color: Colors.black38,
                //                 offset: Offset(0, 2),
                //                 blurRadius: 4),
                //           ],
                //         ),
                //       ),
                //     ),
                //   ),
                // ),
                // const SizedBox(height: 30),
                // FutureBuilder<int>(
                //   future: Future.value(_apiGameLevel ?? 1),
                //   builder: (context, snapshot) {
                //     if (snapshot.connectionState == ConnectionState.waiting) {
                //       return const CircularProgressIndicator(
                //           color: Colors.white);
                //     }
                //     return VoyageCounter(count: snapshot.data ?? 1);
                //   },
                // ),
                Consumer<GameLevelProvider>(
                  builder: (context, gameProvider, child) {
                    return VoyageCounter(count: gameProvider.currentLevel);
                  },
                ),
                const SizedBox(height: 60),
                // SizedBox(height: 70,child:  _isPlayButtonTapped
                //     ? SizedBox(width:50,height: 40,child: const CircularProgressIndicator(color: Colors.white))
                //     : LevelButton(
                //   label: 'PLAY',
                //   onPressed: () async {
                //     final connectivity =
                //     await Connectivity().checkConnectivity();
                //     if (connectivity.contains(ConnectivityResult.none)) {
                //       Fluttertoast.showToast(msg: "You're offline");
                //     } else {
                //       _handlePlayButton();
                //     }
                //   },
                // ),),
                SizedBox(
                  height: 70, // Match the button's height
                  child: _isPlayButtonTapped
                      ? const Center(
                    child: SizedBox(
                      width: 40,   // Square size
                      height: 40,  // Same as width
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3, // Adjust thickness
                      ),
                    ),
                  )
                      : LevelButton(
                    label: 'PLAY',
                    onPressed: () async {
                      final connectivity = await Connectivity().checkConnectivity();
                      if (connectivity.contains(ConnectivityResult.none)) {
                        Fluttertoast.showToast(msg: "You're offline");
                      } else {
                        _handlePlayButton();
                      }
                    },
                  ),
                ),

                const SizedBox(height: 25),
                // AppButton(
                //   label: 'Watch ad and earn coins',
                //   prefixIcon: Icons.play_circle_fill,
                //   onTap: () {
                //     checkInternetAndProceed(context, () {
                //       Navigator.push(
                //         context,
                //         MaterialPageRoute(
                //           builder: (context) => AdPlaybackPage(
                //             onAdComplete: () => _addCoins(5, 'Ad Reward'),
                //           ),
                //         ),
                //       );
                //     });
                //   },
                // ),
          GestureDetector(
            onTap: () {
              AudioHelper().playButtonSound();
              checkInternetAndProceed(context, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdPlaybackPage(
                            onAdComplete: () => _addCoins(5, 'Ad Reward'),
                          ),
                        ),
                      );
                    });
              },
            child: Container(
              width: 180, // 80% width
              height: 45,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8BC34A), Color(0xFF388E3C)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(25),
                border: const Border(
                  bottom: BorderSide(color: Color(0xFF1B5E20), width: 3),
                  right: BorderSide(color: Color(0xFF1B5E20), width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    offset: const Offset(0, 4),
                    blurRadius: 4,
                  ),
                ],
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                    Icon(Icons.play_circle_fill, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                  Text(
                     'Watch and earn'.toUpperCase(),
                    style:
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          // letterSpacing: 1.2,
                        ),
                  ),
                ],
              ),
            ),
          ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
