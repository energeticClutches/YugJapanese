import '../../../models/learning_item.dart';
import '../../dashboard/models/content_source.dart';
import '../models/search_result.dart';
import 'search_repository.dart';

/// Priority order used to pick a single [SearchResult.matchedField] when a
/// query matches more than one field (e.g. "one" as both a stroke count and
/// nothing else — kept simple and deterministic).
const List<String> _fieldPriority = <String>[
  'symbol',
  'romaji',
  'reading',
  'meaning',
  'jlptLevel',
  'radical',
  'strokeCount',
];

class _IndexedItem {
  const _IndexedItem({
    required this.script,
    required this.item,
    required this.fieldKeywords,
  });

  final String script;
  final LearningItem item;

  /// Field name -> lowercased searchable strings for that field.
  final Map<String, List<String>> fieldKeywords;
}

/// Builds an in-memory search index from the same [ContentSource]s the
/// dashboard uses (reusing each script's existing [LessonRepository]),
/// rather than maintaining a parallel data-access path per script.
class OfflineSearchRepository implements SearchRepository {
  OfflineSearchRepository(this._sources);

  final List<ContentSource> _sources;
  List<_IndexedItem>? _cachedIndex;

  Future<List<_IndexedItem>> _buildIndex() async {
    final List<_IndexedItem>? cached = _cachedIndex;
    if (cached != null) {
      return cached;
    }

    final List<_IndexedItem> index = <_IndexedItem>[];
    final Set<String> seenIds = <String>{};

    for (final ContentSource source in _sources) {
      final lessons = await source.repository.getAllLessons();
      for (final lesson in lessons) {
        for (final character in lesson.characters) {
          final String resultId = '${source.contentId}:${character.id}';
          if (!seenIds.add(resultId)) {
            continue;
          }
          final LearningItem? item =
              await source.repository.getItem(character.id);
          if (item == null) {
            continue;
          }
          index.add(
            _IndexedItem(
              script: source.contentId,
              item: item,
              fieldKeywords: _fieldKeywordsFor(item),
            ),
          );
        }
      }
    }

    _cachedIndex = index;
    return index;
  }

  Map<String, List<String>> _fieldKeywordsFor(LearningItem item) {
    return <String, List<String>>{
      'symbol': <String>[item.symbol.toLowerCase()],
      'romaji': <String>[
        item.primaryReading.toLowerCase(),
        ...item.secondaryReadings.map((String r) => r.toLowerCase()),
      ],
      'reading': item.kunReadings.map((String r) => r.toLowerCase()).toList(),
      'meaning': <String>[item.meaning.toLowerCase()],
      'jlptLevel': item.jlptLevel == null
          ? const <String>[]
          : <String>[item.jlptLevel!.toLowerCase()],
      'radical': item.radical == null
          ? const <String>[]
          : <String>[item.radical!.toLowerCase()],
      'strokeCount': <String>['${item.strokeCount}'],
    };
  }

  SearchResult _toResult({
    required _IndexedItem indexed,
    required String matchedField,
  }) {
    final LearningItem item = indexed.item;
    return SearchResult(
      id: '${indexed.script}:${item.id}',
      symbol: item.symbol,
      script: indexed.script,
      title: item.symbol,
      subtitle: '${item.primaryReading} · ${item.meaning}',
      searchKeywords: indexed.fieldKeywords.values
          .expand((List<String> keywords) => keywords)
          .toSet()
          .toList(growable: false),
      matchedField: matchedField,
      learningItem: item,
    );
  }

  /// Which field of [indexed] matches [normalizedQuery], honoring
  /// [_fieldPriority], or `null` if none do. Stroke count also matches
  /// queries like "5 strokes" by comparing only the digits.
  String? _matchedField(_IndexedItem indexed, String normalizedQuery) {
    for (final String field in _fieldPriority) {
      final List<String> keywords = indexed.fieldKeywords[field] ?? const [];
      if (keywords.any((String k) => k.contains(normalizedQuery))) {
        return field;
      }
    }
    final String digitsOnly = normalizedQuery.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isNotEmpty &&
        indexed.fieldKeywords['strokeCount']!.contains(digitsOnly)) {
      return 'strokeCount';
    }
    return null;
  }

  @override
  Future<List<SearchResult>> allIndexed() async {
    final List<_IndexedItem> index = await _buildIndex();
    return index
        .map((_IndexedItem i) => _toResult(indexed: i, matchedField: 'symbol'))
        .toList(growable: false);
  }

  @override
  Future<List<SearchResult>> search(String normalizedQuery) async {
    if (normalizedQuery.isEmpty) {
      return const <SearchResult>[];
    }
    final List<_IndexedItem> index = await _buildIndex();
    final List<SearchResult> results = <SearchResult>[];
    for (final _IndexedItem indexed in index) {
      final String? matchedField = _matchedField(indexed, normalizedQuery);
      if (matchedField != null) {
        results.add(_toResult(indexed: indexed, matchedField: matchedField));
      }
    }
    return results;
  }
}
