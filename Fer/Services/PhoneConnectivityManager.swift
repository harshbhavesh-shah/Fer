//
//  PhoneConnectivityManager.swift
//  Fer
//
//  iPhone side of the iPhone <-> Watch bridge. The Watch never talks to
//  Firebase directly (FirebaseFirestore has no watchOS build), so this is
//  the only thing that does — everything the Watch needs is relayed
//  through here, and everything the Watch produces comes back through here
//  too:
//
//   1. Relays sign-in state (just a bool + display name — never the
//      password) so the Watch shows the right screen without its own login.
//   2. Pushes the current routines list so the Watch can start a workout
//      from one without querying Firestore itself.
//   3. Mirrors whatever workout is active on the phone to the Watch, and
//      applies back any logging actions (set completed, add set, skip
//      rest...) made from the wrist.
//   4. Receives workouts logged standalone on the Watch (phone unreachable
//      at the time) via transferUserInfo, and saves them to Firestore here.
//

import Foundation
import WatchConnectivity
import FirebaseAuth
import Combine

@MainActor
final class PhoneConnectivityManager: NSObject, ObservableObject {
    let objectWillChange = ObservableObjectPublisher()

    static let shared = PhoneConnectivityManager()

    private weak var activeWorkout: WorkoutSessionViewModel?
    private var session: WCSession?
    private var latestRoutines: [RoutineTemplate] = []

    private override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }

    // MARK: - Active workout hookup

    func attach(_ viewModel: WorkoutSessionViewModel) {
        activeWorkout = viewModel
        pushMirror(viewModel.snapshot)
    }

    func detach() {
        activeWorkout = nil
        pushMirror(nil)
    }

    func pushMirror(_ snapshot: WorkoutMirrorSnapshot?) {
        updateContext { context in
            if let snapshot, let data = try? JSONEncoder().encode(snapshot) {
                context["mirror"] = data
            } else {
                context.removeValue(forKey: "mirror")
            }
        }
    }

    // MARK: - Sign-in state relay

    func pushSignInState(isSignedIn: Bool, displayName: String?) {
        updateContext { context in
            context["isSignedIn"] = isSignedIn
            context["displayName"] = displayName ?? ""
        }
    }

    // MARK: - Routines relay

    func pushRoutines(_ routines: [RoutineTemplate]) {
        latestRoutines = routines
        updateContext { context in
            if let data = try? JSONEncoder().encode(routines) {
                context["routines"] = data
            }
        }
    }

    // MARK: - Context helper

    /// Application context always holds the *latest* full state (Watch
    /// Connectivity replaces rather than queues it), so every push merges
    /// into whatever was there before instead of overwriting other keys.
    private func updateContext(_ mutate: (inout [String: Any]) -> Void) {
        guard let session, session.activationState == .activated, session.isPaired, session.isWatchAppInstalled else { return }
        var context = (try? session.applicationContext) ?? [:]
        mutate(&context)
        try? session.updateApplicationContext(context)
    }

    private func currentStatePayload() -> [String: Any] {
        var payload: [String: Any] = [
            "isSignedIn": AuthService.shared.isSignedIn,
            "displayName": AuthService.shared.currentUser?.displayName ?? ""
        ]
        if let data = try? JSONEncoder().encode(latestRoutines) {
            payload["routines"] = data
        }
        return payload
    }

    // MARK: - Receiving from Watch

    private func handleStandaloneWorkout(_ data: Data) {
        guard let workout = try? JSONDecoder().decode(WorkoutSession.self, from: data) else { return }
        Task {
            try? await FirestoreService.shared.saveWorkout(workout)
        }
    }
}

extension PhoneConnectivityManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            self.pushSignInState(isSignedIn: AuthService.shared.isSignedIn, displayName: AuthService.shared.currentUser?.displayName)
            self.pushRoutines(self.latestRoutines)
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) { session.activate() }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        Task { @MainActor in
            if message["requestState"] as? Bool == true {
                replyHandler(self.currentStatePayload())
                return
            }
            if let data = message["action"] as? Data, let action = try? JSONDecoder().decode(WatchAction.self, from: data) {
                self.activeWorkout?.apply(action)
            }
            replyHandler([:])
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        Task { @MainActor in
            if let data = userInfo["pendingWorkout"] as? Data {
                self.handleStandaloneWorkout(data)
            }
        }
    }
}
