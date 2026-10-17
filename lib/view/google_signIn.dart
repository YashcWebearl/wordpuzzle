import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:word_puzzle/registration_page.dart';
import 'package:word_puzzle/view/game_selection_screen.dart';
import 'package:word_puzzle/widget/app_3d_button.dart';
import 'package:word_puzzle/widget/floating_words_background.dart';

import '../Widget/base_url.dart';
import '../Widget/bg_container.dart';
import '../widget/coin_service.dart';
import '../widget/get_level.dart';
import '../crossword/crossword_level_service.dart';

final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: [
    'email',
    'https://www.googleapis.com/auth/userinfo.profile',
  ],
);

class LoginScreen extends StatefulWidget {
  final bool isRegistration;

  const LoginScreen({
    super.key,
    this.isRegistration = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool googleLoading = false;

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _googleSignIn.onCurrentUserChanged.listen((account) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _handleEmailSignIn() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      Fluttertoast.showToast(msg: "Please enter email and password");
      return;
    }

    // Specific email/password combination rule preserved exactly
    if (email != 'yashchauhan864@gmail.com' || password != '123123') {
      Fluttertoast.showToast(msg: "please use google sign in for login");
      return;
    }

    setState(() => isLoading = true);

    try {
      final uri = Uri.parse('$LURL/api/user/login');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
            {'email': email, 'password': password, "gameName": "Wordix"}),
      );

      print(
          'Email Login Status: ${response.statusCode} | Body: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final token = json['token'];
        String? userId;
        if (json['user'] != null) {
          userId = json['user']['_id']?.toString() ??
              json['user']['registeredID']?.toString();
        } else if (json['userId'] != null) {
          userId = json['userId'].toString();
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('email', email.trim().toLowerCase());
        if (userId != null && userId.isNotEmpty) {
          await prefs.setString('user_id', userId);
        }

        if (mounted) {
          final coinProvider =
              Provider.of<CoinProvider>(context, listen: false);
          final gameLevelProvider =
              Provider.of<GameLevelProvider>(context, listen: false);

          await coinProvider.initialize();

          await Future.wait([
            coinProvider.getCoin(),
            gameLevelProvider.refresh(),
            CrosswordLevelService.fetchLevel(),
          ]);
        }
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) => const GameSelectionScreen()),
            (route) => false,
          );
        }
      } else {
        final msg = jsonDecode(response.body)['message'] ??
            "Login failed. Please check credentials.";
        Fluttertoast.showToast(msg: msg);
      }
    } catch (e) {
      print("Email Login Error: $e");
      Fluttertoast.showToast(msg: "Network error. Please try again.");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => googleLoading = true);

    try {
      await _googleSignIn.signOut();
      final account = await _googleSignIn.signIn();

      if (account == null) {
        Fluttertoast.showToast(msg: "Google Sign-In cancelled");
        return;
      }

      final email = account.email;
      final name = account.displayName ?? 'User';
      final photo = account.photoUrl ?? '';
      final googleId = account.id;

      http.Response response;

      if (widget.isRegistration) {
        final uri = Uri.parse('$LURL/api/user/google');
        response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'registeredID': googleId,
            'email': email,
            'gameName': "Wordix",
            'userName': name,
            'photo': photo,
          }),
        );
      } else {
        final uri = Uri.parse('$LURL/api/user/login');
        response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email,
            'gameName': "Wordix",
          }),
        );
      }

      print('Status: ${response.statusCode} | Body: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final token = json['token'];
        String? userId;
        if (json['user'] != null) {
          userId = json['user']['_id']?.toString() ??
              json['user']['registeredID']?.toString();
        } else if (json['userId'] != null) {
          userId = json['userId'].toString();
        }
        userId ??= googleId;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('email', email.trim().toLowerCase());
        if (userId.isNotEmpty) {
          await prefs.setString('user_id', userId);
        }

        if (mounted) {
          final coinProvider =
              Provider.of<CoinProvider>(context, listen: false);
          final gameLevelProvider =
              Provider.of<GameLevelProvider>(context, listen: false);

          await coinProvider.initialize();

          await Future.wait([
            coinProvider.getCoin(),
            gameLevelProvider.refresh(),
            CrosswordLevelService.fetchLevel(),
          ]);
        }
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) => const GameSelectionScreen()),
            (route) => false,
          );
        }
      } else if (response.statusCode == 409 && widget.isRegistration) {
        Fluttertoast.showToast(
          msg: jsonDecode(response.body)['message'] ??
              "User already exists. Please login.",
          backgroundColor: Colors.orange,
        );
      } else {
        Fluttertoast.showToast(
            msg: "Authentication failed. Please try again.");
      }
    } on PlatformException catch (e) {
      print("Google error: ${e.code} - ${e.message}");
      Fluttertoast.showToast(msg: "Google Sign-In failed: ${e.message}");
    } catch (e) {
      print("Sign in error: $e");
      Fluttertoast.showToast(msg: "Something went wrong. Try again.");
    } finally {
      if (mounted) setState(() => googleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context);
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isNarrow = screenWidth < 360;

    final double horizontalPadding = isNarrow ? 14.0 : 22.0;
    final double cardPadding = isNarrow ? 18.0 : 28.0;

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
                      const Color(0xFF001428).withValues(alpha: 0.88),
                      const Color(0xFF030D1B).withValues(alpha: 0.92),
                      const Color(0xFF000814).withValues(alpha: 0.96),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // 2. Ambient Floating Words Overlay
            const FloatingWordsBackground(isWordix: true),

            // 3. Main Foreground Content
            SafeArea(
              child: Column(
                children: [
                  // Back Navigation Button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16, top: 8),
                      child: App3DButton(
                        width: 42,
                        height: 42,
                        borderRadius: 21.0,
                        depth: 3.5,
                        gradientColors: const [
                          Color(0xFF0F3057),
                          Color(0xFF00587A)
                        ],
                        shadowColor: const Color(0xFF002238),
                        glowColor: const Color(0xFF00E5FF),
                        child: const Center(
                          child: Icon(Icons.arrow_back_rounded,
                              color: Colors.white, size: 20),
                        ),
                        onPressed: () => Navigator.maybePop(context),
                      ),
                    ),
                  ),

                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding, vertical: 12),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(32),
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                                child: Container(
                                  padding: EdgeInsets.all(cardPadding),
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.black.withValues(alpha: 0.58),
                                    borderRadius: BorderRadius.circular(32),
                                    border: Border.all(
                                      color: Colors.white
                                          .withValues(alpha: 0.20),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF00E5FF)
                                            .withValues(alpha: 0.16),
                                        blurRadius: 28,
                                        spreadRadius: 2,
                                      ),
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.5),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Header Badge & Title
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00E5FF)
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                            color: const Color(0xFF00E5FF)
                                                .withValues(alpha: 0.35),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          widget.isRegistration
                                              ? "NEW PLAYER"
                                              : "AUTHENTICATION",
                                          style: const TextStyle(
                                            color: Color(0xFF80DEEA),
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 2.0,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 12),

                                      Text(
                                        widget.isRegistration
                                            ? "Create Account"
                                            : "Welcome Back",
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: 1.0,
                                          shadows: [
                                            Shadow(
                                              color: Color(0xFF00E5FF),
                                              blurRadius: 16,
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
                                        widget.isRegistration
                                            ? "Sign up to track levels & earn coins!"
                                            : "Login with your email or Google to continue.",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          color: Colors.white
                                              .withValues(alpha: 0.75),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),

                                      const SizedBox(height: 28),

                                      // Email Input Field
                                      _buildGlassTextField(
                                        controller: emailController,
                                        hintText: 'Email Address',
                                        icon: Icons.email_rounded,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                      ),

                                      const SizedBox(height: 16),

                                      // Password Input Field
                                      _buildGlassTextField(
                                        controller: passwordController,
                                        hintText: 'Password',
                                        icon: Icons.lock_rounded,
                                        obscureText: _obscurePassword,
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off_rounded
                                                : Icons.visibility_rounded,
                                            color: Colors.white70,
                                            size: 20,
                                          ),
                                          onPressed: () => setState(() =>
                                              _obscurePassword =
                                                  !_obscurePassword),
                                        ),
                                      ),

                                      const SizedBox(height: 26),

                                      // 3D Login / Sign Up Button
                                      App3DButton(
                                        text: widget.isRegistration
                                            ? 'SIGN UP'
                                            : 'LOGIN',
                                        icon: widget.isRegistration
                                            ? Icons.person_add_rounded
                                            : Icons.login_rounded,
                                        height: 52,
                                        fontSize: 16,
                                        borderRadius: 26.0,
                                        width: double.infinity,
                                        isLoading: isLoading,
                                        gradientColors: widget.isRegistration
                                            ? const [
                                                Color(0xFF00E676),
                                                Color(0xFF00B0FF)
                                              ]
                                            : const [
                                                Color(0xFF00E5FF),
                                                Color(0xFF0091EA)
                                              ],
                                        shadowColor: widget.isRegistration
                                            ? const Color(0xFF00796B)
                                            : const Color(0xFF01579B),
                                        glowColor: widget.isRegistration
                                            ? const Color(0xFF00E676)
                                            : const Color(0xFF00E5FF),
                                        textColor: const Color(0xFF021B2D),
                                        iconColor: const Color(0xFF021B2D),
                                        onPressed: _handleEmailSignIn,
                                      ),

                                      const SizedBox(height: 22),

                                      // OR Divider
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Divider(
                                              color: Colors.white
                                                  .withValues(alpha: 0.25),
                                              thickness: 1,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 14),
                                            child: Text(
                                              'OR',
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withValues(alpha: 0.6),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 1.5,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Divider(
                                              color: Colors.white
                                                  .withValues(alpha: 0.25),
                                              thickness: 1,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 22),

                                      // 3D Google Sign-In Button
                                      App3DButton(
                                        height: 52,
                                        borderRadius: 26.0,
                                        width: double.infinity,
                                        depth: 4.5,
                                        gradientColors: const [
                                          Color(0xFFFFFFFF),
                                          Color(0xFFECEFF1)
                                        ],
                                        shadowColor: const Color(0xFF90A4AE),
                                        glowColor: Colors.white,
                                        isLoading: googleLoading,
                                        onPressed: _handleGoogleSignIn,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Image.asset(
                                              'assets/google_logo.png',
                                              width: 22,
                                              height: 22,
                                            ),
                                            const SizedBox(width: 12),
                                            const Text(
                                              'Sign In with Google',
                                              style: TextStyle(
                                                color: Color(0xFF263238),
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 28),

                                      // Register / Login Toggle
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            widget.isRegistration
                                                ? "Already have an account? "
                                                : "New player? ",
                                            style: TextStyle(
                                              color: Colors.white
                                                  .withValues(alpha: 0.8),
                                              fontSize: 14.5,
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              if (widget.isRegistration) {
                                                Navigator.pop(context);
                                              } else {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        const RegistrationScreen(),
                                                  ),
                                                );
                                              }
                                            },
                                            child: Text(
                                              widget.isRegistration
                                                  ? 'Login'
                                                  : 'Register now',
                                              style: const TextStyle(
                                                color: Color(0xFF00E5FF),
                                                fontWeight: FontWeight.w900,
                                                fontSize: 15,
                                                letterSpacing: 0.3,
                                                decoration:
                                                    TextDecoration.underline,
                                                decorationColor:
                                                    Color(0xFF00E5FF),
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
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1.2,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        cursorColor: const Color(0xFF00E5FF),
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 14.5,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF80DEEA), size: 22),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
