//
//  FerWatchApp.swift
//  Fer Watch App
//
//  No Firebase here — FirebaseFirestore has no watchOS build, so the Watch
//  app doesn't link any Firebase SDK at all. It talks to the iPhone over
//  WatchConnectivity (WatchConnectivityManager), and the phone is the one
//  that actually reads/writes Firestore.
//

import SwiftUI

@main
struct FerWatchApp: App {
    init() {
        _ = WatchConnectivityManager.shared
    }

    var body: some Scene {
        WindowGroup {
            WatchRootView()
        }
    }
}
