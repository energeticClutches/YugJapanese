class AchievementProgress {
  const AchievementProgress({
    required this.achievementId,
    required this.isUnlocked,
    this.unlockedAt,
  });

  final String achievementId;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  AchievementProgress copyWith({
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return AchievementProgress(
      achievementId: achievementId,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'achievementId': achievementId,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }

  factory AchievementProgress.fromMap(Map<String, dynamic> map) {
    return AchievementProgress(
      achievementId: map['achievementId'] as String,
      isUnlocked: map['isUnlocked'] as bool,
      unlockedAt: map['unlockedAt'] == null
          ? null
          : DateTime.parse(map['unlockedAt'] as String),
    );
  }
}
