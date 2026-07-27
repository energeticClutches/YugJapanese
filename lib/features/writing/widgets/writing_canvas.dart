import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../models/stroke.dart';
import '../models/stroke_point.dart';
import '../models/stroke_template.dart';
import 'writing_canvas_painter.dart';

/// An interactive square drawing surface that records what the user
/// actually draws as [Stroke]s (one per finger-down..finger-up gesture),
/// which is what [WritingEvaluator] scores.
///
/// Optionally renders a reference stroke guide behind the ink and a
/// practice grid, both driven by the user's Settings.
class WritingCanvas extends StatefulWidget {
  const WritingCanvas({
    super.key,
    required this.strokes,
    required this.onStrokesChanged,
    this.guideStrokes,
    this.guideProgress,
    this.showGrid = true,
    this.onCanvasSize,
    this.onDrawingActive,
  });

  /// Strokes drawn so far. The parent owns this list so it survives
  /// rebuilds and can be handed to the evaluator.
  final List<Stroke> strokes;

  final ValueChanged<List<Stroke>> onStrokesChanged;

  /// Reference strokes to show faintly for tracing, or `null` for none.
  final List<StrokeTemplate>? guideStrokes;

  /// How much of the guide to reveal, in fractional stroke units. Null
  /// reveals the whole guide (used by the tracing step, where the target
  /// stays visible rather than animating).
  final double? guideProgress;

  final bool showGrid;

  /// Reports the laid-out canvas size. Strokes are recorded in this same
  /// local coordinate space, so the evaluator needs it to judge coverage
  /// and placement against the right frame of reference.
  final ValueChanged<Size>? onCanvasSize;

  /// Fires `true` when a stroke starts and `false` when it ends. This
  /// screen is normally wrapped in a scrolling page, and Japanese strokes
  /// are frequently near-vertical — indistinguishable, as a gesture, from
  /// "scroll the page". A [GestureDetector]'s pan recognizer loses that
  /// disambiguation to the ancestor `SingleChildScrollView` more often
  /// than not, silently swallowing vertical strokes. The canvas itself
  /// uses a [Listener] (raw pointer events, which bypass gesture-arena
  /// disambiguation and always fire) to guarantee every stroke is
  /// captured; this callback lets the parent additionally suspend page
  /// scrolling for the duration of a stroke so the two gestures don't
  /// fight over the same touch.
  final ValueChanged<bool>? onDrawingActive;

  @override
  State<WritingCanvas> createState() => _WritingCanvasState();
}

class _WritingCanvasState extends State<WritingCanvas> {
  Stroke? _active;

  void _start(Offset position, Size size) {
    if (!_within(position, size)) {
      return;
    }
    widget.onDrawingActive?.call(true);
    setState(() {
      _active = Stroke(
        points: <StrokePoint>[
          StrokePoint(position: position, timestamp: DateTime.now()),
        ],
      );
    });
  }

  void _extend(Offset position, Size size) {
    final Stroke? active = _active;
    if (active == null) {
      return;
    }
    // Clamp rather than drop points once the finger leaves the canvas —
    // a raw Listener keeps delivering move events outside the widget's
    // bounds (unlike a GestureDetector, which a scroll ancestor could
    // otherwise still steal mid-stroke), and silently dropping those
    // points would leave the stroke visibly cut short.
    final Offset clamped = Offset(
      position.dx.clamp(0, size.width),
      position.dy.clamp(0, size.height),
    );
    setState(() {
      _active = Stroke(
        points: <StrokePoint>[
          ...active.points,
          StrokePoint(position: clamped, timestamp: DateTime.now()),
        ],
      );
    });
  }

  void _end() {
    widget.onDrawingActive?.call(false);
    final Stroke? active = _active;
    if (active == null) {
      return;
    }
    setState(() {
      _active = null;
    });
    widget.onStrokesChanged(<Stroke>[...widget.strokes, active]);
  }

  bool _within(Offset p, Size size) {
    return p.dx >= 0 && p.dy >= 0 && p.dx <= size.width && p.dy <= size.height;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final Size size = Size(
            constraints.maxWidth,
            constraints.maxHeight,
          );
          final ValueChanged<Size>? report = widget.onCanvasSize;
          if (report != null) {
            // Reporting during layout would mutate parent state mid-build.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                report(size);
              }
            });
          }
          return Semantics(
            label: 'Writing canvas. Draw the character with your finger.',
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.medium),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.medium),
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (PointerDownEvent e) =>
                      _start(e.localPosition, size),
                  onPointerMove: (PointerMoveEvent e) =>
                      _extend(e.localPosition, size),
                  onPointerUp: (PointerUpEvent e) => _end(),
                  onPointerCancel: (PointerCancelEvent e) => _end(),
                  child: CustomPaint(
                    size: size,
                    painter: WritingCanvasPainter(
                      strokes: widget.strokes,
                      activeStroke: _active,
                      showGrid: widget.showGrid,
                      guideStrokes: widget.guideStrokes,
                      guideProgress: widget.guideProgress ??
                          (widget.guideStrokes?.length.toDouble() ?? 0),
                      inkColor: scheme.onSurface,
                      gridColor: scheme.outlineVariant,
                      guideColor: scheme.primary.withValues(alpha: 0.22),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
