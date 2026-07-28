# Project Log

## Project

Offline-first Flutter application for learning Japanese writing on Android
phones and tablets. The learning order is Hiragana, Katakana, then Kanji.

## Current State (read this first in a new session)

- **Last completed milestone: 20 (Production Release v1.0), plus five
  post-release bugfixes — BUG-001 (Android back button), BUG-002 (the
  writing canvas never existed — see that entry below, it's a substantial
  feature build, not a small patch), BUG-003 (Hiragana lesson list),
  BUG-004 (dark mode readability), BUG-006 (writing evaluator scored
  scribbles as correct) — and one enhancement pass over the learning
  systems (spaced repetition, stroke direction, mnemonics, pacing).**
  `flutter analyze` clean, `flutter test` passing (68/68). **The release
  APK/AAB have not been rebuilt since the enhancement pass** — rebuild
  before treating release artifacts as current.
- **Writing accuracy is measured against real stroke geometry as of
  BUG-006.** Before that fix the evaluator only ever saw a stroke count
  and a bounding box, so any scribble with the right number of strokes
  scored ~100%. Accuracy figures recorded before BUG-006 are meaningless
  and should not be compared against current ones.
  Remaining open items are **release blockers, not defects**, and live in
  `RELEASE_CHECKLIST.md` — chiefly: release builds are intentionally
  debug-signed (no production keystore exists yet), the launcher icon and
  splash are placeholder artwork, and startup performance and tablet
  layouts are unverified on physical hardware.
- **The writing canvas is real as of the BUG-002 fix** — `lib/features/writing/`
  now has an actual finger-drawn canvas, stroke-order animation, and
  tracing guide, backed by `assets/data/stroke_data.json` (KanjiVG-derived,
  CC BY-SA 3.0, see `CREDITS.md`). Before this it was entirely absent and
  `learning_screen.dart` scored fabricated synthetic strokes instead of
  real input — if you see references to "writing evaluation" in earlier
  log entries (M7, M17, M18), know that every accuracy number from before
  this fix was machine-generated, not earned.
- **Android application ID is `com.energeticclutches.yugjapanese`** (M20,
  renamed from the `com.example.japanese_learning` placeholder). Display
  name is "YugJapanese". Note this means a device with a pre-M20 build
  installed will keep it as a *separate* app with separate data.
- **Startup cost is dominated by the first cold open of the 8 Hive
  boxes** (~3.4–5.3s on the emulator). M20 A/B-tested parallel vs
  sequential opening and found no difference — do not "optimize" that
  again without measuring; see `_openBoxSafely`'s comment. M19's claim
  that parallelizing gave "roughly 8x" less latency was unmeasured and is
  now corrected in that entry.
- **Docs at the repository root:** `CHANGELOG.md`, `RELEASE_CHECKLIST.md`,
  `PRIVACY_POLICY.md`, `TERMS_OF_USE.md`, `CREDITS.md`. The three legal
  files are bundled as assets and rendered in-app by
  `LegalDocumentScreen` (Settings → Legal), so edit the root file and the
  in-app copy follows automatically.
