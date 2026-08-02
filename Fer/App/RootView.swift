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
    @State private var isWorkoutFullScreen = false

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
        .safeAreaInset(edge: .bottom) {
            if let vm = activeWorkout, !isWorkoutFullScreen {
                ActiveWorkoutMiniBar(viewModel: vm) {
                    Haptics.light()
                    isWorkoutFullScreen = true
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: activeWorkout == nil)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isWorkoutFullScreen)
        .fullScreenCover(isPresented: $isWorkoutFullScreen) {
            if let vm = activeWorkout {
                ActiveWorkoutView(
                    viewModel: vm,
                    activeWorkout: $activeWorkout,
                    historyVM: historyVM,
                    onMinimize: {
                        Haptics.light()
                        isWorkoutFullScreen = false
                    }
                )
                .interactiveDismissDisabled()
            }
        }
        .onAppear {
            guard activeWorkout == nil, let draft = WorkoutDraftStore.load() else { return }
            activeWorkout = WorkoutSessionViewModel(draft: draft)
            isWorkoutFullScreen = true
        }
        .onChange(of: activeWorkout == nil) { _, isNil in
            isWorkoutFullScreen = !isNil
        }
    }
}

private struct ActiveWorkoutMiniBar: View {
    @ObservedObject var viewModel: WorkoutSessionViewModel
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Theme.gradient(for: Theme.accent)))

                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.routineName)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Text("\(viewModel.totalSetsCompleted) sets · \(Formatters.duration(viewModel.elapsed))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("Resume")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.accent)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.regularMaterial)
        }
        .buttonStyle(.plain)
    }
}

#Preview{RootView()}
