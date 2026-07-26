import '../models/practice_result.dart';

abstract class PracticeRepository {
  Future<List<PracticeResult>> getAllResults();

  Future<void> saveResult(PracticeResult result);
}
