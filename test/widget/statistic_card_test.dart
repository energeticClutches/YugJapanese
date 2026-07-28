import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_learning/features/analytics/widgets/statistic_card.dart';

void main() {
  testWidgets('StatisticCard renders its icon, label, and value', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatisticCard(
            icon: Icons.check_circle_outline,
            label: 'Lessons Completed',
            value: '2',
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    expect(find.text('Lessons Completed'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });
}
