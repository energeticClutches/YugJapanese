import 'dart:math' as math;
import 'dart:ui';

import '../models/stroke.dart';
import '../models/stroke_template.dart';
import '../models/writing_result.dart';

/// Scores a handwritten attempt against the character's reference strokes.
///
/// The comparison is purely geometric and runs offline: both the attempt and
/// the KanjiVG reference polylines are normalized into a common space,
/// resampled to a fixed number of points, and compared point-wise. Shape
/// similarity is the backbone of the score — stroke count, order, direction
/// and proportion can only modulate it, so a drawing that does not resemble
/// the character cannot score well no matter how many strokes it has.
class WritingEvaluator {
  const WritingEvaluator();

  /// Points each stroke is resampled to before comparison.
  static const int _samplesPerStroke = 32;

  /// Normalized point distance at which a stroke scores zero. Normalized
  /// coordinates span roughly [-0.5, 0.5], so 0.35 is "most of the glyph away".
  static const double _maxStrokeDistance = 0.35;

  /// Falloff exponent: keeps near-misses generous and punishes real divergence.
  static const double _distanceExponent = 1.5;

  WritingResult evaluate({
    required List<Stroke> strokes,
    required int expectedStrokeCount,
    required Rect expectedBoundingBox,
    required Size canvasSize,
    required bool isDrawingCompleted,
    List<StrokeTemplate>? referenceStrokes,
  }) {
    final List<List<Offset>> drawn = _denoise(_toPolylines(strokes), canvasSize);

    if (!isDrawingCompleted || drawn.isEmpty) {
      return WritingResult(
        accuracy: 0,
        strokeCountCorrect: false,
        completed: isDrawingCompleted,
        feedbackMessage: _buildFeedback(
          accuracy: 0,
          strokeCountCorrect: false,
          isDrawingCompleted: isDrawingCompleted,
          orderPenalised: false,
          reversedStrokes: 0,
          hasReference: referenceStrokes != null && referenceStrokes.isNotEmpty,
        ),
      );
    }

    final bool strokeCountCorrect = drawn.length == expectedStrokeCount;
    final List<List<Offset>>? reference = referenceStrokes == null
        ? null
        : <List<Offset>>[
            for (final StrokeTemplate t in referenceStrokes)
              if (t.points.length >= 2) t.points,
          ];

    if (reference == null || reference.isEmpty) {
      // No reference geometry for this character: shape cannot be verified, so
      // fall back to the coarse bounding-box heuristic and cap it well below
      // full marks rather than claiming an accuracy we have not measured.
      final double fallback = _fallbackScore(
        drawn: drawn,
        expectedStrokeCount: expectedStrokeCount,
        expectedBoundingBox: expectedBoundingBox,
        canvasSize: canvasSize,
      );
      return WritingResult(
        accuracy: fallback,
        strokeCountCorrect: strokeCountCorrect,
        completed: isDrawingCompleted,
        feedbackMessage: _buildFeedback(
          accuracy: fallback,
          strokeCountCorrect: strokeCountCorrect,
          isDrawingCompleted: isDrawingCompleted,
          orderPenalised: false,
          reversedStrokes: 0,
          hasReference: false,
        ),
      );
    }

    final List<List<Offset>> userNorm = _normalize(drawn);
    final List<List<Offset>> refNorm = _normalize(reference);

    final _ShapeMatch match = _matchShapes(userNorm, refNorm);

    final double countScore = _strokeCountScore(
      drawn.length,
      reference.length,
    );
    final double proportionScore = _proportionScore(userNorm, refNorm);
    final double directionFactor =
        match.matched == 0 ? 1 : 1 - (0.15 * match.reversed / match.matched);

    // Shape is the backbone; the rest can only scale it down.
    double accuracy = match.score;
    accuracy *= _lerp(0.55, 1, countScore);
    accuracy *= directionFactor;
    accuracy *= _lerp(0.85, 1, proportionScore);

    final double clamped = _clamp01(accuracy);

    return WritingResult(
      accuracy: clamped,
      strokeCountCorrect: strokeCountCorrect,
      completed: isDrawingCompleted,
      feedbackMessage: _buildFeedback(
        accuracy: clamped,
        strokeCountCorrect: strokeCountCorrect,
        isDrawingCompleted: isDrawingCompleted,
        orderPenalised: match.orderPenalised,
        reversedStrokes: match.reversed,
        hasReference: true,
      ),
    );
  }

  // --- geometry -------------------------------------------------------------

  List<List<Offset>> _toPolylines(List<Stroke> strokes) {
    return <List<Offset>>[
      for (final Stroke s in strokes)
        if (s.points.isNotEmpty)
          <Offset>[for (final point in s.points) point.position],
    ];
  }

