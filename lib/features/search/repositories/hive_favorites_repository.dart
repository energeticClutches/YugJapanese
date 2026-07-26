import 'package:hive/hive.dart';

import '../../../core/utils/safe_parse.dart';
import '../models/favorite_item.dart';
import 'favorites_repository.dart';

class HiveFavoritesRepository implements FavoritesRepository {
  const HiveFavoritesRepository();

  static const String boxName = 'favorites';

  Box<dynamic> get _box => Hive.box<dynamic>(boxName);

  @override
  Future<List<FavoriteItem>> getAll() async {
    return _box.values
        .whereType<Map>()
        .map((Map value) => safeParse(value, FavoriteItem.fromMap))
        .whereType<FavoriteItem>()
        .toList(growable: false);
  }

  @override
  Future<void> add(FavoriteItem item) {
    return _box.put(item.id, item.toMap());
  }

  @override
  Future<void> remove(String id) {
    return _box.delete(id);
  }
}
