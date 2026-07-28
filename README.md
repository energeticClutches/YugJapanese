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
[CHANGELOG.md](CHANGELOG.md), [RELEASE_NOTES.md](RELEASE_NOTES.md),
[PRIVACY_POLICY.md](PRIVACY_POLICY.md), [TERMS_OF_USE.md](TERMS_OF_USE.md),
[CREDITS.md](CREDITS.md).

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
dart format --output=none --set-exit-if-changed .   # formatting check
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

## Continuous Integration

Every push and every pull request runs the [Flutter CI workflow](.github/workflows/flutter_ci.yml)
on `ubuntu-latest`: install the pinned Flutter SDK (`3.44.8`, matching this
project) and JDK 17, `flutter pub get`, a `dart format --set-exit-if-changed`
check, `flutter analyze`, the full `flutter test` suite, then a release
`flutter build apk` and `flutter build appbundle` — in that order, so the
workflow stops at the first stage that fails and the failing step name in
the Actions log tells you which one. Release builds sign with the debug
key already checked into `android/app/build.gradle` (see
[RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md)), so no signing secrets are
needed in CI. Flutter SDK, pub packages, and Gradle caches are all cached
between runs to keep builds fast. This is still validation-only — no
upload to Play Store, Firebase App Distribution, or any deployment step
runs in CI; that's a later phase.

The JDK/Flutter install and cache-restore steps live in a shared composite
action, [`.github/actions/setup-flutter-build`](.github/actions/setup-flutter-build/action.yml),
also used by the Release workflow below — one definition of the build
environment instead of two copies to keep in sync.

**Downloading a CI build:** open the workflow run for the commit you want
(GitHub → **Actions** tab → *Flutter CI* → the run) and scroll to its
**Artifacts** section at the bottom of the summary page. Three artifacts
are attached to every successful run:

- `flutter-release-apk` — the release APK (`app-release.apk`), installable
  directly on a device with `adb install`.
- `flutter-release-aab` — the release App Bundle (`app-release.aab`), the
  format Play Store submissions use.
- `coverage-report` — `lcov.info` from that run's test suite; see "Code
  coverage" below.

Artifacts follow GitHub's default retention window and are only produced
when the build stage succeeds — a failed run has no artifacts to
download.

## Code coverage

Every CI run executes `flutter test --coverage`, which runs the full
suite exactly as before and additionally writes `coverage/lcov.info` (lcov
format) alongside it. The workflow verifies that file actually exists
before uploading it as the `coverage-report` artifact (see above) —
`if-no-files-found: error` on the upload step means a run that somehow
produced no coverage data fails loudly instead of silently skipping the
artifact.

**Current baseline: ~53% line coverage** (1,290 of 2,452 lines, measured
locally when this phase was added — re-run the command below for the
current number, since it moves as tests and code are added). Coverage is
**informational only right now, not a gate**: nothing in CI fails, and no
PR is blocked, based on the percentage. Deliberately so — with a young
test suite, a hard threshold this early would either be trivially low
(useless) or would create pressure to write low-value tests just to hit
a number. The plan is to let real coverage data accumulate across several
weeks of normal development first, then set a threshold based on where
coverage actually stabilizes rather than guessing at one now.

**Inspecting coverage locally:**

```bash
flutter test --coverage
# writes coverage/lcov.info
```

To view it as an interactive HTML report (needs `lcov`'s `genhtml`,
installed via `apt install lcov`, `brew install lcov`, or
`choco install lcov` on Windows):

```bash
genhtml coverage/lcov.info -o coverage/html
# then open coverage/html/index.html in a browser
```

Alternatively, most editors can render `lcov.info` inline over the
source — e.g. VS Code's "Coverage Gutters" extension watches for
`coverage/lcov.info` and annotates covered/uncovered lines directly in
the gutter, no `genhtml` step needed. `coverage/` is already
git-ignored, so none of this output gets committed.

**Codecov integration was investigated and intentionally not wired up
yet** — adding it means sending this project's code-coverage data to a
third-party service, which is a deliberate choice to make with an actual
Codecov account in hand, not something to enable silently as a side
effect of a CI update. Rather than add an incomplete/untested step, here
is what turning it on later involves:

1. Sign in to [codecov.io](https://codecov.io) with the GitHub account
   that owns this repo and enable the `YugJapanese` repository.
2. If the repo is private (or to avoid tokenless upload's rate limits
   even on a public repo), copy the repository upload token Codecov
   generates and add it as a GitHub Actions secret named
   `CODECOV_TOKEN` (**Settings → Secrets and variables → Actions** — a
   repository-settings change, so it has to be done by hand, the same as
   the branch-protection settings above).
3. Add one step to `flutter_ci.yml`, directly after "Verify coverage
   report was generated":

   ```yaml
   - name: Upload coverage to Codecov
     uses: codecov/codecov-action@v4
     with:
       files: coverage/lcov.info
       fail_ci_if_error: false
       token: ${{ secrets.CODECOV_TOKEN }}
   ```

   `fail_ci_if_error: false` keeps this non-blocking by design — a
   Codecov outage or upload hiccup should never fail an otherwise-green
   build, and no `codecov.yml` threshold config should be added until
   Phase 5's informational baseline has matured into an actual gate.

## Release process

Pushing a Git tag matching `v*` (e.g. `v1.0.0`) triggers the separate
[Release workflow](.github/workflows/release.yml) — it never runs on a
normal push or pull request, only on that tag pattern. It does not re-run
formatting/analysis/tests (the tagged commit is expected to have already
passed CI on its branch); it validates the version, builds, and publishes:

1. **Validate version** — reads `version:` from `pubspec.yaml`, and fails
   the workflow if: the field is missing, it isn't valid
   `<major>.<minor>.<patch>+<build number>` semantic versioning (e.g.
   `1.0.0+1`), or the numeric part doesn't match the pushed tag (tag
   `v1.0.0` requires `pubspec.yaml` to say `1.0.0+<anything>`). Version
   numbers are never modified automatically — bump `pubspec.yaml` and
   commit it yourself before tagging.
