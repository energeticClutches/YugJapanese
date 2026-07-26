import 'package:hive/hive.dart';

import '../../../core/utils/safe_parse.dart';
import '../models/achievement_progress.dart';
import 'achievement_repository.dart';

class HiveAchievementRepository implements AchievementRepository {
  const HiveAchievementRepository();

  static const String boxName = 'achievement_progress';

  Box<dynamic> get _box => Hive.box<dynamic>(boxName);

  @override
  Future<List<AchievementProgress>> getAllProgress() async {
    return _box.values
        .whereType<Map>()
        .map((Map value) => safeParse(value, AchievementProgress.fromMap))
        .whereType<AchievementProgress>()
        .toList(growable: false);
  }

  @override
  Future<AchievementProgress?> getProgress(String achievementId) async {
    final value = _box.get(achievementId);
    if (value is! Map) {
      return null;
    }
    return safeParse(value, AchievementProgress.fromMap);
  }

  @override
  Future<void> saveProgress(AchievementProgress progress) {
    return _box.put(progress.achievementId, progress.toMap());
  }
}
