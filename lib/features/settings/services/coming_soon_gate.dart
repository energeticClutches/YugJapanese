/// Rate-limits "this isn't built yet" notices so mashing a placeholder
/// button doesn't queue a SnackBar per tap.
///
/// Session-only: the cooldown is not persisted, so it resets on app
/// restart. There is nothing here worth surviving a restart for — it
/// exists purely to stop repeat taps in one sitting from spamming the
/// user, not to track feature usage across sessions.
class ComingSoonGate {
  static const Duration cooldown = Duration(minutes: 15);

  final Map<String, DateTime> _lastShown = <String, DateTime>{};

  /// Whether a notice for [feature] should be shown right now. Each
  /// feature key has its own independent cooldown, so exhausting Export's
  /// window has no effect on Import's.
  bool shouldShow(String feature, {DateTime? now}) {
    final DateTime current = now ?? DateTime.now();
    final DateTime? last = _lastShown[feature];
    if (last != null && current.difference(last) < cooldown) {
      return false;
    }
    _lastShown[feature] = current;
    return true;
  }
}
