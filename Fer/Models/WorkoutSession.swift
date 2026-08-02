//
//  WorkoutSession.swift
//  Fer
//
//  A completed (or in-progress) logged workout.
//
//  Plain `id` (not @DocumentID) on purpose — shared with the Watch target,
//  which can't import FirebaseFirestore (no watchOS support). FirestoreService
//  assigns `id` manually from the document reference after decoding.
//

import Foundation

struct WorkoutSession: Codable, Identifiable, Hashable {
    var id: String?
    var ownerId: String = ""
    var routineName: String
    var startedAt: Date
    var endedAt: Date?
    var exercises: [LoggedExercise]
    var notes: String = ""

    var duration: TimeInterval {
        (endedAt ?? Date()).timeIntervalSince(startedAt)
    }

    var totalVolume: Double {
        exercises.reduce(0) { partial, ex in
            partial + ex.sets.filter(\.isCompleted).reduce(0) { $0 + ($1.weight * Double($1.reps)) }
        }
    }

    var totalSetsCompleted: Int {
        exercises.reduce(0) { $0 + $1.sets.filter(\.isCompleted).count }
    }

    static func == (lhs: WorkoutSession, rhs: WorkoutSession) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct LoggedExercise: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var exerciseId: String
    var exerciseName: String
    var sets: [SetEntry]
}

struct SetEntry: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var weight: Double = 0
    var reps: Int = 0
    var rpe: Double? = nil
    var isCompleted: Bool = false
    var isWarmup: Bool = false
}
