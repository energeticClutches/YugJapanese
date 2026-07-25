import 'package:flutter/foundation.dart';

import '../repositories/search_history_repository.dart';

class SearchHistoryController extends ChangeNotifier {
  SearchHistoryController(this._repository) {
    _load();
  }

  final SearchHistoryRepository _repository;
  List<String> _recent = <String>[];
  bool _isReady = false;

  List<String> get recent => _recent;
  bool get isReady => _isReady;

  Future<void> _load() async {
    _recent = await _repository.getRecent();
    _isReady = true;
    notifyListeners();
  }

  Future<void> record(String query) async {
    await _repository.record(query);
    _recent = await _repository.getRecent();
    notifyListeners();
  }

  Future<void> clear() async {
    await _repository.clear();
    _recent = <String>[];
    notifyListeners();
  }
}
