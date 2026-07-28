import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_learning/features/achievements/models/streak_info.dart';
import 'package:japanese_learning/features/achievements/services/achievement_service.dart';
import 'package:japanese_learning/features/dashboard/models/content_source.dart';
import 'package:japanese_learning/features/dashboard/services/statistics_service.dart';
import 'package:japanese_learning/features/progress/models/lesson_progress.dart';
import 'package:japanese_learning/features/quiz/models/practice_result.dart';
import 'package:japanese_learning/features/quiz/services/practice_statistics_service.dart';
import 'package:japanese_learning/features/review/models/review_item.dart';
import 'package:japanese_learning/repositories/content_repository_factory.dart';

import '../fakes/fake_achievement_repository.dart';
import '../fakes/fake_practice_repository.dart';
import '../fakes/fake_progress_repository.dart';
import '../fakes/fake_review_repository.dart';

/// Fixed "today" so streak arithmetic never depends on the wall clock.
final DateTime _today = DateTime(2026, 7, 29);

DateTime _daysAgo(int days) => _today.subtract(Duration(days: days));

LessonProgress _completedLesson(int lessonNumber, DateTime completedOn) {
  return LessonProgress(
    contentId: 'hiragana',
    lessonNumber: lessonNumber,
    isCompleted: true,
    bestWritingAccuracy: 0.8,
    lastAccessedAt: completedOn,
    completedAt: completedOn,
    lastCompletedAt: completedOn,
  );
}

PracticeResult _quiz(String id, DateTime endedOn) {
  return PracticeResult(
    id: id,
    modeId: 'recognition',
    contentIds: const <String>['hiragana'],
    totalQuestions: 10,
    correctAnswers: 8,
    incorrectAnswers: 2,
    accuracy: 80,
    startTime: endedOn,
    endTime: endedOn,
  );
}

ReviewItem _review(String lessonId, DateTime reviewedOn) {
  return ReviewItem(
    lessonId: lessonId,
    nextReview: reviewedOn.add(const Duration(days: 3)),
    lastReviewed: reviewedOn,
    reviewCount: 1,
    easeFactor: 2.5,
    intervalDays: 3,
  );
}

/// Only Hiragana is registered here — the streak reads progress per content
/// source, and one script is enough to exercise the rules.
final List<ContentSource> sources = <ContentSource>[
  ContentSource(
    contentId: 'hiragana',
    repository: ContentRepositoryFactory.repositoryFor('hiragana'),
  ),
];

