import 'package:hive/hive.dart';

import '../models/practice_result.dart';
import 'practice_repository.dart';

class HivePracticeRepository implements PracticeRepository {
  const HivePracticeRepository();

  static const String boxName = 'practice_results';

  Box<dynamic> get _box => Hive.box<dynamic>(boxName);

  @override
  Future<List<PracticeResult>> getAllResults() async {
    return _box.values
        .whereType<Map>()
        .map(
          (Map value) =>
              PracticeResult.fromMap(Map<String, dynamic>.from(value)),
        )
        .toList(growable: false);
  }

  @override
  Future<void> saveResult(PracticeResult result) {
    return _box.put(result.id, result.toMap());
  }
}
