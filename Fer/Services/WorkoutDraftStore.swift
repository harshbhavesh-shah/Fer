//
//  WorkoutDraftStore.swift
//  Fer
//
//  Local autosave for the in-progress workout so a force-quit mid-workout
//  doesn't lose logged sets — the Live Activity survives the app being
//  killed, but without this, the actual session data wouldn't.
//
//  Lives in the shared App Group container (not the app's own sandboxed
//  Application Support directory) so the FerLiveActivity extension's
//  CompleteSetIntent can read and write the same file when the user taps
//  the Lock Screen checkmark — that's the only way a completion made while
//  the app is suspended (or not running) can survive to be picked up again
//  next time the app is foregrounded.
//

import Foundation

struct WorkoutDraft: Codable {
    var routineName: String
    var exercises: [LoggedExercise]
    var startedAt: Date
    var restSecondsByExerciseId: [String: Int]
    /// UserProfile.WeightUnit.rawValue — carried here (rather than read from
    /// UserDefaults) so CompleteSetIntent can format a set's summary without
    /// needing an App Group UserDefaults suite of its own.
    var weightUnitRaw: String = "lb"
}

enum WorkoutDraftStore {
    static let appGroupID = "group.com.Harshbshah.Fer"

    private static var fileURL: URL {
        let base = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
            ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("active_workout_draft.json")
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
