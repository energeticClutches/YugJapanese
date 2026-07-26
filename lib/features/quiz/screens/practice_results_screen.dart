import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../models/practice_mode.dart';
import '../models/practice_result.dart';
import '../providers/practice_providers.dart';
import '../services/practice_generator.dart';
import '../widgets/score_card.dart';

class PracticeResultsScreen extends ConsumerWidget {
  const PracticeResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PracticeResult? result = ref.watch(practiceServiceProvider).lastResult;

    if (result == null) {
      return AppScaffold(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No completed session yet.'),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () => _returnToPracticeHome(context),
                child: const Text('Return to Practice'),
              ),
            ],
          ),
        ),
      );
    }

    final PracticeMode? mode = PracticeGenerator.modeById(result.modeId);
    final bool hasMistakes = result.incorrectItemIds.isNotEmpty;

    return AppScaffold(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.md),
            Text(
              'Session Complete',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              mode?.title ?? result.modeId,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xl),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                ScoreCard(
                  icon: Icons.percent,
                  label: 'Accuracy',
                  value: '${result.accuracy.round()}%',
                ),
                ScoreCard(
                  icon: Icons.check_circle_outline,
                  label: 'Correct',
                  value: '${result.correctAnswers}',
                ),
                ScoreCard(
                  icon: Icons.cancel_outlined,
                  label: 'Incorrect',
                  value: '${result.incorrectAnswers}',
                ),
                ScoreCard(
                  icon: Icons.timer_outlined,
                  label: 'Time',
                  value: _formatDuration(result.duration),
                ),
                ScoreCard(
                  icon: Icons.quiz_outlined,
                  label: 'Characters Practiced',
                  value: '${result.totalQuestions}',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            if (hasMistakes) ...[
              Text('Areas to Review', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              Text(
                '${result.incorrectItemIds.length} character(s) to review.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                OutlinedButton(
                  onPressed: () => _returnToPracticeHome(context),
                  child: const Text('Return Home'),
                ),
                if (hasMistakes)
                  OutlinedButton(
                    onPressed: () => context.push(
                      '/quiz/play?mode=${result.modeId}&items=${result.incorrectItemIds.join(',')}',
                    ),
                    child: const Text('Review Mistakes'),
                  ),
                FilledButton(
                  onPressed: () => context.push(
                    '/quiz/play?mode=${result.modeId}&scripts=${result.contentIds.join(',')}&length=${result.totalQuestions}',
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final int minutes = duration.inMinutes;
    final int seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }
}

/// Pops back to whatever pushed this results screen (normally the quiz
/// session, which itself was pushed on top of Practice home) rather than
/// resetting the navigation stack. Falls back to `go('/quiz')` only if
/// there's nothing left to pop to (e.g. this screen was reached directly).
void _returnToPracticeHome(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/quiz');
  }
}
