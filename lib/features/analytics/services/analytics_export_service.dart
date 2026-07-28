import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/daily_learning_stat.dart';
import '../models/learning_analytics.dart';
import '../models/script_analytics.dart';
import '../models/weak_area.dart';

/// Builds CSV/JSON summaries of [LearningAnalytics] and writes them to the
/// app's documents directory. Analytics-only — not a full progress backup
/// (that remains the separate, still-placeholder Export/Import on the
/// Settings screen).
class AnalyticsExportService {
  const AnalyticsExportService();

  String toCsv(LearningAnalytics analytics) {
    final StringBuffer buffer = StringBuffer();

    buffer.writeln('Learning Analytics Export');
    buffer.writeln('Generated At,${analytics.computedAt.toIso8601String()}');
    buffer.writeln();

    buffer.writeln('Overall Summary');
    buffer.writeln('Metric,Value');
    buffer.writeln(
      'Total Lessons Completed,${analytics.totalLessonsCompleted}',
    );
    buffer.writeln(
      'Completion Percentage,${analytics.completionPercentage.toStringAsFixed(1)}',
    );
    buffer.writeln(
      'Total Practice Sessions,${analytics.totalPracticeSessions}',
    );
    buffer.writeln('Total Reviews,${analytics.totalReviews}');
    buffer.writeln(
      'Estimated Study Minutes,${analytics.estimatedStudyMinutes}',
    );
    buffer.writeln('Current Streak Days,${analytics.currentStreakDays}');
    buffer.writeln('Longest Streak Days,${analytics.longestStreakDays}');
    buffer.writeln('Achievements Unlocked,${analytics.achievementsUnlocked}');
    buffer.writeln('Achievements Total,${analytics.achievementsTotal}');
    buffer.writeln();

    buffer.writeln('Script Breakdown');
    buffer.writeln(
      'Script,Completion %,Avg Writing Accuracy,Avg Quiz Accuracy,Reviews Due,Practice Sessions',
    );
    for (final ScriptAnalytics script in analytics.scriptBreakdown) {
      buffer.writeln(
        '${_csv(script.contentId)},'
        '${script.completionPercentage.toStringAsFixed(1)},'
        '${script.averageWritingAccuracy.toStringAsFixed(1)},'
        '${script.averageQuizAccuracy.toStringAsFixed(1)},'
        '${script.reviewsDue},'
        '${script.practiceSessions}',
      );
    }
    buffer.writeln();

    buffer.writeln('Daily Activity (last 30 days)');
    buffer.writeln(
      'Date,Lessons Completed,Reviews Completed,Practice Sessions,Questions Answered,Avg Writing Accuracy,Avg Quiz Accuracy',
    );
    for (final DailyLearningStat day in analytics.dailyActivity) {
      buffer.writeln(
        '${_dateLabel(day.date)},'
        '${day.lessonsCompleted},'
        '${day.reviewsCompleted},'
        '${day.practiceSessions},'
        '${day.questionsAnswered},'
        '${day.averageWritingAccuracy?.toStringAsFixed(1) ?? ''},'
        '${day.averageQuizAccuracy?.toStringAsFixed(1) ?? ''}',
      );
    }
    buffer.writeln();

    buffer.writeln('Weak Areas');
    buffer.writeln('Type,Script,Label,Description');
    for (final WeakArea area in analytics.weakAreas) {
      buffer.writeln(
        '${area.type.name},${_csv(area.contentId)},${_csv(area.label)},'
        '${_csv(area.description)}',
      );
    }

    return buffer.toString();
  }

  String toJson(LearningAnalytics analytics) {
    final Map<String, dynamic> map = <String, dynamic>{
      'generatedAt': analytics.computedAt.toIso8601String(),
      'summary': <String, dynamic>{
        'totalLessonsCompleted': analytics.totalLessonsCompleted,
        'completionPercentage': analytics.completionPercentage,
        'totalPracticeSessions': analytics.totalPracticeSessions,
        'totalReviews': analytics.totalReviews,
        'estimatedStudyMinutes': analytics.estimatedStudyMinutes,
        'currentStreakDays': analytics.currentStreakDays,
        'longestStreakDays': analytics.longestStreakDays,
        'achievementsUnlocked': analytics.achievementsUnlocked,
        'achievementsTotal': analytics.achievementsTotal,
      },
      'scriptBreakdown': [
        for (final ScriptAnalytics script in analytics.scriptBreakdown)
          <String, dynamic>{
            'contentId': script.contentId,
            'completionPercentage': script.completionPercentage,
            'averageWritingAccuracy': script.averageWritingAccuracy,
            'averageQuizAccuracy': script.averageQuizAccuracy,
            'reviewsDue': script.reviewsDue,
            'practiceSessions': script.practiceSessions,
          },
      ],
      'dailyActivity': [
        for (final DailyLearningStat day in analytics.dailyActivity)
          <String, dynamic>{
            'date': _dateLabel(day.date),
            'lessonsCompleted': day.lessonsCompleted,
            'reviewsCompleted': day.reviewsCompleted,
            'practiceSessions': day.practiceSessions,
            'questionsAnswered': day.questionsAnswered,
            'averageWritingAccuracy': day.averageWritingAccuracy,
            'averageQuizAccuracy': day.averageQuizAccuracy,
            'reviewSuccessRate': day.reviewSuccessRate,
          },
      ],
      'weakAreas': [
        for (final WeakArea area in analytics.weakAreas)
          <String, dynamic>{
            'type': area.type.name,
            'contentId': area.contentId,
            'itemId': area.itemId,
            'label': area.label,
            'description': area.description,
          },
      ],
      'insights': analytics.insights,
    };

    return const JsonEncoder.withIndent('  ').convert(map);
  }

  Future<File> exportToFile(
    LearningAnalytics analytics, {
    required bool asCsv,
  }) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String extension = asCsv ? 'csv' : 'json';
    final String content = asCsv ? toCsv(analytics) : toJson(analytics);
    final File file = File(
      '${directory.path}/analytics_export_$timestamp.$extension',
    );
    return file.writeAsString(content);
  }

  String _dateLabel(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _csv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
