import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../models/daily_learning_stat.dart';

/// A simple GitHub-style activity calendar: one small square per day,
/// color intensity scaled to that day's total activity count. Pure Flutter
/// (`Wrap` of `Container`s) — no charting package.
class ActivityHeatmap extends StatelessWidget {
  const ActivityHeatmap({super.key, required this.days});

  final List<DailyLearningStat> days;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    int maxActivity = 0;
    for (final DailyLearningStat day in days) {
      if (day.activityCount > maxActivity) {
        maxActivity = day.activityCount;
      }
    }

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final DailyLearningStat day in days)
          Tooltip(
            message:
                '${day.date.month}/${day.date.day}: ${day.activityCount} '
                'activit${day.activityCount == 1 ? 'y' : 'ies'}',
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: day.activityCount == 0
                    ? AppColors.divider
                    : colorScheme.primary.withValues(
                        alpha: 0.25 +
                            0.75 *
                                (maxActivity == 0
                                    ? 0
                                    : day.activityCount / maxActivity),
                      ),
                borderRadius: BorderRadius.circular(AppRadius.small / 2),
              ),
            ),
          ),
      ],
    );
  }
}
