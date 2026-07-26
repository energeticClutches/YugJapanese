import 'package:hive/hive.dart';

import '../models/analytics_snapshot.dart';
import 'analytics_repository.dart';

class HiveAnalyticsRepository implements AnalyticsRepository {
  const HiveAnalyticsRepository();

  static const String boxName = 'analytics_snapshot';
  static const String _key = 'snapshot';

  Box<dynamic> get _box => Hive.box<dynamic>(boxName);

  @override
  Future<AnalyticsSnapshot?> getSnapshot() async {
    final value = _box.get(_key);
    if (value is! Map) {
      return null;
    }
    return AnalyticsSnapshot.fromMap(Map<String, dynamic>.from(value));
  }

  @override
  Future<void> saveSnapshot(AnalyticsSnapshot snapshot) {
    return _box.put(_key, snapshot.toMap());
  }
}
