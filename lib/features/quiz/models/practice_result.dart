/// Persisted summary of one completed practice session ("Persist session
/// summaries for analytics"). Deliberately flat — no nested `LearningItem`/
/// `PracticeQuestion` data — matching the `toMap`/`fromMap` convention used
/// by every other Hive-backed model in this codebase.
class PracticeResult {
  const PracticeResult({
    required this.id,
    required this.modeId,
    required this.contentIds,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.accuracy,
    required this.startTime,
    required this.endTime,
    this.incorrectItemIds = const <String>[],
  });

  final String id;
  final String modeId;
  final List<String> contentIds;
  final int totalQuestions;
  final int correctAnswers;
  final int incorrectAnswers;
  final double accuracy;
  final DateTime startTime;
  final DateTime endTime;

  /// Ids of learning items answered incorrectly in this session — the
  /// signal `PracticeGenerator`'s Weak Items mode reads across all results.
  final List<String> incorrectItemIds;

  Duration get duration => endTime.difference(startTime);

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'modeId': modeId,
      'contentIds': contentIds,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'incorrectAnswers': incorrectAnswers,
      'accuracy': accuracy,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'incorrectItemIds': incorrectItemIds,
    };
  }

  factory PracticeResult.fromMap(Map<String, dynamic> map) {
    return PracticeResult(
      id: map['id'] as String,
      modeId: map['modeId'] as String,
      contentIds: (map['contentIds'] as List<dynamic>)
          .map((dynamic e) => e as String)
          .toList(),
      totalQuestions: map['totalQuestions'] as int,
      correctAnswers: map['correctAnswers'] as int,
      incorrectAnswers: map['incorrectAnswers'] as int,
      accuracy: (map['accuracy'] as num).toDouble(),
      startTime: DateTime.parse(map['startTime'] as String),
      endTime: DateTime.parse(map['endTime'] as String),
      incorrectItemIds: (map['incorrectItemIds'] as List<dynamic>?)
              ?.map((dynamic e) => e as String)
              .toList() ??
          const <String>[],
    );
  }
}
