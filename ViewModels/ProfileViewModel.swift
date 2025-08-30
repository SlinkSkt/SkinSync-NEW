//
//  ProfileViewModel.swift
//  SkinSync
//
//

import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var profile: Profile
    private let store: DataStore
    
    init(store: DataStore) {
        self.store = store
        self.profile = (try? store.loadProfile())
        ?? Profile(nickname: "",
                   yearOfBirthRange: "",
                   skinType: .normal,
                   allergies: [],
                   goals: [])
    }
    
    func save() {
        do { try store.save(profile: profile) } catch { }
    }
}
