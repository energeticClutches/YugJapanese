import 'package:japanese_learning/features/analytics/models/analytics_snapshot.dart';
import 'package:japanese_learning/features/analytics/repositories/analytics_repository.dart';

/// Simple in-memory [AnalyticsRepository] for tests — no Hive involved.
class FakeAnalyticsRepository implements AnalyticsRepository {
  AnalyticsSnapshot? _snapshot;

  @override
  Future<AnalyticsSnapshot?> getSnapshot() async => _snapshot;

  @override
  Future<void> saveSnapshot(AnalyticsSnapshot snapshot) async {
    _snapshot = snapshot;
  }
}
