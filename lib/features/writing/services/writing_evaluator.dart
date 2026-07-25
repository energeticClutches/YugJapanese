import 'dart:math' as math;
import 'dart:ui';

import '../models/stroke.dart';
import '../models/writing_result.dart';

class WritingEvaluator {
  const WritingEvaluator();

  WritingResult evaluate({
    required List<Stroke> strokes,
    required int expectedStrokeCount,
    required Rect expectedBoundingBox,
    required Size canvasSize,
    required bool isDrawingCompleted,
  }) {
    final bool strokeCountCorrect = strokes.length == expectedStrokeCount;
    final Rect drawnBounds = _calculateBounds(strokes);
    final double coverage = _calculateCoverage(drawnBounds, canvasSize);
    final double boxSimilarity =
        _calculateBoundingBoxSimilarity(drawnBounds, expectedBoundingBox);
    final double strokeScore = expectedStrokeCount == 0
        ? 0
        : 1 - ((strokes.length - expectedStrokeCount).abs() / expectedStrokeCount);

    final double accuracy = _clamp01(
      (strokeScore * 0.35) +
          (isDrawingCompleted ? 0.15 : 0.0) +
          (coverage * 0.25) +
          (boxSimilarity * 0.25),
    );

    return WritingResult(
      accuracy: accuracy,
      strokeCountCorrect: strokeCountCorrect,
      completed: isDrawingCompleted,
      feedbackMessage: _buildFeedback(
        accuracy: accuracy,
        strokeCountCorrect: strokeCountCorrect,
        isDrawingCompleted: isDrawingCompleted,
      ),
    );
  }

  Rect _calculateBounds(List<Stroke> strokes) {
    if (strokes.isEmpty) {
      return Rect.zero;
    }

    double? minX;
    double? minY;
    double? maxX;
    double? maxY;

    for (final stroke in strokes) {
      for (final point in stroke.points) {
        minX = minX == null ? point.position.dx : math.min(minX, point.position.dx);
        minY = minY == null ? point.position.dy : math.min(minY, point.position.dy);
        maxX = maxX == null ? point.position.dx : math.max(maxX, point.position.dx);
        maxY = maxY == null ? point.position.dy : math.max(maxY, point.position.dy);
      }
    }

    if (minX == null || minY == null || maxX == null || maxY == null) {
      return Rect.zero;
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  double _calculateCoverage(Rect bounds, Size canvasSize) {
    if (bounds.isEmpty || canvasSize.isEmpty) {
      return 0;
    }

    final double canvasArea = canvasSize.width * canvasSize.height;
    if (canvasArea <= 0) {
      return 0;
    }

    final double area = bounds.width * bounds.height;
    return _clamp01(area / canvasArea * 8);
  }

  double _calculateBoundingBoxSimilarity(Rect actual, Rect expected) {
    if (actual.isEmpty || expected.isEmpty) {
      return 0;
    }

    final double widthDelta =
        (actual.width - expected.width).abs() / math.max(expected.width, 1);
    final double heightDelta =
        (actual.height - expected.height).abs() / math.max(expected.height, 1);
    final double offsetDelta = ((actual.left - expected.left).abs() +
            (actual.top - expected.top).abs()) /
        math.max(expected.width + expected.height, 1);

    return _clamp01(1 - ((widthDelta + heightDelta + offsetDelta) / 3));
  }

  String _buildFeedback({
    required double accuracy,
    required bool strokeCountCorrect,
    required bool isDrawingCompleted,
  }) {
    final List<String> lines = <String>[];

    if (accuracy >= 0.8) {
      lines.add('Great job!');
    } else if (accuracy >= 0.6) {
      lines.add('Nice work.');
    } else {
      lines.add('Keep practicing.');
    }

    if (strokeCountCorrect) {
      lines.add('Your stroke count is correct.');
    } else {
      lines.add('Try matching the stroke count more closely.');
    }

    if (!isDrawingCompleted) {
      lines.add('Finish the character before submitting.');
    }

    return lines.join(' ');
  }

  double _clamp01(double value) {
    return value.clamp(0, 1).toDouble();
  }
}
