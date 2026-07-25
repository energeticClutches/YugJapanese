import '../models/achievement_progress.dart';

abstract class AchievementRepository {
  Future<List<AchievementProgress>> getAllProgress();

  Future<AchievementProgress?> getProgress(String achievementId);

  Future<void> saveProgress(AchievementProgress progress);
}
