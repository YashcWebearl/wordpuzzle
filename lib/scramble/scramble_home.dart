import 'package:flutter/material.dart';
import 'package:word_puzzle/widget/common_game_home_screen.dart';
import 'scramble_background.dart';
import 'scramble_game.dart';
import 'scramble_level_service.dart';
import 'scramble_logo.dart';

/// Scramble Home Screen powered by CommonGameHomeScreen
class ScrambleHomeScreen extends StatefulWidget {
  const ScrambleHomeScreen({super.key});

  @override
  State<ScrambleHomeScreen> createState() => _ScrambleHomeScreenState();
}

class _ScrambleHomeScreenState extends State<ScrambleHomeScreen> {
  int _currentLevel = 1;

  @override
  void initState() {
    super.initState();
    _currentLevel = ScrambleLevelService.levelNotifier.value;
    ScrambleLevelService.levelNotifier.addListener(_onLevelChanged);
    _loadState();
  }

  void _onLevelChanged() {
    if (mounted && _currentLevel != ScrambleLevelService.levelNotifier.value) {
      setState(() {
        _currentLevel = ScrambleLevelService.levelNotifier.value;
      });
    }
  }

  @override
  void dispose() {
    ScrambleLevelService.levelNotifier.removeListener(_onLevelChanged);
    super.dispose();
  }

  Future<void> _loadState() async {
    final lvl = await ScrambleLevelService.init();
    if (mounted && _currentLevel != lvl) {
      setState(() => _currentLevel = lvl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommonGameHomeScreen(
      gameTagline: 'KITTY STACK & SPELL',
      gameSubtitle: 'Stack & spell letters to uncover secret words',
      logoWidget: const ScrambleLogo(size: 135),
      background: const ScrambleCosmicBackground(),
      currentLevel: _currentLevel,
      primaryColor: const Color(0xFFD500F9),
      accentColor: const Color(0xFFEA80FC),
      arcadeHubGradient: const [
        Color(0xFF4A148C),
        Color(0xFF260845),
      ],
      arcadeHubShadow: const Color(0xFF16032A),
      settingsGradient: const [
        Color(0xFF4A148C),
        Color(0xFF260845),
      ],
      settingsShadow: const Color(0xFF16032A),
      playButtonGradient: const [
        Color(0xFFE040FB),
        Color(0xFF7C4DFF),
      ],
      playButtonShadow: const Color(0xFF4A148C),
      playButtonTextColor: Colors.white,
      onPlay: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ScrambleGameScreen(level: _currentLevel),
          ),
        );
      },
    );
  }
}
