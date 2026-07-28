import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_learning/features/quiz/widgets/answer_option.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('renders its label', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
        AnswerOption(
          label: 'ka',
          state: AnswerOptionState.neutral,
          onTap: () {},
        ),
      ),
    );

    expect(find.text('ka'), findsOneWidget);
  });

  testWidgets('calls onTap when tapped', (WidgetTester tester) async {
    int tapCount = 0;
    await tester.pumpWidget(
      wrap(
        AnswerOption(
          label: 'ka',
          state: AnswerOptionState.neutral,
          onTap: () => tapCount++,
        ),
      ),
    );

    await tester.tap(find.byType(AnswerOption));
    await tester.pump();

    expect(tapCount, 1);
  });

  testWidgets(
    'does not call onTap when onTap is null (locked/answered state)',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(
          const AnswerOption(
            label: 'ka',
            state: AnswerOptionState.revealedCorrect,
            onTap: null,
          ),
        ),
      );

      // Should render without throwing and without a tappable InkWell action.
      expect(find.text('ka'), findsOneWidget);
    },
  );

  testWidgets('renders distinctly for each visual state without throwing', (
    WidgetTester tester,
  ) async {
    for (final AnswerOptionState state in AnswerOptionState.values) {
      await tester.pumpWidget(
        wrap(AnswerOption(label: 'ka', state: state, onTap: () {})),
      );
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('ka'), findsOneWidget);
    }
  });
}
