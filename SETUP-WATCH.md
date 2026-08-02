# Fer — Adding the Watch App

All the Watch app's Swift code is already written and sitting in
`Fer Watch App/` next to your `Fer/` folder.

**Update:** the Watch app no longer uses Firebase at all. Firestore's SDK
doesn't ship a watchOS build (its networking layer can't compile for the
platform), which is what was causing the `No such module 'FirebaseFirestore'`
error — it wasn't a config problem, it was a hard SDK limitation. The Watch
now talks to the iPhone over WatchConnectivity instead, and the phone does
all the actual Firestore reads/writes on its behalf. This is also more
secure than the earlier design: your password never leaves the phone.

## 1. Create the target

1. Open `Fer.xcodeproj`.
2. File → New → Target… → watchOS → **Watch App**.
3. Name it exactly **Fer Watch App** (matches the folder already on disk)
   and set "Embed in Companion Application" to **Fer**.
4. Xcode generates its own starter `ContentView.swift` /
   `FerWatchAppApp.swift` — **delete those two** (Move to Trash), then drag
   the real `Fer Watch App/` folder contents into the new target's group,
   making sure "Fer Watch App" is checked as the target when adding them.

## 2. Share the common files with the new target

These need to belong to **both** targets (Fer and Fer Watch App):

- `Fer/Models/Exercise.swift`
- `Fer/Models/MuscleGroup.swift`
- `Fer/Models/RoutineTemplate.swift`
- `Fer/Models/WorkoutSession.swift`
- `Fer/Models/WorkoutMirror.swift`
- `Fer/Data/ExerciseLibrary.swift` (optional — not used by the Watch UI yet, but harmless to share)
- `Fer/Utilities/Formatters.swift`

For each: select it in the Project Navigator → File Inspector (⌥⌘1) →
under "Target Membership", check **Fer Watch App** too.

**Do not** share these — they're iPhone-only and won't compile on watchOS:

- `Fer/Utilities/Haptics.swift` (UIKit)
- `Fer/Services/AuthService.swift` (real Firebase session)
- `Fer/Services/FirestoreService.swift` (imports FirebaseFirestore)
- `Fer/Services/PhoneConnectivityManager.swift` (the phone side of the bridge)
- `Fer/ViewModels/RoutinesViewModel.swift` (imports FirebaseFirestore)
- `Fer/Models/UserProfile.swift` (not needed on Watch; also fine to leave iOS-only)

The Watch app has its own equivalents already: `WatchHaptics.swift`,
`WatchAuthService.swift`, `WatchConnectivityManager.swift`,
`WatchWorkoutViewModel.swift`.

## 3. No Firebase setup needed for this target

Unlike before — **skip adding any Firebase package products or
GoogleService-Info.plist to the Fer Watch App target.** It doesn't link
Firebase at all now, so there's nothing to configure there.

## 4. Build and run

Pick the "Fer Watch App" scheme with a paired Watch simulator and run. Make
sure the Fer iPhone app has been opened and you're signed in — as soon as
the two are connected, the Watch receives your sign-in state and routines
automatically.

## How it behaves

- **Phone nearby + workout active there:** Watch shows "Resume from
  iPhone" and mirrors that session — tapping a set on your wrist marks it
  complete on the phone too.
- **Phone not reachable / prefer logging from the wrist:** Watch runs a
  fully standalone workout (from a routine synced earlier, or empty) and,
  on Finish, hands the completed workout to the phone via
  `transferUserInfo` — a queued, guaranteed-delivery transfer that lands as
  soon as the phone is reachable again, even if it's in the background.
  The phone then saves it to Firestore, and it shows up in History.

## Known v1 limitations

- You can't add exercises to a workout from the Watch — standalone
  workouts must come from an existing routine (built on the phone), or
  start empty.
- No workout history or progress charts on the Watch yet — just the
  active-workout screen.
- Mirroring relies on `WCSession.isReachable`; if the Watch app isn't
  foregrounded, actions sent from it may not deliver instantly (they're not
  queued like standalone-workout saves are).
