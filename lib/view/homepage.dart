import 'package:flutter/material.dart';
import 'difficultyselect.dart';
import 'levelselect.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDAAB5C), // Primary color
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/icon/logo.png',
                width: 180,
              ),
              const SizedBox(height: 60),
              Text(
                'Word Puzzle',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF7A5821),
                  fontFamily: 'Georgia', // Use a serif font for word-game feel
                ),
              ),
              const SizedBox(height: 120),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  backgroundColor: const Color(0xFF7A5821),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                ),
                onPressed: () {
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => const LevelSelectPage(currentMaxLevel: 3),
                  //   ),
                  // );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DifficultySelectPage(),
                      ),
                    );
                },
                child: const Text(
                  'Start Game',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
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
