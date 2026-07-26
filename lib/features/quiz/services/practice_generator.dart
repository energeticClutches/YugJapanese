import 'dart:math';

import '../../../models/learning_item.dart';
import '../../../models/lesson_model.dart';
import '../../../repositories/content_repository_factory.dart';
import '../../audio/repositories/audio_repository.dart';
import '../../progress/models/lesson_progress.dart';
import '../../progress/repositories/progress_repository.dart';
import '../../review/models/review_item.dart';
import '../../review/repositories/review_repository.dart';
import '../models/practice_mode.dart';
import '../models/practice_question.dart';
import '../models/practice_result.dart';
import '../repositories/practice_repository.dart';

class _PoolItem {
  const _PoolItem({required this.contentId, required this.learningItem});

  final String contentId;
  final LearningItem learningItem;
}

/// Selects items and builds [PracticeQuestion]s for every practice mode.
/// One private builder per [QuestionType] so quiz logic isn't duplicated
/// across modes — a mode only decides which builder(s) and which item pool
/// to draw from.
class PracticeGenerator {
  PracticeGenerator({
    required AudioRepository audioRepository,
    required ProgressRepository progressRepository,
    required ReviewRepository reviewRepository,
    required PracticeRepository practiceRepository,
    Random? random,
  })  : _audioRepository = audioRepository,
        _progressRepository = progressRepository,
        _reviewRepository = reviewRepository,
        _practiceRepository = practiceRepository,
        _random = random ?? Random();

  final AudioRepository _audioRepository;
  final ProgressRepository _progressRepository;
  final ReviewRepository _reviewRepository;
  final PracticeRepository _practiceRepository;
  final Random _random;

  static const List<PracticeMode> catalog = <PracticeMode>[
    PracticeMode(
      id: 'recognition',
      title: 'Recognition Quiz',
      description: 'See a character, choose its reading.',
      iconKey: 'recognition',
      difficulty: PracticeDifficulty.beginner,
      supportedScripts: <String>['hiragana', 'katakana', 'kanji'],
    ),
    PracticeMode(
      id: 'meaning',
      title: 'Meaning Quiz',
      description: 'See a character, choose its meaning.',
      iconKey: 'meaning',
      difficulty: PracticeDifficulty.beginner,
      supportedScripts: <String>['hiragana', 'katakana', 'kanji'],
    ),
    PracticeMode(
      id: 'reading',
      title: 'Reading Quiz',
      description: 'See a meaning, choose the matching character.',
      iconKey: 'reading',
      difficulty: PracticeDifficulty.intermediate,
      supportedScripts: <String>['hiragana', 'katakana', 'kanji'],
    ),
    PracticeMode(
      id: 'listening',
      title: 'Listening Quiz',
      description: 'Hear a pronunciation, choose the matching character.',
      iconKey: 'listening',
      difficulty: PracticeDifficulty.intermediate,
      supportedScripts: <String>['hiragana', 'katakana', 'kanji'],
    ),
    PracticeMode(
      id: 'mixed',
      title: 'Mixed Practice',
      description: 'A random mix of scripts and question types.',
      iconKey: 'mixed',
      difficulty: PracticeDifficulty.advanced,
      supportedScripts: <String>['hiragana', 'katakana', 'kanji'],
    ),
    PracticeMode(
      id: 'weak_items',
      title: 'Weak Items Practice',
      description:
          'Targets characters with low accuracy, missed reviews, or past mistakes.',
      iconKey: 'weak_items',
      difficulty: PracticeDifficulty.advanced,
      supportedScripts: <String>['hiragana', 'katakana', 'kanji'],
    ),
  ];

  static PracticeMode? modeById(String id) {
    for (final PracticeMode mode in catalog) {
      if (mode.id == id) {
        return mode;
      }
    }
    return null;
  }

