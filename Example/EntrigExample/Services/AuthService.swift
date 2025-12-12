import Foundation
import Supabase

/// Auth service for managing authentication (matching Flutter auth logic exactly)
class AuthService {
    static let shared = AuthService()

    private var supabase: SupabaseClient {
        SupabaseService.shared.client
    }

    private init() {}

    // MARK: - Auth State

    var currentUser: Supabase.User? {
        supabase.auth.currentUser
    }

    var currentUserId: String? {
        guard let user = currentUser else { return nil }
        return user.id.uuidString.lowercased()
    }

    var isSignedIn: Bool {
        currentUser != nil
    }

    // MARK: - Sign In (Anonymous Auth - matching Flutter)

    func signIn(name: String) async throws -> String {
        // Sign in anonymously (same as Flutter)
        let session = try await supabase.auth.signInAnonymously()

        // Lowercase to match PostgreSQL UUID storage format
        let userId = session.user.id.uuidString.lowercased()

        // Store user in database with the same ID
        try await SupabaseService.shared.upsertUser(id: userId, name: name)

        return userId
    }

    // MARK: - Sign Out

    func signOut() async throws {
        try await supabase.auth.signOut()
    }

    // MARK: - Auth State Listener

    func observeAuthStateChanges(onChange: @escaping (String?) -> Void) {
        Task {
            for await state in await supabase.auth.authStateChanges {
                switch state.event {
                case .signedIn:
                    onChange(state.session?.user.id.uuidString)
                case .signedOut:
                    onChange(nil)
                default:
                    break
                }
            }
        }
    }
}
