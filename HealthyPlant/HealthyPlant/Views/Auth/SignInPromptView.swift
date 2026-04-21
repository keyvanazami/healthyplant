import SwiftUI

struct SignInPromptView: View {
    @EnvironmentObject var authService: AuthService
    @Binding var isPresented: Bool
    @State private var isSigningIn = false
    @State private var errorMessage: String?
    @State private var showEmailAuth = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Theme.accent.opacity(0.12))
                        .frame(width: 120, height: 120)
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .font(.system(size: 50))
                        .foregroundColor(Theme.accent)
                }

                VStack(spacing: 10) {
                    Text("Sign In to Sync")
                        .font(.title2.weight(.bold))
                        .foregroundColor(Theme.textPrimary)

                    Text("Keep your plants, care history, and settings safe across devices. You can always do this later in Settings.")
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 32)
                }

                Spacer()

                VStack(spacing: 12) {
                    // Google
                    Button {
                        Task { await signInWithGoogle() }
                    } label: {
                        HStack(spacing: 10) {
                            if isSigningIn {
                                ProgressView().tint(.black)
                            } else {
                                Image(systemName: "g.circle.fill")
                                    .font(.system(size: 20))
                                Text("Continue with Google")
                            }
                        }
                        .font(.body.weight(.semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.accent)
                        .cornerRadius(14)
                    }
                    .disabled(isSigningIn)

                    // Email / Password
                    Button {
                        showEmailAuth = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 18))
                            Text("Continue with Email")
                        }
                        .font(.body.weight(.semibold))
                        .foregroundColor(Theme.accent)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.clear)
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.accent, lineWidth: 1.5))
                    }

                    Button {
                        isPresented = false
                    } label: {
                        Text("Skip for now")
                            .font(.subheadline)
                            .foregroundColor(Theme.textSecondary)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
        .fullScreenCover(isPresented: $showEmailAuth) {
            EmailAuthView(isPresented: $showEmailAuth, onSuccess: {
                isPresented = false
            })
            .environmentObject(authService)
        }
    }

    private func signInWithGoogle() async {
        isSigningIn = true
        errorMessage = nil
        do {
            try await authService.signInWithGoogle()
            isPresented = false
        } catch {
            errorMessage = error.localizedDescription
        }
        isSigningIn = false
    }
}
