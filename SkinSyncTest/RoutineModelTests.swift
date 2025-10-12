//
//  RoutineModelTests.swift
//  SkinSyncTests
//
//  Unit tests for Routine and RoutineSlot
//

import XCTest
@testable import SkinSync

final class RoutineModelTests: XCTestCase {
    
    func testRoutineSlotInitialization() {
        // Given: A routine slot
        let slot = RoutineSlot(step: "Cleanser", productID: UUID())
        
        // Then: Properties should be set
        XCTAssertNotNil(slot.id)
        XCTAssertEqual(slot.step, "Cleanser")
        XCTAssertNotNil(slot.productID)
    }
    
    func testRoutineInitialization() {
        // Given: A routine with slots
        let slot1 = RoutineSlot(step: "Cleanser", productID: nil)
        let slot2 = RoutineSlot(step: "Toner", productID: nil)
        let routine = Routine(title: "AM", slots: [slot1, slot2])
        
        // Then: Properties should match
        XCTAssertEqual(routine.title, "AM")
        XCTAssertEqual(routine.slots.count, 2)
        XCTAssertEqual(routine.slots[0].step, "Cleanser")
    }
    
    func testRoutineEncodingDecoding() throws {
        // Given: A routine
        let original = Routine(title: "PM", slots: [])
        
        // When: Encoding and decoding
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Routine.self, from: data)
        
        // Then: Should match
        XCTAssertEqual(decoded.title, original.title)
    }
}

