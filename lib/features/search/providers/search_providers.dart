import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../dashboard/providers/dashboard_providers.dart';
import '../models/search_result.dart';
import '../repositories/favorites_repository.dart';
import '../repositories/hive_favorites_repository.dart';
import '../repositories/hive_search_history_repository.dart';
import '../repositories/offline_search_repository.dart';
import '../repositories/search_history_repository.dart';
import '../repositories/search_repository.dart';
import '../services/favorites_controller.dart';
import '../services/search_history_controller.dart';
import '../services/search_service.dart';

final searchRepositoryProvider = Provider<SearchRepository>(
  (Ref ref) => OfflineSearchRepository(ref.watch(contentSourcesProvider)),
);

final searchServiceProvider = Provider<SearchService>(
  (Ref ref) => SearchService(ref.watch(searchRepositoryProvider)),
);

final favoritesRepositoryProvider = Provider<FavoritesRepository>(
  (Ref ref) => const HiveFavoritesRepository(),
);

final favoritesProvider = ChangeNotifierProvider<FavoritesController>(
  (Ref ref) => FavoritesController(ref.watch(favoritesRepositoryProvider)),
);

final searchHistoryRepositoryProvider = Provider<SearchHistoryRepository>(
  (Ref ref) => const HiveSearchHistoryRepository(),
);

final searchHistoryProvider = ChangeNotifierProvider<SearchHistoryController>(
  (Ref ref) =>
      SearchHistoryController(ref.watch(searchHistoryRepositoryProvider)),
);

/// The text currently typed into the search bar.
final searchQueryProvider = StateProvider<String>((Ref ref) => '');

final searchResultsProvider = FutureProvider<List<SearchResult>>(
  (Ref ref) async {
    final String query = ref.watch(searchQueryProvider);
    final SearchService service = ref.watch(searchServiceProvider);
    return service.search(query);
  },
);

/// The full, unfiltered index — used to derive "Popular" suggestions
/// without re-triggering a search.
final allSearchResultsProvider = FutureProvider<List<SearchResult>>(
  (Ref ref) => ref.watch(searchRepositoryProvider).allIndexed(),
);
