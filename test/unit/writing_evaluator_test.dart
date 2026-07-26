import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_learning/features/writing/models/stroke.dart';
import 'package:japanese_learning/features/writing/models/stroke_point.dart';
import 'package:japanese_learning/features/writing/services/writing_evaluator.dart';

Stroke _strokeAcross(Offset from, Offset to) {
  final DateTime now = DateTime(2026, 1, 1);
  return Stroke(
    points: <StrokePoint>[
      StrokePoint(position: from, timestamp: now),
      StrokePoint(position: to, timestamp: now),
    ],
  );
}

void main() {
  group('WritingEvaluator', () {
    const WritingEvaluator evaluator = WritingEvaluator();

    test('empty, incomplete drawing scores at (or near) zero', () {
      final result = evaluator.evaluate(
        strokes: const <Stroke>[],
        expectedStrokeCount: 3,
        expectedBoundingBox: const Rect.fromLTWH(0, 0, 100, 100),
        canvasSize: const Size(200, 200),
        isDrawingCompleted: false,
      );

      expect(result.accuracy, 0);
      expect(result.strokeCountCorrect, isFalse);
      expect(result.completed, isFalse);
      expect(result.feedbackMessage, contains('Keep practicing'));
    });

    test('correct stroke count and matching bounds scores highly', () {
      final result = evaluator.evaluate(
        strokes: <Stroke>[
          _strokeAcross(const Offset(0, 0), const Offset(100, 100)),
        ],
        expectedStrokeCount: 1,
        expectedBoundingBox: const Rect.fromLTWH(0, 0, 100, 100),
        canvasSize: const Size(100, 100),
        isDrawingCompleted: true,
      );

      expect(result.strokeCountCorrect, isTrue);
      expect(result.completed, isTrue);
      expect(result.accuracy, greaterThan(0.5));
      expect(result.feedbackMessage, contains('stroke count is correct'));
    });

    test('accuracy is always clamped between 0 and 1', () {
      final result = evaluator.evaluate(
        strokes: <Stroke>[
          _strokeAcross(const Offset(-500, -500), const Offset(500, 500)),
        ],
        expectedStrokeCount: 1,
        expectedBoundingBox: const Rect.fromLTWH(0, 0, 10, 10),
        canvasSize: const Size(100, 100),
        isDrawingCompleted: true,
      );

      expect(result.accuracy, inInclusiveRange(0, 1));
    });

    test('wrong stroke count is reflected in feedback', () {
      final result = evaluator.evaluate(
        strokes: <Stroke>[
          _strokeAcross(const Offset(0, 0), const Offset(50, 50)),
        ],
        expectedStrokeCount: 5,
        expectedBoundingBox: const Rect.fromLTWH(0, 0, 100, 100),
        canvasSize: const Size(100, 100),
        isDrawingCompleted: true,
      );

      expect(result.strokeCountCorrect, isFalse);
      expect(result.feedbackMessage, contains('matching the stroke count'));
    });
  });
}
