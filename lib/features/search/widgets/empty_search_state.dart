import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

class EmptySearchState extends StatelessWidget {
  const EmptySearchState({
    super.key,
    this.message =
        'No results found. Try a different character, romaji, or meaning.',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
