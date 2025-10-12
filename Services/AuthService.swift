//
//  AuthService.swift
//  SkinSync
//
//
//
import Foundation
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import UIKit

struct AppUser: Identifiable, Equatable {
    let id: String
    let firstName: String
    let email: String

    static func fromFirebaseUser(_ user: User) -> AppUser {
        let display = user.displayName ?? ""
        let first = display.split(separator: " ").first.map(String.init) ?? display
        return .init(id: user.uid, firstName: first, email: user.email ?? "")
    }
}

protocol AuthServicing {
    var currentUser: AppUser? { get }
    func signInWithGoogle() async throws -> AppUser
    func signOut() throws
}

final class AuthService: AuthServicing {
    var currentUser: AppUser? {
        Auth.auth().currentUser.map { AppUser.fromFirebaseUser($0) }
    }

    @MainActor
    func signInWithGoogle() async throws -> AppUser {
        guard let rootVC = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?
            .rootViewController
        else {
            throw NSError(domain: "Auth", code: -2,
                          userInfo: [NSLocalizedDescriptionKey: "No root view controller"])
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
        let googleUser = result.user

        guard let idToken = googleUser.idToken?.tokenString else {
            throw NSError(domain: "Auth", code: -4,
                          userInfo: [NSLocalizedDescriptionKey: "Missing Google ID token"])
        }
        let accessToken = googleUser.accessToken.tokenString

        let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                       accessToken: accessToken)
        let authResult = try await Auth.auth().signIn(with: credential)
        return AppUser.fromFirebaseUser(authResult.user)
    }

    func signOut() throws {
        try Auth.auth().signOut()
        GIDSignIn.sharedInstance.signOut()
    }
}
