enum AchievementCriteria {
  lessonsCompleted,
  longestStreakDays,
  reviewsCompleted,
  averageAccuracy,
}

/// Static definition of an achievement. Instances live in
/// [AchievementService.catalog]; only unlock state ([AchievementProgress])
/// is persisted.
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconKey,
    required this.criteria,
    required this.threshold,
  });

  final String id;
  final String title;
  final String description;

  /// Key resolved to a concrete icon by the widget layer, keeping this
  /// model free of Flutter dependencies.
  final String iconKey;

  final AchievementCriteria criteria;
  final double threshold;
}
