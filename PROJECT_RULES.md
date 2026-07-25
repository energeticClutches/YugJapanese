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

### Screen-level content resolution

Generic identifiers (e.g. `"contentId:lessonNumber"`) are resolved back to
a display title only at the screen/widget layer, by checking
`contentId == 'hiragana'` and calling `HiraganaRepository()` directly —
never inside a repository, service, or scheduler. Services and schedulers
must stay content-agnostic even though only Hiragana has content today, so
Katakana/Kanji need no architectural changes later, only new resolution
branches at existing call sites (search for `contentId == 'hiragana'`).

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
