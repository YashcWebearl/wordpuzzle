import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:word_puzzle/widget/bg_container.dart';
import 'package:word_puzzle/widget/common_game_home_screen.dart';
import 'package:word_puzzle/widget/floating_words_background.dart';
import 'package:word_puzzle/widget/get_level.dart';
import 'package:word_puzzle/wordix/word_search.dart';

/// Wordix Home Screen powered by CommonGameHomeScreen
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<GameLevelProvider>(context, listen: false).refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameLevelProvider = Provider.of<GameLevelProvider>(context);
    final currentLevel = gameLevelProvider.currentLevel;
    final gridSize = gameLevelProvider.currentGridSize;

    return CommonGameHomeScreen(
      gameTagline: 'WORDIX SEARCH & VOYAGE',
      gameSubtitle: 'Find words in the letter grid & advance your voyage',
      logoWidget: Center(
        child: Image.asset(
          'assets/icon/icon3.png',
          width: 120,
          height: 120,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.extension_rounded,
            color: Color(0xFF00E5FF),
            size: 70,
          ),
        ),
      ),
      arcadeHubGradient: const [
        Color(0xFF0F3057),
        Color(0xFF002244),
      ],
      arcadeHubShadow: const Color(0xFF001122),
      settingsGradient: const [
        Color(0xFF0F3057),
        Color(0xFF002244),
      ],
      settingsShadow: const Color(0xFF001122),
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
      currentLevel: currentLevel,
      primaryColor: const Color(0xFF00E5FF),
      accentColor: const Color(0xFF80D8FF),
      playButtonGradient: const [
        Color(0xFF00E5FF),
        Color(0xFF0091EA),
      ],
      playButtonShadow: const Color(0xFF002244),
      playButtonTextColor: const Color(0xFF001122),
      onPlay: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WordSearchPage(
              gridSize: gridSize,
              initialLevel: currentLevel,
            ),
          ),
        );
      },
    );
  }
}
