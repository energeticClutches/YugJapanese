import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// Generic error-state display (icon + message + optional retry action).
/// No screen in this app had a dedicated error UI before M19 — `AsyncValue
/// .when`'s `error:` branch typically fell back to an empty/default view
/// instead. Use this where surfacing the failure to the user is more
/// helpful than silently showing empty data.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    this.message = 'Something went wrong. Please try again.',
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            const SizedBox(height: AppSpacing.md),
            Text(message, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.md),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
