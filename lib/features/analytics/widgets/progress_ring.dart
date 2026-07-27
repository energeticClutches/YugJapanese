import 'package:flutter/material.dart';


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
                  backgroundColor: Theme.of(context).colorScheme.outline,
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
              ),
              Text('${clamped.round()}%', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
