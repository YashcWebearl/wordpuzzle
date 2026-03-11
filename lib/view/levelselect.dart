import 'package:flutter/material.dart';
import 'package:word_puzzle/view/word_search.dart';
import '../db/prefs.dart';

class LevelSelectPage extends StatefulWidget {
  final int gridSize;

  const LevelSelectPage({
    super.key,
    required this.gridSize,
  });

  @override
  State<LevelSelectPage> createState() => _LevelSelectPageState();
}

class _LevelSelectPageState extends State<LevelSelectPage> {
  int currentMaxLevel = 1;

  @override
  void initState() {
    super.initState();
    _loadMaxLevel();
  }

  Future<void> _loadMaxLevel() async {
    final savedLevel = await Prefs.getMaxLevel(widget.gridSize);
    setState(() {
      currentMaxLevel = savedLevel;
    });
  }

  Future<void> _saveMaxLevel(int newLevel) async {
    if (newLevel > currentMaxLevel) {
      await Prefs.saveMaxLevel(widget.gridSize, newLevel);
      await _loadMaxLevel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDAAB5C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7A5821),
        title: const Text(
          'Select Level',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: const BackButton(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: SizedBox(
          width: 360,
          height: 640,
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1,
                    ),
                    itemCount: 20,
                    itemBuilder: (context, index) {
                      final level = index + 1;
                      final isUnlocked = level <= currentMaxLevel;

                      return GestureDetector(
                        onTap: isUnlocked
                            ? () async {
                          final result = await Navigator.push<int>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WordSearchPage(
                                initialLevel: level,
                                gridSize: widget.gridSize,
                              ),
                            ),
                          );
                          if (result != null) {
                            await _saveMaxLevel(result);
                          }
                          await _loadMaxLevel(); // Reload max level after navigation
                        }
                            : null,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isUnlocked
                                ? const Color(0xFF7A5821)
                                : Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              if (isUnlocked)
                                const BoxShadow(
                                  color: Colors.black38,
                                  offset: Offset(2, 2),
                                  blurRadius: 4,
                                ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'L$level',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isUnlocked ? Colors.white : Colors.black45,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:word_puzzle/view/word_search.dart';
//
// import '../db/prefs.dart';
//
// class LevelSelectPage extends StatefulWidget {
//   // final int currentMaxLevel;
//   final int gridSize;
//
//   const LevelSelectPage({
//     super.key,
//     // required this.currentMaxLevel,
//     required this.gridSize,
//   });
//
//   @override
//   State<LevelSelectPage> createState() => _LevelSelectPageState();
// }
//
// class _LevelSelectPageState extends State<LevelSelectPage> {
//
//   int currentMaxLevel = 1;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadMaxLevel();
//   }
//
//   Future<void> _loadMaxLevel() async {
//     final savedLevel = await Prefs.getMaxLevel(widget.gridSize);
//     setState(() {
//       currentMaxLevel = savedLevel;
//     });
//   }
//
//   Future<void> _saveMaxLevel(int newLevel) async {
//     if (newLevel > currentMaxLevel) {
//       await Prefs.saveMaxLevel(widget.gridSize, newLevel);
//       await _loadMaxLevel();
//     }
//   }
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFDAAB5C), // Black background for larger screens
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF7A5821),
//         title: const Text(
//           'Select Level',
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         ),
//         centerTitle: true,
//         leading: const BackButton(color: Colors.white),
//         elevation: 0,
//       ),
//       body: Center(
//         child: SizedBox(
//           width: 360,
//           height: 640,
//           // decoration: BoxDecoration(
//           //   // color: const Color(0xFFDAAB5C),
//           //   borderRadius: BorderRadius.circular(8),
//           //   boxShadow: const [
//           //     BoxShadow(
//           //       color: Colors.black54,
//           //       blurRadius: 10,
//           //     ),
//           //   ],
//           // ),
//           child: Column(
//             children: [
//
//               Expanded(
//                 child: Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: GridView.builder(
//                     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                       crossAxisCount: 3,
//                       mainAxisSpacing: 10,
//                       crossAxisSpacing: 10,
//                       childAspectRatio: 1,
//                     ),
//                     itemCount: 20,
//                     itemBuilder: (context, index) {
//                       final level = index + 1;
//                       final isUnlocked = level <= currentMaxLevel;
//
//                       return GestureDetector(
//                         onTap: isUnlocked
//                             ? () async {
//                           final result = await Navigator.push<int>(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => WordSearchPage(
//                                 initialLevel: level,
//                                 gridSize: widget.gridSize,
//                               ),
//                             ),
//                           );
//
//                           // if (result != null && result > widget.currentMaxLevel) {
//                           //   Navigator.pushReplacement(
//                           //     context,
//                           //     MaterialPageRoute(
//                           //       builder: (context) => LevelSelectPage(
//                           //         // currentMaxLevel: result,
//                           //         gridSize: widget.gridSize,
//                           //       ),
//                           //     ),
//                           //   );
//                           // }
//                           if (result != null) {
//                             await _saveMaxLevel(result);
//                           }
//                         }
//                             : null,
//                         child: Container(
//                           decoration: BoxDecoration(
//                             color: isUnlocked
//                                 ? const Color(0xFF7A5821)
//                                 : Colors.grey.shade400,
//                             borderRadius: BorderRadius.circular(12),
//                             boxShadow: [
//                               if (isUnlocked)
//                                 const BoxShadow(
//                                   color: Colors.black38,
//                                   offset: Offset(2, 2),
//                                   blurRadius: 4,
//                                 ),
//                             ],
//                           ),
//                           child: Center(
//                             child: Text(
//                               'L$level',
//                               style: TextStyle(
//                                 fontSize: 20,
//                                 fontWeight: FontWeight.bold,
//                                 color:
//                                 isUnlocked ? Colors.white : Colors.black45,
//                               ),
//                             ),
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
//
// // import 'package:flutter/material.dart';
// // import 'package:word_puzzle/view/word_search.dart';
// //
// // // class LevelSelectPage extends StatelessWidget {
// // //   final int currentMaxLevel;
// // //
// // //   const LevelSelectPage({super.key, required this.currentMaxLevel});
// // class LevelSelectPage extends StatelessWidget {
// //   final int currentMaxLevel;
// //   final int gridSize;
// //
// //   const LevelSelectPage({super.key, required this.currentMaxLevel, required this.gridSize});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: const Color(0xFFDAAB5C),
// //       appBar: AppBar(
// //         backgroundColor: const Color(0xFF7A5821),
// //         title: const Text(
// //           'Select Level',
// //           style: TextStyle(
// //             fontWeight: FontWeight.bold,
// //             color: Colors.white,
// //           ),
// //         ),
// //         centerTitle: true,
// //         leading: BackButton(color: Colors.white),
// //       ),
// //       body: Padding(
// //         padding: const EdgeInsets.all(5),
// //         child: GridView.builder(
// //           gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
// //             crossAxisCount: 6,
// //             mainAxisSpacing: 20,
// //             crossAxisSpacing: 20,
// //             childAspectRatio: 1,
// //           ),
// //           itemCount: 20, // Total levels, adjust as needed
// //           itemBuilder: (context, index) {
// //             final level = index + 1;
// //             final isUnlocked = level <= currentMaxLevel;
// //
// //             return GestureDetector(
// //               onTap: isUnlocked
// //                   ? () async {
// //                 // Navigate to level
// //
// //                 // Navigator.push(
// //                 // context,
// //                 // MaterialPageRoute(builder: (context) => WordSearchPage(initialLevel: level)));
// //
// //                 final result = await Navigator.push<int>(
// //                   context,
// //                   MaterialPageRoute(
// //                     builder: (context) => WordSearchPage(initialLevel: level, gridSize: gridSize),
// //                   ),
// //                 );
// //
// //                 if (result != null && result > currentMaxLevel) {
// //                   Navigator.pushReplacement(
// //                     context,
// //                     MaterialPageRoute(
// //                       builder: (context) => LevelSelectPage(currentMaxLevel: result, gridSize: gridSize),
// //                     ),
// //                   );
// //                 }
// //
// //
// //
// //                 // Navigator.push(
// //                 //   context,
// //                 //   MaterialPageRoute(
// //                 //     builder: (context) => WordSearchPage(initialLevel: level, gridSize: gridSize),
// //                 //   ),
// //                 // );
// //
// //               }
// //                   : null,
// //               child: Container(
// //                 decoration: BoxDecoration(
// //                   color: isUnlocked ? const Color(0xFF7A5821) : Colors.grey.shade400,
// //                   borderRadius: BorderRadius.circular(12),
// //                   boxShadow: [
// //                     if (isUnlocked)
// //                       const BoxShadow(
// //                         color: Colors.black38,
// //                         offset: Offset(2, 2),
// //                         blurRadius: 4,
// //                       ),
// //                   ],
// //                 ),
// //                 child: Center(
// //                   child: Text(
// //                     'L$level',
// //                     style: TextStyle(
// //                       fontSize: 24,
// //                       fontWeight: FontWeight.bold,
// //                       color: isUnlocked ? Colors.white : Colors.black45,
// //                       letterSpacing: 1.2,
// //                     ),
// //                   ),
// //                 ),
// //               ),
// //             );
// //           },
// //         ),
// //       ),
// //     );
// //   }
// // }
//
// // import 'package:flutter/material.dart';
// // import 'package:word_puzzle/view/word_search.dart';
// //
// // class LevelSelectPage extends StatelessWidget {
// //   final int currentMaxLevel;
// //   const LevelSelectPage({super.key, required this.currentMaxLevel});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final levels = List.generate(currentMaxLevel, (i) => i + 1);
// //
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text('Select Level'),
// //         backgroundColor: Color(0xff7a5821),
// //       ),
// //       body: ListView.builder(
// //         itemCount: levels.length,
// //         itemBuilder: (context, index) {
// //           int level = levels[index];
// //           return ListTile(
// //             title: Text('Level $level'),
// //             trailing: const Icon(Icons.arrow_forward_ios),
// //             onTap: () {
// //               Navigator.push(
// //                 context,
// //                 MaterialPageRoute(builder: (context) => WordSearchPage(initialLevel: level)),
// //               );
// //             },
// //           );
// //         },
// //       ),
// //     );
// //   }
// // }
