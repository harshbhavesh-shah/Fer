//
//  WorkoutDetailView.swift
//  Fer
//

import SwiftUI

struct WorkoutDetailView: View {
    let workout: WorkoutSession
    @ObservedObject private var settings = SettingsStore.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 16) {
                    Label("\(workout.totalSetsCompleted) sets", systemImage: "checkmark.circle")
                    Label("\(Formatters.weight(workout.totalVolume, unit: settings.weightUnit)) \(settings.weightUnit.label)", systemImage: "scalemass")
                    Label(Formatters.duration(workout.duration), systemImage: "timer")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                ForEach(workout.exercises) { exercise in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(exercise.exerciseName).font(.headline)
                        ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, set in
                            HStack {
                                Text("Set \(index + 1)")
                                    .frame(width: 60, alignment: .leading)
                                    .foregroundStyle(.secondary)
                                Text("\(Formatters.weight(set.weight, unit: settings.weightUnit)) \(settings.weightUnit.label) × \(set.reps)")
                                Spacer()
                                if set.isCompleted {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                                }
                            }
                            .font(.subheadline)
                        }
                    }
                    .cardStyle()
                }
            }
            .padding()
        }
        .navigationTitle(workout.routineName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
