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
import 'package:word_puzzle/view/home_screen.dart';
import 'package:word_puzzle/widget/button.dart';

import '../Widget/base_url.dart';
import '../Widget/bg_container.dart';
import '../widget/coin_service.dart';

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
  GoogleSignInAccount? _currentUser;

  @override
  void initState() {
    super.initState();
    _googleSignIn.onCurrentUserChanged.listen((account) {
      if (mounted) {
        setState(() => _currentUser = account);
      }
    });
  }

  // Future<void> _handleEmailSignIn() async {
  //   final email = emailController.text.trim();
  //   final password = passwordController.text.trim();
  //
  //   if (email.isEmpty || password.isEmpty) {
  //     Fluttertoast.showToast(msg: "Please enter email and password");
  //     return;
  //   }
  //
  //   setState(() => isLoading = true);
  //
  //   try {
  //     final uri = Uri.parse('$LURL/api/user/login');
  //     final response = await http.post(
  //       uri,
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode({
  //         'email': email,
  //         'password': password,
  //       }),
  //     );
  //
  //     print(
  //         'Email Login Status: ${response.statusCode} | Body: ${response.body}');
  //
  //     if (response.statusCode == 200) {
  //       final json = jsonDecode(response.body);
  //       final token = json['token'];
  //
  //       final prefs = await SharedPreferences.getInstance();
  //       await prefs.setString('auth_token', token);
  //       await prefs.setString('email', email);
  //
  //       final coinProvider = CoinProvider();
  //       await coinProvider.initialize();
  //
  //       if (mounted) {
  //         Navigator.pushAndRemoveUntil(
  //           context,
  //           MaterialPageRoute(builder: (context) => const HomePage()),
  //           (route) => false,
  //         );
  //       }
  //     } else {
  //       final msg = jsonDecode(response.body)['message'] ??
  //           "Login failed. Please check credentials.";
  //       Fluttertoast.showToast(msg: msg);
  //     }
  //   } catch (e) {
  //     print("Email Login Error: $e");
  //     Fluttertoast.showToast(msg: "Network error. Please try again.");
  //   } finally {
  //     if (mounted) setState(() => isLoading = false);
  //   }
  // }
  Future<void> _handleEmailSignIn() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      Fluttertoast.showToast(msg: "Please enter email and password");
      return;
    }

    // ---- NEW VALIDATION ----
    // Allow only this specific email/password combination
    if (email != 'yashchauhan864@gmail.com' || password != '123123') {
      // Fluttertoast.showToast(
      //   msg: "please use google sign in for login",
      //   backgroundColor: Colors.orange,
      // );
      Fluttertoast.showToast(msg: "please use google sign in for login");
      return;
    }
    // ------------------------

    setState(() => isLoading = true);

    try {
      final uri = Uri.parse('$LURL/api/user/login');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          "gameName": "Word Puzzle"
        }),
      );

      print('Email Login Status: ${response.statusCode} | Body: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final token = json['token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('email', email);

        // final coinProvider = CoinProvider();
        // await coinProvider.initialize();
        if (mounted) {
          final coinProvider = Provider.of<CoinProvider>(context, listen: false);
          await coinProvider.initialize();
          await coinProvider.getCoin();   // Fetches updated coins from server
        }
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
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
            'gameName': "Word Puzzle",
            'userName': name,
            'photo': photo,
          }),
        );
      } else {
        final uri = Uri.parse('$LURL/api/user/login');
        response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email}),
        );
      }

      print('Status: ${response.statusCode} | Body: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final token = json['token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('email', email);

        // final coinProvider = CoinProvider();
        // await coinProvider.initialize();
        if (mounted) {
          final coinProvider = Provider.of<CoinProvider>(context, listen: false);
          await coinProvider.initialize();
          await coinProvider.getCoin();   // Fetches updated coins from server
        }
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
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
        Fluttertoast.showToast(msg: "Authentication failed. Please try again.");
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

    return Scaffold(
      body: BackgroundContainer(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                  child: Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.isRegistration
                                  ? "Create Account"
                                  : "Welcome Back",
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black45,
                                    offset: Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              widget.isRegistration
                                  ? "Sign up to start playing!"
                                  : "Login with your email or Google to continue.",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        TextField(
                          controller: emailController,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.black.withValues(alpha: 0.2),
                            hintText: 'Email Address',
                            hintStyle:
                                TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                            prefixIcon:
                                const Icon(Icons.email, color: Colors.white),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.5)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(
                                  color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.black.withValues(alpha: 0.2),
                            hintText: 'Password',
                            hintStyle:
                                TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                            prefixIcon:
                                const Icon(Icons.lock, color: Colors.white),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.white,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.5)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(
                                  color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : AppButton(
                                label:
                                    widget.isRegistration ? 'Sign Up' : 'Login',
                                prefixIcon: Icons.login,
                                onTap: _handleEmailSignIn,
                              ),
                        const SizedBox(height: 25),
                        Row(
                          children: [
                            Expanded(
                                child: Divider(
                                    color: Colors.white.withValues(alpha: 0.5))),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('OR',
                                  style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 16)),
                            ),
                            Expanded(
                                child: Divider(
                                    color: Colors.white.withValues(alpha: 0.5))),
                          ],
                        ),
                        const SizedBox(height: 25),
                        googleLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : AppButton(
                                label: 'Login with Google',
                                prefixImage: Image.asset(
                                    'assets/google_logo.png',
                                    width: 24,
                                    height: 24),
                                onTap: _handleGoogleSignIn,
                              ),
                        const SizedBox(height: 35),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.isRegistration
                                  ? "Already have account? "
                                  : "New player? ",
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 16),
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
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 17,
                                  decoration: TextDecoration.underline,
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
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
