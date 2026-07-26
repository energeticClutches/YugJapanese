import 'dart:async';

import 'package:google_fonts/google_fonts.dart';

/// Runs before every test in this directory (Flutter's test runner picks
/// this file up automatically). `AppTypography` calls
/// `GoogleFonts.notoSansJpTextTheme()` on every access; without this,
/// `google_fonts` attempts a real network fetch in the test environment,
/// which hangs (no internet access) and makes any widget test using
/// `pumpAndSettle` time out waiting on an indeterminate loading spinner
/// that never resolves. Disabling runtime fetching makes it fall back to
/// the bundled default font immediately instead.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await testMain();
}
