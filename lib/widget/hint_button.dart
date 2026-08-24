import 'package:flutter/material.dart';

class CustomHintButton extends StatelessWidget {
  final IconData icon;
  final int value;
  final bool showCoin;
  final VoidCallback onPressed;

  const CustomHintButton({
    Key? key,
    required this.icon,
    required this.value,
    this.showCoin = false,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isNarrow = screenWidth < 360;

    final double btnSize = isNarrow ? 40.0 : 50.0;
    final double iconSize = isNarrow ? 18.0 : 24.0;
    final double fontSize = isNarrow ? 10.0 : 12.0;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: btnSize,
        height: btnSize,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFAEEA00), Color(0xFF64DD17)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border(
            bottom: BorderSide(color: const Color(0xFF33691E), width: isNarrow ? 3 : 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              offset: const Offset(0, 4),
              blurRadius: 6,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF5D4037), size: iconSize),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showCoin == false) ...[
                  SizedBox(
                    width: isNarrow ? 3 : 5,
                  )
                ],
                Text(
                  '$value',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF5D4037),
                    fontFamily: 'Inder',
                  ),
                ),
                if (showCoin) ...[
                  SizedBox(width: isNarrow ? 2 : 4),
                  Icon(Icons.monetization_on,
                      size: isNarrow ? 10 : 14, color: Colors.amber),
                ] else ...[
                  SizedBox(
                    width: isNarrow ? 3 : 5,
                  )
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }
}
