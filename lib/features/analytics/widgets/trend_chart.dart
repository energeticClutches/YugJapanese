import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// One line series for [TrendChart]. `null` entries are gaps (no data for
/// that point) — the line breaks rather than interpolating across them.
class TrendSeries {
  const TrendSeries({
    required this.label,
    required this.color,
    required this.values,
  });

  final String label;
  final Color color;
  final List<double?> values;
}

/// A minimal line chart drawn with [CustomPainter] — no charting package is
/// approved for this project. The data-in/chart-out API (`List<TrendSeries>`
/// in, a widget out) keeps the painting swappable for a real charting
/// package later without touching callers.
class TrendChart extends StatelessWidget {
  const TrendChart({
    super.key,
    required this.series,
    this.height = 160,
    this.maxY = 100,
  });

  final List<TrendSeries> series;
  final double height;
  final double maxY;

  @override
  Widget build(BuildContext context) {
    final bool hasAnyData = series.any(
      (TrendSeries s) => s.values.any((double? v) => v != null),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: height,
          width: double.infinity,
          child: hasAnyData
              ? CustomPaint(
                  painter: _TrendChartPainter(
                    series: series,
                    maxY: maxY,
                    gridColor: Theme.of(context).colorScheme.outline,
                  ),
                )
              : Center(
                  child: Text(
                    'Not enough history yet.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          children: [
            for (final TrendSeries s in series)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 10, height: 10, color: s.color),
                  const SizedBox(width: 4),
                  Text(s.label, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  _TrendChartPainter({
    required this.series,
    required this.maxY,
    required this.gridColor,
  });

  final List<TrendSeries> series;
  final double maxY;

  /// Resolved from the active theme by the parent — a [CustomPainter] has no
  /// [BuildContext] of its own, so the grid colour has to be passed in.
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final double y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    for (final TrendSeries trendSeries in series) {
      final int n = trendSeries.values.length;
      if (n < 2) {
        continue;
      }

      final Paint linePaint = Paint()
        ..color = trendSeries.color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round;

      Path? path;
      bool wasGap = true;
      for (int i = 0; i < n; i++) {
        final double? value = trendSeries.values[i];
        if (value == null) {
          wasGap = true;
          continue;
        }
        final double x = size.width * i / (n - 1);
        final double y = size.height * (1 - (value.clamp(0, maxY) / maxY));
        if (wasGap) {
          path ??= Path();
          path.moveTo(x, y);
          wasGap = false;
        } else {
          path!.lineTo(x, y);
        }
      }
      if (path != null) {
        canvas.drawPath(path, linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) {
    return oldDelegate.series != series ||
        oldDelegate.maxY != maxY ||
        oldDelegate.gridColor != gridColor;
  }
}
