//
//  AuthService.swift
//  Fer
//
//  Wraps Firebase Auth for the iPhone/iPad/Mac targets. The Watch never
//  holds its own Firebase session or password — it only learns whether
//  you're signed in via PhoneConnectivityManager, which relays just a
//  boolean + display name (never the password) over WatchConnectivity.
//

import Foundation
import FirebaseAuth
import Combine

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var currentUser: FirebaseAuth.User?
    @Published var isLoading = true
    @Published var errorMessage: String?

    private var handle: AuthStateDidChangeListenerHandle?

    private init() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
            self?.isLoading = false
            PhoneConnectivityManager.shared.pushSignInState(isSignedIn: user != nil, displayName: user?.displayName)
        }
    }

    deinit {
        if let handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    var isSignedIn: Bool { currentUser != nil }
    var uid: String? { currentUser?.uid }

    func signIn(email: String, password: String) async {
        errorMessage = nil
        do {
            _ = try await Auth.auth().signIn(withEmail: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signUp(email: String, password: String, displayName: String) async {
        errorMessage = nil
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try await changeRequest.commitChanges()
            try await FirestoreService.shared.createUserProfile(
                uid: result.user.uid,
                displayName: displayName,
                email: email
            )
            PhoneConnectivityManager.shared.pushSignInState(isSignedIn: true, displayName: displayName)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() {
        try? Auth.auth().signOut()
    }

    func resetPassword(email: String) async {
        errorMessage = nil
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
