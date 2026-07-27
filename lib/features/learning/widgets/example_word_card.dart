import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/kanji_example.dart';

/// Shows a single example word (kanji spelling, reading, and meaning).
/// Data-driven and reusable for any [KanjiExample], including future
/// standalone vocabulary entries.
class ExampleWordCard extends StatelessWidget {
  const ExampleWordCard({super.key, required this.example});

  final KanjiExample example;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.fromBorderSide(
          BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
      ),
      child: Column(
        children: [
          Text(example.word, style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(example.reading, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(example.meaning, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
