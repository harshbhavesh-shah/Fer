//
//  ExerciseLibrary.swift
//  Fer
//
//  Built-in seed exercise list. Loaded locally (no network needed) so the
//  library always works offline; user custom exercises get merged in from Firestore.
//

import Foundation

enum ExerciseLibrary {
    static let all: [Exercise] = [
        // Chest
        ex("Barbell Bench Press", .chest, [.triceps, .shoulders], .barbell),
        ex("Incline Barbell Bench Press", .chest, [.shoulders, .triceps], .barbell),
        ex("Dumbbell Bench Press", .chest, [.triceps, .shoulders], .dumbbell),
        ex("Incline Dumbbell Press", .chest, [.shoulders, .triceps], .dumbbell),
        ex("Cable Fly", .chest, [], .cable),
        ex("Push Up", .chest, [.triceps, .abs], .bodyweight, .bodyweightReps),
        ex("Chest Dip", .chest, [.triceps], .bodyweight, .bodyweightReps),
        ex("Machine Chest Press", .chest, [.triceps], .machine),

        // Back
        ex("Deadlift", .back, [.hamstrings, .glutes, .forearms], .barbell),
        ex("Pull Up", .back, [.biceps], .bodyweight, .bodyweightReps),
        ex("Chin Up", .back, [.biceps], .bodyweight, .bodyweightReps),
        ex("Lat Pulldown", .back, [.biceps], .cable),
        ex("Barbell Row", .back, [.biceps], .barbell),
        ex("Dumbbell Row", .back, [.biceps], .dumbbell),
        ex("Seated Cable Row", .back, [.biceps], .cable),
        ex("T-Bar Row", .back, [.biceps], .barbell),

        // Shoulders
        ex("Overhead Press", .shoulders, [.triceps], .barbell),
        ex("Dumbbell Shoulder Press", .shoulders, [.triceps], .dumbbell),
        ex("Lateral Raise", .shoulders, [], .dumbbell),
        ex("Front Raise", .shoulders, [], .dumbbell),
        ex("Rear Delt Fly", .shoulders, [.back], .dumbbell),
        ex("Face Pull", .shoulders, [.back], .cable),
        ex("Arnold Press", .shoulders, [.triceps], .dumbbell),

        // Arms
        ex("Barbell Curl", .biceps, [.forearms], .barbell),
        ex("Dumbbell Curl", .biceps, [.forearms], .dumbbell),
        ex("Hammer Curl", .biceps, [.forearms], .dumbbell),
        ex("Preacher Curl", .biceps, [], .barbell),
        ex("Cable Curl", .biceps, [], .cable),
        ex("Tricep Pushdown", .triceps, [], .cable),
        ex("Skull Crusher", .triceps, [], .barbell),
        ex("Overhead Tricep Extension", .triceps, [], .dumbbell),
        ex("Close Grip Bench Press", .triceps, [.chest], .barbell),
        ex("Wrist Curl", .forearms, [], .dumbbell),

        // Legs
        ex("Barbell Back Squat", .quads, [.glutes, .hamstrings], .barbell),
        ex("Front Squat", .quads, [.glutes], .barbell),
        ex("Leg Press", .quads, [.glutes, .hamstrings], .machine),
        ex("Walking Lunge", .quads, [.glutes], .dumbbell),
        ex("Leg Extension", .quads, [], .machine),
        ex("Romanian Deadlift", .hamstrings, [.glutes, .back], .barbell),
        ex("Leg Curl", .hamstrings, [], .machine),
        ex("Hip Thrust", .glutes, [.hamstrings], .barbell),
        ex("Bulgarian Split Squat", .quads, [.glutes], .dumbbell),
        ex("Standing Calf Raise", .calves, [], .machine),
        ex("Seated Calf Raise", .calves, [], .machine),

        // Abs
        ex("Plank", .abs, [], .bodyweight, .time),
        ex("Hanging Leg Raise", .abs, [], .bodyweight, .bodyweightReps),
        ex("Cable Crunch", .abs, [], .cable),
        ex("Ab Wheel Rollout", .abs, [], .other),
        ex("Sit Up", .abs, [], .bodyweight, .bodyweightReps),
        ex("Russian Twist", .abs, [], .bodyweight, .bodyweightReps),

        // Cardio / full body
        ex("Treadmill Run", .cardio, [], .other, .distanceTime),
        ex("Rowing Machine", .cardio, [.back], .machine, .distanceTime),
        ex("Stationary Bike", .cardio, [.quads], .machine, .distanceTime),
        ex("Kettlebell Swing", .fullBody, [.glutes, .back], .kettlebell),
        ex("Burpee", .fullBody, [], .bodyweight, .bodyweightReps),
        ex("Farmer's Carry", .fullBody, [.forearms], .dumbbell, .distanceTime),
    ]

    private static func ex(
        _ name: String,
        _ primary: MuscleGroup,
        _ secondary: [MuscleGroup],
        _ equipment: Equipment,
        _ tracking: Exercise.TrackingType = .weightReps
    ) -> Exercise {
        Exercise(
            id: name.lowercased().replacingOccurrences(of: " ", with: "-").replacingOccurrences(of: "'", with: ""),
            name: name,
            primaryMuscle: primary,
            secondaryMuscles: secondary,
            equipment: equipment,
            trackingType: tracking
        )
    }

    static func byId(_ id: String) -> Exercise? {
        all.first { $0.id == id }
    }
}
