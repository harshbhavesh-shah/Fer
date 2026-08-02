//
//  SettingsView.swift
//  Fer
//

import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @StateObject private var auth = AuthService.shared
    @StateObject private var settings = SettingsStore.shared
    @State private var showingSignOutConfirm = false
    @State private var appeared = false

    private let restTimeOptions = [30, 60, 90, 120, 180]

    var body: some View {
        List {
            Section {
                ProfileHeader(name: auth.currentUser?.displayName, email: auth.currentUser?.email)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            Section("Preferences") {
                Picker(selection: $settings.weightUnit) {
                    ForEach(UserProfile.WeightUnit.allCases, id: \.self) { unit in
                        Text(unit.label.uppercased()).tag(unit)
                    }
                } label: {
                    Label("Weight Unit", systemImage: "scalemass")
                }
                .pickerStyle(.segmented)
                .onChange(of: settings.weightUnit) { _, _ in Haptics.selection() }

                Picker(selection: $settings.defaultRestSeconds) {
                    ForEach(restTimeOptions, id: \.self) { seconds in
                        Text("\(seconds)s").tag(seconds)
                    }
                } label: {
                    Label("Default Rest Time", systemImage: "timer")
                }
                .onChange(of: settings.defaultRestSeconds) { _, _ in Haptics.selection() }

                Picker(selection: $settings.nowPlayingSource) {
                    ForEach(SettingsStore.NowPlayingSourceKind.allCases, id: \.self) { source in
                        Text(source.label).tag(source)
                    }
                } label: {
                    Label("Now Playing Source", systemImage: "music.note")
                }
                .onChange(of: settings.nowPlayingSource) { _, _ in
                    Haptics.selection()
                    NowPlayingManager.shared.refreshSource()
                }
            }

            Section {
                Button(role: .destructive) {
                    Haptics.medium()
                    showingSignOutConfirm = true
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }

            Section("About") {
                LabeledContent {
                    Text("1.0.0")
                } label: {
                    Label("Version", systemImage: "info.circle")
                }
            }
        }
        .navigationTitle("Settings")
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) { appeared = true }
        }
        .confirmationDialog("Sign out of Fer?", isPresented: $showingSignOutConfirm, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) {
                auth.signOut()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

private struct ProfileHeader: View {
    let name: String?
    let email: String?

    private var initials: String {
        guard let name, !name.isEmpty else { return String(email?.first ?? "?").uppercased() }
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap(\.first)
        return String(letters).uppercased()
    }

    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Theme.gradient(for: Theme.accent))
                .frame(width: 56, height: 56)
                .overlay(
                    Text(initials)
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                if let name, !name.isEmpty {
                    Text(name).font(.headline)
                }
                if let email {
                    Text(email)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding()
        .cardStyle()
        .padding(.horizontal)
        .padding(.top, 4)
    }
}

#Preview {
    NavigationStack { SettingsView() }
}
