import 'dart:ui';
import 'package:flutter/material.dart';
import 'crossword_background.dart';
import 'crossword_home.dart';
import 'crossword_logo.dart';
import 'crossword_level_service.dart';

class CrosswordSplashScreen extends StatefulWidget {
  const CrosswordSplashScreen({super.key});

  @override
  State<CrosswordSplashScreen> createState() => _CrosswordSplashScreenState();
}

class _CrosswordSplashScreenState extends State<CrosswordSplashScreen> {
  double _progress = 0.0;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    // Prefetch level immediately while showing splash animation
    CrosswordLevelService.fetchLevel();
    _startLoading();
  }

  void _startLoading() {
    Future.delayed(const Duration(milliseconds: 100), _updateProgress);
  }

  Future<void> _updateProgress() async {
    if (!mounted || _isNavigating) return;
    if (_progress >= 1.0) {
      _isNavigating = true;
      // Ensure backend level sync completes or gracefully falls back within 2s
      await CrosswordLevelService.ensureLatestLevel(
        timeout: const Duration(seconds: 2),
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, __, ___) => const CrosswordHomeScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    } else {
      setState(() {
        _progress = (_progress + 0.06).clamp(0.0, 1.0);
      });
      Future.delayed(const Duration(milliseconds: 90), _updateProgress);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CrosswordNatureBackground(
        child: Positioned.fill(
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(height: 30),

                  // Center Logo + Brand Text + 3D Loading Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 3D Crossword Logo
                      const CrosswordLogo(size: 220),

                      const SizedBox(height: 26),

                      // Brand Titles
                      const Text(
                        'CROSSWORD',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 4.5,
                          shadows: [
                            Shadow(
                              color: Color(0xFF00E676),
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

                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFFFB74D)
                                .withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          'CONNECT & WORDQUEST',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF69F0AE),
                            letterSpacing: 2.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // 3D Neon Forest Loading Bar Card
                      ClipRRect(
                        borderRadius: BorderRadius.circular(26),
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
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.20),
                                width: 1.4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF9100)
                                      .withValues(alpha: 0.2),
                                  blurRadius: 18,
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
                                      'GATHERING WORDS...',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    Text(
                                      '${(_progress * 100).toInt()}%',
                                      style: const TextStyle(
                                        color: Color(0xFFFFD54F),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
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
                                              Color(0xFF00E676),
                                              Color(0xFF00A859),
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF00E676)
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

                  // Bottom Company Pill
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
      ),
    );
  }
}
