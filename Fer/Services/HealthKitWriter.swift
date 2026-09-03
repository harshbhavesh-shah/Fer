//
//  HealthKitWriter.swift
//  Fer
//
//  Writes each finished workout to Apple Health as a strength-training
//  HKWorkout, so it shows up in the Health app / Activity rings alongside
//  anything logged by other apps. Separate from HeartRateMonitor, which
//  only *reads* HealthKit's existing heart-rate samples.
//

import Foundation
import HealthKit

@MainActor
final class HealthKitWriter {
    static let shared = HealthKitWriter()

    private let healthStore = HKHealthStore()

    private init() {}

    func save(_ session: WorkoutSession) {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let workoutType = HKObjectType.workoutType()

        healthStore.requestAuthorization(toShare: [workoutType], read: []) { granted, _ in
            guard granted else { return }
            Task { @MainActor in HealthKitWriter.shared.write(session) }
        }
    }

    private func write(_ session: WorkoutSession) {
        let workout = HKWorkout(
            activityType: .traditionalStrengthTraining,
            start: session.startedAt,
            end: session.endedAt ?? Date(),
            workoutEvents: nil,
            totalEnergyBurned: nil,
            totalDistance: nil,
            metadata: [HKMetadataKeyWorkoutBrandName: "Fer"]
        )
        healthStore.save(workout) { _, _ in }
    }
}
