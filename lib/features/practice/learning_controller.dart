import 'package:flutter/foundation.dart';

import '../../models/learning_item.dart';
import '../../models/learning_session.dart';
import '../../models/learning_step.dart';
import '../../repositories/lesson_repository.dart';

class LearningController extends ChangeNotifier {
  LearningController(this._repository);

  final LessonRepository _repository;
  LearningSession? _session;
  int? _currentLessonNumber;
  List<LearningItem> _items = <LearningItem>[];
  bool _skipIntroduction = false;

  LearningSession? get session => _session;
  int? get lessonNumber => _currentLessonNumber;
  LearningItem? get currentItem {
    final int index = _session?.currentCharacterIndex ?? 0;
    if (_items.isEmpty || index < 0 || index >= _items.length) {
      return null;
    }
    return _items[index];
  }

  LearningItem? get currentCharacter => currentItem;

  Future<void> startLesson(
    int lessonNumber, {
    bool skipIntroduction = false,
  }) async {
    final lesson = await _repository.getLesson(lessonNumber);
    if (lesson == null) {
      return;
    }
    _skipIntroduction = skipIntroduction;
    _currentLessonNumber = lesson.lessonNumber;
    _items = <LearningItem>[];
    for (final character in lesson.characters) {
      _items.add(
        LearningItem(
          id: character.id,
          symbol: character.character,
          primaryReading: character.romaji,
          meaning: character.englishName,
          strokeCount: character.strokeCount,
          lessonNumber: character.lessonNumber,
          audioAsset: character.audioAsset,
          strokeAsset: '',
          metadata: <String, dynamic>{
            'unicode': character.unicode,
            'isLearned': character.isLearned,
          },
          secondaryReadings: character.secondaryReadings,
          kunReadings: character.kunReadings,
          radical: character.radical,
          grade: character.grade,
          jlptLevel: character.jlptLevel,
          examples: character.examples,
          notes: character.notes,
        ),
      );
    }
    final LearningStep startStep =
        skipIntroduction ? LearningStep.strokeOrder : LearningStep.introduction;
    _session = LearningSession(
      lessonNumber: lesson.lessonNumber,
      currentCharacterIndex: 0,
      currentStep: startStep,
      totalCharacters: _items.length,
      completedCharacters: 0,
      startStep: startStep,
    );
    notifyListeners();
  }

  LearningStep get currentStep =>
      _session?.currentStep ?? LearningStep.introduction;

  void nextStep() {
    final LearningSession? session = _session;
    if (session == null) {
      return;
    }
    _session = session.nextStep();
    notifyListeners();
  }

  void previousStep() {
    final LearningSession? session = _session;
    if (session == null) {
      return;
    }
    _session = session.previousStep();
    notifyListeners();
  }

  void nextCharacter() {
    final LearningSession? session = _session;
    if (session == null) {
      return;
    }
    _session = session.nextCharacter();
    notifyListeners();
  }

  void restartLesson() {
    final int? lessonNumber = _currentLessonNumber;
    if (lessonNumber == null) {
      return;
    }
    startLesson(lessonNumber, skipIntroduction: _skipIntroduction);
  }
}
