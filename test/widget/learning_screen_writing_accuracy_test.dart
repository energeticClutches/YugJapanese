import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_learning/features/practice/learning_screen.dart';
import 'package:japanese_learning/features/progress/providers/progress_providers.dart';
import 'package:japanese_learning/features/review/providers/review_providers.dart';
import 'package:japanese_learning/features/settings/models/app_settings.dart';
import 'package:japanese_learning/features/settings/providers/settings_providers.dart';
import 'package:japanese_learning/features/settings/repositories/settings_repository.dart';
import 'package:japanese_learning/features/writing/widgets/writing_canvas.dart';

import '../fakes/fake_progress_repository.dart';
import '../fakes/fake_review_repository.dart';

/// In-memory [SettingsRepository] so `SettingsController` never touches Hive.
class _FakeSettingsRepository implements SettingsRepository {
  AppSettings _settings = AppSettings.defaults;

  @override
  Future<AppSettings> loadSettings() async => _settings;

  @override
  Future<void> saveSettings(AppSettings settings) async {
    _settings = settings;
  }

  @override
  Future<void> resetToDefaults() async {
    _settings = AppSettings.defaults;
  }
}

void main() {
  testWidgets('submitting a real drawn stroke on free writing scores above 0% '
      '(Milestone 31, Issue 1)', (WidgetTester tester) async {
    // The default 800x600 test surface clips the "Next"/"Check my
    // writing" buttons below the fold on this content-heavy screen.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          progressRepositoryProvider.overrideWithValue(
            FakeProgressRepository(),
          ),
          reviewRepositoryProvider.overrideWithValue(FakeReviewRepository()),
          settingsRepositoryProvider.overrideWithValue(
            _FakeSettingsRepository(),
          ),
        ],
        child: const MaterialApp(
          home: LearningScreen(lessonNumber: 1, contentId: 'hiragana'),
        ),
      ),
    );
    // `LoadingIndicator` is an indeterminate spinner (never-ending
    // animation), and so is `StrokeOrderPlayer` on the next step —
    // `pumpAndSettle` would time out waiting for either to stop, so every
    // wait here is a bounded pump loop instead.
    for (
      int i = 0;
      i < 20 && find.textContaining('Introduction').evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.textContaining('Introduction'), findsOneWidget);

    // Introduction -> Stroke Order -> Tracing -> Free Writing.
    for (int i = 0; i < 3; i++) {
      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.textContaining('Free Writing'), findsOneWidget);

    // Draw one real, reasonably long stroke across the canvas — not a tap,
    // so it survives `_denoise` and reaches the shape matcher.
    final Rect canvasRect = tester.getRect(find.byType(WritingCanvas));
    final Offset start = canvasRect.topLeft + const Offset(20, 20);
    final Offset end = canvasRect.bottomRight - const Offset(20, 20);
    final TestGesture gesture = await tester.startGesture(start);
    for (int i = 1; i <= 10; i++) {
      final Offset next = Offset.lerp(start, end, i / 10)!;
      await gesture.moveTo(next);
      await tester.pump(const Duration(milliseconds: 10));
    }
    await gesture.up();
    await tester.pump();

    await tester.tap(find.text('Check my writing'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // The bug forced every graded attempt to 0% via the "nothing was
    // drawn" fallback message — assert both the score and the message to
    // pin down which one regresses.
    expect(find.text('0%'), findsNothing);
    expect(
      find.textContaining('Finish the character before submitting'),
      findsNothing,
    );
  });
}
