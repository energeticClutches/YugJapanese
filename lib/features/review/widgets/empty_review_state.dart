import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

class EmptyReviewState extends StatelessWidget {
  const EmptyReviewState({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text("You're all caught up!", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'No lessons are due for review right now.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
