import 'package:flutter/material.dart';
import 'levelselect.dart';

class DifficultySelectPage extends StatelessWidget {
  const DifficultySelectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDAAB5C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7A5821),
        title: const Text(
          'Select Difficulty',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        leading: BackButton(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              DifficultyButton(title: "Easy", gridSize: 6),
              const SizedBox(height: 20),
              DifficultyButton(title: "Medium", gridSize: 8),
              const SizedBox(height: 20),
              DifficultyButton(title: "Hard", gridSize: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class DifficultyButton extends StatefulWidget {
  final String title;
  final int gridSize;

  const DifficultyButton({super.key, required this.title, required this.gridSize});

  @override
  State<DifficultyButton> createState() => _DifficultyButtonState();
}

class _DifficultyButtonState extends State<DifficultyButton> {

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
        backgroundColor: const Color(0xFF7A5821),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 6,
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LevelSelectPage( gridSize: widget.gridSize),
          ),
        );
      },
      child: Text(
        widget.title,
        style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
