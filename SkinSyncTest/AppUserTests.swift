//
//  AppUserTests.swift
//  SkinSyncTests
//
//  Unit tests for AppUser model
//

import XCTest
@testable import SkinSync

final class AppUserTests: XCTestCase {
    
    func testAppUserInitialization() {
        // Given: AppUser parameters
        let user = AppUser(
            id: "user123",
            firstName: "John",
            email: "john@example.com"
        )
        
        // Then: Properties should be set
        XCTAssertEqual(user.id, "user123")
        XCTAssertEqual(user.firstName, "John")
        XCTAssertEqual(user.email, "john@example.com")
    }
    
    func testAppUserEquality() {
        // Given: Two users with same properties
        let user1 = AppUser(id: "123", firstName: "Alice", email: "alice@test.com")
        let user2 = AppUser(id: "123", firstName: "Alice", email: "alice@test.com")
        
        // Then: Should be equal
        XCTAssertEqual(user1, user2)
    }
    
    func testAppUserInequality() {
        // Given: Two users with different IDs
        let user1 = AppUser(id: "123", firstName: "Alice", email: "alice@test.com")
        let user2 = AppUser(id: "456", firstName: "Alice", email: "alice@test.com")
        
        // Then: Should not be equal
        XCTAssertNotEqual(user1, user2)
    }
}

