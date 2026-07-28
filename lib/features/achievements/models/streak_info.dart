class StreakInfo {
  const StreakInfo({
    required this.currentStreak,
    required this.longestStreak,
    this.lastActiveDate,
  });

  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActiveDate;

  static const StreakInfo empty = StreakInfo(
    currentStreak: 0,
    longestStreak: 0,
  );
}
