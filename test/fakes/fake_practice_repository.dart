import 'package:japanese_learning/features/quiz/models/practice_result.dart';
import 'package:japanese_learning/features/quiz/repositories/practice_repository.dart';

/// Simple in-memory [PracticeRepository] for tests — no Hive involved.
class FakePracticeRepository implements PracticeRepository {
  final Map<String, PracticeResult> _store = <String, PracticeResult>{};

  @override
  Future<List<PracticeResult>> getAllResults() async =>
      _store.values.toList(growable: false);

  @override
  Future<void> saveResult(PracticeResult result) async {
    _store[result.id] = result;
  }
}
