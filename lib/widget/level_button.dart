import 'package:flutter/material.dart';
import 'package:word_puzzle/widget/sound.dart';

class LevelButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed; // Allow null for disabled state
  final bool isEnabled;

  const LevelButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onPressed : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
        decoration: BoxDecoration(
          gradient: isEnabled
              ? const LinearGradient(
                  colors: [Color(0xFFAEEA00), Color(0xFF64DD17)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : const LinearGradient(
                  colors: [Colors.grey, Colors.blueGrey],
                ),
          borderRadius: BorderRadius.circular(30),
          border: Border(
            bottom: BorderSide(
                color: isEnabled ? const Color(0xFF33691E) : Colors.black26,
                width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              offset: const Offset(0, 4),
              blurRadius: 6,
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 2,
            shadows: [
              Shadow(
                color: Colors.black45,
                offset: Offset(1, 2),
                blurRadius: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}




















// class LevelButton extends StatelessWidget {
//   final String label;
//   final VoidCallback onPressed;
//
//   const LevelButton({
//     Key? key,
//     required this.label,
//     required this.onPressed,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return ElevatedButton(
//       onPressed: (){
//         // Play button click sound
//         AudioHelper().playButtonSound();
//         onPressed();
//       },
//       style: ElevatedButton.styleFrom(
//         backgroundColor: Colors.lightGreenAccent.shade700,
//         foregroundColor: Colors.white,
//         padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(30),
//         ),
//         textStyle: const TextStyle(
//           fontSize: 24,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//       child: Text(label),
//     );
//   }
// }
