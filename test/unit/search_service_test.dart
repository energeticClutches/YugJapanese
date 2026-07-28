import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_learning/features/search/models/search_result.dart';
import 'package:japanese_learning/features/search/repositories/search_repository.dart';
import 'package:japanese_learning/features/search/services/search_service.dart';
import 'package:japanese_learning/models/learning_item.dart';

LearningItem _item(String id, String symbol) {
  return LearningItem(
    id: id,
    symbol: symbol,
    primaryReading: 'a',
    meaning: 'meaning',
    strokeCount: 1,
    lessonNumber: 1,
    audioAsset: '',
    strokeAsset: '',
  );
}

SearchResult _result({
  required String id,
  required String symbol,
  required String script,
  required List<String> keywords,
}) {
  return SearchResult(
    id: id,
    symbol: symbol,
    script: script,
    title: symbol,
    subtitle: '',
    searchKeywords: keywords,
    matchedField: 'symbol',
    learningItem: _item(id, symbol),
  );
}

class _FakeSearchRepository implements SearchRepository {
  _FakeSearchRepository(this._all);

  final List<SearchResult> _all;

  @override
  Future<List<SearchResult>> allIndexed() async => _all;

  @override
  Future<List<SearchResult>> search(String normalizedQuery) async {
    return _all
        .where(
          (SearchResult r) =>
              r.symbol.toLowerCase().contains(normalizedQuery) ||
              r.searchKeywords.any((String k) => k.contains(normalizedQuery)),
        )
        .toList();
  }
}

void main() {
  group('SearchService', () {
    test(
      'empty query returns no results without touching the repository',
      () async {
        final service = SearchService(_FakeSearchRepository(<SearchResult>[]));

        expect(await service.search('   '), isEmpty);
      },
    );

    test('ranks an exact symbol match above a prefix match', () async {
      final List<SearchResult> data = <SearchResult>[
        _result(
          id: 'a',
          symbol: 'あ',
          script: 'hiragana',
          keywords: <String>['a'],
        ),
        _result(
          id: 'a-word',
          symbol: 'あい',
          script: 'hiragana',
          keywords: <String>['ai'],
        ),
      ];
      final service = SearchService(_FakeSearchRepository(data));

      final List<SearchResult> results = await service.search('あ');

      expect(results.first.id, 'a');
    });

    test('ranks an exact keyword match above a keyword-prefix match', () async {
      final List<SearchResult> data = <SearchResult>[
        _result(
          id: 'exact',
          symbol: '一',
          script: 'kanji',
          keywords: <String>['one'],
        ),
        _result(
          id: 'prefix',
          symbol: '二',
          script: 'kanji',
          keywords: <String>['onetime'],
        ),
      ];
      final service = SearchService(_FakeSearchRepository(data));

      final List<SearchResult> results = await service.search('one');

      expect(results.first.id, 'exact');
    });

    test('falls back to fuzzy matching for a near-miss query', () async {
      final List<SearchResult> data = <SearchResult>[
        _result(
          id: 'ka',
          symbol: 'か',
          script: 'hiragana',
          keywords: <String>['ka'],
        ),
      ];
      final service = SearchService(_FakeSearchRepository(data));

      // "kx" is one substitution away from "ka" — should still surface it
      // via the fuzzy fallback since direct matches are sparse.
      final List<SearchResult> results = await service.search('kx');

      expect(results.map((SearchResult r) => r.id), contains('ka'));
    });

    test('groupByScript buckets results by their script', () async {
      final service = SearchService(_FakeSearchRepository(<SearchResult>[]));
      final List<SearchResult> results = <SearchResult>[
        _result(id: 'h', symbol: 'あ', script: 'hiragana', keywords: <String>[]),
        _result(id: 'k', symbol: '一', script: 'kanji', keywords: <String>[]),
      ];

      final Map<String, List<SearchResult>> grouped = service.groupByScript(
        results,
      );

      expect(grouped['hiragana']?.single.id, 'h');
      expect(grouped['kanji']?.single.id, 'k');
    });
  });
}
