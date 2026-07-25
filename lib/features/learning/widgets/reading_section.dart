import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// Displays a Kanji's on'yomi and kun'yomi readings. Renders nothing for
/// content that has neither (Hiragana, Katakana).
class ReadingSection extends StatelessWidget {
  const ReadingSection({
    super.key,
    required this.onReadings,
    required this.kunReadings,
  });

  final List<String> onReadings;
  final List<String> kunReadings;

  @override
  Widget build(BuildContext context) {
    if (onReadings.isEmpty && kunReadings.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (onReadings.isNotEmpty)
          Expanded(
            child: _ReadingColumn(label: 'On Reading', readings: onReadings),
          ),
        if (onReadings.isNotEmpty && kunReadings.isNotEmpty)
          const SizedBox(width: AppSpacing.lg),
        if (kunReadings.isNotEmpty)
          Expanded(
            child: _ReadingColumn(label: 'Kun Reading', readings: kunReadings),
          ),
      ],
    );
  }
}

class _ReadingColumn extends StatelessWidget {
  const _ReadingColumn({required this.label, required this.readings});

  final String label;
  final List<String> readings;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      children: [
        Text(label, style: theme.textTheme.labelMedium, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.xs),
        Text(
          readings.join(', '),
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
