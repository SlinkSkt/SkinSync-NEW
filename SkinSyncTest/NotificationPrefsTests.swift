//
//  NotificationPrefsTests.swift
//  SkinSyncTests
//
//  Unit tests for NotificationPrefs
//

import XCTest
@testable import SkinSync

final class NotificationPrefsTests: XCTestCase {
    
    func testNotificationPrefsInitialization() {
        // Given: Notification preferences
        let prefs = NotificationPrefs(
            enableAM: true,
            amHour: 8,
            amMinute: 0,
            enablePM: true,
            pmHour: 20,
            pmMinute: 30
        )
        
        // Then: Properties should be set
        XCTAssertTrue(prefs.enableAM)
        XCTAssertEqual(prefs.amHour, 8)
        XCTAssertEqual(prefs.amMinute, 0)
        XCTAssertTrue(prefs.enablePM)
        XCTAssertEqual(prefs.pmHour, 20)
        XCTAssertEqual(prefs.pmMinute, 30)
    }
    
    func testNotificationPrefsEquality() {
        // Given: Two identical preferences
        let prefs1 = NotificationPrefs(
            enableAM: true, amHour: 8, amMinute: 30,
            enablePM: false, pmHour: 20, pmMinute: 0
        )
        let prefs2 = NotificationPrefs(
            enableAM: true, amHour: 8, amMinute: 30,
            enablePM: false, pmHour: 20, pmMinute: 0
        )
        
        // Then: Should be equal
        XCTAssertEqual(prefs1, prefs2)
    }
}

