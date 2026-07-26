import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// A bare circular progress indicator with a centered value label. Used
/// standalone (unlike `ProgressSummaryCard`, which wraps a ring in a full
/// card) so it can be dropped into denser layouts like the Overall Progress
/// section here.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.percentage,
    required this.label,
    this.size = 100,
  });

  final double percentage;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double clamped = percentage.clamp(0, 100).toDouble();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: clamped / 100,
                  strokeWidth: 8,
                  backgroundColor: AppColors.divider,
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
              ),
              Text('${clamped.round()}%', style: AppTypography.title),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: AppTypography.caption),
      ],
    );
  }
}
