//
//  ProfileViewModel.swift
//  SkinSync
//
//

import Foundation
import FirebaseAuth

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var profile: Profile
    private let store: DataStore
    private let profileService: ProfileServicing

    init(store: DataStore, profileService: ProfileServicing = ProfileService()) {
        self.store = store
        self.profileService = profileService

        self.profile = (try? store.loadProfile())
        ?? Profile(nickname: "",
                   yearOfBirthRange: "",
                   email: "",
                   phoneNumber: "",
                   skinType: .normal,
                   allergies: [],
                   goals: [],
                   profileIcon: "person.fill")

        if let user = Auth.auth().currentUser {
            Task { await loadFromCloudIfAvailable(userId: user.uid) }
        }
    }

    func save() {
        do { try store.save(profile: profile) } catch { }

        if let user = Auth.auth().currentUser {
            Task {
                do { try await profileService.saveProfile(userId: user.uid, profile: profile) }
                catch { }
            }
        }
    }

    private func loadFromCloudIfAvailable(userId: String) async {
        do {
            if let cloud = try await profileService.loadProfile(userId: userId) {
                await MainActor.run {
                    self.profile = cloud
                    do { try self.store.save(profile: cloud) } catch { }
                }
            }
        } catch { }
    }

    func resetAllData() {
        profile = Profile(
            nickname: "",
            yearOfBirthRange: "",
            email: "",
            phoneNumber: "",
            skinType: .normal,
            allergies: [],
            goals: [],
            profileIcon: "person.fill"
        )
        save()
    }
}
