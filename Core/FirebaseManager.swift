//
//  FirebaseManager.swift
//  SkinSync
//
//
//

import FirebaseFirestore
import FirebaseAuth
import FirebaseCore

final class FirebaseManager {
    static let shared = FirebaseManager()
    let db: Firestore
    private init() {
        if FirebaseApp.app() == nil { FirebaseApp.configure() }
        self.db = Firestore.firestore()
    }
}
