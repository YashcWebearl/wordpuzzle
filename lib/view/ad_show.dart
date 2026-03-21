// import 'package:flutter/material.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
//
// class AdPlaybackPage extends StatefulWidget {
//   final VoidCallback onAdComplete;
//
//   const AdPlaybackPage({super.key, required this.onAdComplete});
//
//   @override
//   State<AdPlaybackPage> createState() => _AdPlaybackPageState();
// }
//
// class _AdPlaybackPageState extends State<AdPlaybackPage> {
//
//   RewardedInterstitialAd? _rewardedInterstitialAd;
//   bool _isAdLoaded = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadRewardedAd();
//   }
//
//   void _loadRewardedAd() async {
//     bool hasConnection = true;
//
//     try {
//       var connectivityResult = await (Connectivity().checkConnectivity());
//       if (connectivityResult == ConnectivityResult.none) {
//         hasConnection = false;
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('No internet connection. Try again.')),
//         );
//         widget.onAdComplete();
//         Navigator.pop(context);
//         return;
//       }
//     } catch (e) {
//       print('Connectivity check failed: $e');
//     }
//
//     RewardedInterstitialAd.load(
//       adUnitId: 'ca-app-pub-3212732022684570/8803285020', // ✅ Your real ID
//       request: const AdRequest(),
//       rewardedInterstitialAdLoadCallback:
//       RewardedInterstitialAdLoadCallback(
//         onAdLoaded: (RewardedInterstitialAd ad) {
//           _rewardedInterstitialAd = ad;
//           _isAdLoaded = true;
//           _showAd();
//         },
//         onAdFailedToLoad: (LoadAdError error) {
//           print('Ad failed to load: $error');
//           Navigator.pop(context);
//         },
//       ),
//     );
//   }
//
//   void _showAd() {
//     if (_rewardedInterstitialAd != null) {
//       _rewardedInterstitialAd!.fullScreenContentCallback =
//           FullScreenContentCallback(
//             onAdDismissedFullScreenContent: (ad) {
//               ad.dispose();
//               widget.onAdComplete();
//               Navigator.pop(context);
//             },
//             onAdFailedToShowFullScreenContent: (ad, error) {
//               ad.dispose();
//               Navigator.pop(context);
//             },
//           );
//
//       _rewardedInterstitialAd!.show(
//         onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
//           print('User earned reward: ${reward.amount} ${reward.type}');
//
//           // 👉 Ahiya tame coin / diamond add kari sako
//           // Example:
//           // context.read<CoinProvider>().addCoins(50);
//         },
//       );
//     }
//   }
//
//   @override
//   void dispose() {
//     _rewardedInterstitialAd?.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return PopScope(
//       canPop: false,
//       onPopInvoked: (didPop) async {
//         return;
//       },
//       child: SafeArea(
//         child: Scaffold(
//           backgroundColor: Colors.black.withOpacity(0.8),
//           body: Center(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 24.0),
//               child: Container(
//                 padding: const EdgeInsets.all(24),
//                 decoration: BoxDecoration(
//                   gradient: const LinearGradient(
//                     colors: [Color(0xFFAEEA00), Color(0xFF64DD17)],
//                     begin: Alignment.topCenter,
//                     end: Alignment.bottomCenter,
//                   ),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     const Text(
//                       'Loading Ad...',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         fontFamily: 'Pridi',
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                     if (!_isAdLoaded)
//                       const CircularProgressIndicator(color: Colors.white),
//                     const SizedBox(height: 20),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class AdPlaybackPage extends StatefulWidget {
  final VoidCallback onAdComplete;

  const AdPlaybackPage({super.key, required this.onAdComplete});

  @override
  State<AdPlaybackPage> createState() => _AdPlaybackPageState();
}

class _AdPlaybackPageState extends State<AdPlaybackPage> {

  RewardedInterstitialAd? _rewardedInterstitialAd;
  bool _isAdLoaded = false;
  bool _isRewardEarned = false; // ✅ important flag

  @override
  void initState() {
    super.initState();
    _loadRewardedAd();
  }

  void _loadRewardedAd() async {
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());

