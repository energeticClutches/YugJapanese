import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

enum AnswerOptionState { neutral, selectedCorrect, selectedIncorrect, revealedCorrect }

class AnswerOption extends StatelessWidget {
  const AnswerOption({
    super.key,
    required this.label,
    required this.state,
    required this.onTap,
  });

  final String label;
  final AnswerOptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    Color borderColor = AppColors.divider;
    Color? fillColor;
    switch (state) {
      case AnswerOptionState.neutral:
        break;
      case AnswerOptionState.selectedCorrect:
      case AnswerOptionState.revealedCorrect:
        borderColor = AppColors.success;
        fillColor = AppColors.success.withValues(alpha: 0.12);
        break;
      case AnswerOptionState.selectedIncorrect:
        borderColor = colorScheme.error;
        fillColor = colorScheme.error.withValues(alpha: 0.12);
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: fillColor ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: borderColor),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Text(
              label,
              style: AppTypography.body,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
