//
//  RoutineEditorView.swift
//  Fer
//

import SwiftUI

struct RoutineEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: RoutinesViewModel
    @State var routine: RoutineTemplate
    @State private var showingPicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Routine name", text: $routine.name)
                    Picker("Icon", selection: $routine.iconName) {
                        ForEach(["list.bullet.rectangle", "flame.fill", "bolt.fill", "figure.strengthtraining.traditional", "figure.run"], id: \.self) { icon in
                            Image(systemName: icon).tag(icon)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Exercises") {
                    ForEach($routine.exercises) { $item in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(item.exerciseName).font(.subheadline.weight(.semibold))
                            HStack {
                                Stepper("Sets: \(item.targetSets)", value: $item.targetSets, in: 1...10)
                            }
                            HStack {
                                Stepper("Reps: \(item.targetReps)", value: $item.targetReps, in: 1...30)
                            }
                            HStack {
                                Stepper("Rest: \(item.restSeconds)s", value: $item.restSeconds, in: 15...300, step: 15)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { offsets in
                        Haptics.light()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            routine.exercises.remove(atOffsets: offsets)
                        }
                    }
                    .onMove { offsets, destination in
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            routine.exercises.move(fromOffsets: offsets, toOffset: destination)
                        }
                    }

                    Button {
                        Haptics.light()
                        showingPicker = true
                    } label: {
                        Label("Add Exercise", systemImage: "plus.circle.fill")
                    }
                }

                if routine.id != nil {
                    Section {
                        Button("Delete Routine", role: .destructive) {
                            viewModel.delete(routine)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(routine.id == nil ? "New Routine" : "Edit Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Haptics.success()
                        viewModel.save(routine)
                        dismiss()
                    }
                    .disabled(routine.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItem(placement: .topBarLeading) {
                    if !routine.exercises.isEmpty {
                        EditButton()
                    }
                }
            }
            .sheet(isPresented: $showingPicker) {
                ExercisePickerView { exercise in
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        routine.exercises.append(
                            RoutineExercise(
                                exerciseId: exercise.id,
                                exerciseName: exercise.name,
                                restSeconds: SettingsStore.shared.defaultRestSeconds
                            )
                        )
                    }
                }
            }
        }
    }
}
