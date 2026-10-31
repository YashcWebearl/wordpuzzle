import 'package:flutter/material.dart';
import 'package:word_puzzle/widget/common_game_home_screen.dart';
import 'package:word_puzzle/widget/sound.dart';
import 'balloon_background.dart';
import 'balloon_game.dart';
import 'balloon_level_service.dart';
import 'balloon_logo.dart';

/// Balloon Rescue Home Screen powered by CommonGameHomeScreen
class BalloonHomeScreen extends StatefulWidget {
  const BalloonHomeScreen({super.key});

  @override
  State<BalloonHomeScreen> createState() => _BalloonHomeScreenState();
}

class _BalloonHomeScreenState extends State<BalloonHomeScreen> {
  int _currentLevel = 1;

  @override
  void initState() {
    super.initState();
    AudioHelper().initialize();
    _loadLevel();
    BalloonLevelService.levelNotifier.addListener(_onLevelChanged);
  }

  @override
  void dispose() {
    BalloonLevelService.levelNotifier.removeListener(_onLevelChanged);
    super.dispose();
  }

  void _onLevelChanged() {
    if (mounted) {
      setState(() {
        _currentLevel = BalloonLevelService.levelNotifier.value;
      });
    }
  }

  Future<void> _loadLevel() async {
    final lvl = await BalloonLevelService.init();
    if (mounted) {
      setState(() => _currentLevel = lvl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommonGameHomeScreen(
      gameTagline: 'BALLOON RESCUE & WORDQUEST',
      gameSubtitle: 'Guess letters & keep all 5 balloons floating',
      logoWidget: const BalloonRescueLogo(size: 135),
      background: const BalloonSkyBackground(),
      currentLevel: _currentLevel,
      primaryColor: const Color(0xFFFF9100),
      accentColor: const Color(0xFFFFD54F),
      arcadeHubGradient: const [
        Color(0xFF4E342E),
        Color(0xFF2E1909),
      ],
      arcadeHubShadow: const Color(0xFF1A0A02),
      settingsGradient: const [
        Color(0xFF4E342E),
        Color(0xFF2E1909),
      ],
      settingsShadow: const Color(0xFF1A0A02),
      playButtonGradient: const [
        Color(0xFFFFD54F),
        Color(0xFFFF9100),
      ],
      playButtonShadow: const Color(0xFFE65100),
      playButtonTextColor: const Color(0xFF3E2723),
      onPlay: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BalloonGameScreen(level: _currentLevel),
          ),
        );
      },
      onSelectLevel: null,
    );
  }
}
