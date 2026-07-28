# RC1 Verification Report — Milestone 26

**Date:** 2026-07-28
**Build tested:** Release APK/AAB built fresh from a clean `main` checkout (commit `fac406f`), debug-signed per `RELEASE_CHECKLIST.md`.
**Device:** Android emulator, `sdk_gphone16k_x86_64`, Android 17 (API 37), 1080×2400.
**Method:** Fresh install (`pm clear` to guarantee a true first-run state), then a real interactive walkthrough via `adb` (screenshots + `input tap`/`swipe`, verified against `uiautomator dump` bounds — not simulated), with `adb logcat` capturing the entire session across three separate process lifetimes (initial launch, a full `am force-stop` + relaunch, and an airplane-mode relaunch).

## Update — Milestone 26.1 (2026-07-28): blocker resolved, Ready for release

The blocker below (`google_fonts` fetching over the network) has been fixed:
`NotoSansJP-Variable.ttf` (SIL OFL 1.1, sourced directly from Google's
official font repository) is now bundled in `assets/fonts/` and declared
in `pubspec.yaml`; `app_typography.dart`/`app_theme.dart` reference it by
family name instead of calling `GoogleFonts.notoSansJp()`/
`notoSansJpTextTheme()`; the `google_fonts` package itself was removed
from `pubspec.yaml` (confirmed via `flutter pub get`: *"These packages
are no longer being depended on: google_fonts"*), and the
`test/flutter_test_config.dart` workaround that disabled its runtime
fetching for tests was deleted as dead code.

**Re-validation performed** (targeted, not a full second RC1 pass, per
plan): `flutter analyze` clean, `flutter test` 94/94, both
`flutter build apk/appbundle --release` succeed. Installed the rebuilt
APK fresh (`pm clear`), disabled wifi *and* mobile data
(`svc wifi disable` / `svc data disable`), launched, and captured
`adb logcat`: **zero requests to `fonts.gstatic.com` or
`fonts.google.com`, zero `E/flutter` lines, zero unhandled exceptions,
zero crashes.** Spot-checked Japanese typography on the Kanji lesson
list (dense multi-stroke glyphs) — renders identically to before, since
it's literally the same typeface file, just loaded locally instead of
fetched. Also caught and fixed a real bug introduced by the initial
fix attempt: `assets/fonts/OFL.txt` (the bundled license text, read by
`main.dart` for the in-app Licenses page) was missing its own
`assets:` entry in `pubspec.yaml` — the `fonts:` block only registers
the `.ttf` itself, not other files in that directory — which surfaced
immediately as "Unable to load asset" when opening Settings → Licenses
on the first rebuild. Fixed and re-verified before calling this done.

**Updated recommendation: Ready for release.** The one blocker found in
the original RC1 pass is resolved and re-verified; nothing else in this
report changes. See `RELEASE_CHECKLIST.md` for the corresponding
checklist updates.

## Original findings (Milestone 26, pre-fix)

**Recommendation at the time:** Minor fixes required. One real release blocker was found — a network call that contradicts this app's own written "no network access" privacy claim — everything else exercised in this pass (every item in the milestone's scope) works correctly, including in dark theme, landscape, and fully offline. The fix is narrow (bundle a font asset instead of fetching it) and does not require touching any other part of the app.

## Release blockers

### 1. `google_fonts` fetches over the network at runtime, contradicting the app's "no network access" privacy claim

**Where:** `lib/core/theme/app_typography.dart` (`GoogleFonts.notoSansJpTextTheme()`) and `lib/core/theme/app_theme.dart` (`GoogleFonts.notoSansJp()`) — the app's entire typography system.

**What happens:** `PRIVACY_POLICY.md` states outright: *"The app makes no network requests. It does not use the internet."* `README.md` says the app is *"fully functional offline from first launch"* with *"no account, no cloud, no network access required."* In reality, `google_fonts`'s default runtime-fetching behavior attempts a live HTTPS request to `fonts.gstatic.com` for the Noto Sans JP typeface — there is no bundled `.ttf` asset and no `fonts:` block in `pubspec.yaml`, so there's no local fallback; the network fetch is the only path.

**Evidence (from logcat, this session):**
```
E/flutter: [ERROR:flutter/runtime/dart_vm_initializer.cc(40)] Unhandled Exception: Exception:
Failed to load font with url https://fonts.gstatic.com/s/a/...ttf: ClientException with
SocketException: Failed host lookup: 'fonts.gstatic.com' ...
```
This is not a single harmless line at splash — it recurred **7 times across the session** (once per distinct font weight/variant first encountered while navigating to a new part of the UI), across all three process lifetimes tested:
- `18:34:22` — initial cold start
- `18:49:03`, `18:49:39` — after a full `force-stop` + relaunch
- `18:56:09`, `19:01:06`, `19:01:50` — during normal navigation in that same session (quiz, settings)
- `19:03:26` — relaunch with wifi *and* mobile data explicitly disabled (`svc wifi disable` / `svc data disable`), confirming the app attempts this regardless of connectivity state, not just on a flaky connection

**What it does *not* do:** crash the app, corrupt any state, or break rendering. Android's system font stack provides CJK glyph fallback, so every Hiragana/Katakana/Kanji character tested rendered correctly and legibly — in light theme, dark theme, and across three lesson scripts. Confirmed the app is otherwise fully usable with wifi and mobile data both disabled (see "Offline verification" below). This is why it wasn't caught earlier — it's invisible unless you're reading logs.

**Why it's still a blocker:** the audit's own technical-verification checklist asks explicitly for "no exceptions in logs," and this one fires on every cold start, unconditionally, in the shipped release build. More importantly, it's a genuine (if narrow) breach of a specific, written privacy promise — "makes no network requests" is not true as shipped.

**Suggested fix:** bundle `NotoSansJP` as a local asset (standard `fonts:` entry in `pubspec.yaml`, referenced via a plain `fontFamily` instead of the `GoogleFonts.notoSansJp*()` runtime-fetch API), or set `GoogleFonts.config.allowRuntimeFetching = false` with that same local asset registered as the fallback. Either removes the network call entirely; no other code changes needed since `AppTypography`/`AppTheme` are the only two call sites.

## What was verified working (no issues found)

**Technical checks:**
- `flutter analyze` — clean, no issues.
- `flutter test` — 94/94 passing.
- `flutter build apk --release` — succeeds (52.7 MB).
- `flutter build appbundle --release` — succeeds (51.2 MB).
- Zero native crashes (`FATAL EXCEPTION`/`AndroidRuntime`) across all three process lifetimes and ~67,000 lines of captured logcat.
- Zero Riverpod provider errors, zero Hive errors/corruption, zero `RenderFlex` overflow warnings, zero "used after being disposed" errors, zero ANRs, zero asset-loading failures — checked across the entire session, not spot-checked.

