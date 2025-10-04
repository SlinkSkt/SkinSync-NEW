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
                   goals: [],
                   profileIcon: "person.fill")
    }
    
    func save() {
        do { try store.save(profile: profile) } catch { }
    }
    
    func resetAllData() {
        profile = Profile(
            nickname: "",
            yearOfBirthRange: "",
            skinType: .normal,
            allergies: [],
            goals: [],
            profileIcon: "person.fill"
        )
        save()
    }
}
