# Changelog

All notable changes to this project are documented here. Versions follow
[Semantic Versioning](https://semver.org/).

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
- **Writing engine** — stroke-by-stroke practice canvas with stroke-order
  guides, an optional reference grid, and automated accuracy scoring.
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
