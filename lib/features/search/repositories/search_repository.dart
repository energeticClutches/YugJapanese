import '../models/search_result.dart';

abstract class SearchRepository {
  /// Every indexed item, unfiltered — used for suggestions and as the
  /// candidate pool for fuzzy fallback matching.
  Future<List<SearchResult>> allIndexed();

  /// Items whose character, readings, meaning, JLPT level, radical, or
  /// stroke count contain [normalizedQuery] (already trimmed/lowercased).
  Future<List<SearchResult>> search(String normalizedQuery);
}
