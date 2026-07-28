import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';

/// The Analytics screen's learning-streak summary, replacing the activity
/// calendar heatmap it used to show (Milestone 31, Issue 6).
///
/// Shows the three facts the streak actually tracks — current run, best
/// run, and when the learner was last active — instead of a grid of
/// per-day squares that was both hard to read and derived from
/// "opened a lesson" rather than "completed something".
class LearningStreakCard extends StatelessWidget {
  const LearningStreakCard({
    super.key,
    required this.currentStreak,
    required this.longestStreak,
    this.lastActiveDate,
  });

  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActiveDate;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
        side: BorderSide(color: colorScheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_fire_department_outlined,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(_headline, style: theme.textTheme.titleLarge),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _Metric(
                    label: 'Current streak',
                    value: _days(currentStreak),
                  ),
                ),
                Expanded(
                  child: _Metric(
                    label: 'Longest streak',
                    value: _days(longestStreak),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              lastActiveDate == null
                  ? 'No learning activity recorded yet.'
                  : 'Last active: ${_formatDate(lastActiveDate!)}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  String get _headline {
    if (currentStreak <= 0) {
      return 'Start a streak';
    }
    if (currentStreak == 1) {
      return 'Day one — keep it going';
    }
    return '$currentStreak days in a row';
  }

  String _days(int value) => '$value ${value == 1 ? 'day' : 'days'}';

  static String _formatDate(DateTime date) {
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        const SizedBox(height: AppSpacing.xs),
        Text(value, style: theme.textTheme.titleMedium),
      ],
    );
  }
}
