//
//  MuscleGroup.swift
//  Fer
//
//  Core taxonomy used to categorize exercises.
//

import SwiftUI

enum MuscleGroup: String, Codable, CaseIterable, Identifiable {
    case chest, back, shoulders, biceps, triceps, forearms
    case abs, quads, hamstrings, glutes, calves, cardio, fullBody

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .chest: return "Chest"
        case .back: return "Back"
        case .shoulders: return "Shoulders"
        case .biceps: return "Biceps"
        case .triceps: return "Triceps"
        case .forearms: return "Forearms"
        case .abs: return "Abs"
        case .quads: return "Quads"
        case .hamstrings: return "Hamstrings"
        case .glutes: return "Glutes"
        case .calves: return "Calves"
        case .cardio: return "Cardio"
        case .fullBody: return "Full Body"
        }
    }

    var icon: String {
        switch self {
        case .chest: return "figure.strengthtraining.traditional"
        case .back: return "figure.rower"
        case .shoulders: return "figure.arms.open"
        case .biceps, .triceps, .forearms: return "dumbbell.fill"
        case .abs: return "figure.core.training"
        case .quads, .hamstrings, .glutes: return "figure.squat"
        case .calves: return "figure.step.training"
        case .cardio: return "heart.fill"
        case .fullBody: return "figure.mixed.cardio"
        }
    }

    var accentColor: Color {
        switch self {
        case .chest: return .red
        case .back: return .blue
        case .shoulders: return .orange
        case .biceps, .triceps, .forearms: return .purple
        case .abs: return .yellow
        case .quads, .hamstrings, .glutes: return .green
        case .calves: return .mint
        case .cardio: return .pink
        case .fullBody: return .teal
        }
    }
}

enum Equipment: String, Codable, CaseIterable, Identifiable {
    case barbell, dumbbell, machine, cable, bodyweight, kettlebell, band, other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .barbell: return "Barbell"
        case .dumbbell: return "Dumbbell"
        case .machine: return "Machine"
        case .cable: return "Cable"
        case .bodyweight: return "Bodyweight"
        case .kettlebell: return "Kettlebell"
        case .band: return "Band"
        case .other: return "Other"
        }
    }
}
