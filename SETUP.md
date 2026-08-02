# Fer — Setup Guide

Your iPhone workout tracker is built and sitting in `Fer/`. It's a real
SwiftUI app (routines, active workout logging, rest timers, history,
per-exercise progress charts) but it needs two things wired up in Xcode
before it will run, because they require your own accounts / GUI steps
I can't do from here:

## 1. Add the Firebase SDK package

1. Open `Fer.xcodeproj` in Xcode.
2. File → Add Package Dependencies…
3. Paste in: `https://github.com/firebase/firebase-ios-sdk`
4. When prompted for products, add these to the **Fer** target:
   - `FirebaseAuth`
   - `FirebaseFirestore`
   - `FirebaseCore`

## 2. Create a Firebase project and connect it

1. Go to https://console.firebase.google.com → Add project (name it
   whatever you like, e.g. "Fer").
2. Inside the project, click the iOS icon to add an app.
   - Bundle ID: `com.Harshbshah.Fer` (must match exactly — this is
     already set in the Xcode project).
3. Download the generated `GoogleService-Info.plist`.
4. Drag it into the `Fer/` folder in Xcode's file navigator (check
   "Copy items if needed" and make sure it's added to the **Fer** target).
5. In the Firebase console:
   - **Authentication** → Sign-in method → enable **Email/Password**.
   - **Firestore Database** → Create database → start in production mode
     (any region close to you).

## 3. Firestore security rules

Paste this into Firestore → Rules so each signed-in user can only read/write
their own data (routines, workouts, profile):

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      match /{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

## 4. Build and run

Build (⌘R) on a simulator or your iPhone. Sign up with an email/password —
that same account is what will let the Watch, iPad, and Mac apps (built in
later passes) sync to the same data.

---

## What's included in this first version

- Email/password auth (Firebase Auth) — same account syncs everywhere.
- Exercise library (~55 seeded exercises across all major muscle groups),
  searchable and filterable, with your own custom exercises supported later.
- Routines: create/edit templates with target sets/reps/rest per exercise.
- Active workout: log weight × reps per set, animated set-completion,
  auto-starting rest timer with haptics (soft tick in the final 3 seconds,
  success buzz at zero), skip / add-15s controls.
- Workout history grouped by month, with a detail view per workout.
- Per-exercise progress chart (Swift Charts) tracking your best set over time.
- A small design system (`Theme.swift`, `Haptics.swift`) so buttons, cards,
  and transitions feel consistent and animated throughout.

## Not yet built (next passes, per your priority order)

- Apple Watch companion app
- Mac app (should mostly "just work" via Mac Catalyst once this is solid —
  I'd add `TARGETED_DEVICE_FAMILY` / a Catalyst target)
- iPad-specific layout polish (it already runs on iPad, just not optimized)
- Android app (separate Kotlin/Jetpack Compose project in Android Studio)
- Food tracking and goal tracking modules
