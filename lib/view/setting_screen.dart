import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word_puzzle/view/welcome_screen.dart';
import 'package:word_puzzle/widget/app_3d_button.dart';
import 'package:word_puzzle/widget/bg_container.dart';
import 'package:word_puzzle/widget/floating_words_background.dart';
import 'package:word_puzzle/widget/sound.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isSoundOn = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await AudioHelper().initialize();
    if (mounted) {
      setState(() {
        isSoundOn = AudioHelper().isSoundOn;
      });
    }
  }

  Future<void> _toggleSound(bool value) async {
    HapticFeedback.lightImpact();
    setState(() {
      isSoundOn = value;
    });
    await AudioHelper().toggleSound();
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: const Color(0xFF041224).withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF5252).withValues(alpha: 0.25),
                      blurRadius: 25,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFF5252).withValues(alpha: 0.18),
                        border: Border.all(
                          color: const Color(0xFFFF5252).withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: Color(0xFFFF5252),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "ARE YOU SURE?",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Logging out will reset your session. Your high scores and achievements will remain saved.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 26),
                    Row(
                      children: [
                        // NO Button
                        Expanded(
                          child: App3DButton.cyan(
                            text: 'NO',
                            height: 46,
                            fontSize: 14,
                            borderRadius: 23.0,
                            onPressed: () {
                              Navigator.pop(dialogContext);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        // YES Button
                        Expanded(
                          child: App3DButton(
                            text: 'YES',
                            height: 46,
                            fontSize: 14,
                            borderRadius: 23.0,
                            gradientColors: const [
                              Color(0xFFFF5252),
                              Color(0xFFD50000),
                            ],
                            shadowColor: const Color(0xFF8B0000),
                            glowColor: const Color(0xFFFF5252),
                            textColor: Colors.white,
                            onPressed: () async {
                              final prefs =
                                  await SharedPreferences.getInstance();

                              // Preserve daily rewards, sound, locale
                              final rewardKeys = prefs
                                  .getKeys()
                                  .where((k) =>
                                      k.startsWith('daily_reward_') ||
                                      k.startsWith('last_claim_date'))
                                  .toList();
                              final Map<String, String> preservedRewards = {};
                              for (final key in rewardKeys) {
                                final val = prefs.getString(key);
                                if (val != null) preservedRewards[key] = val;
                              }
                              final soundOn = prefs.getBool('sound_on');
                              final locale = prefs.getString('locale');

                              await prefs.clear();

                              for (final entry in preservedRewards.entries) {
                                await prefs.setString(entry.key, entry.value);
                              }
                              if (soundOn != null) {
                                await prefs.setBool('sound_on', soundOn);
                              }
                              if (locale != null) {
                                await prefs.setString('locale', locale);
                              }

                              try {
                                final GoogleSignIn googleSignIn =
                                    GoogleSignIn();
                                await googleSignIn.signOut();
                              } catch (e) {
                                // Ignore Google sign out error
                              }

                              if (context.mounted) {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const WelcomeScreen()),
                                  (Route<dynamic> route) => false,
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundContainer(
        child: Stack(
          children: [
            // 1. Cyber-Oceanic Dark Scrim
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF001428).withValues(alpha: 0.88),
                      const Color(0xFF030D1B).withValues(alpha: 0.92),
                      const Color(0xFF000814).withValues(alpha: 0.96),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // 2. Ambient Floating Words Overlay
            const FloatingWordsBackground(isWordix: true),

            // 3. Main Content
            SafeArea(
              child: Column(
                children: [
                  // Top Bar with 3D Close Button
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left placeholder for symmetry
                        const SizedBox(width: 44),
                        // Title pill in center
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF00E5FF)
                                  .withValues(alpha: 0.3),
                              width: 1.2,
                            ),
                          ),
                          child: const Text(
                            'PREFERENCES',
                            style: TextStyle(
                              color: Color(0xFF80DEEA),
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.2,
                            ),
                          ),
                        ),
                        // Right: 3D Close Button
                        App3DButton(
                          width: 42,
                          height: 42,
                          borderRadius: 21.0,
                          depth: 3.5,
                          gradientColors: const [
                            Color(0xFFFF5252),
                            Color(0xFFD50000),
                          ],
                          shadowColor: const Color(0xFF8B0000),
                          glowColor: const Color(0xFFFF5252),
                          child: const Center(
                            child: Icon(Icons.close_rounded,
                                color: Colors.white, size: 22),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Center Settings Card
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 380),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 26,
                                vertical: 32,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.20),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00E5FF)
                                        .withValues(alpha: 0.15),
                                    blurRadius: 24,
                                    spreadRadius: 2,
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Icon Badge
                                  Container(
                                    width: 68,
                                    height: 68,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF00E5FF),
                                          Color(0xFF0091EA)
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF00E5FF)
                                              .withValues(alpha: 0.45),
                                          blurRadius: 18,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.settings_rounded,
                                        color: Color(0xFF021B2D),
                                        size: 36,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 18),

                                  const Text(
                                    'SETTINGS',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 2.5,
                                      shadows: [
                                        Shadow(
                                          color: Color(0xFF00E5FF),
                                          blurRadius: 14,
                                        ),
                                        Shadow(
                                          color: Colors.black54,
                                          offset: Offset(0, 2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 30),

                                  // Sound Toggle Row with 3D tactile switch
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color:
                                            Colors.white.withValues(alpha: 0.12),
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: (isSoundOn
                                                        ? const Color(0xFF00E5FF)
                                                        : Colors.grey)
                                                    .withValues(alpha: 0.2),
                                              ),
                                              child: Icon(
                                                isSoundOn
                                                    ? Icons.volume_up_rounded
                                                    : Icons.volume_off_rounded,
                                                color: isSoundOn
                                                    ? const Color(0xFF00E5FF)
                                                    : Colors.white70,
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Text(
                                              'Sound Effects',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                        _build3DToggleSwitch(
                                          value: isSoundOn,
                                          onChanged: _toggleSound,
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  // 3D Log Out Button (Sunset Coral / Amber Gradient)
                                  App3DButton(
                                    text: 'LOG OUT',
                                    icon: Icons.logout_rounded,
                                    height: 50,
                                    fontSize: 15,
                                    borderRadius: 25.0,
                                    width: double.infinity,
                                    gradientColors: const [
                                      Color(0xFFFF7043),
                                      Color(0xFFD84315),
                                    ],
                                    shadowColor: const Color(0xFF870000),
                                    glowColor: const Color(0xFFFF7043),
                                    textColor: Colors.white,
                                    onPressed: () =>
                                        _showLogoutConfirmationDialog(context),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3D Tactile Toggle Switch
  Widget _build3DToggleSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () {
        AudioHelper().playButtonSound();
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOut,
        width: 66,
        height: 36,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: value
                ? [
                    const Color(0xFF00E5FF).withValues(alpha: 0.35),
                    const Color(0xFF00B0FF).withValues(alpha: 0.45)
                  ]
                : [
                    Colors.black.withValues(alpha: 0.5),
                    Colors.black.withValues(alpha: 0.7)
                  ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(
            color: value
                ? const Color(0xFF00E5FF).withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.25),
            width: 1.5,
          ),
          boxShadow: [
            if (value)
              BoxShadow(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                blurRadius: 10,
                spreadRadius: 1,
              ),
          ],
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutBack,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: value
                    ? [const Color(0xFF00E5FF), const Color(0xFF0091EA)]
                    : [const Color(0xFFB0BEC5), const Color(0xFF78909C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                value ? Icons.check_rounded : Icons.close_rounded,
                color: value ? const Color(0xFF021B2D) : Colors.white70,
                size: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
