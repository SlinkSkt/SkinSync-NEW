//
//  ProductModelTests.swift
//  SkinSyncTests
//
//  Unit tests for Product model
//

import XCTest
@testable import SkinSync

final class ProductModelTests: XCTestCase {
    
    func testProductInitialization() {
        // Given: Product with properties
        let product = Product(
            name: "Test Serum",
            brand: "TestBrand",
            category: "Serum",
            assetName: "test_image",
            concerns: [.dryness, .aging],
            ingredients: [],
            barcode: "1234567890",
            rating: 4.5,
            isFromOpenBeautyFacts: true
        )
        
        // Then: Properties should be set correctly
        XCTAssertEqual(product.name, "Test Serum")
        XCTAssertEqual(product.brand, "TestBrand")
        XCTAssertEqual(product.barcode, "1234567890")
        XCTAssertEqual(product.rating, 4.5)
        XCTAssertTrue(product.isFromOpenBeautyFacts)
    }
    
    func testProductEncodingDecoding() throws {
        // Given: A product
        let original = Product(
            name: "Test",
            brand: "Brand",
            category: "Cat",
            assetName: "asset",
            concerns: [.acne],
            ingredients: [],
            barcode: "123"
        )
        
        // When: Encoding and decoding
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Product.self, from: data)
        
        // Then: Should match
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.barcode, original.barcode)
    }
}

