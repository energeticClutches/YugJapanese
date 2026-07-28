import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/practice_mode.dart';
import 'practice_icons.dart';

class PracticeCard extends StatelessWidget {
  const PracticeCard({
    super.key,
    required this.mode,
    required this.enabled,
    required this.onTap,
    this.bestScore,
    this.lastPlayed,
    this.disabledReason,
  });

  final PracticeMode mode;
  final bool enabled;
  final VoidCallback onTap;
  final double? bestScore;
  final DateTime? lastPlayed;
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
          side: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.large),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                      ),
                      child: Icon(
                        practiceModeIconForKey(mode.iconKey),
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            mode.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            practiceDifficultyLabel(mode.difficulty),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  mode.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (!enabled && disabledReason != null)
                  Text(
                    disabledReason!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: colorScheme.error),
                  )
                else
                  Text(
                    '${bestScore == null ? 'Best: --' : 'Best: ${bestScore!.round()}%'} · '
                    '${lastPlayed == null ? 'Not played yet' : 'Last played ${_formatDate(lastPlayed!)}'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
