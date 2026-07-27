# Changelog

All notable changes to this project are documented here. Versions follow
[Semantic Versioning](https://semver.org/).

## [Unreleased] — post-1.0.0 fixes

### Fixed

- **BUG-002 (critical):** the writing canvas did not exist — the
  stroke-order, tracing, and free-writing lesson steps all rendered the
  same character-info card with no drawable surface, and the accuracy
  score shown after "writing" was computed from fabricated synthetic
  strokes rather than anything the user actually drew. Built a real
  finger-drawn canvas, a stroke-order animation, and a tracing guide,
  backed by new stroke-path data derived from KanjiVG (CC BY-SA 3.0 —
  see `CREDITS.md`) covering all 171 characters this app teaches. The
  Show Stroke Guides / Show Writing Grid / Animation Speed settings are
  now genuinely wired to the canvas instead of doing nothing. Also fixed
  a gesture-arena conflict found during testing: the canvas sits inside a
  scrolling page, and near-vertical strokes (most Japanese strokes) were
  being silently swallowed by the page's scroll gesture instead of being
  drawn.
- **Hiragana content gap:** only the 5 vowels had lesson data; the other
  41 gojuon characters were simply missing. Added as Lessons 2–10,
  mirroring Katakana's row grouping, with stroke counts sourced from
  KanjiVG rather than typed by hand.
- **BUG-001 (critical):** the Android back button exited the app instead
  of navigating up the in-app screen stack, because nearly every
  navigation call used `go()` (replaces the whole stack) instead of
  `push()`. Reclassified every navigation call by intent — drill-down
  navigation now pushes, "return from a finished flow" now pops.
- Katakana サ was declared as 2 strokes in the lesson data; it is
  genuinely 3 (caught by cross-checking against KanjiVG during the
  BUG-002 stroke-data conversion).

## [1.0.0] — 2026-07-26

First production release. The app is feature-complete and fully offline.

### Added — this release (Milestone 20)

- Production application ID `com.energeticclutches.yugjapanese`, replacing
  the Flutter placeholder package name.
- Placeholder launcher icon and splash screen (torii-gate motif in the
  app's theme colors), generated for all Android densities via
  `flutter_launcher_icons` and `flutter_native_splash`.
- In-app Privacy Policy, Terms of Use, and Credits & Attribution screens,
  reachable from **Settings → Legal**, rendered from the repository's own
  Markdown files so the bundled and repository copies cannot drift apart.
- `CHANGELOG.md` and `RELEASE_CHECKLIST.md`.
- App display name set to "YugJapanese"; About dialog now reports v1.0.0
  and the MIT license.

### Feature history (Milestones 1–19)

- **Learning content** — Hiragana, Katakana, and Kanji lessons with
  per-character detail, readings, meanings, and extended Kanji metadata.
- **Writing engine** — finger-drawn practice canvas with an animated
  stroke-order guide, an optional reference grid, and accuracy scoring
  against the actual drawn strokes (see the BUG-002 fix above — this
  didn't work correctly until then).
- **Spaced review** — a scheduler that promotes or demotes items based on
  recall performance, with a dedicated review session flow.
- **Practice / quiz engine** — six modes (Recognition, Meaning, Reading,
  Listening, Mixed, and Weak Items) with configurable session length and
  per-mode best-score tracking.
- **Analytics** — overall completion, per-script breakdowns, streaks,
  study-time estimates, activity heatmap, weak-area detection, and
  CSV/JSON export.
- **Dashboard** — aggregated progress, streaks, recent achievements, and
  quick entry points into every feature.
- **Achievements** — unlockable milestones with progress tracking.
- **Universal search** — searches every script by character, romaji,
  meaning, or reading, with favorites and search history.
- **Audio** — offline pronunciation playback that degrades gracefully when
  a recording is not yet bundled.
- **Settings** — theme, learning, feedback, accessibility, and data
  management options, plus storage-usage and license diagnostics.
- **Polish (M19)** — shared loading/empty/error state widgets, defensive
  Hive parsing with corrupted-box recovery, accessibility labels, text
  scaling clamped to 1.6x, responsive card layouts, targeted animations,
  and a 36-test unit/widget/flow suite.

### Known limitations

- Pronunciation audio is currently recorded for 5 Hiragana characters
  (`a`, `i`, `u`, `e`, `o`). The remaining 107 audio paths referenced by
  the lesson data resolve to no audio and simply hide the play button —
  this is by design, not an error.
- Import/export of progress from the Settings screen is stubbed
  ("not available yet"); analytics export (CSV/JSON) does work.
- "Larger writing area" in Accessibility settings is not yet implemented.
- Release builds are signed with the debug key. See
  `RELEASE_CHECKLIST.md` — a production upload keystore must be created
  before any Play Store submission.
- Android only. No `ios/` platform target exists yet.
