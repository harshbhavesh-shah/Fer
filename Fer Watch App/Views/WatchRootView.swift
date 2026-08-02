//
//  WatchRootView.swift
//  Fer Watch App
//

import SwiftUI

struct WatchRootView: View {
    @StateObject private var auth = WatchAuthService.shared
    @StateObject private var connectivity = WatchConnectivityManager.shared

    var body: some View {
        Group {
            if auth.isLoading {
                ProgressView()
            } else if auth.isSignedIn {
                WatchDashboardView()
            } else {
                WatchWaitingView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: auth.isSignedIn)
        .onAppear { connectivity.requestStateIfNeeded() }
    }
}
