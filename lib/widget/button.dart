import 'package:flutter/material.dart';
import 'package:word_puzzle/widget/sound.dart';

/// A full-width, rounded button with your brand colors.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final TextStyle? textStyle;
  final double? width;
  final IconData? prefixIcon;
  final Widget? prefixImage;

  const AppButton({
    super.key,
    required this.label,
    this.onTap,
    // this.backgroundColor = const Color(0xFF1100FF),
    this.backgroundColor = Colors.orangeAccent,
    this.textStyle,
    this.width,
    this.prefixIcon,
    this.prefixImage,
  });

  // @override
  // Widget build(BuildContext context) {
  //   return GestureDetector(
  //     onTap: () {
  //       AudioHelper().playButtonSound();
  //       onTap?.call();
  //     },
  //     child: Container(
  //       width: width,
  //       height: 50,
  //       decoration: BoxDecoration(
  //         gradient: const LinearGradient(
  //           colors: [Color(0xFF8BC34A), Color(0xFF388E3C)],
  //           begin: Alignment.topCenter,
  //           end: Alignment.bottomCenter,
  //         ),
  //         borderRadius: BorderRadius.circular(25),
  //         border: const Border(
  //           bottom: BorderSide(color: Color(0xFF1B5E20), width: 3),
  //           right: BorderSide(color: Color(0xFF1B5E20), width: 1),
  //         ),
  //         boxShadow: [
  //           BoxShadow(
  //             color: Colors.black.withOpacity(0.2),
  //             offset: const Offset(0, 4),
  //             blurRadius: 4,
  //           ),
  //         ],
  //       ),
  //       alignment: Alignment.center,
  //       padding: const EdgeInsets.symmetric(horizontal: 20),
  //       child: Row(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           if (prefixIcon != null)
  //             Icon(prefixIcon, color: Colors.white, size: 20),
  //           if (prefixImage != null) prefixImage!,
  //           if (prefixIcon != null || prefixImage != null)
  //             const SizedBox(width: 8),
  //           Text(
  //             label.toUpperCase(),
  //             style: textStyle ??
  //                 const TextStyle(
  //                   color: Colors.white,
  //                   fontSize: 16,
  //                   fontWeight: FontWeight.w900,
  //                   letterSpacing: 1.2,
  //                   shadows: [
  //                     Shadow(
  //                       color: Colors.black45,
  //                       offset: Offset(1, 1),
  //                       blurRadius: 2,
  //                     ),
  //                   ],
  //                 ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
  @override
Widget build(BuildContext context) {
  return
    GestureDetector(
    onTap: () {
      AudioHelper().playButtonSound();
      onTap?.call();
    },
    child: Container(
      width: width ?? MediaQuery.of(context).size.width * 0.60, // 80% width
      height: 45,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8BC34A), Color(0xFF388E3C)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(25),
        border: const Border(
          bottom: BorderSide(color: Color(0xFF1B5E20), width: 3),
          right: BorderSide(color: Color(0xFF1B5E20), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(0, 4),
            blurRadius: 4,
          ),
        ],
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (prefixIcon != null)
            Icon(prefixIcon, color: Colors.white, size: 16),
          if (prefixImage != null) prefixImage!,
          if (prefixIcon != null || prefixImage != null)
            const SizedBox(width: 4),
          Text(
            label.toUpperCase(),
            style: textStyle ??
                const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  // letterSpacing: 1.2,
                ),
          ),
        ],
      ),
    ),
  );
}
}

// import 'package:flutter/material.dart';
//
// /// A full-width, rounded button with your brand colors.
// class AppButton extends StatelessWidget {
//   final String label;
//   final VoidCallback? onTap;
//   final Color backgroundColor;
//   final TextStyle? textStyle;
//   final double width;
//   final IconData? suffixIcon;
//
//   const AppButton({
//     super.key,
//     required this.label,
//     this.onTap,
//     this.backgroundColor = const Color(0xFF1100FF),
//     this.textStyle,
//     this.width = double.infinity,
//     this.suffixIcon,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: width,
//         height: 45,
//         decoration: BoxDecoration(
//           color: backgroundColor,
//           borderRadius: BorderRadius.circular(24),
//         ),
//         alignment: Alignment.center,
//         padding: const EdgeInsets.symmetric(horizontal: 16),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               label,
//               style: textStyle ??
//                   const TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                   ),
//             ),
//             if (suffixIcon != null) ...[
//               const SizedBox(width: 8),
//               Icon(suffixIcon, color: Colors.white),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }
