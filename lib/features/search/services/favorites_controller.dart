import 'package:flutter/foundation.dart';

import '../models/favorite_item.dart';
import '../repositories/favorites_repository.dart';

class FavoritesController extends ChangeNotifier {
  FavoritesController(this._repository) {
    _load();
  }

  final FavoritesRepository _repository;
  List<FavoriteItem> _favorites = <FavoriteItem>[];
  bool _isReady = false;

  List<FavoriteItem> get favorites => _favorites;
  bool get isReady => _isReady;

  bool isFavorite(String id) =>
      _favorites.any((FavoriteItem item) => item.id == id);

  Future<void> _load() async {
    _favorites = await _repository.getAll();
    _isReady = true;
    notifyListeners();
  }

  Future<void> toggle({
    required String script,
    required String itemId,
    required String symbol,
  }) async {
    final String id = '$script:$itemId';
    if (isFavorite(id)) {
      await _repository.remove(id);
      _favorites = _favorites
          .where((FavoriteItem item) => item.id != id)
          .toList();
    } else {
      final FavoriteItem item = FavoriteItem(
        script: script,
        itemId: itemId,
        symbol: symbol,
        createdAt: DateTime.now(),
      );
      await _repository.add(item);
      _favorites = <FavoriteItem>[..._favorites, item];
    }
    notifyListeners();
  }
}
