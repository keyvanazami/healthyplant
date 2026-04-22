import SwiftUI

struct EmailAuthView: View {
    @EnvironmentObject var authService: AuthService
    @Binding var isPresented: Bool
    var onSuccess: (() -> Void)? = nil
    var onSignedIn: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    enum Mode { case signIn, signUp }
    @State private var mode: Mode = .signIn

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var displayName = ""

    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showForgotPassword = false
    @State private var resetEmail = ""
    @State private var resetSent = false
    @State private var resetLoading = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Theme.accent.opacity(0.12))
                                .frame(width: 80, height: 80)
                            Image(systemName: "envelope.badge.shield.half.filled")
                                .font(.system(size: 34))
                                .foregroundColor(Theme.accent)
                        }
                        .padding(.top, 48)

                        Text(mode == .signIn ? "Welcome back" : "Create account")
                            .font(.title2.weight(.bold))
                            .foregroundColor(Theme.textPrimary)

                        Text(mode == .signIn
                             ? "Sign in to sync your plants across devices."
                             : "Sign up to keep your plants safe across devices.")
                            .font(.subheadline)
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    // Mode toggle
                    HStack(spacing: 0) {
                        modeTab("Sign In", selected: mode == .signIn) { mode = .signIn; clearFields() }
                        modeTab("Sign Up", selected: mode == .signUp) { mode = .signUp; clearFields() }
                    }
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 32)

                    // Form fields
                    VStack(spacing: 14) {
                        if mode == .signUp {
                            authField(icon: "person", placeholder: "Display name (optional)", text: $displayName)
                        }

                        authField(icon: "envelope", placeholder: "Email address", text: $email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)

                        secureField(icon: "lock", placeholder: "Password (8+ characters)", text: $password)

                        if mode == .signUp {
                            secureField(icon: "lock.fill", placeholder: "Confirm password", text: $confirmPassword)
                        }

                        if mode == .signIn {
                            HStack {
                                Spacer()
                                Button("Forgot password?") {
                                    resetEmail = email
                                    showForgotPassword = true
                                }
                                .font(.caption)
                                .foregroundColor(Theme.accent)
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                    .padding(.horizontal, 32)

                    // Error
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }

                    // Submit
                    Button {
                        Task { await submit() }
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView().tint(.black)
                            } else {
                                Text(mode == .signIn ? "Sign In" : "Create Account")
                                    .font(.body.weight(.semibold))
                            }
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.accent)
                        .cornerRadius(14)
                    }
                    .disabled(isLoading)
                    .padding(.horizontal, 32)

                    // Back
                    Button {
                        dismiss()
                    } label: {
                        Text("Back")
                            .font(.subheadline)
                            .foregroundColor(Theme.textSecondary)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showForgotPassword) {
            forgotPasswordSheet
        }
    }

    // MARK: - Forgot Password Sheet

    private var forgotPasswordSheet: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 24) {
                Text("Reset Password")
                    .font(.title3.weight(.bold))
                    .foregroundColor(Theme.textPrimary)
                    .padding(.top, 32)

                if resetSent {
                    VStack(spacing: 12) {
                        Image(systemName: "envelope.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(Theme.accent)
                        Text("Check your inbox")
                            .font(.headline)
                            .foregroundColor(Theme.textPrimary)
                        Text("We sent a password reset link to \(resetEmail).")
                            .font(.subheadline)
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 32)
                } else {
                    VStack(spacing: 14) {
                        Text("Enter your email and we'll send you a reset link.")
                            .font(.subheadline)
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)

                        authField(icon: "envelope", placeholder: "Email address", text: $resetEmail)
                            .padding(.horizontal, 32)

                        Button {
                            Task { await sendReset() }
                        } label: {
                            HStack {
                                if resetLoading { ProgressView().tint(.black) }
                                else { Text("Send Reset Link").font(.body.weight(.semibold)) }
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.accent)
                            .cornerRadius(14)
                        }
                        .disabled(resetLoading || resetEmail.isEmpty)
                        .padding(.horizontal, 32)
                    }
                }

                Button("Close") { showForgotPassword = false }
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
                    .padding(.bottom, 32)
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Actions

    private func submit() async {
        errorMessage = nil
        guard validate() else { return }
        isLoading = true
        do {
            if mode == .signIn {
                try await authService.signInWithEmail(email: email.trimmingCharacters(in: .whitespaces),
                                                      password: password)
                onSignedIn?()
            } else {
                try await authService.signUpWithEmail(email: email.trimmingCharacters(in: .whitespaces),
                                                      password: password,
                                                      displayName: displayName.trimmingCharacters(in: .whitespaces))
            }
            dismiss()
            onSuccess?()
        } catch {
            errorMessage = friendlyError(error)
        }
        isLoading = false
    }

    private func sendReset() async {
        resetLoading = true
        do {
            try await authService.sendPasswordReset(email: resetEmail.trimmingCharacters(in: .whitespaces))
            resetSent = true
        } catch {
            // show error inline
        }
        resetLoading = false
    }

    private func validate() -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        guard trimmedEmail.contains("@"), trimmedEmail.contains(".") else {
            errorMessage = "Please enter a valid email address."
            return false
        }
        guard password.count >= 8 else {
            errorMessage = "Password must be at least 8 characters."
            return false
        }
        if mode == .signUp {
            guard password == confirmPassword else {
                errorMessage = "Passwords don't match."
                return false
            }
        }
        return true
    }

    private func clearFields() {
        password = ""
        confirmPassword = ""
        errorMessage = nil
    }

    // MARK: - Helpers

    private func friendlyError(_ error: Error) -> String {
        let msg = error.localizedDescription
        if msg.contains("email address is already in use") {
            return "An account with this email already exists. Try signing in instead."
        } else if msg.contains("no user record") || msg.contains("wrong password") || msg.contains("invalid credential") {
            return "Incorrect email or password."
        } else if msg.contains("badly formatted") {
            return "Please enter a valid email address."
        } else if msg.contains("network") {
            return "Network error. Check your connection and try again."
        }
        return msg
    }

    @ViewBuilder
    private func modeTab(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(selected ? .semibold : .regular))
                .foregroundColor(selected ? .black : Theme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(selected ? Theme.accent : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(3)
    }

    @ViewBuilder
    private func authField(icon: String, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(Theme.textSecondary)
                .frame(width: 20)
            TextField(placeholder, text: text)
                .foregroundColor(Theme.textPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        }
        .padding(14)
        .background(Color.white.opacity(0.07))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.12), lineWidth: 1))
    }

    @ViewBuilder
    private func secureField(icon: String, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(Theme.textSecondary)
                .frame(width: 20)
            SecureField(placeholder, text: text)
                .foregroundColor(Theme.textPrimary)
        }
        .padding(14)
        .background(Color.white.opacity(0.07))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.12), lineWidth: 1))
    }
}
