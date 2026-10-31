import 'package:flutter/material.dart';
import 'package:word_puzzle/widget/common_game_success_screen.dart';
import 'scramble_background.dart';
import 'scramble_game.dart';
import 'scramble_home.dart';
import 'scramble_level_service.dart';

/// 3D Animated Victory / Defeat Screen for Scramble powered by CommonGameSuccessScreen
class ScrambleSuccessScreen extends StatelessWidget {
  final int level;
  final int coinsEarned;
  final bool isWin;
  final int movesUsed;

  const ScrambleSuccessScreen({
    super.key,
    required this.level,
    this.coinsEarned = 3,
    this.isWin = true,
    this.movesUsed = 0,
  });

  @override
  Widget build(BuildContext context) {
    return CommonGameSuccessScreen(
      level: level,
      coinsEarned: isWin ? coinsEarned : 0,
      isWin: isWin,
      background: const ScrambleCosmicBackground(),
      primaryColor: const Color(0xFFAB47BC),
      accentColor: const Color(0xFFE040FB),
      darkAuraColor: const Color(0xFF38125E),
      onCompleteLevel: () async {
        await ScrambleLevelService.completeLevel(level, stars: 3);
      },
      onNextLevel: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ScrambleGameScreen(
              level: isWin ? level + 1 : level,
            ),
          ),
        );
      },
      onHome: () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const ScrambleHomeScreen(),
          ),
          (route) => route.isFirst,
        );
      },
    );
  }
}
