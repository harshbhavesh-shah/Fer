# Fer — Enabling Spotify for Now Playing

The Now Playing card (swipe left on Active Workout) works today against
Apple Music / your local library via `MPMusicPlayerController`, no setup
needed. Spotify support is written (`Fer/Services/SpotifyNowPlayingSource.swift`)
but wrapped in `#if canImport(SpotifyiOS)`, so it compiles to nothing until
you've done the steps below — Spotify's SDK is a proprietary binary that
isn't distributed via Swift Package Manager, and using it requires your own
Spotify Developer app, so these are steps only you can do.

## 1. Register a Spotify Developer app

1. Go to [developer.spotify.com/dashboard](https://developer.spotify.com/dashboard) and create an app.
2. Note the **Client ID**.
3. Add a Redirect URI: `fer-spotify-auth://spotify-callback` (or change the
   scheme in step 4 below to whatever you use here — they must match).

## 2. Download and add the SDK

1. Download `SpotifyiOS.xcframework` from the
   [Spotify iOS SDK releases](https://github.com/spotify/ios-sdk).
2. Drag `SpotifyiOS.xcframework` into the **Fer** target in Xcode (not the
   Watch or FerLiveActivity targets) — check "Copy items if needed" and
   make sure it's added to Fer's "Frameworks, Libraries, and Embedded
   Content" as **Embed & Sign**.

## 3. Fill in your credentials

In `Fer/Services/SpotifyNowPlayingSource.swift`, set:
```swift
private static let spotifyClientId = "YOUR_SPOTIFY_CLIENT_ID"
private static let spotifyRedirectURL = URL(string: "fer-spotify-auth://spotify-callback")!
```

## 4. Register the URL scheme + Spotify query capability

In the Fer target's Info settings (Target → Info tab):
- **URL Types**: add one with URL Schemes = `fer-spotify-auth` (or whatever
  you used in step 1/3).
- **LSApplicationQueriesSchemes**: add `spotify` (needed to detect whether
  the Spotify app is installed).

I didn't wire these into the generated Info.plist mechanism myself — the
Fer target currently uses `GENERATE_INFOPLIST_FILE = YES` with flat
`INFOPLIST_KEY_*` build settings, which can't express `CFBundleURLTypes`
(an array of dictionaries). Editing this by hand risked breaking Info.plist
generation for the whole app before the feature could even compile, so it's
safer for you to add these two entries through Xcode's Info tab UI, which
handles the underlying plist structure for you.

## 5. Handle the OAuth redirect

Add to `FerApp.swift`:
```swift
.onOpenURL { url in
    // Forward to whichever SpotifyNowPlayingSource instance is active,
    // e.g. via NowPlayingManager, calling appRemote.authorizationParameters(from: url)
    // then appRemote.connect() on success.
}
```
(`SpotifyNowPlayingSource` doesn't yet expose a hook for this since it can't
compile without the SDK present — add one once you've completed steps 1–4.)

## 6. Switch the source

Once linked, go to Settings → Now Playing Source → Spotify in the app.
