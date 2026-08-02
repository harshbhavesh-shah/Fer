# Fer for Android — Setup

The `android/` folder is a standalone Android Studio (Gradle) project that talks to the
**same Firebase project** as the iOS app (`fer-app-312e4`), so a workout logged on
Android shows up instantly on iPhone/Watch and vice versa.

## 1. Register the Android app in Firebase (one-time, must be done in the console)

This is the one step I can't do for you — it requires your Firebase console login.

1. Go to the [Firebase console](https://console.firebase.google.com/) → project **fer-app-312e4**.
2. Project settings → **Add app** → Android.
3. Package name: `com.harshbshah.fer` (must match exactly).
4. Nickname: "Fer Android" (anything).
5. Skip the SHA-1 field for now (only needed later for Google Sign-In / Play Integrity — email/password auth doesn't need it).
6. Download the generated **`google-services.json`**.
7. Place it at `android/app/google-services.json` (sibling to `android/app/build.gradle.kts`). The build will fail without it — the Gradle project deliberately doesn't ship a copy since it contains project identifiers.

## 2. Open in Android Studio

1. Open Android Studio → **Open** → select the `android/` folder (not the repo root).
2. Let Gradle sync. If prompted to create the Gradle wrapper jar, accept — Android Studio bundles its own JDK and Gradle distribution and will fetch what's declared in `gradle/wrapper/gradle-wrapper.properties` (Gradle 8.7).
3. Run on an emulator or device (minSdk 26 / Android 8.0+).

## 3. Now Playing panel (optional, one-time per device)

The Active Workout screen's Now Playing panel reads whatever music app is currently
playing (Spotify, YouTube Music, etc.) via Android's notification-listener API — no
per-app developer keys needed, unlike iOS's Spotify integration. Grant access once from
**Settings → Now Playing Access → Grant** in the app (this opens the system's
notification-listener settings screen).

## 4. Verify cross-platform sync

Sign up with the same or a different test account on Android and iOS, then:
- Create a routine on one platform, confirm it appears on the other within a few seconds.
- Log a workout on one platform, confirm it shows up in History/Dashboard stats on the other.
- Check the Firebase console (Firestore Database) to confirm documents land under
  `users/{uid}/routines` and `users/{uid}/workouts` with the same field shapes as the iOS app writes.

## What's not in this pass

No Wear OS companion app and no Spotify-SDK-specific integration (the generic
notification-listener Now Playing source covers the same use case without the Spotify
Developer Dashboard setup iOS requires — see `SETUP-SPOTIFY.md`). Both could be added
later following the same pattern as the iOS Watch app / SpotifyNowPlayingSource.
