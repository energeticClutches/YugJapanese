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
    );
  }
}
