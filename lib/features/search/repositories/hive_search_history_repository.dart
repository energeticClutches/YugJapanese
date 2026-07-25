import 'package:hive/hive.dart';

import 'search_history_repository.dart';

class HiveSearchHistoryRepository implements SearchHistoryRepository {
  const HiveSearchHistoryRepository();

  static const String boxName = 'search_history';
  static const String _key = 'recent';

  Box<dynamic> get _box => Hive.box<dynamic>(boxName);

  @override
  Future<List<String>> getRecent() async {
    final value = _box.get(_key);
    if (value is! List) {
      return const <String>[];
    }
    return value.whereType<String>().toList(growable: false);
  }

  @override
  Future<void> record(String query) async {
    final String trimmed = query.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final List<String> current = List<String>.from(await getRecent());
    current.removeWhere(
      (String existing) => existing.toLowerCase() == trimmed.toLowerCase(),
    );
    current.insert(0, trimmed);
    final List<String> capped =
        current.take(SearchHistoryRepository.maxEntries).toList();
    await _box.put(_key, capped);
  }

  @override
  Future<void> clear() {
    return _box.delete(_key);
  }
}
