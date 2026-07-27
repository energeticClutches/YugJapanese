import 'dart:math' as math;

import '../models/review_item.dart';
import '../repositories/review_repository.dart';

/// Spaced repetition scheduler over a fixed interval ladder, modulated by a
/// per-lesson ease factor.
///
/// The ladder gives the coarse schedule; [ReviewItem.easeFactor] stretches or
/// compresses it so a lesson the learner keeps getting wrong comes back sooner
/// than a lesson at the same ladder step that they answer cleanly. Weak
/// reviews step back down the ladder rather than resetting to the start, so a
/// single bad day does not undo weeks of progress.
class ReviewScheduler {
  const ReviewScheduler(this._repository);

  final ReviewRepository _repository;

  static const List<int> intervalProgressionDays = <int>[
    1,
    3,
    7,
    14,
    30,
    60,
    90,
  ];

  static const double _defaultEaseFactor = 2.5;
  static const double _minEaseFactor = 1.3;
  static const double _maxEaseFactor = 2.8;

  /// Accuracy at or above which a review counts as recalled.
  static const double passThreshold = 0.6;

  /// Accuracy at or above which recall was comfortable enough to earn ease.
  static const double strongThreshold = 0.85;

  Future<List<ReviewItem>> getDueReviews({DateTime? now}) async {
    final DateTime currentTime = now ?? DateTime.now();
    final List<ReviewItem> due = (await _repository.getAllReviews())
        .where((ReviewItem item) => item.isDue(currentTime))
        .toList()
      ..sort((ReviewItem a, ReviewItem b) {
        // Weakest material first, so a short session spends its time where
        // recall is most fragile rather than on whatever happened to fall due
        // earliest.
        final int byPriority = _priority(b, currentTime)
            .compareTo(_priority(a, currentTime));
        if (byPriority != 0) {
          return byPriority;
        }
        return a.nextReview.compareTo(b.nextReview);
      });
    return due;
  }

  /// How badly a due item needs attention. Higher sorts first.
  ///
  /// Combines how long it has been waiting with how much trouble it has
  /// caused before, so a lesson failed three times outranks one that merely
  /// came due a little earlier.
  double _priority(ReviewItem item, DateTime now) {
    final int overdueDays =
        now.difference(item.nextReview).inDays.clamp(0, 60).toInt();
    // Ease runs [1.3, 2.8]; invert so difficult lessons score higher.
    final double difficulty =
        (_maxEaseFactor - item.easeFactor) / (_maxEaseFactor - _minEaseFactor);
    return (overdueDays / 60) + (difficulty * 2) + (item.lapses * 0.5);
  }

  /// Creates the first review schedule for a lesson, if one doesn't already
  /// exist. Safe to call every time a lesson is completed normally.
  ///
  /// [accuracy] is the learner's score on the lesson just finished. A shaky
  /// first pass is scheduled sooner and starts with a lower ease, so weak
  /// lessons enter the rotation already marked as needing work.
  Future<ReviewItem> scheduleInitialReview(
    String lessonId, {
    DateTime? now,
    double? accuracy,
  }) async {
    final ReviewItem? existing = await _repository.getReview(lessonId);
    if (existing != null) {
      return existing;
    }

    final DateTime currentTime = now ?? DateTime.now();
    final double ease = accuracy == null
        ? _defaultEaseFactor
        : _clampEase(_defaultEaseFactor + _easeDelta(accuracy));
    final int firstIntervalDays = intervalProgressionDays.first;
    final ReviewItem item = ReviewItem(
      lessonId: lessonId,
      nextReview: currentTime.add(Duration(days: firstIntervalDays)),
      lastReviewed: currentTime,
      reviewCount: 0,
      easeFactor: ease,
      intervalDays: firstIntervalDays,
    );
    await _repository.saveReview(item);
    return item;
  }