  /// Whether Listening mode currently has enough real (non-placeholder)
  /// audio to build a 4-choice question. Per the project's audio-honesty
  /// rule, no synthetic audio is added to force this — callers should
  /// disable the mode when this is false.
  Future<bool> isListeningModeAvailable() async {
    final List<_PoolItem> pool = await _loadListenablePool(
      ContentRepositoryFactory.availableContentIds,
    );
    return pool.length >= 4;
  }

  Future<List<PracticeQuestion>> generateSession({
    required String modeId,
    required List<String> scripts,
    required int questionCount,
  }) async {
    switch (modeId) {
      case 'recognition':
        return _generateSingleType(scripts, QuestionType.recognition, questionCount);
      case 'meaning':
        return _generateSingleType(scripts, QuestionType.meaning, questionCount);
      case 'reading':
        return _generateSingleType(scripts, QuestionType.reading, questionCount);
      case 'listening':
        return _generateListening(scripts, questionCount);
      case 'mixed':
        return _generateMixed(scripts, questionCount);
      case 'weak_items':
        return _generateWeakItems(questionCount);
      default:
        throw ArgumentError('Unknown practice mode "$modeId"');
    }
  }

  /// Regenerates a short session scoped to exactly the given item ids —
  /// used by the results screen's "Review Mistakes" action.
  Future<List<PracticeQuestion>> generateForItemIds(
    List<String> itemIds,
  ) async {
    final List<_PoolItem> pool = await _loadPool(
      ContentRepositoryFactory.availableContentIds,
    );
    final List<_PoolItem> targets =
        pool.where((_PoolItem item) => itemIds.contains(item.learningItem.id)).toList();
    if (targets.isEmpty) {
      return const <PracticeQuestion>[];
    }
    const List<QuestionType> types = <QuestionType>[
      QuestionType.recognition,
      QuestionType.meaning,
      QuestionType.reading,
    ];
    return <PracticeQuestion>[
      for (int i = 0; i < targets.length; i++)
        _buildQuestion(
          targets[i],
          types[_random.nextInt(types.length)],
          pool,
          'q_${i}_${targets[i].learningItem.id}',
        ),
    ];
  }

  Future<List<PracticeQuestion>> _generateSingleType(
    List<String> scripts,
    QuestionType type,
    int count,
  ) async {
    final List<_PoolItem> pool = await _loadPool(scripts);
    if (pool.isEmpty) {
      return const <PracticeQuestion>[];
    }
    final List<_PoolItem> targets = _pickTargets(pool, count);
    return <PracticeQuestion>[
      for (int i = 0; i < targets.length; i++)
        _buildQuestion(targets[i], type, pool, 'q_${i}_${targets[i].learningItem.id}'),
    ];
  }

  Future<List<PracticeQuestion>> _generateListening(
    List<String> scripts,
    int count,
  ) async {
    final List<_PoolItem> pool = await _loadListenablePool(scripts);
    if (pool.length < 4) {
      return const <PracticeQuestion>[];
    }
    final List<_PoolItem> targets = _pickTargets(pool, count);
    return <PracticeQuestion>[
      for (int i = 0; i < targets.length; i++)
        _buildQuestion(
          targets[i],
          QuestionType.listening,
          pool,
          'q_${i}_${targets[i].learningItem.id}',
        ),
    ];
  }

  Future<List<PracticeQuestion>> _generateMixed(
    List<String> scripts,
    int count,
  ) async {
    final List<_PoolItem> pool = await _loadPool(scripts);
    if (pool.isEmpty) {
      return const <PracticeQuestion>[];
    }
    final List<_PoolItem> listenablePool = await _loadListenablePool(scripts);
    final List<QuestionType> availableTypes = <QuestionType>[
      QuestionType.recognition,
      QuestionType.meaning,
      QuestionType.reading,
      if (listenablePool.length >= 4) QuestionType.listening,
    ];

    final List<PracticeQuestion> questions = <PracticeQuestion>[];
    for (int i = 0; i < count; i++) {
      final QuestionType type = availableTypes[_random.nextInt(availableTypes.length)];
      final List<_PoolItem> sourcePool =
          type == QuestionType.listening ? listenablePool : pool;
      final _PoolItem target = sourcePool[_random.nextInt(sourcePool.length)];
      questions.add(
        _buildQuestion(target, type, sourcePool, 'q_${i}_${target.learningItem.id}'),
      );
    }
    return questions;
  }

