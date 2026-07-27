import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

import '../models/stroke.dart';
import '../models/stroke_point.dart';
import '../models/stroke_template.dart';

/// Paints the writing surface: optional guide grid, optional reference
/// stroke guide, and the strokes the user has drawn.
///
/// [guideProgress] drives the stroke-order animation. It counts strokes in
/// fractional units — e.g. 2.5 means strokes 1 and 2 are fully drawn and
/// stroke 3 is half drawn — so a single animating double can render an
/// ordered stroke-by-stroke reveal.
class WritingCanvasPainter extends CustomPainter {
  const WritingCanvasPainter({
    required this.strokes,
    required this.activeStroke,
    required this.showGrid,
    required this.guideStrokes,
    required this.guideProgress,
    required this.inkColor,
    required this.gridColor,
    required this.guideColor,
  });

  /// Strokes the user has completed.
  final List<Stroke> strokes;

  /// The stroke currently under the finger, if any.
  final Stroke? activeStroke;

  final bool showGrid;

  /// Reference strokes to trace, or `null` to draw no guide.
  final List<StrokeTemplate>? guideStrokes;

  /// How much of the guide to reveal, in fractional stroke units. When
  /// this is at or above the stroke count the whole character shows.
  final double guideProgress;

  final Color inkColor;
  final Color gridColor;
  final Color guideColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (showGrid) {
      _paintGrid(canvas, size);
    }
    final List<StrokeTemplate>? guide = guideStrokes;
    if (guide != null && guide.isNotEmpty) {
      _paintGuide(canvas, size, guide);
    }
    _paintUserStrokes(canvas, size);
  }

  void _paintGrid(Canvas canvas, Size size) {
    final Paint border = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRect(Offset.zero & size, border);

    // Standard practice-sheet guides: centre cross, dashed.
    final Paint inner = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    _dashedLine(
      canvas,
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      inner,
    );
    _dashedLine(
      canvas,
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      inner,
    );
  }

  void _dashedLine(Canvas canvas, Offset from, Offset to, Paint paint) {
    const double dash = 6;
    const double gap = 6;
    final double totalLength = (to - from).distance;
    if (totalLength <= 0) {
      return;
    }
    final Offset unit = (to - from) / totalLength;
    double drawn = 0;
    while (drawn < totalLength) {
      final double end = (drawn + dash).clamp(0, totalLength).toDouble();
      canvas.drawLine(from + unit * drawn, from + unit * end, paint);
      drawn = end + gap;
    }
  }

  void _paintGuide(Canvas canvas, Size size, List<StrokeTemplate> guide) {
    final Paint paint = Paint()
      ..color = guideColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.075
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (int i = 0; i < guide.length; i++) {
      final double remaining = guideProgress - i;
      if (remaining <= 0) {
        break;
      }
      final List<Offset> points = guide[i].scaledTo(size);
      if (points.length < 2) {
        continue;
      }
      // A fully-revealed stroke draws whole; the in-progress one is
      // truncated proportionally so the reveal follows writing direction.
      final double fraction = remaining >= 1 ? 1.0 : remaining;
      canvas.drawPath(_partialPath(points, fraction), paint);
    }
  }

  /// Builds a path covering [fraction] (0–1) of the polyline's length,
  /// interpolating within the segment where the cut falls.
  Path _partialPath(List<Offset> points, double fraction) {
    final Path path = Path()..moveTo(points.first.dx, points.first.dy);
    if (fraction >= 1) {
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      return path;
    }

    double total = 0;
    for (int i = 1; i < points.length; i++) {
      total += (points[i] - points[i - 1]).distance;
    }
    if (total <= 0) {
      return path;
    }

    double target = total * fraction;
    for (int i = 1; i < points.length; i++) {
      final double seg = (points[i] - points[i - 1]).distance;
      if (seg <= 0) {
        continue;
      }
      if (seg >= target) {
        final Offset cut =
            Offset.lerp(points[i - 1], points[i], target / seg)!;
        path.lineTo(cut.dx, cut.dy);
        return path;
      }
      path.lineTo(points[i].dx, points[i].dy);
      target -= seg;
    }
    return path;
  }

  void _paintUserStrokes(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = inkColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.05
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final Stroke stroke in strokes) {
      _paintStroke(canvas, stroke, paint);
    }
    final Stroke? active = activeStroke;
    if (active != null) {
      _paintStroke(canvas, active, paint);
    }
  }

  void _paintStroke(Canvas canvas, Stroke stroke, Paint paint) {
    final List<StrokePoint> points = stroke.points;
    if (points.isEmpty) {
      return;
    }
    if (points.length == 1) {
      // A tap with no movement still leaves a mark.
      canvas.drawPoints(
        PointMode.points,
        <Offset>[points.first.position],
        paint,
      );
      return;
    }
    final Path path = Path()
      ..moveTo(points.first.position.dx, points.first.position.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].position.dx, points[i].position.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WritingCanvasPainter old) {
    return old.strokes != strokes ||
        old.activeStroke != activeStroke ||
        old.showGrid != showGrid ||
        old.guideStrokes != guideStrokes ||
        old.guideProgress != guideProgress ||
        old.inkColor != inkColor ||
        old.gridColor != gridColor ||
        old.guideColor != guideColor;
  }
}
