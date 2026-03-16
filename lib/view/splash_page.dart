// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:http/http.dart' as http;
// import 'package:package_info_plus/package_info_plus.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:word_puzzle/view/welcome_screen.dart';
// import '../widget/base_url.dart';
// import '../widget/bg_container.dart';
// import 'difficultyselect.dart';
// import 'home_screen.dart';
//
// class SplashPage extends StatefulWidget {
//   const SplashPage({super.key});
//
//   @override
//   State<SplashPage> createState() => _SplashPageState();
// }
//
// class _SplashPageState extends State<SplashPage> {
//   double _progress = 0.0;
//   // static const String LURL = 'YOUR_API_BASE_URL'; // Replace with your API base URL
//
//   @override
//   void initState() {
//     super.initState();
//     _startLoading();
//   }
//
//   void _startLoading() {
//     Future.delayed(const Duration(milliseconds: 100), _updateProgress);
//   }
//
//   void _updateProgress() {
//     if (_progress >= 1.0) {
//       _checkAppVersionAndNavigate();
//     } else {
//       setState(() {
//         _progress += 0.05;
//       });
//       Future.delayed(const Duration(milliseconds: 100), _updateProgress);
//     }
//   }
//
//   Future<String> getAppCode() async {
//     PackageInfo packageInfo = await PackageInfo.fromPlatform();
//     return packageInfo.buildNumber; // Fetches versionCode from build.gradle
//   }
//
//   Future<void> _checkAppVersionAndNavigate() async {
//     try {
//       String currentAppCode = await getAppCode();
//       print('Current app code: $currentAppCode');
//       final response = await http.get(Uri.parse('$LURL/api/user/slash'));
//       print('API called for version check');
//
//       if (response.statusCode == 200) {
//         final jsonData = json.decode(response.body);
//         final String serverAppCode = jsonData['data']['app_code'] ?? "0";
//         print('Server app code: $serverAppCode');
//
//         if (serverAppCode == currentAppCode) {
//           _checkAuthAndNavigate();
//         } else {
//           _showUpdateDialog();
//         }
//       } else {
//         // Fallback in case of API failure
//         _checkAuthAndNavigate();
//       }
//     } catch (e) {
//       print('Error during version check: $e');
//       // Fallback on exception
//       _checkAuthAndNavigate();
//     }
//   }
//
//   Future<void> _checkAuthAndNavigate() async {
//     if (!mounted) return; // Prevent navigation if widget is disposed
//
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('auth_token');
//     print('Token is: $token');
//
//     if (token != null && token.isNotEmpty) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (context) => const HomePage()),
//       );
//     } else {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (context) => const WelcomeScreen()),
//       );
//     }
//   }
//
//   void _showUpdateDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         contentPadding: EdgeInsets.zero,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         content: Container(
//           decoration: BoxDecoration(
//             gradient: const LinearGradient(
//               colors: [Color(0xFF6B5BFF), Color(0xFF2E1A8E)],
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//             ),
//             borderRadius: BorderRadius.circular(20),
//           ),
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Text(
//                 'UPDATE REQUIRED',
//                 style: TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                   fontFamily: 'Georgia',
//                 ),
//               ),
//               const SizedBox(height: 10),
//               const Text(
//                 'Please update the app to continue.',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 16,
//                   color: Colors.white,
//                   fontFamily: 'Georgia',
//                 ),
//               ),
//               const SizedBox(height: 20),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF2E1A8E),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     onPressed: () async {
//                       final Uri url = Uri.parse('');
//                       if (await canLaunchUrl(url)) {
//                         await launchUrl(url);
//                       } else {
//                         print('Could not launch $url');
//                       }
//                     },
//                     child: const Text('Update', style: TextStyle(color: Colors.white)),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: BackgroundContainer(
//         child: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const SizedBox(),
//               Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   // Image.asset(
//                   //   'assets/icon/icon.png',
//                   //   width: 250,
//                   // ),
//                   Image.asset(
//                     'assets/icon/icon.png',
//                     width: 300.w,
//                     height: 300.h,
//                   ),
//                   const SizedBox(height: 40),
//                   ClipRRect(
//                     borderRadius: BorderRadius.circular(20),
//                     child: Container(
//                       width: 250,
//                       height: 20,
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       child: Stack(
//                         children: [
//                           FractionallySizedBox(
//                             widthFactor: _progress,
//                             child: Container(
//                               decoration: BoxDecoration(
//                                 color: Colors.green,
//                                 borderRadius: BorderRadius.circular(20),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//
//
//               Padding(
//                 padding: EdgeInsets.only(bottom: 20.h),
//                 child: const Text(
//                   "WebEarl Technologies Pvt Ltd",
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontSize: 20,
//                     color: Colors.white,
//                     // color: Color(0xFF2E1A8E),
//                     fontWeight: FontWeight.w500,
//                     shadows: [
//                       Shadow(
//                         offset: Offset(1, 1),
//                         blurRadius: 3.0,
//                         color: Colors.white, // White shadow
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//












import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:word_puzzle/view/welcome_screen.dart';
import '../widget/base_url.dart';
import '../widget/bg_container.dart';
import 'home_screen.dart';
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}
class _SplashPageState extends State<SplashPage> {
  double _progress = 0.0;
  @override
  void initState() {
    super.initState();
    _startLoading();
  }
  void _startLoading() {
    Future.delayed(const Duration(milliseconds: 100), _updateProgress);
  }
  void _updateProgress() {
    if (_progress >= 1.0) {
      _checkAppVersionAndNavigate();
    } else {
      setState(() {
        _progress += 0.05;
      });
      Future.delayed(const Duration(milliseconds: 100), _updateProgress);
    }
  }
  Future<String> getAppCode() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.buildNumber;
  }
  Future<void> _checkAppVersionAndNavigate() async {
    try {
      String currentAppCode = await getAppCode();
      print('Current app code: $currentAppCode');
      final response = await http.get(Uri.parse('$LURL/api/user/slash'));
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
    if (token != null && token.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
    }
  }
  void _showUpdateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6B5BFF), Color(0xFF2E1A8E)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'UPDATE REQUIRED',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Please update the app to continue.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E1A8E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      final Uri url = Uri.parse('');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      } else {
                        print('Could not launch $url');
                      }
                    },
                    child: const Text('Update', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundContainer(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/icon/icon.png',
                    width: 300,
                    height: 300,
                  ),
                  const SizedBox(height: 40),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                      child: Container(
                        width: 280,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'LOADING...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: 200,
                                height: 10,
                                color: Colors.white.withOpacity(0.3),
                                child: FractionallySizedBox(
                                  widthFactor: _progress,
                                  child: Container(
                                    color: const Color(0xFFFFD700),
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
              // Padding(
              //   padding: EdgeInsets.only(bottom: 20),
              //   child: ClipRRect(
              //     borderRadius: BorderRadius.circular(20),
              //     child: BackdropFilter(
              //       filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
              //       child: Container(
              //         padding: const EdgeInsets.symmetric(
              //           horizontal: 16,
              //           vertical: 8,
              //         ),
              //         decoration: BoxDecoration(
              //           color: Colors.black.withOpacity(0.2),
              //           borderRadius: BorderRadius.circular(20),
              //           border: Border.all(
              //             color: Colors.black.withOpacity(0.2),
              //             width: 1,
              //           ),
              //           boxShadow: [
              //             BoxShadow(
              //                 color: Colors.black.withOpacity(0.1),
              //                 blurRadius: 10),
              //           ],
              //         ),
              //         child: const Text(
              //           "WebEarl Technologies Pvt Ltd",
              //           textAlign: TextAlign.center,
              //           style: TextStyle(
              //             fontSize: 18,
              //             color: Colors.black,
              //             fontWeight: FontWeight.w800,
              //             shadows: [
              //               Shadow(
              //                 offset: Offset(1, 1),
              //                 blurRadius: 3.0,
              //                 color: Colors.black45,
              //               ),
              //             ],
              //           ),
              //         ),
              //       ),
              //     ),
              //   ),
              // ),
              Padding(
                padding: const EdgeInsets.only(bottom: 20), // ਥੋੜ੍ਹੀ ਸਪੇਸ ਵਧਾਈ ਹੈ
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0), // Blur ਇਫੈਕਟ ਵਧਾਇਆ
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        // ਡਾਰਕ ਬੈਕਗ੍ਰਾਊਂਡ ਜੋ ਥੋੜ੍ਹਾ ਪਾਰਦਰਸ਼ੀ ਹੈ
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1), // ਬਾਰਡਰ ਨੂੰ ਹਲਕਾ ਰੱਖਿਆ
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Text(
                        "WebEarl Technologies Pvt Ltd",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          // ਟੈਕਸਟ ਦਾ ਰੰਗ ਚਿੱਟਾ ਜਾਂ ਗੋਲਡਨ ਰੱਖੋ ਤਾਂ ਜੋ ਡਾਰਕ ਤੇ ਉੱਭਰ ਕੇ ਆਵੇ
                          color: Color(0xFFFFD700), // Golden color for highlighting
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
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
    );
  }
}
