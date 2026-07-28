import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_learning/features/review/widgets/review_card.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  group('ReviewCard (Milestone 23, Issue 1)', () {
    testWidgets('renders the script and lesson, not a bare glyph', (
      WidgetTester tester,
    ) async {
      // The screen used to build its title as
      // 'Lesson ${lesson.characters.first.character}' — i.e. "Lesson あ" —
      // naming neither the script nor the lesson number.
      await tester.pumpWidget(
        wrap(
          ReviewCard(
            title: 'Hiragana · Lesson 1',
            subtitle: 'Vowels · Due today',
            onTap: () {},
          ),
        ),
      );

      expect(find.text('Hiragana · Lesson 1'), findsOneWidget);
      expect(find.text('Vowels · Due today'), findsOneWidget);
      expect(find.text('Lesson あ'), findsNothing);
    });

    testWidgets('renders without a subtitle', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(ReviewCard(title: 'Kanji · Lesson 3', onTap: () {})),
      );

      expect(find.text('Kanji · Lesson 3'), findsOneWidget);
    });

    testWidgets('is tappable', (WidgetTester tester) async {
      int taps = 0;
      await tester.pumpWidget(
        wrap(
          ReviewCard(
            title: 'Katakana · Lesson 2',
            subtitle: 'Ka Row · 3 days overdue',
            onTap: () => taps++,
          ),
        ),
      );

      await tester.tap(find.byType(ReviewCard));
      await tester.pump();

      expect(taps, 1);
    });
  });
}
