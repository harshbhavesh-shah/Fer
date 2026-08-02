//
//  HistoryViewModel.swift
//  Fer
//

import Foundation
import FirebaseFirestore
import Combine

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var workouts: [WorkoutSession] = []
    private var listener: ListenerRegistration?

    init() {
        listener = FirestoreService.shared.workoutsListener { [weak self] workouts in
            self?.workouts = workouts
        }
    }

    deinit {
        listener?.remove()
    }

    var currentStreak: Int {
        let calendar = Calendar.current
        let days = Set(workouts.map { calendar.startOfDay(for: $0.startedAt) })
        var streak = 0
        var cursor = calendar.startOfDay(for: Date())
        while days.contains(cursor) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    var workoutsThisWeek: Int {
        let calendar = Calendar.current
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else { return 0 }
        return workouts.filter { $0.startedAt >= weekAgo }.count
    }

    func delete(_ workout: WorkoutSession) {
        guard let id = workout.id else { return }
        Haptics.light()
        Task { try? await FirestoreService.shared.deleteWorkout(id: id) }
    }

    func history(forExerciseId id: String) -> [(date: Date, bestSet: SetEntry)] {
        FirestoreService.shared.history(forExerciseId: id, workouts: workouts)
    }

    /// Start-of-day dates (in the last `days` days, including today) that had at least one workout.
    func workoutDates(last days: Int) -> Set<Date> {
        let calendar = Calendar.current
        guard let cutoff = calendar.date(byAdding: .day, value: -(days - 1), to: calendar.startOfDay(for: Date())) else {
            return []
        }
        return Set(workouts.compactMap { workout -> Date? in
            let day = calendar.startOfDay(for: workout.startedAt)
            return day >= cutoff ? day : nil
        })
    }

    /// Total volume per day for the last `days` days, oldest first, zero-filled for rest days.
    func dailyVolume(last days: Int) -> [(date: Date, volume: Double)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var volumeByDay: [Date: Double] = [:]
        for workout in workouts {
            let day = calendar.startOfDay(for: workout.startedAt)
            volumeByDay[day, default: 0] += workout.totalVolume
        }
        return (0..<days).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return (date: day, volume: volumeByDay[day] ?? 0)
        }
    }

    /// Total volume per week for the last `weeks` weeks, oldest first.
    func weeklyVolume(weeks: Int) -> [(weekStart: Date, volume: Double)] {
        let calendar = Calendar.current
        guard let thisWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) else {
            return []
        }
        var volumeByWeek: [Date: Double] = [:]
        for workout in workouts {
            guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: workout.startedAt)) else { continue }
            volumeByWeek[weekStart, default: 0] += workout.totalVolume
        }
        return (0..<weeks).reversed().compactMap { offset in
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -offset, to: thisWeekStart) else { return nil }
            return (weekStart: weekStart, volume: volumeByWeek[weekStart] ?? 0)
        }
    }

    /// Total completed-set volume grouped by primary muscle group, largest first.
    func volumeByMuscleGroup() -> [(muscle: MuscleGroup, volume: Double)] {
        var volumeByMuscle: [MuscleGroup: Double] = [:]
        let exercisesById = Dictionary(uniqueKeysWithValues: ExerciseLibrary.all.map { ($0.id, $0) })
        for workout in workouts {
            for exercise in workout.exercises {
                guard let muscle = exercisesById[exercise.exerciseId]?.primaryMuscle else { continue }
                let volume = exercise.sets.filter(\.isCompleted).reduce(0) { $0 + ($1.weight * Double($1.reps)) }
                volumeByMuscle[muscle, default: 0] += volume
            }
        }
        return volumeByMuscle
            .filter { $0.value > 0 }
            .map { (muscle: $0.key, volume: $0.value) }
            .sorted { $0.volume > $1.volume }
    }
}