      if (connectivityResult == ConnectivityResult.none) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No internet connection. Try again.')),
        );
        Navigator.pop(context);
        return;
      }
    } catch (e) {
      print('Connectivity check failed: $e');
    }

    RewardedInterstitialAd.load(
      adUnitId: 'ca-app-pub-3212732022684570/8803285020',
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback:
      RewardedInterstitialAdLoadCallback(

        onAdLoaded: (RewardedInterstitialAd ad) {
          _rewardedInterstitialAd = ad;

          setState(() {
            _isAdLoaded = true;
          });

          _showAd();
        },

        onAdFailedToLoad: (LoadAdError error) {
          print('Ad failed to load: $error');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ad failed: ${error.message}')),
          );

          Navigator.pop(context);
        },
      ),
    );
  }

  void _showAd() {
    if (_rewardedInterstitialAd == null) return;

    _rewardedInterstitialAd!.fullScreenContentCallback =
        FullScreenContentCallback(

          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();

            // ✅ reward only if earned
            if (_isRewardEarned) {
              widget.onAdComplete();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Watch full ad to earn reward'),
                ),
              );
            }

            Navigator.pop(context);
          },

          onAdFailedToShowFullScreenContent: (ad, error) {
            print('Ad failed to show: $error');
            ad.dispose();
            Navigator.pop(context);
          },
        );

    _rewardedInterstitialAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        print('Reward earned: ${reward.amount} ${reward.type}');

        _isRewardEarned = true; // ✅ set flag

        // 👉 Add reward logic here
        // Example:
        // context.read<CoinProvider>().addCoins(50);
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
      onPopInvoked: (didPop) async {
        return;
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.black.withOpacity(0.8),
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

























































// import 'package:flutter/material.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
//
// class AdPlaybackPage extends StatefulWidget {
//   final VoidCallback onAdComplete;
//
//   const AdPlaybackPage({super.key, required this.onAdComplete});
//
//   @override
//   State<AdPlaybackPage> createState() => _AdPlaybackPageState();
// }
//
// class _AdPlaybackPageState extends State<AdPlaybackPage> {
//
//   InterstitialAd? _interstitialAd;
//   bool _isAdLoaded = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadInterstitialAd();
//   }
//
//   void _loadInterstitialAd() async {
//     // Attempt connectivity check
//     bool hasConnection = true;
//     try {
//       var connectivityResult = await (Connectivity().checkConnectivity());
//       if (connectivityResult == ConnectivityResult.none) {
//         hasConnection = false;
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('No internet connection. Try again.')),
//         );
//         widget.onAdComplete();
//         Navigator.pop(context);
//         return;
//       }
//     } catch (e) {
//       print('Connectivity check failed: $e');
//       // Proceed with ad loading even if connectivity check fails
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Network check unavailable. Attempting to load ad.')),
//       );
//     }
//
//     InterstitialAd.load(
//       adUnitId: 'ca-app-pub-3940256099942544/1033173712', // Test ID
//       // adUnitId: 'ca-app-pub-7508634868293786/4776467304', // Real ID
//       request: const AdRequest(),
//       adLoadCallback: InterstitialAdLoadCallback(
//         onAdLoaded: (InterstitialAd ad) {
//           setState(() {
//             _interstitialAd = ad;
//             _isAdLoaded = true;
//           });
//           _showInterstitialAd();
//         },
//         onAdFailedToLoad: (LoadAdError error) {
//           print('InterstitialAd failed to load: $error');
//           print('Error code: ${error.code}, Message: ${error.message}, Domain: ${error.domain}');
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Ad failed to load: ${error.message}')),
//           );
//           // widget.onAdComplete();
//           Navigator.pop(context);
//         },
//       ),
//     );
//   }
//
//   void _showInterstitialAd() {
//     if (_isAdLoaded && _interstitialAd != null) {
//       _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
//         onAdDismissedFullScreenContent: (InterstitialAd ad) {
//           print('Ad dismissed.');
//           ad.dispose();
//           widget.onAdComplete();
//           Navigator.pop(context);
//         },
//         onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
//           print('Ad failed to show: $error');
//           ad.dispose();
//           // widget.onAdComplete();
//           // Navigator.pop(context);
//         },
//       );
//       _interstitialAd!.show();
//     }
//   }
//
//   @override
//   void dispose() {
//     _interstitialAd?.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return PopScope(
//       canPop: false,
//       onPopInvoked: (didPop) async {
//         /// Do nothing → back completely disabled
//         return;
//       },
//       child: SafeArea(
//         bottom: true,
//         top: true,
//         maintainBottomViewPadding: true,
//         child: Scaffold(
//           backgroundColor: Colors.black.withOpacity(0.8),
//           body: Center(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 24.0),
//               child: Container(
//                 padding: const EdgeInsets.all(24),
//                 decoration: BoxDecoration(
//                   // ✅ Changed to green gradient
//                   gradient: const LinearGradient(
//                     colors: [Color(0xFFAEEA00), Color(0xFF64DD17)],
//                     begin: Alignment.topCenter,
//                     end: Alignment.bottomCenter,
//                   ),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     const Text(
//                       'Loading Ad...',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         fontFamily: 'Pridi',
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                     if (!_isAdLoaded)
//                       const CircularProgressIndicator(color: Colors.white),
//                     if (_isAdLoaded)
//                       const Text(
//                         'Ad is loading. Please wait.',
//                         style: TextStyle(color: Colors.white),
//                       ),
//                     const SizedBox(height: 20),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }