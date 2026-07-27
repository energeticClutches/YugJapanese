# YugJapanese

An offline-first Flutter app for learning to read and write Japanese —
Hiragana, Katakana, and Kanji — with guided lessons, spaced-repetition
review, six practice/quiz modes, achievements, and a learning-analytics
dashboard. No account, no cloud, no network access required.

**Version 1.0.0** · Android · application ID
`com.energeticclutches.yugjapanese` · MIT licensed.

Release builds are currently signed with the debug key and the launcher
icon/splash are placeholder artwork — see [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md)
for what must be done before publishing. Other docs:
[CHANGELOG.md](CHANGELOG.md), [PRIVACY_POLICY.md](PRIVACY_POLICY.md),
[TERMS_OF_USE.md](TERMS_OF_USE.md), [CREDITS.md](CREDITS.md).

## Features

- **Guided lessons** for Hiragana, Katakana, and JLPT N5 Kanji, with
  stroke-order guidance and handwriting evaluation.
- **Spaced-repetition review** (fixed-interval scheduler: 1 → 3 → 7 → 14 →
  30 → 60 → 90 days).
- **Practice/Quiz engine** — six modes (Recognition, Meaning, Reading,
  Listening, Mixed, Weak Items) sharing one question-generation/scoring
  engine.
- **Achievements & streaks**, computed from existing progress/review/quiz
  data (no separate tracking).
- **Analytics dashboard** — script breakdown, accuracy trends, an activity
  calendar, weak-area detection tied into the Weak Items quiz mode,
  deterministic study insights, and CSV/JSON export.
- **Offline audio**, universal search, and a Settings screen with theme,
  accessibility, and data-management options.

## Architecture overview

Each unit of functionality is a **feature** under `lib/features/<name>/`,
following the same internal shape as needed:

```text
lib/features/<name>/
  models/         # plain Dart, no Flutter imports; toMap()/fromMap() for Hive
  repositories/   # abstract contract + a Hive-backed implementation
  services/       # business logic (pure Dart where possible)
  providers/      # Riverpod wiring: Provider → Service → ChangeNotifierProvider/FutureProvider
  screens/        # one screen per route
  widgets/        # feature-local reusable widgets
```

Conventions established across the codebase (see `PROJECT_RULES.md` for
the full list, kept up to date as the source of truth):

- **`ContentRepositoryFactory`** (`lib/repositories/content_repository_factory.dart`)
  is the only place that maps a `contentId` string (`'hiragana'`,
  `'katakana'`, `'kanji'`) to its `LessonRepository`. Adding a new script
  means registering it here — nothing else branches on content-id strings.
- **State management**: `flutter_riverpod`, one pattern throughout — a
  `Provider<XRepository>`, a `Provider<XService>` (or `ChangeNotifierProvider`
  for stateful services like `AudioService`/`SettingsController`), consumed
  via `ref.watch`. No `StateNotifier`/codegen mixed in.
  `FutureProvider`s that need to refresh when unrelated state changes
  `ref.watch()` another provider purely as an invalidation signal, rather
  than scattering manual `ref.invalidate()` calls through the UI.
  See [`PROJECT_RULES.md`](PROJECT_RULES.md).
- **Persistence**: Hive, one box per feature, opened at startup in
  `lib/main.dart` via `_openBoxSafely` (recovers from a corrupted box file
  instead of crashing at launch). Every repository read goes through
  `safeParse` (`lib/core/utils/safe_parse.dart`) so one malformed record is
  skipped instead of throwing.
- **Theming**: everything goes through `lib/core/theme/` tokens
  (`AppColors`, `AppSpacing`, `AppRadius`, `AppTypography`) — avoid raw
  magic numbers in new UI code.

## Folder structure

```text
lib/
  core/            theme tokens, responsive helpers, router
  models/           cross-script models shared by every content type (LearningItem, LessonModel, ...)
  repositories/     ContentRepositoryFactory + per-script LessonRepository implementations
  services/         cross-cutting services (JSON asset loading)
  shared/widgets/   small widgets reused across multiple features (AppScaffold, LoadingIndicator, EmptyState, ErrorState, ...)
  features/
    hiragana/ katakana/ kanji/    per-script lesson-list screens
    practice/                     the guided-lesson learning flow (NOT the quiz engine — see quiz/)
    writing/                      handwriting evaluation
    progress/                     lesson completion tracking
    review/                       spaced-repetition scheduling
    quiz/                         practice/quiz engine (6 modes) — named quiz/ to avoid colliding with practice/
    achievements/                 streaks + achievement unlocking
    analytics/                    read-only aggregation dashboard + CSV/JSON export
    dashboard/                    home screen, aggregates every other feature
    settings/                     preferences, data reset, diagnostics
    audio/                        pronunciation playback
    search/                       universal offline search + favorites
assets/
  data/    per-script lesson JSON (hiragana_lessons.json, katakana_lessons.json, kanji_lessons.json),
           plus stroke_data.json (per-character stroke polylines, derived from KanjiVG — see CREDITS.md)
  audio/   per-script pronunciation clips (hiragana/katakana/kanji subfolders)
  branding/ placeholder launcher icon / splash source images
test/
  fakes/   in-memory repository fakes shared by unit/widget/flow tests
  unit/    pure-logic tests (schedulers, evaluators, generators, services)
  widget/  widget-level tests
  flow/    flutter_test-based multi-step flow tests (see "Testing" below)
```

## Setup

```bash
flutter pub get
flutter run
```

Requires the Flutter SDK (`^3.12.2` per `pubspec.yaml`) and an Android
toolchain (this app currently targets Android phones/tablets only). No API
keys, accounts, or network access are needed — the app is fully
functional offline from first launch.

## Testing

```bash
flutter analyze   # static analysis
flutter test      # unit + widget + flow tests
```

There is no `integration_test`/device-driven test runner in this project;
`test/flow/` substitutes `flutter_test`-based multi-step tests (real
services wired to in-memory fakes) for the same coverage without the
device-driver machinery. `analysis_options.yaml` intentionally runs with
Dart's bare defaults — no `flutter_lints` — to avoid an unplanned
retroactive cleanup pass across the whole existing codebase; this is a
disclosed limitation, not an oversight.

## Asset management guide

To add a new script's content:

1. Add `assets/data/<script>_lessons.json` (same shape as
   `hiragana_lessons.json`) and register it under `flutter: assets:` in
   `pubspec.yaml`.
2. Add a `<Script>Repository implements LessonRepository` in
   `lib/repositories/`, following `HiraganaRepository`'s shape (loads via
   `JsonLoaderService`, caches the parsed lessons).
3. Register it in `ContentRepositoryFactory`. Nothing else needs to change
   — dashboard, search, statistics, achievements, and the quiz engine all
   pick it up automatically through `ContentRepositoryFactory
   .availableContentIds`.

To add real pronunciation audio: drop files into
`assets/audio/<script>/` matching the `audioAsset` paths already declared
in that script's lesson JSON. `LocalAudioRepository` verifies a file
actually exists before ever offering to play it, so partial audio
coverage degrades to a disabled button, never a crash — **never generate
or bundle synthetic/placeholder audio and present it as real
pronunciation** (see `PROJECT_RULES.md`'s "Audio asset honesty" rule).

## Known limitations

- **Review scheduling has no failure path**: every recorded review is
  currently a "success" (fixed-interval scheduler, not SM-2). The
  Analytics screen's "Review success rate" trend is therefore always 100%
  on days with a review — an honest reflection of the current scheduler,
  not fabricated data.
- **Per-script quiz accuracy is approximate**: a quiz session's accuracy
  is recorded per-session, not per-script, so `ScriptAnalytics
  .averageQuizAccuracy` averages sessions that touched a script rather
  than scoring individual items.
- **"Estimated Study Minutes" is a heuristic**, not measured time: real
  quiz-session durations plus a fixed per-lesson/per-review estimate.
- Only Hiragana's 5 vowel characters have real (synthesized-tone,
  clearly-labeled) pronunciation audio today; Katakana and Kanji have
  none yet — see the Asset management guide above to add more.
- No multi-device (tablet/landscape) physical testing has been performed
  beyond a single phone emulator profile; tablet layouts are reasoned
  about via the shared `AppScaffold` 960dp content cap, not verified on
  real tablet hardware.
- **Cold start is slow on the emulator** (~3.5–5.3s), almost entirely due
  to the first cold open of the 8 Hive boxes. This was measured and
  A/B-tested in M20; opening the boxes concurrently versus sequentially
  makes no difference, so it is disk I/O rather than the concurrency
  strategy. Physical hardware is expected to be much faster but has not
  been measured. If it needs to improve, the lever is opening fewer boxes
  eagerly rather than changing how they are awaited.
- Progress import/export from Settings is stubbed; analytics CSV/JSON
  export does work. "Larger writing area" in Accessibility is not yet
  implemented.
- Android only — there is no `ios/` platform target yet.

See `PROJECT_LOG.md` for the full milestone-by-milestone build history and
`PROJECT_RULES.md` for the enforced architectural conventions.
