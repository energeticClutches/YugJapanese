import 'package:flutter/foundation.dart';

/// Attempts to parse [value] via [fromMap], returning `null` instead of
/// throwing if the stored record is malformed (a missing/mistyped field,
/// e.g. from manual tampering or a future schema change). Every Hive
/// repository's read path uses this so one corrupted record is skipped
/// instead of crashing the whole read.
T? safeParse<T>(
  Map<dynamic, dynamic> value,
  T Function(Map<String, dynamic> map) fromMap,
) {
  try {
    return fromMap(Map<String, dynamic>.from(value));
  } catch (error, stackTrace) {
    if (kDebugMode) {
      debugPrint('safeParse: failed to parse $T — $error\n$stackTrace');
    }
    return null;
  }
}
