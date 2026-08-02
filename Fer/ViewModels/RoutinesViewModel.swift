//
//  RoutinesViewModel.swift
//  Fer
//
//  iOS-only (uses FirebaseFirestore directly, which the Watch target can't
//  import). Whenever the routines list changes, it's also relayed to the
//  Watch via PhoneConnectivityManager so the Watch can start a standalone
//  workout from a routine without querying Firestore itself.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreTarget
import Combine

@MainActor
final class RoutinesViewModel: ObservableObject {
    @Published var routines: [RoutineTemplate] = []
    private var listener: ListenerRegistration?

    init() {
        listener = FirestoreService.shared.routinesListener { [weak self] routines in
            self?.routines = routines
            PhoneConnectivityManager.shared.pushRoutines(routines)
        }
    }

    deinit {
        listener?.remove()
    }

    func save(_ routine: RoutineTemplate) {
        Task {
            try? await FirestoreService.shared.saveRoutine(routine)
        }
    }

    func delete(_ routine: RoutineTemplate) {
        guard let id = routine.id else { return }
        Task {
            try? await FirestoreService.shared.deleteRoutine(id: id)
        }
    }

    func markUsed(_ routine: RoutineTemplate) {
        guard let id = routine.id else { return }
        FirestoreService.shared.markRoutineUsed(id: id)
    }
}
