//
//  WatchMirroredWorkoutView.swift
//  Fer Watch App
//
//  Shows whatever workout is currently active on the iPhone. Tapping a set
//  sends the action back to the phone (which stays the source of truth);
//  this view just renders the latest snapshot it's received.
//

import SwiftUI

struct WatchMirroredWorkoutView: View {
    @StateObject private var connectivity = WatchConnectivityManager.shared

    var body: some View {
        Group {
            if let snapshot = connectivity.mirrorSnapshot {
                List {
                    Section {
                        HStack {
                            Text(snapshot.routineName).font(.headline)
                            Spacer()
                            Text(Formatters.duration(snapshot.elapsed))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }

                    if snapshot.isResting {
                        Section {
                            HStack {
                                Image(systemName: "timer")
                                Text("Resting: \(snapshot.restRemaining)s")
                                Spacer()
                                Button("Skip") {
                                    connectivity.send(.skipRest)
                                }
                                .font(.caption)
                            }
                        }
                    }

                    ForEach(Array(snapshot.exercises.enumerated()), id: \.element.id) { exerciseIndex, exercise in
                        Section(exercise.exerciseName) {
                            ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { setIndex, set in
                                Button {
                                    connectivity.send(.toggleSet(exerciseIndex: exerciseIndex, setIndex: setIndex))
                                } label: {
                                    HStack {
                                        Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(set.isCompleted ? .green : .secondary)
                                        Text("\(Formatters.weight(set.weight)) × \(set.reps)")
                                    }
                                }
                            }
                            Button {
                                connectivity.send(.addSet(exerciseIndex: exerciseIndex))
                            } label: {
                                Label("Add Set", systemImage: "plus")
                            }
                            .font(.caption)
                        }
                    }
                }
                .navigationTitle("Active")
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "iphone.slash")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("No active workout on iPhone")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
    }
}
