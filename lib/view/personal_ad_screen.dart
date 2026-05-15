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
  bool _isLoading = true;
  Timer? _timer;
  Map<String, dynamic>? _adData;

  @override
  void initState() {
    super.initState();
    _fetchAd();
  }

  Future<void> _fetchAd() async {
    print('Starting _fetchAd in PersonalAdScreen...');
    try {
      final adService = AdService();
      final data = await adService.getGamePoster("Wordix");
      if (mounted) {
        print('Data received in Screen: $data');
        if (data == null ||
            data['gamePhoto'] == null ||
            data['gamePhoto'].toString().isEmpty) {
          print('No poster found or empty photo, redirecting to home...');
          _onCancel();
          return;
        }
        setState(() {
          _adData = data;
          _isLoading = false;
        });
        print('Starting timer after fetch...');
        _startTimer();
      }
    } catch (e) {
      print('Error in PersonalAdScreen fetch: $e');
      if (mounted) {
        _onCancel();
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        if (mounted) {
          setState(() {
            _remainingSeconds--;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _canCancel = true;
          });
        }
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onCancel() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => widget.nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full Screen Ad Image
          _isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: Colors.amber,
                        strokeWidth: 3,
                      ),
                      SizedBox(height: 15),
                      Text(
                        "Loading Ad...",
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : Positioned.fill(
                  child: Image.network(
                    _adData!['gamePhoto'],
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.amber,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      print("Image load error, redirecting...");
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _onCancel();
                      });
                      return const SizedBox.shrink();
                    },
                  ),
                ),

          // Overlay Gradient (Optional, to make timer/button more readable)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.2, 0.8, 1.0],
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.4),
                  ],
                ),
              ),
            ),
          ),

          // Cancel Button / Timer
          if (!_isLoading && _adData != null)
            Positioned(
              top: 60,
              right: 25,
              child: _canCancel
                  ? GestureDetector(
                      onTap: _onCancel,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(25),
                        border:
                            Border.all(color: Colors.amber.withOpacity(0.5)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.1),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.amber),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Skip in $_remainingSeconds",
                            style: GoogleFonts.dynaPuff(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}
