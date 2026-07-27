import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/stroke_template.dart';
import 'writing_canvas_painter.dart';

/// Plays a character's strokes in writing order, one after another, with a
/// replay control. Non-interactive — this is the "watch how it's written"
/// step that precedes tracing.
///
/// [strokeDuration] is supplied by the caller from the user's Animation
/// Speed setting, so the whole animation scales with that preference.
class StrokeOrderPlayer extends StatefulWidget {
  const StrokeOrderPlayer({
    super.key,
    required this.strokes,
    required this.strokeDuration,
    this.showGrid = true,
  });

  final List<StrokeTemplate> strokes;

  /// How long a single stroke takes to draw.
  final Duration strokeDuration;

  final bool showGrid;

  @override
  State<StrokeOrderPlayer> createState() => _StrokeOrderPlayerState();
}

class _StrokeOrderPlayerState extends State<StrokeOrderPlayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _totalDuration,
  )..forward();

  Duration get _totalDuration =>
      widget.strokeDuration * widget.strokes.length.clamp(1, 100);

  @override
  void didUpdateWidget(StrokeOrderPlayer old) {
    super.didUpdateWidget(old);
    // A new character (or a changed speed setting) restarts the playback.
    if (old.strokes != widget.strokes ||
        old.strokeDuration != widget.strokeDuration) {
      _controller
        ..duration = _totalDuration
        ..forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final int count = widget.strokes.length;

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.medium),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.medium),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (BuildContext context, Widget? child) {
                  return CustomPaint(
                    painter: WritingCanvasPainter(
                      strokes: const [],
                      activeStroke: null,
                      showGrid: widget.showGrid,
                      guideStrokes: widget.strokes,
                      guideProgress: _controller.value * count,
                      inkColor: scheme.onSurface,
                      gridColor: scheme.outlineVariant,
                      guideColor: scheme.primary,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextButton.icon(
          onPressed: () => _controller.forward(from: 0),
          icon: const Icon(Icons.replay),
          label: Text(
            count == 1 ? 'Replay (1 stroke)' : 'Replay ($count strokes)',
          ),
        ),
      ],
    );
  }
}
