import '../models/character_model.dart';
import '../models/learning_item.dart';
import '../models/lesson_model.dart';
import 'lesson_repository.dart';
import '../services/json_loader_service.dart';

class HiraganaRepository implements LessonRepository {
  HiraganaRepository({JsonLoaderService? loader})
    : _loader = loader ?? const JsonLoaderService();

  final JsonLoaderService _loader;
  List<LessonModel>? _cachedLessons;

  Future<List<LessonModel>> _loadLessons() async {
    return _cachedLessons ??= await _loader.loadHiraganaLessons();
  }

  LearningItem _toLearningItem(CharacterModel character) {
    return LearningItem(
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
      notes: character.notes,
    );
  }

  @override
  Future<List<LessonModel>> getAllLessons() async {
    return _loadLessons();
  }

  @override
  Future<LessonModel?> getLesson(int lesson) async {
    final lessons = await getAllLessons();
    for (final LessonModel item in lessons) {
      if (item.lessonNumber == lesson) {
        return item;
      }
    }
    return null;
  }

  @override
  Future<LearningItem?> getItem(String id) async {
    final lessons = await getAllLessons();
    for (final LessonModel lesson in lessons) {
      for (final CharacterModel character in lesson.characters) {
        if (character.id == id) {
          return _toLearningItem(character);
        }
      }
    }
    return null;
  }
}
