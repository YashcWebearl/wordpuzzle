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
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 50,
        height: 50,
        // decoration: const BoxDecoration(
        //   shape: BoxShape.circle,
        //   color: Color(0xFF3200FF), // Vibrant blue
        // ),
        decoration: BoxDecoration(
          // shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFAEEA00), Color(0xFF64DD17)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border(
            bottom: BorderSide(color: const Color(0xFF33691E), width: 4),
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
            Icon(icon, color: Color(0xFF5D4037), size: 24),
            // const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              // crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (showCoin == false) ...[
                  SizedBox(
                    width: 5,
                  )
                ],
                Text(
                  '$value',
                  style: const TextStyle(
                    // color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF5D4037),
                    fontFamily: 'Inder', // Optional: matches your style
                  ),
                ),
                if (showCoin) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.monetization_on,
                      size: 14, color: Colors.amber),
                ] else ...[
                  SizedBox(
                    width: 5,
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
