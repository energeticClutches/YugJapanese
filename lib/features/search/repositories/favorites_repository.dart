import '../models/favorite_item.dart';

abstract class FavoritesRepository {
  Future<List<FavoriteItem>> getAll();

  Future<void> add(FavoriteItem item);

  Future<void> remove(String id);
}
