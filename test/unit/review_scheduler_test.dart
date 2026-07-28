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
      final ReviewItem item = await scheduler.scheduleInitialReview(
        'hiragana:1',
        now: now,
      );

      expect(item.intervalDays, ReviewScheduler.intervalProgressionDays.first);
      expect(item.reviewCount, 0);
      expect(item.nextReview, now.add(const Duration(days: 1)));
    });

    test(
      'scheduleInitialReview is a no-op if a schedule already exists',
      () async {
        final ReviewItem first = await scheduler.scheduleInitialReview(
          'hiragana:1',
          now: now,
        );
        final ReviewItem second = await scheduler.scheduleInitialReview(
          'hiragana:1',
          now: now.add(const Duration(days: 5)),
        );

        expect(second.nextReview, first.nextReview);
        expect(second.reviewCount, first.reviewCount);
      },
    );

    test(
      'recordSuccessfulReview advances through the interval progression',
      () async {
        await scheduler.scheduleInitialReview('hiragana:1', now: now);

        ReviewItem updated = await scheduler.recordSuccessfulReview(
          'hiragana:1',
          now: now,
        );
        expect(
          updated.intervalDays,
          ReviewScheduler.intervalProgressionDays[1],
        );
        expect(updated.reviewCount, 1);

        updated = await scheduler.recordSuccessfulReview(
          'hiragana:1',
          now: now,
        );
        expect(
          updated.intervalDays,
          ReviewScheduler.intervalProgressionDays[2],
        );
        expect(updated.reviewCount, 2);
      },
    );

    test(
      'recordSuccessfulReview never advances past the final interval',
      () async {
        const String lessonId = 'hiragana:1';
        await scheduler.scheduleInitialReview(lessonId, now: now);

        for (
          int i = 0;
          i < ReviewScheduler.intervalProgressionDays.length + 3;
          i++
        ) {
          await scheduler.recordSuccessfulReview(lessonId, now: now);
        }

        final ReviewItem? finalItem = await repository.getReview(lessonId);
        expect(finalItem, isNotNull);
        expect(
          finalItem!.intervalDays,
          ReviewScheduler.intervalProgressionDays.last,
        );
      },
    );

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

    group('accuracy-aware scheduling', () {
      test(
        'a weak review steps back down the ladder and counts a lapse',
        () async {
          await scheduler.scheduleInitialReview('hiragana:1', now: now);
          await scheduler.recordSuccessfulReview('hiragana:1', now: now);
          await scheduler.recordSuccessfulReview('hiragana:1', now: now);
          final ReviewItem before = (await repository.getReview('hiragana:1'))!;
          expect(
            before.intervalDays,
            ReviewScheduler.intervalProgressionDays[2],
          );

          final ReviewItem after = await scheduler.recordReview(
            'hiragana:1',
            accuracy: 0.2,
            now: now,
          );

          expect(
            after.intervalDays,
            ReviewScheduler.intervalProgressionDays[1],
            reason: 'should drop one rung, not reset to the start',
          );
          expect(after.lapses, 1);
          expect(after.easeFactor, lessThan(before.easeFactor));
        },
      );

      test('a strong review earns ease, a bare pass does not', () async {
        await scheduler.scheduleInitialReview('strong:1', now: now);
        await scheduler.scheduleInitialReview('bare:1', now: now);

        final ReviewItem strong = await scheduler.recordReview(
          'strong:1',
          accuracy: 0.95,
          now: now,
        );
        final ReviewItem bare = await scheduler.recordReview(
          'bare:1',
          accuracy: 0.65,
          now: now,
        );

        expect(strong.easeFactor, greaterThan(bare.easeFactor));
        expect(strong.lapses, 0);
        expect(bare.lapses, 0);
        // Both are still on the same ladder rung; ease is what differs.
        expect(strong.intervalDays, bare.intervalDays);
      });

      test(
        'accumulated ease stretches the gap once intervals get long',
        () async {
          // Drive both to the same high rung, one answering strongly throughout.
          for (int i = 0; i < 5; i++) {
            await scheduler.recordReview('strong:1', accuracy: 0.95, now: now);
            await scheduler.recordReview('bare:1', accuracy: 0.65, now: now);
          }

          final ReviewItem strong = (await repository.getReview('strong:1'))!;
          final ReviewItem bare = (await repository.getReview('bare:1'))!;

          expect(
            strong.intervalDays,
            bare.intervalDays,
            reason: 'same ladder rung, so any difference comes from ease',
          );
          expect(strong.easeFactor, greaterThan(bare.easeFactor));
          expect(
            strong.nextReview.isAfter(bare.nextReview),
            isTrue,
            reason:
                'the confident learner should wait longer to see this again',
          );
        },
      );

      test('recordReview routes by accuracy', () async {
        await scheduler.scheduleInitialReview('pass:1', now: now);
        await scheduler.scheduleInitialReview('fail:1', now: now);

        final ReviewItem passed = await scheduler.recordReview(
          'pass:1',
          accuracy: 0.8,
          now: now,
        );
        final ReviewItem failed = await scheduler.recordReview(
          'fail:1',
          accuracy: 0.3,
          now: now,
        );

        expect(passed.lapses, 0);
        expect(failed.lapses, 1);
      });

      test(
        'a shaky first pass starts with lower ease than a clean one',
        () async {
          final ReviewItem shaky = await scheduler.scheduleInitialReview(
            'shaky:1',
            now: now,
            accuracy: 0.3,
          );
          final ReviewItem clean = await scheduler.scheduleInitialReview(
            'clean:1',
            now: now,
            accuracy: 0.95,
          );

          expect(shaky.easeFactor, lessThan(clean.easeFactor));
        },
      );

      test('ease factor stays within bounds under repeated failure', () async {
        await scheduler.scheduleInitialReview('hiragana:1', now: now);
        for (int i = 0; i < 20; i++) {
          await scheduler.recordReview('hiragana:1', accuracy: 0, now: now);
        }
        final ReviewItem item = (await repository.getReview('hiragana:1'))!;
        expect(item.easeFactor, inInclusiveRange(1.3, 2.8));
        expect(item.intervalDays, greaterThanOrEqualTo(1));
        expect(item.nextReview.isAfter(now), isTrue);
      });

      test(
        'due list puts the struggling lesson first, not the oldest',
        () async {
          // Waiting longer, but never failed and easy to recall.
          await repository.saveReview(
            ReviewItem(
              lessonId: 'easy:1',
              nextReview: now.subtract(const Duration(days: 9)),
              reviewCount: 4,
              easeFactor: 2.8,
              intervalDays: 30,
            ),
          );
          // Came due more recently, but repeatedly failed.
          await repository.saveReview(
            ReviewItem(
              lessonId: 'hard:1',
              nextReview: now.subtract(const Duration(days: 1)),
              reviewCount: 4,
              easeFactor: 1.4,
              intervalDays: 1,
              lapses: 3,
            ),
          );

          final List<ReviewItem> due = await scheduler.getDueReviews(now: now);

          expect(due.first.lessonId, 'hard:1');
        },
      );
    });
  });
}
