import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';

/// A destructive-action row (e.g. reset progress/settings) styled to stand
/// apart from regular settings tiles, with an error-tinted border and a
/// dedicated action button.
class DangerZoneCard extends StatelessWidget {
  const DangerZoneCard({
    super.key,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onPressed,
  });

  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(color: colorScheme.error),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(description, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.error,
              side: BorderSide(color: colorScheme.error),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
