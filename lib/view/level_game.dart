import 'package:flutter/material.dart';
import '../widget/bg_container.dart'; // Reuse the background

class LevelOneScreen extends StatelessWidget {
  const LevelOneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundContainer(
        child: Column(
          children: [
            const SizedBox(height: 40),

            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text("Level 1"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.edit, color: Colors.white),
                      const SizedBox(width: 4),
                      Text("10", style: TextStyle(color: Colors.white)),
                      const SizedBox(width: 12),
                      Icon(Icons.bolt, color: Colors.yellow),
                      const SizedBox(width: 4),
                      Text("10", style: TextStyle(color: Colors.white)),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Category Title
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.indigo.shade900,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                "OPPOSITES",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 10),

            // Word List
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  Text("WRONG"),
                  Text("DOWN"),
                  Text("UP"),
                  Text("OUT"),
                  Text("IN"),
                  Text("COLD"),
                  Text("HOT"),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Puzzle Grid (simplified 6x6)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: GridView.count(
                    crossAxisCount: 6,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                    children: "WOUTIRXPNDHOWBLOONBROODITGCKTCS"
                        .split('')
                        .map(
                          (letter) => Center(
                        child: Text(
                          letter,
                          style: const TextStyle(
                            fontSize: 22,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                        .toList(),
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Coin Display
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.monetization_on, color: Colors.amber),
                  SizedBox(width: 5),
                  Text("500",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black)),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
