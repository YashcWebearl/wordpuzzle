import 'package:flutter/material.dart';
import 'package:word_puzzle/widget/common_game_home_screen.dart';
import 'crossword_background.dart';
import 'crossword_game.dart';
import 'crossword_level_service.dart';
import 'crossword_logo.dart';

/// Crossword Home Screen powered by CommonGameHomeScreen
class CrosswordHomeScreen extends StatefulWidget {
  const CrosswordHomeScreen({super.key});

  @override
  State<CrosswordHomeScreen> createState() => _CrosswordHomeScreenState();
}

class _CrosswordHomeScreenState extends State<CrosswordHomeScreen> {
  int _currentLevel = 1;

  @override
  void initState() {
    super.initState();
    _currentLevel = CrosswordLevelService.levelNotifier.value;
    CrosswordLevelService.levelNotifier.addListener(_onLevelChanged);
    _loadState();
  }

  void _onLevelChanged() {
    if (mounted && _currentLevel != CrosswordLevelService.levelNotifier.value) {
      setState(() {
        _currentLevel = CrosswordLevelService.levelNotifier.value;
      });
    }
  }

  @override
  void dispose() {
    CrosswordLevelService.levelNotifier.removeListener(_onLevelChanged);
    super.dispose();
  }

  Future<void> _loadState() async {
    final lvl = await CrosswordLevelService.getLocalLevel();
    if (mounted && _currentLevel != lvl) {
      setState(() => _currentLevel = lvl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommonGameHomeScreen(
      gameTagline: 'WOODLAND ODYSSEY',
      gameSubtitle: 'Connect letters to uncover crossword secrets',
      logoWidget: const CrosswordLogo(size: 135),
      background: const CrosswordNatureBackground(),
      currentLevel: _currentLevel,
      primaryColor: const Color(0xFF00E676),
      accentColor: const Color(0xFF69F0AE),
      arcadeHubGradient: const [
        Color(0xFF1B4332),
        Color(0xFF0F291E),
      ],
      arcadeHubShadow: const Color(0xFF07140E),
      settingsGradient: const [
        Color(0xFF1B4332),
        Color(0xFF0F291E),
      ],
      settingsShadow: const Color(0xFF07140E),
      playButtonGradient: const [
        Color(0xFF00E676),
        Color(0xFF00B0FF),
      ],
      playButtonShadow: const Color(0xFF004D40),
      playButtonTextColor: Colors.white,
      onPlay: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CrosswordGameScreen(level: _currentLevel),
          ),
        );
      },
    );
  }
}
