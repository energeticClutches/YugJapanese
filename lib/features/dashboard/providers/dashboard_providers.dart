import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../repositories/content_repository_factory.dart';
import '../../progress/providers/progress_providers.dart';
import '../models/content_source.dart';
import '../models/learning_statistics.dart';
import '../services/statistics_service.dart';

final statisticsServiceProvider = Provider<StatisticsService>(
  (Ref ref) => StatisticsService(ref.watch(progressRepositoryProvider)),
);

final contentSourcesProvider = Provider<List<ContentSource>>(
  (Ref ref) => ContentRepositoryFactory.availableContentIds
      .map(
        (String contentId) => ContentSource(
          contentId: contentId,
          repository: ContentRepositoryFactory.repositoryFor(contentId),
        ),
      )
      .toList(growable: false),
);

final learningStatisticsProvider = FutureProvider<LearningStatistics>(
  (Ref ref) async {
    ref.watch(progressControllerProvider);
    final StatisticsService service = ref.watch(statisticsServiceProvider);
    final List<ContentSource> sources = ref.watch(contentSourcesProvider);
    return service.getStatistics(sources);
  },
);
