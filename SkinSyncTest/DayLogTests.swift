//
//  DayLogTests.swift
//  SkinSyncTests
//
//  Unit tests for DayLog model
//

import XCTest
@testable import SkinSync

final class DayLogTests: XCTestCase {
    
    func testDayLogInitialization() {
        // Given: DayLog with completed slots
        let slotID1 = UUID()
        let slotID2 = UUID()
        let dayLog = DayLog(
            dateKey: "2025-10-12",
            completedSlotIDs: [slotID1, slotID2]
        )
        
        // Then: Properties should be set
        XCTAssertNotNil(dayLog.id)
        XCTAssertEqual(dayLog.dateKey, "2025-10-12")
        XCTAssertEqual(dayLog.completedSlotIDs.count, 2)
        XCTAssertTrue(dayLog.completedSlotIDs.contains(slotID1))
    }
    
    func testDayLogManipulation() {
        // Given: A DayLog
        var dayLog = DayLog(dateKey: "2025-10-12", completedSlotIDs: [])
        let slotID = UUID()
        
        // When: Adding a slot
        dayLog.completedSlotIDs.append(slotID)
        
        // Then: Slot should exist
        XCTAssertEqual(dayLog.completedSlotIDs.count, 1)
        
        // When: Removing the slot
        dayLog.completedSlotIDs.removeAll { $0 == slotID }
        
        // Then: Should be empty
        XCTAssertTrue(dayLog.completedSlotIDs.isEmpty)
    }
}

