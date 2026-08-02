//
//  HistoryView.swift
//  Fer
//

import SwiftUI
import Charts

struct HistoryView: View {
    @ObservedObject var viewModel: HistoryViewModel
    @State private var appeared = false

    private var groupedByMonth: [(month: String, workouts: [WorkoutSession])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        let groups = Dictionary(grouping: viewModel.workouts) { formatter.string(from: $0.startedAt) }
        return groups.map { (month: $0.key, workouts: $0.value.sorted { $0.startedAt > $1.startedAt }) }
            .sorted { ($0.workouts.first?.startedAt ?? .distantPast) > ($1.workouts.first?.startedAt ?? .distantPast) }
    }

    var body: some View {
        Group {
            if viewModel.workouts.isEmpty {
                EmptyStateView(icon: "clock", title: "No workouts logged", message: "Finish a workout and it will show up here.")
            } else {
                List {
                    Section {
                        WeeklyVolumeChart(historyVM: viewModel)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                    }

                    ForEach(groupedByMonth, id: \.month) { group in
                        Section(group.month) {
                            ForEach(group.workouts) { workout in
                                NavigationLink(value: workout) {
                                    WorkoutSummaryCard(workout: workout)
                                        .padding(.vertical, 4)
                                }
                            }
                            .onDelete { offsets in
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                    for index in offsets {
                                        viewModel.delete(group.workouts[index])
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
                .onAppear {
                    withAnimation(.easeOut(duration: 0.4)) { appeared = true }
                }
            }
        }
        .navigationTitle("History")
        .navigationDestination(for: WorkoutSession.self) { workout in
            WorkoutDetailView(workout: workout)
        }
    }
}

private struct WeeklyVolumeChart: View {
    @ObservedObject var historyVM: HistoryViewModel
    @ObservedObject private var settings = SettingsStore.shared

    private var weeklyVolume: [(weekStart: Date, volume: Double)] {
        historyVM.weeklyVolume(weeks: 8)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Weekly Volume").font(.headline)
            Chart(weeklyVolume, id: \.weekStart) { point in
                BarMark(
                    x: .value("Week", point.weekStart, unit: .weekOfYear),
                    y: .value("Volume", Formatters.displayValue(point.volume, unit: settings.weightUnit))
                )
                .foregroundStyle(Theme.accent)
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .weekOfYear, count: 2)) { _ in
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
            .frame(height: 160)
        }
        .cardStyle()
        .padding(.horizontal)
    }
}
