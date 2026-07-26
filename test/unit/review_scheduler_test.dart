import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_learning/features/review/models/review_item.dart';
import 'package:japanese_learning/features/review/services/review_scheduler.dart';

import '../fakes/fake_review_repository.dart';

void main() {
  group('ReviewScheduler', () {
    late FakeReviewRepository repository;
    late ReviewScheduler scheduler;
    final DateTime now = DateTime(2026, 1, 1);

    setUp(() {
      repository = FakeReviewRepository();
      scheduler = ReviewScheduler(repository);
    });

    test('scheduleInitialReview creates the first interval', () async {
      final ReviewItem item =
          await scheduler.scheduleInitialReview('hiragana:1', now: now);

      expect(item.intervalDays, ReviewScheduler.intervalProgressionDays.first);
      expect(item.reviewCount, 0);
      expect(item.nextReview, now.add(const Duration(days: 1)));
    });

    test('scheduleInitialReview is a no-op if a schedule already exists', () async {
      final ReviewItem first =
          await scheduler.scheduleInitialReview('hiragana:1', now: now);
      final ReviewItem second = await scheduler.scheduleInitialReview(
        'hiragana:1',
        now: now.add(const Duration(days: 5)),
      );

      expect(second.nextReview, first.nextReview);
      expect(second.reviewCount, first.reviewCount);
    });

    test('recordSuccessfulReview advances through the interval progression', () async {
      await scheduler.scheduleInitialReview('hiragana:1', now: now);

      ReviewItem updated =
          await scheduler.recordSuccessfulReview('hiragana:1', now: now);
      expect(updated.intervalDays, ReviewScheduler.intervalProgressionDays[1]);
      expect(updated.reviewCount, 1);

      updated = await scheduler.recordSuccessfulReview('hiragana:1', now: now);
      expect(updated.intervalDays, ReviewScheduler.intervalProgressionDays[2]);
      expect(updated.reviewCount, 2);
    });

    test('recordSuccessfulReview never advances past the final interval', () async {
      const String lessonId = 'hiragana:1';
      await scheduler.scheduleInitialReview(lessonId, now: now);

      for (int i = 0; i < ReviewScheduler.intervalProgressionDays.length + 3; i++) {
        await scheduler.recordSuccessfulReview(lessonId, now: now);
      }

      final ReviewItem? finalItem = await repository.getReview(lessonId);
      expect(finalItem, isNotNull);
      expect(finalItem!.intervalDays, ReviewScheduler.intervalProgressionDays.last);
    });

    test('getDueReviews returns only due items, soonest first', () async {
      await repository.saveReview(
        ReviewItem(
          lessonId: 'hiragana:1',
          nextReview: now.subtract(const Duration(days: 2)),
          reviewCount: 1,
          easeFactor: 2.5,
          intervalDays: 3,
        ),
      );
      await repository.saveReview(
        ReviewItem(
          lessonId: 'hiragana:2',
          nextReview: now.subtract(const Duration(days: 5)),
          reviewCount: 1,
          easeFactor: 2.5,
          intervalDays: 3,
        ),
      );
      await repository.saveReview(
        ReviewItem(
          lessonId: 'hiragana:3',
          nextReview: now.add(const Duration(days: 10)),
          reviewCount: 1,
          easeFactor: 2.5,
          intervalDays: 3,
        ),
      );

      final List<ReviewItem> due = await scheduler.getDueReviews(now: now);

      expect(due.map((ReviewItem r) => r.lessonId), <String>[
        'hiragana:2',
        'hiragana:1',
      ]);
    });
  });
}
