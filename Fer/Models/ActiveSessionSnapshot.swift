//
//  ActiveSessionSnapshot.swift
//  Fer
//
//  The cross-device live-workout document, shared between iOS and Android
//  via Firestore at users/{uid}/activeSession/current — the cloud analog of
//  WorkoutMirrorSnapshot (which only reaches the paired Watch over
//  WatchConnectivity). Whichever device is active writes the complete state
//  here; `updatedAt` is what lets each side tell its own echo apart from a
//  genuine edit from the other device (see WorkoutSessionViewModel's
//  lastPushedUpdatedAt / applyRemoteSnapshot).
//

import Foundation

struct ActiveSessionSnapshot: Codable, Equatable {
    var routineName: String
    var exercises: [LoggedExercise]
    var startedAt: Date
    var isResting: Bool
    var restEndDate: Date?
    var restSecondsByExerciseId: [String: Int]
    var weightUnitRaw: String
    var updatedAt: Date
}