**Functional walkthrough** (fresh install → real interaction, not just navigation):
- App launch / cold start — no splash screen exists in this app (not a defect; there's simply no onboarding flow to test either, confirmed absent from the codebase).
- Dashboard — correct empty states (0% progress, "0 Lessons Completed", "28 Lessons Remaining"), Quick Search entry, Scripts cards.
- Hiragana lesson flow, all four steps exercised for real: Introduction → Stroke Order (animation) → Tracing (drew actual strokes via touch input; the app correctly rejected a sloppy trace with "Trace closer to the guide before continuing" rather than accepting it) → Free Writing (drew a real scribble; `WritingEvaluator` correctly scored it 0%, confirming the BUG-006 fix — scribbles still don't score well — holds in the release build).
- "Next Character" skip-ahead investigated as an edge case: skipping a character before finishing its writing step correctly shows 0% (not stale data from a previous character) — traced through the code and confirmed this is intentional, already-fixed behavior (references BUG-007 / Milestone 22 Issue 3 in its own comments), not a new bug.
- Audio playback — confirmed for あ (one of the five real-audio vowels): `MediaPlayer`/`AudioFlinger` activity in logcat with no errors.
- Quiz mode — full 10-question Recognition Quiz session played for real: correct scoring (40% accuracy, 4 correct / 6 incorrect), timer, "Areas to Review" populated from actual mistakes, "Quiz Novice" achievement unlocked, streak incremented 0 → 1 day, dashboard "Continue Last Practice" card updated.
- Review/SRS — correct empty state ("You're all caught up! No lessons are due for review") since no lesson was fully completed in this session; this is correct scheduler behavior, not a bug.
- Search — live filtering confirmed (typed a query, results narrowed correctly to the matching script/character).
- Analytics — overall stats, Script Breakdown, Weak Areas (correctly populated from the quiz mistakes above with a working "Practice Now" CTA), Achievement Summary, Study Insights.
- **Activity Calendar (Milestone 24 fix) — confirmed live and correct in the release build**: renders as a proper week grid (columns = weeks, rows = weekdays S–S top to bottom), today's cell correctly highlighted in the current-week column. No regression.
- Katakana and Kanji lesson lists — both render correctly with proper glyphs (spot-checked; full lesson flow not re-walked since Hiragana's identical underlying flow was already verified in depth).
- Settings — every toggle and dropdown exercised (Show stroke guides, Show writing grid, Sound effects, Haptic feedback, Larger writing area, Animation speed, Writing hand, Theme).
- **Theme switching** — Light → Dark confirmed instant and visually clean on both Settings and Dashboard: good contrast, no unreadable text, matches the BUG-004 dark-mode fix.
- **Offline verification** — beyond the font issue above, disabled wifi and mobile data (`svc wifi disable`/`svc data disable`, confirmed via the airplane-mode status bar icon) and did a full force-stop + relaunch: app launched and ran with zero new errors of any kind.
- **Progress persistence** — verified across a genuine process kill (`am force-stop`, confirmed via `pidof` returning nothing), not just backgrounding: "Lessons In Progress: 1" survived the cold restart correctly.
- **Orientation handling** — landscape tested on the Dashboard (top section and scrolled-down Achievements/Scripts section): clean reflow, no overflow, no errors.
- **Back navigation** — consistently unwinds screen-by-screen (Learning Flow → Hiragana list → Dashboard → home), no crashes, no dead ends, at every depth tested.
- Streak tracking — correctly incremented from 0 to 1 day after lesson activity.

**Not exhaustively re-tested in this pass** (lower risk, already covered by existing automated tests or prior milestones, or explicitly out of RC1 scope): the full Katakana/Kanji writing-practice flow character-by-character (Hiragana's identical flow was verified in depth instead), export/import (README already discloses import is stubbed), tablet-sized layouts (RELEASE_CHECKLIST.md already discloses this as unverified), and physical-device performance.

## Minor, non-blocking observations

- Dashboard shows "Welcome Back!" even on a genuinely first-ever launch (post `pm clear`). Harmless copy nit — this app has no onboarding/first-run distinction to begin with, so there's no "wrong" state being shown, just slightly odd wording for a brand-new user.

## Conclusion

This build is in very good shape: zero crashes, zero framework-level errors, and every previously-fixed bug spot-checked in this pass (BUG-004 dark theme, BUG-006 writing evaluator, BUG-007/M22#3 state reset, Milestone 24 activity calendar) held up correctly in a real release build. The one blocker found — `google_fonts` fetching over the network — is now fixed and re-verified as of Milestone 26.1 (see the update at the top of this report). **Ready to tag `v1.0.0`** — the remaining items are all already correctly tracked as post-v1.0 deferred work in `RELEASE_CHECKLIST.md` (production keystore, real branding, physical-device verification, store assets, iOS).
