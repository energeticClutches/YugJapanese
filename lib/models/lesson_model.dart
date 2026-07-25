import 'character_model.dart';

class LessonModel {
  const LessonModel({
    required this.lessonNumber,
    required this.title,
    required this.description,
    required this.characters,
  });

  final int lessonNumber;
  final String title;
  final String description;
  final List<CharacterModel> characters;

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      lessonNumber: json['lessonNumber'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      characters: (json['characters'] as List<dynamic>)
          .map((dynamic item) =>
              CharacterModel.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}
