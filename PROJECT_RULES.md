# PROJECT_RULES.md

## Purpose

This project is an offline-first Flutter application for learning how to write Japanese.

Target order:

1. Hiragana
2. Katakana
3. Kanji

The primary target is Android tablets and touch-screen phones.

---

## Technology Stack

- Flutter
- Dart
- Riverpod
- go_router
- Hive
- Material 3
- Google Fonts
- audioplayers

Do not replace these technologies unless explicitly instructed.

---

## General Rules

- Make the smallest change necessary.
- Preserve existing architecture.
- Avoid unnecessary refactoring.
- Do not rename files, folders, classes, or public APIs unless required.
- Keep code readable and maintainable.
- Follow Dart formatting conventions.

---

## Architecture Rules

- UI must not contain business logic.
- Repositories handle data access.
- Controllers manage state.
- Models represent data only.
- Widgets should remain reusable where practical.

### Feature folder shape

Every feature under `lib/features/<name>/` follows the same subfolders as
needed: `models/`, `repositories/`, `providers/`, `services/`, `screens/`,
`widgets/`. Models are plain Dart (no Flutter imports) with `toMap()` /
`fromMap()` for Hive persistence, matching `LessonProgress`, `ReviewItem`,
`Achievement`. Follow this shape for any new feature.

### Reactivity convention (Riverpod)

A `FutureProvider` that must refresh when unrelated data changes elsewhere
should `ref.watch()` the relevant existing provider purely as an
invalidation signal (ignoring the returned value), rather than adding new
`ref.invalidate()` calls into UI/screen code. `progressControllerProvider`
(a `ChangeNotifierProvider`) and `dueReviewsProvider` are the shared
triggers other features already watch this way. Prefer this over threading
new invalidation calls through the learning flow — it is what lets features
like achievements/streaks be built with zero changes to
`practice/`/`writing/`/`hiragana/`.

### Stateful feature controller pattern

A feature that needs live UI updates after a mutation (settings, audio
playback state, favorites, search history, progress) exposes a
`ChangeNotifier` controller/service via `ChangeNotifierProvider` —
`ProgressController`, `SettingsController`, `AudioService`,
`FavoritesController`, `SearchHistoryController` all follow this shape.
Screens `ref.watch()` the provider and rebuild automatically. Do not
introduce `StateNotifier` or Riverpod codegen for this — stay consistent
with the one pattern already used everywhere.

### Content repository factory

`lib/repositories/content_repository_factory.dart` maps a `contentId`
string (`'hiragana'`, `'katakana'`, `'kanji'`, ...) to its `LessonRepository`
via `ContentRepositoryFactory.repositoryFor` /
`ContentRepositoryFactory.tryRepositoryFor`. This is the **only** place
that should branch on contentId strings to decide which repository to use.
`contentSourcesProvider` (dashboard) is generated from
`availableContentIds`, so registering a new script here is what makes it
appear everywhere else (dashboard, search, statistics, achievements)
automatically. Do not add a new `if (contentId == '...')` branch anywhere
else in the codebase for this purpose — extend the factory's map instead.

### Screen-level content resolution

Generic identifiers (e.g. `"contentId:lessonNumber"`) are resolved back to
a display title only at the screen/widget layer — dashboard's Continue
Learning card, `ReviewScreen`, `SearchScreen`'s suggestions — never inside
a repository, service, or scheduler. This resolution goes through
`ContentRepositoryFactory.tryRepositoryFor(contentId)` (generic across
every registered script), not a hardcoded `contentId == 'hiragana'` check.
Each screen currently duplicates a small (~15-line) resolver function
rather than sharing one; that duplication is intentional and acceptable at
this scale — do not extract it into a shared service.

### Per-script repository shape

Each script's `LessonRepository` implementation (`HiraganaRepository`,
`KatakanaRepository`, `KanjiRepository`) is a small, independent class that
loads its own `assets/data/<script>_lessons.json` via
`JsonLoaderService.loadLessons(assetPath)` and maps `CharacterModel` to
`LearningItem` itself. They are deliberately **not** merged into a shared
base/generic class — three near-identical ~40-line repositories was judged
lower-risk than refactoring already-working files, since the actual
reusable logic (JSON parsing) is already centralized in
`JsonLoaderService`. Follow this same shape for a new script rather than
introducing a generic repository base class.

**Two separate places build `LearningItem` from `CharacterModel`** — each
repository's own mapping (used only by `getItem(id)` lookups) and
`LearningController.startLesson` (used by the live learning session, via
its own loop, not the repository). Any field added to `CharacterModel`
must be threaded through **both** or it will silently be dropped from the
active learning session while still working in isolated `getItem` calls —
this exact bug happened during Kanji's Milestone 14 (see `PROJECT_LOG.md`).

### Hive boxes

All opened in `main.dart` at startup, one per feature: `lesson_progress`,
`review_schedule`, `achievement_progress`, `app_settings`, `favorites`,
`search_history`, `practice_results`, `analytics_snapshot`. Add a new box
in `main.dart` (via the repository's public `boxName` constant, matching
`HiveSettingsRepository.boxName` etc.) rather than reusing an existing box
for unrelated data. Boxes are opened via `_openBoxSafely` (M19), which
recovers from a corrupted box file by deleting and reopening it empty
rather than crashing at launch; repository reads use `safeParse`
(`lib/core/utils/safe_parse.dart`) so a single malformed record is skipped
instead of throwing.

### Audio asset honesty

Do not add placeholder/synthetic audio and let it pass as real
pronunciation. If real recordings aren't available, either leave the
`audioAsset` path pointing at a file that doesn't exist yet (the audio
system already handles this gracefully — disabled button, no crash) or, if
a placeholder is genuinely needed to test the playback pipeline, make it
something that obviously isn't speech (e.g. the synthesized sine tones
used for the 5 Hiragana vowels in Milestone 15) and say so explicitly in
`PROJECT_LOG.md` and to the user. Never generate fake speech-like audio.

---

## Dependencies

Do not:

- add new packages
- remove packages
- update package versions

unless explicitly requested.

---

## Scope

Only modify files required for the requested task.

Treat all other files as read-only unless the change cannot be completed otherwise.

---

## Before Finishing

Ensure:

- `flutter analyze` has no errors.
- Existing functionality continues to work.
- No unrelated files are modified.

---

## Response Format

At the end of every task provide:

### Files Modified

- file1
- file2

### Summary

Short explanation of the changes.

### Suggested Commit Message

One concise Git commit message.

---

## Stop Conditions

Stop immediately after:

- completing the requested task,
- satisfying the acceptance criteria,
- and ensuring no unrelated changes were made.

Do not continue with additional improvements or optional refactoring.
