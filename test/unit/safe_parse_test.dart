import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_learning/core/utils/safe_parse.dart';

class _Point {
  const _Point(this.x, this.y);
  final int x;
  final int y;

  factory _Point.fromMap(Map<String, dynamic> map) {
    return _Point(map['x'] as int, map['y'] as int);
  }
}

void main() {
  group('safeParse', () {
    test('returns the parsed value for well-formed data', () {
      final result = safeParse(<String, dynamic>{'x': 1, 'y': 2}, _Point.fromMap);

      expect(result, isNotNull);
      expect(result!.x, 1);
      expect(result.y, 2);
    });

    test('returns null instead of throwing for a missing field', () {
      final result = safeParse(<String, dynamic>{'x': 1}, _Point.fromMap);

      expect(result, isNull);
    });

    test('returns null instead of throwing for a wrong-typed field', () {
      final result =
          safeParse(<String, dynamic>{'x': 'not a number', 'y': 2}, _Point.fromMap);

      expect(result, isNull);
    });
  });
}
