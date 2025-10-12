//
//  UVIndexErrorTests.swift
//  SkinSyncTests
//
//  Unit tests for UVIndexError enum
//

import XCTest
@testable import SkinSync

final class UVIndexErrorTests: XCTestCase {
    
    func testErrorDescriptions() {
        // Test various error descriptions
        XCTAssertEqual(
            UVIndexError.noAPIKey.errorDescription,
            "OpenUV API key not configured. Please add your API key in settings."
        )
        
        XCTAssertEqual(
            UVIndexError.locationPermissionDenied.errorDescription,
            "Location permission denied"
        )
        
        XCTAssertEqual(
            UVIndexError.invalidResponse.errorDescription,
            "Invalid response from server"
        )
    }
    
    func testAPIErrorWithStatusCode() {
        // Test API error with status code
        let error404 = UVIndexError.apiError(404)
        let error500 = UVIndexError.apiError(500)
        
        XCTAssertEqual(error404.errorDescription, "API error: 404")
        XCTAssertEqual(error500.errorDescription, "API error: 500")
    }
    
    func testNetworkError() {
        // Test network error
        let underlyingError = NSError(
            domain: "Network",
            code: -1009,
            userInfo: [NSLocalizedDescriptionKey: "No internet"]
        )
        let error = UVIndexError.networkError(underlyingError)
        
        XCTAssertTrue(error.errorDescription?.contains("Network error") ?? false)
    }
}

