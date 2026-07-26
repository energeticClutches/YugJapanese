import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_learning/features/analytics/models/daily_learning_stat.dart';
import 'package:japanese_learning/features/analytics/models/learning_analytics.dart';
import 'package:japanese_learning/features/analytics/models/script_analytics.dart';
import 'package:japanese_learning/features/analytics/models/weak_area.dart';
import 'package:japanese_learning/features/analytics/services/analytics_export_service.dart';

LearningAnalytics _sampleAnalytics() {
  return LearningAnalytics(
    totalLessonsCompleted: 2,
    completionPercentage: 10.5,
    totalPracticeSessions: 1,
    totalReviews: 1,
    estimatedStudyMinutes: 9,
    currentStreakDays: 1,
    longestStreakDays: 1,
    scriptBreakdown: <ScriptAnalytics>[
      const ScriptAnalytics(
        contentId: 'hiragana',
        completionPercentage: 100,
        averageWritingAccuracy: 1,
        averageQuizAccuracy: 20,
        reviewsDue: 0,
        practiceSessions: 1,
      ),
    ],
    dailyActivity: <DailyLearningStat>[
      DailyLearningStat(
        date: DateTime(2026, 7, 26),
        lessonsCompleted: 1,
        reviewsCompleted: 1,
        practiceSessions: 1,
        questionsAnswered: 10,
        averageWritingAccuracy: 1,
        averageQuizAccuracy: 20,
        reviewSuccessRate: 1,
      ),
    ],
    weakAreas: const <WeakArea>[
      WeakArea(
        type: WeakAreaType.missedQuizItem,
        contentId: 'hiragana',
        itemId: 'hiragana_a',
        label: 'あ',
        description: 'Missed 2 times in quizzes',
        severity: 2,
      ),
    ],
    insights: const <String>['Listening Quiz is your strongest practice mode (20% accuracy).'],
    achievementsUnlocked: 3,
    achievementsTotal: 12,
    nextAchievements: const <NextAchievement>[],
    computedAt: DateTime(2026, 7, 26, 17, 30),
  );
}

void main() {
  group('AnalyticsExportService', () {
    const AnalyticsExportService service = AnalyticsExportService();

    test('toCsv includes summary, script, daily, and weak-area sections', () {
      final String csv = service.toCsv(_sampleAnalytics());

      expect(csv, contains('Overall Summary'));
      expect(csv, contains('Total Lessons Completed,2'));
      expect(csv, contains('Script Breakdown'));
      expect(csv, contains('hiragana,100.0,1.0,20.0,0,1'));
      expect(csv, contains('Daily Activity'));
      expect(csv, contains('2026-07-26'));
      expect(csv, contains('Weak Areas'));
      expect(csv, contains('Missed 2 times in quizzes'));
    });

    test('toCsv escapes fields containing commas', () {
      final analytics = _sampleAnalytics();
      final withComma = LearningAnalytics(
        totalLessonsCompleted: analytics.totalLessonsCompleted,
        completionPercentage: analytics.completionPercentage,
        totalPracticeSessions: analytics.totalPracticeSessions,
        totalReviews: analytics.totalReviews,
        estimatedStudyMinutes: analytics.estimatedStudyMinutes,
        currentStreakDays: analytics.currentStreakDays,
        longestStreakDays: analytics.longestStreakDays,
        scriptBreakdown: analytics.scriptBreakdown,
        dailyActivity: analytics.dailyActivity,
        weakAreas: <WeakArea>[
          const WeakArea(
            type: WeakAreaType.overdueReview,
            contentId: 'hiragana',
            itemId: 'hiragana:1',
            label: 'Lesson あ, い',
            description: 'Overdue by 3 days',
            severity: 3,
          ),
        ],
        insights: analytics.insights,
        achievementsUnlocked: analytics.achievementsUnlocked,
        achievementsTotal: analytics.achievementsTotal,
        nextAchievements: analytics.nextAchievements,
        computedAt: analytics.computedAt,
      );

      final String csv = service.toCsv(withComma);

      expect(csv, contains('"Lesson あ, い"'));
    });

    test('toJson produces valid, parseable JSON with the right structure', () {
      final String json = service.toJson(_sampleAnalytics());
      final Map<String, dynamic> decoded =
          jsonDecode(json) as Map<String, dynamic>;

      expect(decoded['summary']['totalLessonsCompleted'], 2);
      expect(decoded['summary']['achievementsUnlocked'], 3);
      expect(decoded['summary']['achievementsTotal'], 12);
      expect((decoded['scriptBreakdown'] as List).length, 1);
      expect((decoded['dailyActivity'] as List).length, 1);
      expect((decoded['weakAreas'] as List).length, 1);
      expect(decoded['insights'], <String>[
        'Listening Quiz is your strongest practice mode (20% accuracy).',
      ]);
    });
  });
}
