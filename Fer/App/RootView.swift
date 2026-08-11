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
    @State private var showingMiniBarDiscardConfirm = false

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
                ActiveWorkoutMiniBar(
                    viewModel: vm,
                    onExpand: {
                        Haptics.light()
                        isWorkoutFullScreen = true
                    },
                    onDiscard: {
                        Haptics.warning()
                        showingMiniBarDiscardConfirm = true
                    }
                )
                .padding(.horizontal, 8)
                .padding(.bottom, 4)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: activeWorkout == nil)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isWorkoutFullScreen)
        .confirmationDialog("Discard this workout?", isPresented: $showingMiniBarDiscardConfirm, titleVisibility: .visible) {
            Button("Discard Workout", role: .destructive) {
                activeWorkout?.discard()
                activeWorkout = nil
            }
            Button("Keep Going", role: .cancel) {}
        }
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

/// Dark capsule pill docked directly above the tab bar while a workout is
/// minimized — matches Hevy's minimized workout bar exactly (chevron-up to
/// expand, green pulsing dot + elapsed time, current exercise below, trash
/// to discard without reopening).
private struct ActiveWorkoutMiniBar: View {
    @ObservedObject var viewModel: WorkoutSessionViewModel
    let onExpand: () -> Void
    let onDiscard: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onExpand) {
                Image(systemName: "chevron.up")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Circle())
            }

            Button(action: onExpand) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(.green)
                            .frame(width: 7, height: 7)
                        (Text("Workout ").font(.subheadline.weight(.bold))
                            + Text(Formatters.duration(viewModel.elapsed)).font(.subheadline).foregroundStyle(.white.opacity(0.6)))
                            .foregroundStyle(.white)
                    }
                    if let exerciseName = viewModel.currentExerciseName {
                        Text(exerciseName)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                            .lineLimit(1)
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Button(action: onDiscard) {
                Image(systemName: "trash")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.red.opacity(0.8))
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(white: 0.13))
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.3), radius: 10, y: 4)
    }
}

#Preview{RootView()}
