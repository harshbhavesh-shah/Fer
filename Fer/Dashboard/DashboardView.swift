//
//  DashboardView.swift
//  Fer
//

import SwiftUI

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

/// Built as a single unified column layout (bar + weekday label + streak dot
/// all in one VStack per day) rather than a Swift Charts bar chart with a
/// separately-laid-out dot row underneath — those two used different layout
/// systems (Charts' internal axis margins vs. a plain HStack), so their
/// columns never reliably lined up.
private struct WeeklyTrendCard: View {
    @ObservedObject var historyVM: HistoryViewModel
    @ObservedObject private var settings = SettingsStore.shared

    private let barAreaHeight: CGFloat = 60
    private let minBarHeight: CGFloat = 4

    private var days: [(date: Date, volume: Double, hasWorkout: Bool)] {
        let volumes = historyVM.dailyVolume(last: 7)
        let workoutDates = historyVM.workoutDates(last: 7)
        return volumes.map { (date: $0.date, volume: $0.volume, hasWorkout: workoutDates.contains($0.date)) }
    }

    private var maxVolume: Double {
        max(days.map(\.volume).max() ?? 0, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week").font(.headline)

            HStack(alignment: .bottom, spacing: 10) {
                ForEach(days, id: \.date) { day in
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(day.volume > 0 ? Theme.accent : Color.secondary.opacity(0.15))
                            .frame(height: barHeight(for: day.volume))

                        Text(day.date, format: .dateTime.weekday(.narrow))
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Circle()
                            .fill(day.hasWorkout ? Theme.accent : Color.secondary.opacity(0.15))
                            .frame(width: 6, height: 6)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .cardStyle()
    }

    private func barHeight(for volume: Double) -> CGFloat {
        guard volume > 0 else { return minBarHeight }
        return max(minBarHeight, barAreaHeight * CGFloat(volume / maxVolume))
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
