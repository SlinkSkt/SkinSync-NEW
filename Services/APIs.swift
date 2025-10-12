//
//  APIs.swift
//  SkinSync
//
//  Created by Zhen Xiao on 25/8/2025.
//

// Services/APIs.swift
// !!!!!!!!!! ---- STILL UNDER DEVELOPMENT, PLEASE EXCLUDE THIS FROM THE ASSESSMENT 1  --- !!!!!!!!!!
// !!!!!!!!!! ---- STILL UNDER DEVELOPMENT, PLEASE EXCLUDE THIS FROM THE ASSESSMENT 1  --- !!!!!!!!!!
// !!!!!!!!!! ---- STILL UNDER DEVELOPMENT, PLEASE EXCLUDE THIS FROM THE ASSESSMENT 1  --- !!!!!!!!!!
// !!!!!!!!!! ---- STILL UNDER DEVELOPMENT, PLEASE EXCLUDE THIS FROM THE ASSESSMENT 1  --- !!!!!!!!!!
import Foundation
import UIKit

// MARK: - Product API (plug your backend here)
protocol ProductAPI { func product(byBarcode code: String) async throws -> Product? }

struct LocalProductAPI: ProductAPI {
    func product(byBarcode code: String) async throws -> Product? {
        let store = FileDataStore()
        return try store.loadProducts().first(where: { $0.barcode == code })
    }
}

// MARK: - Hybrid Product API (Local + Open Beauty Facts)
// Note: HybridProductAPI removed - now using ProductRepository directly

