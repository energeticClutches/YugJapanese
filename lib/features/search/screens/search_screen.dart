import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../repositories/content_repository_factory.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../dashboard/models/learning_statistics.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../models/search_result.dart';
import '../providers/search_providers.dart';
import '../services/search_history_controller.dart';
import '../widgets/empty_search_state.dart';
import '../widgets/recent_search_chip.dart';
import '../widgets/search_bar_field.dart';
import '../widgets/search_result_tile.dart';
import '../widgets/search_section.dart';

const Map<String, String> _scriptTitles = <String, String>{
  'hiragana': 'Hiragana',
  'katakana': 'Katakana',
  'kanji': 'Kanji',
};

class _ContinueSuggestion {
  const _ContinueSuggestion({
    required this.contentId,
    required this.lessonNumber,
    required this.displayTitle,
  });

  final String contentId;
  final int lessonNumber;
  final String displayTitle;
}

Future<_ContinueSuggestion?> _resolveContinueSuggestion(
  String? lastLessonId,
) async {
  if (lastLessonId == null) {
    return null;
  }
  final List<String> parts = lastLessonId.split(':');
  if (parts.length != 2) {
    return null;
  }
  final String contentId = parts[0];
  final int? lessonNumber = int.tryParse(parts[1]);
  if (lessonNumber == null) {
    return null;
  }
  final repository = ContentRepositoryFactory.tryRepositoryFor(contentId);
  if (repository == null) {
    return null;
  }
  final lesson = await repository.getLesson(lessonNumber);
  if (lesson == null || lesson.characters.isEmpty) {
    return null;
  }
  return _ContinueSuggestion(
    contentId: contentId,
    lessonNumber: lessonNumber,
    displayTitle: 'Lesson ${lesson.characters.first.character}',
  );
}

List<SearchResult> _popularFrom(List<SearchResult> all) {
  final Map<String, List<SearchResult>> byScript = <String, List<SearchResult>>{};
  for (final SearchResult result in all) {
    if (result.learningItem.lessonNumber != 1) {
      continue;
    }
    byScript.putIfAbsent(result.script, () => <SearchResult>[]).add(result);
  }
  return <SearchResult>[
    for (final List<SearchResult> results in byScript.values) ...results.take(2),
  ];
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openResult(SearchResult result) {
    ref.read(searchHistoryProvider).record(_controller.text);
    context.go(
      '/practice/${result.learningItem.lessonNumber}'
      '?content=${result.script}'
      '&char=${Uri.encodeComponent(result.learningItem.id)}',
    );
  }

  void _applyQuery(String query) {
    _controller.text = query;
    _controller.selection = TextSelection.collapsed(offset: query.length);
    ref.read(searchQueryProvider.notifier).state = query;
  }

  @override
  Widget build(BuildContext context) {
    final String query = ref.watch(searchQueryProvider);
    final AsyncValue<List<SearchResult>> resultsAsync =
        ref.watch(searchResultsProvider);
    final SearchHistoryController history = ref.watch(searchHistoryProvider);

    return AppScaffold(
      appBar: AppBar(title: const Text('Search')),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSearchBar(
            controller: _controller,
            onChanged: (String value) {
              setState(() {});
              ref.read(searchQueryProvider.notifier).state = value;
            },
            onSubmitted: (String value) {
              if (value.trim().isNotEmpty) {
                history.record(value);
              }
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: query.trim().isEmpty
                ? _SearchSuggestions(
                    history: history,
                    onQuerySelected: _applyQuery,
                  )
                : resultsAsync.when(
                    data: (List<SearchResult> results) => results.isEmpty
                        ? const EmptySearchState()
                        : _SearchResults(
                            results: results,
                            onResultTap: _openResult,
                          ),
                    loading: () =>
                        const LoadingIndicator(),
                    error: (Object error, StackTrace stackTrace) =>
                        const EmptySearchState(
                          message: 'Something went wrong while searching.',
                        ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SearchResults extends ConsumerWidget {
  const _SearchResults({required this.results, required this.onResultTap});

  final List<SearchResult> results;
  final ValueChanged<SearchResult> onResultTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<String, List<SearchResult>> grouped =
        ref.read(searchServiceProvider).groupByScript(results);

    return ListView(
      children: [
        for (final MapEntry<String, List<SearchResult>> entry in grouped.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: SearchSection(
              title: _scriptTitles[entry.key] ?? entry.key,
              children: [
                for (final SearchResult result in entry.value)
                  SearchResultTile(
                    result: result,
                    onTap: () => onResultTap(result),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SearchSuggestions extends ConsumerWidget {
  const _SearchSuggestions({
    required this.history,
    required this.onQuerySelected,
  });

  final SearchHistoryController history;
  final ValueChanged<String> onQuerySelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<SearchResult>> allAsync =
        ref.watch(allSearchResultsProvider);
    final AsyncValue<LearningStatistics> statisticsAsync =
        ref.watch(learningStatisticsProvider);

    return ListView(
      children: [
        if (history.recent.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            child: SearchSection(
              title: 'Recent',
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final String query in history.recent)
                      RecentSearchChip(
                        label: query,
                        onTap: () => onQuerySelected(query),
                      ),
                  ],
                ),
              ],
            ),
          ),
        allAsync.when(
          data: (List<SearchResult> all) {
            final List<SearchResult> popular = _popularFrom(all);
            if (popular.isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              child: SearchSection(
                title: 'Popular',
                children: [
                  for (final SearchResult result in popular)
                    SearchResultTile(
                      result: result,
                      onTap: () => onQuerySelected(result.symbol),
                    ),
                ],
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (Object error, StackTrace stackTrace) =>
              const SizedBox.shrink(),
        ),
        statisticsAsync.when(
          data: (LearningStatistics statistics) {
            return FutureBuilder<_ContinueSuggestion?>(
              future: _resolveContinueSuggestion(statistics.lastLessonId),
              builder: (context, snapshot) {
                final _ContinueSuggestion? suggestion = snapshot.data;
                if (suggestion == null) {
                  return const SizedBox.shrink();
                }
                return SearchSection(
                  title: 'Continue Learning',
                  children: [
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.play_circle_outline),
                        title: Text(suggestion.displayTitle),
                        subtitle: Text(
                          _scriptTitles[suggestion.contentId] ??
                              suggestion.contentId,
                        ),
                        onTap: () => context.go(
                          '/practice/${suggestion.lessonNumber}'
                          '?content=${suggestion.contentId}',
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (Object error, StackTrace stackTrace) =>
              const SizedBox.shrink(),
        ),
      ],
    );
  }
}
