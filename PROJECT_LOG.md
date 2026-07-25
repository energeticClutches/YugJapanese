# Project Log

## Project

Offline-first Flutter application for learning Japanese writing on Android
phones and tablets. The learning order is Hiragana, Katakana, then Kanji.

## Current State (read this first in a new session)

- **Last completed milestone: 11 (Achievements & Streak System).** Fully
  implemented, `flutter analyze` clean, verified end-to-end on an Android
  emulator (API 37, `emulator-5554`). No open work, no known bugs.
- **Content:** only Hiragana Lesson 1 (vowels あいうえお) exists. Katakana and
  Kanji screens are still "Coming Soon" placeholders; their `ContentSource`
  entries are not yet added to `contentSourcesProvider`
  (`lib/features/dashboard/providers/dashboard_providers.dart`) because they
  have no `LessonRepository` implementation yet.
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
    duplicating a Hiragana-only list.
  - `review` (M10) — spaced repetition, Hive box `review_schedule`, fixed
    interval scheduler (not SM-2 yet).
  - `achievements` (M11) — Hive box `achievement_progress`, streak +
    achievement unlocking computed entirely from existing progress/review
    data; touches nothing in `practice`/`writing`/`hiragana`.
- **Established reactivity convention** (used by every feature since M9):
  a `FutureProvider` that needs to "refresh when X changes" calls
  `ref.watch(xProvider)` purely for its invalidation signal (ignoring the
  returned value) rather than adding explicit `ref.invalidate()` calls
  scattered through UI code. `progressControllerProvider` (a
  `ChangeNotifierProvider`) and `dueReviewsProvider` are the two shared
  triggers other features watch. `learning_screen.dart` still calls
  `ref.invalidate(dueReviewsProvider)` once after scheduling a review (that
  predates this convention and works fine); no other screen needs to.
- **Screen-level content resolution pattern**: several screens (dashboard's
  Continue Learning card, `ReviewScreen`, achievements are not affected)
  turn a generic `"contentId:lessonNumber"` string back into a display title
  by checking `contentId == 'hiragana'` and calling `HiraganaRepository()`
  directly. This is a deliberate, repeated exception to strict genericity —
  acceptable because only Hiragana has content today. When Katakana/Kanji
  repositories are added, search for `contentId == 'hiragana'` across
  `lib/features/` and extend each site.
- Do not start Milestone 12 or any new feature without explicit instruction.

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

## Current Milestone: Persistent Progress

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

## Verification Status

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

## Runtime Verification

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
  `contentSourcesProvider` (currently wires only Hiragana), and
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

## Next Required Action

None. All 11 milestones to date are complete, `flutter analyze` is clean,
and the full app (dashboard, Hiragana lesson, review mode, achievements) is
verified working end-to-end on device. Do not start Milestone 12 or any new
feature (the suggested next one mentioned in prior instructions was a more
advanced SM-2 spaced-repetition algorithm, or expanding Katakana/Kanji
content) until the user explicitly requests it and defines its scope.
