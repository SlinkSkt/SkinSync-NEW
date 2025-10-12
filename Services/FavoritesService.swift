//
//  FavoritesService.swift
//  SkinSync
//
//
//

import Foundation
import FirebaseFirestore

protocol FavoriteServicing {
    func load(userId: String) async throws -> (ids: [String], items: [[String: Any]])
    func save(userId: String, ids: [String], items: [[String: Any]]) async throws
}

final class FavoritesService: FavoriteServicing {
    private let db = FirebaseManager.shared.db

    private func doc(_ userId: String) -> DocumentReference {
        db.collection("users").document(userId).collection("favorites").document("list")
    }

    func load(userId: String) async throws -> (ids: [String], items: [[String: Any]]) {
        let snap = try await doc(userId).getDocument()
        let ids = (snap.data()?["ids"] as? [String]) ?? []
        let items = (snap.data()?["items"] as? [[String: Any]]) ?? []
        return (ids: ids, items: items)
    }

    // NEW: write both ids and a richer items array
    func save(userId: String, ids: [String], items: [[String: Any]]) async throws {
        let payload: [String: Any] = [
            "ids": ids,
            "items": items,
            "updatedAt": Timestamp(date: Date())
        ]
        try await doc(userId).setData(payload)
    }
}
