//
//  AuthView.swift
//  Fer
//
//  Sign in / sign up screen. Using the same Firebase account across
//  iPhone, iPad, Mac, and Watch is what keeps workout data in sync.
//

import SwiftUI

struct AuthView: View {
    @StateObject private var auth = AuthService.shared
    @State private var isSignUp = false
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isSubmitting = false
    @FocusState private var focusedField: Field?

    enum Field { case name, email, password }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 8) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 52))
                            .foregroundStyle(Theme.accent)
                            .symbolEffect(.bounce, value: isSignUp)
                        Text("Fer")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                        Text(isSignUp ? "Create your account" : "Welcome back")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)

                    VStack(spacing: 14) {
                        if isSignUp {
                            FieldBox(icon: "person.fill", placeholder: "Name", text: $name)
                                .focused($focusedField, equals: .name)
                        }
                        FieldBox(icon: "envelope.fill", placeholder: "Email", text: $email, keyboard: .emailAddress)
                            .focused($focusedField, equals: .email)
                        FieldBox(icon: "lock.fill", placeholder: "Password", text: $password, isSecure: true)
                            .focused($focusedField, equals: .password)
                    }

                    if let error = auth.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .transition(.opacity)
                    }

                    Button {
                        Task { await submit() }
                    } label: {
                        if isSubmitting {
                            ProgressView().tint(.white)
                        } else {
                            Text(isSignUp ? "Sign Up" : "Sign In")
                        }
                    }
                    .buttonStyle(.primaryAction())
                    .opacity(isSubmitting ? 0.7 : 1.0)
                    .allowsHitTesting(!isSubmitting)

                    Button {
                        Haptics.selection()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isSignUp.toggle()
                            auth.errorMessage = nil
                        }
                    } label: {
                        Text(isSignUp ? "Already have an account? Sign In" : "New here? Create an account")
                            .font(.subheadline)
                    }
                }
                .padding(24)
            }
        }
        .onTapGesture { focusedField = nil }
    }

    private func submit() async {
        focusedField = nil
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty,
              !password.isEmpty else {
            auth.errorMessage = "Enter an email and password first."
            Haptics.warning()
            return
        }
        isSubmitting = true
        defer { isSubmitting = false }
        if isSignUp {
            await auth.signUp(email: email, password: password, displayName: name.isEmpty ? "Athlete" : name)
        } else {
            await auth.signIn(email: email, password: password)
        }
        if auth.errorMessage == nil { Haptics.success() } else { Haptics.error() }
    }
}

private struct FieldBox: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var isSecure: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboard)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(RoundedRectangle(cornerRadius: 14).fill(.regularMaterial))
    }
}

#Preview {
    AuthView()
}
