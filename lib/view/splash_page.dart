import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:word_puzzle/view/welcome_screen.dart';
import 'package:word_puzzle/widget/app_3d_button.dart';
import 'package:word_puzzle/widget/bg_container.dart';
import 'package:word_puzzle/widget/floating_words_background.dart';
import 'personal_ad_screen.dart';
import '../crossword/crossword_level_service.dart';
import '../widget/base_url.dart';
import '../widget/get_level.dart';
import 'game_selection_screen.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  double _progress = 0.0;
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startLoading();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _startLoading() {
    Future.delayed(const Duration(milliseconds: 100), _updateProgress);
  }

  void _updateProgress() {
    if (!mounted) return;
    if (_progress >= 1.0) {
      _checkAppVersionAndNavigate();
    } else {
      setState(() {
        _progress = (_progress + 0.05).clamp(0.0, 1.0);
      });
      Future.delayed(const Duration(milliseconds: 100), _updateProgress);
    }
  }

  Future<String> getAppCode() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.buildNumber;
  }

  Future<void> _checkAppVersionAndNavigate() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      _checkAuthAndNavigate();
      return;
    }
    try {
      String currentAppCode = await getAppCode();
      print('Current app code: $currentAppCode');
      final response = await http
          .get(Uri.parse('$LURL/api/user/slash/?gameName=Wordix'));
      print('API called for version check');
      print('status code:- ${response.statusCode}');
      print('body code:- ${response.body}');
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final String serverAppCode = jsonData['data']['app_code'] ?? "0";
        print('Server app code: $serverAppCode');
        if (serverAppCode == currentAppCode) {
          _checkAuthAndNavigate();
        } else {
          _showUpdateDialog();
        }
      } else {
        _checkAuthAndNavigate();
      }
    } catch (e) {
      print('Error during version check: $e');
      _checkAuthAndNavigate();
    }
  }

  Future<void> _checkAuthAndNavigate() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    print('Token is: $token');

    Widget nextScreen;
    if (token != null && token.isNotEmpty) {
      if (mounted) {
        final gameLevelProvider =
            Provider.of<GameLevelProvider>(context, listen: false);
        gameLevelProvider.refresh();
        CrosswordLevelService.fetchLevel();
      }
      nextScreen = const GameSelectionScreen();
    } else {
      nextScreen = const WelcomeScreen();
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PersonalAdScreen(nextScreen: nextScreen),
        ),
      );
    }
  }

  void _showUpdateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: const Color(0xFF041224).withValues(alpha: 0.90),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                      blurRadius: 28,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.18),
                        border: Border.all(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.45),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.system_update_rounded,
                        color: Color(0xFF00E5FF),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'UPDATE REQUIRED',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'A brand new update with exciting levels and improvements is available!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 26),
                    App3DButton.cyan(
                      text: 'UPDATE NOW',
                      icon: Icons.download_rounded,
                      height: 48,
                      fontSize: 15,
                      borderRadius: 24.0,
                      width: double.infinity,
                      onPressed: () async {
                        final Uri url = Uri.parse(
                            'https://play.google.com/store/apps/details?id=com.wordix&hl=en');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        } else {
                          print('Could not launch $url');
                        }
                      },
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
    return Scaffold(
      body: BackgroundContainer(
        child: Stack(
          children: [
            // 1. Cosmic Deep Violet & Midnight Scrim (Distinct from blue for high contrast)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1B0C36).withValues(alpha: 0.94),
                      const Color(0xFF100624).withValues(alpha: 0.96),
                      const Color(0xFF070210).withValues(alpha: 0.98),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // Radial Ambient Spotlight behind the logo
            Positioned(
              top: MediaQuery.of(context).size.height * 0.16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 360,
                  height: 360,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF7C4DFF).withValues(alpha: 0.35),
                        const Color(0xFF00E5FF).withValues(alpha: 0.18),
                        Colors.transparent,
                      ],
                      radius: 0.72,
                    ),
                  ),
                ),
              ),
            ),

            // 2. Ambient Floating Words Overlay
            const FloatingWordsBackground(
              isWordix: true,
              baseColor: Color(0xFFCE93D8),
              accentColor: Color(0xFFFFD54F),
            ),

            // 3. Main Center Content
            Positioned.fill(
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(height: 40),

                      // Center: Animated Logo + 3D Loading Bar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Pulsing 3D App Icon on Pearl White Glossy Badge (100% visible dark navy logo)
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: Container(
                              width: 210,
                              height: 210,
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFFFFF),
                                    Color(0xFFF4F7FB),
                                    Color(0xFFE2E8F0),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00E5FF)
                                        .withValues(alpha: 0.50),
                                    blurRadius: 40,
                                    spreadRadius: 6,
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFF7C4DFF)
                                        .withValues(alpha: 0.35),
                                    blurRadius: 28,
                                    spreadRadius: 2,
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.45),
                                    blurRadius: 22,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/icon/icon.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),

                      const SizedBox(height: 28),

                      // Brand Title
                      const Text(
                        'WORDIX',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 4.0,
                          shadows: [
                            Shadow(
                              color: Color(0xFF00E5FF),
                              blurRadius: 20,
                            ),
                            Shadow(
                              color: Colors.black87,
                              offset: Offset(0, 3),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'WORD SEARCH PUZZLE',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF80DEEA),
                          letterSpacing: 3.5,
                        ),
                      ),

                      const SizedBox(height: 38),

                      // 3D Neon Loading Progress Bar Card
                      ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                          child: Container(
                            width: 280,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 18,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.20),
                                width: 1.4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00E5FF)
                                      .withValues(alpha: 0.15),
                                  blurRadius: 20,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'LOADING...',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 2.0,
                                      ),
                                    ),
                                    Text(
                                      '${(_progress * 100).toInt()}%',
                                      style: const TextStyle(
                                        color: Color(0xFF00E5FF),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Track with Neon Gradient Bar
                                Container(
                                  width: double.infinity,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: FractionallySizedBox(
                                      widthFactor: _progress,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF00E5FF),
                                              Color(0xFF00E676),
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF00E5FF)
                                                  .withValues(alpha: 0.6),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Bottom Company Badge
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Text(
                            "WebEarl Technologies Pvt Ltd",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFFFFD54F),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
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
}
