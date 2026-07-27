# Project Log

## Project

Offline-first Flutter application for learning Japanese writing on Android
phones and tablets. The learning order is Hiragana, Katakana, then Kanji.

## Current State (read this first in a new session)

- **Last completed milestone: 20 (Production Release v1.0), plus two
  post-release bugfixes: BUG-001 (Android back button) and BUG-002 (the
  writing canvas never existed — see that entry below, it's a substantial
  feature build, not a small patch).** `flutter analyze` clean, `flutter
  test` passing (36/36). **The release APK/AAB have not been rebuilt since
  BUG-002** — rebuild before treating release artifacts as current.
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

## Next Required Action

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

## Next Required Action

None. All 20 milestones are complete plus the BUG-001 navigation fix and
BUG-002 writing-canvas build above. The app is at v1.0.0, `flutter
analyze` is clean, `flutter test` passes (36/36). Do not start
post-release work, v1.1 planning, or Play Store submission until the user
explicitly requests it and defines scope.

**Open items are release blockers, not bugs**, and are tracked in
`RELEASE_CHECKLIST.md`: a production upload keystore must be created
(release builds are intentionally debug-signed today), the placeholder
launcher icon and splash artwork should be replaced with real branding,
startup performance and tablet/landscape layouts need verification on
physical hardware, store assets are not started, and iOS platform support
is deferred to a future milestone. The release APK/AAB have not been
rebuilt since BUG-002 — do that before considering the release artifacts
current again.
