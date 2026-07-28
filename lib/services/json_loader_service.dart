import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/lesson_model.dart';

class JsonLoaderService {
  const JsonLoaderService();

  Future<List<LessonModel>> loadHiraganaLessons() =>
      loadLessons('assets/data/hiragana_lessons.json');

  /// Loads a lessons JSON asset matching the `{ "lessons": [...] }` schema
  /// shared by every script (see `assets/data/hiragana_lessons.json`).
  Future<List<LessonModel>> loadLessons(String assetPath) async {
    try {
      final String jsonString = await rootBundle.loadString(assetPath);
      final dynamic decoded = jsonDecode(jsonString);
      final List<dynamic> lessonsJson =
          (decoded as Map<String, dynamic>)['lessons'] as List<dynamic>;

      return lessonsJson
          .map(
            (dynamic item) =>
                LessonModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false);
    } catch (_) {
      return <LessonModel>[];
    }
  }
}
