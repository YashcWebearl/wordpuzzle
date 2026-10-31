import 'package:flutter/material.dart';
import 'package:word_puzzle/widget/common_game_success_screen.dart';
import 'crossword_background.dart';
import 'crossword_game.dart';
import 'crossword_home.dart';
import 'crossword_level_service.dart';

/// 3D Animated Victory / Defeat Screen for Crossword powered by CommonGameSuccessScreen
class CrosswordSuccessScreen extends StatelessWidget {
  final int level;
  final int coinsEarned;
  final bool isWin;
  final int movesUsed;

  const CrosswordSuccessScreen({
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
      background: const CrosswordNatureBackground(),
      primaryColor: const Color(0xFF00E676),
      accentColor: const Color(0xFF69F0AE),
      darkAuraColor: const Color(0xFF00331A),
      onCompleteLevel: () async {
        await CrosswordLevelService.completeLevel(
          level: level,
          stars: 3,
          score: (coinsEarned * 100) + 150,
          moves: movesUsed,
        );
      },
      onNextLevel: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CrosswordGameScreen(
              level: isWin ? level + 1 : level,
            ),
          ),
        );
      },
      onHome: () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const CrosswordHomeScreen(),
          ),
          (route) => route.isFirst,
        );
      },
    );
  }
}