  /// Drops accidental taps and stray flecks so they are not scored as strokes.
  List<List<Offset>> _denoise(List<List<Offset>> strokes, Size canvasSize) {
    if (strokes.isEmpty) {
      return strokes;
    }
    final Rect bounds = _boundsOf(strokes);
    final double reference = bounds.isEmpty
        ? canvasSize.shortestSide
        : math.sqrt(bounds.width * bounds.width + bounds.height * bounds.height);
    final double minLength = math.max(6, reference * 0.03);
    final List<List<Offset>> kept = <List<Offset>>[
      for (final List<Offset> s in strokes)
        if (_arcLength(s) >= minLength) s,
    ];
    // If every stroke looks like noise the drawing really is just taps; keep
    // them so the attempt scores badly rather than being treated as empty.
    return kept.isEmpty ? strokes : kept;
  }

  double _arcLength(List<Offset> points) {
    double total = 0;
    for (int i = 1; i < points.length; i++) {
      total += (points[i] - points[i - 1]).distance;
    }
    return total;
  }

  Rect _boundsOf(List<List<Offset>> strokes) {
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = -double.infinity;
    double maxY = -double.infinity;
    for (final List<Offset> s in strokes) {
      for (final Offset p in s) {
        minX = math.min(minX, p.dx);
        minY = math.min(minY, p.dy);
        maxX = math.max(maxX, p.dx);
        maxY = math.max(maxY, p.dy);
      }
    }
    if (!minX.isFinite || maxX < minX || maxY < minY) {
      return Rect.zero;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// Centres the drawing and scales it uniformly by its longest side.
  ///
  /// Uniform (rather than per-axis) scaling is deliberate: stretching each axis
  /// to fill a square would make a flat scribble look like a square glyph.
  List<List<Offset>> _normalize(List<List<Offset>> strokes) {
    final Rect bounds = _boundsOf(strokes);
    final double scale = math.max(bounds.width, bounds.height);
    if (scale <= 0) {
      return <List<Offset>>[
        for (final List<Offset> s in strokes) <Offset>[for (final _ in s) Offset.zero],
      ];
    }
    final Offset centre = bounds.center;
    return <List<Offset>>[
      for (final List<Offset> s in strokes)
        <Offset>[for (final Offset p in s) (p - centre) / scale],
    ];
  }

  /// Resamples a polyline to [count] points spaced evenly along its length.
  List<Offset> _resample(List<Offset> points, int count) {
    if (points.length == 1) {
      return List<Offset>.filled(count, points.first);
    }
    final double total = _arcLength(points);
    if (total <= 0) {
      return List<Offset>.filled(count, points.first);
    }

    final double step = total / (count - 1);
    final List<Offset> out = <Offset>[points.first];
    double travelled = 0;
    int segment = 1;
    Offset cursor = points.first;

    while (out.length < count && segment < points.length) {
      final Offset next = points[segment];
      final double segmentLength = (next - cursor).distance;
      if (segmentLength <= 0) {
        segment++;
        cursor = next;
        continue;
      }
      if (travelled + segmentLength >= step) {
        final double t = (step - travelled) / segmentLength;
        cursor = Offset(
          cursor.dx + (next.dx - cursor.dx) * t,
          cursor.dy + (next.dy - cursor.dy) * t,
        );
        out.add(cursor);
        travelled = 0;
      } else {
        travelled += segmentLength;
        cursor = next;
        segment++;
      }
    }
    while (out.length < count) {
      out.add(points.last);
    }
    return out;
  }

  double _meanDistance(List<Offset> a, List<Offset> b) {
    double total = 0;
    for (int i = 0; i < a.length; i++) {
      total += (a[i] - b[i]).distance;
    }
    return total / a.length;
  }

  /// Similarity of one stroke to one reference stroke, best of both directions.
  _StrokeMatch _compareStroke(List<Offset> user, List<Offset> reference) {
    final List<Offset> u = _resample(user, _samplesPerStroke);
    final List<Offset> r = _resample(reference, _samplesPerStroke);
    final double forward = _meanDistance(u, r);
    final double backward = _meanDistance(u, r.reversed.toList(growable: false));
    final bool reversed = backward < forward;
    final double best = math.min(forward, backward);
    final double normalized = (best / _maxStrokeDistance).clamp(0, 1).toDouble();
    final double score =
        _clamp01(1 - math.pow(normalized, _distanceExponent).toDouble());
    return _StrokeMatch(score: score, reversed: reversed);
  }

  /// Scores the attempt in written order, then checks whether the same shapes
  /// would have matched better in a different order (right shapes, wrong order)
  /// and awards partial credit for that instead of zero.
  _ShapeMatch _matchShapes(
    List<List<Offset>> user,
    List<List<Offset>> reference,
  ) {
    final int slots = math.max(user.length, reference.length);
    final int pairs = math.min(user.length, reference.length);
    if (slots == 0) {
      return const _ShapeMatch(score: 0, reversed: 0, matched: 0, orderPenalised: false);
    }

    double orderedTotal = 0;
    int reversedCount = 0;
    for (int i = 0; i < pairs; i++) {
      final _StrokeMatch m = _compareStroke(user[i], reference[i]);
      orderedTotal += m.score;
      if (m.reversed) {
        reversedCount++;
      }
    }
    // Unmatched reference strokes (missing) and extra user strokes both
    // dilute the average, so either direction costs marks.
    final double ordered = orderedTotal / slots;

    // Greedy best-match ignoring order.
    final List<bool> taken = List<bool>.filled(reference.length, false);
    double unorderedTotal = 0;
    for (int i = 0; i < user.length; i++) {
      double best = 0;
      int bestIndex = -1;
      for (int j = 0; j < reference.length; j++) {
        if (taken[j]) {
          continue;
        }
        final double s = _compareStroke(user[i], reference[j]).score;
        if (s > best) {
          best = s;
          bestIndex = j;
        }
      }
      if (bestIndex >= 0) {
        taken[bestIndex] = true;
        unorderedTotal += best;
      }
    }
    final double unordered = unorderedTotal / slots;

    // Correct order => the two agree and nothing is deducted. Wrong order =>
    // only part of the gap is credited, so order still matters.
    final bool orderPenalised = unordered > ordered + 0.05;
    final double score =
        orderPenalised ? ordered + (unordered - ordered) * 0.6 : ordered;

    return _ShapeMatch(
      score: _clamp01(score),
      reversed: reversedCount,
      matched: pairs,
      orderPenalised: orderPenalised,
    );
  }

  double _strokeCountScore(int actual, int expected) {
    if (expected <= 0) {
      return 0;
    }
    return _clamp01(1 - ((actual - expected).abs() / expected));
  }

  /// How closely the overall glyph proportions match (aspect ratio).
  double _proportionScore(
    List<List<Offset>> user,
    List<List<Offset>> reference,
  ) {
    final Rect u = _boundsOf(user);
    final Rect r = _boundsOf(reference);
    if (u.isEmpty || r.isEmpty) {
      return 0;
    }
    final double userAspect = u.width / math.max(u.height, 1e-6);
    final double refAspect = r.width / math.max(r.height, 1e-6);
    final double ratio = userAspect / math.max(refAspect, 1e-6);
    // 1.0 is a perfect match; score falls off either side symmetrically.
    final double deviation = (math.log(ratio.clamp(1e-6, 1e6)) / math.ln2).abs();
    return _clamp01(1 - deviation / 2);
  }

  /// Coarse pre-existing heuristic, kept only for characters with no reference
  /// geometry and capped so it cannot report a confident high score.
  double _fallbackScore({
    required List<List<Offset>> drawn,
    required int expectedStrokeCount,
    required Rect expectedBoundingBox,
    required Size canvasSize,
  }) {
    final Rect bounds = _boundsOf(drawn);
    final double countScore =
        _strokeCountScore(drawn.length, expectedStrokeCount);
    final double coverage = _coverage(bounds, canvasSize);
    final double boxSimilarity =
        _boundingBoxSimilarity(bounds, expectedBoundingBox);
    return _clamp01(
      ((countScore * 0.4) + (boxSimilarity * 0.35) + (coverage * 0.25)) * 0.6,
    );
  }

  double _coverage(Rect bounds, Size canvasSize) {
    if (bounds.isEmpty || canvasSize.isEmpty) {
      return 0;
    }
    final double canvasArea = canvasSize.width * canvasSize.height;
    if (canvasArea <= 0) {
      return 0;
    }
    return _clamp01(bounds.width * bounds.height / canvasArea * 4);
  }

  double _boundingBoxSimilarity(Rect actual, Rect expected) {
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

  // --- feedback -------------------------------------------------------------

  String _buildFeedback({
    required double accuracy,
    required bool strokeCountCorrect,
    required bool isDrawingCompleted,
    required bool orderPenalised,
    required int reversedStrokes,
    required bool hasReference,
  }) {
    final List<String> lines = <String>[];

    if (accuracy >= 0.9) {
      lines.add('Excellent match!');
    } else if (accuracy >= 0.75) {
      lines.add('Great job!');
    } else if (accuracy >= 0.5) {
      lines.add('Nice work.');
    } else if (accuracy >= 0.2) {
      lines.add('Keep practicing.');
    } else {
      lines.add("Keep practicing. That doesn't look like the character yet.");
    }

    if (strokeCountCorrect) {
      lines.add('Your stroke count is correct.');
    } else {
      lines.add('Try matching the stroke count more closely.');
    }

    if (orderPenalised) {
      lines.add('Check the stroke order.');
    }
    if (reversedStrokes > 0) {
      lines.add(
        reversedStrokes == 1
            ? 'One stroke was drawn in the wrong direction.'
            : '$reversedStrokes strokes were drawn in the wrong direction.',
      );
    }
    if (!hasReference) {
      lines.add('Stroke guides are unavailable for this character.');
    }
    if (!isDrawingCompleted) {
      lines.add('Finish the character before submitting.');
    }

    return lines.join(' ');
  }

  double _lerp(double a, double b, double t) => a + (b - a) * _clamp01(t);

  double _clamp01(double value) {
    if (value.isNaN) {
      return 0;
    }
    return value.clamp(0, 1).toDouble();
  }
}

class _StrokeMatch {
  const _StrokeMatch({required this.score, required this.reversed});

  final double score;
  final bool reversed;
}

class _ShapeMatch {
  const _ShapeMatch({
    required this.score,
    required this.reversed,
    required this.matched,
    required this.orderPenalised,
  });

  final double score;
  final int reversed;
  final int matched;
  final bool orderPenalised;
}
