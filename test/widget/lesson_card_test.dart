import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_learning/shared/widgets/lesson_card.dart';

void main() {
  Widget wrap(Widget child) =>
      MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

  LessonCard card({required String label, double? accuracy}) => LessonCard(
        lessonTitle: 'Lesson 1',
        lessonSubtitle: 'Vowels',
        characters: const <String>['あ'],
        progressLabel: label,
        writingAccuracy: accuracy,
        onStartPressed: () {},
      );

  group('LessonCard status and accuracy (BUG-009)', () {
    testWidgets('a completed lesson scored 0% never shows 100%',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(card(label: 'Completed - Practice Again', accuracy: 0)),
      );

      // The card previously rendered `isCompleted` as "100%" next to an
      // accuracy-derived label, reading as a perfect score on a failed
      // attempt.
      expect(find.textContaining('100%'), findsNothing);
      expect(find.text('Completed - Practice Again'), findsOneWidget);
      expect(find.text('Writing accuracy: 0%'), findsOneWidget);
    });

    testWidgets('accuracy is labelled, not bare, so it cannot be misread',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(card(label: 'Completed', accuracy: 0.82)),
      );

      expect(find.text('Writing accuracy: 82%'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('a genuine 100% attempt still reads as 100%',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrap(card(label: 'Completed', accuracy: 1)));

      expect(find.text('Writing accuracy: 100%'), findsOneWidget);
    });

    testWidgets('an unfinished lesson shows status only, with no percentage',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrap(card(label: 'In Progress')));

      expect(find.text('In Progress'), findsOneWidget);
      // Nothing to report yet — the old card claimed "In Progress - 0%",
      // which read as a scored attempt rather than an unfinished one.
      expect(find.textContaining('%'), findsNothing);
    });

    testWidgets('an untouched lesson shows status only',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrap(card(label: 'Not Started')));

      expect(find.text('Not Started'), findsOneWidget);
      expect(find.textContaining('%'), findsNothing);
    });
  });
}
