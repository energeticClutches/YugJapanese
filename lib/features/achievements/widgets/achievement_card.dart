import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class AchievementCard extends StatelessWidget {
  const AchievementCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.isUnlocked,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool isUnlocked;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final Color foreground =
        isUnlocked ? colorScheme.primary : AppColors.textSecondary;

    final Widget card = Material(
      color: colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: Opacity(
        opacity: isUnlocked ? 1 : 0.5,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: foreground, size: 32),
              const SizedBox(height: AppSpacing.sm),
              Text(title, style: AppTypography.title),
              const SizedBox(height: AppSpacing.xs),
              Text(description, style: AppTypography.caption),
            ],
          ),
        ),
      ),
    );

    if (!isUnlocked) {
      return card;
    }

    // Brief scale-in for unlocked achievements only, to draw the eye
    // without an app-wide animation pass.
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.85, end: 1),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutBack,
      builder: (BuildContext context, double scale, Widget? child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: card,
    );
  }
}
