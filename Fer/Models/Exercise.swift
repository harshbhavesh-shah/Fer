//
//  Exercise.swift
//  Fer
//
//  Represents a single exercise definition in the library (not a logged set).
//

import Foundation

struct Exercise: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var primaryMuscle: MuscleGroup
    var secondaryMuscles: [MuscleGroup]
    var equipment: Equipment
    var isCustom: Bool = false
    var instructions: String? = nil

    /// Which fields make sense to log for this exercise.
    var trackingType: TrackingType = .weightReps

    enum TrackingType: String, Codable {
        case weightReps      // e.g. Bench Press: weight x reps
        case bodyweightReps  // e.g. Pull Up: reps only (optional added weight)
        case time            // e.g. Plank: duration
        case distanceTime    // e.g. Running: distance + duration
    }
}
