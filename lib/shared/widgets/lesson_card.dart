import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

class LessonCard extends StatelessWidget {
  const LessonCard({
    super.key,
    required this.lessonTitle,
    required this.lessonSubtitle,
    required this.characters,
    required this.onStartPressed,
    required this.progressLabel,
    this.writingAccuracy,
  });

  final String lessonTitle;
  final String lessonSubtitle;
  final List<String> characters;
  final VoidCallback onStartPressed;
  final String progressLabel;

  /// Best writing accuracy (0..1) for a finished lesson, or null when the
  /// lesson has not been completed and so has no attempt to report.
  ///
  /// Deliberately separate from [progressLabel]. This used to be an
  /// `int completionPercentage` that was only ever 100 or 0 — `isCompleted`
  /// wearing a percent sign — and it was concatenated onto the label, which
  /// is itself derived from accuracy. "Completed - Practice Again - 100%"
  /// therefore read as a perfect writing score on an attempt that had in
  /// fact scored 0 (BUG-009). The two are rendered as separate, labelled
  /// lines so neither can be mistaken for the other.
  final double? writingAccuracy;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Resolve type styles from the active theme rather than AppTypography's
    // static getters, which are baked to the light palette and render the
    // character previews invisible against the dark surface.
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.extraLarge),
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lessonTitle, style: textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(lessonSubtitle, style: textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(progressLabel, style: textTheme.labelLarge),
            if (writingAccuracy != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Writing accuracy: ${(writingAccuracy! * 100).round()}%',
                style: textTheme.bodySmall,
              ),
            ],
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
                        style: textTheme.titleLarge,
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
