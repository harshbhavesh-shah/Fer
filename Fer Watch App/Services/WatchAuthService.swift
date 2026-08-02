//
//  WatchAuthService.swift
//  Fer Watch App
//
//  Not a real Firebase auth session — the Watch never talks to Firebase at
//  all (FirebaseFirestore has no watchOS build). This just mirrors whether
//  the iPhone is signed in, relayed by WatchConnectivityManager, so the
//  Watch app can show the right screen.
//

import Foundation
import Combine

@MainActor
final class WatchAuthService: ObservableObject {
    static let shared = WatchAuthService()

    @Published var isSignedIn = false
    @Published var displayName: String = ""
    @Published var isLoading = true
    @Published var statusMessage = "Waiting for iPhone…"

    private init() {}

    func update(isSignedIn: Bool, displayName: String) {
        self.isSignedIn = isSignedIn
        self.displayName = displayName
        self.isLoading = false
        if !isSignedIn {
            statusMessage = "Open Fer on your iPhone and sign in."
        }
    }
}
