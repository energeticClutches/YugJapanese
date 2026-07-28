# Changelog

All notable changes to this project are documented here. Versions follow
[Semantic Versioning](https://semver.org/).

## [Unreleased]

No changes yet.

## [1.0.0] — 2026-07-28

First production release. Feature-complete and fully offline, verified
end-to-end against a real release build (Milestone 26 RC1 audit).
`pubspec.yaml` carried `version: 1.0.0+1` since Milestone 20, but this is
the first version actually tagged and published — everything below,
including all post-M20 stabilization work, ships in this release.

### Added

- Production application ID `com.energeticclutches.yugjapanese`, replacing
  the Flutter placeholder package name.
- Placeholder launcher icon and splash screen (torii-gate motif in the
  app's theme colors), generated for all Android densities via
  `flutter_launcher_icons` and `flutter_native_splash`.
- In-app Privacy Policy, Terms of Use, and Credits & Attribution screens,
  reachable from **Settings → Legal**, rendered from the repository's own
  Markdown files so the bundled and repository copies cannot drift apart.
- App display name set to "YugJapanese"; About dialog reports v1.0.0 and
  the MIT license.
- CI/CD: a GitHub Actions workflow running format/analyze/test/build on
  every push and pull request, a separate tag-triggered Release workflow
  that validates the version and publishes a GitHub Release with the
  built APK/AAB attached, Dependabot for `pub` and `github-actions`
  dependencies, and `flutter test --coverage` reporting in CI
  (informational, not gated).

### Feature history (Milestones 1–19)

- **Learning content** — Hiragana, Katakana, and Kanji lessons with
  per-character detail, readings, meanings, and extended Kanji metadata.
- **Writing engine** — finger-drawn practice canvas with an animated
  stroke-order guide, an optional reference grid, and accuracy scoring
  against the actual drawn strokes.
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
  and a unit/widget/flow test suite (grown to 94 tests by this release).

### Fixed (stabilization work between Milestone 20 and this release)

- **BUG-002 (critical):** the writing canvas did not exist — the
  stroke-order, tracing, and free-writing lesson steps all rendered the
  same character-info card with no drawable surface, and the accuracy
  score shown after "writing" was computed from fabricated synthetic
  strokes rather than anything the user actually drew. Built a real
  finger-drawn canvas, a stroke-order animation, and a tracing guide,
  backed by new stroke-path data derived from KanjiVG (CC BY-SA 3.0 — see
  `CREDITS.md`) covering all 171 characters this app teaches.
- **BUG-001 (critical):** the Android back button exited the app instead
  of navigating up the in-app screen stack, because nearly every
  navigation call used `go()` (replaces the whole stack) instead of
  `push()`. Reclassified every navigation call by intent.
- **BUG-003:** the Hiragana lesson list only ever showed Lesson 1;
  Katakana/Kanji already looped over all lessons. Fixed, plus a
  `completionPercentage` argument bug uncovered by the same code path.
- **BUG-004:** dark mode rendered near-black text on dark surfaces across
  33 files, because `AppTypography`'s and `AppColors`' static shortcuts
  never consulted the (already-correct) dark theme/palette.
- **BUG-006:** the writing evaluator scored scribbles as ~100% accurate —
  it never compared the drawing against the character's actual reference
  geometry. Rebuilt scoring around shape comparison against KanjiVG
  stroke data, with stroke count, order, direction, and proportion as
  modulating factors rather than the whole score.
- **BUG-007:** the lesson-completion screen showed a permanent loading
  spinner when reached via "Next Character" or "Next" from free writing
  (only the explicit "Check my writing" button used to grade the
  attempt). Fixed by grading on arrival at the result step.
- **BUG-008:** finishing a lesson had no next-lesson action at all —
  learners were dropped back to the lesson list with no way to continue.
  Added a completion dialog with Next Lesson / Back to Lessons.
- **BUG-009:** the lesson card showed a meaningless
  `isCompleted ? 100 : 0` value labeled as a percentage next to an
  unrelated accuracy-derived status label. Replaced with a single,
  correctly-sourced "Writing accuracy: N%" line shown only when complete.
- **BUG-010:** retrying a quiz or using "Review Mistakes" stacked a new
  `/quiz/results` route on top of the old one instead of replacing it,
  so "Return Home" appeared to do nothing until tapped enough times to
  unwind every stacked copy.
- Katakana サ was declared as 2 strokes in the lesson data; it is
  genuinely 3 (caught by cross-checking against KanjiVG).
- Hiragana content gap: only the 5 vowels had lesson data at Milestone 20;
  added the other 41 gojūon characters as Lessons 2–10.
- **Milestone 21 (UX polish):** deduplicated Export/Import "coming soon"
  notification spam, fixed uneven dashboard statistic-card grid widths,
  unified section-heading typography (Settings/Search were one size
  smaller than everywhere else), decluttered the lesson-screen header,
  and corrected the tracing step's button label ("Continue to Free
  Writing" — it was never actually grading tracing at that point).
- **Milestone 22 (writing engine correctness):** a canvas with only
  filtered-out noise (taps/flecks) fell back to scoring the unfiltered
  input instead of zero; a partial attempt was never scored down for how
  little of the character was actually drawn; tracing accepted literally
  any input since it was never scored at all; and a P0 state-leak bug let
  traced guide ink carry into the free-writing canvas when a step was
  skipped via the generic Next button instead of the submit button.
- **Milestone 23 (review/quiz navigation):** a dead `clearSession()`
  method meant a finished quiz session was still "current" the next time
  any mode was opened, causing every mode card to bounce straight to the
  previous quiz's results; fixed the underlying race rather than the
  routing. Also fixed the Review list showing a bare glyph as a lesson
  title instead of its script/lesson name, added due/overdue subtitles
  and a count header, fixed a permanent-spinner path on a failed lesson
  lookup, and removed a redundant "Return Home" button (adding the
  missing `AppBar` its removal exposed the screen never had).
- **Milestone 24:** the analytics activity calendar used a plain
  flow-wrap layout, so which day started a new "row" shifted with screen
  width and never aligned to real weekdays. Rewritten as an actual
  week-grid (columns = weeks, rows = weekdays) with today's cell
  highlighted.
- **Milestone 26 / 26.1:** RC1 audit found `google_fonts` fetching
  `NotoSansJP` from `fonts.gstatic.com` at runtime, contradicting this
  app's own "no network requests" privacy claim. Fixed by bundling
  `NotoSansJP-Variable.ttf` as a local asset and removing `google_fonts`
  from the dependency tree entirely. See `RC1_VERIFICATION_REPORT.md`.

### Enhanced

- **Spaced repetition:** reviews now advance or step back based on the
  learner's actual score (previously every review was recorded as
  successful regardless of performance); added a live `easeFactor` that
  shortens or lengthens the next interval, and due reviews are now
  ordered by a priority combining overdue-ness, ease, and lapse count
  instead of due date alone.
- **Stroke direction scoring:** backwards-stroke detection now requires a
  clear margin instead of flagging on floating-point noise, and the
  penalty scales with how many strokes were reversed instead of a flat
  15% ceiling.
- **Mnemonics:** every one of the 171 taught characters now has a
  shape- or sound-based hint shown during the introduction step.
- **Pacing:** lesson accuracy is now averaged across every character in
  the attempt (previously only the final character's score was kept),
  and lessons finished shakily are labeled "Completed - Practice Again"
  and re-enter spaced repetition sooner.

### Known limitations

- **Review scheduling has no failure signal in the Analytics trend**: the
  scheduler itself does distinguish pass/fail (see Enhanced above), but
  the "Review success rate" trend on the Analytics screen only counts
  recorded reviews, all of which reach the scheduler as attempted — an
  honest reflection of what's tracked today, not fabricated data.
- **Per-script quiz accuracy is approximate**: a quiz session's accuracy
  is recorded per-session, not per-script.
- **"Estimated Study Minutes" is a heuristic**, not measured time.
- Only Hiragana's 5 vowel characters have real (synthesized-tone,
  clearly-labeled) pronunciation audio; Katakana and Kanji have none yet.
- No physical-device or tablet testing has been performed; layouts are
  reasoned about via the shared 960dp content cap, not verified on real
  tablet hardware.
- Progress import/export from Settings is stubbed; analytics CSV/JSON
  export does work. "Larger writing area" in Accessibility is not yet
  implemented.
- Release builds are signed with the debug key. See
  `RELEASE_CHECKLIST.md` — a production upload keystore must be created
  before any Play Store submission.
- Android only. No `ios/` platform target exists yet.
