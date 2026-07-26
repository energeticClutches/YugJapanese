import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// Session-length selector (10/20/50 questions), shown on the practice home
/// screen above the mode grid.
class PracticeModeSelector extends StatelessWidget {
  const PracticeModeSelector({
    super.key,
    required this.selectedLength,
    required this.onChanged,
  });

  final int selectedLength;
  final ValueChanged<int> onChanged;

  static const List<int> options = <int>[10, 20, 50];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      children: [
        for (final int length in options)
          ChoiceChip(
            label: Text('$length questions'),
            selected: selectedLength == length,
            onSelected: (_) => onChanged(length),
          ),
      ],
    );
  }
}
