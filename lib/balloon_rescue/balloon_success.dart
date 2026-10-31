import 'package:flutter/material.dart';
import 'package:word_puzzle/widget/common_game_success_screen.dart';
import 'balloon_background.dart';
import 'balloon_game.dart';
import 'balloon_home.dart';
import 'balloon_level_service.dart';

/// 3D Animated Victory / Defeat Screen for Balloon Rescue powered by CommonGameSuccessScreen
class BalloonSuccessScreen extends StatelessWidget {
  final int level;
  final int coinsEarned;
  final bool isWin;
  final String word;
  final int balloonsLeft;

  const BalloonSuccessScreen({
    super.key,
    required this.level,
    this.coinsEarned = 3,
    this.isWin = true,
    this.word = '',
    this.balloonsLeft = 5,
  });

  @override
  Widget build(BuildContext context) {
    return CommonGameSuccessScreen(
      level: level,
      coinsEarned: isWin ? coinsEarned : 0,
      isWin: isWin,
      background: const BalloonSkyBackground(),
      primaryColor: const Color(0xFFFF9100),
      accentColor: const Color(0xFFFFD54F),
      darkAuraColor: const Color(0xFF3E2723),
      customSubTitle: word.isNotEmpty
          ? null
          : null,
      onCompleteLevel: () async {
        final stars = balloonsLeft >= 4 ? 3 : (balloonsLeft >= 2 ? 2 : 1);
        await BalloonLevelService.completeLevel(level, stars: stars);
      },
      onNextLevel: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BalloonGameScreen(
              level: isWin ? level + 1 : level,
            ),
          ),
        );
      },
      onHome: () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const BalloonHomeScreen(),
          ),
          (route) => route.isFirst,
        );
      },
    );
  }
}
