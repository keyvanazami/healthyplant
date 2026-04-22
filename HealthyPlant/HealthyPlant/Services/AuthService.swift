import Foundation
import FirebaseAuth
import GoogleSignIn
import AuthenticationServices
import CryptoKit

@MainActor
final class AuthService: ObservableObject {
    @Published var userId: String
    @Published var isAuthenticated: Bool
    @Published var isGoogleLinked: Bool = false
    @Published var isEmailLinked: Bool = false
    @Published var isAppleLinked: Bool = false
    @Published var displayName: String?
    @Published var email: String?
    @Published var photoURL: URL?

    private static let userIdKey = "hp_user_id"
    private static let anonIdKey = "hp_anonymous_id"

    /// True if the user has a real account (Google or email/password), not anonymous.
    var isAccountLinked: Bool { isGoogleLinked || isEmailLinked || isAppleLinked }

    init() {
        if let firebaseUser = Auth.auth().currentUser {
            self.userId = firebaseUser.uid
            self.isAuthenticated = true
            self.isGoogleLinked = firebaseUser.providerData.contains { $0.providerID == "google.com" }
            self.isEmailLinked = firebaseUser.providerData.contains { $0.providerID == "password" }
            self.isAppleLinked = firebaseUser.providerData.contains { $0.providerID == "apple.com" }
            self.displayName = firebaseUser.displayName
            self.email = firebaseUser.email
            self.photoURL = firebaseUser.photoURL
            UserDefaults.standard.set(firebaseUser.uid, forKey: Self.userIdKey)
        } else if let stored = UserDefaults.standard.string(forKey: Self.userIdKey) {
            self.userId = stored
            self.isAuthenticated = true
        } else {
            let newId = UUID().uuidString
            UserDefaults.standard.set(newId, forKey: Self.userIdKey)
            UserDefaults.standard.set(newId, forKey: Self.anonIdKey)
            self.userId = newId
            self.isAuthenticated = true
        }
    }

    /// The anonymous user ID before sign-in (for data migration)
    var anonymousId: String? {
        UserDefaults.standard.string(forKey: Self.anonIdKey)
    }

    /// Get a Firebase ID token for API auth
    func getAuthToken() async -> String? {
        guard let user = Auth.auth().currentUser else { return nil }
        return try? await user.getIDToken()
    }

    var hasGoogleAccount: Bool { isGoogleLinked }

    // MARK: - Google Sign-In

