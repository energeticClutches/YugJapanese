import '../models/review_item.dart';
import '../repositories/review_repository.dart';

/// Fixed-interval spaced repetition scheduler.
///
/// Intentionally simple (not SM-2): each successful review advances the
/// lesson to the next fixed interval below. Replace this class with a more
/// adaptive algorithm later without touching [ReviewRepository] or its
/// callers.
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

  Future<List<ReviewItem>> getDueReviews({DateTime? now}) async {
    final DateTime currentTime = now ?? DateTime.now();
    final List<ReviewItem> allReviews = await _repository.getAllReviews();
    final List<ReviewItem> due = allReviews
        .where((ReviewItem item) => item.isDue(currentTime))
        .toList()
      ..sort(
        (ReviewItem a, ReviewItem b) => a.nextReview.compareTo(b.nextReview),
      );
    return due;
  }

  /// Creates the first review schedule for a lesson, if one doesn't already
  /// exist. Safe to call every time a lesson is completed normally.
  Future<ReviewItem> scheduleInitialReview(String lessonId, {DateTime? now}) async {
    final ReviewItem? existing = await _repository.getReview(lessonId);
    if (existing != null) {
      return existing;
    }

    final DateTime currentTime = now ?? DateTime.now();
    final int firstIntervalDays = intervalProgressionDays.first;
    final ReviewItem item = ReviewItem(
      lessonId: lessonId,
      nextReview: currentTime.add(Duration(days: firstIntervalDays)),
      lastReviewed: currentTime,
      reviewCount: 0,
      easeFactor: _defaultEaseFactor,
      intervalDays: firstIntervalDays,
    );
    await _repository.saveReview(item);
    return item;
  }

  /// Advances a lesson to the next interval after a completed review.
  Future<ReviewItem> recordSuccessfulReview(String lessonId, {DateTime? now}) async {
    final DateTime currentTime = now ?? DateTime.now();
    final ReviewItem? existing = await _repository.getReview(lessonId);

    final int currentIndex = existing == null
        ? -1
        : intervalProgressionDays.indexOf(existing.intervalDays);
    final int nextIndex =
        (currentIndex + 1).clamp(0, intervalProgressionDays.length - 1);
    final int nextIntervalDays = intervalProgressionDays[nextIndex];

    final ReviewItem updated = ReviewItem(
      lessonId: lessonId,
      nextReview: currentTime.add(Duration(days: nextIntervalDays)),
      lastReviewed: currentTime,
      reviewCount: (existing?.reviewCount ?? 0) + 1,
      easeFactor: existing?.easeFactor ?? _defaultEaseFactor,
      intervalDays: nextIntervalDays,
    );
    await _repository.saveReview(updated);
    return updated;
  }
}
