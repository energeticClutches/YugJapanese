import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../repositories/content_repository_factory.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../models/practice_mode.dart';
import '../models/practice_statistics.dart';
import '../providers/practice_providers.dart';
import '../services/practice_generator.dart';
import '../widgets/practice_card.dart';
import '../widgets/practice_mode_selector.dart';

class PracticeHomeScreen extends ConsumerStatefulWidget {
  const PracticeHomeScreen({super.key});

  @override
  ConsumerState<PracticeHomeScreen> createState() => _PracticeHomeScreenState();
}

class _PracticeHomeScreenState extends ConsumerState<PracticeHomeScreen> {
  int _selectedLength = 10;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<PracticeStatistics> statisticsAsync =
        ref.watch(practiceStatisticsProvider);
    final AsyncValue<bool> listeningAvailableAsync =
        ref.watch(listeningModeAvailableProvider);

    return AppScaffold(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.md),
            Text('Practice', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Choose a mode to reinforce recognition, recall, reading, and listening.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Session length', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            PracticeModeSelector(
              selectedLength: _selectedLength,
              onChanged: (int length) => setState(() => _selectedLength = length),
            ),
            const SizedBox(height: AppSpacing.xl),
            statisticsAsync.when(
              data: (PracticeStatistics statistics) => _ModeGrid(
                statistics: statistics,
                listeningAvailable: listeningAvailableAsync.asData?.value ?? true,
                onSelect: (PracticeMode mode) => _startMode(context, mode),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object error, StackTrace stackTrace) => _ModeGrid(
                statistics: PracticeStatistics.empty,
                listeningAvailable: listeningAvailableAsync.asData?.value ?? true,
                onSelect: (PracticeMode mode) => _startMode(context, mode),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  void _startMode(BuildContext context, PracticeMode mode) {
    final String scripts = ContentRepositoryFactory.availableContentIds.join(',');
    context.go('/quiz/play?mode=${mode.id}&scripts=$scripts&length=$_selectedLength');
  }
}

class _ModeGrid extends StatelessWidget {
  const _ModeGrid({
    required this.statistics,
    required this.listeningAvailable,
    required this.onSelect,
  });

  final PracticeStatistics statistics;
  final bool listeningAvailable;
  final ValueChanged<PracticeMode> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        for (final PracticeMode mode in PracticeGenerator.catalog)
          SizedBox(
            width: 320,
            child: PracticeCard(
              mode: mode,
              enabled: mode.id != 'listening' || listeningAvailable,
              disabledReason: mode.id == 'listening' && !listeningAvailable
                  ? 'Not enough audio available yet.'
                  : null,
              bestScore: statistics.bestScoreByMode[mode.id],
              lastPlayed: statistics.lastPlayedByMode[mode.id],
              onTap: () => onSelect(mode),
            ),
          ),
      ],
    );
  }
}
