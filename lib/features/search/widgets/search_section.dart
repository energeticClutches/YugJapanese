import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

class SearchSection extends StatelessWidget {
  const SearchSection({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // titleLarge to match the section-heading size used everywhere
        // else this same role appears (Dashboard, Analytics, Settings —
        // see settings_section.dart). Milestone 21, Issue 3.
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        ...children,
      ],
    );
  }
}