void main() {
  late FakeProgressRepository progress;
  late FakePracticeRepository practice;
  late FakeReviewRepository review;
  late AchievementService service;

  setUp(() {
    progress = FakeProgressRepository();
    practice = FakePracticeRepository();
    review = FakeReviewRepository();
    service = AchievementService(
      achievementRepository: FakeAchievementRepository(),
      progressRepository: progress,
      statisticsService: StatisticsService(progress),
      reviewRepository: review,
      practiceStatisticsService: PracticeStatisticsService(practice),
      practiceRepository: practice,
    );
  });

  group('Learning streak (Milestone 31, Issue 6)', () {
    test('no activity means no streak', () async {
      final StreakInfo streak = await service.calculateStreak(
        sources,
        now: _today,
      );
      expect(streak.currentStreak, 0);
      expect(streak.longestStreak, 0);
      expect(streak.lastActiveDate, isNull);
    });

    test('a completed lesson counts as a learning activity', () async {
      await progress.saveProgress(_completedLesson(1, _today));

      final StreakInfo streak = await service.calculateStreak(
        sources,
        now: _today,
      );
      expect(streak.currentStreak, 1);
    });

    test('a completed quiz counts, with no lesson activity at all', () async {
      await practice.saveResult(_quiz('q1', _today));

      final StreakInfo streak = await service.calculateStreak(
        sources,
        now: _today,
      );
      expect(
        streak.currentStreak,
        1,
        reason: 'quiz sessions used to contribute nothing to the streak',
      );
    });

    test('a completed review counts', () async {
      await review.saveReview(_review('hiragana:1', _today));

      final StreakInfo streak = await service.calculateStreak(
        sources,
        now: _today,
      );
      expect(streak.currentStreak, 1);
    });

    test('merely opening a lesson does not count', () async {
      await progress.saveProgress(
        LessonProgress(
          contentId: 'hiragana',
          lessonNumber: 1,
          isCompleted: false,
          bestWritingAccuracy: 0,
          lastAccessedAt: _today,
        ),
      );

      final StreakInfo streak = await service.calculateStreak(
        sources,
        now: _today,
      );
      expect(
        streak.currentStreak,
        0,
        reason: 'the streak counts completed activities, not visits',
      );
    });

    test('several activities on one day still count as a single day', () async {
      await progress.saveProgress(_completedLesson(1, _today));
      await progress.saveProgress(_completedLesson(2, _today));
      await practice.saveResult(_quiz('q1', _today));
      await practice.saveResult(_quiz('q2', _today));
      await review.saveReview(_review('hiragana:1', _today));

      final StreakInfo streak = await service.calculateStreak(
        sources,
        now: _today,
      );
      expect(streak.currentStreak, 1);
      expect(streak.longestStreak, 1);
    });

    test(
      'consecutive days accumulate across different activity types',
      () async {
        await progress.saveProgress(_completedLesson(1, _daysAgo(2)));
        await practice.saveResult(_quiz('q1', _daysAgo(1)));
        await review.saveReview(_review('hiragana:1', _today));

        final StreakInfo streak = await service.calculateStreak(
          sources,
          now: _today,
        );
        expect(streak.currentStreak, 3);
        expect(streak.longestStreak, 3);
      },
    );

    test('a missed day resets the current streak', () async {
      // Active 5, 4 and 3 days ago, then nothing until today.
      await practice.saveResult(_quiz('q1', _daysAgo(5)));
      await practice.saveResult(_quiz('q2', _daysAgo(4)));
      await practice.saveResult(_quiz('q3', _daysAgo(3)));
      await practice.saveResult(_quiz('q4', _today));

      final StreakInfo streak = await service.calculateStreak(
        sources,
        now: _today,
      );
      expect(streak.currentStreak, 1);
      expect(
        streak.longestStreak,
        3,
        reason: 'the broken run is still the best one achieved',
      );
    });

    test('yesterday still counts as an unbroken streak today', () async {
      await practice.saveResult(_quiz('q1', _daysAgo(2)));
      await practice.saveResult(_quiz('q2', _daysAgo(1)));

      final StreakInfo streak = await service.calculateStreak(
        sources,
        now: _today,
      );
      expect(
        streak.currentStreak,
        2,
        reason: 'a streak should not break until a full day is missed',
      );
    });

    test('a long-abandoned streak reads as zero today', () async {
      await practice.saveResult(_quiz('q1', _daysAgo(10)));
      await practice.saveResult(_quiz('q2', _daysAgo(9)));

      final StreakInfo streak = await service.calculateStreak(
        sources,
        now: _today,
      );
      expect(streak.currentStreak, 0);
      expect(streak.longestStreak, 2);
    });

    test('last active date is the most recent qualifying activity', () async {
      await progress.saveProgress(_completedLesson(1, _daysAgo(4)));
      await practice.saveResult(_quiz('q1', _daysAgo(1)));

      final StreakInfo streak = await service.calculateStreak(
        sources,
        now: _today,
      );
      expect(streak.lastActiveDate, DateTime(2026, 7, 28));
    });

    test('re-completing an old lesson today extends the streak', () async {
      // First finished long ago, studied again today: `completedAt` stays
      // at the original date, so only `lastCompletedAt` can register this.
      await progress.saveProgress(
        LessonProgress(
          contentId: 'hiragana',
          lessonNumber: 1,
          isCompleted: true,
          bestWritingAccuracy: 0.9,
          lastAccessedAt: _today,
          completedAt: _daysAgo(30),
          lastCompletedAt: _today,
        ),
      );

      final StreakInfo streak = await service.calculateStreak(
        sources,
        now: _today,
      );
      expect(streak.currentStreak, 1);
    });
  });

  group('LessonProgress persistence', () {
    test('round-trips lastCompletedAt', () {
      final LessonProgress original = _completedLesson(1, _today);
      final LessonProgress restored = LessonProgress.fromMap(original.toMap());
      expect(restored.lastCompletedAt, _today);
    });

    test('an older record without lastCompletedAt falls back to '
        'completedAt', () {
      final Map<String, dynamic> legacy = <String, dynamic>{
        'contentId': 'hiragana',
        'lessonNumber': 1,
        'isCompleted': true,
        'bestWritingAccuracy': 0.8,
        'lastAccessedAt': _today.toIso8601String(),
        'completedAt': _today.toIso8601String(),
      };
      expect(LessonProgress.fromMap(legacy).lastCompletedAt, _today);
    });

    test('an in-progress record has no completion date', () {
      final Map<String, dynamic> inProgress = <String, dynamic>{
        'contentId': 'hiragana',
        'lessonNumber': 1,
        'isCompleted': false,
        'bestWritingAccuracy': 0.0,
        'lastAccessedAt': _today.toIso8601String(),
        'completedAt': null,
      };
      expect(LessonProgress.fromMap(inProgress).lastCompletedAt, isNull);
    });
  });
}
