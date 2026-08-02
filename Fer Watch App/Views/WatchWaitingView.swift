//
//  WatchWaitingView.swift
//  Fer Watch App
//
//  Shown until the Watch hears back from the iPhone that you're signed in.
//  Normally flashes by once (right after installing the Watch app) — the
//  Watch never signs in itself, it just mirrors the phone's state.
//

import SwiftUI

struct WatchWaitingView: View {
    @StateObject private var auth = WatchAuthService.shared
    @StateObject private var connectivity = WatchConnectivityManager.shared

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "iphone.gen3.radiowaves.left.and.right")
                .font(.title)
                .foregroundStyle(.secondary)
            Text(auth.statusMessage)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            Button("Retry") {
                connectivity.requestStateIfNeeded()
            }
            .font(.footnote)
        }
        .padding()
    }
}
