// import 'dart:ui';
// import 'package:flutter/material.dart';
//
// class VoyageCounter extends StatelessWidget {
//   final int count;
//   final double size;
//
//   const VoyageCounter({
//     Key? key,
//     required this.count,
//     this.size = 200,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return ClipOval(
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
//         child: Container(
//           width: size,
//           height: size,
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             color: Colors.black.withOpacity(0.4), // black transparent
//             border: Border.all(
//               color: Colors.white.withOpacity(0.25),
//               width: 1.5,
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.15),
//                 blurRadius: 12,
//                 spreadRadius: 2,
//               ),
//             ],
//           ),
//           child: Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text(
//                   '$count',
//                   style: const TextStyle(
//                     fontSize: 50,
//                     color: Colors.white,
//                     fontWeight: FontWeight.w400,
//                     fontFamily: 'Kaisei Decol',
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 const Text(
//                   'VOYAGE',
//                   style: TextStyle(
//                     fontSize: 24,
//                     color: Colors.white,
//                     fontFamily: 'Inder',
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }











import 'dart:ui';
import 'package:flutter/material.dart';

class VoyageCounter extends StatelessWidget {
  final int count;
  final double size;

  const VoyageCounter({
    Key? key,
    required this.count,
    this.size = 220,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Outer Neon Ring (Futuristic Glow)
          Container(
            width: size * 0.95,
            height: size * 0.95,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.cyanAccent.withOpacity(0.2), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent.withOpacity(0.15),
                  blurRadius: 40,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),

          // 2. Rotating Border Effect (Visual)
          ShaderMask(
            shaderCallback: (rect) => SweepGradient(
              startAngle: 0.0,
              endAngle: 3.14 * 2,
              stops: const [0.7, 1.0],
              colors: [Colors.transparent, Colors.orangeAccent],
            ).createShader(rect),
            child: Container(
              width: size * 0.88,
              height: size * 0.88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
            ),
          ),

          // 3. Main Glass Card
          ClipRRect(
            borderRadius: BorderRadius.circular(size),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                width: size * 0.78,
                height: size * 0.78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.black.withOpacity(0.4),
                      Colors.black.withOpacity(0.4),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.black.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Subtle Tech Lines
                    Container(
                      width: 40,
                      height: 2,
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent,
                        boxShadow: [BoxShadow(color: Colors.orangeAccent, blurRadius: 10)],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'LVL',
                      style: TextStyle(
                        fontSize: 16,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w300,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    Text(
                      '$count',
                      style: const TextStyle(
                        fontSize: 80,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.1,
                        fontFamily: 'Orbitron', // Game font suggest karu chu
                        shadows: [
                          Shadow(color:Colors.orangeAccent, blurRadius: 20),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    // Progress bar niche rank mate
                    // Container(
                    //   width: size * 0.3,
                    //   height: 4,
                    //   decoration: BoxDecoration(
                    //     borderRadius: BorderRadius.circular(10),
                    //     color: Colors.white12,
                    //   ),
                    //   child: FractionallySizedBox(
                    //     alignment: Alignment.centerLeft,
                    //     widthFactor: 0.7, // Level progress handle karva mate
                    //     child: Container(
                    //       decoration: BoxDecoration(
                    //         borderRadius: BorderRadius.circular(10),
                    //         color: Colors.cyanAccent,
                    //       ),
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          ),

          // 4. Circular Tech Ornaments
          ...List.generate(8, (index) {
            return Transform.rotate(
              angle: (index * 45) * 3.14159 / 180,
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: 2,
                  height: 10,
                  margin: EdgeInsets.only(top: size * 0.02),
                  color: index % 2 == 0 ? Colors.orangeAccent : Colors.white24,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}


















//
// import 'dart:ui';
// import 'package:flutter/material.dart';
//
// class VoyageCounter extends StatelessWidget {
//   final int count;
//   final double size;
//
//   const VoyageCounter({
//     Key? key,
//     required this.count,
//     this.size = 200,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: size,
//       height: size,
//       child: Stack(
//         alignment: Alignment.center,
//         children: [
//           // 1. Outer Glowing Aura
//           Container(
//             width: size,
//             height: size,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               gradient: SweepGradient(
//                 colors: [
//                   Colors.amber.withOpacity(0.0),
//                   Colors.amber.withOpacity(0.4),
//                   Colors.greenAccent.withOpacity(0.4),
//                   Colors.amber.withOpacity(0.0),
//                 ],
//               ),
//             ),
//           ),
//
//           // 2. The Ancient Stone & Bronze Ring
//           Container(
//             width: size * 0.82,
//             height: size * 0.82,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               color: const Color(0xFF2D2D2D), // Deep Stone color
//               border: Border.all(
//                 color: const Color(0xFFC5A059), // Bronze Gold
//                 width: 5,
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.7),
//                   blurRadius: 20,
//                   spreadRadius: 2,
//                 ),
//                 BoxShadow(
//                   color: Colors.amber.withOpacity(0.2),
//                   blurRadius: 30,
//                   spreadRadius: -5,
//                 ),
//               ],
//             ),
//           ),
//
//           // 3. Floating Glass Fragment with Heavy Blur
//           ClipOval(
//             child: BackdropFilter(
//               filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
//               child: Container(
//                 width: size * 0.72,
//                 height: size * 0.72,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   gradient: LinearGradient(
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                     colors: [
//                       Colors.white.withOpacity(0.15),
//                       Colors.black.withOpacity(0.3),
//                     ],
//                   ),
//                 ),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Text(
//                       'LEVEL',
//                       style: TextStyle(
//                         fontSize: 14,
//                         letterSpacing: 5,
//                         fontWeight: FontWeight.w900,
//                         color: Colors.amber.shade200,
//                         shadows: const [
//                           Shadow(blurRadius: 10, color: Colors.black),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       '$count',
//                       style: const TextStyle(
//                         fontSize: 72,
//                         height: 1,
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                         fontFamily: 'serif',
//                         shadows: [
//                           Shadow(color: Colors.white60, blurRadius: 10),
//                           Shadow(color: Colors.amber, blurRadius: 25),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//
//           // 4. Magical Rune Notches (Fixing the loop and positioning)
//           ...List.generate(4, (index) {
//             return Transform.rotate(
//               angle: (index * 90) * 3.14159 / 180,
//               child: Align(
//                 alignment: Alignment.topCenter,
//                 child: Container(
//                   width: 14,
//                   height: 20,
//                   margin: EdgeInsets.only(top: size * 0.05),
//                   decoration: BoxDecoration(
//                     color: const Color(0xFFC5A059),
//                     borderRadius: BorderRadius.circular(4),
//                     boxShadow: const [
//                       BoxShadow(color: Colors.amber, blurRadius: 12),
//                     ],
//                   ),
//                 ),
//               ),
//             );
//           }),
//         ],
//       ),
//     );
//   }
// }
//
//
