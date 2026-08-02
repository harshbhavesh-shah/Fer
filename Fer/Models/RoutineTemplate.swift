//
//  RoutineTemplate.swift
//  Fer
//
//  A saved workout plan (e.g. "Push Day") the user can start from.
//
//  Plain `id` (not @DocumentID) on purpose — this file is shared with the
//  Watch target, and FirebaseFirestore doesn't support watchOS, so nothing
//  here can import it. FirestoreService assigns `id` manually from the
//  document reference after decoding instead.
//

import Foundation

struct RoutineTemplate: Codable, Identifiable, Hashable {
    var id: String?
    var name: String
    var iconName: String = "list.bullet.rectangle"
    var exercises: [RoutineExercise]
    var createdAt: Date = Date()
    var lastUsedAt: Date? = nil
    var ownerId: String = ""

    static func == (lhs: RoutineTemplate, rhs: RoutineTemplate) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct RoutineExercise: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var exerciseId: String
    var exerciseName: String
    var targetSets: Int = 3
    var targetReps: Int = 10
    var restSeconds: Int = 90
    var notes: String = ""
}
