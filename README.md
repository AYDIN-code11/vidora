# Vidora

A privacy-friendly YouTube client for Android — inspired by FreeTube and
NewPipe, built with Flutter and [KMEP](https://github.com/dipodev20/kmep)
(a pure-Dart YouTube extractor). Red & black, ad-free, account-free.

## Features

- **Home / Trending** — Now, Music, Gaming, News feeds
- **Search** — full YouTube search with pagination and query history
- **Watch** — up to 4K playback (media_kit), quality picker, no ads
- **Channels** — banner, subscriber count, video sorting (new/popular/old)
- **Subscriptions** — local-only, merged latest-videos feed
- **Shorts** — shorts feed browsing
- **History** — optional, device-only, with progress tracking
- **Bookmarks** — save videos locally
- **Settings** — default quality, autoplay, region, history toggle

No Google account, no tracking, everything stays on your device. Stream
extraction runs fully on-device via KMEP (headless WebView JS runtime +
on-device PO tokens — no external servers).

## Tech

| Piece | What it is |
|---|---|
| Flutter 3 | UI framework |
| KMEP | YouTube extraction (InnerTube, player.js, BotGuard PO tokens) |
| media_kit | video playback (libmpv) |
| flutter_svg | SVG icon set (custom red/black) |
| shared_preferences | local persistence |

## Build

Requires Flutter 3.24+ and Android SDK. Or just grab the APK from
[GitHub Actions artifacts](../../actions) — every push builds a signed
release APK.

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

## Download

1. Go to the [Actions tab](../../actions/workflows/android.yml)
2. Open the latest successful **Build Android APK** run
3. Download the `vidora-arm64-v8a` artifact (most phones) or
   `vidora-all-abis`

Or create a release tag (`v1.0.0`) — the workflow attaches APKs to a
GitHub release automatically.

## Legal

YouTube™ is a trademark of Google LLC. Vidora is not affiliated with
YouTube or Google. Extraction talks to the same endpoints YouTube's
own apps use; whether that's okay under YouTube's ToS depends on your
jurisdiction — same as every extractor-based client.

## License

GPL-3.0-or-later — same as KMEP. Derivatives must stay open-source.
