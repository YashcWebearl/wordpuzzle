import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:word_puzzle/widget/app_3d_button.dart';
import 'package:word_puzzle/widget/coin_container.dart';
import 'balloon_background.dart';
import 'balloon_game.dart';
import 'balloon_level_service.dart';

class BalloonLevelSelectScreen extends StatefulWidget {
  const BalloonLevelSelectScreen({super.key});

  @override
  State<BalloonLevelSelectScreen> createState() =>
      _BalloonLevelSelectScreenState();
}

class _BalloonLevelSelectScreenState extends State<BalloonLevelSelectScreen> {
  int _maxUnlockedLevel = 1;
  final Map<int, int> _levelStars = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final maxLvl = await BalloonLevelService.getMaxUnlockedLevel();
    final stars = <int, int>{};
    for (int i = 1; i <= maxLvl; i++) {
      stars[i] = await BalloonLevelService.getStarsForLevel(i);
    }
    if (mounted) {
      setState(() {
        _maxUnlockedLevel = maxLvl;
        _levelStars.addAll(stars);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BalloonSkyBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    App3DButton(
                      width: 44,
                      height: 44,
                      borderRadius: 14,
                      color: const Color(0xFF0D47A1).withValues(alpha: 0.75),
                      topHighlightColor: const Color(0xFF1976D2),
                      shadowColor: const Color(0xFF002171),
                      onPressed: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    Text(
                      'SELECT LEVEL',
                      style: GoogleFonts.fredoka(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    const CoinBalanceWidget(),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Level Grid (1 to 100)
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.88,
                        ),
                        itemCount: 100,
                        itemBuilder: (context, index) {
                          final level = index + 1;
                          final isUnlocked = level <= _maxUnlockedLevel;
                          final stars = _levelStars[level] ?? 0;

                          return _buildLevelCard(level, isUnlocked, stars);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelCard(int level, bool isUnlocked, int stars) {
    return GestureDetector(
      onTap: isUnlocked
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BalloonGameScreen(level: level),
                ),
              );
            }
          : null,
      child: Container(
        decoration: BoxDecoration(
          gradient: isUnlocked
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFB300),
                    Color(0xFFFF8F00),
                    Color(0xFFFF6F00),
                  ],
                )
              : LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.45),
                  ],
                ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isUnlocked
                ? Colors.white.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.15),
            width: 2,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF8F00).withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isUnlocked)
              const Icon(
                Icons.lock_rounded,
                color: Colors.white54,
                size: 26,
              )
            else ...[
              Text(
                '$level',
                style: GoogleFonts.fredoka(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      offset: const Offset(0, 2),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // Stars
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (starIdx) {
                  final filled = starIdx < stars;
                  return Icon(
                    filled ? Icons.star_rounded : Icons.star_border_rounded,
                    color: filled ? Colors.white : Colors.white54,
                    size: 13,
                  );
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
