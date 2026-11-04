import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/ad_service.dart';

class PersonalAdScreen extends StatefulWidget {
  final Widget nextScreen;

  const PersonalAdScreen({super.key, required this.nextScreen});

  @override
  State<PersonalAdScreen> createState() => _PersonalAdScreenState();
}

class _PersonalAdScreenState extends State<PersonalAdScreen> {
  int _remainingSeconds = 15;
  bool _canCancel = false;
  Timer? _timer;
  Map<String, dynamic>? _adData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAd();
  }

  Future<void> _openAdLink() async {
    final rawLink = _adData?['link']?.toString() ??
        _adData?['gameLink']?.toString() ??
        _adData?['url']?.toString() ??
        _adData?['appLink']?.toString();

    if (rawLink != null && rawLink.trim().isNotEmpty) {
      try {
        final uri = Uri.parse(rawLink.trim());
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          await launchUrl(uri);
        }
      } catch (e) {
        print("Error launching ad url: $e");
      }
    }
  }

  Future<void> _fetchAd() async {
    try {
      final adService = AdService();
      final data = await adService.getGamePoster("Wordix");
      if (mounted) {
        if (data != null &&
            data['gamePhoto'] != null &&
            data['gamePhoto'].toString().trim().isNotEmpty) {
          setState(() {
            _adData = data;
            _isLoading = false;
          });
          _startTimer();
        } else {
          // If no ad data, go directly to next screen
          _navigateToNextScreen();
        }
      }
    } catch (e) {
      print('Ad fetch exception: $e');
      if (mounted) {
        _navigateToNextScreen();
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds > 1) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        setState(() {
          _remainingSeconds = 0;
          _canCancel = true;
        });
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _navigateToNextScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => widget.nextScreen),
    );
  }

  void _onCancel() {
    if (!_canCancel) return;
    _navigateToNextScreen();
  }

  @override
  Widget build(BuildContext context) {
    final String? photoUrl = _adData?['gamePhoto']?.toString();

    return WillPopScope(
      onWillPop: () async {
        if (_canCancel) {
          _onCancel();
          return false;
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _openAdLink,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Loading state
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              else if (photoUrl != null && photoUrl.trim().isNotEmpty) ...[
                // 1. Blurred background image to fill the entire screen smoothly without black cutoffs
                Positioned.fill(
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                    child: Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      color: Colors.black.withValues(alpha: 0.5),
                      colorBlendMode: BlendMode.darken,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),

                // 2. Main foreground poster: fully visible, never cut off (BoxFit.contain)
                Positioned.fill(
                  child: SafeArea(
                    child: Center(
                      child: Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.white38,
                              size: 60,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ] else
                const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),

              // 3. Skip countdown badge OR Close / Cancel button at Top Right
              if (!_isLoading && _adData != null)
                Positioned(
                  top: 16,
                  right: 16,
                  child: SafeArea(
                    child: _canCancel
                        ? GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _onCancel,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Skip in $_remainingSeconds s",
                                  style: GoogleFonts.dynaPuff(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
