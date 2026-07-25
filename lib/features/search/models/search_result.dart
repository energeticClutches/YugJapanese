import '../../../models/learning_item.dart';

/// A single searchable/discoverable item. Deliberately generic — `script`
/// is the same content identifier used throughout the app ('hiragana',
/// 'katakana', 'kanji'), so a future vocabulary or grammar source can
/// produce [SearchResult]s the same way without new search logic.
class SearchResult {
  const SearchResult({
    required this.id,
    required this.symbol,
    required this.script,
    required this.title,
    required this.subtitle,
    required this.searchKeywords,
    required this.matchedField,
    required this.learningItem,
  });

  /// Unique across all sources, e.g. "kanji:一".
  final String id;
  final String symbol;
  final String script;
  final String title;
  final String subtitle;

  /// Every lowercased keyword this item can be found by (character,
  /// readings, meaning, JLPT level, radical, stroke count).
  final List<String> searchKeywords;

  /// Which field satisfied the current query (e.g. "reading", "meaning") —
  /// query-dependent, so it's set when the result is produced, not cached.
  final String matchedField;

  final LearningItem learningItem;
}
