import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/utils/responsive.dart';

/// Lays out [children] in rows of equal-width cells, computed from the
/// available width and a column count that adapts to screen size and
/// orientation.
///
/// A bare `Wrap` sizes each child to its own intrinsic content width —
/// which is what made dashboard tiles look raggedly aligned: two
/// [StatisticCard]s side by side with different label lengths ("Lessons
/// Completed" vs "Average Accuracy") ended up different widths, so
/// neither their left nor right edges lined up, and the same content
/// reflowed into a different, uneven number of columns depending on
/// available width. Wrapping each child in a computed-width [SizedBox]
/// fixes the width while leaving height intrinsic, so wrapped text still
/// can't overflow the way a fixed-aspect-ratio `GridView` would risk.
///
/// Column count: 2 on a mobile-portrait screen, 3 for a tablet or a
/// mobile screen in landscape — using [Responsive], which existed but
/// had no callers before this.
class EqualWidthGrid extends StatelessWidget {
  const EqualWidthGrid({
    super.key,
    required this.children,
    this.spacing = AppSpacing.md,
    this.runSpacing = AppSpacing.md,
  });

  final List<Widget> children;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    final bool wideRow =
        Responsive.isTablet(context) || Responsive.isLandscape(context);
    final int columns = wideRow ? 3 : 2;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double totalSpacing = spacing * (columns - 1);
        final double cardWidth =
            (constraints.maxWidth - totalSpacing) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final Widget child in children)
              SizedBox(width: cardWidth, child: child),
          ],
        );
      },
    );
  }
}
