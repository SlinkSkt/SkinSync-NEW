//
//  ProfileService.swift
//  SkinSync
//
//
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

protocol ProfileServicing {
    func loadProfile(userId: String) async throws -> Profile?
    func saveProfile(userId: String, profile: Profile) async throws
}

final class ProfileService: ProfileServicing {
    private let db = FirebaseManager.shared.db

    func loadProfile(userId: String) async throws -> Profile? {
        let documentRef = db.collection("users").document(userId).collection("private").document("profile")
        let snapshot = try await documentRef.getDocument()
        guard snapshot.exists, let data = snapshot.data() else { return nil }
        return Profile.fromDictionary(data)
    }

    func saveProfile(userId: String, profile: Profile) async throws {
        let documentRef = db.collection("users").document(userId).collection("private").document("profile")
        try await documentRef.setData(profile.asDictionary)
    }
}
