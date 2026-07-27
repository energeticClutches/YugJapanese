import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/script_analytics.dart';

class ScriptSummaryCard extends StatelessWidget {
  const ScriptSummaryCard({
    super.key,
    required this.title,
    required this.analytics,
  });

  final String title;
  final ScriptAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            _row(context, 'Completion', '${analytics.completionPercentage.round()}%'),
            _row(
              context,
              'Avg. writing accuracy',
              '${analytics.averageWritingAccuracy.round()}%',
            ),
            _row(
              context,
              'Avg. quiz accuracy',
              '${analytics.averageQuizAccuracy.round()}%',
            ),
            _row(context, 'Reviews due', '${analytics.reviewsDue}'),
            _row(context, 'Practice sessions', '${analytics.practiceSessions}'),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs / 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(value, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}