    func signInWithGoogle() async throws {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootVC = window.rootViewController else {
            throw AuthError.noRootViewController
        }

        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        let oldAnonId = UserDefaults.standard.string(forKey: Self.userIdKey)

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: topVC)
        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.missingToken
        }

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )

        let authResult = try await Auth.auth().signIn(with: credential)
        let firebaseUser = authResult.user

        if let oldId = oldAnonId, oldId != firebaseUser.uid {
            UserDefaults.standard.set(oldId, forKey: Self.anonIdKey)
        }

        userId = firebaseUser.uid
        isAuthenticated = true
        isGoogleLinked = true
        isEmailLinked = false
        displayName = firebaseUser.displayName
        email = firebaseUser.email
        photoURL = firebaseUser.photoURL
        UserDefaults.standard.set(firebaseUser.uid, forKey: Self.userIdKey)

        if let oldId = oldAnonId, oldId != firebaseUser.uid {
            await migrateData(from: oldId, to: firebaseUser.uid)
        }
    }

    // MARK: - Email / Password Sign-Up

    func signUpWithEmail(email: String, password: String, displayName: String) async throws {
        let oldAnonId = UserDefaults.standard.string(forKey: Self.userIdKey)

        let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
        let firebaseUser = authResult.user

        // Set display name
        let changeRequest = firebaseUser.createProfileChangeRequest()
        changeRequest.displayName = displayName.isEmpty ? email.components(separatedBy: "@").first : displayName
        try? await changeRequest.commitChanges()

        if let oldId = oldAnonId, oldId != firebaseUser.uid {
            UserDefaults.standard.set(oldId, forKey: Self.anonIdKey)
        }

        userId = firebaseUser.uid
        isAuthenticated = true
        isEmailLinked = true
        isGoogleLinked = false
        self.displayName = firebaseUser.displayName ?? displayName
        self.email = firebaseUser.email
        self.photoURL = nil
        UserDefaults.standard.set(firebaseUser.uid, forKey: Self.userIdKey)

        if let oldId = oldAnonId, oldId != firebaseUser.uid {
            await migrateData(from: oldId, to: firebaseUser.uid)
        }
    }

    // MARK: - Email / Password Sign-In

    func signInWithEmail(email: String, password: String) async throws {
        let oldAnonId = UserDefaults.standard.string(forKey: Self.userIdKey)

        let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
        let firebaseUser = authResult.user

        if let oldId = oldAnonId, oldId != firebaseUser.uid {
            UserDefaults.standard.set(oldId, forKey: Self.anonIdKey)
        }

        userId = firebaseUser.uid
        isAuthenticated = true
        isEmailLinked = true
        isGoogleLinked = firebaseUser.providerData.contains { $0.providerID == "google.com" }
        self.displayName = firebaseUser.displayName
        self.email = firebaseUser.email
        self.photoURL = firebaseUser.photoURL
        UserDefaults.standard.set(firebaseUser.uid, forKey: Self.userIdKey)

        if let oldId = oldAnonId, oldId != firebaseUser.uid {
            await migrateData(from: oldId, to: firebaseUser.uid)
        }
    }

    // MARK: - Password Reset

    func sendPasswordReset(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    // MARK: - Sign Out

    func signOut() {
        try? Auth.auth().signOut()
        GIDSignIn.sharedInstance.signOut()

        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: Self.userIdKey)
        UserDefaults.standard.set(newId, forKey: Self.anonIdKey)

        userId = newId
        isAuthenticated = true
        isGoogleLinked = false
        isEmailLinked = false
        isAppleLinked = false
        displayName = nil
        email = nil
        photoURL = nil
    }

    // MARK: - Apple Sign-In

    func handleAppleSignIn(authorization: ASAuthorization, nonce: String) async throws {
        guard let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = appleCredential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8) else {
            throw AuthError.missingToken
        }

        let oldAnonId = UserDefaults.standard.string(forKey: Self.userIdKey)

        let firebaseCredential = OAuthProvider.appleCredential(
            withIDToken: idToken,
            rawNonce: nonce,
            fullName: appleCredential.fullName
        )
        let authResult = try await Auth.auth().signIn(with: firebaseCredential)
        let firebaseUser = authResult.user

        // Apple only provides the name on first sign-in
        let fullName = [appleCredential.fullName?.givenName, appleCredential.fullName?.familyName]
            .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
        if !fullName.isEmpty && (firebaseUser.displayName == nil || firebaseUser.displayName!.isEmpty) {
            let changeRequest = firebaseUser.createProfileChangeRequest()
            changeRequest.displayName = fullName
            try? await changeRequest.commitChanges()
        }

        if let oldId = oldAnonId, oldId != firebaseUser.uid {
            UserDefaults.standard.set(oldId, forKey: Self.anonIdKey)
        }

        userId = firebaseUser.uid
        isAuthenticated = true
        isAppleLinked = true
        isGoogleLinked = firebaseUser.providerData.contains { $0.providerID == "google.com" }
        isEmailLinked = firebaseUser.providerData.contains { $0.providerID == "password" }
        displayName = firebaseUser.displayName ?? (fullName.isEmpty ? nil : fullName)
        email = firebaseUser.email ?? appleCredential.email
        photoURL = firebaseUser.photoURL
        UserDefaults.standard.set(firebaseUser.uid, forKey: Self.userIdKey)

        if let oldId = oldAnonId, oldId != firebaseUser.uid {
            await migrateData(from: oldId, to: firebaseUser.uid)
        }
    }

    // MARK: - Apple Nonce Helpers (static so views can use them)

    static func randomNonceString(length: Int = 32) -> String {
        var randomBytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .compactMap { String(format: "%02x", $0) }
            .joined()
    }

    // MARK: - Data Migration

    private func migrateData(from oldUserId: String, to newUserId: String) async {
        do {
            let api = APIClient.shared
            let body = MigrateRequest(fromUserId: oldUserId)
            let _: MigrateResponse = try await api.post(
                path: "/api/v1/auth/migrate",
                body: body
            )
            print("[Auth] Data migrated from \(oldUserId) to \(newUserId)")
        } catch {
            print("[Auth] Data migration failed: \(error)")
        }
    }

    nonisolated var storedUserId: String {
        UserDefaults.standard.string(forKey: Self.userIdKey) ?? "unknown"
    }
}

enum AuthError: LocalizedError {
    case noRootViewController
    case missingToken

    var errorDescription: String? {
        switch self {
        case .noRootViewController: return "Unable to find root view controller"
        case .missingToken: return "Failed to get authentication token"
        }
    }
}

private struct MigrateRequest: Encodable {
    let fromUserId: String
}

private struct MigrateResponse: Decodable {
    let migrated: Bool
}