  Future<List<PracticeQuestion>> _generateWeakItems(int count) async {
    final List<String> allScripts = ContentRepositoryFactory.availableContentIds;
    final List<_PoolItem> pool = await _loadPool(allScripts);
    if (pool.isEmpty) {
      return const <PracticeQuestion>[];
    }

    final Set<String> weakIds = <String>{};

    for (final String contentId in allScripts) {
      final List<LessonProgress> progressItems =
          await _progressRepository.getProgressForContent(contentId);
      for (final LessonProgress progress in progressItems) {
        if (progress.isCompleted && progress.bestWritingAccuracy < 70) {
          for (final _PoolItem item in pool) {
            if (item.contentId == contentId &&
                item.learningItem.lessonNumber == progress.lessonNumber) {
              weakIds.add(item.learningItem.id);
            }
          }
        }
      }
    }

    final List<ReviewItem> reviews = await _reviewRepository.getAllReviews();
    final DateTime now = DateTime.now();
    for (final ReviewItem review in reviews) {
      if (!review.isDue(now)) {
        continue;
      }
      final List<String> parts = review.lessonId.split(':');
      if (parts.length != 2) {
        continue;
      }
      final String contentId = parts[0];
      final int? lessonNumber = int.tryParse(parts[1]);
      if (lessonNumber == null) {
        continue;
      }
      for (final _PoolItem item in pool) {
        if (item.contentId == contentId &&
            item.learningItem.lessonNumber == lessonNumber) {
          weakIds.add(item.learningItem.id);
        }
      }
    }

    final List<PracticeResult> results = await _practiceRepository.getAllResults();
    for (final PracticeResult result in results) {
      weakIds.addAll(result.incorrectItemIds);
    }

    List<_PoolItem> weakPool =
        pool.where((_PoolItem item) => weakIds.contains(item.learningItem.id)).toList();
    if (weakPool.isEmpty) {
      // No weak-signal data yet — fall back to the full pool so the mode
      // still produces a session instead of an empty one.
      weakPool = pool;
    }

    const List<QuestionType> types = <QuestionType>[
      QuestionType.recognition,
      QuestionType.meaning,
      QuestionType.reading,
    ];
    final List<_PoolItem> targets = _pickTargets(weakPool, count);
    return <PracticeQuestion>[
      for (int i = 0; i < targets.length; i++)
        _buildQuestion(
          targets[i],
          types[_random.nextInt(types.length)],
          pool,
          'q_${i}_${targets[i].learningItem.id}',
        ),
    ];
  }

  Future<List<_PoolItem>> _loadPool(List<String> contentIds) async {
    final List<_PoolItem> pool = <_PoolItem>[];
    for (final String contentId in contentIds) {
      final repository = ContentRepositoryFactory.tryRepositoryFor(contentId);
      if (repository == null) {
        continue;
      }
      final List<LessonModel> lessons = await repository.getAllLessons();
      for (final LessonModel lesson in lessons) {
        for (final character in lesson.characters) {
          final LearningItem? item = await repository.getItem(character.id);
          if (item == null) {
            continue;
          }
          pool.add(_PoolItem(contentId: contentId, learningItem: item));
        }
      }
    }
    return pool;
  }

  Future<List<_PoolItem>> _loadListenablePool(List<String> contentIds) async {
    final List<_PoolItem> pool = await _loadPool(contentIds);
    final List<_PoolItem> listenable = <_PoolItem>[];
    for (final _PoolItem item in pool) {
      final audio = await _audioRepository.resolveAudio(
        id: item.learningItem.id,
        assetPath: item.learningItem.audioAsset,
        script: item.contentId,
      );
      if (audio != null) {
        listenable.add(item);
      }
    }
    return listenable;
  }

