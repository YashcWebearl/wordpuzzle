import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:word_puzzle/registration_page.dart';
import 'package:word_puzzle/view/google_signIn.dart';
import 'package:word_puzzle/widget/app_3d_button.dart';
import 'package:word_puzzle/widget/bg_container.dart';
import 'package:word_puzzle/widget/floating_words_background.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context);
    final size = MediaQuery.of(context).size;
    final isNarrow = size.width < 360;

    return Scaffold(
      body: BackgroundContainer(
        child: Stack(
          children: [
            // 1. Cyber-Oceanic Dark Scrim
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF001428).withValues(alpha: 0.85),
                      const Color(0xFF030D1B).withValues(alpha: 0.90),
                      const Color(0xFF000814).withValues(alpha: 0.95),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // 2. Animated Ambient Floating Words Background
            const FloatingWordsBackground(isWordix: true),

            // 3. Main Content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: isNarrow ? 20.0 : 28.0,
                    vertical: 24.0,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated 3D Glowing App Icon on Pearl White Glossy Badge
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            width: isNarrow ? 180.w : 210.w,
                            height: isNarrow ? 180.h : 210.h,
                            padding: const EdgeInsets.all(20),
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
                                      .withValues(alpha: 0.45),
                                  blurRadius: 36,
                                  spreadRadius: 6,
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.40),
                                  blurRadius: 20,
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

                        SizedBox(height: isNarrow ? 20 : 28),

                        // Title & Subtitle Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF00E5FF)
                                  .withValues(alpha: 0.3),
                              width: 1.2,
                            ),
                          ),
                          child: const Text(
                            'WORDIX PUZZLE',
                            style: TextStyle(
                              color: Color(0xFF80DEEA),
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3.0,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        const Text(
                          'Welcome!',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.2,
                            shadows: [
                              Shadow(
                                color: Color(0xFF00E5FF),
                                blurRadius: 18,
                              ),
                              Shadow(
                                color: Colors.black54,
                                offset: Offset(0, 3),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          'Train your brain with word adventures',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withValues(alpha: 0.75),
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        SizedBox(height: isNarrow ? 32 : 44),

                        // 3D Glassmorphic Action Buttons Card
                        ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 22, vertical: 26),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 3D Login Button (Cyan / Ocean)
                                  App3DButton.cyan(
                                    text: 'LOGIN',
                                    icon: Icons.login_rounded,
                                    height: 52,
                                    fontSize: 16,
                                    borderRadius: 26.0,
                                    width: double.infinity,
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const LoginScreen(
                                                  isRegistration: false),
                                        ),
                                      );
                                    },
                                  ),

                                  const SizedBox(height: 16),

                                  // 3D Registration Button (Emerald Green)
                                  App3DButton.green(
                                    text: 'CREATE ACCOUNT',
                                    icon: Icons.person_add_rounded,
                                    height: 52,
                                    fontSize: 16,
                                    borderRadius: 26.0,
                                    width: double.infinity,
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const RegistrationScreen(),
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
            ),
          ],
        ),
      ),
    );
  }
}
