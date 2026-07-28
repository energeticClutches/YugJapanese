import 'package:flutter/foundation.dart';

import '../models/lesson_progress.dart';
import '../repositories/progress_repository.dart';

class ProgressController extends ChangeNotifier {
  ProgressController(this._repository);

  final ProgressRepository _repository;
  final Map<String, LessonProgress> _progressByKey = <String, LessonProgress>{};

  LessonProgress? lessonProgress(String contentId, int lessonNumber) {
    return _progressByKey[_key(contentId, lessonNumber)];
  }

  int? lastLessonNumber(String contentId) {
    final List<LessonProgress> progressItems =
        _progressByKey.values
            .where((LessonProgress progress) => progress.contentId == contentId)
            .toList()
          ..sort(
            (LessonProgress first, LessonProgress second) =>
                second.lastAccessedAt.compareTo(first.lastAccessedAt),
          );
    return progressItems.isEmpty ? null : progressItems.first.lessonNumber;
  }

  /// Accuracy a completed lesson must reach before it counts as mastered.
  /// Below this the learner finished the lesson but the writing was shaky, so
  /// the UI nudges them back for another pass instead of calling it done.
  static const double masteryThreshold = 0.75;

  /// Whether [lessonNumber] is finished to a standard worth moving on from.
  bool isMastered(String contentId, int lessonNumber) {
    final LessonProgress? progress = lessonProgress(contentId, lessonNumber);
    return progress != null &&
        progress.isCompleted &&
        progress.bestWritingAccuracy >= masteryThreshold;
  }

  /// Whether [lessonNumber] was completed but not yet to mastery standard.
  bool needsMorePractice(String contentId, int lessonNumber) {
    final LessonProgress? progress = lessonProgress(contentId, lessonNumber);
    return progress != null &&
        progress.isCompleted &&
        progress.bestWritingAccuracy < masteryThreshold;
  }

  int completionPercentage(String contentId, int totalLessons) {
    if (totalLessons == 0) {
      return 0;
    }
    final int completedLessons = _progressByKey.values
        .where(
          (LessonProgress progress) =>
              progress.contentId == contentId && progress.isCompleted,
        )
        .length;
    return ((completedLessons / totalLessons) * 100).round();
  }

  Future<void> loadProgress(String contentId) async {
    final List<LessonProgress> progressItems = await _repository
        .getProgressForContent(contentId);
    for (final LessonProgress progress in progressItems) {
      _progressByKey[_key(progress.contentId, progress.lessonNumber)] =
          progress;
    }
    notifyListeners();
  }

  Future<void> startLesson({
    required String contentId,
    required int lessonNumber,
  }) async {
    final DateTime now = DateTime.now();
    final LessonProgress? existing = await _repository.getLessonProgress(
      contentId: contentId,
      lessonNumber: lessonNumber,
    );
    final LessonProgress progress =
        existing?.copyWith(lastAccessedAt: now) ??
        LessonProgress(
          contentId: contentId,
          lessonNumber: lessonNumber,
          isCompleted: false,
          bestWritingAccuracy: 0,
          lastAccessedAt: now,
        );
    await _save(progress);
  }

  Future<void> completeLesson({
    required String contentId,
    required int lessonNumber,
    required double writingAccuracy,
  }) async {
    final DateTime now = DateTime.now();
    final LessonProgress? existing = await _repository.getLessonProgress(
      contentId: contentId,
      lessonNumber: lessonNumber,
    );
    final LessonProgress progress = LessonProgress(
      contentId: contentId,
      lessonNumber: lessonNumber,
      isCompleted: true,
      bestWritingAccuracy: _bestAccuracy(
        existing?.bestWritingAccuracy ?? 0,
        writingAccuracy,
      ),
      lastAccessedAt: now,
      completedAt: existing?.completedAt ?? now,
      lastCompletedAt: now,
    );
    await _save(progress);
  }

  Future<void> _save(LessonProgress progress) async {
    await _repository.saveProgress(progress);
    _progressByKey[_key(progress.contentId, progress.lessonNumber)] = progress;
    notifyListeners();
  }

  double _bestAccuracy(double current, double candidate) =>
      candidate > current ? candidate : current;

  String _key(String contentId, int lessonNumber) => '$contentId:$lessonNumber';
}
