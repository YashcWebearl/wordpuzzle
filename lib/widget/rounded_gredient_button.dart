import 'package:flutter/material.dart';
import 'package:word_puzzle/widget/sound.dart';

class RoundedGradientButton extends StatelessWidget {
  final String? text;
  final Widget? leftIcon;
  final Widget? rightIcon;
  final double width;
  final double height;
  final VoidCallback onPressed;

  const RoundedGradientButton({
    super.key,
    this.text,
    this.leftIcon,
    this.rightIcon,
    this.width = 300,
    this.height = 57,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        AudioHelper().playButtonSound();
        onPressed();
      },
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00BFA5), Color(0xFF00695C)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(40),
          border: const Border(
            bottom: BorderSide(color: Color(0xFF004D40), width: 4),
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(0, 4),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: _buildContent(),
        ),
      ),
    );
  }

  // List<Widget> _buildContent() {
  //   if (leftIcon != null && rightIcon != null && text != null) {
  //     // Two icons and a label in between (e.g., "vs")
  //     return [
  //       leftIcon!,
  //       const SizedBox(width: 12),
  //       Text(
  //         text!,
  //         style: const TextStyle(
  //           color: Color(0xFF2C004C),
  //           fontSize: 20,
  //           fontFamily: 'Pridi',
  //           fontWeight: FontWeight.bold,
  //         ),
  //       ),
  //       const SizedBox(width: 12),
  //       rightIcon!,
  //     ];
  //   } else if (leftIcon != null && text != null) {
  //     // One icon and label (e.g., "Play ▶️")
  //     return [
  //       Text(
  //         text!,
  //         style: const TextStyle(
  //           color: Color(0xFF2C004C),
  //           fontSize: 20,
  //           fontFamily: 'Pridi',
  //           fontWeight: FontWeight.bold,
  //         ),
  //       ),
  //       // const SizedBox(width: 8),
  //       Padding(
  //         padding: const EdgeInsets.only(top: 3.0),
  //         child: leftIcon!,
  //       ),
  //     ];
  //   } else {
  //     // Fallback (only text or something wrong)
  //     return [
  //       Text(
  //         text ?? '',
  //         style: const TextStyle(
  //           color: Color(0xFF2C004C),
  //           fontSize: 20,
  //           fontFamily: 'Pridi',
  //           fontWeight: FontWeight.bold,
  //         ),
  //       ),
  //     ];
  //   }
  // }
  List<Widget> _buildContent() {
    if (leftIcon != null && rightIcon != null && text != null) {
      // Two icons and a label in between
      return [
        leftIcon!,
        const SizedBox(width: 12),
        Text(
          text!,
          style: const TextStyle(
            color: Color(0xFF2C004C),
            fontSize: 18,
            fontFamily: 'Pridi',
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 6),
        rightIcon!,
      ];
    } else if (leftIcon != null && text != null) {
      // Left icon and label
      return [
        Text(
          text!,
          style: const TextStyle(
            color: Color(0xFF2C004C),
            fontSize: 18,
            fontFamily: 'Pridi',
            fontWeight: FontWeight.bold,
          ),
        ),
        leftIcon!,
      ];
    } else if (rightIcon != null && text != null) {
      // Right icon and label
      return [
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: rightIcon!,
        ),
        const SizedBox(width: 8),
        Text(
          text!,
          style: const TextStyle(
            color: Color(0xFF2C004C),
            fontSize: 18,
            fontFamily: 'Pridi',
            fontWeight: FontWeight.bold,
          ),
        ),
      ];
    } else {
      // Fallback
      return [
        Text(
          text ?? '',
          style: const TextStyle(
            color: Color(0xFF2C004C),
            fontSize: 18,
            fontFamily: 'Pridi',
            fontWeight: FontWeight.bold,
          ),
        ),
      ];
    }
  }
}
