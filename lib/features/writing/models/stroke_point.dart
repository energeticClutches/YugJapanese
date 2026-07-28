import 'dart:ui';

class StrokePoint {
  const StrokePoint({required this.position, required this.timestamp});

  final Offset position;
  final DateTime timestamp;
}
