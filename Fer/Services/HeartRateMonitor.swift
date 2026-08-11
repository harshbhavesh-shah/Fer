//
//  HeartRateMonitor.swift
//  Fer
//
//  Reads whatever heart-rate samples HealthKit already has synced from the
//  paired Watch's normal background monitoring — no changes to the Fer
//  Watch App needed, and no dedicated workout session is started on-device.
//

import Foundation
import HealthKit
import Combine

@MainActor
final class HeartRateMonitor: ObservableObject {
    static let shared = HeartRateMonitor()

    @Published private(set) var latestBPM: Int?

    private let healthStore = HKHealthStore()
    private let heartRateType = HKQuantityType(.heartRate)
    private var query: HKAnchoredObjectQuery?

    /// Samples older than this are treated as stale (no live session running).
    private let freshnessWindow: TimeInterval = 60

    private init() {}

    func start() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        healthStore.requestAuthorization(toShare: [], read: [heartRateType]) { [weak self] granted, _ in
            guard granted else { return }
            Task { @MainActor in self?.beginObserving() }
        }
    }

    func stop() {
        if let query { healthStore.stop(query) }
        query = nil
        latestBPM = nil
    }

    private func beginObserving() {
        guard query == nil else { return }
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-freshnessWindow), end: nil)

        let handler: (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void = { [weak self] _, samples, _, _, _ in
            Task { @MainActor in self?.apply(samples) }
        }

        let newQuery = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit,
            resultsHandler: handler
        )
        newQuery.updateHandler = handler
        query = newQuery
        healthStore.execute(newQuery)
    }

    private func apply(_ samples: [HKSample]?) {
        guard let sample = (samples as? [HKQuantitySample])?.last,
              sample.endDate.timeIntervalSinceNow > -freshnessWindow else {
            return
        }
        let unit = HKUnit.count().unitDivided(by: .minute())
        latestBPM = Int(sample.quantity.doubleValue(for: unit).rounded())
    }
}
