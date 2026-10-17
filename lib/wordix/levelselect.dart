import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../db/prefs.dart';
import '../widget/app_3d_button.dart';
import '../widget/bg_container.dart';
import '../widget/coin_container.dart';
import '../widget/floating_words_background.dart';
import '../widget/sound.dart';
import 'word_search.dart';

class LevelSelectPage extends StatefulWidget {
  final int gridSize;

  const LevelSelectPage({
    super.key,
    required this.gridSize,
  });

  @override
  State<LevelSelectPage> createState() => _LevelSelectPageState();
}

class _LevelSelectPageState extends State<LevelSelectPage> {
  int currentMaxLevel = 1;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMaxLevel();
  }

  Future<void> _loadMaxLevel() async {
    final savedLevel = await Prefs.getMaxLevel(widget.gridSize);
    if (mounted) {
      setState(() {
        currentMaxLevel = savedLevel;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveMaxLevel(int newLevel) async {
    if (newLevel > currentMaxLevel) {
      await Prefs.saveMaxLevel(widget.gridSize, newLevel);
      await _loadMaxLevel();
    }
  }

  String _getDifficultyName() {
    switch (widget.gridSize) {
      case 6:
        return 'EASY';
      case 8:
        return 'MEDIUM';
      case 10:
        return 'HARD';
      default:
        return '${widget.gridSize}×${widget.gridSize}';
    }
  }

  Color _getDifficultyColor() {
    switch (widget.gridSize) {
      case 6:
        return const Color(0xFF00E676);
      case 8:
        return const Color(0xFF00E5FF);
      case 10:
        return const Color(0xFFFF5252);
      default:
        return const Color(0xFF00E5FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final diffColor = _getDifficultyColor();

    return Scaffold(
      backgroundColor: const Color(0xFF020B18),
      body: Stack(
        children: [
          // 1. Dynamic Wallpaper Background with Dark Cyber Scrim
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

          // 2. Ambient glow orbs
          Positioned(
            top: 40,
            right: -30,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: diffColor.withOpacity(0.08),
              ),
            ),
          ),

          // 3. Floating Words & Particle Overlay
          const Positioned.fill(
            child: FloatingWordsBackground(
              baseColor: Color(0xFF00E5FF),
              accentColor: Color(0xFF7C4DFF),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LEVELS',
                              style: GoogleFonts.fredoka(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: const Color(0xFF00E5FF)
                                        .withOpacity(0.5),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: diffColor.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: diffColor.withOpacity(0.6),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    '${_getDifficultyName()} • ${widget.gridSize}×${widget.gridSize}',
                                    style: GoogleFonts.nunito(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: diffColor,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const CoinBalanceWidget(),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                // Level Progress Banner
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A2239).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.emoji_events_rounded,
                              size: 20,
                              color: Color(0xFFFFD700),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'UNLOCKED PROGRESS',
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.white70,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '$currentMaxLevel / 20 COMPLETED',
                          style: GoogleFonts.fredoka(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF00E5FF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Grid of 3D Level Pods
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF00E5FF)),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          physics: const BouncingScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.88,
                          ),
                          itemCount: 20,
                          itemBuilder: (context, index) {
                            final level = index + 1;
                            final isUnlocked = level <= currentMaxLevel;
                            final isCurrent = level == currentMaxLevel;

                            return _Level3DPod(
                              level: level,
                              isUnlocked: isUnlocked,
                              isCurrent: isCurrent,
                              onTap: isUnlocked
                                  ? () async {
                                      AudioHelper().playButtonSound();
                                      final result = await Navigator.push<int>(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => WordSearchPage(
                                            initialLevel: level,
                                            gridSize: widget.gridSize,
                                          ),
                                        ),
                                      );
                                      if (result != null) {
                                        await _saveMaxLevel(result);
                                      }
                                      await _loadMaxLevel();
                                    }
                                  : () {
                                      AudioHelper().playButtonSound();
                                      ScaffoldMessenger.of(context)
                                          .hideCurrentSnackBar();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Complete Level ${level - 1} first!'),
                                          duration: const Duration(seconds: 1),
                                          backgroundColor:
                                              const Color(0xFF0A2239),
                                        ),
                                      );
                                    },
                            );
                          },
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

class _Level3DPod extends StatefulWidget {
  final int level;
  final bool isUnlocked;
  final bool isCurrent;
  final VoidCallback onTap;

  const _Level3DPod({
    required this.level,
    required this.isUnlocked,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  State<_Level3DPod> createState() => _Level3DPodState();
}

class _Level3DPodState extends State<_Level3DPod> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final double depth = widget.isUnlocked ? 5.0 : 3.0;

    // Palette depending on state
    Color baseColor;
    Color topHighlight;
    Color shadowColor;
    Color textColor;
    Color borderColor;

    if (widget.isCurrent) {
      // Golden/Amber active level
      baseColor = const Color(0xFF0077B6);
      topHighlight = const Color(0xFF00E5FF);
      shadowColor = const Color(0xFF03045E);
      textColor = Colors.white;
      borderColor = const Color(0xFF00E5FF);
    } else if (widget.isUnlocked) {
      // Cleared / Unlocked level
      baseColor = const Color(0xFF0A2E50);
      topHighlight = const Color(0xFF144B7E);
      shadowColor = const Color(0xFF03101E);
      textColor = const Color(0xFFE0FBFC);
      borderColor = const Color(0xFF00B4D8).withOpacity(0.5);
    } else {
      // Locked level
      baseColor = const Color(0xFF0B1622);
      topHighlight = const Color(0xFF132233);
      shadowColor = const Color(0xFF04080D);
      textColor = Colors.white30;
      borderColor = Colors.white.withOpacity(0.06);
    }

    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        HapticFeedback.mediumImpact();
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        transform: Matrix4.translationValues(0, _isPressed ? depth : 0, 0),
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            top: BorderSide(color: topHighlight, width: 2),
            left: BorderSide(color: borderColor, width: 1.5),
            right: BorderSide(color: borderColor, width: 1.5),
            bottom:
                BorderSide(color: shadowColor, width: _isPressed ? 1.5 : depth),
          ),
          boxShadow: [
            if (!_isPressed && widget.isUnlocked)
              BoxShadow(
                color: widget.isCurrent
                    ? const Color(0xFF00E5FF).withOpacity(0.35)
                    : Colors.black.withOpacity(0.4),
                blurRadius: widget.isCurrent ? 12 : 6,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Top gloss line
            Positioned(
              top: 3,
              left: 6,
              right: 6,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color:
                      Colors.white.withOpacity(widget.isUnlocked ? 0.35 : 0.08),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!widget.isUnlocked) ...[
                  const Icon(
                    Icons.lock_rounded,
                    size: 20,
                    color: Colors.white30,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.level}',
                    style: GoogleFonts.fredoka(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ] else ...[
                  if (widget.isCurrent)
                    const Icon(
                      Icons.play_arrow_rounded,
                      size: 16,
                      color: Color(0xFF00E5FF),
                    )
                  else
                    const Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: Color(0xFFFFD700),
                    ),
                  const SizedBox(height: 1),
                  Text(
                    '${widget.level}',
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                      shadows: [
                        if (widget.isCurrent)
                          const Shadow(
                            color: Color(0xFF00E5FF),
                            blurRadius: 8,
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),

            // Current Badge Dot
            if (widget.isCurrent)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF00E5FF),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF00E5FF),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
