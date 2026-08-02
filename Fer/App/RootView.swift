//
//  RootView.swift
//  Fer
//
//  Top-level auth gate + tab bar.
//

import SwiftUI

struct RootView: View {
    @StateObject private var auth = AuthService.shared

    var body: some View {
        Group {
            if auth.isLoading {
                ProgressView()
            } else if auth.isSignedIn {
                MainTabView()
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                AuthView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: auth.isSignedIn)
        .animation(.easeInOut(duration: 0.35), value: auth.isLoading)
    }
}

struct MainTabView: View {
    @StateObject private var routinesVM = RoutinesViewModel()
    @StateObject private var historyVM = HistoryViewModel()
    @State private var activeWorkout: WorkoutSessionViewModel?

    var body: some View {
        TabView {
            NavigationStack {
                DashboardView(routinesVM: routinesVM, historyVM: historyVM, activeWorkout: $activeWorkout)
            }
            .tabItem { Label("Dashboard", systemImage: "house.fill") }

            NavigationStack {
                RoutinesListView(viewModel: routinesVM, activeWorkout: $activeWorkout)
            }
            .tabItem { Label("Routines", systemImage: "list.bullet.rectangle.fill") }

            NavigationStack {
                HistoryView(viewModel: historyVM)
            }
            .tabItem { Label("History", systemImage: "clock.fill") }

            NavigationStack {
                ExerciseLibraryView(historyVM: historyVM)
            }
            .tabItem { Label("Exercises", systemImage: "dumbbell.fill") }

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .fullScreenCover(item: $activeWorkout) { vm in
            ActiveWorkoutView(viewModel: vm, activeWorkout: $activeWorkout)
        }
    }
}

#Preview{RootView()}