  /// Records a completed review and reschedules from its [accuracy].
  ///
  /// Scores at or above [passThreshold] advance the ladder; weaker ones step
  /// it back and count a lapse.
  Future<ReviewItem> recordReview(
    String lessonId, {
    required double accuracy,
    DateTime? now,
  }) {
    return accuracy >= passThreshold
        ? recordSuccessfulReview(lessonId, now: now, accuracy: accuracy)
        : recordFailedReview(lessonId, now: now, accuracy: accuracy);
  }

  /// Advances a lesson to the next interval after a completed review.
  Future<ReviewItem> recordSuccessfulReview(
    String lessonId, {
    DateTime? now,
    double? accuracy,
  }) async {
    final DateTime currentTime = now ?? DateTime.now();
    final ReviewItem? existing = await _repository.getReview(lessonId);

    final int currentIndex = existing == null
        ? -1
        : intervalProgressionDays.indexOf(existing.intervalDays);
    final int nextIndex =
        (currentIndex + 1).clamp(0, intervalProgressionDays.length - 1);
    final int nextIntervalDays = intervalProgressionDays[nextIndex];

    final double ease = _clampEase(
      (existing?.easeFactor ?? _defaultEaseFactor) +
          (accuracy == null ? 0 : _easeDelta(accuracy)),
    );

    final ReviewItem updated = ReviewItem(
      lessonId: lessonId,
      nextReview: currentTime.add(
        Duration(days: _scaledInterval(nextIntervalDays, ease)),
      ),
      lastReviewed: currentTime,
      reviewCount: (existing?.reviewCount ?? 0) + 1,
      easeFactor: ease,
      intervalDays: nextIntervalDays,
      lapses: existing?.lapses ?? 0,
    );
    await _repository.saveReview(updated);
    return updated;
  }

  /// Steps a lesson back down the ladder after a weak review.
  Future<ReviewItem> recordFailedReview(
    String lessonId, {
    DateTime? now,
    double? accuracy,
  }) async {
    final DateTime currentTime = now ?? DateTime.now();
    final ReviewItem? existing = await _repository.getReview(lessonId);

    final int currentIndex = existing == null
        ? 0
        : intervalProgressionDays.indexOf(existing.intervalDays);
    // Drop back one rung rather than all the way to the start: the learner
    // still saw this material, they just need it again sooner.
    final int nextIndex =
        (currentIndex - 1).clamp(0, intervalProgressionDays.length - 1);
    final int nextIntervalDays = intervalProgressionDays[nextIndex];

    final double ease = _clampEase(
      (existing?.easeFactor ?? _defaultEaseFactor) +
          (accuracy == null ? -0.20 : _easeDelta(accuracy)),
    );

    final ReviewItem updated = ReviewItem(
      lessonId: lessonId,
      nextReview: currentTime.add(
        Duration(days: _scaledInterval(nextIntervalDays, ease)),
      ),
      lastReviewed: currentTime,
      reviewCount: (existing?.reviewCount ?? 0) + 1,
      easeFactor: ease,
      intervalDays: nextIntervalDays,
      lapses: (existing?.lapses ?? 0) + 1,
    );
    await _repository.saveReview(updated);
    return updated;
  }

  /// Ease earned (or lost) by a review at [accuracy].
  ///
  /// Comfortable recall widens the gap to the next review; a bare pass leaves
  /// it alone; a miss narrows it.
  double _easeDelta(double accuracy) {
    if (accuracy >= strongThreshold) {
      return 0.10;
    }
    if (accuracy >= passThreshold) {
      return 0;
    }
    // Scales with how far short the attempt fell.
    return -0.20 - (0.30 * ((passThreshold - accuracy) / passThreshold));
  }

  /// Applies ease to a ladder interval, keeping at least one day.
  int _scaledInterval(int ladderDays, double ease) {
    final double scaled = ladderDays * (ease / _defaultEaseFactor);
    return math.max(1, scaled.round());
  }

  double _clampEase(double value) =>
      value.clamp(_minEaseFactor, _maxEaseFactor).toDouble();
}
