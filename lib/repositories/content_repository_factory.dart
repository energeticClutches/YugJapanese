import 'hiragana_repository.dart';
import 'kanji_repository.dart';
import 'katakana_repository.dart';
import 'lesson_repository.dart';

/// Maps a content identifier (e.g. "hiragana", "katakana") to the
/// [LessonRepository] that serves it.
///
/// Add a new script by registering it in [_factories] — callers (the
/// learning flow, dashboard, review screen, content sources) resolve
/// repositories through here instead of branching on contentId strings.
class ContentRepositoryFactory {
  ContentRepositoryFactory._();

  static final Map<String, LessonRepository Function()> _factories =
      <String, LessonRepository Function()>{
        'hiragana': () => HiraganaRepository(),
        'katakana': () => KatakanaRepository(),
        'kanji': () => KanjiRepository(),
      };

  static List<String> get availableContentIds =>
      _factories.keys.toList(growable: false);

  static LessonRepository repositoryFor(String contentId) {
    final LessonRepository? repository = tryRepositoryFor(contentId);
    if (repository == null) {
      throw ArgumentError('No repository registered for "$contentId"');
    }
    return repository;
  }

  static LessonRepository? tryRepositoryFor(String contentId) {
    return _factories[contentId]?.call();
  }
}
