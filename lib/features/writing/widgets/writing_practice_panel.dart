import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../models/stroke.dart';
import '../models/stroke_template.dart';
import 'writing_canvas.dart';

/// The interactive writing step: a canvas plus its undo/clear/submit
/// controls. Used for both tracing (guide visible) and free writing
/// (guide hidden), which differ only in whether [guideStrokes] is passed.
class WritingPracticePanel extends StatelessWidget {
  const WritingPracticePanel({
    super.key,
    required this.strokes,
    required this.onStrokesChanged,
    required this.onSubmit,
    required this.expectedStrokeCount,
    this.guideStrokes,
    this.showGrid = true,
    this.instructions,
    this.onCanvasSize,
    this.onDrawingActive,
    this.submitLabel = 'Check my writing',
  });

  final List<Stroke> strokes;
  final ValueChanged<List<Stroke>> onStrokesChanged;
  final VoidCallback onSubmit;
  final int expectedStrokeCount;

  /// Label for the primary action button. Defaults to the free-writing
  /// wording ("Check my writing" — accurate there, since that step is the
  /// one that actually gets scored). Tracing passes something that
  /// describes what really happens when you tap it: nothing is graded
  /// mid-trace, the canvas just clears and the lesson moves on
  /// (Milestone 21, Issue 5 — see `learning_screen.dart`'s `_submitWriting`).
  final String submitLabel;

  /// Reference strokes shown faintly behind the ink, or `null` for none.
  final List<StrokeTemplate>? guideStrokes;

  final bool showGrid;
  final String? instructions;

  /// Forwarded from [WritingCanvas]; see its docs.
  final ValueChanged<Size>? onCanvasSize;

  /// Forwarded from [WritingCanvas]; see its docs.
  final ValueChanged<bool>? onDrawingActive;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool hasInk = strokes.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (instructions != null) ...[
          Text(
            instructions!,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        WritingCanvas(
          strokes: strokes,
          onStrokesChanged: onStrokesChanged,
          guideStrokes: guideStrokes,
          showGrid: showGrid,
          onCanvasSize: onCanvasSize,
          onDrawingActive: onDrawingActive,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${strokes.length} of $expectedStrokeCount strokes',
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: hasInk
                    ? () => onStrokesChanged(
                          strokes.sublist(0, strokes.length - 1),
                        )
                    : null,
                icon: const Icon(Icons.undo),
                label: const Text('Undo'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                    hasInk ? () => onStrokesChanged(const <Stroke>[]) : null,
                icon: const Icon(Icons.clear),
                label: const Text('Clear'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          onPressed: hasInk ? onSubmit : null,
          child: Text(submitLabel),
        ),
      ],
    );
  }
}
