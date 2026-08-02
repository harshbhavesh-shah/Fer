//
//  FirestoreService.swift
//  Fer
//
//  All Firestore reads/writes live here. Firestore's SDK persists data
//  locally and syncs automatically, so this also gives us offline support
//  for free across iPhone / iPad / Mac.
//
//  iOS-only — FirebaseFirestore doesn't ship a watchOS build, so the Watch
//  target never imports this file. The Watch app talks to the phone over
//  WatchConnectivity instead (see PhoneConnectivityManager /
//  WatchConnectivityManager), and the phone does the actual Firestore I/O.
//
//  Firestore layout:
//    users/{uid}                                 -> UserProfile
//    users/{uid}/routines/{routineId}             -> RoutineTemplate
//    users/{uid}/workouts/{workoutId}             -> WorkoutSession
//    users/{uid}/customExercises/{exerciseId}     -> Exercise
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

@MainActor
final class FirestoreService: ObservableObject {
    static let shared = FirestoreService()

    private let db = Firestore.firestore()

    private init() {
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings()
        db.settings = settings
    }

    // Reads straight from FirebaseAuth rather than the app's AuthService
    // wrapper so this file can be shared, unmodified, with the Watch target
    // (which has its own auth wrapper but the same underlying Firebase user).
    private var currentUid: String? { Auth.auth().currentUser?.uid }

    private func requireUid() throws -> String {
        guard let uid = currentUid else {
            throw FirestoreError.notSignedIn
        }
        return uid
    }

    enum FirestoreError: LocalizedError {
        case notSignedIn
        var errorDescription: String? {
            switch self {
            case .notSignedIn: return "You need to be signed in to sync data."
            }
        }
    }

    // MARK: - User profile

    func createUserProfile(uid: String, displayName: String, email: String) async throws {
        let profile = UserProfile(displayName: displayName, email: email)
        try db.collection("users").document(uid).setData(from: profile, merge: true)
    }

    func fetchUserProfile() async throws -> UserProfile? {
        let uid = try requireUid()
        let snapshot = try await db.collection("users").document(uid).getDocument()
        var profile = try? snapshot.data(as: UserProfile.self)
        profile?.id = snapshot.documentID
        return profile
    }

    // MARK: - Routines

    func routinesListener(onChange: @escaping ([RoutineTemplate]) -> Void) -> ListenerRegistration? {
        guard let uid = currentUid else { return nil }
        return db.collection("users").document(uid).collection("routines")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, _ in
                let routines = snapshot?.documents.compactMap { doc -> RoutineTemplate? in
                    guard var routine = try? doc.data(as: RoutineTemplate.self) else { return nil }
                    routine.id = doc.documentID
                    return routine
                } ?? []
                onChange(routines)
            }
    }

    func saveRoutine(_ routine: RoutineTemplate) async throws {
        let uid = try requireUid()
        var routine = routine
        routine.ownerId = uid
        let ref: DocumentReference
        if let id = routine.id {
            ref = db.collection("users").document(uid).collection("routines").document(id)
        } else {
            ref = db.collection("users").document(uid).collection("routines").document()
        }
        try ref.setData(from: routine, merge: true)
    }

    func deleteRoutine(id: String) async throws {
        let uid = try requireUid()
        try await db.collection("users").document(uid).collection("routines").document(id).delete()
    }

    func markRoutineUsed(id: String) {
        guard let uid = currentUid else { return }
        db.collection("users").document(uid).collection("routines").document(id)
            .updateData(["lastUsedAt": Timestamp(date: Date())])
    }

    // MARK: - Workouts

    func workoutsListener(onChange: @escaping ([WorkoutSession]) -> Void) -> ListenerRegistration? {
        guard let uid = currentUid else { return nil }
        return db.collection("users").document(uid).collection("workouts")
            .order(by: "startedAt", descending: true)
            .limit(to: 200)
            .addSnapshotListener { snapshot, _ in
                let workouts = snapshot?.documents.compactMap { doc -> WorkoutSession? in
                    guard var workout = try? doc.data(as: WorkoutSession.self) else { return nil }
                    workout.id = doc.documentID
                    return workout
                } ?? []
                onChange(workouts)
            }
    }

    @discardableResult
    func saveWorkout(_ workout: WorkoutSession) async throws -> String {
        let uid = try requireUid()
        var workout = workout
        workout.ownerId = uid
        let ref: DocumentReference
        if let id = workout.id {
            ref = db.collection("users").document(uid).collection("workouts").document(id)
        } else {
            ref = db.collection("users").document(uid).collection("workouts").document()
        }
        try ref.setData(from: workout, merge: true)
        return ref.documentID
    }

    func deleteWorkout(id: String) async throws {
        let uid = try requireUid()
        try await db.collection("users").document(uid).collection("workouts").document(id).delete()
    }

    /// Fetches historical sets for a specific exercise, most recent first, for progress charts.
    func history(forExerciseId exerciseId: String, workouts: [WorkoutSession]) -> [(date: Date, bestSet: SetEntry)] {
        workouts.compactMap { workout -> (Date, SetEntry)? in
            guard let logged = workout.exercises.first(where: { $0.exerciseId == exerciseId }) else { return nil }
            let completed = logged.sets.filter { $0.isCompleted && !$0.isWarmup }
            guard let best = completed.max(by: { $0.weight * Double($0.reps) < $1.weight * Double($1.reps) }) else { return nil }
            return (workout.startedAt, best)
        }
        .sorted { $0.0 < $1.0 }
        .map { (date: $0.0, bestSet: $0.1) }
    }
}
