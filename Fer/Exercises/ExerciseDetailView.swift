//
//  ExerciseDetailView.swift
//  Fer
//

import SwiftUI
import Charts

struct ExerciseDetailView: View {
    let exercise: Exercise
    @ObservedObject var historyVM: HistoryViewModel
    @ObservedObject private var settings = SettingsStore.shared

    private var history: [(date: Date, bestSet: SetEntry)] {
        historyVM.history(forExerciseId: exercise.id)
    }

    private var personalBest: SetEntry? {
        history.max { $0.bestSet.weight * Double($0.bestSet.reps) < $1.bestSet.weight * Double($1.bestSet.reps) }?.bestSet
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Image(systemName: exercise.primaryMuscle.icon)
                        .font(.largeTitle)
                        .foregroundStyle(exercise.primaryMuscle.accentColor)
                    VStack(alignment: .leading) {
                        Text(exercise.name).font(.title2.bold())
                        Text("\(exercise.primaryMuscle.displayName) · \(exercise.equipment.displayName)")
                            .foregroundStyle(.secondary)
                    }
                }

                if let pb = personalBest {
                    HStack(spacing: 24) {
                        SummaryMetric(title: "Best Set", value: "\(Formatters.weight(pb.weight, unit: settings.weightUnit)) \(settings.weightUnit.label) × \(pb.reps)")
                        SummaryMetric(title: "Sessions", value: "\(history.count)")
                    }
                    .cardStyle()
                }

                if history.isEmpty {
                    EmptyStateView(icon: "chart.line.uptrend.xyaxis", title: "No history yet", message: "Log this exercise in a workout to see your progress here.")
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Progress (est. 1RM trend)").font(.headline)
                        Chart(history, id: \.date) { point in
                            LineMark(
                                x: .value("Date", point.date),
                                y: .value("Weight", Formatters.displayValue(point.bestSet.weight, unit: settings.weightUnit))
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(Theme.accent)

                            PointMark(
                                x: .value("Date", point.date),
                                y: .value("Weight", Formatters.displayValue(point.bestSet.weight, unit: settings.weightUnit))
                            )
                            .foregroundStyle(Theme.accent)
                        }
                        .chartYAxisLabel(settings.weightUnit.label.uppercased())
                        .frame(height: 220)
                    }
                    .cardStyle()
                }
            }
            .padding()
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SummaryMetric: View {
    let title: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title3.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