2. **Build** — the same `flutter build apk --release` and
   `flutter build appbundle --release` used in CI, via the same shared
   `setup-flutter-build` action (same pinned Flutter/JDK versions, same
   debug-signed release config).
3. **Publish** — creates (or updates, if re-run on the same tag) a
   production GitHub Release titled `Version <version>` with
   auto-generated release notes, and attaches `app-release.apk` and
   `app-release.aab` as downloadable assets. The workflow fails if either
   asset can't be uploaded.

To cut a release:

```bash
# 1. Bump pubspec.yaml's version (e.g. 1.0.0+1 -> 1.0.1+2) and commit it.
# 2. Tag that commit and push the tag:
git tag v1.0.1
git push origin v1.0.1
```

## Recommended repository settings (not yet applied)

The settings below are **recommendations only** — they require the
GitHub web UI (**Settings → Branches** / **Rulesets**) and are not, and
cannot be, applied by a workflow file or by Claude. Documenting them here
so they're a deliberate decision when someone with admin access wants to
turn them on, not an unreviewed default.

**Branch naming** this repository is set up to expect: `main` (protected,
production), `develop` (optional integration branch, same protections
minus "require PRs" if solo development doesn't need it), and
short-lived `feature/*`, `bugfix/*`, `hotfix/*` branches merged via PR
and deleted after merge.

**Recommended protection rule for `main`** (Settings → Branches → Add
branch protection rule, or the newer Rulesets UI):

- Require a pull request before merging (require at least 1 approval if
  this becomes a multi-contributor repo).
- Require status checks to pass before merging — select the `Flutter CI`
  workflow's `Format, analyze, test, and build` job specifically, so a
  broken build/test/format/analyze can't merge.
- Require branches to be up to date before merging, so a PR is tested
  against the code it will actually merge into, not a stale base.
- Do not allow bypassing the above settings (applies rules to admins too,
  not just other contributors).
- Restrict force pushes to `main`.
- Restrict deletions of `main`.
- Require linear history, if the project commits to a single merge
  strategy (squash or rebase merges only) — optional, a style preference
  rather than a safety requirement.

The same rule (minus "require linear history", which is more of a `main`
convention) is reasonable to mirror on `develop` if that branch is
adopted. `feature/*`/`bugfix/*`/`hotfix/*` branches are intentionally
left unprotected — they're disposable working branches merged via PR into
one of the two above.

## Dependency management (Dependabot)

[Dependabot](https://docs.github.com/en/code-security/dependabot) is
GitHub's built-in bot for dependency freshness and security: it watches
this repo's manifests, and when a newer (or, more urgently, a
vulnerable) version of something is available, it opens a Pull Request
that bumps just that dependency — instead of updates being tracked
manually or drifting unnoticed. Configured in
[`.github/dependabot.yml`](.github/dependabot.yml) for the two
ecosystems this repo actually has:

- **`pub`** (Flutter/Dart) — watches `pubspec.yaml`/`pubspec.lock`.
- **`github-actions`** — watches the actions referenced in
  `.github/workflows/` (`actions/checkout`, `actions/cache`,
  `actions/setup-java`, `subosito/flutter-action`,
  `softprops/action-gh-release`, etc.).

No other ecosystem is configured — there's no `ios/`, `package.json`,
`Gemfile`, or similar in this repo for Dependabot to watch.

**Schedule:** both ecosystems check weekly (Monday, 06:00 UTC), not
daily — enough to stay current without turning every morning into a PR
queue. Security-vulnerability updates aren't bound by this schedule:
GitHub opens those as soon as a vulnerability affecting a dependency
actually in use is published, independent of the weekly cadence (this
requires "Dependabot security updates" to be turned on under **Settings
→ Security** — a repository setting, not something a config file can
enable; see the branch-protection section above for the same caveat).

**Grouping:** minor/patch bumps within each ecosystem are grouped into a
single PR (`flutter-minor-and-patch`, `github-actions-minor-and-patch`)
so routine updates don't produce one PR per package. Major-version bumps
are deliberately left out of the group and always get their own PR, so
a breaking upgrade doesn't quietly ride along with routine ones and stays
easy to find in review.

**Version constraints are never rewritten automatically.** Most direct
dependencies in `pubspec.yaml` are declared as `any` (no upper bound), so
Dependabot's default versioning strategy only needs to update
`pubspec.lock`'s resolved versions — the manifest constraints you wrote
stay exactly as they are unless a dependency genuinely can't be
satisfied any other way.

**Reviewing a Dependabot PR:** it runs through [the same CI
workflow](.github/workflows/flutter_ci.yml) as any human-authored PR —
formatting, static analysis, the full test suite, and a release APK/AAB
build — no special-casing needed, since `flutter_ci.yml` triggers on
every pull request regardless of author. Treat a Dependabot PR like any
other: read the changelog/diff it links, confirm CI is green, and merge
manually. There's no reviewer/assignee auto-added — that's still a human
decision here.

**Why auto-merge is intentionally off:** nothing in this repo merges a
Dependabot PR automatically — that would require a *separate* GitHub
Actions workflow reacting to Dependabot PRs (e.g. auto-approving and
enabling auto-merge), which this phase deliberately does not add, per
its own constraints. Even a passing CI run only proves the app still
builds and the existing tests still pass — it doesn't guarantee a
dependency's behavior didn't change in some way the test suite doesn't
cover, so a human still looks at every one before it merges.

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
