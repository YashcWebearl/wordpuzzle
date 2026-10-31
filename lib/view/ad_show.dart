import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:word_puzzle/services/daily_service.dart';

class AdPlaybackPage extends StatefulWidget {
  final VoidCallback onAdComplete;
  final bool isRewardAd;

  const AdPlaybackPage({
    super.key,
    required this.onAdComplete,
    this.isRewardAd = false,
  });

  @override
  State<AdPlaybackPage> createState() => _AdPlaybackPageState();
}

class _AdPlaybackPageState extends State<AdPlaybackPage> {
  RewardedInterstitialAd? _rewardedInterstitialAd;
  bool _isAdLoaded = false;
  bool _isRewardEarned = false;
  bool _hasClosed = false;

  @override
  void initState() {
    super.initState();
    _loadAndShowAd();
  }

  void _finishAndClose({bool isError = false}) {
    if (_hasClosed) return;
    _hasClosed = true;

    if (mounted) {
      Navigator.pop(context);
    }

    if (widget.isRewardAd) {
      if (_isRewardEarned) {
        DailyService().updateTaskProgress(
          taskKey: 'watch_ad',
          increment: 1,
          gameName: 'Wordix',
        );
        widget.onAdComplete();
      } else if (!isError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Watch full ad to earn reward'),
          ),
        );
      }
    } else {
      // For level win / interstitial ads, always proceed to success screen
      widget.onAdComplete();
    }
  }

  void _loadAndShowAd() async {
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult.contains(ConnectivityResult.none)) {
        if (mounted && widget.isRewardAd) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No internet connection. Try again.')),
          );
        }
        _finishAndClose(isError: true);
        return;
      }
    } catch (e) {
      print('Connectivity check failed: $e');
    }

    RewardedInterstitialAd.load(
      adUnitId: 'ca-app-pub-3212732022684570/8803285020',
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (RewardedInterstitialAd ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          _rewardedInterstitialAd = ad;
          setState(() {
            _isAdLoaded = true;
          });
          _showRewardedInterstitialAd();
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('RewardedInterstitialAd failed to load: $error');
          _finishAndClose(isError: true);
        },
      ),
    );
  }

  void _showRewardedInterstitialAd() {
    if (_rewardedInterstitialAd == null) {
      _finishAndClose(isError: true);
      return;
    }

    _rewardedInterstitialAd!.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _finishAndClose();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('Ad failed to show: $error');
        ad.dispose();
        _finishAndClose(isError: true);
      },
    );

    _rewardedInterstitialAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        print('Reward earned: ${reward.amount} ${reward.type}');
        _isRewardEarned = true;
      },
    );
  }

  @override
  void dispose() {
    _rewardedInterstitialAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        return;
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.black.withValues(alpha: 0.8),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFAEEA00), Color(0xFF64DD17)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Loading Ad...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Pridi',
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (!_isAdLoaded)
                      const CircularProgressIndicator(color: Colors.white),
                    if (_isAdLoaded)
                      const Text(
                        'Ad is loading. Please wait...',
                        style: TextStyle(color: Colors.white),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
