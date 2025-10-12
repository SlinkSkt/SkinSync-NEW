//
//  ProfileModelTests.swift
//  SkinSyncTests
//
//  Unit tests for Profile model dictionary conversion
//

import XCTest
@testable import SkinSync

final class ProfileModelTests: XCTestCase {
    
    func testProfileRoundTripConversion() {
        // Given: A profile with various properties
        let original = Profile(
            nickname: "TestUser",
            yearOfBirthRange: "1990-2000",
            email: "test@example.com",
            phoneNumber: "+1234567890",
            skinType: .combination,
            allergies: ["Parabens"],
            goals: [.clearAcne, .brighten],
            profileIcon: "person.circle"
        )
        
        // When: Converting to dictionary and back
        let dict = original.asDictionary
        let reconstructed = Profile.fromDictionary(dict)
        
        // Then: All properties should match
        XCTAssertEqual(reconstructed.nickname, original.nickname)
        XCTAssertEqual(reconstructed.email, original.email)
        XCTAssertEqual(reconstructed.skinType, original.skinType)
        XCTAssertEqual(reconstructed.allergies, original.allergies)
        XCTAssertEqual(reconstructed.goals, original.goals)
    }
    
    func testProfileFromEmptyDictionary() {
        // Given: An empty dictionary
        let dict: [String: Any] = [:]
        
        // When: Converting to Profile
        let profile = Profile.fromDictionary(dict)
        
        // Then: Should have default values
        XCTAssertEqual(profile.skinType, .normal)
        XCTAssertTrue(profile.allergies.isEmpty)
        XCTAssertEqual(profile.profileIcon, "person.fill")
    }
}

