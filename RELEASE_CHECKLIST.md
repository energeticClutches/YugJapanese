# Release Checklist — v1.0.0

Status as of Milestone 20 (2026-07-26), re-verified and corrected by the
Milestone 26 (RC1) audit and Milestone 26.1 fix (2026-07-28). Items marked
⬜ are **blockers for a public Play Store release** and are intentionally
deferred out of this milestone's scope.

## Code quality

- [x] `flutter analyze` reports no issues.
- [x] `flutter test` — all 94 tests pass (unit, widget, and flow; grown
      from 36 at Milestone 20 as the app grew — re-confirmed passing as
      of Milestone 26.1).
- [x] No stray debug printing on the startup or interaction paths.
      (`debugPrint` appears only inside `safe_parse`'s `kDebugMode` guard.)
- [x] No TODO/FIXME comments blocking v1.0. The former `TODO` markers in
      `android/app/build.gradle.kts` were resolved: the application ID is
      now real, and the debug-signing line carries an explicit note that
      the choice is intentional for v1.0.
- [x] No unused dependencies. Every package in `pubspec.yaml` is used;
      `flutter_launcher_icons` and `flutter_native_splash` are correctly
      scoped to `dev_dependencies`.
- [x] All bundled assets are referenced, and every referenced asset either
      exists or degrades gracefully (see Functionality below).

## Functionality

Verified on the Android emulator against a **release build**, from a
clean install:

- [x] Fresh install launches successfully under the new application ID.
- [x] Upgrade-over-existing-install preserves data.
- [x] Progress survives a full process kill and cold restart
      (verified: "Lessons In Progress" 0 → 1 and the dashboard CTA
      changing from "Start Learning" to "Continue" persisted across a
      `force-stop` and relaunch).
- [x] Dashboard — aggregates, empty states, and navigation.
- [x] Search — matches across Hiragana, Katakana, and Kanji; live
      filtering; navigation from a result into the correct character.
- [x] Learning flow — lesson steps, character navigation, stroke guides.
- [x] Audio — playback confirmed (audio frames delivered, no errors);
      characters without a bundled recording correctly hide the control.
- [x] Practice/quiz — a full 10-question Recognition session, scored and
      timed, with mistakes feeding "Areas to Review", and the best score
      persisted and shown on the mode card.
- [x] Analytics — overall completion, per-script breakdown, live streak.
- [x] Settings — all preference groups, Diagnostics (storage usage,
      licenses), and the new Legal section.
- [x] Legal — Privacy Policy, Terms of Use, and Credits render in-app.
- [x] Offline — the app makes no network requests. **Flagged false by the
      Milestone 26 (RC1) audit** (`google_fonts` fetched `NotoSansJP` from
      `fonts.gstatic.com` at runtime), **fixed in Milestone 26.1**: the
      font is now bundled locally (`assets/fonts/NotoSansJP-Variable.ttf`)
      and `google_fonts` was removed from the dependency tree entirely.
      Re-verified with wifi and mobile data both disabled: zero requests
      to `fonts.gstatic.com`/`fonts.google.com` in logcat. See
      `RC1_VERIFICATION_REPORT.md`.
- [x] No uncaught exceptions in logcat across the entire walkthrough.
      **Flagged false by the Milestone 26 (RC1) audit** (the network
      fetch above threw an unhandled exception on every cold start),
      **fixed in Milestone 26.1**: re-ran the full offline walkthrough
      against the rebuilt release APK — zero `E/flutter` lines, zero
      unhandled exceptions, zero crashes.

## UI

- [x] Responsive layouts (960dp content cap; practice mode cards adapt to
      narrow screens).
- [x] Accessible: icon controls carry tooltips, touch targets meet the
      48dp minimum, and text scaling is clamped to 1.6x so large system
      fonts cannot break card layouts.
- [x] Consistent Material 3 theming via shared spacing/radius/color/
      typography tokens, in both light and dark themes.
- [x] Targeted animations (quiz answer reveal, achievement unlock).
- [x] Empty and error states are handled by shared widgets rather than
      ad hoc per screen.

## Release

- [x] Version set to `1.0.0+1` in `pubspec.yaml`.
- [x] Application ID is `com.energeticclutches.yugjapanese`; no
      `com.example.*` references remain anywhere in the project.
- [x] App display name is "YugJapanese".
- [x] Launcher icons generated for all Android densities, including an
      adaptive icon.
- [x] Splash screen generated with light and dark variants.
- [x] Legal documents bundled in-app and present at the repository root.
- [x] `flutter build apk --release` succeeds (57.2 MB — up from 52.2 MB
      after Milestone 26.1 bundled the ~9.1 MB Noto Sans JP variable font
      directly into the APK instead of fetching it at runtime).
- [x] `flutter build appbundle` succeeds (56.0 MB).

## Resolved blockers

- [x] ~~Stop `google_fonts` from fetching `NotoSansJP` over the network at
      runtime.~~ Found by the Milestone 26 (RC1) audit, **fixed in
      Milestone 26.1**: `NotoSansJP-Variable.ttf` (SIL OFL 1.1, official
      Google Fonts source) is now bundled directly in `assets/fonts/` and
      declared as a `fonts:` entry in `pubspec.yaml`; `app_typography.dart`
      and `app_theme.dart` reference it by family name instead of calling
      `GoogleFonts.notoSansJp()`/`notoSansJpTextTheme()`; the `google_fonts`
      package was removed from `pubspec.yaml` entirely (confirmed via
      `flutter pub get`: "These packages are no longer being depended on:
      google_fonts"). Re-verified end to end: `flutter analyze` clean,
      `flutter test` 94/94, both release builds succeed, and a fresh
      offline install (wifi + mobile data both disabled) produces zero
      requests to `fonts.gstatic.com`/`fonts.google.com` and zero
      unhandled exceptions in logcat. Full detail in
      `RC1_VERIFICATION_REPORT.md`.

## Deferred — required before publishing

- [ ] **Create a production upload keystore.** Release builds are
      currently signed with the debug key so that APK and AAB artifacts
      remain installable for testing. This is intentional for v1.0
      development and is **not** publishable. Before submitting to Google
      Play:
      1. Generate an upload keystore with `keytool`.
      2. Store its credentials in `android/key.properties` and add that
         file to `.gitignore` — never commit keystores or passwords.
      3. Add a `signingConfigs.release` block in
         `android/app/build.gradle.kts` reading from those properties and
         point the `release` build type at it, replacing the
         `signingConfigs.getByName("debug")` line.
      4. Rebuild and verify the AAB is signed with the upload key.
- [ ] **Replace the placeholder branding.** The current launcher icon and
      splash logo are minimal original placeholder artwork (a torii-gate
      silhouette drawn programmatically in the app's theme colors, source
      in `assets/branding/`). They are deliberately simple and easy to
      swap; commission or design real branding before a store listing.
- [ ] **Verify startup performance on physical hardware.** Cold start
      measures ~3.5–5.3s on the x86 Android emulator, dominated by the
      first cold open of the 8 Hive boxes (~3.4–5.3s of it). This was
      A/B tested: opening the boxes concurrently versus sequentially made
      no measurable difference, so it is emulator disk I/O rather than the
      concurrency strategy. Real hardware is expected to be substantially
      faster, but this has not been measured — confirm on a physical
      device, and if it is still slow, the lever is opening fewer boxes
      eagerly (e.g. deferring the analytics and practice boxes until those
      screens are first opened).
- [ ] **Physical-device and tablet testing.** All verification to date has
      been on a single phone-profile emulator. 7"/10" tablet layouts and
      landscape orientation are reasoned about via the 960dp content cap
      and code review, not physically verified.
- [ ] **Store assets** — feature graphic, screenshots, store description,
      content rating questionnaire, and data-safety form. Not started;
      explicitly out of scope for Milestone 20.
- [ ] **iOS support** — this project has no `ios/` directory. Launcher
      icons and splash screens for iOS are deferred to a future milestone
      and will require scaffolding the platform target first.

## Notes

- The build emits a benign warning: `Expected to find fonts for
  (packages/cupertino_icons/CupertinoIcons, MaterialIcons), but found
  (MaterialIcons)`. No app code references `CupertinoIcons`; the warning
  comes from Flutter's bundled Cupertino widgets. Adding the
  `cupertino_icons` package would silence it but provides no value for
  this Android-only Material 3 app, so it was left alone.
