//
//  AuthViewModel.swift
//  SkinSync
//
// 
//

import Foundation
import FirebaseAuth

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var user: AppUser?
    @Published var isLoading = false
    @Published var error: String?

    private let auth: AuthServicing
    private var handle: AuthStateDidChangeListenerHandle?
    init(auth: AuthServicing = AuthService()) {
        self.auth = auth
        self.user = auth.currentUser

        handle = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            guard let self else { return }
            self.user = firebaseUser.map { AppUser.fromFirebaseUser($0) }
        }
    }

    deinit {
        if let handle { Auth.auth().removeStateDidChangeListener(handle) }
    }

    func signInWithGoogle() {
        isLoading = true
        error = nil
        Task {
            defer { isLoading = false }
            do { user = try await auth.signInWithGoogle() }
            catch { self.error = error.localizedDescription }
        }
    }

    func signOut() {
        do { try auth.signOut(); user = nil }
        catch { self.error = error.localizedDescription }
    }
}
