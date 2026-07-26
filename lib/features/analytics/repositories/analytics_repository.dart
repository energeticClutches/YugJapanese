import '../models/analytics_snapshot.dart';

abstract class AnalyticsRepository {
  Future<AnalyticsSnapshot?> getSnapshot();

  Future<void> saveSnapshot(AnalyticsSnapshot snapshot);
}
