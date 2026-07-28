import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';

class ReviewSummaryCard extends StatelessWidget {
  const ReviewSummaryCard({
    super.key,
    required this.dueCount,
    required this.onTap,
  });

  final int dueCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool hasDueReviews = dueCount > 0;

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Today's Reviews",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      hasDueReviews
                          ? '$dueCount ${dueCount == 1 ? 'Lesson' : 'Lessons'} Due'
                          : "You're all caught up!",
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
              Icon(
                hasDueReviews ? Icons.refresh : Icons.check_circle_outline,
                color: colorScheme.primary,
                size: 32,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
