import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dashboard/models/content_source.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../../progress/providers/progress_providers.dart';
import '../../quiz/providers/practice_providers.dart';
import '../../review/providers/review_providers.dart';
import '../models/achievement_progress.dart';
import '../models/streak_info.dart';
import '../repositories/achievement_repository.dart';
import '../repositories/hive_achievement_repository.dart';
import '../services/achievement_service.dart';

final achievementRepositoryProvider = Provider<AchievementRepository>(
  (Ref ref) => const HiveAchievementRepository(),
);

final achievementServiceProvider = Provider<AchievementService>(
  (Ref ref) => AchievementService(
    achievementRepository: ref.watch(achievementRepositoryProvider),
    progressRepository: ref.watch(progressRepositoryProvider),
    statisticsService: ref.watch(statisticsServiceProvider),
    reviewRepository: ref.watch(reviewRepositoryProvider),
    practiceStatisticsService: ref.watch(practiceStatisticsServiceProvider),
  ),
);

final streakInfoProvider = FutureProvider<StreakInfo>(
  (Ref ref) async {
    ref.watch(progressControllerProvider);
    ref.watch(dueReviewsProvider);
    final AchievementService service = ref.watch(achievementServiceProvider);
    final List<ContentSource> sources = ref.watch(contentSourcesProvider);
    return service.calculateStreak(sources);
  },
);

final achievementProgressListProvider = FutureProvider<List<AchievementProgress>>(
  (Ref ref) async {
    ref.watch(progressControllerProvider);
    ref.watch(dueReviewsProvider);
    ref.watch(practiceServiceProvider);
    final AchievementService service = ref.watch(achievementServiceProvider);
    final List<ContentSource> sources = ref.watch(contentSourcesProvider);
    return service.evaluateAchievements(sources);
  },
);
