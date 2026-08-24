import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:word_puzzle/widget/sound.dart';

import 'coin_noti.dart';
import 'coin_service.dart';

class CoinBalanceWidget extends StatelessWidget {
  // final int coins;
  final Color backgroundColor;
  final double borderRadius;

  const CoinBalanceWidget({
    Key? key,
    // required this.coins,
    this.backgroundColor = Colors.white,
    this.borderRadius = 20.0,
  }) : super(key: key);

  // @override
  // Widget build(BuildContext context) {
  //   // final coinProvider = Provider.of<CoinProvider>(context, listen: false);
  //   // print('coin provider111111111 :-${coinProvider.coins}');
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  //     decoration: BoxDecoration(
  //       color: backgroundColor,
  //       borderRadius: BorderRadius.circular(borderRadius),
  //     ),
  //     child: Row(
  //       children: [
  //         const Icon(
  //           Icons.monetization_on,
  //           color: Colors.amber,
  //           size: 20,
  //         ),
  //         const SizedBox(width: 5),
  //         // Text(
  //         //   '$coins',
  //         //   style: const TextStyle(
  //         //     fontWeight: FontWeight.bold,
  //         //     color: Colors.black,
  //         //   ),
  //         // ),
  //         // ValueListenableBuilder<int>(
  //         //   valueListenable: CoinNotifier.coins,
  //         //   builder: (context, coinsValue, child) {
  //         //     return Text(
  //         //       '$coinsValue',
  //         //       style: const TextStyle(
  //         //         fontSize: 20,
  //         //         fontWeight: FontWeight.bold,
  //         //         color: Colors.black,
  //         //       ),
  //         //     );
  //         //   },
  //         // ),
  //
  //         Consumer<CoinProvider>(
  //           builder: (context, coinProvider, child) {
  //             print('CoinBalanceWidget build: coins = ${coinProvider.coins}');
  //             return Text(
  //               '${coinProvider.coins}',
  //               style: const TextStyle(
  //                 fontSize: 20,
  //                 fontWeight: FontWeight.bold,
  //                 color: Color(0xFF2C004C),
  //               ),
  //             );
  //           },
  //         ),
  //       ],
  //     ),
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isNarrow = screenWidth < 360;

    final double paddingH = isNarrow ? 8.0 : 12.0;
    final double paddingV = isNarrow ? 4.0 : 6.0;
    final double imageSize = isNarrow ? 18.0 : 22.0;
    final double fontSize = isNarrow ? 14.0 : 18.0;
    final double spacing = isNarrow ? 4.0 : 8.0;

    return Consumer<CoinProvider>(
      builder: (context, coinProvider, child) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: paddingV),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFAEEA00), Color(0xFF64DD17)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: const Color(0xFFFFE082), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/coin.png', width: imageSize, height: imageSize),
              SizedBox(width: spacing),
              Text(
                '${coinProvider.coins}',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF5D4037),
                  shadows: const [
                    Shadow(
                      color: Colors.white70,
                      offset: Offset(0, 1),
                      blurRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
