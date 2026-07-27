import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';

/// A titled card grouping related [SettingsTile]-style rows, used for every
/// section of the settings screen (Appearance, Learning, Feedback, ...).
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // titleLarge, not titleMedium: every other screen (Dashboard,
        // Analytics) renders this same role — a section-group heading
        // within a scrollable body — one step larger. Settings and Search
        // (search_section.dart) were the only two screens a size down,
        // which is what read as "several headings appear noticeably
        // smaller than expected" (Milestone 21, Issue 3).
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        Material(
          color: colorScheme.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.large),
            side: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: _withDividers(children),
          ),
        ),
      ],
    );
  }

  List<Widget> _withDividers(List<Widget> tiles) {
    final List<Widget> result = <Widget>[];
    for (int i = 0; i < tiles.length; i++) {
      if (i > 0) {
        result.add(const Divider(height: 1));
      }
      result.add(tiles[i]);
    }
    return result;
  }
}