- **Content:** Hiragana (46 characters, 10 lessons — expanded from the
  original 5-vowel Lesson 1 in BUG-002, mirroring Katakana's row grouping),
  Katakana (46 characters, 10 lessons), and Kanji (79 JLPT N5 / Grade-1
  kyōiku characters, 8 lessons) all have real content and are fully
  enabled end-to-end (learning flow, progress, reviews, achievements,
  dashboard, search, writing practice).
- **Remote:** pushed to `https://github.com/energeticClutches/YugJapanese`
  (`main` branch). Commit and push only when the user explicitly asks.
  Latest pushed commit: `70adb40` — "fix: build the writing canvas, which
  never existed (BUG-002)" (2026-07-27).
- **Toolchain:** Flutter 3.44.8, AGP 9.0.1, Gradle 9.1.0, Kotlin 2.3.20 — this
  is the working, verified combination. Do not change these versions; if
  `flutter run`/build ever fails again with an opaque Gradle
  `MissingValueException`, suspect a corrupt Android SDK platform package
  before touching build files (see the "Runtime Verification" entry after
  Milestone 8 for the full diagnosis story).
- **Feature map** (each is its own `lib/features/<name>/` with
  `models/repositories/providers/services/screens/widgets`):
  - `progress` (M8) — generic `LessonProgress`, Hive box `lesson_progress`.
  - `dashboard` (M9) — `StatisticsService` + `ContentSource` is the reusable
    "which content exists" wiring; other features import it rather than
    duplicating a per-script list. `contentSourcesProvider` is now generated
    from `ContentRepositoryFactory.availableContentIds` (M13), so it already
    includes every registered script with no manual wiring.
  - `review` (M10) — spaced repetition, Hive box `review_schedule`, fixed
    interval scheduler (not SM-2 yet).
  - `achievements` (M11) — Hive box `achievement_progress`, streak +
    achievement unlocking computed entirely from existing progress/review
    data; touches nothing in `practice`/`writing`/`hiragana`.
  - `settings` (M12) — Hive box `app_settings`. `AppSettings` (theme mode,
    sound/haptics/auto-play toggles, learning prefs) is the single source of
    truth other features read from (`currentSettingsProvider`).
  - `katakana` / `kanji` (M13, M14) — thin per-script repositories following
    the same shape as `HiraganaRepository`; see "Content repository factory"
    below. `CharacterModel`/`LearningItem` gained optional Kanji-only fields
    (`secondaryReadings`, `kunReadings`, `radical`, `grade`, `jlptLevel`,
    `examples`, `notes`) — always empty/null for Hiragana/Katakana.
  - `learning` (M14) — NOT a script; holds `KanjiExample` and the
    Kanji-specific display widgets (`ReadingSection`, `RadicalCard`,
    `ExampleWordCard`) shared by the introduction step and search results.
  - `audio` (M15) — no persistence. `AudioService` (`ChangeNotifier`) wraps
    `audioplayers`; `LocalAudioRepository` verifies a given asset path
    actually exists (via `rootBundle.load` + cache) before ever reporting it
    playable, so missing recordings degrade to a disabled button, never a
    crash. Only 5 placeholder tone files exist today (Hiragana vowels) — see
    the M15 log entry before assuming any audio is real pronunciation.
  - `search` (M16) — Hive boxes `favorites` and `search_history`. Indexes
    every script through `contentSourcesProvider` (same list dashboard
    uses), so a future script needs zero search-specific code once it's
    registered in `ContentRepositoryFactory`.
  - `quiz` (M17) — NOT the same feature as `practice/` (that name was
    already taken by the guided-lesson flow at `/practice/:lessonNumber`;
    this is a deliberate deviation from the milestone brief's literal
    folder name, see the M17 log entry). Hive box `practice_results`. Six
    data-driven modes (`PracticeGenerator.catalog`) share one
    `PracticeQuestion`/`PracticeSession`/`PracticeService` engine; pulls its
    item pool through `contentSourcesProvider`/`ContentRepositoryFactory`
    like every other cross-script feature. Routes `/quiz`, `/quiz/play`,
    `/quiz/results`.
  - `analytics` (M18) — read-only aggregation over every other feature's
    existing repositories; adds no new source-of-truth data, only a
    scalar `AnalyticsSnapshot` cache (Hive box `analytics_snapshot`)
    written as a side effect of `AnalyticsService.getAnalytics()`, which
    itself always recomputes fresh (no caching precedent broken — see the
    M18 log entry). Route `/analytics`. `TrendChart`/`ActivityHeatmap` are
    hand-rolled `CustomPainter`/`Wrap` widgets — no charting package is
    approved for this project.
- **Content repository factory**: `lib/repositories/content_repository_factory.dart`
  maps a `contentId` string (`'hiragana'`, `'katakana'`, `'kanji'`) to its
  `LessonRepository`. This is the **only** place that should ever branch on
  contentId strings for "which repository". Introduced in M13 specifically
  to replace the old hardcoded-per-screen resolution described below; add a
  new script by registering it here and nowhere else needs to change.
- **Established reactivity convention** (used by every feature since M9):
  a `FutureProvider` that needs to "refresh when X changes" calls
  `ref.watch(xProvider)` purely for its invalidation signal (ignoring the
  returned value) rather than adding explicit `ref.invalidate()` calls
  scattered through UI code. `progressControllerProvider` (a
  `ChangeNotifierProvider`) and `dueReviewsProvider` are the two shared
  triggers other features watch. `learning_screen.dart` still calls
  `ref.invalidate(dueReviewsProvider)` once after scheduling a review (that
  predates this convention and works fine); no other screen needs to.
- **Stateful feature controller pattern**: every feature needing live UI
  updates after a mutation (settings, audio playback, favorites, search
  history) uses a `ChangeNotifier` controller/service exposed via
  `ChangeNotifierProvider`, matching `ProgressController` from M8. Screens
  call `ref.watch(xProvider)` to rebuild automatically; there is no feature
  using `StateNotifier`/Riverpod 3 codegen instead — stay consistent with
  this rather than introducing a second state-management style.
- **Screen-level content resolution pattern**: generic identifiers (e.g.
  `"contentId:lessonNumber"`) are still resolved back to a display title
  only at the screen/widget layer (dashboard's Continue Learning card,
  `ReviewScreen`, `SearchScreen`'s Continue Learning suggestion) — never
  inside a repository, service, or scheduler. As of M13 this resolution goes
  through `ContentRepositoryFactory.tryRepositoryFor(contentId)` (generic),
  **not** a hardcoded `contentId == 'hiragana'` check (that was the M9–M12
  approach; if you find that pattern anywhere, it's a leftover and should be
  updated to use the factory, not a template to copy).
- **Learning flow can now jump to a specific character**: `LearningScreen`
  and `LearningController.startLesson` accept an optional
  `startCharacterId`, threaded through the router's `char` query param
  (M16). Used by search results to open a lesson at the exact character
  found instead of always at index 0; reuse this instead of building a
  parallel "character detail" screen if something else ever needs the same
  behavior.
- **Testing (M19)**: `test/` exists now — `test/fakes/` has in-memory
  (non-Hive) fakes for every repository interface; prefer reusing one over
  writing a new fake. `test/flutter_test_config.dart` disables
  `google_fonts` runtime fetching for every test automatically — don't
  remove it, tests will hang under `pumpAndSettle` without it. If a new
  widget test needs a `FutureProvider` that `ref.watch()`s
  `practiceServiceProvider` (a `ChangeNotifierProvider`), override that
  `FutureProvider` directly rather than letting it construct
  `practiceServiceProvider` internally — see the M19 log entry and the
  comment in `test/widget/dashboard_screen_test.dart` for the
  `flutter_test`/Riverpod deadlock this works around (not present in the
  real app).
- **Data safety (M19)**: every Hive repository read goes through
  `safeParse` (`lib/core/utils/safe_parse.dart`) — use it for any new
  repository's `fromMap` calls too, don't call `X.fromMap(...)` directly
  from a repository. Boxes open via `_openBoxSafely` in `main.dart`,
  which self-heals a corrupted box file; a new box should follow the same
  pattern rather than a bare `Hive.openBox`.
- Do not start Milestone 20 or any new feature without explicit instruction.

## Completed Milestones

### Foundation

- Flutter project bootstrapped with Material 3 and null safety.
- Approved dependencies only: Riverpod, go_router, Hive, Hive Flutter,
  path provider, Google Fonts, shared preferences, Flutter SVG, and
  audioplayers.
- `CLAUDE.md` and `PROJECT_RULES.md` established as permanent project context
  and agent rules.

### Design System

- Centralized Japanese-inspired colors, typography, spacing, radius values,
  and Material 3 light theme in `lib/core/theme/`.
- Typography uses Noto Sans JP through Google Fonts.

### App Shell

- go_router application shell and placeholder feature routes created.
- Responsive helpers, reusable app scaffold, feature cards, and lesson card
  widgets created.
- Home, Hiragana, Katakana, Kanji, Progress, and Settings routes exist.

### Hiragana Content

- Immutable character and lesson models added.
- Lesson repository abstraction and local Hiragana repository added.
- Local JSON asset contains Hiragana Lesson 1 (vowels: あ い う え お).
- Hiragana screen displays Lesson 1 and launches the learning flow.

### Generic Learning Flow

- Generic `LearningItem`, `LearningSession`, and `LearningStep` models added.
- `LearningController` depends on the generic lesson repository contract.
- Learning flow supports introduction, stroke order, tracing, free writing,
  and completion stages.
- Hiragana repository remains the current content implementation, without
  Hiragana-specific logic in the learning controller.

### Writing Evaluation

- Reusable writing models and a local `WritingEvaluator` added under
  `lib/features/writing/`.
- Evaluation calculates simple stroke-count, completion, canvas-coverage, and
  bounding-box metrics.
- Writing results are displayed in a reusable result card during learning.
- No handwriting canvas, OCR, AI, cloud service, or persistence was added to
  the evaluator.

## Milestone 8: Persistent Progress

Implemented and analyzer-clean:

- Generic `LessonProgress` model with content ID, lesson number, completion
  status, best writing accuracy, last-accessed timestamp, and completion
  timestamp.
- `ProgressRepository` abstraction and `HiveProgressRepository` implementation.
- `ProgressController` manages loading, in-progress state, lesson completion,
  best-score retention, completion percentages, and last accessed lesson.
- Hive initializes and opens the `lesson_progress` box in `main.dart`.
- Starting a lesson records it as in progress.
- Completing the final character saves the lesson result and returns to
  Hiragana.
- Hiragana Lesson 1 card shows `Not Started`, `In Progress`, or `Completed`,
  along with the script completion percentage.

### Files Added for Progress

- `lib/features/progress/models/lesson_progress.dart`
- `lib/features/progress/repositories/progress_repository.dart`
- `lib/features/progress/repositories/hive_progress_repository.dart`
- `lib/features/progress/services/progress_controller.dart`
- `lib/features/progress/providers/progress_providers.dart`

### Files Changed for Progress

- `lib/main.dart`
- `lib/features/practice/learning_screen.dart`
- `lib/features/hiragana/hiragana_screen.dart`
- `lib/shared/widgets/lesson_card.dart`

### Verification Status

`flutter analyze` was run successfully (flutter_riverpod 3.3.2, go_router
17.3.0 resolved). It initially reported 6 errors, all caused by API surface
changes in Riverpod 3.x rather than logic issues; no product behavior was
changed. Smallest possible fixes were applied:

- `lib/features/progress/providers/progress_providers.dart`: Riverpod 3.x
  removed the generated `ProviderRef<T>` / `ChangeNotifierProviderRef<T>`
  types in favor of a single generic `Ref`, and moved `ChangeNotifierProvider`
  into `package:flutter_riverpod/legacy.dart`. Updated both provider callbacks
  to use `Ref` and added the `legacy.dart` import.
- `lib/features/writing/writing_evaluator_provider.dart`: same `ProviderRef<T>`
  to `Ref` update for consistency with the installed Riverpod version.
- `lib/features/practice/learning_screen.dart`: added the missing
  `package:go_router/go_router.dart` import (required for the existing
  `context.go('/hiragana')` call) and the missing direct import of
  `../writing/services/writing_evaluator.dart` (the `WritingEvaluator` type
  was used but not exported transitively through the provider file).

After these fixes, `flutter analyze` reports **0 errors**. One pre-existing
`info`-level lint remains (`unnecessary_import` for `dart:ui` in
`learning_screen.dart`, from the earlier writing-evaluation milestone,
unrelated to progress persistence); left unchanged per scope.

No Flutter, Android SDK, Gradle, Java, IDE, or dependency configuration was
changed. No new packages were added.

### Runtime Verification

The app was built and launched on an Android emulator (API 37, `emulator-5554`)
to verify the persistent progress milestone at runtime.

Initially `flutter run` failed during the Android build with:

```
Could not determine the dependencies of task ':app:compileDebugJavaWithJavac'.
> Cannot query the value of this provider because it has no value available.
```

Root cause was **not** in the project. The locally installed Android SDK
platform `android-36` was corrupt: it was missing `android.jar`,
`build.prop`, `core-for-system-modules.jar`, and `android-stubs-src.jar`
(`android-35` and `android-36.1` were intact). AGP 9.0.1 surfaced this only as
an opaque Gradle `MissingValueException`; temporarily pinning AGP/Gradle lower
revealed the real message, `Failed to find target with hash string 'android-36'`.

Resolution: reinstalled `platforms;android-36` via `sdkmanager`. All temporary
AGP, Gradle wrapper, `gradle.properties`, and Kotlin-plugin changes made while
diagnosing were reverted; the Android build configuration is byte-for-byte
identical to the stock Flutter 3.44.8 template and to its pre-debug state.

Result: `√ Built build\app\outputs\flutter-apk\app-debug.apk`, installed and
launched successfully on the original AGP 9.0.1 / Gradle 9.1.0 toolchain, with
no Dart exceptions in the runtime log. Hive initialized and the app rendered
without error.

No application source files were changed during runtime verification.

## Milestone 9: Dashboard & Learning Statistics

Implemented and verified on device:

- Generic `LearningStatistics` model (`lib/features/dashboard/models/`), with
  no dependency on Hiragana or any specific script.
- `ContentSource` descriptor pairing a `contentId` with its `LessonRepository`,
  used to make statistics computation script-agnostic.
- `StatisticsService` computes total/completed/in-progress lesson counts,
  completion percentage, average best-writing-accuracy, and the most recently
  accessed lesson, by reading `ProgressRepository` directly (not the
  `ProgressController` cache), so stats are always correct even if no other
  screen has loaded progress yet. Pure Dart, no UI logic.
- Riverpod `dashboard_providers.dart` exposes `statisticsServiceProvider`,
  `contentSourcesProvider` (wired only Hiragana at the time; generated from
  `ContentRepositoryFactory` since M13), and
  `learningStatisticsProvider` (`FutureProvider`, watches
  `progressControllerProvider` so it recomputes automatically whenever
  progress is saved elsewhere in the app).
- New `DashboardScreen` replaces the placeholder `HomeScreen` as the `/` route
  and app home: welcome header, overall-progress ring, four statistic cards,
  a Continue Learning / Start Learning card, and script cards for Hiragana
  (enabled), Katakana and Kanji (disabled placeholders).
- Reusable widgets added: `StatisticCard`, `ProgressSummaryCard`,
  `ContinueLearningCard`, `ScriptCard`.
- `lib/features/home/home_screen.dart` removed (superseded); `app_router.dart`
  updated to route `/` to `DashboardScreen`. No other route changes.
- Removed a pre-existing unused `dart:ui` import in `learning_screen.dart`
  surfaced by `flutter analyze` (out of this milestone's own scope, but
  needed to satisfy the "no analyzer issues" acceptance criterion).

`flutter analyze`: **No issues found.**

### Runtime Verification

Ran on the same Android emulator (API 37) used for the persistent-progress
milestone. Confirmed via screenshots and taps:

- Cold app start lands on the dashboard and shows real, previously-persisted
  Hive data (1 lesson completed, 100% overall progress, 1% average accuracy).
- The Continue Learning card correctly resolved the most recent progress
  entry to "Lesson あ" and navigated to `/practice/1` on tap, landing on the
  correct in-progress lesson.
- Tapping the Hiragana script card navigated to `/hiragana`, which showed
  "Lesson 1 / Vowels / Completed - 100%", consistent with the dashboard.
  Katakana and Kanji cards render disabled/greyed with "Coming Soon".
- No Dart exceptions in the runtime log; no layout overflow observed on
  device at any scroll position.

### Files Added

- `lib/features/dashboard/models/learning_statistics.dart`
- `lib/features/dashboard/models/content_source.dart`
- `lib/features/dashboard/services/statistics_service.dart`
- `lib/features/dashboard/providers/dashboard_providers.dart`
- `lib/features/dashboard/widgets/statistic_card.dart`
- `lib/features/dashboard/widgets/progress_summary_card.dart`
- `lib/features/dashboard/widgets/continue_learning_card.dart`
- `lib/features/dashboard/widgets/script_card.dart`
- `lib/features/dashboard/screens/dashboard_screen.dart`

### Files Changed / Removed

- `lib/core/router/app_router.dart` (routes `/` to `DashboardScreen`)
- `lib/features/practice/learning_screen.dart` (removed unused `dart:ui` import)
- `lib/features/home/home_screen.dart` removed (replaced by the dashboard)

## Milestone 10: Review Mode & Spaced Repetition Foundation

Implemented and verified on device:

- Generic `ReviewItem` model (`lib/features/review/models/`): `lessonId`
  (e.g. `"hiragana:1"`), `nextReview`, `lastReviewed`, `reviewCount`,
  `easeFactor` (reserved, unused), `intervalDays`. No dependency on any
  script.
- `ReviewRepository` abstraction and `HiveReviewRepository` implementation,
  backed by a new `review_schedule` Hive box (opened in `main.dart`
  alongside `lesson_progress`), keyed directly by `lessonId`.
- `ReviewScheduler`: fixed interval progression
  `1 → 3 → 7 → 14 → 30 → 60 → 90` days. `scheduleInitialReview` creates a
  lesson's first schedule (no-ops if one already exists);
  `recordSuccessfulReview` advances to the next interval;
  `getDueReviews` returns schedules whose `nextReview` has passed, sorted
  soonest-first. Deliberately not SM-2; replaceable later without touching
  `ReviewRepository` or its callers. Kept independent from
  `LessonRepository`/`ProgressRepository` — it only knows about generic
  `lessonId` strings.
- Riverpod `review_providers.dart`: `reviewRepositoryProvider`,
  `reviewSchedulerProvider`, `dueReviewsProvider` (`FutureProvider`,
  manually invalidated by the learning screen after scheduling so the
  dashboard and review screen stay in sync).
- `ReviewScreen` (new `/review` route) lists due reviews under "Today's
  Reviews", resolving each `lessonId` to a display title (currently only
  `hiragana` is resolved, matching the dashboard's existing
  `lastLessonId`-resolution pattern) and launching review mode via
  `/practice/:lessonNumber?mode=review`.
- Review mode: `LearningScreen` gained an `isReviewMode` flag (read from the
  `mode=review` query parameter). `LearningSession` gained a `startStep`
  field (default `introduction`) that both the initial step and
  `nextCharacter()`/`previousStep()` respect, so review mode starts every
  character at Stroke Order and can't be backed into Introduction.
  `LearningController.startLesson` takes an optional `skipIntroduction` flag
  and remembers it for `restartLesson`. On completing the final character in
  review mode, the screen calls `recordSuccessfulReview` (instead of
  `scheduleInitialReview`) and returns to `/review` (instead of
  `/hiragana`).
- Dashboard integration: new "Today's Reviews" section between "Continue
  Learning" and "Scripts", using the same `dueReviewsProvider`.
- Reusable widgets: `ReviewCard`, `ReviewSummaryCard` (handles both the
  "N Lessons Due" and "You're all caught up!" states), `EmptyReviewState`.

`flutter analyze`: **No issues found.**

### Runtime Verification

Verified on the same Android emulator (API 37). To exercise the due-review
path without waiting a real day, the first interval was temporarily set to
`-1` days, the app reinstalled fresh, and reverted back to `1` immediately
after verification; `flutter analyze` was re-run clean afterward and no
other files were affected.

Confirmed via screenshots and taps:

- Completing Hiragana Lesson 1 normally created a review schedule; the
  dashboard's "Today's Reviews" correctly showed "1 Lesson Due".
- Opening the review card navigated to `/review`, correctly resolving and
  displaying "Lesson あ".
- Tapping it launched `/practice/1?mode=review`; the screen showed
  **"Current Step: Stroke Order"** on character 1 of 5 (introduction
  skipped), and "Previous" was a no-op at that step. Character 5 also
  started at Stroke Order (confirms `nextCharacter()` respects `startStep`,
  not just the initial session).
- Completing the review advanced the schedule to the 3-day interval and
  returned to `/review`, which then correctly showed the full-page
  `EmptyReviewState` ("You're all caught up!").
- No Dart exceptions in the runtime log throughout.

### Files Added

- `lib/features/review/models/review_item.dart`
- `lib/features/review/repositories/review_repository.dart`
- `lib/features/review/repositories/hive_review_repository.dart`
- `lib/features/review/services/review_scheduler.dart`
- `lib/features/review/providers/review_providers.dart`
- `lib/features/review/widgets/review_card.dart`
- `lib/features/review/widgets/review_summary_card.dart`
- `lib/features/review/widgets/empty_review_state.dart`
- `lib/features/review/screens/review_screen.dart`

### Files Changed

- `lib/main.dart` (opens the `review_schedule` Hive box)
- `lib/core/router/app_router.dart` (adds `/review`; `/practice/:lessonNumber`
  now reads the `mode=review` query parameter)
- `lib/models/learning_session.dart` (adds `startStep`, used by
  `nextCharacter()`/`previousStep()`)
- `lib/features/practice/learning_controller.dart` (adds
  `skipIntroduction` param to `startLesson`, remembered for `restartLesson`)
- `lib/features/practice/learning_screen.dart` (accepts `isReviewMode`;
  schedules/advances reviews and routes to `/review` on completion in
  review mode)
- `lib/features/dashboard/screens/dashboard_screen.dart` (adds "Today's
  Reviews" section)

## Milestone 11: Achievements & Streak System

Implemented and verified on device. Deliberately zero changes to the
learning flow (`practice/`, `writing/`, `hiragana/`) — streaks and
achievements are computed entirely by reading data those features already
persist.

- Models (`lib/features/achievements/models/`, all pure Dart, no Flutter
  imports, matching `LessonProgress`/`ReviewItem` convention):
  - `Achievement`: static catalog entry (`id`, `title`, `description`,
    `iconKey`, `criteria` enum, `threshold`). Not persisted — only unlock
    state is. `iconKey` is a plain string so the model stays Flutter-free;
    `achievementIconForKey()` in the widgets layer resolves it to an
    `IconData`.
  - `AchievementProgress`: persisted unlock state (`achievementId`,
    `isUnlocked`, `unlockedAt`).
  - `StreakInfo`: `currentStreak`, `longestStreak`, `lastActiveDate`
    (`StreakInfo.empty` constant for the no-data case). **Not persisted as
    its own record** — recomputed each time from every `LessonProgress`'s
    `lastAccessedAt` across all `ContentSource`s. This was a deliberate
    design choice: the raw dates are already durable in the existing
    `lesson_progress` Hive box, so a second, separately-persisted streak
    counter would just be a cache that could drift out of sync. Revisit only
    if this ever becomes a real performance problem (it won't at this app's
    scale).
  - `AchievementRepository` / `HiveAchievementRepository`: standard
    repository pair (matches `ProgressRepository`/`ReviewRepository`
    shape), Hive box `achievement_progress`, keyed by `achievementId`.
- `AchievementService` (`lib/features/achievements/services/`): the only
  non-trivial logic in this milestone.
  - `static const List<Achievement> catalog` — 6 seed achievements:
    `first_lesson` (1 lesson), `five_lessons` (5 lessons), `streak_3`
    (3-day streak), `streak_7` (7-day streak), `first_review` (1 review),
    `perfect_accuracy` (100% average accuracy). Criteria are data
    (`AchievementCriteria` enum + `threshold`), not a hardcoded per-id
    switch, so adding a 7th achievement later is a one-entry catalog
    addition, not new branching logic.
  - `calculateStreak(sources)`: collects the distinct calendar dates from
    every lesson's `lastAccessedAt`, then walks backward from today for the
    current streak (today OR yesterday must be active, or it's 0) and scans
    the full sorted date set for the longest consecutive run.
  - `evaluateAchievements(sources)`: for each catalog entry, if already
    unlocked in the repository it's left alone (achievements never re-lock);
    otherwise checks the relevant threshold against
    `StatisticsService.getStatistics()` (reused from M9 — not duplicated),
    the computed `StreakInfo`, or the summed `reviewCount` across
    `ReviewRepository.getAllReviews()`, and persists+returns a newly-unlocked
    `AchievementProgress` if met.
  - Depends on `StatisticsService` and `ReviewRepository` by constructor
    injection — reads only, never writes to progress or review data.
- Riverpod `achievement_providers.dart`: `achievementRepositoryProvider`,
  `achievementServiceProvider`, `streakInfoProvider` and
  `achievementProgressListProvider` (both `FutureProvider`s that
  `ref.watch(progressControllerProvider)` and `ref.watch(dueReviewsProvider)`
  purely as invalidation triggers — see "Established reactivity convention"
  above). This is what makes "no learning-flow changes" possible: those two
  providers already get touched/invalidated by existing M8/M10 code.
- `AchievementsScreen` (new `/achievements` route): `StreakCard` at top,
  `AchievementGrid` below showing all 6 catalog entries (locked ones
  greyed/dimmed via `Opacity`, matching the existing `ScriptCard`
  locked-state pattern).
- Reusable widgets (`lib/features/achievements/widgets/`): `AchievementCard`,
  `StreakCard` (optional `onTap`, used by the dashboard to link to
  `/achievements`), `AchievementGrid` (takes a plain `List<AchievementGridItem>`
  data list, not raw widgets — wraps `AchievementCard`s in a responsive
  `Wrap`, no fixed column count so it scales from phone to tablet),
  `achievement_icons.dart` (the `iconKey` → `IconData` lookup, shared by the
  achievements screen and the dashboard's "recently unlocked" card so the
  mapping isn't duplicated).
- Dashboard integration: new "Achievements" section between "Today's
  Reviews" and "Scripts" — `StreakCard` (tap → `/achievements`) plus a
  "recently unlocked" `AchievementCard` for the achievement with the most
  recent `unlockedAt` (falls back to a plain "Complete lessons to earn your
  first achievement." message when nothing is unlocked yet).

`flutter analyze`: **No issues found.**

### Runtime Verification

Verified on the same Android emulator used for prior milestones, using the
existing Hive data left over from Milestone 10's testing (1 completed
Hiragana lesson, 1 completed review) — no test-data manipulation was needed
this time, unlike Milestone 10.

- Dashboard's new Achievements section showed **"Current Streak: 1 Day" /
  "Longest Streak: 1 Day"**, correctly derived from that lesson's
  `lastAccessedAt` being today.
- The "recently unlocked" card correctly showed **"Reinforced — Complete
  your first review."** — this unlocked automatically purely from
  re-evaluating existing `ReviewRepository` data, with no code path in
  `learning_screen.dart` or anywhere in the learning flow touched.
- Tapping the streak card navigated to `/achievements`, which correctly
  showed **"First Steps"** (complete first lesson) and **"Reinforced"**
  fully colored/unlocked, and **"Building Momentum"** (5 lessons),
  **"Getting Consistent"** (3-day streak), **"One Week Strong"** (7-day
  streak) correctly greyed out/locked.
- No Dart exceptions in the runtime log throughout.

### Files Added

- `lib/features/achievements/models/achievement.dart`
- `lib/features/achievements/models/achievement_progress.dart`
- `lib/features/achievements/models/streak_info.dart`
- `lib/features/achievements/repositories/achievement_repository.dart`
- `lib/features/achievements/repositories/hive_achievement_repository.dart`
- `lib/features/achievements/services/achievement_service.dart`
- `lib/features/achievements/providers/achievement_providers.dart`
- `lib/features/achievements/widgets/achievement_card.dart`
- `lib/features/achievements/widgets/streak_card.dart`
- `lib/features/achievements/widgets/achievement_grid.dart`
- `lib/features/achievements/widgets/achievement_icons.dart`
- `lib/features/achievements/screens/achievements_screen.dart`

### Files Changed

- `lib/main.dart` (opens the `achievement_progress` Hive box)
- `lib/core/router/app_router.dart` (adds `/achievements`)
- `lib/features/dashboard/screens/dashboard_screen.dart` (adds the
  "Achievements" section)

No files under `lib/features/practice/`, `lib/features/writing/`,
`lib/features/hiragana/`, or `lib/features/progress/` were touched.

## Milestone 12: Settings & Data Management

Implemented and verified on device.

- `AppSettings` (`lib/features/settings/models/`): `themeMode`
  (`AppThemeMode.system/light/dark`), `soundEnabled`, `hapticsEnabled`,
  `showStrokeGuide`, `showGrid`, `autoPlayAudio`, `animationSpeed`
  (`AnimationSpeed.slow/normal/fast`), `preferredWritingHand`
  (`WritingHand.left/right`), `language`, `largerWritingArea`
  (accessibility, future-ready). All fields have defaults via
  `AppSettings.defaults`; `toMap()`/`fromMap()` follow the standard
  convention. `supportedLanguages` validation lives in the service, not the
  model.
- `SettingsRepository` / `HiveSettingsRepository`: Hive box `app_settings`,
  single key `settings`.
- `SettingsService`: validates (currently just `language` against
  `supportedLanguages`, falling back to the default), and owns
  `resetAllProgress()` — clears the `lesson_progress`, `review_schedule`,
  and `achievement_progress` Hive boxes directly via their repositories'
  public `boxName` constants (no new repository methods needed on those
  three repositories, no new coupling beyond reading a constant).
- `SettingsController` (`ChangeNotifier`) + `currentSettingsProvider`
  (`ChangeNotifierProvider`) — the pattern every later stateful feature
  (`audio`, `search`) copies.
- `SettingsScreen`: Appearance (theme), Learning (stroke guide/grid/
  animation speed), Feedback (sound/haptics), Accessibility (larger writing
  area, writing hand), Data Management (Export/Import placeholders — no
  real implementation, intentionally out of scope; Reset Progress / Reset
  Settings behind confirmation dialogs via `DangerZoneCard`), About
  (`AboutListTile`). Reusable widgets: `SettingsSection`, `SettingsTile`,
  `SettingsSwitchTile`, `SettingsDropdownTile`, `DangerZoneCard`.
- **Theme integration**: `AppTheme` was refactored into a shared `_build()`
  builder parameterized by color/text-theme inputs, adding `AppTheme.dark`
  alongside the existing `AppTheme.light` (previously there was no dark
  theme at all). `AppTypography` gained `darkTextTheme` alongside
  `textTheme` via the same extraction. `main.dart`'s `JapaneseLearningApp`
  wraps `MaterialApp.router` in a `Consumer` reading
  `currentSettingsProvider` to set `themeMode` live — changing the setting
  updates the whole app immediately, verified on device.

`flutter analyze`: **No issues found.**

### Files Added

- `lib/features/settings/models/app_settings.dart`
- `lib/features/settings/repositories/settings_repository.dart`
- `lib/features/settings/repositories/hive_settings_repository.dart`
- `lib/features/settings/services/settings_service.dart`
- `lib/features/settings/services/settings_controller.dart`
- `lib/features/settings/providers/settings_providers.dart`
- `lib/features/settings/widgets/settings_section.dart`
- `lib/features/settings/widgets/settings_tile.dart`
- `lib/features/settings/widgets/settings_switch_tile.dart`
- `lib/features/settings/widgets/settings_dropdown_tile.dart`
- `lib/features/settings/widgets/danger_zone_card.dart`
- `lib/features/settings/screens/settings_screen.dart` (replaces the old
  `lib/features/settings/settings_screen.dart` placeholder — file moved)

### Files Changed

- `lib/main.dart` (opens `app_settings` Hive box; `MaterialApp.router` now
  reads `currentSettingsProvider` for live theme switching)
- `lib/core/theme/app_theme.dart` (adds `AppTheme.dark`, shared `_build()`)
- `lib/core/theme/app_typography.dart` (adds `darkTextTheme`)
- `lib/core/theme/app_colors.dart` (adds dark-mode color constants)
- `lib/core/router/app_router.dart` (settings screen import path change)

## Milestone 13: Katakana Learning Module

Implemented and verified on device. This milestone introduced the
`ContentRepositoryFactory` pattern that every later milestone builds on.

- `assets/data/katakana_lessons.json`: all 46 basic Katakana characters,
  grouped into 10 lessons by gojūon row (vowels, ka/sa/ta/na/ha/ma row = 5
  each, ya row = 3, ra row = 5, wa+n = 3). Same field schema as
  `hiragana_lessons.json` (`character`/`romaji`/`englishName`, not the
  milestone brief's illustrative `symbol`/`primaryReading`/`meaning` names)
  — deliberate, to keep reusing `CharacterModel`/`JsonLoaderService`
  unmodified rather than maintaining two JSON conventions.
- `JsonLoaderService.loadLessons(assetPath)`: generalized from the
  Hiragana-only `loadHiraganaLessons()`, which now just calls it with a
  fixed path. Zero behavior change for Hiragana.
- `KatakanaRepository`: same shape as `HiraganaRepository` (not merged into
  a shared base class — three ~40-line near-identical repositories was
  judged an acceptable, low-risk level of duplication versus refactoring
  two already-working files; the real duplication that mattered,
  JSON-parsing, was already centralized in `JsonLoaderService`).
- **`ContentRepositoryFactory`** (`lib/repositories/content_repository_factory.dart`,
  new): `Map<String, LessonRepository Function()>` keyed by contentId.
  `contentSourcesProvider` (dashboard) is now generated from
  `availableContentIds` instead of a hardcoded single-entry list.
  `LearningScreen`, `dashboard_screen.dart`'s Continue Learning resolution,
  and `review_screen.dart`'s resolution were all switched from
  `if (contentId == 'hiragana') HiraganaRepository()` to
  `ContentRepositoryFactory.tryRepositoryFor(contentId)` — this is the
  change that makes Katakana (and Kanji, one milestone later) need zero
  special-case branches anywhere outside the factory.
- Router: `/practice/:lessonNumber` gained a `content` query parameter
  (defaults to `'hiragana'` for back-compat with existing review schedules
  already keyed `"hiragana:N"`).
- `KatakanaScreen`: real lesson-list screen (was a placeholder) — unlike
  `HiraganaScreen` (which only ever shows lesson 1, since Hiragana has just
  one), it lists all 10 lessons with per-lesson `LessonCard`s.
- Dashboard: the `Scripts` `Wrap` is now generated from
  `contentSourcesProvider` (`for (final source in contentSources) ...`)
  instead of three hardcoded `ScriptCard` literals; each card's subtitle
  (`"N% complete · N due"`) is computed per-script via a new
  `_resolveScriptSummary` helper.
- **Bug found and fixed during runtime verification**: `_resolveScriptSummary`
  initially read completion percentage from `ProgressController`'s in-memory
  cache (`progressController.completionPercentage(...)`), which is only
  populated after some screen calls `loadProgress(contentId)` — the
  Dashboard itself never does, so every card showed 0% regardless of real
  progress. Fixed by reading `ProgressRepository.getProgressForContent(...)`
  directly (matching how `StatisticsService` already did it), which needs
  no cache to be pre-warmed. Verified on device: Hiragana correctly showed
  100% after the fix, having shown 0% before it.

`flutter analyze`: **No issues found.**

### Files Added

- `assets/data/katakana_lessons.json`
- `lib/repositories/katakana_repository.dart`
- `lib/repositories/content_repository_factory.dart`

### Files Changed

- `lib/services/json_loader_service.dart` (generalized `loadLessons`)
- `lib/features/katakana/katakana_screen.dart` (placeholder → real screen)
- `lib/features/practice/learning_screen.dart` (`contentId` param, uses the
  factory instead of a hardcoded `HiraganaRepository`)
- `lib/core/router/app_router.dart` (`content` query param)
- `lib/features/dashboard/providers/dashboard_providers.dart`
  (`contentSourcesProvider` generated from the factory)
- `lib/features/dashboard/screens/dashboard_screen.dart` (generic Continue
  Learning resolution, dynamic Scripts section, `_resolveScriptSummary` bug
  fix)
- `lib/features/review/screens/review_screen.dart` (generic resolution)
- `pubspec.yaml` (registers the new JSON asset)

## Milestone 14: Kanji Foundation

Implemented and verified on device.

- `assets/data/kanji_lessons.json`: 79 JLPT N5 kanji — the standard Grade-1
  kyōiku (教育漢字) character set, chosen specifically because it's a
  well-defined, verifiable list rather than an ad-hoc N5 selection. Split
  into 8 lessons of ~10. Each entry adds (all optional on the shared
  models): `secondaryReadings`, `kunReadings`, `radical`, `grade` (always
  `1`), `jlptLevel` (always `"N5"`), `examples` (one `{word, reading,
  meaning}` per character), `notes` (unused so far).
- `CharacterModel` / `LearningItem` (`lib/models/`) extended with those same
  seven optional fields, defaulting to empty list / `null` — zero JSON
  changes needed for Hiragana/Katakana, and their `_toLearningItem` mapping
  code in `HiraganaRepository`/`KatakanaRepository` was **not** touched.
- `KanjiExample` (`lib/features/learning/models/`) — deliberately the only
  new supporting model; a `KanjiReading` model (also suggested by the
  brief) was judged unnecessary since plain `List<String>` already covers
  on/kun readings without adding a class.
- `KanjiRepository`: same shape as Hiragana/Katakana.
- Introduction-step UI (`lib/features/learning/widgets/`): `ReadingSection`
  (on/kun readings), `RadicalCard` (radical + stroke count),
  `ExampleWordCard` (one example word). Wired into
  `learning_screen.dart`'s introduction `Card`, gated on
  `currentStep == LearningStep.introduction && currentCharacter.radical !=
  null` — `radical` was chosen as the "is this actually Kanji metadata"
  flag since every Kanji entry sets it and Hiragana/Katakana never do.
- Dashboard: Kanji enabled (icon/title added to the existing per-script
  maps), the old static "Coming Soon" Kanji `ScriptCard` removed now that
  it comes through the same dynamic `contentSourcesProvider` loop as
  Katakana.
- **Bug found and fixed during runtime verification**: the new fields
  showed as blank on the introduction screen despite the JSON/model/
  repository all being correct. Root cause:
  `LearningController.startLesson` builds `LearningItem`s **directly** from
  `CharacterModel` in its own loop — it never calls the repository's
  `_toLearningItem`, which is only used by `getItem(id)` lookups. Fixed by
  threading the same seven fields through `LearningController`'s
  construction too. Worth remembering: `KanjiRepository._toLearningItem` is
  effectively dead code for the live learning session; the controller is
  the actual construction path.

`flutter analyze`: **No issues found.**

### Files Added

- `assets/data/kanji_lessons.json`
- `lib/repositories/kanji_repository.dart`
- `lib/features/learning/models/kanji_example.dart`
- `lib/features/learning/widgets/reading_section.dart`
- `lib/features/learning/widgets/radical_card.dart`
- `lib/features/learning/widgets/example_word_card.dart`

### Files Changed

- `lib/models/character_model.dart` / `lib/models/learning_item.dart`
  (seven new optional fields)
- `lib/features/practice/learning_controller.dart` (threads the new fields
  through — the actual bug fix)
- `lib/features/practice/learning_screen.dart` (renders the new widgets on
  the introduction step)
- `lib/features/kanji/kanji_screen.dart` (placeholder → real lesson-list
  screen, same pattern as `KatakanaScreen`)
- `lib/repositories/content_repository_factory.dart` (registers `'kanji'`)
- `lib/features/dashboard/screens/dashboard_screen.dart` (Kanji enabled,
  static card removed)
- `pubspec.yaml` (registers the new JSON asset)

## Milestone 15: Audio & Pronunciation System

Implemented and verified on device.

- `lib/features/audio/`: `AudioItem` (`id`, `assetPath`, `type` —
  `AudioType.character/word`, `script`). `AudioRepository` /
  `LocalAudioRepository`: resolves an asset path to an `AudioItem` only if
  `rootBundle.load(assetPath)` succeeds (try/catch, result cached per
  path) — this is what makes a missing recording fail safe instead of
  crashing. `AudioService` (`ChangeNotifier`, wraps `audioplayers`'
  `AudioPlayer`): `play()`/`stop()`/`setVolume()` (the last unused today,
  a "future-ready" extension point for a volume setting), exposes
  `AudioPlaybackState { status: idle/loading/playing/error, currentId }`
  so only the button for the character actually playing shows a spinner.
  Providers: `audioRepositoryProvider`, `audioServiceProvider`
  (`ChangeNotifierProvider`), `currentPlaybackStateProvider`.
- Widgets: `AudioButton` (resolves availability itself via a cached
  `Future<AudioItem?>` in a `ConsumerStatefulWidget`, so callers never
  check availability; disables with "Audio not available" /
  "Sound is off" / "Checking audio…" labels as appropriate),
  `PlaybackIndicator` (the icon/spinner), `PronunciationCard` (symbol +
  `AudioButton`, for future reuse outside the learning flow).
- `learning_screen.dart`: `AudioButton` added under the symbol on every
  step (not just introduction); auto-play on entering the introduction
  step for a new character, gated on `settings.soundEnabled &&
  settings.autoPlayAudio`, tracked via a `_autoPlayedItemId` guard so it
  fires once per character (reset on Restart).
- **Audio assets — read this before assuming anything plays real speech.**
  Only 5 files exist: `assets/audio/hiragana/{a,i,u,e,o}.wav`, short
  synthesized sine-wave tones (pure Python `wave` module, distinct
  frequency per vowel) generated purely to prove the play → resolve →
  asset-load → playback-complete pipeline works end-to-end without
  throwing — **not** real Japanese pronunciation. `hiragana_lessons.json`'s
  5 `audioAsset` paths were updated from `.mp3` to `.wav` to point at them.
  Katakana and Kanji have **zero** audio files by design, specifically to
  exercise and demonstrate the missing-asset path (verified on device:
  あ shows a working "Play Pronunciation" button, ア shows a disabled
  "Audio not available" button, no crash either way). `assets/audio/
  {hiragana,katakana,kanji}/` are registered as folder-level pubspec asset
  entries (with `.gitkeep` placeholders in the two empty ones) specifically
  so that dropping real recordings in later requires **no pubspec or code
  changes** — that was an explicit design goal, not an accident.
- Not implemented (explicitly out of scope per the milestone): the
  lesson-card speaker icon (marked "optional" in the brief, absent from its
  stop-condition list), and a settings-screen volume control (marked
  "future-ready"). The "sound disabled" `AudioButton` state was verified by
  code review, not live on-device — there's no navigation entry point from
  the Dashboard to `/settings` yet (pre-existing gap, still open).

`flutter analyze`: **No issues found.**

### Files Added

- `lib/features/audio/models/audio_item.dart`
- `lib/features/audio/repositories/audio_repository.dart`
- `lib/features/audio/repositories/local_audio_repository.dart`
- `lib/features/audio/services/audio_service.dart`
- `lib/features/audio/providers/audio_providers.dart`
- `lib/features/audio/widgets/audio_button.dart`
- `lib/features/audio/widgets/playback_indicator.dart`
- `lib/features/audio/widgets/pronunciation_card.dart`
- `assets/audio/hiragana/{a,i,u,e,o}.wav`

### Files Changed

- `assets/data/hiragana_lessons.json` (5 `audioAsset` paths → `.wav`)
- `lib/features/practice/learning_screen.dart` (`AudioButton` + auto-play)
- `pubspec.yaml` (registers `assets/audio/{hiragana,katakana,kanji}/`)

## Milestone 16: Universal Search & Dictionary

Implemented and verified on device.

- `lib/features/search/`: `SearchResult` (`id`, `symbol`, `script`, `title`,
  `subtitle`, `searchKeywords`, `matchedField`, `learningItem`) and
  `FavoriteItem` (`script`, `itemId`, `symbol`, `createdAt`) models.
- `OfflineSearchRepository`: builds its index from `contentSourcesProvider`
  (the same list the dashboard uses — no parallel per-script data access),
  calling each repository's `getAllLessons()` then `getItem(id)` per
  character (O(n²) in character count, but n ≈ 130 today so this is free;
  revisit only if content grows by an order of magnitude). Matching walks
  a fixed field priority (`symbol → romaji → reading → meaning → jlptLevel
  → radical → strokeCount`) and returns the first field that contains the
  (already-lowercased) query, plus a digits-only fallback so `"5 strokes"`
  matches stroke count `5`. `SearchResult.matchedField` is therefore always
  computed at query time, never cached on the index.
- `SearchService`: normalizes (trim + lowercase), takes the repository's
  direct matches, adds a Levenshtein-distance-≤1 fuzzy fallback against the
  full index only when direct matches are sparse (< 5 results) and the
  query is ≥ 2 characters, ranks everything (exact symbol match > exact
  keyword > prefix match > substring match > fuzzy-only), and groups by
  script for the UI.
- `FavoritesRepository`/`HiveFavoritesRepository` (Hive box `favorites`) and
  `SearchHistoryRepository`/`HiveSearchHistoryRepository` (Hive box
  `search_history`, capped at 10, most-recent-first, de-duplicated
  case-insensitively) — each paired with a `ChangeNotifier` controller
  (`FavoritesController`, `SearchHistoryController`) following the M12
  pattern.
- Providers: `searchRepositoryProvider`, `searchServiceProvider`,
  `favoritesProvider`, `searchHistoryProvider`, `searchQueryProvider`
  (`StateProvider<String>`), `searchResultsProvider` (`FutureProvider`,
  watches the query provider — real-time search with no debounce needed at
  this data scale), `allSearchResultsProvider` (the unfiltered index, used
  for "Popular" suggestions without re-running a search).
- `SearchScreen`: `AppSearchBar` (named to avoid colliding with Flutter's
  own Material 3 `SearchBar` widget) at top; when the query is empty shows
  Recent (chips from history), Popular (first 2 lesson-1 characters per
  script from the index — an honest "commonly-learned basics" proxy, not a
  claim of real usage analytics), and Continue Learning (same resolution
  pattern as the dashboard's card, duplicated locally per the established
  screen-level-resolution convention); otherwise shows results grouped by
  script via `SearchSection`/`SearchResultTile`. Reusable widgets:
  `AppSearchBar`, `SearchResultTile`, `SearchSection`, `EmptySearchState`,
  `RecentSearchChip`, `FavoriteButton`.
- Dashboard: new "Quick Search" `FeatureCard` (that widget existed since
  early milestones but was unused until now) linking to `/search`.
- **Selecting a result reuses the existing learning flow, not a new detail
  screen** — `LearningController.startLesson` and `LearningScreen` gained
  an optional `startCharacterId`; if set, the session's initial character
  index is looked up by id instead of defaulting to `0`. The router's
  `/practice/:lessonNumber` gained a `char` query parameter for this.
  Preserved across `restartLesson()`. Verified on device: searching
  `"water"` → tapping 水 opens Kanji Lesson 5 already on "Character 2 of
  10" (水 itself), not lesson start.
- **Bug found and fixed during runtime verification**: opening a Kanji
  character from search (or, it turns out, normally) showed a 44px bottom
  overflow on the Previous/Next/Restart button row. Root cause predates
  this milestone: `learning_screen.dart`'s practice `Column` was never
  wrapped in a scrollable — harmless while the introduction card was short
  (Hiragana/Katakana), but M14's Kanji introduction content (readings +
  radical + example) made it taller than the viewport. Fixed by wrapping
  the `Column` in a `SingleChildScrollView`; verified the same 水 screen
  scrolls cleanly with all four buttons reachable.

`flutter analyze`: **No issues found.**

### Files Added

- `lib/features/search/models/search_result.dart`
- `lib/features/search/models/favorite_item.dart`
- `lib/features/search/repositories/search_repository.dart`
- `lib/features/search/repositories/offline_search_repository.dart`
- `lib/features/search/repositories/favorites_repository.dart`
- `lib/features/search/repositories/hive_favorites_repository.dart`
- `lib/features/search/repositories/search_history_repository.dart`
- `lib/features/search/repositories/hive_search_history_repository.dart`
- `lib/features/search/services/search_service.dart`
- `lib/features/search/services/favorites_controller.dart`
- `lib/features/search/services/search_history_controller.dart`
- `lib/features/search/providers/search_providers.dart`
- `lib/features/search/screens/search_screen.dart`
- `lib/features/search/widgets/search_bar_field.dart` (`AppSearchBar`)
- `lib/features/search/widgets/search_result_tile.dart`
- `lib/features/search/widgets/search_section.dart`
- `lib/features/search/widgets/empty_search_state.dart`
- `lib/features/search/widgets/recent_search_chip.dart`
- `lib/features/search/widgets/favorite_button.dart`

### Files Changed

- `lib/features/practice/learning_controller.dart` (`startCharacterId`)
- `lib/features/practice/learning_screen.dart` (`startCharacterId` param;
  **`SingleChildScrollView` overflow fix**)
- `lib/core/router/app_router.dart` (`char` query param; `/search` route)
- `lib/features/dashboard/screens/dashboard_screen.dart` ("Quick Search"
  `FeatureCard`)
- `lib/main.dart` (opens `favorites` and `search_history` Hive boxes)

## Milestone 17: Advanced Practice Modes (Quiz Engine)

Implemented and verified on device.

- **Naming deviation from the milestone brief, deliberate**: the brief
  specified `lib/features/practice/{models,repositories,...}`, but
  `lib/features/practice/` already existed — it's the guided-lesson flow
  (`learning_controller.dart` + `learning_screen.dart`, routed at
  `/practice/:lessonNumber`), added long before this milestone and not a
  standard multi-subfolder feature. Per `PROJECT_RULES.md` ("do not rename
  files, folders, classes, or public APIs unless required"), renaming that
  existing feature to free up the name was rejected — it would have touched
  `app_router.dart`, `dashboard_screen.dart`, `review_screen.dart`, and
  `search_screen.dart`, all of which build `/practice/...` URLs today. The
  new engine lives in **`lib/features/quiz/`** instead (full
  `models/repositories/services/providers/screens/widgets` shape, matching
  `search/`), with routes `/quiz`, `/quiz/play`, `/quiz/results`. All
  user-facing copy still says "Practice" (dashboard section, screen
  headings, card titles) — only the internal folder/route name differs from
  the brief.
- Models (`lib/features/quiz/models/`): `PracticeMode` (static catalog
  entry — id/title/description/iconKey/difficulty/supportedScripts, not
  persisted); `PracticeQuestion` (`QuestionType` enum
  `recognition/meaning/reading/listening`, one shared model every mode
  builds); `PracticeSession` (in-memory only, mirrors `LearningSession`'s
  immutable-state-machine shape — not Hive-persisted, since nested
  `LearningItem`/`PracticeQuestion` data doesn't fit the flat `toMap`
  convention); `PracticeResult` (the persisted session summary — flat
  fields, `toMap`/`fromMap` with ISO8601 dates, exactly the
  `LessonProgress`/`ReviewItem` convention; carries `incorrectItemIds` which
  is what powers Weak Items generation from history); `PracticeStatistics`
  (aggregate value object computed from every `PracticeResult`, mirrors
  `LearningStatistics`'s relationship to `StatisticsService`).
- `PracticeRepository` / `HivePracticeRepository`: Hive box
  `practice_results`, keyed by result id — exact shape of
  `HiveReviewRepository`.
- `PracticeGenerator` (`lib/features/quiz/services/`): `static const
  catalog` of exactly 6 modes (`recognition`, `meaning`, `reading`,
  `listening`, `mixed`, `weak_items`). One private question-type builder per
  `QuestionType` shared across every mode — a mode only decides which
  builder(s) and which item pool to use, so quiz logic isn't duplicated 6
  times. Item pool is pulled via `getAllLessons()` then `getItem(id)` per
  character through `ContentRepositoryFactory` — the same pattern
  `OfflineSearchRepository` established in M16 — deliberately **not** a
  manual `LearningItem` reconstruction from `CharacterModel` (that was the
  exact bug class fixed in M14; calling the repository's own `getItem`
  avoids repeating it a third place). Distractors: 3 random items from the
  same script, falling back cross-script if a script's pool has fewer than
  4 items (relevant because Hiragana has only 5 characters total).
  Configurable session length (10/20/50) cycles through a reshuffled pool
  when the requested count exceeds the available unique items.
  - **Listening mode and the audio-honesty rule**: the item pool is
    filtered to characters with audio verified via
    `AudioRepository.resolveAudio` — today that's effectively only the 5
    Hiragana vowels (Katakana/Kanji have zero audio files, per M15). No new
    placeholder audio was added to work around this, per
    `PROJECT_RULES.md`'s "Audio asset honesty" rule. `PracticeHomeScreen`
    disables the Listening card with "Not enough audio available yet." if
    the filtered pool has fewer than 4 items (`listeningModeAvailableProvider`),
    the same graceful-degradation pattern the M15 `AudioButton` already
    uses for missing assets — verified true (enabled) on device today,
    since the 5 Hiragana vowels are exactly enough.
  - **Weak Items mode**: pool built from lessons with
    `bestWritingAccuracy < 70` (`ProgressRepository`), overdue reviews
    (`ReviewRepository`), and every past `PracticeResult.incorrectItemIds`
    (`PracticeRepository`) — deduped, falls back to the full pool if no
    weak-signal data exists yet so the mode never returns empty.
- `PracticeService` (`ChangeNotifier`, exact shape of `AudioService`):
  `startSession`/`startReviewMistakes`/`submitAnswer`/`clearSession`. On the
  final answer it persists a `PracticeResult` via `PracticeRepository` and
  exposes it as `lastResult`.
- `PracticeStatisticsService`: aggregates every `PracticeResult` into
  `PracticeStatistics` (total sessions/questions, accuracy/best-score/
  last-played per mode, most-practiced and weakest script, a practice
  streak computed the same "distinct dates, walk backward" way
  `AchievementService.calculateStreak` already does — sourced from
  `PracticeResult.endTime` instead of `LessonProgress.lastAccessedAt`;
  duplicated rather than shared, matching the project's existing tolerance
  for this kind of small duplication over a forced cross-feature
  abstraction, e.g. the three near-identical script repositories from M13).
- Providers (`lib/features/quiz/providers/practice_providers.dart`) follow
  the established repository → service → `ChangeNotifierProvider`/
  `FutureProvider` shape; `practiceStatisticsProvider` and
  `practiceResultsProvider` both `ref.watch(practiceServiceProvider)` purely
  as an invalidation trigger — the same reactivity convention every feature
  since M9 uses, no manual `ref.invalidate()` calls added.
- Screens: `PracticeHomeScreen` (`/quiz` — mode grid with per-mode best
  score/last played, session-length selector), `PracticeSessionScreen`
  (`/quiz/play?mode=&scripts=&length=`, or `?mode=&items=` for "Review
  Mistakes" — reads query params once via a `_started` guard, submits
  answers with a brief reveal delay, auto-navigates to results when the
  session completes), `PracticeResultsScreen` (`/quiz/results` — score/
  accuracy/correct/incorrect/time/characters practiced/areas to review;
  Retry, Review Mistakes, Return Home actions). Widgets: `PracticeCard`,
  `QuestionCard` (reuses the existing `AudioButton` for Listening
  questions), `AnswerOption`, `ScoreCard`, `SessionSummaryCard`,
  `PracticeModeSelector`, `practice_icons.dart`.
- **Achievement integration**: `AchievementCriteria` gained 4 values
  (`practiceSessionsCompleted`, `practiceQuestionsAnswered`,
  `perfectPracticeSessions`, `practiceStreakDays`); `AchievementService`
  gained a `required PracticeStatisticsService practiceStatisticsService`
  constructor dependency (same shape as its existing `ReviewRepository`/
  `StatisticsService` deps) and 4 new `_meetsCriteria` switch cases
  (Dart-enforced exhaustive, so a 5th criteria without a case would be a
  compile error, not a silent no-op). 6 new catalog entries reuse those 4
  criteria at different thresholds: `first_practice_session` (1 session),
  `perfect_practice_score` (1 perfect session), `practice_sessions_10` (10
  sessions), `practice_questions_100` / `practice_questions_500`, and
  `practice_streak_30` (30-day streak). `AchievementsScreen` needed **zero**
  changes — it already iterates `AchievementService.catalog` generically.
  `achievementProgressListProvider` and its dependents additionally
  `ref.watch(practiceServiceProvider)` as an invalidation trigger.
- **Dashboard integration**: new "Practice" section between "Achievements"
  and "Scripts" — `SessionSummaryCard` ("Start Practice" / "Continue Last
  Practice", resolving the most recent `PracticeResult`'s mode title via
  `PracticeGenerator.modeById`), plus three `StatisticCard`s (Sessions This
  Week, Weekly Accuracy — both computed inline from `practiceResultsProvider`
  the same way `_resolveScriptSummary` is computed inline elsewhere in this
  file — and Best Quiz Score from `PracticeStatistics.bestScore`).
  `dashboard_providers.dart` needed no changes; the quiz feature has its own
  providers file, imported directly into `dashboard_screen.dart` the same
  way achievements/review already are.
- `lib/main.dart` opens the new `practice_results` Hive box via
  `HivePracticeRepository.boxName` (the newer constant-reference style, not
  the older string-literal style the first two boxes use).

`flutter analyze`: **No issues found.**

### Runtime Verification

Verified on the same Android emulator (API 37, `emulator-5554`) used for
every prior milestone.

- Dashboard's new "Practice" section rendered correctly pre-session ("Get
  Started" / "Try a quiz mode..." / "Start Practice", all three stat cards
  showing placeholder `--`/`0` states).
- `PracticeHomeScreen` showed all 6 modes with correct titles, difficulty
  labels, descriptions, and "Best: -- · Not played yet"; Listening Quiz was
  enabled (not greyed out), confirming the audio-pool availability check
  correctly found the 5 real Hiragana vowel recordings.
- Started a 10-question Listening Quiz: each question correctly showed the
  reused `AudioButton` ("Play Pronunciation") and 4 Hiragana-symbol choices;
  answering advanced through all 10 questions with the reveal delay working
  and no repeated/stuck questions, confirming the reshuffle-and-cycle logic
  for a session length (10) larger than the unique pool (5 Hiragana vowels).
- Results screen correctly showed **20% Accuracy, 2 Correct, 8 Incorrect,
  2m 20s Time, 10 Characters Practiced**, "8 character(s) to review.", and
  all three actions (Return Home / Review Mistakes / Retry) present only
  where applicable.
- Returning to `/quiz` immediately showed the Listening Quiz card updated
  to **"Best: 20% · Last played 7/26/2026"**, confirming persistence and
  the `practiceStatisticsProvider` invalidation trigger both work.
- Dashboard's Practice section updated to **"Continue" / "Listening Quiz" /
  "Continue Last Practice"**, **"1" Sessions This Week**, **"20%" Weekly
  Accuracy** — confirming the dashboard's own invalidation watch works
  without any manual refresh.
- Achievements section's "recently unlocked" card updated to **"Quiz
  Novice — Complete your first practice session."**, confirming the new
  `AchievementCriteria.practiceSessionsCompleted` case fired correctly
  end-to-end through the new `PracticeStatisticsService` dependency, with
  **zero changes needed in `AchievementsScreen`** itself.
- Force-restarted the app (killed and relaunched, cold start) and confirmed
  the dashboard still showed the same 20% best score / session data —
  verifies the `practice_results` Hive box is opened correctly at boot in
  `main.dart` and survives a real app restart, not just in-memory state.
- Checked the full `flutter run` log across the entire session: no Dart
  exceptions, no `FlutterError` output, only benign platform log lines
  (frame-skip warnings, an unrelated `HWUI` EGL format notice).
- Regression spot check: Hiragana/Katakana/Kanji dashboard stats, the
  existing "Today's Reviews" section, and the guided-lesson `/practice/1`
  flow were all visible and unaffected in the same screenshots — nothing
  under `lib/features/practice/`, `lib/features/writing/`,
  `lib/features/hiragana/`/`katakana/`/`kanji/`, or `lib/features/review/`
  was touched by this milestone.

### Files Added

- `lib/features/quiz/models/practice_mode.dart`
- `lib/features/quiz/models/practice_question.dart`
- `lib/features/quiz/models/practice_session.dart`
- `lib/features/quiz/models/practice_result.dart`
- `lib/features/quiz/models/practice_statistics.dart`
- `lib/features/quiz/repositories/practice_repository.dart`
- `lib/features/quiz/repositories/hive_practice_repository.dart`
- `lib/features/quiz/services/practice_generator.dart`
- `lib/features/quiz/services/practice_service.dart`
- `lib/features/quiz/services/practice_statistics_service.dart`
- `lib/features/quiz/providers/practice_providers.dart`
- `lib/features/quiz/screens/practice_home_screen.dart`
- `lib/features/quiz/screens/practice_session_screen.dart`
- `lib/features/quiz/screens/practice_results_screen.dart`
- `lib/features/quiz/widgets/practice_card.dart`
- `lib/features/quiz/widgets/question_card.dart`
- `lib/features/quiz/widgets/answer_option.dart`
- `lib/features/quiz/widgets/score_card.dart`
- `lib/features/quiz/widgets/session_summary_card.dart`
- `lib/features/quiz/widgets/practice_mode_selector.dart`
- `lib/features/quiz/widgets/practice_icons.dart`

### Files Changed

- `lib/main.dart` (opens `practice_results` Hive box)
- `lib/core/router/app_router.dart` (adds `/quiz`, `/quiz/play`,
  `/quiz/results`)
- `lib/features/achievements/models/achievement.dart` (4 new
  `AchievementCriteria` values)
- `lib/features/achievements/services/achievement_service.dart` (6 new
  catalog entries, `practiceStatisticsService` constructor dependency, 4
  new `_meetsCriteria` cases)
- `lib/features/achievements/providers/achievement_providers.dart` (wires
  the new dependency; adds an invalidation watch)
- `lib/features/dashboard/screens/dashboard_screen.dart` (new "Practice"
  section between Achievements and Scripts)

No files under `lib/features/practice/`, `lib/features/writing/`,
`lib/features/hiragana/`/`katakana/`/`kanji/`, or `lib/features/review/`
were touched.

## Milestone 18: Learning Analytics & Insights

Implemented and verified on device. Purely additive/read-only — no
existing repository, service, or model in any other feature was modified;
every number shown here is derived live from data those features already
persist.

- **No chart package.** No charting library is in the approved dependency
  list, and `PROJECT_RULES.md` forbids adding dependencies without
  explicit approval. `TrendChart` (`lib/features/analytics/widgets/`) is a
  small `CustomPainter` line chart instead — a `List<TrendSeries>` in, a
  painted widget out, so a real charting package could replace the
  internals later without touching callers. `ActivityHeatmap` is similarly
  a plain `Wrap` of colored `Container`s (no package).
- **`AnalyticsRepository`/`HiveAnalyticsRepository`** (Hive box
  `analytics_snapshot`) persist only a small `AnalyticsSnapshot` (scalar
  totals + timestamp) as a side effect of every `AnalyticsService
  .getAnalytics()` call — not a competing read path. Every other *Service
  in this app (`StatisticsService`, `AchievementService`,
  `PracticeStatisticsService`) recomputes fresh on every call with no
  caching precedent, and this app's data volume is small enough that this
  is free; `AnalyticsService.getAnalytics()` follows the same rule and is
  what every screen actually watches.
- **`AnalyticsService`** (`lib/features/analytics/services/`) aggregates,
  reusing existing services/repositories directly rather than
  recomputing their logic: `PracticeStatisticsService` for quiz stats,
  `AchievementService.calculateStreak` for the *same* streak already shown
  on the dashboard/achievements screen (not a second parallel one),
  `AchievementRepository.getAllProgress()` for unlock state (read-only,
  unlike `evaluateAchievements` which has persistence side effects). Produces
  a `LearningAnalytics`: script breakdown, a trailing-30-day
  `DailyLearningStat` activity log, sorted/capped `WeakArea`s (low writing
  accuracy, most-missed quiz items via `PracticeResult.incorrectItemIds`,
  most-overdue reviews), a handful of deterministic `insights` strings
  (streak callout, week-over-week accuracy delta, strongest/weakest quiz
  mode, days-since-last-review per script), and `NextAchievement` progress
  fractions for locked achievements (computed via a `_currentValueFor`
  switch that mirrors `AchievementService._meetsCriteria`'s shape — the
  same small, accepted duplication `PracticeStatisticsService`'s streak
  calc already established in M17).
- **Disclosed data limitations** (real data, not fabricated, but worth
  knowing before trusting these numbers):
  - `ReviewScheduler` has no failure-tracking path (`recordSuccessfulReview`
    is the only outcome ever recorded), so "Review success rate" in the
    trend chart is always 100% on any day with a review — an honest
    reflection of the current scheduler, not invented pass/fail data.
  - `ReviewItem` stores only the single most recent `lastReviewed`
    timestamp per lesson (no full review-event history), so the 30-day
    activity log's reviews-per-day undercounts lessons reviewed more than
    once in that window.
  - `PracticeResult` (M17) records session-level accuracy across every
    script touched in that session, not a per-script breakdown, so
    `ScriptAnalytics.averageQuizAccuracy` is an approximation (average of
    sessions that touched that script at all).
  - "Estimated Study Minutes" is a heuristic, clearly labeled "(est.)" in
    the UI: real `PracticeResult` durations + 3 minutes per completed
    lesson + 1 minute per recorded review.
- **`AnalyticsExportService`**: pure `toCsv`/`toJson` string builders plus
  `exportToFile` using `path_provider`'s `getApplicationDocumentsDirectory()`
  (already an approved, previously-unused dependency) and `dart:io`'s
  `File` — the first file I/O in this codebase. Analytics-only, distinct
  from the still-placeholder full-progress Export/Import on the Settings
  screen (M12, untouched).
- Providers (`lib/features/analytics/providers/analytics_providers.dart`):
  `learningAnalyticsProvider` (`FutureProvider`, watches
  `progressControllerProvider`/`dueReviewsProvider`/`practiceServiceProvider`/
  `achievementProgressListProvider` purely as invalidation triggers — the
  established reactivity convention) and `scriptAnalyticsProvider` (a
  plain `Provider` deriving `.scriptBreakdown` from the same computation,
  not a second aggregation).
- `AnalyticsScreen` (`/analytics`): Overall Progress (`ProgressRing` +
  `StatisticCard`s), Script Breakdown (`ScriptSummaryCard` per script),
  Accuracy Trends (`TrendChart`), Activity Calendar (`ActivityHeatmap`),
  Weak Areas (`WeakAreaCard` list + a "Practice Now" button that routes to
  `/quiz/play?mode=weak_items&length=10` — reuses `PracticeGenerator`'s
  existing weak-item generation exactly as-is, zero new wiring), Achievement
  Summary (unlocked/total + next-achievement progress bars, reusing
  `achievementIconForKey`), Study Insights (`InsightCard` list). An export
  menu in the app bar calls `AnalyticsExportService` and shows a snackbar
  with the saved path or an error.
- Dashboard integration: new "View Analytics" `FeatureCard` (same shape as
  the existing "Quick Search" card) plus a 3-stat row — Weekly Activity,
  Average Accuracy, Practice Trend (Improving/Declining/Steady/"No data
  yet", comparing the trailing 7 days of `dailyActivity` against the
  preceding 7) — both sourced from the same `learningAnalyticsProvider`,
  no dashboard-specific computation added.

`flutter analyze`: **No issues found.**

### Runtime Verification

Verified on the same Android emulator (API 37, `emulator-5554`), using the
real data already on the device from Milestone 17's testing (1 completed
Listening Quiz session, 8/10 answers incorrect, 2 completed lessons).

- Dashboard's new "View Analytics" card and quick-metrics row (Weekly
  Activity: 5, Average Accuracy: 1%, Practice Trend: "No data yet" — correct,
  since fewer than 14 days of history exist) rendered correctly and linked
  to `/analytics`.
- Overall Progress matched the dashboard's own numbers exactly: 11%
  completion, 2 lessons completed, 1 practice session, 1 total review, 9
  min estimated study time, 1-day current/longest streak.
- Script Breakdown showed all three scripts with correct per-script
  numbers (Hiragana: 100% complete, 1% writing accuracy, 20% quiz
  accuracy, 1 practice session; Katakana/Kanji correctly near-zero).
- Accuracy Trends and the Activity Calendar both rendered against the
  sparse real history (a `CustomPainter` line segment and two highlighted
  heatmap cells on the two most recent active days) with no rendering
  errors on a chart with mostly-null data points.
- Weak Areas correctly surfaced **Lesson あ** and **Lesson ア** (1% writing
  accuracy) plus **あ/お/え** (missed 2× in quizzes) and **い/う** (missed
  1× each) — an exact match for the M17 test session's 8 incorrect
  answers. Tapping "Practice Now" launched a real Weak Items quiz session
  starting on カ タ カ ナ オ, confirming the same weak-signal data
  `PracticeGenerator._generateWeakItems` already used is what Analytics
  surfaces.
- Achievement Summary correctly showed **3 / 12** unlocked.
- Study Insights showed "Listening Quiz is your strongest practice mode
  (20% accuracy)" — correct, it's the only mode played so far.
- Exported both CSV and JSON via the app bar menu; both saved successfully
  (snackbar confirmed the file path) and were pulled from the device via
  `adb shell run-as` for inspection: the CSV contained well-formed summary/
  script/daily-activity/weak-areas sections, and the JSON parsed cleanly
  with `json.load` and contained the same data structured as nested
  objects.
- No Dart exceptions or `FlutterError` output anywhere in the `flutter run`
  log across the full session (dashboard → analytics → weak items quiz →
  export ×2); only benign platform log lines.
- Regression check: dashboard's pre-existing sections, the quiz flow
  (including a real Weak Items session launched from Analytics), and app
  restart persistence were all exercised in the same session with no
  issues.

### Files Added

- `lib/features/analytics/models/daily_learning_stat.dart`
- `lib/features/analytics/models/script_analytics.dart`
- `lib/features/analytics/models/weak_area.dart`
- `lib/features/analytics/models/learning_analytics.dart`
- `lib/features/analytics/models/analytics_snapshot.dart`
- `lib/features/analytics/repositories/analytics_repository.dart`
- `lib/features/analytics/repositories/hive_analytics_repository.dart`
- `lib/features/analytics/services/analytics_service.dart`
- `lib/features/analytics/services/analytics_export_service.dart`
- `lib/features/analytics/providers/analytics_providers.dart`
- `lib/features/analytics/screens/analytics_screen.dart`
- `lib/features/analytics/widgets/statistic_card.dart`
- `lib/features/analytics/widgets/trend_chart.dart`
- `lib/features/analytics/widgets/progress_ring.dart`
- `lib/features/analytics/widgets/insight_card.dart`
- `lib/features/analytics/widgets/script_summary_card.dart`
- `lib/features/analytics/widgets/activity_heatmap.dart`
- `lib/features/analytics/widgets/weak_area_card.dart`

### Files Changed

- `lib/main.dart` (opens `analytics_snapshot` Hive box)
- `lib/core/router/app_router.dart` (adds `/analytics`)
- `lib/features/dashboard/screens/dashboard_screen.dart` (new "View
  Analytics" section)

No files under `lib/features/progress/`, `lib/features/review/`,
`lib/features/quiz/`, or `lib/features/achievements/` were modified —
this milestone only reads from their existing repositories/services.

## Milestone 19: Polish, Accessibility & Performance

Implemented and verified on device. This milestone's brief spanned 12
open-ended areas (UI consistency, accessibility, responsive layout,
performance, animation, error handling, offline validation, startup,
settings, data integrity, testing, docs) — broader than any prior
milestone and not a bounded feature. Three parallel codebase surveys
(accessibility/UI/error-handling, performance/responsive/startup,
testing/docs/data-integrity) identified the real gaps first; the plan
then made explicit, disclosed scope decisions per area rather than
attempting unlimited depth everywhere. Below is what was actually done,
plus what was deliberately deferred and why.

- **Data integrity & error handling**: every Hive `fromMap` factory
  previously used unchecked `as` casts with no try/catch anywhere in the
  read path — a single corrupted record would throw uncaught. New
  `lib/core/utils/safe_parse.dart` (`T? safeParse<T>(...)`) catches any
  parse failure and returns `null`; all 8 `Hive*Repository` list-read
  methods now use it (`.map((v) => safeParse(v, X.fromMap)).whereType<X>()`),
  so one bad record is skipped instead of crashing the whole read.
  `lib/main.dart`'s box-opening now goes through `_openBoxSafely`, which
  deletes and recreates a box that fails to open rather than crashing
  `main()` at launch. Separately, `SettingsService.resetAllProgress()` was
  found to only clear 3 of the 8 Hive boxes — missing `practice_results`
  and `analytics_snapshot` (an M17/M18 oversight) — now fixed to clear all
  5 progress-related boxes (favorites/search history are intentionally
  left alone). `PROJECT_RULES.md`'s Hive-boxes list, which was stale since
  M17, now lists all 8.
- **Performance/startup**: the 8 `Hive.openBox` calls in `main.dart` were
  sequential; they're now a single `Future.wait([...])` (combined with the
  corrupted-box recovery above) — claimed at the time to be roughly 8x
  less sequential latency in that startup phase. **This claim was wrong
  and was corrected in M20**: the change was never measured here, and M20's
  A/B test on device found parallel and sequential box opening to be
  indistinguishable (~3.8s median either way). The cost is cold disk I/O,
  not the concurrency strategy. The `Future.wait` was left in place because
  it is no worse; see the M20 entry and the comment on `_openBoxSafely`.
  `dashboard_screen.dart`'s weekly-summary helper no
  longer implicitly re-derives "now" on every call path.
- **Accessibility**: only one `Tooltip` existed anywhere in the app before
  this milestone. `AudioButton` (icon-only) now has a `tooltip` matching
  its existing visible label logic; the search bar's clear button gained
  one too. `MaterialApp.router`'s `builder` now wraps the app in
  `MediaQuery.withClampedTextScaling(minScaleFactor: 1.0, maxScaleFactor:
  1.6)` — verified on device with the system font scale set to 2.0x: text
  visibly grows but layouts don't overflow, confirming the clamp is
  active. Touch targets were audited (no `iconSize`/`visualDensity`
  overrides found shrinking anything below Material's 48dp default) — no
  code change needed there.
- **UI consistency**: theme-token usage was already strong (a full-codebase
  survey found only 2 stray hardcoded values — both fixed:
  `analytics_screen.dart`'s `BorderRadius.circular(4)` → `AppRadius.small`,
  `script_summary_card.dart`'s raw `EdgeInsets.symmetric(vertical: 2)` →
  `AppSpacing.xs / 2`). The real gap was 15 separate ad hoc
  `Center(child: CircularProgressIndicator())` loading states with no
  shared widget. New `lib/shared/widgets/loading_indicator.dart`,
  `empty_state.dart`, `error_state.dart`; `LoadingIndicator` was adopted
  across all 15 sites found (mechanical swap, confirmed via
  `grep`-for-zero-remaining-instances after).
- **Responsive**: `lib/core/utils/responsive.dart` was already defined but
  essentially unused (one call site). The one real issue found —
  `practice_home_screen.dart`'s mode cards at a hardcoded `width: 320`,
  tight on a 360dp phone — now uses a `LayoutBuilder` to cap at 320 but
  shrink to fit narrower screens. Other flagged card widths (280/200/150dp)
  were left as-is: they reflow correctly via `Wrap` and only produce mild
  tablet whitespace, not overflow.
- **Animation**: `AnswerOption`'s neutral/correct/incorrect color change is
  now an `AnimatedContainer` (~200ms) instead of an instant swap — verified
  on device (visible red/green tint transition on reveal).
  `AchievementCard` gets a brief scale-in (`TweenAnimationBuilder`, ~250ms,
  `Curves.easeOutBack`) when unlocked, used on the dashboard's
  "recently unlocked" card and the achievements grid.
- **Offline validation**: confirmed, not new work — `grep` for `http`,
  `dio`, or any network package import across `lib/` returns nothing; the
  app has no network dependency to validate away.
- **Settings enhancements**: new "Diagnostics" section — a real storage-
  usage figure (`SettingsService.getStorageUsageBytes()` sums each Hive
  box's on-disk file size via `path_provider`, already an approved,
  previously-unused dependency) and a "Licenses" tile using Flutter's
  built-in `showLicensePage()`. Verified on device: showed "10.3 KB" and
  the licenses page opened correctly. App version/build already existed
  via the M12 `AboutListTile`. "Clear cache" wasn't added — this app has
  no cache distinct from the Hive boxes the existing "Reset progress"
  action already covers.
- **Navigation fix found during device verification**: there was no UI
  path from the Dashboard to `/settings` anywhere in the app (a
  previously-logged "known open item") — discovered while trying to
  manually verify the new Diagnostics section and impossible to route
  around, so fixed as part of this milestone's own "Startup & Navigation"
  scope: `DashboardScreen` gained a minimal `AppBar` with a settings gear
  `IconButton` (tooltipped) routing to `/settings`.
- **Testing**: zero tests existed before this milestone (no `test/`
  directory, no `flutter_test` in `pubspec.yaml` — there wasn't even a
  `dev_dependencies:` block). Added `flutter_test` as the one new
  dependency this milestone required. New `test/fakes/` (in-memory
  repository fakes for Progress/Review/Practice/Achievement/Analytics, no
  Hive), `test/unit/` (`review_scheduler_test`, `writing_evaluator_test`,
  `safe_parse_test`, `analytics_export_service_test`,
  `practice_generator_test` — exercises real Hiragana JSON assets under
  `flutter_test`, `search_service_test`), `test/widget/`
  (`answer_option_test`, `statistic_card_test`, `dashboard_screen_test`),
  `test/flow/lesson_completion_flow_test.dart` (a `flutter_test`
  substitute for a true integration test: the real `ProgressController`
  wired to a fake repository, exercising start→complete→persist→
  completion-percentage). 36 tests, all passing.
  - **`test/flutter_test_config.dart`** was needed: `AppTypography` calls
    `GoogleFonts.notoSansJpTextTheme()` on every access, and `google_fonts`
    attempts a real network fetch under `flutter_test` by default — with
    no network available this hangs rather than failing fast. This file
    (auto-discovered by the Flutter test runner) sets
    `GoogleFonts.config.allowRuntimeFetching = false` before any test
    runs, so it falls back to the bundled default font immediately.
  - **A genuine `flutter_test`/Riverpod interaction bug was found and
    routed around, not silently ignored**: several real `FutureProvider`s
    (`achievementProgressListProvider`, `learningAnalyticsProvider`,
    `practiceStatisticsProvider`, `practiceResultsProvider`) `ref.watch()`
    a legacy `ChangeNotifierProvider` (`practiceServiceProvider`) purely
    as an invalidation trigger — the established, correct pattern used
    throughout this app. Under `flutter_test`'s `ProviderContainer`
    specifically, reading that `ChangeNotifierProvider` and then awaiting
    one of those `FutureProvider`s deadlocks — reproduced in isolation
    with nothing but those two providers, unrelated to anything this
    milestone changed, and **not reproducible in the real app** (the exact
    same provider graph was exercised live on the emulator throughout this
    session's own verification with no issue). `dashboard_screen_test.dart`
    overrides every async provider `DashboardScreen` touches directly
    rather than depending on that unrelated test-harness quirk; documented
    inline in the test file for whoever touches it next.
- **Documentation**: `README.md` was a 2-line stub — rewritten with
  features, architecture overview, folder structure, setup/testing
  instructions, an asset-management guide, and a "Known limitations"
  section (consolidating the review-success-rate, per-script-quiz-accuracy,
  study-time-estimate, and audio-coverage caveats already disclosed in
  M15/M18, plus the new single-device-testing limitation below).
  `PROJECT_RULES.md`'s Hive-boxes list fixed (see above).

**Explicitly deferred** (disclosed, not silently skipped):
- `flutter_lints`/`analysis_options.yaml` rules: `analysis_options.yaml`
  is an intentionally empty stub today (zero lint rules). Enabling lints
  now risks a large, unplanned cleanup across the whole existing codebase
  and could break the "flutter analyze reports no issues" acceptance
  criterion — left at today's baseline.
- True multi-device testing (7"/10" tablets, landscape): only one phone
  emulator profile (API 37) is available in this environment. Verified on
  that profile; tablet/landscape behavior is reasoned about via the
  existing `AppScaffold` 960dp content cap and `Wrap` reflow, not
  physically verified on tablet hardware.
- The `integration_test` package: substituted with the `flutter_test`-based
  `test/flow/` approach described above.
- Exhaustive `Semantics` coverage: only the specific gaps the survey found
  were fixed, not a wrap-everything pass.
- A full animation overhaul: only the two additions listed above.

`flutter analyze`: **No issues found.** `flutter test`: **36/36 passing.**

### Runtime Verification

Verified on the same Android emulator (API 37, `emulator-5554`), reusing
the real data accumulated across M17/M18's testing.

- App launched cleanly after the `main.dart` bootstrap changes
  (parallelized, corrupted-box-safe box opening); dashboard showed the
  same real data as before (11% progress, 2 lessons completed, etc.) —
  confirms the Hive hardening didn't change behavior for the healthy-data
  path.
- The new dashboard settings icon navigated to `/settings` correctly.
- Settings' new Diagnostics section showed a real computed **"10.3 KB"**
  storage figure and "Licenses" opened Flutter's built-in licenses page
  (About dialog → "View licenses" → scrollable package list) without
  error. The updated "Reset progress" description text
  (practice history + analytics now mentioned) rendered correctly.
- Started a Recognition quiz session: the answer-reveal color transition
  (`AnimatedContainer`) showed a visible red (incorrect)/green (correct)
  tint on selection, confirmed via a mid-transition screenshot.
- The Achievements section's "Quiz Novice" card and the Practice section's
  mode-selection cards (still capped at 320dp / shrinking on narrow
  layouts per the responsive fix) rendered correctly.
- Set the emulator's system font scale to 2.0x and relaunched: quiz answer
  text grew visibly larger but no layout overflowed or clipped, confirming
  the 1.0–1.6x clamp is active (reset back to 1.0x afterward).
- No Dart exceptions or `FlutterError` output anywhere in the `flutter
  run` log across the full session (dashboard → settings → diagnostics →
  licenses → quiz → answer reveal → font-scale test); only benign platform
  log lines.

### Files Added

- `lib/core/utils/safe_parse.dart`
- `lib/shared/widgets/loading_indicator.dart`
- `lib/shared/widgets/empty_state.dart`
- `lib/shared/widgets/error_state.dart`
- `test/flutter_test_config.dart`
- `test/fakes/fake_progress_repository.dart`
- `test/fakes/fake_review_repository.dart`
- `test/fakes/fake_practice_repository.dart`
- `test/fakes/fake_achievement_repository.dart`
- `test/fakes/fake_analytics_repository.dart`
- `test/fakes/fake_audio_repository.dart`
- `test/unit/review_scheduler_test.dart`
- `test/unit/writing_evaluator_test.dart`
- `test/unit/safe_parse_test.dart`
- `test/unit/analytics_export_service_test.dart`
- `test/unit/practice_generator_test.dart`
- `test/unit/search_service_test.dart`
- `test/widget/answer_option_test.dart`
- `test/widget/statistic_card_test.dart`
- `test/widget/dashboard_screen_test.dart`
- `test/flow/lesson_completion_flow_test.dart`

### Files Changed

- `lib/main.dart` (parallelized + corrupted-box-safe box opening,
  clamped text scaling)
- All 8 `Hive*Repository` classes (`safeParse` adoption)
- `lib/features/settings/services/settings_service.dart` (
  `resetAllProgress` now clears all 5 progress-related boxes; new
  `getStorageUsageBytes()`)
- `lib/features/settings/providers/settings_providers.dart` (new
  `storageUsageProvider`)
- `lib/features/settings/screens/settings_screen.dart` (Diagnostics
  section; updated reset-progress copy)
- `lib/features/audio/widgets/audio_button.dart`,
  `lib/features/search/widgets/search_bar_field.dart` (tooltips)
- `lib/features/analytics/screens/analytics_screen.dart`,
  `lib/features/analytics/widgets/script_summary_card.dart` (token fixes)
- 15 files adopting `LoadingIndicator` (`kanji_screen.dart`,
  `katakana_screen.dart`, `hiragana_screen.dart`,
  `features/practice/learning_screen.dart`, `settings_screen.dart`,
  `review_screen.dart`, `search_screen.dart`, `achievements_screen.dart`,
  `dashboard_screen.dart`, `practice_home_screen.dart`,
  `practice_session_screen.dart`, `analytics_screen.dart`)
- `lib/features/quiz/screens/practice_home_screen.dart` (responsive card
  width)
- `lib/features/quiz/widgets/answer_option.dart`,
  `lib/features/achievements/widgets/achievement_card.dart` (animations)
- `lib/features/dashboard/screens/dashboard_screen.dart` (settings
  navigation icon)
- `pubspec.yaml` (adds `dev_dependencies: flutter_test`)
- `README.md` (full rewrite)
- `PROJECT_RULES.md` (Hive-boxes list fix only)

## Milestone 20: Production Release (v1.0)

Implemented and verified against a **release build** on device. This was a
stabilization milestone, not a feature milestone: release configuration,
branding, legal documents, data-integrity and asset verification, a full
application audit, performance measurement, release-build validation, and
release documentation. Three decisions were confirmed with the user before
planning (application ID, signing strategy, icon/splash approach).

- **Release configuration**: `pubspec.yaml` version bumped `0.1.0+1` →
  `1.0.0+1`. The Android `applicationId` and `namespace` moved from the
  Flutter placeholder `com.example.japanese_learning` to
  `com.energeticclutches.yugjapanese`; `MainActivity.kt` was moved
  (`git mv`) to the matching package directory and its `package`
  declaration updated; the now-empty `com/example/` directories were
  removed. `AndroidManifest.xml`'s `android:label` changed from the raw
  `japanese_learning` to `YugJapanese`. A grep sweep confirms **zero**
  remaining `com.example` references anywhere in the project.
  `compileSdk`/`minSdk`/`targetSdk`/`versionCode`/`versionName` are all
  derived from `flutter.*` and needed no change. Verified by building and
  installing before moving on — a fresh install under the new ID starts
  with empty progress, as expected for what Android treats as a different
  app.
- **Signing (deliberately deferred)**: release builds still use the debug
  signing config, per the user's explicit instruction not to generate a
  production keystore in this milestone. The former `TODO` comment in
  `build.gradle.kts` was replaced with a note stating this is intentional
  for v1.0 and pointing at `RELEASE_CHECKLIST.md`, which documents the
  full production-signing procedure as a release blocker. **No keystore or
  signing credentials were created.**
- **Branding (Android only)**: added `flutter_launcher_icons` and
  `flutter_native_splash` as dev dependencies — the only dependency
  additions this milestone. Placeholder artwork was generated
  programmatically (a torii-gate silhouette drawn with PIL primitives, in
  the existing `AppColors` palette — no copyrighted material, no traced
  logo) into `assets/branding/`: `app_icon.png` (opaque), 
  `app_icon_foreground.png` (transparent, sized inside Android's ~66%
  adaptive-icon safe zone), and `splash_logo.png`. Both generators were
  run; all Android mipmap densities, adaptive-icon XML, `colors.xml`, and
  light/dark splash drawables and styles are generated. Verified on device:
  the icon renders correctly on the home screen and the splash displays
  before the dashboard.
  - **iOS was dropped from this milestone.** The user's original
    instruction asked for iOS icons and splash screens, but this project
    has no `ios/` directory and has been Android-only throughout. Rather
    than scaffold a new platform target as a side effect of a branding
    task, the conflict was raised and the user confirmed: Android now,
    iOS "in the near future". `flutter_launcher_icons`/
    `flutter_native_splash` are configured with `ios: false`.
- **Legal**: new `PRIVACY_POLICY.md`, `TERMS_OF_USE.md`, and `CREDITS.md`
  at the repository root, reachable in-app from a new **Settings → Legal**
  section. Rather than duplicating the text into Dart string literals,
  the Markdown files themselves are bundled as assets and rendered by a
  new `LegalDocumentScreen` — the repository copy and the in-app copy are
  the same file and cannot drift. It uses a small purpose-built renderer
  (`_MarkdownText`, ~60 lines) covering headings, bullets, and bold; no
  Markdown package was added, since none is on the approved list. The
  first on-device check caught a real defect — the source files' 72-column
  hard wraps were rendering as literal line breaks, so paragraphs broke
  mid-sentence — fixed by re-joining wrapped lines into paragraphs before
  layout, and re-verified.
- **About / version**: `SettingsScreen`'s hardcoded `0.1.0` version
  constants updated to `1.0.0`, app name to `YugJapanese`, and the About
  dialog now carries the MIT license line and a real description.
- **Asset verification**: audited every asset path referenced by the
  lesson JSON (112 paths) against `pubspec.yaml` and the filesystem. 5
  exist (the Hiragana vowel recordings); the other 107 are audio paths
  referenced ahead of recording. These resolve to `null` through
  `LocalAudioRepository`'s existence check and simply hide the play
  button — confirmed by design, not a bug, and now documented in
  `CHANGELOG.md` as a known limitation.
- **Data integrity**: verified fresh install, upgrade-over-existing-install
  (release APK installed over the prior build, data preserved), and
  persistence across a full `force-stop` + cold restart — "Lessons In
  Progress" 0 → 1 and the dashboard CTA "Start Learning" → "Continue"
  both survived. Quiz results persisted too ("Best: 20% · Last played
  7/26/2026" on the mode card after a restart).
- **Full application audit** (release build, clean install): Dashboard,
  Search (all three scripts, live filtering, result → correct character
  navigation), Learning flow, Audio playback (confirmed via AudioTrack
  frames delivered, no errors), Practice/quiz (a complete 10-question
  Recognition session, scored and timed, with mistakes feeding "Areas to
  Review"), Analytics (completion, per-script breakdown, live streak),
  Settings (all groups + Diagnostics), and the new Legal screens. No
  uncaught exceptions in logcat across the entire walkthrough.
- **Performance — and a corrected M19 claim**: cold start measures
  ~3.5–5.3s on the x86 emulator. Instrumenting a profile build showed
  `Hive.initFlutter()` costs ~30–70ms while the **first cold open of the 8
  boxes costs ~3.4–5.3s** — nearly all of startup. An initial experiment
  appeared to show sequential opening was ~9x faster than the `Future.wait`
  introduced in M19, but that measurement was flawed: the sequential pass
  ran second in the same process, on a warm page cache. A proper A/B
  (separate builds, five cold starts each) found **no meaningful
  difference** — parallel ~3.8s median, sequential ~3.8s median. So M19's
  "roughly 8x less sequential latency" claim was never true; it was
  asserted without measurement. The M19 entry above has been corrected.
  The `Future.wait` was left in place (it is no worse), and
  `_openBoxSafely`'s doc comment now records the measurement so this isn't
  re-litigated. The real lever, if startup needs to improve, is opening
  fewer boxes eagerly. Startup on physical hardware has **not** been
  measured and is listed as a release blocker.
- **Release build validation**: `flutter analyze` clean, `flutter test`
  36/36 passing, `flutter build apk --release` succeeds (52.2 MB), and
  `flutter build appbundle` succeeds (50.9 MB) — both debug-signed. Builds
  emit a benign `cupertino_icons` font warning that originates from
  Flutter's bundled Cupertino widgets, not from app code (no
  `CupertinoIcons` reference exists in `lib/`); adding the package would
  silence it but is pointless for an Android-only Material 3 app, so it was
  left alone and documented.
- **Documentation**: new `CHANGELOG.md` (v1.0.0 entry plus a feature
  history of M1–M19 and a known-limitations list) and new
  `RELEASE_CHECKLIST.md` (code quality, functionality, UI, and release
  sections, plus an explicit "deferred — required before publishing" list
  covering the production keystore, replacing placeholder branding,
  physical-device/tablet testing, store assets, and iOS support).

### Files touched (Milestone 20)

- `pubspec.yaml` (version `1.0.0+1`; `flutter_launcher_icons` +
  `flutter_native_splash` dev deps and their config; legal Markdown files
  registered as assets)
- `android/app/build.gradle.kts` (applicationId + namespace; signing
  comment)
- `android/app/src/main/AndroidManifest.xml` (`android:label`)
- `android/app/src/main/kotlin/com/energeticclutches/yugjapanese/MainActivity.kt`
  (moved from `com/example/japanese_learning/`; package declaration)
- `android/app/src/main/res/**` (generated icons, adaptive-icon XML,
  `colors.xml`, splash drawables and styles — light and dark)
- `assets/branding/app_icon.png`, `app_icon_foreground.png`,
  `splash_logo.png` (new)
- `lib/features/settings/screens/legal_document_screen.dart` (new)
- `lib/core/router/app_router.dart` (`/legal/privacy`, `/legal/terms`,
  `/legal/credits` routes)
- `lib/features/settings/screens/settings_screen.dart` (version/name
  constants, About copy, new Legal section)
- `lib/main.dart` (comment only — records the startup A/B measurement)
- `PRIVACY_POLICY.md`, `TERMS_OF_USE.md`, `CREDITS.md`, `CHANGELOG.md`,
  `RELEASE_CHECKLIST.md` (new)
- `PROJECT_LOG.md` (this entry; M19 performance claim corrected)

## Bugfix (post-M20): Android Back button exited the app instead of navigating up the screen stack

**BUG-001, critical.** From any drilled-down screen (e.g. Dashboard →
Hiragana → Lesson), the hardware/gesture Back button exited straight to
the Android home screen instead of retracing the in-app navigation one
screen at a time.

**Root cause**: almost every navigation call in the app used
`context.go(...)`, which replaces go_router's entire navigation stack
rather than pushing onto it. The only exceptions were the two `/legal/*`
links added in M20. Since nothing else ever pushed, the stack never held
more than one entry, so Back always had nowhere to go but out — regardless
of how many screens deep the user actually was.

**Fix** (no router restructuring — a flat push/pop discipline was
sufficient): every navigation call was reclassified by intent, not
blanket-swapped.
- Drill-down navigation (Dashboard → any section; script lesson list →
  lesson; search result → lesson; starting a quiz session) — `go()` →
  `push()`. ~20 call sites across `dashboard_screen.dart`,
  `hiragana_screen.dart`, `katakana_screen.dart`, `kanji_screen.dart`,
  `search_screen.dart`, `review_screen.dart`, `analytics_screen.dart`,
  `practice_home_screen.dart`, `practice_results_screen.dart`.
- Returning from a finished/empty flow (lesson complete, quiz has no
  content, "Return to Practice"/"Return Home") — `pop()` with a `go()`
  fallback for the case where there's nothing left to pop to
  (`learning_screen.dart`, `practice_session_screen.dart`,
  `practice_results_screen.dart`).
- Quiz session → results — `pushReplacement()`, so Back from results skips
  the finished session but still returns through Quiz home → Dashboard
  rather than exiting (`practice_session_screen.dart`).

**Verified**: `flutter analyze` clean, `flutter test` 36/36 passing. On
device, the exact reported repro (Dashboard → Hiragana → Lesson, 3 deep):
Back #1 → Hiragana list, Back #2 → Dashboard, Back #3 (from root) → exits
to Android home as expected. App process stayed alive throughout, no
crash in logcat. As a side effect, screens reached via `push()` now
correctly show a back arrow in their AppBar (Flutter only renders one when
there's something to pop), which was also silently missing before.

## Bugfix (post-M20): BUG-002 — writing canvas never existed

**Critical.** Reported: the lesson screen showed navigation controls and
character info but no writing canvas, stroke-order animation, or tracing
surface for any of Hiragana/Katakana/Kanji, so the app's core "practice
writing" feature was unusable. The Show Stroke Guides / Show Writing Grid
/ Animation Speed settings had no visible effect.

**Investigation (per the user's explicit "investigate first" instruction)**
found this was not a rendering bug — `lib/features/writing/` had never
contained a canvas. `introduction`, `strokeOrder`, `tracing`, and
`freeWriting` all rendered the same character-info card in
`learning_screen.dart`; only a text label differed. The only `CustomPaint`
in the whole app was the analytics trend chart; there was no
`GestureDetector`/pointer handling anywhere capable of capturing a
stroke. `PROJECT_LOG.md`'s own M7 entry said as much: "No handwriting
canvas... was added to the evaluator." A second, more serious finding
surfaced during investigation: `learning_screen.dart`'s
`_evaluateCurrentItem` fabricated synthetic diagonal strokes and scored
those — every "writing accuracy" ever recorded or shown in Analytics was
machine-generated, not the user's actual handwriting.

Given the scope (no canvas existed, and true stroke-order animation needs
per-character stroke-path data this project never had), the user chose
the full option: build a real canvas *and* source real stroke-order data,
rather than a stopgap.

**Stroke data**: KanjiVG (r20250816, CC BY-SA 3.0) was downloaded and its
per-stroke SVG paths converted offline (`scratchpad/convert_strokes.py`,
not committed) into `assets/data/stroke_data.json` — cubic Béziers
flattened to polylines, normalized to 0–1 space, no runtime SVG parsing.
Covers all 171 characters this app teaches (130 existing + 41 new
Hiragana, see below). The conversion cross-checked KanjiVG's own stroke
count against each character's declared `strokeCount` and caught one
pre-existing data error: Katakana サ was declared as 2 strokes but is
genuinely 3 (fixed in `katakana_lessons.json`). Attribution added to
`CREDITS.md`.

**New writing feature** (`lib/features/writing/`): `StrokeTemplate`/
`CharacterStrokes` models, `StrokeDataRepository` (loads/caches the
bundled JSON, same missing-data-degrades-gracefully pattern as
`LocalAudioRepository`), `characterStrokesProvider`. `WritingCanvas`
(real finger-drawn `Stroke`/`StrokePoint` capture), `WritingCanvasPainter`
(grid, stroke guide, ink — one painter, several render modes),
`StrokeOrderPlayer` (animated stroke-by-stroke playback, speed driven by
`AnimationSpeed`), `WritingPracticePanel` (canvas + undo/clear/submit).
`learning_screen.dart`'s `strokeOrder`/`tracing`/`freeWriting` steps now
render distinctly instead of sharing one card; `_evaluateCurrentItem` was
replaced with `_evaluateDrawnStrokes`, which scores the real captured
strokes against the canvas's actual size and the reference glyph's real
bounding box. All three Learning settings are now genuinely wired:
`showGrid` and `showStrokeGuide` toggle the canvas overlays,
`animationSpeed` scales `StrokeOrderPlayer`'s per-stroke duration —
verified on device by toggling both switches off and confirming the
tracing canvas rendered completely blank.

**A gesture-arena bug found and fixed during on-device testing** (not
present in the initial implementation's design, caught before it shipped):
the canvas sits inside `learning_screen.dart`'s page-level
`SingleChildScrollView`, and a `GestureDetector`-based pan recognizer
reliably lost near-vertical strokes to the ancestor scrollable — verified
directly: a horizontal test swipe drew ink, an identical vertical swipe
drew nothing. Since most Japanese strokes are vertical or diagonal, this
would have silently eaten real input. Fixed by switching `WritingCanvas`
to a `Listener` (raw pointer events, which bypass gesture-arena
disambiguation entirely) and adding `onDrawingActive`, which the parent
uses to set `NeverScrollableScrollPhysics` on the page scroll view for
the duration of a stroke, so the two gestures stop competing for the same
touch. Re-verified after the fix: vertical, horizontal, and diagonal
strokes all capture correctly.

**Hiragana content gap closed**: only 5 of 46 gojuon characters had
lesson data (Lesson 1, vowels only) — everything past that was simply
absent, not stroke-related. Added Lessons 2–10 (41 characters), mirroring
Katakana's exact row grouping (Ka/Sa/Ta/Na/Ha/Ma/Ya/Ra/Wa-N). Stroke
counts were read from KanjiVG rather than typed by hand, so they cannot
disagree with the number of strokes actually animated. `hiragana_lessons.json`
diff is a pure addition — Lesson 1's real `.wav` audio paths are
untouched; the 41 new characters correctly have no audio yet (same
graceful-degradation path as before).

**Verified**: `flutter analyze` clean, `flutter test` 36/36 passing. On
the emulator: a full Hiragana あ walkthrough (stroke-order animation
→ tracing with guide+grid → free writing from memory → submit) produced
a genuine 96% accuracy result from real drawn strokes, not a fabricated
one; a Katakana-row and an 8-stroke Kanji (雨) spot check both rendered
correct stroke-order animations; the Settings toggles were confirmed live
on the tracing canvas. No crashes in logcat across the session.

### Files touched (BUG-002)

- `assets/data/stroke_data.json` (new, 171 characters, ~375 KB)
- `assets/data/katakana_lessons.json` (サ strokeCount 2→3)
- `assets/data/hiragana_lessons.json` (Lessons 2–10 added, 41 characters)
- `CREDITS.md` (KanjiVG attribution), `pubspec.yaml` (asset registration)
- `lib/features/writing/models/stroke_template.dart`,
  `repositories/stroke_data_repository.dart`,
  `providers/stroke_data_providers.dart` (new)
- `lib/features/writing/widgets/writing_canvas_painter.dart`,
  `writing_canvas.dart`, `stroke_order_player.dart`,
  `writing_practice_panel.dart` (new)
- `lib/features/practice/learning_screen.dart` (per-step rendering,
  real evaluation, drawing-active scroll freeze)

## BUG-003: Hiragana Lesson List Showed Only the First Lesson

`HiraganaScreen` fetched a single lesson with `getLesson(1)` and rendered
one card, while `KatakanaScreen` and `KanjiScreen` already looped over
`getAllLessons()`. Nine of the ten Hiragana lessons were unreachable from
the list. Switched to the same multi-lesson pattern, fixed
`completionPercentage`'s misused `totalLessons` argument (it was being
passed the literal `1`), and added the missing `?content=hiragana` query
parameter on the practice route.

Files changed: `lib/features/hiragana/hiragana_screen.dart`.

## BUG-004: Dark Mode Text, Dividers, and Search Glyphs Unreadable

`AppTypography`'s static getters (`title`, `headline`, `body`, `caption`,
`label`, `display`) all resolved from a light-only `TextTheme`, so every
widget using them painted near-black text on dark surfaces.
`AppColors.divider` and `.textSecondary` had the same problem. The dark
palette and `darkTextTheme` already existed and were correctly wired into
`AppTheme.dark` — the static shortcuts simply never consulted them.
Replaced both with `Theme.of(context)` lookups across 33 files, leaving
light mode byte-identical.

Three cases needed more than a lookup swap:

- `TrendChart`'s `CustomPainter` has no `BuildContext`, so its grid colour
  is now passed into the constructor and included in `shouldRepaint`.
- Quiz answer feedback had an adaptive error colour but a light-only
  success colour; added `AppColors.darkSuccess`.
- `SearchResultTile`'s `CircleAvatar` set no `foregroundColor`, so
  Material 3 fell back to `onPrimaryContainer` — a `ColorScheme` role this
  app never defines — leaving every search result glyph invisible in dark
  mode. Pinned to `onSurface`. This one was only findable by running the
  app; static analysis reports nothing.

## BUG-006: Writing Evaluator Scored Scribbles as ~100% Accurate

The evaluator never received the character's reference stroke geometry.
Its score was stroke count (35%), a free 15% for any completed drawing,
and two bounding-box heuristics (50%) — nothing that measured whether the
drawing resembled the character. Measured before the fix: a single
diagonal line scored **100%** for a one-stroke character, two dots in
opposite corners **100%**, a random three-stroke scribble **98.7%**.

`learning_screen.dart` was already loading the KanjiVG reference strokes
in order to derive that bounding box, then discarding the geometry. They
are now passed through (`referenceStrokes`, one line at the call site).

The evaluator normalizes attempt and reference into a common space
(centred, **uniformly** scaled — per-axis scaling would stretch a flat
scribble into a square glyph), resamples each stroke to 32 arc-length
equidistant points, and compares point-wise. Shape is the backbone of the
score; stroke count, order, direction and proportion only modulate it
multiplicatively, so no combination of secondary signals can rescue a
wrong shape. Strokes average over `max(user, reference)` so missing and
extra strokes both cost marks; wrong order earns partial credit via a
greedy order-free match rather than zero; sub-threshold flecks are
filtered as accidental taps. Characters with no reference data fall back
to the old bounding-box heuristic, capped at 0.6 and labelled as such in
the feedback rather than claiming an accuracy that was never measured.

All 171 lesson characters have reference strokes, so shape scoring is
live for all three scripts; the fallback is a safety net, not a normal
path.

## Enhancement Pass: Spaced Repetition, Stroke Direction, Mnemonics, Pacing

Four targeted improvements to existing systems. No new features, no UI
redesign, no new models beyond one field.

### Spaced repetition

Weaknesses found:

- `learning_screen.dart` called `recordSuccessfulReview` **unconditionally**
  in review mode, ignoring the score the learner had just earned. A 5%
  attempt advanced the interval exactly as a 95% one did.
- There was no failure path at all — `recordFailedReview` did not exist.
- `ReviewItem.easeFactor` was persisted and carried forward but never
  read or updated; it was documented as "reserved for a future adaptive
  scheduler". Nothing consumed it.
- `getDueReviews` sorted purely by due date, so a session spent its time
  on whatever fell due first rather than on what was weakest.

Changes, all within the existing scheduler and repository:

- `recordReview(lessonId, accuracy:)` routes by score against
  `passThreshold` (0.6). Weak reviews step **one rung back** down the
  ladder — not to the start — and increment a lapse counter.
- `easeFactor` is now live: strong recall (≥0.85) earns ease, a bare pass
  is neutral, a miss loses ease in proportion to how far short it fell.
  Clamped to [1.3, 2.8] and applied as a multiplier on the ladder
  interval, so a difficult lesson returns sooner than an easy one sitting
  on the same rung.
- `getDueReviews` sorts by a priority combining overdue-ness, inverted
  ease, and lapse count, so the most fragile material comes first.
- `scheduleInitialReview` accepts the lesson's accuracy, so a shaky first
  pass enters the rotation already marked as needing work.

`ReviewItem` gained one field, `lapses`, defaulting to 0 in `fromMap` so
schedules saved before this change still load.

Also fixed at the call site: `completeLesson` was recording only the
**final character's** accuracy as the whole lesson's score. It now
averages across every character in the attempt, which makes both the
stored `bestWritingAccuracy` and everything derived from it meaningful.

### Stroke direction

Direction was detected as `backward < forward` with no margin, so a
near-symmetric stroke could be flagged as backwards on floating-point
noise alone. And the penalty was a flat 15% ceiling: a character written
with **every** stroke backwards still scored 85%, which teaches learners
that stroke direction is cosmetic.

- Detection now requires the reversed reading to be better by a margin
  before calling a stroke backwards.
- The penalty scales with the share of strokes reversed
  (`1 − 0.20s − 0.30s²`), and repeated mistakes cap the total score so a
  technically-wrong attempt cannot reach the top band.

Measured on real glyphs — correct 100%, one stroke backwards on a
multi-stroke character 89%, everything backwards 50% (was 85%). One slip
stays beginner-friendly; systematically wrong technique does not.

While testing this, found and fixed a separate latent bug: `Rect.isEmpty`
is true when *either* dimension is zero, so `_proportionScore` returned 0
for any perfectly flat glyph. 一 was losing 15% for being correctly
written as a horizontal line; it now scores 100%.

### Mnemonics

`CharacterModel` and `LearningItem` already carried a `notes` field, and
`LearningController` already threaded it into the learning flow — the
lesson data simply never populated it. Wrote a concise shape- or
sound-based hint for all 171 characters (46 hiragana, 46 katakana, 79
kanji) into the existing `notes` key, and rendered it in the existing
introduction step as a single lightbulb row beneath the meaning. It
appears only during introduction, so it does not crowd tracing or
writing. No new widget, no layout change.

`HiraganaRepository` and `KatakanaRepository` were dropping `notes` in
`_toLearningItem` (the search path); `KanjiRepository` already kept it.
Now all three agree.

### Pacing

`ProgressController` gained two derived predicates — `isMastered` and
`needsMorePractice` — both computed from the `bestWritingAccuracy` that
was already being stored, against a `masteryThreshold` of 0.75. No new
model fields, no new persistence.

The three script screens' `_progressLabel` now distinguishes a lesson
finished cleanly ("Completed") from one finished shakily ("Completed -
Practice Again"), and weak lessons enter spaced repetition with lower
ease so they resurface sooner. Mastery tracks the learner's best attempt,
so a later bad day does not revoke it.

### Verification

`flutter analyze` clean. `flutter test` 68/68 (was 48; 20 new tests
covering direction penalties and false-positive detection, accuracy-aware
scheduling and lapse handling, priority ordering, mastery predicates, and
mnemonic data coverage/length/uniqueness across all three scripts).

Files changed: `lib/features/review/models/review_item.dart`,
`lib/features/review/services/review_scheduler.dart`,
`lib/features/writing/services/writing_evaluator.dart`,
`lib/features/progress/services/progress_controller.dart`,
`lib/features/practice/learning_screen.dart`,
`lib/repositories/{hiragana,katakana}_repository.dart`,
`lib/features/{hiragana,katakana,kanji}/*_screen.dart`,
`assets/data/{hiragana,katakana,kanji}_lessons.json`.

Commits: `b0ac8b6` (scheduling), `ba0b463` (stroke direction),
`fc3668c` (mnemonic data), `4243fbd` (pacing, rendering, this log).

### Success Criteria — Outcome

All four met.

1. **Review scheduling prioritizes weaker material.** `getDueReviews` now
   ranks by overdue-ness, inverted ease, and lapse count instead of due
   date alone, and reviews are recorded from the learner's actual score
   rather than assumed successful. Note the scheduling unit is the
   *lesson* (`hiragana:1`), not the individual character — the app has no
   per-character progress store, and adding one would have been a new
   system rather than an improvement to an existing one.
2. **Stroke direction has meaningful impact.** Everything backwards fell
   from 85% to 50%; a single slip on a multi-stroke character costs ~11%.
   Repeated mistakes are capped out of the top band.
3. **Mnemonic hints without clutter.** All 171 characters carry a hint,
   rendered as one lightbulb row during the introduction step only. No new
   widget and no layout change; verified on device that it is absent from
   the stroke-order, tracing, and writing steps.
4. **Pacing reflects performance.** Lesson accuracy now averages across
   the whole attempt rather than recording only the final character, which
   is what makes `isMastered` / `needsMorePractice` and the shorter first
   review interval for weak lessons meaningful.

**Verified on device:** the mnemonic on あ and 一 (present during
introduction, absent afterwards) and the flat-glyph scoring fix (一 traced
correctly now scores 84% on a real stroke, previously capped near 71%).

**Not verified on device:** the scheduling and pacing changes. Both need
multi-day review intervals or completed lessons to observe, so they rest
on the 20 new unit tests. Treat them as tested, not witnessed — if a
future session can leave lessons completed and come back to them, that is
worth doing.

## BUG-007: Loading Indicator Never Dismissed After Lesson Completion

Not a loading bug. `LearningScreen` rendered `LoadingIndicator()` for
`LearningStep.completed` whenever `_writingResult` was null — a spinner
standing in for a state the code assumed was transient. Nothing async was
ever in flight behind it: no Future, no provider, no Hive write. The
completion Future resolved fine, providers left their loading state,
writes committed, and no exception was swallowed. The spinner simply had
nothing that could ever clear it.

`_writingResult` was only ever assigned in `_submitWriting`, which runs
only on "Check my writing". Two ordinary paths reach `completed` without
it:

- **"Next Character" on the final character.** That button renders in
  every step, and `LearningSession.nextCharacter` short-circuits to
  `currentStep: completed` on the last index.
- **"Next" from the free-writing step**, since `nextStep()` maps
  freeWriting → completed.

Both dead-ended: `_continueAfterResult` returns early on its own
`result == null` guard, so the visible button did nothing and Back was
the only escape. Identical on all three scripts — they share this one
screen via `/practice/:lessonNumber?content=`.

Fixed by grading the attempt on arrival at the result step rather than
only on submit, which covers every path in, present and future. An
untouched canvas scores 0 with "Finish the character before submitting" —
the honest outcome for skipping the step, and consistent with BUG-006's
rule that the app never reports an accuracy it did not measure. The
unreachable spinner branch was removed so the bug cannot return.

## BUG-008: No Progression to the Next Lesson

`_continueAfterResult` saved progress, scheduled the review, then popped
back to the lesson list. There was no next-lesson logic anywhere in the
codebase.

Everything the report attributed to unlocking was already working:
`completeLesson` marks `isCompleted` and notifies, so the lesson list,
achievements, and analytics refresh through the existing
`progressControllerProvider` convention, and `dueReviewsProvider` is
invalidated. There is also **no lesson gating in this app** — every
lesson card is always tappable — so "the next lesson becomes available"
was structurally already true. The only real gap was the missing action.

`LearningController.nextLessonNumber()` resolves the following lesson
from the repository the session was built from (lowest lesson number
above the current one, so it does not depend on JSON ordering). The
screen shows a non-dismissible completion dialog with the lesson's
accuracy and either **Next Lesson** / **Back to Lessons**, or a
module-complete message when the script is finished. Continuing uses
`pushReplacement`, so chaining lessons does not stack a screen per
lesson and Back still returns to the lesson list.

Review mode deliberately keeps its old behaviour — it belongs to the
review queue, not the lesson ladder, so it still returns to `/review`.

**Verified on device** (Android emulator, API 37), both scripts driven
end to end:

- *Hiragana Lesson 1* — "Next Character" on the final character (あ…お)
  now lands on a result card, not a spinner. Continue → "Lesson 1
  complete / Lesson 2 is ready" → Lesson 2 loads. Back from Lesson 2
  returns to the lesson list, not Lesson 1, confirming
  `pushReplacement`. The list showed Lesson 1 as Completed and the
  dashboard moved to "Hiragana 20% complete".
- *Hiragana Lesson 10* (last) — reached `completed` the other way, via
  the **Next** button from free writing without submitting. One drawn
  stroke on ん scored **15%** with "Your stroke count is correct", which
  confirms the arrival-time grading runs the real evaluator on real
  captured input rather than defaulting to zero. The dialog correctly
  dropped the Next Lesson action and said "That was the last lesson
  here."
- *Kanji Lesson 1* — same completion path, same result card, and Next
  Lesson went to **Kanji** Lesson 2 (学), confirming `contentId` survives
  the replacement route rather than falling back to Hiragana.

No exceptions in the run log across the whole session. Katakana was not
driven separately — it shares `LearningScreen` with the two scripts that
were.

## BUG-009: Lesson Card Conflated Completion With Writing Accuracy

`LessonCard` rendered `'$progressLabel - $completionPercentage%'`. The
value behind that percent sign was `isCompleted ? 100 : 0` — a boolean
wearing a percent sign, computed identically in all three script
screens. It never expressed a proportion of anything, so it added no
information the label did not already carry.

The harm came from what it sat next to. `_progressLabel` derives
"Completed - Practice Again" from `bestWritingAccuracy`, so the line read
"Completed - Practice Again - 100%": a completion state and an
accuracy-derived label joined to a number belonging to neither reading a
learner would reach for. A lesson finished at 0% advertised a perfect
score. The same flaw ran the other way at the start — "In Progress - 0%"
implied a scored attempt where there had merely not been one yet.

So the value was never *wrong*; it was meaningless as a percentage and
ambiguous beside an accuracy label. Fixed by removing it rather than
relabelling it, and showing the metric learners actually thought they
were reading: `writingAccuracy` (nullable, 0..1) renders as its own
"Writing accuracy: N%" line, and only once the lesson is complete. An
unfinished lesson shows status alone. Same widget, same visual language,
one clear line instead of one ambiguous line.

Covered by 5 widget tests, including the exact reported case — a
completed lesson scored 0% must not render "100%" anywhere.

## Release Candidate QA Audit (in progress)

A full pre-RC1 production-readiness pass: static review for lifecycle/
provider/error-handling bugs that `flutter analyze` and the existing test
suite don't catch, plus dynamic testing on an Android emulator (API 37)
across a fresh install, light and dark theme, and real lesson/quiz
activity. This entry records what has been found and fixed **so far**;
the audit is not finished (see Outstanding below), so treat this as a
checkpoint, not a final RC1 sign-off.

**Baseline before touching anything:** `flutter analyze` clean, `flutter
test` 78/78 passing.

### BUG-010: Retry/Review Mistakes silently buries "Return Home" under stacked results screens — confirmed and fixed

Found on device, not from code reading: after retrying a quiz or using
"Review Mistakes" from the results screen, "Return Home" stopped
appearing to do anything. Repeated taps and even the hardware Back button
produced no visible change, on a real device frame rate — this was not
the emulator lag described below, since it was reproducible after
generous waits.

Root cause: `PracticeResultsScreen`'s "Retry" and "Review Mistakes"
buttons used `context.push('/quiz/play?...')`. When that session
finishes, `PracticeSessionScreen` does `context.pushReplacement(
'/quiz/results')` (`practice_session_screen.dart`) — replacing only the
`/quiz/play` frame it just pushed. The **older** `/quiz/results` frame
underneath is never touched, so every retry/review-mistakes round trip
nets +1 stacked `/quiz/results` route. Every one of those stacked copies
renders pixel-identical content, because the screen reads a single shared
`PracticeService.lastResult`, not per-route data — so a learner who
retries twice has to tap "Return Home" three times before anything
appears to happen, with zero visual feedback on the first two taps.
Confirmed by tapping Return Home repeatedly: the fourth tap (after one
initial quiz + one Review Mistakes + one Retry) finally landed back on
Practice Home.

Fix: both buttons now use `context.pushReplacement(...)` instead of
`context.push(...)` (`practice_results_screen.dart`), so a retry replaces
the results screen it was launched from rather than stacking on top of
it. The stack depth stays constant (`/quiz`, `/quiz/results`) no matter
how many times the learner retries. Preserves the existing comment's
documented intent — Back from results always lands on Practice Home —
which a plain `go()` would have broken.

**Not yet re-verified on a rebuilt APK.** The fix is in the source but the
running emulator session was still on the pre-fix build when this was
written up; re-verification is on the Outstanding list below.

### Static findings reviewed, not changed

A static sweep (separate read-only pass over the codebase, since
`flutter analyze`/tests give no signal on these) surfaced several
fire-and-forget `Future`s with no `try/catch` and a couple of
`FutureBuilder`s with no explicit error branch. Each was checked against
the actual call graph before deciding whether to touch it:

- **`ReviewScreen._ReviewList`'s `FutureBuilder` has no `hasError`
  branch** (`review_screen.dart`) — if `_resolveReviewItem` throws (e.g. a
  bundled lesson JSON fails to parse), `snapshot.hasData` stays false
  forever and the Review tab shows a permanent spinner instead of an
  error state. Real gap, cheap and safe to fix, but not yet done —
  carried onto the Outstanding list rather than rushed in alongside
  BUG-010.
- **`PracticeSessionScreen._start()` and `LearningScreen`'s lesson-save
  path call async work with no `try/catch`** — if `generateSession`
  throws (only reachable via a malformed `modeId`, and every real UI path
  supplies one from the fixed mode catalog) or a Hive write throws, the
  screen's "saving" flag never resets, permanently disabling the button
  it guards. Same class of bug as BUG-007. Not reachable through any
  actual button in this app today, so left alone rather than hardening
  code with no live path to it — noted here so it isn't rediscovered from
  scratch later.
- **Three script screens (`hiragana_screen.dart`, `katakana_screen.dart`,
  `kanji_screen.dart`) fire `Future<void>.microtask(() =>
  progressController.loadProgress(...))` in `initState` with no
  try/catch.** Only fails if a Hive box that already opened successfully
  at app startup somehow throws on a later read — not observed, not
  changed.
- **`DashboardScreen`'s per-card `FutureBuilder`s
  (`_resolveContinueLesson`, `_resolveScriptSummary`) build a new `Future`
  on every rebuild**, so any of the 7 providers it watches changing (e.g.
  `ref.invalidate(dueReviewsProvider)` after finishing a lesson) resets
  those cards to their loading state for a frame. Real, but a
  single-frame flicker with no data loss — the correct fix is routing
  these through cached `FutureProvider` families instead of inline
  `FutureBuilder`s, which is a bigger structural change than this audit's
  scope. Documented here rather than attempted under time pressure.

### Environment note: this emulator has severe input/render lag

Worth recording so a future session doesn't mistake it for an app bug
again. The running emulator logged `Davey! duration=6348ms` (a single
frame taking 6.3 **seconds**) and repeated `Skipped 375 frames!` warnings.
Early in this pass that lag produced a false alarm — a tap that looked
completely unresponsive for 10+ seconds, then landed. `drive.ps1`'s
per-action wait was raised from 1000ms to 2500ms as a partial mitigation.
Two other apparent "dead buttons" during this session turned out to be
my own screenshot-coordinate math (forgetting the 1.2x scale between the
900x2000 display crop and the device's actual 1080x2400), not app or
emulator behavior — worth the reminder that a silent tap failure needs
both explanations ruled out before it's written up as a finding.

### Outstanding — audit not yet complete

- Re-verify BUG-010 on a rebuilt APK (fix is in source, not yet re-run).
- Landscape orientation pass — not started.
- Force-stop/relaunch persistence check and offline (airplane-mode)
  behavior — not started.
- Dark theme pass covered Dashboard, Hiragana list, and the lesson
  introduction/stroke-order/tracing steps so far, all clean; Quiz,
  Search, Analytics, Achievements, and Settings not yet re-checked in
  dark mode specifically (they were only exercised in light mode this
  session).
- The three static findings above are logged, not fixed — revisit if a
  future pass has time, or if one of them stops being purely theoretical.

## Milestone 21: UX Polish, Responsive Layout & Notification Behaviour

A stabilization milestone — five targeted issues, no new features, no
redesign. Each was investigated for root cause before touching anything.

### Issue 1: Export/Import notification spam

`SettingsScreen._showComingSoon` called `ScaffoldMessenger.showSnackBar`
unconditionally on every tap, with no dedup or cooldown state anywhere —
`SettingsScreen` is a stateless `ConsumerWidget`, so there was nowhere for
a "last shown at" timestamp to live. `ScaffoldMessenger` queues rather
than replaces, so rapid taps played the whole backlog back one after
another instead of coalescing.

Added `ComingSoonGate` (`features/settings/services/coming_soon_gate.dart`),
a small in-memory class tracking a last-shown `DateTime` per feature key,
exposed as an app-lifetime `Provider` (`comingSoonGateProvider`) rather
than converting the screen to stateful — matches this app's existing
convention of putting behaviour in providers, not widget state. Session-only
by design: a 15-minute UI cooldown has no reason to survive an app
restart, so it isn't persisted to Hive. Export and Import key on separate
feature strings, so exhausting one's cooldown doesn't silence the other.
4 unit tests (`test/unit/coming_soon_gate_test.dart`) cover first-tap,
mid-cooldown, post-cooldown, and cross-feature independence.

### Issue 2: Dashboard tile alignment

Root cause: three `Wrap(children: [StatisticCard(...), ...])` sections
(Learning Statistics, weekly practice stats, Scripts) sized every card to
its own intrinsic content width. `StatisticCard`'s `Column` has no width
constraint, so "Lessons Completed" and "Average Accuracy" — different
label lengths — produced different-width cards in the same row, and the
number of cards per row changed unpredictably with available width rather
than settling into a clean grid. This is what read as "uneven or
improperly spaced" across screen sizes and orientations.

Added `EqualWidthGrid` (`shared/widgets/equal_width_grid.dart`): a
`LayoutBuilder` + `Wrap` that gives every child in a row the same computed
width, leaving height intrinsic (unlike a fixed-aspect-ratio `GridView`,
which risked overflow the moment a longer label wrapped to a second line).
Column count comes from `Responsive.isTablet`/`isLandscape` — 2 columns on
mobile portrait, 3 otherwise — which is the app's existing `core/utils/
responsive.dart` utility. It was written for exactly this and had zero
callers anywhere in the codebase until now. All three `Wrap` sites in
`dashboard_screen.dart` now use `EqualWidthGrid`.

### Issue 3: Typography consistency

No hardcoded `fontSize`s or raw `TextStyle`s exist anywhere in `lib/`
(confirmed by grep) — BUG-004's fix (dark-mode `Theme.of(context)`
lookups replacing `AppTypography`'s static getters) held, and no static
getter usages have crept back in. The actual inconsistency was a role
mismatch: the section-heading role (a group label within a scrollable
screen body — "Learning Statistics", "Scripts" on Dashboard; every section
title on Analytics) renders at `titleLarge` everywhere **except**
`SettingsSection` and `SearchSection`, which used `titleMedium` — one
step smaller, for the identical role. That's what read as "several
headings appear noticeably smaller than expected." Fixed both shared
widgets, plus the four standalone section headers written directly in
`settings_screen.dart` ("Data Management", "About", "Legal",
"Diagnostics") that had the same `titleMedium` mismatch. `legal_document_
screen.dart`'s `#`/`##` Markdown heading styles were left alone — that's
a real, self-contained two-level heading hierarchy for one document
renderer, not an inconsistency with the rest of the app. Dialogs need no
change either: no `dialogTheme` override exists, so `AlertDialog` already
uses Material 3's own default hierarchy (`headlineSmall` title,
`bodyMedium` content) consistently everywhere. No bottom sheets exist in
this app.

### Issue 4: Lesson screen visual clutter

`LearningScreen`'s header was four stacked `Text` rows — title, character,
step, position — each separated by the same `AppSpacing.sm`, reading as an
undifferentiated status dump rather than a heading with context under it.
Merged the step and position facts onto one line ("Introduction ·
Character 1 of 5"), reusing the "·"-joined compact-fact pattern already
used elsewhere in this app (the dashboard's script summary cards). Also
tightened the gap under the "Lesson N" title from `sm` to `xs`, so it
reads as a heading with a subtitle, and widened the gap between the two
action-button rows (step navigation vs. character navigation/restart)
from `md` to `lg`, so the two groups of actions read as separate stages
rather than one four-button block. No functionality changed — same
buttons, same handlers, same information, fewer equally-weighted lines.

### Issue 5: Tracing-stage CTA wording

Root cause, confirmed against the state machine: `_submitWriting` branches
on `currentStep == LearningStep.tracing` — during tracing it clears the
canvas and calls `_controller.nextStep()`; only the `else` branch (free
writing) calls `_evaluateDrawnStrokes`. So "Check my writing," shown by
`WritingPracticePanel` for both steps, was never true during tracing —
nothing gets evaluated there at all. Added a `submitLabel` parameter to
`WritingPracticePanel` (default `'Check my writing'`, so its one other
caller needed no change beyond passing the new value), and
`LearningScreen` now passes `'Continue to Free Writing'` specifically for
the tracing step. Free writing keeps the original label, since that's the
step the evaluator actually scores.

### Verification

`flutter analyze`: clean. `flutter test`: 82/82 (78 baseline + 4 new
`ComingSoonGate` tests).

**Not verified on device for this milestone** — explicitly at the user's
direction; the development emulator was running unusably slowly this
session. Every change here is layout/wording/state-tracking, not lesson
or scoring logic, and all five are backed by the reasoning above plus a
clean analyzer/test run, but none of it has been seen rendered. Treat
Issues 2–5 in particular (all visual) as code-reviewed, not
device-confirmed, until someone opens the app on a working emulator or
device and checks: Settings/Search headers now match Dashboard's section
heading size in both themes, the three dashboard `Wrap` sections form a
clean grid in portrait and landscape, the lesson header/button spacing
reads as intended, and the tracing step's button says "Continue to Free
Writing" rather than "Check my writing."

## Milestone 22: Writing Engine Accuracy & Canvas State Management

Critical stabilization milestone: two correctness bugs in the writing
evaluator, and one P0 state-leak bug in the lesson flow. No OCR/AI/cloud
handwriting recognition introduced — every fix works within the existing
geometric evaluator (`WritingEvaluator`) and the existing per-character
canvas-reset pattern in `LearningScreen`.

### Issue 1: incomplete drawings received a score

Root cause, in `writing_evaluator.dart`: `_denoise` filters out taps and
flecks below a minimum arc-length threshold, but when **every** stroke
was noise, it fell back to returning the *unfiltered* original strokes —
"so the attempt scores badly rather than being treated as empty," per the
old comment. That fallback was the bug: it hands a stray dot straight to
`_matchShapes`, which resamples a single point to 32 identical copies and
compares it against real reference strokes — a dot sitting anywhere near
the glyph's centre can score a non-trivial, non-zero similarity purely by
proximity. Separately, even a *real* partial attempt (say, one correct
stroke where three were expected) was never bounded by how much of the
character was actually drawn: `_strokeCountScore`'s multiplicative floor
is 0.55, so a lone accurate stroke against a 3-stroke character could
still land respectably above zero.

Two fixes, both reusing the evaluator's existing multiplicative-factor
architecture rather than adding a parallel mechanism:

1. `_denoise` no longer falls back to the unfiltered strokes — if
   everything is noise, the result is empty, and `evaluate()`'s existing
   `drawn.isEmpty` branch (previously reachable only for a truly empty
   canvas) now correctly also catches "drew nothing but taps." Feedback
   for this case is now distinct ("too small to count as a stroke")
   rather than reusing the generic "finish before submitting" line, via a
   new `tooSmallToScore` flag through `_buildFeedback`.
2. A new **completion factor**: total (normalized) ink drawn versus total
   (normalized) ink the reference needs, raised to a 1.5 exponent so a
   near-complete attempt (ratio ≥ ~0.8) stays near full weight while a
   partial one (ratio ≤ ~0.3) is pushed under 5%. Normalizing both sides
   independently before comparing arc length is what makes this
   scale-and-position-independent, consistent with how the rest of the
   evaluator already compares shapes.

5 new unit tests (`test/unit/writing_evaluator_test.dart`): a single dot
scores exactly 0 with distinct feedback, an extremely short stroke scores
0, one correct stroke out of three expected scores well under half
credit, and a faithful full-length trace is confirmed unaffected by the
new factor. All 19 pre-existing evaluator tests still pass unchanged —
verified by hand against the new math before running them, not just
after: the existing "single diagonal line," "missing strokes," and
"extra strokes" tests only assert `lessThan` bounds, which the new
(always ≤ 1) completion factor can only tighten, never violate; the
tests with `greaterThan` bounds (faithful trace, small-but-correct
character, order-preserved trace) all have a drawn/reference ink ratio
at or near 1.0, where the new factor is a no-op.

### Issue 2: tracing accepted anything

Root cause: tracing was never scored at all. `_submitWriting`'s tracing
branch cleared the canvas and advanced unconditionally; the button itself
was only gated on `hasInk` (any non-empty canvas), not on resembling the
guide in any way. "Detecting that the user touched the screen" was a
literal description of the existing behaviour, not an exaggeration.

Fixed by scoring tracing with the *same* `WritingEvaluator.evaluate()`
call already used for the graded free-writing attempt, run against the
character's guide strokes (already resolved and available regardless of
the learner's "Show stroke guides" display preference — that setting only
controls the on-canvas overlay, not whether the underlying reference data
exists). A deliberately lenient floor (`_minTracingAccuracyToAdvance =
0.3`) blocks advancing only when the trace is essentially unrelated to
the guide; a genuine, if imperfect, beginner trace clears it comfortably
given the evaluator's already-generous shape-match falloff. Below the
floor, a SnackBar asks the learner to trace closer to the guide and the
step does not advance — ink is left in place (not cleared) so they can
adjust rather than start over. This does not touch scoring shown to the
learner as their "result": tracing's score is used only as a gate, never
displayed or persisted; free writing remains the sole graded attempt.

### Issue 3 (P0): canvas leaked traced ink into the memory-writing stage

Root cause, in `learning_screen.dart`: the canvas-reset logic
(`_strokesForItemId != currentCharacter.id`) only fired on a **character**
change, never on a **step** change within the same character. The
generic "Next" button — present on every step, including tracing and
free writing, via the always-visible Previous/Next row — calls
`_controller.nextStep()` directly and never goes through
`_submitWriting`, which was the only place that (partially) cleared
`_strokes`. So: trace the guide, skip the check button, tap the generic
Next instead, and the traced ink carried straight into the free-writing
canvas — showing the answer during the stage meant to test recall
without it. Confirmed against the state machine, not just observed
behaviour, before touching anything.

Fixed at the single point all step transitions pass through:
`build()`. A new `_strokesForStep` field tracks which step `_strokes`
currently belongs to, alongside the existing `_strokesForItemId`. The
reset condition now fires whenever *either* the character or the step
changes — the character branch does the full reset (strokes, guide
strokes, result) exactly as before; a new step-only branch resets
strokes and the writing result (not guide strokes, which belong to the
character, not the step, so re-fetching them on every step would just be
a wasted flicker). Because this lives in `build()` rather than inside any
one button's handler, it fires regardless of which control ends a step —
the writing panel's own submit button, the generic Next button, Previous,
Restart, all of them — which is what "regardless of how the previous
stage was exited" requires. The redundant manual `_strokes = <Stroke>[]`
inside `_submitWriting`'s tracing branch was removed, since the build()
guard now covers it unconditionally — one reset mechanism instead of two.

There is no separate undo/redo history to reset: `Undo`/`Clear` in
`WritingPracticePanel` operate directly on the current `_strokes` list
(`sublist`/empty list), so clearing `_strokes` inherently clears both.
`WritingEvaluator` itself holds no mutable state across calls (a `const`
class, pure functions), so there is nothing evaluator-side to reset
beyond the `_writingResult` this fix already clears.

### Cross-script and theme consistency

Deliverable 4 (Hiragana/Katakana/Kanji consistency) and deliverable 5
(light/dark theme) are satisfied **by construction** rather than by
separately testing three scripts and two themes: `WritingEvaluator` and
`LearningScreen` contain no script-specific or theme-specific branching
anywhere — every script routes through the same `LearningScreen` widget
via `ContentRepositoryFactory`, and none of this milestone's changes
touch color, styling, or theme data at all (Issues 1–3 are evaluator
math and canvas-state logic only). There was nothing to make consistent
across scripts or themes that wasn't already shared.

### Verification

`flutter analyze`: clean. `flutter test`: 87/87 (82 baseline-after-M21 +
5 new evaluator tests).

**Not verified on a running app** — explicitly at the user's direction
for this session (the development emulator is currently too slow to use).
Issue 3 in particular is the kind of bug that is easiest to trust once
seen: open a lesson, trace a character, skip the check button, tap Next,
and confirm the free-writing canvas comes up blank. That has not been
done. All three fixes rest on tracing the exact code path by hand (this
entry documents that reasoning above) plus a clean analyzer/test run, not
on watching it happen.

## Milestone 23: Review System & Quiz Navigation Audit

Four reported issues. Two of them (2 and 4) turned out to share a single
root cause that also explains the "identical navigation" symptom, so
they're documented together below rather than as separate fixes.

### Issues 2 & 4: one stale-session bug behind both

**Root cause.** `PracticeService` is an app-lifetime
`ChangeNotifierProvider` singleton, and its `clearSession()` method has
**no callers anywhere in the codebase** — it is dead code. So once any
quiz finishes, `currentSession` keeps pointing at that finished session
forever, with `isComplete == true` (`currentIndex >= questions.length`).

`PracticeSessionScreen` starts its own session from an
`addPostFrameCallback`, which by definition runs *after* the first
`build()`. That first build therefore observed the **previous** session:
not generating, not null, not empty, and complete. It fell straight into
the `session.isComplete` branch and immediately
`pushReplacement`ed to `/quiz/results`.

That single defect produces both reported symptoms:

- **Issue 4** ("multiple Quiz menu buttons navigate to the same screen"):
  every mode card — Recognition, Meaning, Reading, Listening, Mixed, Weak
  Items — bounced instantly to the same stale results screen. The routing
  was never wrong: `go_router` parses `mode` correctly, `_startMode`
  builds a distinct URL per mode, and `generateSession` switches on it
  properly. Nothing in the navigation layer needed changing.
- **Issue 2** ("Review Mistakes performs the same action as Retake
  Quiz"): both buttons launch `/quiz/play`, so both hit the same bounce
  and returned to the results screen they were launched from — two
  different buttons that both appeared to do nothing, which is exactly
  what "the same action" looks like from outside. `startReviewMistakes`
  (scoped to the missed item ids) and `startSession` (a fresh full
  session) were already correctly distinct in the service layer.

Neither reproduces on a fresh install — both need one completed quiz
first — which is why they showed up during testing rather than earlier.

**Fix.** One guard: `!_started` added to the loading condition in
`PracticeSessionScreen.build`. Until this screen's own `_start()` has
run, it shows the loading indicator instead of interpreting whatever
session the singleton happens to be holding. That closes exactly the
one-frame window the bug lived in, without touching routing, the
service, or the generator.

**Also fixed for Issue 2**, separately from the bounce: the session
screen had no `AppBar` at all, so once the bounce was fixed, Recognition
and Meaning (both "a glyph plus four text options") would still have been
visually indistinguishable. It now shows a title — the mode's own name
from `PracticeGenerator.modeById`, or "Review Mistakes" when scoped to
mistake ids. Reuses the existing catalog lookup rather than adding a
second title table.

4 unit tests (`test/unit/practice_session_staleness_test.dart`) pin the
state facts the guard depends on: a completed session reports
`isComplete` and returns a null `currentQuestion` (so the screen cannot
simply fall through to rendering it), while a fresh one does neither.

### Issue 1: Review section showed the wrong information

Three separate defects, all in the presentation layer — the scheduler,
repository, providers, and due-item calculation were all correct on
inspection (`getDueReviews` filters by `isDue` and sorts by a priority
combining overdue-ness, inverted ease, and lapse count, exactly as the
Milestone 21 enhancement pass built it).

1. **The card title was malformed.** It was built as
   `'Lesson ${lesson.characters.first.character}'` — the literal word
   "Lesson" glued to the lesson's first *glyph* — rendering as
   **"Lesson あ"**. That names neither the script nor the lesson number,
   so with more than one script in rotation the list was a column of
   near-identical unidentifiable rows. `LessonModel` already carries
   `lessonNumber`, `title` ("Lesson 1") and `description` ("Vowels");
   the title is now `"Hiragana · Lesson 1"`.
2. **No progress or priority information reached the screen.**
   `ReviewCard` accepted only a `title`, so the carefully priority-ordered
   list rendered flat — nothing indicated which item was most urgent or
   how overdue anything was. Added an optional `subtitle` (the same
   title-over-subtitle shape `LessonCard` and `PracticeCard` already use,
   not a new pattern) carrying the lesson topic plus a "Due today" /
   "N days overdue" label derived from `nextReview`.
3. **The list header showed no count.** The dashboard's
   `ReviewSummaryCard` says "N Lessons Due", but tapping through landed
   on a list that stated no total. Added a matching count line so the two
   screens agree, noting the list is ordered most-fragile-first.

**Also fixed here** (a finding logged during the earlier RC1 QA audit as
"logged, not fixed"): `_ReviewList`'s `FutureBuilder` checked only
`!snapshot.hasData`. `Future.wait` rejects if any lesson lookup throws,
and on rejection `hasData` stays false permanently — so a load failure
became an infinite spinner with no way out. It now checks `hasError`
first and falls back to the existing empty state rather than inventing a
new error UI. Since Issue 1 was specifically "the Review section doesn't
present correct information", leaving a known permanent-spinner path in
the same widget would have been an odd omission.

3 widget tests (`test/widget/review_card_test.dart`) cover the corrected
title/subtitle rendering, the no-subtitle case, and tap-through.

### Issue 3: removed the redundant "Return Home" button

`_returnToPracticeHome` popped back to whatever pushed the results
screen — the same thing a back action already does. Removed.

One thing the report didn't mention but that removal exposed: this screen
had **no `AppBar` at all**, unlike every other pushed screen in the app
(Search, Settings, Learning Flow). Flutter only renders the automatic
back arrow when a screen has one, so removing the button as-asked would
have left the system back gesture as the only way off the screen. Added
an `AppBar` titled "Quiz Results", restoring the same affordance
everything else already has. "Review Mistakes" and "Retry" are untouched.

The empty-state "Return to Practice" button (shown when there is no
completed session at all) was deliberately left alone — that is a
different screen state, not the completion screen the issue was about,
and it is the only control on it.

### Cross-script verification

Deliverable 5 (Hiragana/Katakana/Kanji) is satisfied structurally rather
than by three manual passes: none of the changed code branches on script.
The quiz fix is in a screen shared by all modes and scripts; the review
fix resolves scripts through `ContentRepositoryFactory` and the new
script-name map covers all three registered ids, falling back to the raw
`contentId` for anything unregistered.

### Verification

`flutter analyze`: clean. `flutter test`: 94/94 (87 after M22 + 4 staleness
+ 3 review-card).

**Not verified on a running app** — the emulator remains too slow to use
this session, per the same standing direction as Milestones 21 and 22.
The stale-session fix (Issues 2 & 4) is the one most worth confirming by
hand, and it has a precise repro: complete any quiz, return to the
Practice menu, tap a *different* mode, and confirm that mode's own quiz
starts (with its name in the app bar) instead of the previous result
reappearing.

## Next Required Action

Four things are open, none signed off:

1. **Milestone 23** — confirm the stale-session repro above, and that the
   Review list now names scripts and lessons correctly with real data.
2. **Milestone 22** — the tracing→free-writing canvas-reset repro.
3. **Milestone 21** — the visual checks (header sizes, dashboard grid,
   lesson spacing, tracing CTA wording).
4. **The RC1 QA audit** — orientation, persistence, offline, remaining
   dark-theme screens, and re-verifying BUG-010 on a rebuilt APK.

All four are on-device checks; none needs new code unless a check fails.
Do not start post-release work, v1.1 planning, or Play Store submission
until they are closed out.

**Open items are release blockers, not bugs**, and are tracked in
`RELEASE_CHECKLIST.md`: a production upload keystore must be created
(release builds are intentionally debug-signed today), the placeholder
launcher icon and splash artwork should be replaced with real branding,
startup performance and tablet/landscape layouts need verification on
physical hardware, store assets are not started, and iOS platform support
is deferred to a future milestone. The release APK was rebuilt after
BUG-007/008/009 (debug-signed, as above); nothing since then — the RC1
audit's BUG-010 fix, or Milestones 21, 22 and 23 — is in that APK yet.
Rebuild once all four outstanding on-device checks above have been done.

## Milestone 24: Analytics & Activity Calendar Polish

### Issue 1: Activity calendar orientation

**Root cause was in rendering, not data ordering.** `AnalyticsService`
already built `dailyActivity` correctly — 30 entries, oldest first,
strictly chronological (`_buildDailyActivity` in
`analytics_service.dart`). The bug was entirely in
`ActivityHeatmap`: it rendered the days with a plain `Wrap` of squares,
which just fills each row left-to-right until it runs out of width and
starts a new row. That's a flow layout, not a calendar — how many days
land in each row (and therefore which day starts each new row) depended
on the current screen width, so the grouping into visual "weeks" shifted
on every resize, orientation change, or device size, and never aligned
to real weekdays. There was nothing wrong to "fix" in the date math; the
squares were always in the right order, just laid out with no notion of
a week grid.

**Fix.** Rewrote `ActivityHeatmap` (`lib/features/analytics/widgets/activity_heatmap.dart`)
as an actual week grid instead of a wrap: columns are weeks, rows are
weekdays (Sunday at the top), oldest week on the left and the current
week on the right, so the visual direction reads left-to-right and
top-to-bottom as chronological progression — the intended GitHub-style
reading flow. The first week is padded with blank cells up to the
correct weekday so day-of-week alignment is exact even when the 30-day
window doesn't start on a Sunday. Added weekday initials as a left-hand
label column, and a highlight ring on today's cell, both for
readability, not as a new feature. The grid is wrapped in a horizontal
`SingleChildScrollView`, so it stays legible and responsive at any width
(narrow phone portrait through tablet landscape) by scrolling instead of
reflowing, and cell sizing/spacing/colors/rounding, tooltip text, and
the empty/intensity color scale are all unchanged from before — same
Material 3 theme colors, same widget call site in `analytics_screen.dart`.
No other analytics widgets, providers, or the `AnalyticsService` data
layer were touched.

`flutter analyze` clean. No existing tests referenced `ActivityHeatmap`
directly (analytics is covered at the service/model level), so none
needed updating.

## Phase 1: Continuous Integration Foundation (GitHub Actions)

Added `.github/workflows/flutter_ci.yml`: runs on every push and every
pull request, on `ubuntu-latest`. Four steps in order, each gating the
next, so a failure stops the workflow immediately and the failing step's
name (visible in the Actions log) says which stage broke:

1. `flutter pub get` (via `subosito/flutter-action@v2`, pinned to Flutter
   `3.44.8` — the exact version this repo is developed against, per
   `flutter --version` — rather than floating on `stable`, so CI can't
   silently drift from what's actually been run locally).
2. `dart format --output=none --set-exit-if-changed .`
3. `flutter analyze`
4. `flutter test`

**`flutter format` doesn't exist in this Flutter version** — it was
removed in favor of `dart format`, which is what the workflow (and the
Testing section of `README.md`) actually invokes. Same behavior
(`--set-exit-if-changed` fails the step without touching any file), just
the current command name.

**The formatting-check step required a one-time repo-wide reformat
first.** `dart format --set-exit-if-changed .` failed on 108 of 189 files
before this phase — the codebase had never been run through `dart format`
end to end, so adding the check as specified would have made CI red from
its very first run and stayed that way. Ran `dart format .` once
(whitespace/line-wrapping/trailing-comma only — verified with `git diff
-w` that no non-formatting hunks exist, then `flutter analyze` and
`flutter test` both still pass clean/94-for-94 after), so the new check
starts green instead of permanently broken. No application logic changed.

Both the Flutter SDK (keyed on `3.44.8` via `flutter-action`'s own
`cache: true`) and the pub package cache (`~/.pub-cache`, keyed on a hash
of `pubspec.lock`) are cached between runs. `concurrency` cancels a
stale in-progress run when a newer push/PR update lands on the same
branch, so runs don't queue up.

Documented in `README.md` under a new "Continuous Integration" section.
Scope was intentionally CI-only, per this phase's constraints: no release
builds, signing, artifacts, or deployment (Fastlane, Play Store, Firebase
App Distribution) were added — those are later phases, and this workflow
was kept to one job so they can be added as new jobs/steps without
restructuring it.

## Phase 2: Build Verification & Artifact Generation

Extended `.github/workflows/flutter_ci.yml` in place — same single job,
same file, no second workflow — with four more steps after `flutter
test`: `flutter build apk --release`, `flutter build appbundle --release`,
then an `actions/upload-artifact@v4` step for each output. Renamed the
step names to the plain imperative form the milestone asked for (Check
formatting / Static analysis / Run tests / Build APK / Build App Bundle),
so each Actions log entry names its stage directly instead of a
paragraph-style label.

**Verified locally before touching CI**, since a broken path here only
shows up as a red run: ran `flutter build apk --release` and `flutter
build appbundle --release` for real. Both succeed and produce
`build/app/outputs/flutter-apk/app-release.apk` (52.7MB) and
`build/app/outputs/bundle/release/app-release.aab` (51.2MB) — the exact
paths now wired into the `upload-artifact` steps. `build/` is already
git-ignored, so nothing about this pass risked committing binaries.

**No signing setup needed.** `android/app/build.gradle`'s release
`buildTypes` block already points `signingConfig` at the debug config —
a decision from the M20 release (see `RELEASE_CHECKLIST.md`, no
production keystore exists yet) — so `flutter build apk/appbundle
--release` succeeds on a stock GitHub runner with zero secrets. This
phase intentionally doesn't add a production keystore; that's release
signing work, out of scope here.

**Added `actions/setup-java@v4` pinned to JDK 17**, matching
`sourceCompatibility`/`jvmTarget` in `android/app/build.gradle` exactly.
`ubuntu-latest` ships several JDKs and the one `JAVA_HOME` happens to
point at isn't guaranteed to be 17 as the runner image updates over
time, so this pins the version the Gradle build actually targets instead
of relying on whatever the image defaults to today.

**Caching**, reviewed per the phase's investigation requirements:
- Pub packages: already cached from Phase 1, unchanged.
- Flutter SDK: already cached from Phase 1 via `flutter-action`'s own
  `cache: true`, unchanged.
- Gradle: new — `~/.gradle/caches` and `~/.gradle/wrapper`, keyed on a
  hash of `gradle-wrapper.properties` plus every `*.gradle*` file under
  `android/`, so a cache hit requires the exact same Gradle/AGP/plugin
  versions and invalidates automatically the moment any of those change.

Artifacts (`flutter-release-apk`, `flutter-release-aab`) upload with
`if-no-files-found: error`, so a build that silently produced nothing at
the expected path fails the run instead of uploading an empty artifact.
Retention is left at GitHub's default — no project-specific value was
already set, and the milestone said not to introduce one. Documented in
`README.md` under "Continuous Integration": how to find and download the
two artifacts from a run's Actions summary page.

Scope stayed build-verification-only per this phase's constraints: no
Play Store, Firebase App Distribution, or Fastlane integration, and no
production signing — those remain later-phase work.

## Phase 3: Release Workflow, Version Validation & Branch Protection

Added a second, dedicated workflow, `.github/workflows/release.yml`,
instead of extending `flutter_ci.yml` — the milestone was explicit that CI
(validation, every push/PR) and Release (delivery, only on a `v*` tag)
stay separate workflows. `flutter_ci.yml`'s triggers, job, and step
sequence are otherwise untouched from Phase 2.

**Reuse, not duplication.** The milestone's investigation requirements
asked to "reuse shared workflow steps where practical" and "avoid
duplicating configuration unnecessarily" — but the two workflows are
separate files with separate triggers, and GitHub Actions has no way to
share literal steps across workflow files except a composite action or a
reusable (`workflow_call`) workflow. Pulled the JDK-install /
Flutter-install / pub-cache / Gradle-cache steps Phase 2 had written
inline into `.github/actions/setup-flutter-build/action.yml`, a composite
action with `flutter-version`/`java-version` inputs (defaulted to the
same `3.44.8`/`17` Phase 2 pinned). Both `flutter_ci.yml` and
`release.yml` now call `uses: ./.github/actions/setup-flutter-build`
instead of each carrying its own copy — one definition of "how this repo
builds" instead of two that could quietly drift apart. This is the one
place Phase 3 touches `flutter_ci.yml`: its setup steps became one
composite-action call; format/analyze/test/build/upload-artifact steps,
names, and order are byte-for-byte what Phase 2 shipped.

**Version validation (`validate-version` job).** Reads `version:` out of
`pubspec.yaml` with `grep`/`sed` (no extra tooling needed) and fails the
job with an `::error::` annotation if: the field is missing, or the value
isn't `<major>.<minor>.<patch>+<build>` (regex-anchored, e.g. `1.0.0+1`).
Beyond what the milestone listed explicitly, it also fails if the numeric
part doesn't match the pushed tag (`v1.0.0` requires `pubspec.yaml` to
say `1.0.0+<build>`) — the milestone's own Part 3 example (`Tag: v1.0.0`
→ `Release: Version 1.0.0`) only makes sense if those two are guaranteed
to agree, and "application versions remain consistent" (Part 1's stated
objective) is exactly this check. Verified the script against the real
`pubspec.yaml` (currently `1.0.0+1`) for both the matching-tag and
mismatched-tag cases before wiring it into the workflow. Version numbers
are never written by the workflow — bumping `pubspec.yaml` stays a
developer action, per the milestone's explicit instruction.

**Build & publish (`build-and-release` job).** `needs:
validate-version`, so a bad version never reaches a build. Runs the exact
`flutter build apk --release` / `flutter build appbundle --release`
commands verified in Phase 2, via the shared setup action, then
`softprops/action-gh-release@v2` (a widely-used, actively maintained
release action — chosen over hand-rolling `gh release create` calls so
release-creation edge cases, like re-running on an existing tag, are
someone else's tested code, not new logic in this repo) creates a
`draft: false, prerelease: false` GitHub Release titled `Version
<version>` with auto-generated release notes, and attaches
`app-release.apk`/`app-release.aab` from the exact output paths confirmed
in Phase 2. `fail_on_unmatched_files: true` fails the workflow if either
asset can't be found/uploaded, matching the milestone's requirement.
`permissions: contents: write` is scoped to this workflow only (CI stays
at the default read-only token) since only Release actually needs to
create a Release. No new secrets: `action-gh-release` uses the
automatic, repo-scoped `GITHUB_TOKEN`.

**No app signing was added.** Same as Phase 2 — the release build type in
`android/app/build.gradle` still points at the debug signing config, so
these are functionally the same debug-signed builds as CI's, just
attached to a tagged GitHub Release rather than a workflow-run artifact.
A production keystore remains open work in `RELEASE_CHECKLIST.md`.

**Branch protection is documentation only**, per the milestone's explicit
instruction not to configure repository settings through code (GitHub
branch protection isn't expressible in a workflow file regardless).
Added a "Recommended repository settings (not yet applied)" section to
`README.md` covering the `main`/`develop`/`feature`/`bugfix`/`hotfix`
branch model, and the specific rule recommended for `main`: require PRs,
require the `Flutter CI` status check, require branches up to date before
merge, disallow bypassing the above, block force-pushes and deletion of
`main`, and require linear history as an optional style choice. This
repository currently has only `main`, with no protection rules and no
`develop`/`feature`/`bugfix`/`hotfix` branches yet; the recommendation is
written as a decision for whoever has admin access to make deliberately,
not as a description of current repository state.

Constraints respected: no Play Store, Firebase App Distribution, or
Fastlane integration; no production signing; `flutter_ci.yml`'s
push/PR-triggered validation behavior is unchanged.

## Phase 4: Automated Dependency Management & Security Monitoring

Added `.github/dependabot.yml`, schema v2, two `updates` entries.

**Ecosystems: exactly the two the repo has, nothing speculative.**
Checked before writing anything — no `ios/` directory, no `package.json`,
`Gemfile`, `requirements.txt`, or `Dockerfile` anywhere in the repo, so
`pub` (Dart/Flutter — `pubspec.yaml`/`pubspec.lock`) and `github-actions`
(the two workflow files from Phases 1-3) are the only two ecosystems
configured, matching the milestone's own explicit Part 1 scope and its
"avoid monitoring unused package managers" investigation requirement.
Deliberately **not** added: a `gradle` ecosystem entry for the AGP
(`9.0.1`) / Kotlin (`2.3.20`) plugin versions pinned in
`android/settings.gradle.kts` — Dependabot does support tracking those,
and they're real pinned versions that could go stale, but the milestone's
Part 1 named only `pub` and `github-actions` explicitly; adding a third
ecosystem nobody asked for cuts against "keep the configuration simple
and maintainable" (investigation requirement 5). Worth revisiting in a
future phase if AGP/Kotlin version drift becomes a real maintenance
concern.

**Schedule.** Both ecosystems: `weekly`, Monday 06:00 UTC — one fixed
day so all routine dependency PRs land together for a single weekly
review pass, not scattered through the week. Security-vulnerability
updates aren't gated by this schedule at all — GitHub opens those
immediately when a relevant advisory publishes, independent of
`dependabot.yml`'s `schedule:` block, provided "Dependabot security
updates" is turned on under **Settings → Security**. That's a repository
setting, not something expressible in a config file, so — same posture
as Phase 3's branch-protection section — it's documented as a
recommendation in `README.md` rather than assumed to already be on.

**Grouping and majors.** Each ecosystem groups its own minor/patch bumps
into one PR (`flutter-minor-and-patch`, `github-actions-minor-and-patch`,
via `groups: <name>: patterns: ["*"], update-types: [minor, patch]`) to
cut PR-per-package noise, per Part 3. Major-version bumps are
deliberately excluded from that `update-types` filter, so they always
surface as their own individual PR rather than riding along inside a
grouped one — the milestone's Part 4 asked to avoid *unnecessary* major
upgrades, and keeping majors ungrouped is what makes them easy to spot
and defer/reject individually rather than accepting them as a byproduct
of clearing a batched PR.

**No constraint rewriting.** Verified this is actually true for this
repo, not just asserted: most direct dependencies in `pubspec.yaml`
(`flutter_riverpod: any`, `go_router: any`, etc. — see
`CLAUDE.md`'s approved-dependencies list) are declared as `any`, so
Dependabot's default `pub` versioning strategy only needs to bump
`pubspec.lock`'s resolved versions to pick up a new release; it doesn't
need to touch `pubspec.yaml`'s constraints at all unless a dependency
genuinely can't be satisfied any other way. No `versioning-strategy`
override was added — the default already does what Part 4 asked for
here, so nothing to configure.

**Labels: `dependencies` + `flutter`, or `dependencies` +
`github-actions`.** The milestone's suggested label set also included
`security`, but `dependabot.yml`'s `labels:` field applies uniformly to
every PR from that `updates` entry — there's no config-level way to
attach a label only to the subset that are vulnerability-driven, so
adding `security` to both lists would just mislabel every routine
version bump as a security fix. Documented this limitation in
`README.md` rather than papering over it with a label that would lie
about most of the PRs wearing it.

**CI integration required no changes at all.** `flutter_ci.yml` already
triggers on `pull_request:` with no author/branch restriction, so a
Dependabot-authored PR runs the identical format/analyze/test/build
pipeline as any human PR the moment it opens — Part 5's requirement was
already satisfied by Phase 1's original trigger configuration. Per this
phase's explicit constraint, no new workflow (auto-merge or otherwise)
was added; a Dependabot PR goes through the same manual
review-then-merge step as everything else, documented in `README.md`
under "Dependency management (Dependabot)" alongside what Dependabot is,
the weekly cadence, and why auto-merge stays off (passing CI proves the
app still builds and tests still pass, not that a dependency's behavior
is unchanged in every way the suite doesn't cover — still a human
decision).

## Phase 5: Code Coverage & Quality Reporting

Extended the existing `validate` job in `flutter_ci.yml` — no second
workflow, per the constraint. Three changes to one job:

1. **`flutter test` → `flutter test --coverage`.** Same tests, same
   pass/fail behavior (a failing test still fails the step and the
   workflow immediately, unchanged) — the only difference is Flutter
   also writes `coverage/lcov.info` alongside the run.
2. **New "Verify coverage report was generated" step**, directly after
   tests: fails with an explicit `::error::` if `coverage/lcov.info`
   isn't present, rather than letting a silently-missing file surface
   later as a confusing artifact-upload failure. No placeholder file is
   ever written — if coverage generation didn't happen, this step is
   the thing that says so.
3. **New `coverage-report` artifact upload** (`coverage/lcov.info`,
   `if-no-files-found: error`) — placed right after that verification
   step, before the APK/AAB build steps, so it's grouped with the
   testing stage it belongs to rather than mixed in with the build
   artifacts from Phase 2. Distinct artifact name, so nothing here
   duplicates or collides with `flutter-release-apk`/`flutter-release-aab`.

**Verified locally before touching CI**, same discipline as Phase 2: ran
`flutter test --coverage` for real, confirmed `coverage/lcov.info` is
written (2,784 lines) at the exact path the milestone specified, and
computed the actual baseline from it — summing `LF`/`LH` records gives
**1,290 of 2,452 lines, ~53% line coverage**, as of this phase. That
number is recorded in `README.md` as a snapshot, explicitly labeled as
moving, not a target. `coverage/` was already git-ignored (Phase 1 never
needed to touch it), so no generated files risk being committed.

**No threshold, by design.** Nothing in the new steps inspects the
coverage percentage or can fail based on it — the verification step only
checks the file exists, not what's in it. Consistent with this phase's
explicit "informational, not enforced" objective: a threshold set against
a 53%, largely-untested baseline would either be meaninglessly low or
create an incentive to pad numbers with low-value tests rather than
actually improve testing where it matters.

**Codecov: investigated, deliberately not wired in.** Asked before
assuming — sending this project's coverage data to a third-party service
is the kind of call that should be made with an actual Codecov account
in hand, not defaulted into as a side effect of a CI update, and the
milestone itself explicitly sanctioned documenting it instead of adding
"incomplete configuration." Full integration steps (account setup, the
`CODECOV_TOKEN` secret if wanted, the exact `codecov/codecov-action@v4`
step with `fail_ci_if_error: false`) are written out in `README.md`'s
"Code coverage" section as a ready-to-paste follow-up, not implemented.

Documented in `README.md`: how coverage generates, the current baseline
number, how to inspect `lcov.info` locally (`genhtml` for a static HTML
report, or an editor extension like VS Code's Coverage Gutters that reads
the file directly), why it's informational for now, and the future path
to Codecov. Constraints respected: no threshold, no build failing on
coverage percentage, no second workflow, `flutter_ci.yml`'s existing
format/analyze/test/build steps and the Phase 2 build artifacts are
otherwise untouched.
