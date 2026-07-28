import 'package:flutter/foundation.dart';

import '../models/practice_question.dart';
import '../models/practice_result.dart';
import '../models/practice_session.dart';
import '../repositories/practice_repository.dart';
import 'practice_generator.dart';

/// Drives an active quiz session end-to-end: generation, answer validation,
/// scoring, and persisting the completed result. Screens `ref.watch()` this
/// — exact shape of `AudioService`/`SettingsController`.
class PracticeService extends ChangeNotifier {
  PracticeService({
    required PracticeGenerator generator,
    required PracticeRepository repository,
  }) : _generator = generator,
       _repository = repository;

  final PracticeGenerator _generator;
  final PracticeRepository _repository;

  PracticeSession? _session;
  PracticeResult? _lastResult;
  bool _isGenerating = false;

  PracticeSession? get currentSession => _session;
  PracticeResult? get lastResult => _lastResult;
  bool get isGenerating => _isGenerating;

  Future<void> startSession({
    required String modeId,
    required List<String> scripts,
    required int questionCount,
  }) async {
    _isGenerating = true;
    notifyListeners();

    final List<PracticeQuestion> questions = await _generator.generateSession(
      modeId: modeId,
      scripts: scripts,
      questionCount: questionCount,
    );

    _session = PracticeSession(
      modeId: modeId,
      questions: questions,
      currentIndex: 0,
      correctAnswers: 0,
      incorrectAnswers: 0,
      startTime: DateTime.now(),
    );
    _isGenerating = false;
    notifyListeners();
  }

  /// Regenerates a short session scoped to the given item ids — used by the
  /// results screen's "Review Mistakes" action.
  Future<void> startReviewMistakes(List<String> itemIds) async {
    _isGenerating = true;
    notifyListeners();

    final List<PracticeQuestion> questions = await _generator
        .generateForItemIds(itemIds);

    _session = PracticeSession(
      modeId: _lastResult?.modeId ?? 'weak_items',
      questions: questions,
      currentIndex: 0,
      correctAnswers: 0,
      incorrectAnswers: 0,
      startTime: DateTime.now(),
    );
    _isGenerating = false;
    notifyListeners();
  }

  /// Validates [answer] against the current question, advances to the next
  /// question, and — once every question has been answered — persists a
  /// [PracticeResult] and exposes it via [lastResult].
  Future<void> submitAnswer(String answer) async {
    final PracticeSession? session = _session;
    final PracticeQuestion? question = session?.currentQuestion;
    if (session == null || question == null) {
      return;
    }

    final bool wasCorrect = answer == question.correctAnswer;
    final PracticeAnswerRecord record = PracticeAnswerRecord(
      questionId: question.id,
      itemId: question.learningItem.id,
      contentId: question.contentId,
      wasCorrect: wasCorrect,
    );

    final PracticeSession updated = session.copyWith(
      currentIndex: session.currentIndex + 1,
      correctAnswers: session.correctAnswers + (wasCorrect ? 1 : 0),
      incorrectAnswers: session.incorrectAnswers + (wasCorrect ? 0 : 1),
      answers: <PracticeAnswerRecord>[...session.answers, record],
    );

    if (updated.isComplete) {
      final PracticeSession finished = updated.copyWith(
        endTime: DateTime.now(),
      );
      _session = finished;
      await _finishSession(finished);
    } else {
      _session = updated;
    }
    notifyListeners();
  }

  Future<void> _finishSession(PracticeSession session) async {
    final List<String> incorrectItemIds = session.answers
        .where((PracticeAnswerRecord record) => !record.wasCorrect)
        .map((PracticeAnswerRecord record) => record.itemId)
        .toList();
    final List<String> contentIds = session.answers
        .map((PracticeAnswerRecord record) => record.contentId)
        .toSet()
        .toList();

    final PracticeResult result = PracticeResult(
      id: '${session.modeId}_${session.startTime.microsecondsSinceEpoch}',
      modeId: session.modeId,
      contentIds: contentIds,
      totalQuestions: session.questions.length,
      correctAnswers: session.correctAnswers,
      incorrectAnswers: session.incorrectAnswers,
      accuracy: session.accuracy,
      startTime: session.startTime,
      endTime: session.endTime ?? DateTime.now(),
      incorrectItemIds: incorrectItemIds,
    );

    await _repository.saveResult(result);
    _lastResult = result;
  }

  void clearSession() {
    _session = null;
    notifyListeners();
  }
}
