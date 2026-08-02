//
//  FerApp.swift
//  Fer
//
//  Created by Harsh Shah on 29/07/26.
//

import SwiftUI
import FirebaseCore

@main
struct FerApp: App {
    init() {
        FirebaseApp.configure()
        // Activate the WatchConnectivity session at launch (not just when a
        // workout starts) so the Watch app can request credentials or be
        // reachable as soon as possible.
        _ = PhoneConnectivityManager.shared
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
