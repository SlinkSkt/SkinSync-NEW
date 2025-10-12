//
//  RoutineService.swift
//  SkinSync
//

import Foundation
import FirebaseFirestore


struct RoutineItemPayload: Codable {
    let id: String
    let name: String
    let brand: String
    let category: String
    let barcode: String
}

struct RoutinePayload: Codable {
    var morning: [RoutineItemPayload]
    var evening: [RoutineItemPayload]
    var updatedAt: Date
}

protocol RoutineServicing {
    func save(userId: String, payload: RoutinePayload) async throws
    func load(userId: String) async throws -> RoutinePayload?
}

final class RoutineService: RoutineServicing {
    private let db = FirebaseManager.shared.db


    private func doc(_ userId: String) -> DocumentReference {
        db.collection("users")
          .document(userId)
          .collection("private")
          .document("routine")
    }

    func save(userId: String, payload: RoutinePayload) async throws {
        let morningArray: [[String: Any]] = payload.morning.map { i in
            [
                "id": i.id,
                "name": i.name,
                "brand": i.brand,
                "category": i.category,
                "barcode": i.barcode
            ]
        }
        let eveningArray: [[String: Any]] = payload.evening.map { i in
            [
                "id": i.id,
                "name": i.name,
                "brand": i.brand,
                "category": i.category,
                "barcode": i.barcode
            ]
        }

        let data: [String: Any] = [
            "morning": morningArray,
            "evening": eveningArray,
            "updatedAt": Timestamp(date: payload.updatedAt)
        ]

        print("RoutineService: writing → users/\(userId)/private/routine")
        try await doc(userId).setData(data, merge: true)
        print("RoutineService: write OK")
    }

    func load(userId: String) async throws -> RoutinePayload? {
        let snap = try await doc(userId).getDocument()
        guard let data = snap.data() else { return nil }

        let mDicts = data["morning"] as? [[String: Any]] ?? []
        let eDicts = data["evening"] as? [[String: Any]] ?? []

        let morning: [RoutineItemPayload] = mDicts.compactMap { d in
            guard let id = d["id"] as? String,
                  let name = d["name"] as? String,
                  let brand = d["brand"] as? String,
                  let category = d["category"] as? String,
                  let barcode = d["barcode"] as? String else { return nil }
            return RoutineItemPayload(id: id, name: name, brand: brand, category: category, barcode: barcode)
        }

        let evening: [RoutineItemPayload] = eDicts.compactMap { d in
            guard let id = d["id"] as? String,
                  let name = d["name"] as? String,
                  let brand = d["brand"] as? String,
                  let category = d["category"] as? String,
                  let barcode = d["barcode"] as? String else { return nil }
            return RoutineItemPayload(id: id, name: name, brand: brand, category: category, barcode: barcode)
        }

        let ts = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        return RoutinePayload(morning: morning, evening: evening, updatedAt: ts)
    }
}
