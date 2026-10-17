import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widget/app_3d_button.dart';
import '../widget/bg_container.dart';
import '../widget/coin_container.dart';
import '../widget/floating_words_background.dart';
import 'levelselect.dart';

class DifficultySelectPage extends StatelessWidget {
  const DifficultySelectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020B18),
      body: Stack(
        children: [
          // 1. Dynamic Wallpaper Background with Dark Scrim
          Positioned.fill(
            child: BackgroundContainer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF001428).withOpacity(0.80),
                      const Color(0xFF030D1B).withOpacity(0.88),
                      const Color(0xFF000611).withOpacity(0.93),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. Ambient neon aura
          Positioned(
            top: -60,
            left: -40,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00E5FF).withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -50,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7C4DFF).withOpacity(0.12),
              ),
            ),
          ),

          // 3. Floating words overlay
          const Positioned.fill(
            child: FloatingWordsBackground(
              baseColor: Color(0xFF00E5FF),
              accentColor: Color(0xFF00B0FF),
              particleCount: 16,
            ),
          ),

          // 4. Foreground Content
          SafeArea(
            child: Column(
              children: [
                // Top App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      App3DIconButton(
                        icon: Icons.arrow_back_rounded,
                        color: const Color(0xFF0A2239),
                        topHighlightColor: const Color(0xFF1B4965),
                        shadowColor: const Color(0xFF03101E),
                        iconColor: const Color(0xFF00E5FF),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'DIFFICULTY',
                          style: GoogleFonts.fredoka(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: const Color(0xFF00E5FF).withOpacity(0.5),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const CoinBalanceWidget(),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Subtitle Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.grid_view_rounded,
                          size: 16,
                          color: Color(0xFF00E5FF),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'CHOOSE YOUR GRID CHALLENGE',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Difficulty Cards List
                Expanded(
                  child: ListView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _DifficultyCard(
                        title: 'EASY',
                        badge: 'BEGINNER',
                        gridLabel: '6 × 6 GRID',
                        description:
                            'Casual, fast-paced word hunting. Perfect for a quick brain warmup.',
                        icon: Icons.sentiment_satisfied_alt_rounded,
                        accentColor: const Color(0xFF00E676),
                        topColor: const Color(0xFF00E676),
                        bottomColor: const Color(0xFF00B0FF),
                        shadowColor: const Color(0xFF007E33),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const LevelSelectPage(gridSize: 6),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      _DifficultyCard(
                        title: 'MEDIUM',
                        badge: 'POPULAR',
                        gridLabel: '8 × 8 GRID',
                        description:
                            'The sweet spot. Balanced puzzles with richer multi-word overlays.',
                        icon: Icons.psychology_rounded,
                        accentColor: const Color(0xFF00E5FF),
                        topColor: const Color(0xFF00E5FF),
                        bottomColor: const Color(0xFF0091EA),
                        shadowColor: const Color(0xFF006494),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const LevelSelectPage(gridSize: 8),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      _DifficultyCard(
                        title: 'HARD',
                        badge: 'EXPERT',
                        gridLabel: '10 × 10 GRID',
                        description:
                            'Dense letter matrix with tricky criss-cross word placement for masters.',
                        icon: Icons.local_fire_department_rounded,
                        accentColor: const Color(0xFFFF5252),
                        topColor: const Color(0xFFFF5252),
                        bottomColor: const Color(0xFFD50000),
                        shadowColor: const Color(0xFF8B0000),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const LevelSelectPage(gridSize: 10),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  final String title;
  final String badge;
  final String gridLabel;
  final String description;
  final IconData icon;
  final Color accentColor;
  final Color topColor;
  final Color bottomColor;
  final Color shadowColor;
  final VoidCallback onTap;

  const _DifficultyCard({
    required this.title,
    required this.badge,
    required this.gridLabel,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.topColor,
    required this.bottomColor,
    required this.shadowColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return App3DButton(
      height: 120,
      color: const Color(0xFF0A2239),
      topHighlightColor: const Color(0xFF133A5E),
      shadowColor: const Color(0xFF04101D),
      borderColor: accentColor.withOpacity(0.35),
      borderRadius: BorderRadius.circular(22),
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            // Left 3D Icon Badge
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [topColor, bottomColor],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border(
                  top: const BorderSide(color: Colors.white60, width: 2),
                  bottom: BorderSide(color: shadowColor, width: 4),
                  left: BorderSide(color: topColor, width: 1.5),
                  right: BorderSide(color: bottomColor, width: 1.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 32,
              ),
            ),

            const SizedBox(width: 16),

            // Middle Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.fredoka(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: accentColor.withOpacity(0.6),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          badge,
                          style: GoogleFonts.nunito(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white60,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Right Grid Pill
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Text(
                    gridLabel,
                    style: GoogleFonts.fredoka(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.white38,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
