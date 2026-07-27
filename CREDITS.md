# Credits & Attribution

YugJapanese is built with the following open-source software:

## Framework & state management

- [Flutter](https://flutter.dev) — application framework (BSD-3-Clause)
- [flutter_riverpod](https://pub.dev/packages/flutter_riverpod) — state
  management (MIT)
- [go_router](https://pub.dev/packages/go_router) — navigation (BSD-3-Clause)

## Storage

- [hive](https://pub.dev/packages/hive) /
  [hive_flutter](https://pub.dev/packages/hive_flutter) — local database
  (Apache-2.0)
- [path_provider](https://pub.dev/packages/path_provider) — filesystem
  paths (BSD-3-Clause)
- [shared_preferences](https://pub.dev/packages/shared_preferences) —
  key-value storage (BSD-3-Clause)

## Typography & graphics

- [google_fonts](https://pub.dev/packages/google_fonts) — bundles the
  Noto Sans JP typeface (SIL Open Font License) used throughout the app
  for Japanese text rendering.
- [flutter_svg](https://pub.dev/packages/flutter_svg) — vector graphics
  rendering (MIT)

## Stroke order data

- **[KanjiVG](https://kanjivg.tagaini.net/)** by Ulrich Apel, licensed
  under [Creative Commons Attribution-Share Alike 3.0](https://creativecommons.org/licenses/by-sa/3.0/).
  `assets/data/stroke_data.json` is a derivative work: the per-stroke SVG
  paths for the 130 characters this app teaches were extracted, flattened
  from cubic Béziers into polylines, and normalized to a 0–1 coordinate
  space. As a derivative of a CC BY-SA work, that file is itself made
  available under CC BY-SA 3.0. No other part of this project is affected
  by that license.

## Audio

- [audioplayers](https://pub.dev/packages/audioplayers) — audio playback
  (MIT)
- Hiragana pronunciation audio bundled in `assets/audio/` was recorded/
  produced for this project.

## Branding

- The v1.0 app icon and splash screen are original, minimal placeholder
  artwork created for this project (a torii-gate silhouette drawn
  programmatically), not copied from any existing logo or brand. See
  `RELEASE_CHECKLIST.md` for notes on replacing this before a public
  store listing.

## Icons

- Material Icons, via Flutter's built-in Material Design icon font
  (Apache-2.0).

Full license texts for each dependency are available in-app via
**Settings → Licenses**, which lists the exact packages and versions
bundled in this build.
