import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';

class ReviewCard extends StatelessWidget {
  const ReviewCard({
    super.key,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final String title;

  /// Secondary line — the lesson's topic plus how overdue it is. Optional
  /// so the card keeps working anywhere only a title is meaningful. Same
  /// title-over-subtitle shape [LessonCard] and [PracticeCard] already
  /// use, so this is the existing visual language rather than a new one
  /// (Milestone 23, Issue 1).
  final String? subtitle;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.large),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: Icon(Icons.refresh, color: colorScheme.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
