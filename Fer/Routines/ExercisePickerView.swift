//
//  ExercisePickerView.swift
//  Fer
//

import SwiftUI

struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""
    @State private var selectedMuscle: MuscleGroup?
    let onSelect: (Exercise) -> Void

    private var filtered: [Exercise] {
        ExerciseLibrary.all.filter { exercise in
            let matchesSearch = search.isEmpty || exercise.name.localizedCaseInsensitiveContains(search)
            let matchesMuscle = selectedMuscle == nil || exercise.primaryMuscle == selectedMuscle
            return matchesSearch && matchesMuscle
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(title: "All", isSelected: selectedMuscle == nil) {
                            withAnimation { selectedMuscle = nil }
                        }
                        ForEach(MuscleGroup.allCases) { muscle in
                            FilterChip(title: muscle.displayName, isSelected: selectedMuscle == muscle) {
                                withAnimation { selectedMuscle = muscle }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                List(filtered) { exercise in
                    Button {
                        Haptics.medium()
                        onSelect(exercise)
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: exercise.primaryMuscle.icon)
                                .foregroundStyle(exercise.primaryMuscle.accentColor)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(exercise.name).foregroundStyle(.primary)
                                Text(exercise.equipment.displayName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search exercises")
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(isSelected ? Theme.accent : Color(.tertiarySystemFill))
                )
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.bouncy)
    }
}
