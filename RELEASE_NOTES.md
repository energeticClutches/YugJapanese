# YugJapanese v1.0.0

Prepared release notes for the `v1.0.0` GitHub Release. The Release
workflow (`.github/workflows/release.yml`) auto-generates notes from
commit history when the tag is pushed; paste this curated version in
over that draft when publishing, for a clearer user-facing summary.

---

YugJapanese is an offline-first Flutter app for learning to read and
write Japanese — Hiragana, Katakana, and Kanji — with guided lessons,
spaced-repetition review, six practice/quiz modes, achievements, and a
learning-analytics dashboard. No account, no cloud, no network access
required: everything runs and is stored entirely on your device.

## Core features

- **Guided lessons** for all 46 Hiragana, all 46 Katakana, and 79 JLPT N5
  Kanji characters, each with stroke-order guidance, a mnemonic hint, and
  handwriting evaluation against real stroke geometry.
- **Spaced-repetition review**, with a scheduler that shortens or
  lengthens the next interval based on how well you actually recalled
  each item, prioritizing the most fragile material first.
- **Practice/Quiz engine** — six modes (Recognition, Meaning, Reading,
  Listening, Mixed, and Weak Items) sharing one scoring engine, with
  per-mode best-score tracking.
- **Achievements & streaks**, computed automatically from your existing
  progress and review activity.
- **Analytics dashboard** — per-script completion, accuracy trends, an
  activity calendar, weak-area detection tied into the Weak Items quiz
  mode, and CSV/JSON export.
- **Offline audio and universal search** across every character by
  glyph, romaji, meaning, or reading.

## Offline-first architecture

Every lesson, stroke path, and font this app needs is bundled inside the
app package itself — there are no servers, no accounts, and the app
makes zero network requests of any kind. All progress, reviews, quiz
results, and settings are stored locally in an on-device database and
never leave your device. See `PRIVACY_POLICY.md` for the full policy.

## Writing recognition

Handwriting accuracy is scored by comparing your drawn strokes against
real reference stroke geometry (derived from the KanjiVG project), not
just stroke count or a bounding box — a scribble with the right number
of strokes no longer scores well. Scoring accounts for shape, stroke
order, stroke direction, and how complete the drawing is, so an
incomplete or backwards-drawn attempt is scored down proportionally
rather than passed or failed outright.

## Review & spaced-repetition enhancements

The review scheduler responds to your actual performance: a weak review
steps back rather than advancing, a strong one earns a longer interval,
and due reviews are ordered by urgency (overdue-ness, ease, and past
lapses) rather than by due date alone — so the material you're shakiest
on comes up first.

## CI/CD infrastructure

Every push and pull request runs through GitHub Actions: formatting,
static analysis, the full test suite, and release APK/AAB builds, with
test coverage reported on every run. Dependency freshness is tracked
automatically via Dependabot. This same release was built and validated
through that pipeline before being tagged.

## Known limitations

- Release builds are signed with a debug key (no production upload
  keystore yet) — this build is not intended for Play Store submission.
- Pronunciation audio is bundled for 5 Hiragana vowels only; the
  remaining characters have no audio yet and simply hide the play
  button.
- Progress import/export is not yet implemented (analytics CSV/JSON
  export does work).
- Tested on an Android phone emulator profile; tablet and physical-device
  layouts have not been separately verified.
- Android only — there is no iOS build.

See `CHANGELOG.md` for the full list of fixes and improvements in this
release, and `RELEASE_CHECKLIST.md` for what remains before a public
Play Store submission.

## Requirements

- Android 7.0 (API 24) or newer.

## Installation

Download `app-release.apk` from this release's assets and install it
directly on an Android device:

1. On the device, allow installs from the source you're using (browser
   or file manager) if prompted — this is a one-time Android setting for
   installing an APK outside the Play Store.
2. Open the downloaded `app-release.apk` and confirm the install.
3. Launch **YugJapanese** — no setup, account, or network connection is
   needed.

(`app-release.aab` is also attached — that format is for Play Store
submission tooling, not direct installation.)
