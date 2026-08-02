//
//  DashboardView.swift
//  Fer
//

import SwiftUI
import Charts

struct DashboardView: View {
    @ObservedObject var routinesVM: RoutinesViewModel
    @ObservedObject var historyVM: HistoryViewModel
    @Binding var activeWorkout: WorkoutSessionViewModel?
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                HStack(spacing: 12) {
                    StatPill(value: "\(historyVM.currentStreak)", label: "Day streak", icon: "flame.fill", color: .orange)
                    StatPill(value: "\(historyVM.workoutsThisWeek)", label: "This week", icon: "calendar", color: .blue)
                    StatPill(value: "\(historyVM.workouts.count)", label: "All time", icon: "trophy.fill", color: .purple)
                }

                if !historyVM.workouts.isEmpty {
                    WeeklyTrendCard(historyVM: historyVM)
                }

                Button {
                    startWorkout { WorkoutSessionViewModel(blank: true) }
                } label: {
                    Label("Start Empty Workout", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.primaryAction())

                if !routinesVM.routines.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Your Routines").font(.headline)
                        ForEach(routinesVM.routines.prefix(3)) { routine in
                            RoutineQuickStartRow(routine: routine) {
                                startWorkout {
                                    routinesVM.markUsed(routine)
                                    return WorkoutSessionViewModel(from: routine)
                                }
                            }
                        }
                    }
                }

                if let recent = historyVM.workouts.first {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Last Workout").font(.headline)
                        NavigationLink(value: recent) {
                            WorkoutSummaryCard(workout: recent)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Fer")
        .navigationDestination(for: WorkoutSession.self) { workout in
            WorkoutDetailView(workout: workout)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) { appeared = true }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                Text(Formatters.mediumDate.string(from: Date()))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    /// Guards against silently overwriting (and losing) an already-active
    /// workout — e.g. if it's currently minimized rather than on screen.
    private func startWorkout(_ make: () -> WorkoutSessionViewModel) {
        guard activeWorkout == nil else {
            Haptics.warning()
            return
        }
        Haptics.medium()
        activeWorkout = make()
    }
}

private struct WeeklyTrendCard: View {
    @ObservedObject var historyVM: HistoryViewModel
    @ObservedObject private var settings = SettingsStore.shared

    private var dailyVolume: [(date: Date, volume: Double)] {
        historyVM.dailyVolume(last: 7)
    }

    private var workoutDates: Set<Date> {
        historyVM.workoutDates(last: 7)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week").font(.headline)

            Chart(dailyVolume, id: \.date) { point in
                BarMark(
                    x: .value("Day", point.date, unit: .day),
                    y: .value("Volume", Formatters.displayValue(point.volume, unit: settings.weightUnit))
                )
                .foregroundStyle(Theme.accent)
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.narrow))
                }
            }
            .chartYAxis(.hidden)
            .frame(height: 100)

            HStack(spacing: 8) {
                ForEach(lastSevenDays, id: \.self) { day in
                    Circle()
                        .fill(workoutDates.contains(day) ? Theme.accent : Color.secondary.opacity(0.15))
                        .frame(width: 10, height: 10)
                }
            }
        }
        .cardStyle()
    }

    private var lastSevenDays: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).reversed().compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }
    }
}

private struct StatPill: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon).foregroundStyle(color)
            Text(value).statNumberStyle()
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .cardStyle(padding: 8)
    }
}

private struct RoutineQuickStartRow: View {
    let routine: RoutineTemplate
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: routine.iconName)
                    .font(.title3)
                    .foregroundStyle(Theme.accent)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(routine.name).font(.subheadline.weight(.semibold))
                    Text("\(routine.exercises.count) exercises")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.accent)
            }
            .padding(12)
            .cardStyle(padding: 4)
        }
        .buttonStyle(.bouncy)
    }
}

struct WorkoutSummaryCard: View {
    let workout: WorkoutSession
    @ObservedObject private var settings = SettingsStore.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(workout.routineName).font(.subheadline.weight(.semibold))
                Spacer()
                Text(Formatters.relativeDate.localizedString(for: workout.startedAt, relativeTo: Date()))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 16) {
                Label("\(workout.totalSetsCompleted) sets", systemImage: "checkmark.circle")
                Label("\(Formatters.weight(workout.totalVolume, unit: settings.weightUnit)) \(settings.weightUnit.label) vol", systemImage: "scalemass")
                Label(Formatters.duration(workout.duration), systemImage: "timer")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .cardStyle()
    }
}

#Preview {
    NavigationStack {
        DashboardView(routinesVM: RoutinesViewModel(), historyVM: HistoryViewModel(), activeWorkout: .constant(nil))
    }
}
