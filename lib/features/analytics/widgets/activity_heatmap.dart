import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../models/daily_learning_stat.dart';

/// A GitHub-style activity calendar: one small square per day, color
/// intensity scaled to that day's total activity count, laid out as a
/// proper week grid — columns are weeks (oldest on the left, current week
/// on the right) and rows are weekdays (Sunday at the top), so the visual
/// direction reads left-to-right as chronological progression, matching
/// the calendar's actual date ordering. Pure Flutter (`Row`/`Column` of
/// `Container`s) — no charting package.
class ActivityHeatmap extends StatelessWidget {
  const ActivityHeatmap({super.key, required this.days});

  final List<DailyLearningStat> days;

  static const double _cellSize = 18;
  static const double _cellSpacing = 4;
  static const double _labelColumnWidth = 20;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    int maxActivity = 0;
    for (final DailyLearningStat day in days) {
      if (day.activityCount > maxActivity) {
        maxActivity = day.activityCount;
      }
    }

    // Group days into week-columns aligned on Sunday, oldest week first, so
    // the grid reads chronologically left-to-right and top-to-bottom.
    final DateTime firstDay = days.first.date;
    final int leadingBlanks = firstDay.weekday % 7; // Sunday == 0 offset
    final List<DailyLearningStat?> cells = [
      for (int i = 0; i < leadingBlanks; i++) null,
      ...days,
    ];
    final int weekCount = (cells.length / 7).ceil();
    final List<List<DailyLearningStat?>> weeks = [
      for (int w = 0; w < weekCount; w++)
        [
          for (int d = 0; d < 7; d++)
            (w * 7 + d) < cells.length ? cells[w * 7 + d] : null,
        ],
    ];

    const weekdayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final DateTime today = DateTime.now();
    final DateTime todayOnly = DateTime(today.year, today.month, today.day);

    Widget buildCell(DailyLearningStat? day) {
      if (day == null) {
        return const SizedBox(width: _cellSize, height: _cellSize);
      }
      final bool isToday = day.date == todayOnly;
      return Tooltip(
        message:
            '${day.date.month}/${day.date.day}: ${day.activityCount} '
            'activit${day.activityCount == 1 ? 'y' : 'ies'}',
        child: Container(
          width: _cellSize,
          height: _cellSize,
          decoration: BoxDecoration(
            color: day.activityCount == 0
                ? colorScheme.outline
                : colorScheme.primary.withValues(
                    alpha:
                        0.25 +
                        0.75 *
                            (maxActivity == 0
                                ? 0
                                : day.activityCount / maxActivity),
                  ),
            borderRadius: BorderRadius.circular(AppRadius.small / 2),
            border: isToday
                ? Border.all(color: colorScheme.onSurface, width: 1.5)
                : null,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _labelColumnWidth,
            child: Column(
              children: [
                for (final String label in weekdayLabels)
                  SizedBox(
                    width: _labelColumnWidth,
                    height: _cellSize,
                    child: Center(
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          for (final List<DailyLearningStat?> week in weeks)
            Padding(
              padding: const EdgeInsets.only(left: _cellSpacing),
              child: Column(
                children: [
                  for (final DailyLearningStat? day in week)
                    Padding(
                      padding: const EdgeInsets.only(bottom: _cellSpacing),
                      child: buildCell(day),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
