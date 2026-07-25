import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import 'achievement_card.dart';

class AchievementGridItem {
  const AchievementGridItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.isUnlocked,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool isUnlocked;
}

class AchievementGrid extends StatelessWidget {
  const AchievementGrid({super.key, required this.items});

  final List<AchievementGridItem> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        for (final AchievementGridItem item in items)
          SizedBox(
            width: 200,
            child: AchievementCard(
              title: item.title,
              description: item.description,
              icon: item.icon,
              isUnlocked: item.isUnlocked,
            ),
          ),
      ],
    );
  }
}
