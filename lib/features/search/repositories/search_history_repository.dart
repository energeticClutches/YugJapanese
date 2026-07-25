abstract class SearchHistoryRepository {
  /// Most-recent-first, capped at [maxEntries].
  Future<List<String>> getRecent();

  Future<void> record(String query);

  Future<void> clear();

  static const int maxEntries = 10;
}
