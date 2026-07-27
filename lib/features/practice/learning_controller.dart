import 'package:flutter/foundation.dart';

import '../../models/learning_item.dart';
import '../../models/learning_session.dart';
import '../../models/learning_step.dart';
import '../../models/lesson_model.dart';
import '../../repositories/lesson_repository.dart';

class LearningController extends ChangeNotifier {
  LearningController(this._repository);

  final LessonRepository _repository;
  LearningSession? _session;
  int? _currentLessonNumber;
  List<LearningItem> _items = <LearningItem>[];
  bool _skipIntroduction = false;
  String? _startCharacterId;

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
    String? startCharacterId,
  }) async {
    final lesson = await _repository.getLesson(lessonNumber);
    if (lesson == null) {
      return;
    }
    _skipIntroduction = skipIntroduction;
    _startCharacterId = startCharacterId;
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
    final int requestedIndex = startCharacterId == null
        ? -1
        : _items.indexWhere((LearningItem item) => item.id == startCharacterId);
    _session = LearningSession(
      lessonNumber: lesson.lessonNumber,
      currentCharacterIndex: requestedIndex < 0 ? 0 : requestedIndex,
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

  /// The lesson that follows the one currently loaded, or null when this is
  /// the last lesson in the script.
  ///
  /// Reads from the same repository the session was built from, so it stays
  /// correct for whichever script is being studied without the screen having
  /// to know how lessons are numbered or stored.
  Future<int?> nextLessonNumber() async {
    final int? current = _currentLessonNumber;
    if (current == null) {
      return null;
    }
    final List<LessonModel> lessons = await _repository.getAllLessons();
    int? next;
    for (final LessonModel lesson in lessons) {
      // Lowest lesson number above the current one — the JSON is ordered
      // today, but picking the minimum does not depend on that.
      if (lesson.lessonNumber > current &&
          (next == null || lesson.lessonNumber < next)) {
        next = lesson.lessonNumber;
      }
    }
    return next;
  }

  void restartLesson() {
    final int? lessonNumber = _currentLessonNumber;
    if (lessonNumber == null) {
      return;
    }
    startLesson(
      lessonNumber,
      skipIntroduction: _skipIntroduction,
      startCharacterId: _startCharacterId,
    );
  }
}
