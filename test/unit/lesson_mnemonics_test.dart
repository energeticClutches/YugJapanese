import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_learning/models/character_model.dart';

const List<String> _scripts = <String>['hiragana', 'katakana', 'kanji'];

List<Map<String, dynamic>> _charactersOf(String script) {
  final Map<String, dynamic> raw = jsonDecode(
    File('assets/data/${script}_lessons.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  return <Map<String, dynamic>>[
    for (final dynamic lesson in raw['lessons'] as List<dynamic>)
      for (final dynamic c
          in (lesson as Map<String, dynamic>)['characters'] as List<dynamic>)
        c as Map<String, dynamic>,
  ];
}

void main() {
  group('lesson mnemonics', () {
    test('every character in every script has a hint', () {
      for (final String script in _scripts) {
        final List<Map<String, dynamic>> characters = _charactersOf(script);
        expect(characters, isNotEmpty, reason: '$script has no characters');
        for (final Map<String, dynamic> c in characters) {
          final Object? notes = c['notes'];
          expect(
            notes,
            isA<String>(),
            reason: 'missing notes for ${c['character']} ($script)',
          );
          expect(
            (notes as String).trim(),
            isNotEmpty,
            reason: 'blank notes for ${c['character']} ($script)',
          );
        }
      }
    });

    test('hints stay short enough to sit inline in the lesson flow', () {
      for (final String script in _scripts) {
        for (final Map<String, dynamic> c in _charactersOf(script)) {
          expect(
            (c['notes'] as String).length,
            lessThanOrEqualTo(80),
            reason: 'hint too long for ${c['character']} ($script)',
          );
        }
      }
    });

    test('hints are distinct, so none is a copy-paste placeholder', () {
      for (final String script in _scripts) {
        final List<String> notes = <String>[
          for (final Map<String, dynamic> c in _charactersOf(script))
            c['notes'] as String,
        ];
        expect(notes.toSet().length, notes.length, reason: '$script has dupes');
      }
    });

    test('CharacterModel parses the hint through fromJson', () {
      final Map<String, dynamic> first = _charactersOf('hiragana').first;
      final CharacterModel model = CharacterModel.fromJson(first);
      expect(model.notes, isNotNull);
      expect(model.notes, first['notes']);
    });
  });
}
