import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';

class StreakCard extends StatelessWidget {
  const StreakCard({
    super.key,
    required this.currentStreak,
    required this.longestStreak,
    this.onTap,
  });

  final int currentStreak;
  final int longestStreak;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.extraLarge),
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.extraLarge),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Row(
            children: [
              Icon(
                Icons.local_fire_department,
                color: colorScheme.primary,
                size: 32,
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Current Streak',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '$currentStreak ${currentStreak == 1 ? 'Day' : 'Days'}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Longest Streak',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '$longestStreak ${longestStreak == 1 ? 'Day' : 'Days'}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
