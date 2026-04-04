import Foundation
import FirebaseAuth
import GoogleSignIn

@MainActor
final class AuthService: ObservableObject {
    @Published var userId: String
    @Published var isAuthenticated: Bool
    @Published var isGoogleLinked: Bool = false
    @Published var displayName: String?
    @Published var email: String?
    @Published var photoURL: URL?

    private static let userIdKey = "hp_user_id"
    private static let anonIdKey = "hp_anonymous_id"

    init() {
        if let firebaseUser = Auth.auth().currentUser {
            self.userId = firebaseUser.uid
            self.isAuthenticated = true
            self.isGoogleLinked = firebaseUser.providerData.contains { $0.providerID == "google.com" }
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

    /// The anonymous user ID before Google sign-in (for data migration)
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
              let rootVC = windowScene.windows.first?.rootViewController else {
            throw AuthError.noRootViewController
        }

        let oldAnonId = UserDefaults.standard.string(forKey: Self.userIdKey)

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
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
        displayName = firebaseUser.displayName
        email = firebaseUser.email
        photoURL = firebaseUser.photoURL
        UserDefaults.standard.set(firebaseUser.uid, forKey: Self.userIdKey)

        // Migrate data from anonymous account
        if let oldId = oldAnonId, oldId != firebaseUser.uid {
            await migrateData(from: oldId, to: firebaseUser.uid)
        }
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
        displayName = nil
        email = nil
        photoURL = nil
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
