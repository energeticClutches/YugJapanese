import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../achievements/providers/achievement_providers.dart';
import '../../dashboard/models/content_source.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../../progress/providers/progress_providers.dart';
import '../../quiz/providers/practice_providers.dart';
import '../../review/providers/review_providers.dart';
import '../models/learning_analytics.dart';
import '../models/script_analytics.dart';
import '../repositories/analytics_repository.dart';
import '../repositories/hive_analytics_repository.dart';
import '../services/analytics_export_service.dart';
import '../services/analytics_service.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>(
  (Ref ref) => const HiveAnalyticsRepository(),
);

final analyticsExportServiceProvider = Provider<AnalyticsExportService>(
  (Ref ref) => const AnalyticsExportService(),
);

final analyticsServiceProvider = Provider<AnalyticsService>(
  (Ref ref) => AnalyticsService(
    progressRepository: ref.watch(progressRepositoryProvider),
    reviewRepository: ref.watch(reviewRepositoryProvider),
    practiceRepository: ref.watch(practiceRepositoryProvider),
    practiceStatisticsService: ref.watch(practiceStatisticsServiceProvider),
    achievementService: ref.watch(achievementServiceProvider),
    achievementRepository: ref.watch(achievementRepositoryProvider),
    analyticsRepository: ref.watch(analyticsRepositoryProvider),
  ),
);

final learningAnalyticsProvider = FutureProvider<LearningAnalytics>(
  (Ref ref) async {
    ref.watch(progressControllerProvider);
    ref.watch(dueReviewsProvider);
    ref.watch(practiceServiceProvider);
    ref.watch(achievementProgressListProvider);
    final AnalyticsService service = ref.watch(analyticsServiceProvider);
    final List<ContentSource> sources = ref.watch(contentSourcesProvider);
    return service.getAnalytics(sources);
  },
);

final scriptAnalyticsProvider = Provider<List<ScriptAnalytics>>(
  (Ref ref) {
    final analytics = ref.watch(learningAnalyticsProvider);
    return analytics.asData?.value.scriptBreakdown ?? const <ScriptAnalytics>[];
  },
);
