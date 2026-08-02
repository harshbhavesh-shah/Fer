//
//  WorkoutDraftStore.swift
//  Fer
//
//  Local autosave for the in-progress workout so a force-quit mid-workout
//  doesn't lose logged sets — the Live Activity survives the app being
//  killed, but without this, the actual session data wouldn't.
//

import Foundation

struct WorkoutDraft: Codable {
    var routineName: String
    var exercises: [LoggedExercise]
    var startedAt: Date
    var restSecondsByExerciseId: [String: Int]
}

enum WorkoutDraftStore {
    private static var fileURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("active_workout_draft.json")
    }

    static func save(_ draft: WorkoutDraft) {
        let dir = fileURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        guard let data = try? JSONEncoder().encode(draft) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    static func load() -> WorkoutDraft? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(WorkoutDraft.self, from: data)
    }

    static func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
