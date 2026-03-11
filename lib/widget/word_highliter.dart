import 'package:flutter/material.dart';

class DragLinePainter extends CustomPainter {
  final Offset? start;
  final Offset? end;
  final double cellSize;
  final int gridSize;

  DragLinePainter({
    required this.start,
    required this.end,
    required this.cellSize,
    required this.gridSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (start == null || end == null) return;

    final paint = Paint()
      ..color =
          const Color(0xFF8BC34A).withOpacity(0.5) // Nature Green (Translucent)
      ..strokeWidth = cellSize * 0.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Fixed centering by using exact half-cell offset
    final startX = start!.dx * cellSize + cellSize / 2.0;
    final startY = start!.dy * cellSize + cellSize / 2.0;
    final endX = end!.dx * cellSize + cellSize / 2.0;
    final endY = end!.dy * cellSize + cellSize / 2.0;

    canvas.drawLine(
      Offset(startX, startY),
      Offset(endX, endY),
      paint,
    );
  }

  @override
  bool shouldRepaint(DragLinePainter oldDelegate) {
    return oldDelegate.start != start || oldDelegate.end != end;
  }
}
