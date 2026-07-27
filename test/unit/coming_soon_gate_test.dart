import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_learning/features/settings/services/coming_soon_gate.dart';

void main() {
  group('ComingSoonGate (Milestone 21, Issue 1)', () {
    test('shows on the first tap', () {
      final ComingSoonGate gate = ComingSoonGate();
      expect(gate.shouldShow('Export progress'), isTrue);
    });

    test('suppresses repeat taps within the cooldown', () {
      final ComingSoonGate gate = ComingSoonGate();
      final DateTime start = DateTime(2026, 1, 1, 12);
      expect(gate.shouldShow('Export progress', now: start), isTrue);
      expect(
        gate.shouldShow(
          'Export progress',
          now: start.add(const Duration(minutes: 1)),
        ),
        isFalse,
      );
      expect(
        gate.shouldShow(
          'Export progress',
          now: start.add(const Duration(minutes: 14, seconds: 59)),
        ),
        isFalse,
      );
    });

    test('shows again once the cooldown has elapsed', () {
      final ComingSoonGate gate = ComingSoonGate();
      final DateTime start = DateTime(2026, 1, 1, 12);
      expect(gate.shouldShow('Export progress', now: start), isTrue);
      expect(
        gate.shouldShow(
          'Export progress',
          now: start.add(const Duration(minutes: 15, seconds: 1)),
        ),
        isTrue,
      );
    });

    test('Export and Import cool down independently', () {
      final ComingSoonGate gate = ComingSoonGate();
      final DateTime start = DateTime(2026, 1, 1, 12);
      expect(gate.shouldShow('Export progress', now: start), isTrue);
      expect(
        gate.shouldShow(
          'Import progress',
          now: start.add(const Duration(minutes: 1)),
        ),
        isTrue,
        reason: 'exhausting Export\'s cooldown must not affect Import',
      );
    });
  });
}
