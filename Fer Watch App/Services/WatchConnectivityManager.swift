//
//  WatchConnectivityManager.swift
//  Fer Watch App
//
//  watchOS side of the bridge. The Watch never imports Firebase — that's
//  deliberate, not a limitation we're working around lightly:
//  FirebaseFirestore doesn't ship a watchOS build at all (its networking
//  layer doesn't compile for the platform), so nothing here can touch
//  Firestore directly. Instead:
//
//   - Sign-in state and the routines list are relayed from the iPhone via
//     application context (always-latest, no queueing needed).
//   - While a workout is active on the iPhone, snapshots of it arrive the
//     same way, and actions (set completed, add set...) are sent back with
//     sendMessage.
//   - Workouts logged standalone on the Watch are handed to the phone via
//     transferUserInfo, which queues reliably even if the phone isn't
//     reachable right this second — the phone saves them to Firestore.
//

import Foundation
import WatchConnectivity
import Combine

@MainActor
final class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    @Published var mirrorSnapshot: WorkoutMirrorSnapshot?
    @Published var routines: [RoutineTemplate] = []
    @Published var isPhoneReachable = false

    private var session: WCSession?

    private override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }

    func requestStateIfNeeded() {
        guard let session, session.activationState == .activated, session.isReachable else {
            if !WatchAuthService.shared.isSignedIn {
                WatchAuthService.shared.statusMessage = "Open Fer on your iPhone nearby to sync."
            }
            return
        }
        session.sendMessage(["requestState": true], replyHandler: { [weak self] reply in
            Task { @MainActor in self?.apply(reply) }
        }, errorHandler: { error in
            Task { @MainActor in
                WatchAuthService.shared.statusMessage = "Couldn't reach iPhone: \(error.localizedDescription)"
            }
        })
    }

    /// Sends a mirrored-workout logging action back to the phone (e.g. set
    /// completed) and optimistically applies it locally so the UI feels
    /// instant even before the phone's authoritative snapshot comes back.
    func send(_ action: WatchAction) {
        applyOptimistically(action)
        guard let session, session.isReachable, let data = try? JSONEncoder().encode(action) else { return }
        session.sendMessage(["action": data], replyHandler: nil, errorHandler: nil)
    }

    /// Queues a standalone (Watch-only) workout for the phone to save to
    /// Firestore. transferUserInfo persists across relaunches and delivers
    /// as soon as the phone is reachable, even in the background.
    func sendStandaloneWorkout(_ workout: WorkoutSession) {
        guard let data = try? JSONEncoder().encode(workout) else { return }
        session?.transferUserInfo(["pendingWorkout": data])
    }

    private func applyOptimistically(_ action: WatchAction) {
        guard var snapshot = mirrorSnapshot else { return }
        switch action {
        case .toggleSet(let exerciseIndex, let setIndex):
            guard snapshot.exercises.indices.contains(exerciseIndex),
                  snapshot.exercises[exerciseIndex].sets.indices.contains(setIndex) else { return }
            snapshot.exercises[exerciseIndex].sets[setIndex].isCompleted.toggle()
        case .addSet(let exerciseIndex):
            guard snapshot.exercises.indices.contains(exerciseIndex) else { return }
            snapshot.exercises[exerciseIndex].sets.append(SetEntry())
        case .skipRest:
            snapshot.isResting = false
        case .addRestTime(let seconds):
            snapshot.restRemaining += seconds
        case .finish, .discard:
            mirrorSnapshot = nil
            return
        }
        mirrorSnapshot = snapshot
    }

    private func apply(_ payload: [String: Any]) {
        if let isSignedIn = payload["isSignedIn"] as? Bool {
            let name = payload["displayName"] as? String ?? ""
            WatchAuthService.shared.update(isSignedIn: isSignedIn, displayName: name)
        }
        if let data = payload["routines"] as? Data,
           let decoded = try? JSONDecoder().decode([RoutineTemplate].self, from: data) {
            routines = decoded
        }
        if let data = payload["mirror"] as? Data,
           let snapshot = try? JSONDecoder().decode(WorkoutMirrorSnapshot.self, from: data) {
            mirrorSnapshot = snapshot
        } else if payload["mirror"] == nil {
            mirrorSnapshot = nil
        }
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            self.isPhoneReachable = session.isReachable
            self.requestStateIfNeeded()
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isPhoneReachable = session.isReachable
            self.requestStateIfNeeded()
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            self.apply(applicationContext)
        }
    }
}
