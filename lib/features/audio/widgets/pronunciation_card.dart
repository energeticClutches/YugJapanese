import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/audio_item.dart';
import 'audio_button.dart';

/// A symbol paired with its [AudioButton]. Reusable anywhere a compact
/// "character + play pronunciation" unit is needed, beyond the learning
/// flow's introduction step.
class PronunciationCard extends StatelessWidget {
  const PronunciationCard({
    super.key,
    required this.symbol,
    required this.id,
    required this.assetPath,
    required this.script,
    this.type = AudioType.character,
  });

  final String symbol;
  final String id;
  final String assetPath;
  final String script;
  final AudioType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.fromBorderSide(
          BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(symbol, style: Theme.of(context).textTheme.displayLarge),
          const SizedBox(height: AppSpacing.md),
          AudioButton(id: id, assetPath: assetPath, script: script, type: type),
        ],
      ),
    );
  }
}
