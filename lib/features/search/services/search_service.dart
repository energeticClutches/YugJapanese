import '../models/search_result.dart';
import '../repositories/search_repository.dart';

/// Normalizes queries, combines exact/contains matches from the repository
/// with a light fuzzy fallback for typos, ranks the combined set, and
/// groups results by script for the search screen.
class SearchService {
  const SearchService(this._repository);

  final SearchRepository _repository;

  String normalize(String rawQuery) => rawQuery.trim().toLowerCase();

  Future<List<SearchResult>> search(String rawQuery) async {
    final String query = normalize(rawQuery);
    if (query.isEmpty) {
      return const <SearchResult>[];
    }

    final List<SearchResult> direct = await _repository.search(query);
    final Map<String, SearchResult> byId = <String, SearchResult>{
      for (final SearchResult result in direct) result.id: result,
    };

    // Only worth a full-index fuzzy pass when direct matches are sparse and
    // the query is long enough for edit-distance-1 to be meaningful.
    if (byId.length < 5 && query.length >= 2) {
      final List<SearchResult> all = await _repository.allIndexed();
      for (final SearchResult candidate in all) {
        if (byId.containsKey(candidate.id)) {
          continue;
        }
        if (_isFuzzyMatch(candidate, query)) {
          byId[candidate.id] = candidate;
        }
      }
    }

    final List<SearchResult> results = byId.values.toList()
      ..sort(
        (SearchResult a, SearchResult b) =>
            _score(b, query).compareTo(_score(a, query)),
      );
    return results;
  }

  Map<String, List<SearchResult>> groupByScript(List<SearchResult> results) {
    final Map<String, List<SearchResult>> grouped =
        <String, List<SearchResult>>{};
    for (final SearchResult result in results) {
      grouped.putIfAbsent(result.script, () => <SearchResult>[]).add(result);
    }
    return grouped;
  }

  bool _isFuzzyMatch(SearchResult candidate, String query) {
    for (final String keyword in candidate.searchKeywords) {
      if (keyword.isEmpty) {
        continue;
      }
      if (_levenshtein(keyword, query) <= 1) {
        return true;
      }
    }
    return false;
  }

  int _score(SearchResult result, String query) {
    final String symbol = result.symbol.toLowerCase();
    if (symbol == query) {
      return 100;
    }
    if (result.searchKeywords.contains(query)) {
      return 90;
    }
    if (symbol.startsWith(query)) {
      return 70;
    }
    if (result.searchKeywords.any((String k) => k.startsWith(query))) {
      return 60;
    }
    if (result.searchKeywords.any((String k) => k.contains(query))) {
      return 40;
    }
    return 10;
  }

  int _levenshtein(String a, String b) {
    if (a == b) {
      return 0;
    }
    if (a.isEmpty) {
      return b.length;
    }
    if (b.isEmpty) {
      return a.length;
    }

    List<int> previousRow = List<int>.generate(b.length + 1, (int i) => i);
    for (int i = 1; i <= a.length; i++) {
      final List<int> currentRow = List<int>.filled(b.length + 1, 0);
      currentRow[0] = i;
      for (int j = 1; j <= b.length; j++) {
        final int cost = a[i - 1] == b[j - 1] ? 0 : 1;
        final int deletion = previousRow[j] + 1;
        final int insertion = currentRow[j - 1] + 1;
        final int substitution = previousRow[j - 1] + cost;
        currentRow[j] = [
          deletion,
          insertion,
          substitution,
        ].reduce((int x, int y) => x < y ? x : y);
      }
      previousRow = currentRow;
    }
    return previousRow[b.length];
  }
}
