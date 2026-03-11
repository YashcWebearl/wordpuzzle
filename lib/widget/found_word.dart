import 'package:flutter/material.dart';

class WordLinePainter extends CustomPainter {
  final Map<String, List<Offset>> foundWordPaths;
  final List<Offset>? hintedPath;
  final double cellSize;
  final List<Color> colors;
  final double blinkValue;

  WordLinePainter({
    required this.foundWordPaths,
    required this.cellSize,
    required this.colors,
    this.hintedPath,
    this.blinkValue = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw hinted path (Blinking Nature Green)
    if (hintedPath != null && hintedPath!.isNotEmpty) {
      final points = hintedPath!.map((offset) {
        double x = offset.dx * cellSize + cellSize / 2.0;
        double y = offset.dy * cellSize + cellSize / 2.0;
        return Offset(x, y);
      }).toList();

      linePaint.color = Colors.green.withOpacity(blinkValue);
      linePaint.strokeWidth = cellSize * 0.7;

      final pathLine = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        pathLine.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(pathLine, linePaint);
    }

    // Draw found words (Nature Earthy/Sky Colors)
    int colorIndex = 0;
    for (final entry in foundWordPaths.entries) {
      final path = entry.value;
      if (path.isEmpty) continue;

      final points = path.map((offset) {
        double x = offset.dx * cellSize + cellSize / 2.0;
        double y = offset.dy * cellSize + cellSize / 2.0;
        return Offset(x, y);
      }).toList();

      // Use nature colors: Ambers, Greens, Sky Blues
      final natureColors = [
        const Color(0xFF8BC34A).withOpacity(0.6), // Light Green
        const Color(0xFFFFD54F).withOpacity(0.6), // Amber
        const Color(0xFF4FC3F7).withOpacity(0.6), // Sky Blue
        const Color(0xFFAED581).withOpacity(0.6), // Lime Green
        const Color(0xFFFFB74D).withOpacity(0.6), // Orange
      ];

      linePaint.color = natureColors[colorIndex % natureColors.length];
      linePaint.strokeWidth = cellSize * 0.7;
      colorIndex++;

      final pathLine = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        pathLine.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(pathLine, linePaint);
    }
  }

  @override
  bool shouldRepaint(WordLinePainter oldDelegate) {
    return oldDelegate.foundWordPaths != foundWordPaths ||
        oldDelegate.hintedPath != hintedPath ||
        oldDelegate.blinkValue != blinkValue ||
        oldDelegate.cellSize != cellSize;
  }
}
