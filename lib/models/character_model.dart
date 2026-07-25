import '../features/learning/models/kanji_example.dart';

class CharacterModel {
  const CharacterModel({
    required this.id,
    required this.character,
    required this.romaji,
    required this.englishName,
    required this.strokeCount,
    required this.lessonNumber,
    required this.unicode,
    required this.isLearned,
    required this.audioAsset,
    this.secondaryReadings = const <String>[],
    this.kunReadings = const <String>[],
    this.radical,
    this.grade,
    this.jlptLevel,
    this.examples = const <KanjiExample>[],
    this.notes,
  });

  final String id;
  final String character;
  final String romaji;
  final String englishName;
  final int strokeCount;
  final int lessonNumber;
  final String unicode;
  final bool isLearned;
  final String audioAsset;

  /// Optional richer metadata used by Kanji (and left empty/null by
  /// Hiragana and Katakana, which don't provide these JSON fields).
  final List<String> secondaryReadings;
  final List<String> kunReadings;
  final String? radical;
  final int? grade;
  final String? jlptLevel;
  final List<KanjiExample> examples;
  final String? notes;

  factory CharacterModel.fromJson(Map<String, dynamic> json) {
    return CharacterModel(
      id: json['id'] as String,
      character: json['character'] as String,
      romaji: json['romaji'] as String,
      englishName: json['englishName'] as String,
      strokeCount: json['strokeCount'] as int,
      lessonNumber: json['lessonNumber'] as int,
      unicode: json['unicode'] as String,
      isLearned: json['isLearned'] as bool? ?? false,
      audioAsset: json['audioAsset'] as String,
      secondaryReadings: (json['secondaryReadings'] as List<dynamic>?)
              ?.map((dynamic e) => e as String)
              .toList() ??
          const <String>[],
      kunReadings: (json['kunReadings'] as List<dynamic>?)
              ?.map((dynamic e) => e as String)
              .toList() ??
          const <String>[],
      radical: json['radical'] as String?,
      grade: json['grade'] as int?,
      jlptLevel: json['jlptLevel'] as String?,
      examples: (json['examples'] as List<dynamic>?)
              ?.map(
                (dynamic e) => KanjiExample.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <KanjiExample>[],
      notes: json['notes'] as String?,
    );
  }
}
