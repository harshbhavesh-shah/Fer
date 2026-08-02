//
//  LiveActivityManager.swift
//  Fer
//
//  Owns the Lock Screen / Dynamic Island Live Activity for the in-progress
//  workout. No App Group or push entitlement needed — this process starts,
//  updates, and ends the Activity directly while the app is running.
//

import ActivityKit
import Foundation

@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()

    private var activity: Activity<WorkoutActivityAttributes>?

    private init() {}

    func start(routineName: String, contentState: WorkoutActivityAttributes.ContentState) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        end()
        let attributes = WorkoutActivityAttributes(routineName: routineName)
        activity = try? Activity.request(
            attributes: attributes,
            content: .init(state: contentState, staleDate: nil)
        )
    }

    func update(_ contentState: WorkoutActivityAttributes.ContentState) {
        guard let activity else { return }
        Task { await activity.update(.init(state: contentState, staleDate: nil)) }
    }

    func end() {
        guard let activity else { return }
        Task { await activity.end(nil, dismissalPolicy: .immediate) }
        self.activity = nil
    }
}
