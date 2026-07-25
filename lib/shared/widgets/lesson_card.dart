import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

class LessonCard extends StatelessWidget {
  const LessonCard({
    super.key,
    required this.lessonTitle,
    required this.lessonSubtitle,
    required this.characters,
    required this.onStartPressed,
    required this.progressLabel,
    required this.completionPercentage,
  });

  final String lessonTitle;
  final String lessonSubtitle;
  final List<String> characters;
  final VoidCallback onStartPressed;
  final String progressLabel;
  final int completionPercentage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.extraLarge),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lessonTitle, style: AppTypography.headline),
            const SizedBox(height: AppSpacing.xs),
            Text(lessonSubtitle, style: AppTypography.body),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '$progressLabel - $completionPercentage%',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: characters
                  .map(
                    (String character) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                      ),
                      child: Text(
                        character,
                        style: AppTypography.title,
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onStartPressed,
                child: const Text('Start Lesson'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
