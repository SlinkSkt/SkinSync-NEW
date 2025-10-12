//
//  IngredientModelTests.swift
//  SkinSyncTests
//
//  Unit tests for Ingredient model
//

import XCTest
@testable import SkinSync

final class IngredientModelTests: XCTestCase {
    
    func testIngredientInitialization() {
        // Given: Ingredient with properties
        let ingredient = Ingredient(
            inciName: "Sodium Hyaluronate",
            commonName: "Hyaluronic Acid",
            role: "Humectant",
            note: "Attracts moisture"
        )
        
        // Then: Properties should be set
        XCTAssertEqual(ingredient.inciName, "Sodium Hyaluronate")
        XCTAssertEqual(ingredient.commonName, "Hyaluronic Acid")
        XCTAssertEqual(ingredient.role, "Humectant")
        XCTAssertEqual(ingredient.note, "Attracts moisture")
        XCTAssertNotNil(ingredient.id)
    }
    
    func testIngredientEncodingDecoding() throws {
        // Given: An ingredient
        let original = Ingredient(
            inciName: "Niacinamide",
            commonName: "Vitamin B3",
            role: "Brightening",
            note: nil
        )
        
        // When: Encoding and decoding
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Ingredient.self, from: data)
        
        // Then: Properties should match
        XCTAssertEqual(decoded.inciName, original.inciName)
        XCTAssertEqual(decoded.commonName, original.commonName)
    }
}

