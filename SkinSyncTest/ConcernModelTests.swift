//
//  ConcernModelTests.swift
//  SkinSyncTests
//
//  Unit tests for Concern enum
//

import XCTest
@testable import SkinSync

final class ConcernModelTests: XCTestCase {
    
    func testConcernProperties() {
        // Test raw values and titles
        XCTAssertEqual(Concern.acne.rawValue, "acne")
        XCTAssertEqual(Concern.acne.title, "Acne")
        XCTAssertEqual(Concern.acne.id, "acne")
        
        XCTAssertEqual(Concern.dryness.rawValue, "dryness")
        XCTAssertEqual(Concern.dryness.title, "Dryness")
    }
    
    func testConcernCaseIterable() {
        // Test all concern cases are available
        let allConcerns = Concern.allCases
        XCTAssertEqual(allConcerns.count, 8)
        XCTAssertTrue(allConcerns.contains(.acne))
        XCTAssertTrue(allConcerns.contains(.dryness))
    }
    
    func testConcernHashable() {
        // Test concerns work in Sets
        let concernSet: Set<Concern> = [.acne, .dryness, .acne]
        XCTAssertEqual(concernSet.count, 2)
    }
}

