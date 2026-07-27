import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/weak_area.dart';

IconData _iconForType(WeakAreaType type) {
  switch (type) {
    case WeakAreaType.lowWritingAccuracy:
      return Icons.gesture_outlined;
    case WeakAreaType.missedQuizItem:
      return Icons.quiz_outlined;
    case WeakAreaType.overdueReview:
      return Icons.schedule_outlined;
  }
}

class WeakAreaCard extends StatelessWidget {
  const WeakAreaCard({super.key, required this.weakArea});

  final WeakArea weakArea;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(_iconForType(weakArea.type), color: colorScheme.error),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(weakArea.label, style: Theme.of(context).textTheme.labelLarge),
                  Text(weakArea.description, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
