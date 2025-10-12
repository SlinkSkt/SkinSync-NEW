// ViewModels/ProductDetailViewModel.swift
import Foundation
import SwiftUI

@MainActor
final class ProductDetailViewModel: ObservableObject {
    @Published var product: Product?
    @Published var isLoading: Bool = false
    @Published var error: Error?
    @Published var parsedIngredients: ParsedIngredients = ParsedIngredients()
    @Published var showingIngredientSheet: Bool = false
    @Published var selectedIngredient: Ingredient?
    
    private let store: DataStore
    private let productRepository: ProductRepository?
    
    init(product: Product, store: DataStore, productRepository: ProductRepository? = nil) {
        self.product = product
        self.store = store
        self.productRepository = productRepository
        parseIngredients()
    }
    
    init(barcode: String, store: DataStore, productRepository: ProductRepository? = nil) {
        self.product = nil
        self.store = store
        self.productRepository = productRepository
        Task {
            await fetchProductByBarcode(barcode)
        }
    }
    
    // MARK: - Barcode Fetching
    
    private func fetchProductByBarcode(_ barcode: String) async {
        guard let repository = productRepository else {
            error = APIError.networkError(NSError(domain: "ProductDetailViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "No repository available"]))
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            if let fetchedProduct = try await repository.fetchByBarcode(barcode) {
                product = fetchedProduct
                parseIngredients()
            } else {
                error = APIError.invalidResponse
            }
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    // MARK: - Ingredient Parsing
    
    private func parseIngredients() {
        guard let product = product else { return }
        
        // Parse ingredients text into active and other ingredients
        // Use ingredientsText from OBF if available, otherwise fallback to parsed ingredients
        let ingredientsText = product.ingredientsText ?? product.ingredients.map { $0.commonName }.joined(separator: ", ")
        
        // Define known active ingredients
        let activeIngredients = [
            "Niacinamide", "Retinol", "Hyaluronic Acid", "Vitamin C", "Salicylic Acid",
            "Glycolic Acid", "Peptides", "Ceramides", "Squalane", "Alpha Arbutin",
            "Azelaic Acid", "Benzoyl Peroxide", "Kojic Acid", "Licorice Root",
            "Green Tea Extract", "Centella Asiatica", "Snail Mucin", "Tranexamic Acid"
        ]
        
        let allIngredients = ingredientsText.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        var actives: [Ingredient] = []
        var others: [Ingredient] = []
        
        for ingredientName in allIngredients {
            let isActive = activeIngredients.contains { active in
                ingredientName.localizedCaseInsensitiveContains(active)
            }
            
            let ingredient = Ingredient(
                inciName: ingredientName,
                commonName: ingredientName,
                role: isActive ? "Active" : "Supporting",
                note: isActive ? getIngredientNote(for: ingredientName) : nil
            )
            
            if isActive {
                actives.append(ingredient)
            } else {
                others.append(ingredient)
            }
        }
        
        parsedIngredients = ParsedIngredients(
            activeIngredients: actives,
            otherIngredients: others
        )
    }
    
    private func getIngredientNote(for ingredient: String) -> String? {
        let notes: [String: String] = [
            "Niacinamide": "Helps reduce pore appearance and improve skin texture",
            "Retinol": "Promotes cell turnover and reduces signs of aging",
            "Hyaluronic Acid": "Provides intense hydration and plumps skin",
            "Vitamin C": "Brightens skin and provides antioxidant protection",
            "Salicylic Acid": "Exfoliates and helps clear clogged pores",
            "Glycolic Acid": "Gentle exfoliant that improves skin texture",
            "Peptides": "Support skin repair and collagen production",
            "Ceramides": "Strengthen skin barrier and retain moisture"
        ]
        
        for (key, value) in notes {
            if ingredient.localizedCaseInsensitiveContains(key) {
                return value
            }
        }
        return nil
    }
    
    // MARK: - Actions
    
    func showIngredientDetails(_ ingredient: Ingredient) {
        selectedIngredient = ingredient
        showingIngredientSheet = true
    }
    
    func refreshProduct() {
        isLoading = true
        // Simulate refresh - in real app, this would fetch from API
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isLoading = false
            self.parseIngredients()
        }
    }
}

// MARK: - Supporting Types

struct ParsedIngredients {
    var activeIngredients: [Ingredient] = []
    var otherIngredients: [Ingredient] = []
    
    var hasIngredients: Bool {
        !activeIngredients.isEmpty || !otherIngredients.isEmpty
    }
}

// MARK: - Product Extensions

extension Product {
    var imageName: String? {
        // Use assetName for local images, imageURL for remote images
        if !assetName.isEmpty {
            return assetName
        } else if let imageURL = imageURL, !imageURL.isEmpty {
            return nil // Will use AsyncImage for remote URLs
        }
        return nil
    }
    
    var productQuantity: String? {
        // Use the quantity field from Open Beauty Facts
        return quantity
    }
    
    var productCategoriesArray: [String] {
        // Use productCategories from OBF, fallback to single category
        if let categories = productCategories, !categories.isEmpty {
            return categories
        }
        return [category]
    }
    
    var productLabelsArray: [String] {
        // Use productLabels from OBF
        return productLabels ?? []
    }
}
