//
//  SkinTypeTests.swift
//  SkinSyncTests
//
//  Unit tests for SkinType enum
//

import XCTest
@testable import SkinSync

final class SkinTypeTests: XCTestCase {
    
    func testSkinTypeRawValues() {
        // Test raw values and identifiers
        XCTAssertEqual(SkinType.normal.rawValue, "normal")
        XCTAssertEqual(SkinType.dry.rawValue, "dry")
        XCTAssertEqual(SkinType.oily.rawValue, "oily")
        XCTAssertEqual(SkinType.combination.rawValue, "combination")
        XCTAssertEqual(SkinType.sensitive.rawValue, "sensitive")
        XCTAssertEqual(SkinType.normal.id, "normal")
    }
    
    func testSkinTypeFromRawValue() {
        // Test initialization from raw values
        XCTAssertEqual(SkinType(rawValue: "normal"), .normal)
        XCTAssertEqual(SkinType(rawValue: "dry"), .dry)
        XCTAssertNil(SkinType(rawValue: "invalid"))
    }
    
    func testSkinTypeCaseIterable() {
        // Test all cases are available
        let allTypes = SkinType.allCases
        XCTAssertEqual(allTypes.count, 5)
        XCTAssertTrue(allTypes.contains(.normal))
    }
}

