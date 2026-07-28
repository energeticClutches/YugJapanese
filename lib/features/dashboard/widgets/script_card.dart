import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';

class ScriptCard extends StatelessWidget {
  const ScriptCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final Color foreground = enabled
        ? colorScheme.primary
        : colorScheme.onSurface.withValues(alpha: 0.6);

    return Material(
      color: colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.large),
        onTap: enabled ? onTap : null,
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: foreground, size: 32),
                const SizedBox(height: AppSpacing.sm),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
