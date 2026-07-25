import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../models/achievement.dart';
import '../models/achievement_progress.dart';
import '../models/streak_info.dart';
import '../providers/achievement_providers.dart';
import '../services/achievement_service.dart';
import '../widgets/achievement_grid.dart';
import '../widgets/achievement_icons.dart';
import '../widgets/streak_card.dart';

List<AchievementGridItem> _toGridItems(List<AchievementProgress> progress) {
  return AchievementService.catalog.map((Achievement achievement) {
    final AchievementProgress itemProgress = progress.firstWhere(
      (AchievementProgress p) => p.achievementId == achievement.id,
      orElse: () => AchievementProgress(
        achievementId: achievement.id,
        isUnlocked: false,
      ),
    );
    return AchievementGridItem(
      title: achievement.title,
      description: achievement.description,
      icon: achievementIconForKey(achievement.iconKey),
      isUnlocked: itemProgress.isUnlocked,
    );
  }).toList(growable: false);
}

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<StreakInfo> streakAsync = ref.watch(streakInfoProvider);
    final AsyncValue<List<AchievementProgress>> achievementsAsync =
        ref.watch(achievementProgressListProvider);
    final StreakInfo streak = streakAsync.asData?.value ?? StreakInfo.empty;

    return AppScaffold(
      appBar: AppBar(title: const Text('Achievements')),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreakCard(
              currentStreak: streak.currentStreak,
              longestStreak: streak.longestStreak,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Achievements',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            achievementsAsync.when(
              data: (List<AchievementProgress> progress) =>
                  AchievementGrid(items: _toGridItems(progress)),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (Object error, StackTrace stackTrace) =>
                  AchievementGrid(items: _toGridItems(const <AchievementProgress>[])),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
