import 'package:japanese_learning/features/achievements/models/achievement_progress.dart';
import 'package:japanese_learning/features/achievements/repositories/achievement_repository.dart';

/// Simple in-memory [AchievementRepository] for tests — no Hive involved.
class FakeAchievementRepository implements AchievementRepository {
  final Map<String, AchievementProgress> _store =
      <String, AchievementProgress>{};

  @override
  Future<List<AchievementProgress>> getAllProgress() async =>
      _store.values.toList(growable: false);

  @override
  Future<AchievementProgress?> getProgress(String achievementId) async =>
      _store[achievementId];

  @override
  Future<void> saveProgress(AchievementProgress progress) async {
    _store[progress.achievementId] = progress;
  }
}
