import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

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
        side: const BorderSide(color: AppColors.divider),
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
                    Text("Today's Reviews", style: AppTypography.caption),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      hasDueReviews
                          ? '$dueCount ${dueCount == 1 ? 'Lesson' : 'Lessons'} Due'
                          : "You're all caught up!",
                      style: AppTypography.headline,
                    ),
                  ],
                ),
              ),
              Icon(
                hasDueReviews
                    ? Icons.refresh
                    : Icons.check_circle_outline,
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
