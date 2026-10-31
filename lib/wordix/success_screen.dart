import 'package:flutter/material.dart';
import 'package:word_puzzle/widget/bg_container.dart';
import 'package:word_puzzle/widget/common_game_success_screen.dart';
import 'package:word_puzzle/widget/floating_words_background.dart';
import 'home_screen.dart';

/// Wordix Success Screen powered by CommonGameSuccessScreen
class SuccessScreen extends StatelessWidget {
  final int level;
  final int? coin;
  final int gridSize;
  final VoidCallback onNextLevel;
  final VoidCallback onBackToLevels;

  const SuccessScreen({
    super.key,
    required this.level,
    this.coin,
    required this.gridSize,
    required this.onNextLevel,
    required this.onBackToLevels,
  });

  @override
  Widget build(BuildContext context) {
    return CommonGameSuccessScreen(
      level: level,
      coinsEarned: coin ?? 3,
      isWin: true,
      background: Stack(
        fit: StackFit.expand,
        children: [
          BackgroundContainer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.1,
                  colors: [
                    const Color(0xFF0D1B2A).withValues(alpha: 0.85),
                    const Color(0xFF000814).withValues(alpha: 0.95),
                  ],
                ),
              ),
            ),
          ),
          const FloatingWordsBackground(isWordix: true),
        ],
      ),
      primaryColor: const Color(0xFF00E5FF),
      accentColor: const Color(0xFF80D8FF),
      darkAuraColor: const Color(0xFF0A2239),
      onNextLevel: () async {
        Navigator.pop(context);
        onNextLevel();
      },
      onHome: () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const HomePage(),
          ),
          (route) => false,
        );
      },
    );
  }
}
