import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    _startTimer();
    _fetchAd();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 1) {
        if (mounted) {
          setState(() {
            _remainingSeconds--;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _remainingSeconds = 0;
            _canCancel = true;
          });
        }
        _timer?.cancel();
      }
    });
  }

  Future<void> _fetchAd() async {
    try {
      final adService = AdService();
      final data = await adService.getGamePoster("Wordix");
      if (mounted) {
        setState(() {
          _adData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Ad fetch exception: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onCancel() {
    if (!_canCancel) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => widget.nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? photoUrl = _adData?['gamePhoto'];

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
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Ad Image Only
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            else if (photoUrl != null && photoUrl.trim().isNotEmpty)
              Positioned.fill(
                child: Image.network(
                  photoUrl,
                  fit: BoxFit.cover,
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
              )
            else
              const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),

            // 2. Top Right: Timer badge (15s countdown) or Cancel Icon (after 15s)
            Positioned(
              top: 50,
              right: 20,
              child: SafeArea(
                child: _canCancel
                    ? GestureDetector(
                        onTap: _onCancel,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 1.5,
                            ),
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
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
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
    );
  }
}
