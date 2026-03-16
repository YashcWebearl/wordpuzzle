import 'dart:async';
import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:word_puzzle/view/splash_page.dart';
import 'package:word_puzzle/widget/coin_service.dart';
import 'package:word_puzzle/widget/get_level.dart';
import 'package:word_puzzle/widget/sound.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  print('sound fetch');
  await AudioHelper().initialize();

  FlutterError.onError = (FlutterErrorDetails details) async {
    FlutterError.presentError(details);
    FlutterError.dumpErrorToConsole(details);
    print(details.exceptionAsString());
  };

  final coinProvider = CoinProvider();
  await coinProvider.initialize();

  MobileAds.instance.initialize();

  PlatformDispatcher.instance.onError = (error, stack) {
    print('Caught Dart Error: $error');
    print('Stack trace: $stack');
    return true;
  };

  // IMPORTANT: Wrap EVERYTHING in MultiProvider at the ROOT level
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: coinProvider),
        ChangeNotifierProvider(create: (_) => GameLevelProvider()),
      ],
      child: const WordSearchApp(),
    ),
  );
}

class WordSearchApp extends StatefulWidget {
  const WordSearchApp({super.key});

  @override
  State<WordSearchApp> createState() => _WordSearchAppState();
}

class _WordSearchAppState extends State<WordSearchApp> {
  late final StreamSubscription<List<ConnectivityResult>> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      final isOffline = results.contains(ConnectivityResult.none);
      if (isOffline) {
        Fluttertoast.showToast(msg: "You're offline");
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ScreenUtilInit is INSIDE the provider scope now
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Word Search Puzzle',
          debugShowCheckedModeBanner: false,
          home: const SplashPage(),
        );
      },
    );
  }
}

































// import 'dart:async';
// import 'dart:ui';
//
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:word_puzzle/view/splash_page.dart';
// import 'package:word_puzzle/view/welcome_screen.dart';
// import 'package:word_puzzle/widget/coin_service.dart';
// import 'package:word_puzzle/widget/get_level.dart';
// import 'package:word_puzzle/widget/sound.dart';
//
// // Future<void> main() async {
// //   WidgetsFlutterBinding.ensureInitialized();
// //   await SystemChrome.setPreferredOrientations([
// //     DeviceOrientation.portraitUp,
// //     DeviceOrientation.portraitDown,
// //   ]);
// //   print('sound fetch');
// //
// //   await AudioHelper().initialize();
// //   FlutterError.onError = (FlutterErrorDetails details) async {
// //     FlutterError.presentError(details);
// //     FlutterError.dumpErrorToConsole(details);
// //     print(details.exceptionAsString());
// //     // await SystemChrome.setPreferredOrientations([
// //     //   DeviceOrientation.portraitUp,
// //     //   DeviceOrientation.portraitDown,
// //     // ]);
// //   };
// //   final coinProvider = CoinProvider();
// //   await coinProvider.initialize(); //
// //   MobileAds.instance.initialize();
// //   PlatformDispatcher.instance.onError = (error, stack) {
// //     print('Caught Dart Error: $error');
// //     print('Stack trace: $stack');
// //     return true;
// //   };
// //   // runApp(const WordSearchApp());
// //   // runApp(
// //   //   // ChangeNotifierProvider(
// //   //   //   create: (_) => coinProvider,
// //   //   //   child: WordSearchApp(),
// //   //   // ),
// //   //   MultiProvider(
// //   //     providers: [
// //   //       // ChangeNotifierProvider(create: (_) => CoinProvider()),
// //   //       ChangeNotifierProvider.value(value: coinProvider),
// //   //       ChangeNotifierProvider(create: (_) => GameLevelProvider()),
// //   //     ],
// //   //     child: const WordSearchApp(),
// //   //   ),
// //   // );
// //   runApp(
// //     MultiProvider(
// //       providers: [
// //         ChangeNotifierProvider.value(value: coinProvider),
// //         ChangeNotifierProvider(create: (_) => GameLevelProvider()),
// //       ],
// //       child: const WordSearchApp(),
// //     ),
// //   );
// // }
// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await SystemChrome.setPreferredOrientations([
//     DeviceOrientation.portraitUp,
//     DeviceOrientation.portraitDown,
//   ]);
//
//   await AudioHelper().initialize();
//   FlutterError.onError = (FlutterErrorDetails details) async {
//     FlutterError.presentError(details);
//     FlutterError.dumpErrorToConsole(details);
//     print(details.exceptionAsString());
//     // await SystemChrome.setPreferredOrientations([
//     //   DeviceOrientation.portraitUp,
//     //   DeviceOrientation.portraitDown,
//     // ]);
//   };
//   final coinProvider = CoinProvider();
//   await coinProvider.initialize();
//   MobileAds.instance.initialize();
//
//   // Initialize GameLevelProvider here
//   final gameLevelProvider = GameLevelProvider();
//
//   runApp(
//     MultiProvider(
//       providers: [
//         ChangeNotifierProvider.value(value: coinProvider),
//         ChangeNotifierProvider.value(value: gameLevelProvider), // Use .value since already initialized
//       ],
//       child: const WordSearchApp(),
//     ),
//   );
// }
// class WordSearchApp extends StatefulWidget {
//   const WordSearchApp({super.key});
//
//   @override
//   State<WordSearchApp> createState() => _WordSearchAppState();
// }
//
// class _WordSearchAppState extends State<WordSearchApp> {
//   late final StreamSubscription<List<ConnectivityResult>> _subscription;
//
//   @override
//   void initState() {
//     // TODO: implement initState
//     super.initState();
//     _subscription = Connectivity().onConnectivityChanged.listen((results) {
//       final isOffline = results.contains(ConnectivityResult.none);
//       if (isOffline) {
//         Fluttertoast.showToast(msg: "You're offline");
//       }
//     });
//   }
//   @override
//   void dispose() {
//     _subscription.cancel();
//     super.dispose();
//   }
//
//   // @override
//   Widget build(BuildContext context) {
//     return ScreenUtilInit(
//       designSize: const Size(375, 812),
//       minTextAdapt: true,
//       splitScreenMode: true,
//       builder: (context, child) {
//         return SafeArea(
//           bottom: true,
//           top: false,
//           child:
//           MaterialApp(
//             title: 'Word Search Puzzle',
//             debugShowCheckedModeBanner: false,
//             // home: isLoggedIn == null
//             //     ? const Scaffold(
//             //   body: Center(child: CircularProgressIndicator()),
//             // )
//             //     : isLoggedIn!
//             //     ?  StartScreen()
//             //     :  WelcomeScreen()
//
//             home: const SplashPage(),
//
//           ),
//         );
//       },
//     );
//   }
// }
//
