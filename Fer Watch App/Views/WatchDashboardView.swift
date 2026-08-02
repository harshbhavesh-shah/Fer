//
//  WatchDashboardView.swift
//  Fer Watch App
//
//  If the phone has an active workout, jump straight into mirroring it.
//  Otherwise, offer routines to start a standalone workout right here.
//

import SwiftUI

struct WatchDashboardView: View {
    @StateObject private var connectivity = WatchConnectivityManager.shared
    @State private var standaloneWorkout: WatchWorkoutViewModel?

    var body: some View {
        NavigationStack {
            List {
                if connectivity.mirrorSnapshot != nil {
                    Section {
                        NavigationLink {
                            WatchMirroredWorkoutView()
                        } label: {
                            Label("Resume from iPhone", systemImage: "iphone.radiowaves.left.and.right")
                        }
                    }
                }

                Section("Start Standalone") {
                    Button {
                        WatchHaptics.click()
                        standaloneWorkout = WatchWorkoutViewModel(routineName: "Quick Workout", exercises: [])
                    } label: {
                        Label("Empty Workout", systemImage: "plus")
                    }

                    ForEach(connectivity.routines) { routine in
                        Button {
                            WatchHaptics.click()
                            standaloneWorkout = WatchWorkoutViewModel(from: routine)
                        } label: {
                            Text(routine.name)
                        }
                    }
                }
            }
            .navigationTitle("Fer")
            .fullScreenCover(item: $standaloneWorkout) { vm in
                WatchStandaloneWorkoutView(viewModel: vm, activeWorkout: $standaloneWorkout)
            }
        }
    }
}