  List<_PoolItem> _pickTargets(List<_PoolItem> pool, int count) {
    final List<_PoolItem> targets = <_PoolItem>[];
    List<_PoolItem> shuffled = List<_PoolItem>.of(pool)..shuffle(_random);
    int cursor = 0;
    while (targets.length < count) {
      if (cursor >= shuffled.length) {
        shuffled = List<_PoolItem>.of(pool)..shuffle(_random);
        cursor = 0;
      }
      targets.add(shuffled[cursor]);
      cursor++;
    }
    return targets;
  }

  PracticeQuestion _buildQuestion(
    _PoolItem target,
    QuestionType type,
    List<_PoolItem> pool,
    String id,
  ) {
    final List<_PoolItem> samePool =
        pool.where((_PoolItem item) => item.contentId == target.contentId).toList();
    switch (type) {
      case QuestionType.recognition:
        return PracticeQuestion(
          id: id,
          learningItem: target.learningItem,
          contentId: target.contentId,
          questionType: QuestionType.recognition,
          prompt: target.learningItem.symbol,
          choices: _pickChoices(
            correctValue: target.learningItem.primaryReading,
            samePool: samePool,
            fullPool: pool,
            valueOf: (_PoolItem item) => item.learningItem.primaryReading,
          ),
          correctAnswer: target.learningItem.primaryReading,
        );
      case QuestionType.meaning:
        return PracticeQuestion(
          id: id,
          learningItem: target.learningItem,
          contentId: target.contentId,
          questionType: QuestionType.meaning,
          prompt: target.learningItem.symbol,
          choices: _pickChoices(
            correctValue: target.learningItem.meaning,
            samePool: samePool,
            fullPool: pool,
            valueOf: (_PoolItem item) => item.learningItem.meaning,
          ),
          correctAnswer: target.learningItem.meaning,
        );
      case QuestionType.reading:
        return PracticeQuestion(
          id: id,
          learningItem: target.learningItem,
          contentId: target.contentId,
          questionType: QuestionType.reading,
          prompt: target.learningItem.meaning,
          choices: _pickChoices(
            correctValue: target.learningItem.symbol,
            samePool: samePool,
            fullPool: pool,
            valueOf: (_PoolItem item) => item.learningItem.symbol,
          ),
          correctAnswer: target.learningItem.symbol,
        );
      case QuestionType.listening:
        return PracticeQuestion(
          id: id,
          learningItem: target.learningItem,
          contentId: target.contentId,
          questionType: QuestionType.listening,
          prompt: 'Listen and choose the matching character.',
          choices: _pickChoices(
            correctValue: target.learningItem.symbol,
            samePool: samePool,
            fullPool: pool,
            valueOf: (_PoolItem item) => item.learningItem.symbol,
          ),
          correctAnswer: target.learningItem.symbol,
          metadata: <String, dynamic>{
            'audioId': target.learningItem.id,
            'audioAssetPath': target.learningItem.audioAsset,
            'audioScript': target.contentId,
          },
        );
    }
  }

  List<String> _pickChoices({
    required String correctValue,
    required List<_PoolItem> samePool,
    required List<_PoolItem> fullPool,
    required String Function(_PoolItem) valueOf,
    int count = 4,
  }) {
    final Set<String> choices = <String>{correctValue};

    final List<_PoolItem> primary = List<_PoolItem>.of(samePool)..shuffle(_random);
    for (final _PoolItem item in primary) {
      if (choices.length >= count) {
        break;
      }
      final String value = valueOf(item);
      if (value.isEmpty || value == correctValue) {
        continue;
      }
      choices.add(value);
    }

    if (choices.length < count) {
      final List<_PoolItem> secondary = List<_PoolItem>.of(fullPool)..shuffle(_random);
      for (final _PoolItem item in secondary) {
        if (choices.length >= count) {
          break;
        }
        final String value = valueOf(item);
        if (value.isEmpty || value == correctValue) {
          continue;
        }
        choices.add(value);
      }
    }

    final List<String> result = choices.toList()..shuffle(_random);
    return result;
  }
}
