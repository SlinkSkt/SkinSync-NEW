//
//  DateExtensionTests.swift
//  SkinSyncTests
//
//  Unit tests for Date extension
//

import XCTest
@testable import SkinSync

final class DateExtensionTests: XCTestCase {
    
    func testSkinsyncDateKeyFormat() {
        // Given: A specific date
        var components = DateComponents()
        components.year = 2025
        components.month = 10
        components.day = 12
        
        let calendar = Calendar(identifier: .gregorian)
        let date = calendar.date(from: components)!
        
        // When: Getting the date key
        let dateKey = date.skinsyncDateKey
        
        // Then: Should be in yyyy-MM-dd format
        XCTAssertEqual(dateKey, "2025-10-12")
    }
    
    func testSkinsyncDateKeyIgnoresTime() {
        // Given: Two dates on same day, different times
        var morning = DateComponents()
        morning.year = 2025
        morning.month = 5
        morning.day = 15
        morning.hour = 8
        
        var evening = DateComponents()
        evening.year = 2025
        evening.month = 5
        evening.day = 15
        evening.hour = 20
        
        let calendar = Calendar(identifier: .gregorian)
        let morningDate = calendar.date(from: morning)!
        let eveningDate = calendar.date(from: evening)!
        
        // Then: Keys should be identical
        XCTAssertEqual(morningDate.skinsyncDateKey, eveningDate.skinsyncDateKey)
    }
}

