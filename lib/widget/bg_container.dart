import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'get_level.dart';

class BackgroundContainer extends StatelessWidget {
  final Widget child;

  const BackgroundContainer({super.key, required this.child});

  // Method to get background image path based on level
  // String _getBackgroundImage(int level) {
  //   if (level >= 1 && level <= 10) {
  //     return 'assets/bg.png';
  //   } else if (level >= 11 && level <= 20) {
  //     return 'assets/bg2.png';
  //   } else if (level >= 21 && level <= 30) {
  //     return 'assets/bg3.png';
  //   } else if (level >= 31 && level <= 40) {
  //     return 'assets/bg4.png';
  //   } else if (level >= 41 && level <= 50) {
  //     return 'assets/bg5.png';
  //   } else {
  //     // 51 and above
  //     return 'assets/bg6.png';
  //   }
  // }
  String _getBackgroundImage(int level) {
    // Level as seed use kariye so same level mate same bg ave (consistent)
    final random = Random(level);

    // Random 1 to 9 (bg, bg2, bg3... bg9)
    final bgNumber = random.nextInt(10) + 1;

    // Map to file names
    switch (bgNumber) {
      case 1:
        return 'assets/bg.png';
      case 2:
        return 'assets/bg2.png';
      case 3:
        return 'assets/bg3.png';
      case 4:
        return 'assets/bg4.png';
      case 5:
        return 'assets/bg5.png';
      case 6:
        return 'assets/bg6.png';
      case 7:
        return 'assets/bg7.png';
      case 8:
        return 'assets/bg8.png';
      case 9:
        return 'assets/bg9.png';
      case 10:
        return 'assets/bg10.png';
      default:
        return 'assets/bg.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context);

    // Listen to GameLevelProvider for level changes
    return Consumer<GameLevelProvider>(
      builder: (context, gameLevelProvider, _) {
        final currentLevel = gameLevelProvider.currentLevel;
        final backgroundImage = _getBackgroundImage(currentLevel);

        return Stack(
          fit: StackFit.expand,
          children: [
            // Image.asset(
            //   backgroundImage,
            //   fit: BoxFit.cover,
            // ),
            Image.asset(
              backgroundImage,
              fit: BoxFit.cover,
              key: ValueKey(backgroundImage), // aa add karo
            ),
            child,
          ],
        );
      },
    );
  }
}

















































// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
//
// class BackgroundContainer extends StatelessWidget {
//   final Widget child;
//
//   const BackgroundContainer({super.key, required this.child});
//
//   @override
//   Widget build(BuildContext context) {
//     ScreenUtil.init(context);
//     return Stack(
//       fit: StackFit.expand,
//       children: [
//         Image.asset(
//           'assets/bg.png',
//           fit: BoxFit.cover,
//         ),
//         child,
//       ],
//     );
//   }
// }
