//
//  WatchStandaloneWorkoutView.swift
//  Fer Watch App
//
//  A workout logged entirely on the Watch (no iPhone needed) — writes
//  straight to Firestore via WatchWorkoutViewModel.finish().
//

import SwiftUI

struct WatchStandaloneWorkoutView: View {
    @ObservedObject var viewModel: WatchWorkoutViewModel
    @Binding var activeWorkout: WatchWorkoutViewModel?
    @State private var showingFinishConfirm = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text(viewModel.routineName).font(.headline)
                        Spacer()
                        Text(Formatters.duration(viewModel.elapsed))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }

                if viewModel.isResting {
                    Section {
                        HStack {
                            Image(systemName: "timer")
                            Text("Resting: \(viewModel.restRemaining)s")
                            Spacer()
                            Button("Skip") { viewModel.skipRest() }.font(.caption)
                        }
                    }
                }

                ForEach(Array(viewModel.exercises.enumerated()), id: \.element.id) { exerciseIndex, exercise in
                    Section(exercise.exerciseName) {
                        ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { setIndex, set in
                            Button {
                                viewModel.toggleComplete(exerciseIndex: exerciseIndex, setIndex: setIndex)
                            } label: {
                                HStack {
                                    Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(set.isCompleted ? .green : .secondary)
                                    Text("\(Formatters.weight(set.weight)) × \(set.reps)")
                                }
                            }
                        }
                        Button {
                            viewModel.addSet(to: exerciseIndex)
                        } label: {
                            Label("Add Set", systemImage: "plus")
                        }
                        .font(.caption)
                    }
                }

                if viewModel.exercises.isEmpty {
                    Text("No exercises yet.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button("Finish", role: .none) {
                        showingFinishConfirm = true
                    }
                    .disabled(viewModel.totalSetsCompleted == 0)
                }
            }
            .navigationTitle("Workout")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Discard") {
                        viewModel.discard()
                        activeWorkout = nil
                    }
                    .foregroundStyle(.red)
                }
            }
            .confirmationDialog("Finish workout?", isPresented: $showingFinishConfirm) {
                Button("Save & Finish") {
                    Task {
                        await viewModel.finish()
                        activeWorkout = nil
                    }
                }
                Button("Keep Going", role: .cancel) {}
            }
        }
    }
}
