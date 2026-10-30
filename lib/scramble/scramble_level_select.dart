import 'dart:math' as math;
import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:word_puzzle/view/ad_show.dart';
import 'package:word_puzzle/widget/app_3d_button.dart';
import 'package:word_puzzle/widget/coin_container.dart';
import 'package:word_puzzle/widget/coin_service.dart';
import 'package:word_puzzle/widget/sound.dart';
import 'scramble_level_service.dart';
import 'scramble_game.dart';

class ScrambleLevelSelectScreen extends StatefulWidget {
  const ScrambleLevelSelectScreen({super.key});

  @override
  State<ScrambleLevelSelectScreen> createState() =>
      _ScrambleLevelSelectScreenState();
}

class _ScrambleLevelSelectScreenState extends State<ScrambleLevelSelectScreen> {
  int _maxUnlocked = 1;
  final Map<int, int> _starsMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    AudioHelper().initialize();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final maxLvl = await ScrambleLevelService.getMaxUnlockedLevel();
    for (int i = 1; i <= maxLvl; i++) {
      _starsMap[i] = await ScrambleLevelService.getStarsForLevel(i);
    }
    if (mounted) {
      setState(() {
        _maxUnlocked = maxLvl;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF16082A),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.4),
                radius: 1.4,
                colors: [
                  Color(0xFF38146A),
                  Color(0xFF220A43),
                  Color(0xFF100322),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Header
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      Text(
                        'SELECT LEVEL',
                        style: GoogleFonts.fredoka(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const CoinBalanceWidget(),
                    ],
                  ),
                ),

                SizedBox(height: 10.h),

                // Level Voyage Grid
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFF4081),
                          ),
                        )
                      : GridView.builder(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20.w, vertical: 12.h),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 14.w,
                            mainAxisSpacing: 16.h,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: math.max(60, _maxUnlocked + 8),
                          itemBuilder: (context, index) {
                            final level = index + 1;
                            final isUnlocked = level <= _maxUnlocked;
                            final stars = _starsMap[level] ?? 0;
                            final isCurrent = level == _maxUnlocked;

                            return _buildLevelCard(
                              level: level,
                              isUnlocked: isUnlocked,
                              stars: stars,
                              isCurrent: isCurrent,
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

  Widget _buildLevelCard({
    required int level,
    required bool isUnlocked,
    required int stars,
    required bool isCurrent,
  }) {
    return GestureDetector(
      onTap: () async {
        if (!isUnlocked) {
          AudioHelper().playNotFoundSound();
          HapticFeedback.lightImpact();
          return;
        }

        AudioHelper().playButtonSound();
        HapticFeedback.mediumImpact();

        final connectivity = await Connectivity().checkConnectivity();
        if (!mounted) return;
        if (connectivity.contains(ConnectivityResult.none)) {
          Fluttertoast.showToast(msg: "You're offline");
          return;
        }

        final coinProvider = Provider.of<CoinProvider>(context, listen: false);
        if (coinProvider.coins < 4) {
          _showInsufficientCoinsDialog();
          return;
        }

        await coinProvider.undoCoins(4);
        AudioHelper().playMoneySound();
        Fluttertoast.showToast(msg: "4 coins deducted to start the game");

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ScrambleGameScreen(level: level),
          ),
        ).then((_) => _loadProgress());
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isCurrent
                ? const [Color(0xFFE040FB), Color(0xFF7C4DFF)]
                : (isUnlocked
                    ? const [Color(0xFF7B1FA2), Color(0xFF4A148C)]
                    : const [Color(0xFF26153E), Color(0xFF1B0E2E)]),
          ),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: isCurrent
                ? const Color(0xFFFFD54F)
                : (isUnlocked
                    ? const Color(0xFFCE93D8).withValues(alpha: 0.4)
                    : Colors.white10),
            width: isCurrent ? 2.5 : 1.2,
          ),
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                    color: const Color(0xFFD500F9).withValues(alpha: 0.5),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isUnlocked) ...[
              Text(
                '$level',
                style: GoogleFonts.poppins(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4.h),
              // Stars
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (s) {
                  final earned = s < stars;
                  return Icon(
                    Icons.star_rounded,
                    size: 14.sp,
                    color: earned ? const Color(0xFFFFD700) : Colors.white24,
                  );
                }),
              ),
            ] else ...[
              Icon(
                Icons.lock_rounded,
                color: Colors.white24,
                size: 26.sp,
              ),
              SizedBox(height: 2.h),
              Text(
                '$level',
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: Colors.white24,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showInsufficientCoinsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        contentPadding: EdgeInsets.zero,
        content: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: const Color(0xFF230D42).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: const Color(0xFFD500F9).withValues(alpha: 0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD500F9).withValues(alpha: 0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFF9100)],
                      ),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD500F9).withValues(alpha: 0.5),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.monetization_on_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'NOT ENOUGH COINS!',
                    style: GoogleFonts.fredoka(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'You need 4 coins to start this puzzle.\nWatch a quick ad to claim free bonus coins!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: App3DButton(
                          height: 48,
                          color: const Color(0xFF4A148C),
                          topHighlightColor: const Color(0xFF7B1FA2),
                          shadowColor: const Color(0xFF1E0338),
                          onPressed: () => Navigator.pop(dialogCtx),
                          child: Text(
                            'RETURN',
                            style: GoogleFonts.fredoka(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: App3DButton(
                          height: 48,
                          color: const Color(0xFFAB47BC),
                          topHighlightColor: const Color(0xFFCE93D8),
                          shadowColor: const Color(0xFF4A148C),
                          onPressed: () {
                            Navigator.pop(dialogCtx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AdPlaybackPage(
                                  isRewardAd: true,
                                  onAdComplete: () {
                                    Provider.of<CoinProvider>(context,
                                            listen: false)
                                        .addCoins(5);
                                  },
                                ),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.ondemand_video_rounded,
                                  color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                '+5 COINS',
                                style: GoogleFonts.fredoka(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
