import 'package:flutter/material.dart';

class WordLinePainter extends CustomPainter {
  final Map<String, List<Offset>> foundWordPaths;
  final List<String>? wordsList;
  final List<Offset>? hintedPath;
  final double cellSize;
  final List<Color> colors;
  final double blinkValue;

  WordLinePainter({
    required this.foundWordPaths,
    this.wordsList,
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

      linePaint.color = Colors.green.withValues(alpha: blinkValue.clamp(0.0, 1.0));
      linePaint.strokeWidth = cellSize * 0.78;

      final pathLine = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        pathLine.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(pathLine, linePaint);
    }

    // Draw found words
    int colorIndex = 0;
    for (final entry in foundWordPaths.entries) {
      final path = entry.value;
      if (path.isEmpty) continue;

      final points = path.map((offset) {
        double x = offset.dx * cellSize + cellSize / 2.0;
        double y = offset.dy * cellSize + cellSize / 2.0;
        return Offset(x, y);
      }).toList();

      final word = entry.key;
      final wordIdx = wordsList != null ? wordsList!.indexOf(word) : colorIndex;
      final baseColor = (colors.isNotEmpty)
          ? colors[(wordIdx >= 0 ? wordIdx : colorIndex) % colors.length]
          : const Color(0xFF8BC34A);

      linePaint.color = baseColor.withValues(alpha: 0.58);
      linePaint.strokeWidth = cellSize * 0.78;
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
        oldDelegate.cellSize != cellSize ||
        oldDelegate.wordsList != wordsList;
  }
}
