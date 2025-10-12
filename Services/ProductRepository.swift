import Foundation

// MARK: - Product Repository Protocol

protocol ProductRepository {
    func search(query: String, page: Int, pageSize: Int) async throws -> [Product]
    func fetchByBarcode(_ barcode: String) async throws -> Product?
    func fetchRandomProducts(count: Int) async throws -> [Product]
}

// MARK: - Open Beauty Facts Response Models

struct OBFProductResponse: Codable {
    let status: Int
    let statusVerbose: String?
    let product: OBFProduct?
    
    private enum CodingKeys: String, CodingKey {
        case status, statusVerbose = "status_verbose", product
    }
}

struct OBFProduct: Codable {
    let code: String?
    let productName: String?
    let brands: String?
    let categories: String?
    let categoriesTags: [String]?
    let labels: String?
    let labelsTags: [String]?
    let quantity: String?
    let imageURL: String?
    let imageSmallURL: String?
    let imageFrontURL: String?
    let imageFrontSmallURL: String?
    let imageIngredientsURL: String?
    let imageIngredientsSmallURL: String?
    let imageNutritionURL: String?
    let imageNutritionSmallURL: String?
    let ingredientsText: String?
    let ingredientsTextEn: String?
    let ingredientsAnalysisTags: [String]?
    let allergens: String?
    let allergensTags: [String]?
    let traces: String?
    let tracesTags: [String]?
    let additives: String?
    let additivesTags: [String]?
    let nutritionGrades: String?
    let novaGroup: Int?
    let ecoscoreGrade: String?
    let lastModifiedTime: Int?
    let createdTime: Int?
    let lastModifiedBy: String?
    let createdBy: String?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode only the fields that exist in the API response
        code = try container.decodeIfPresent(String.self, forKey: .code)
        productName = try container.decodeIfPresent(String.self, forKey: .productName)
        brands = try container.decodeIfPresent(String.self, forKey: .brands)
        categories = try container.decodeIfPresent(String.self, forKey: .categories)
        categoriesTags = try container.decodeIfPresent([String].self, forKey: .categoriesTags)
        labels = try container.decodeIfPresent(String.self, forKey: .labels)
        labelsTags = try container.decodeIfPresent([String].self, forKey: .labelsTags)
        quantity = try container.decodeIfPresent(String.self, forKey: .quantity)
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        imageSmallURL = try container.decodeIfPresent(String.self, forKey: .imageSmallURL)
        imageFrontURL = try container.decodeIfPresent(String.self, forKey: .imageFrontURL)
        imageFrontSmallURL = try container.decodeIfPresent(String.self, forKey: .imageFrontSmallURL)
        imageIngredientsURL = try container.decodeIfPresent(String.self, forKey: .imageIngredientsURL)
        imageIngredientsSmallURL = try container.decodeIfPresent(String.self, forKey: .imageIngredientsSmallURL)
        imageNutritionURL = try container.decodeIfPresent(String.self, forKey: .imageNutritionURL)
        imageNutritionSmallURL = try container.decodeIfPresent(String.self, forKey: .imageNutritionSmallURL)
        ingredientsText = try container.decodeIfPresent(String.self, forKey: .ingredientsText)
        ingredientsTextEn = try container.decodeIfPresent(String.self, forKey: .ingredientsTextEn)
        ingredientsAnalysisTags = try container.decodeIfPresent([String].self, forKey: .ingredientsAnalysisTags)
        allergens = try container.decodeIfPresent(String.self, forKey: .allergens)
        allergensTags = try container.decodeIfPresent([String].self, forKey: .allergensTags)
        traces = try container.decodeIfPresent(String.self, forKey: .traces)
        tracesTags = try container.decodeIfPresent([String].self, forKey: .tracesTags)
        additives = try container.decodeIfPresent(String.self, forKey: .additives)
        additivesTags = try container.decodeIfPresent([String].self, forKey: .additivesTags)
        nutritionGrades = try container.decodeIfPresent(String.self, forKey: .nutritionGrades)
        novaGroup = try container.decodeIfPresent(Int.self, forKey: .novaGroup)
        ecoscoreGrade = try container.decodeIfPresent(String.self, forKey: .ecoscoreGrade)
        lastModifiedTime = try container.decodeIfPresent(Int.self, forKey: .lastModifiedTime)
        createdTime = try container.decodeIfPresent(Int.self, forKey: .createdTime)
        lastModifiedBy = try container.decodeIfPresent(String.self, forKey: .lastModifiedBy)
        createdBy = try container.decodeIfPresent(String.self, forKey: .createdBy)
    }
    
    private enum CodingKeys: String, CodingKey {
        case code, brands, categories, quantity
        case productName = "product_name"
        case categoriesTags = "categories_tags"
        case labels, labelsTags = "labels_tags"
        case imageURL = "image_url"
        case imageSmallURL = "image_small_url"
        case imageFrontURL = "image_front_url"
        case imageFrontSmallURL = "image_front_small_url"
        case imageIngredientsURL = "image_ingredients_url"
        case imageIngredientsSmallURL = "image_ingredients_small_url"
        case imageNutritionURL = "image_nutrition_url"
        case imageNutritionSmallURL = "image_nutrition_small_url"
        case ingredientsText = "ingredients_text"
        case ingredientsTextEn = "ingredients_text_en"
        case ingredientsAnalysisTags = "ingredients_analysis_tags"
        case allergens, allergensTags = "allergens_tags"
        case traces, tracesTags = "traces_tags"
        case additives, additivesTags = "additives_tags"
        case nutritionGrades = "nutrition_grades"
        case novaGroup = "nova_group"
        case ecoscoreGrade = "ecoscore_grade"
        case lastModifiedTime = "last_modified_t"
        case createdTime = "created_t"
        case lastModifiedBy = "last_modified_by"
        case createdBy = "created_by"
    }
}

struct OBFSearchResponse: Codable {
    let page: Int?
    let pageSize: Int?
    let count: Int?
    let products: [OBFProduct]?
    
    private enum CodingKeys: String, CodingKey {
        case page, pageSize = "page_size", count, products
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle page field that might be string or int
        if let pageString = try? container.decode(String.self, forKey: .page) {
            page = Int(pageString)
        } else {
            page = try container.decodeIfPresent(Int.self, forKey: .page)
        }
        
        // Handle pageSize field that might be string or int
        if let pageSizeString = try? container.decode(String.self, forKey: .pageSize) {
            pageSize = Int(pageSizeString)
        } else {
            pageSize = try container.decodeIfPresent(Int.self, forKey: .pageSize)
        }
        
        // Handle count field that might be string or int
        if let countString = try? container.decode(String.self, forKey: .count) {
            count = Int(countString)
        } else {
            count = try container.decodeIfPresent(Int.self, forKey: .count)
        }
        
        products = try container.decodeIfPresent([OBFProduct].self, forKey: .products)
    }
}

// MARK: - Open Beauty Facts Product Repository

@MainActor
class OpenBeautyFactsRepository: ProductRepository {
    private let baseURL = "https://world.openbeautyfacts.org/api/v2"
    private let session = URLSession.shared
    private let store: DataStore
    
    init(store: DataStore) {
        self.store = store
    }
    
    // MARK: - Search API
    
    func search(query: String, page: Int = 1, pageSize: Int = 20) async throws -> [Product] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        // Use CGI search endpoint which works properly with search terms
        let url = URL(string: "https://world.openbeautyfacts.org/cgi/search.pl")!
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "search_terms", value: query),
            URLQueryItem(name: "search_simple", value: "1"),
            URLQueryItem(name: "action", value: "process"),
            URLQueryItem(name: "json", value: "1"),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "page_size", value: String(pageSize)),
            URLQueryItem(name: "fields", value: "code,product_name,brands,image_url,image_small_url,ingredients_text,quantity,categories_tags,labels_tags")
        ]

        guard let finalURL = components.url else {
            throw APIError.invalidURL
        }

        print("🔍 ProductRepository: CGI search URL: \(finalURL)")

        do {
            let (data, response) = try await session.data(from: finalURL)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("🔍 ProductRepository: Search failed with status: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                throw APIError.invalidResponse
            }

            print("🔍 ProductRepository: Search response size: \(data.count) bytes")

            // The API returns a dictionary with products array
            let searchResponse = try JSONDecoder().decode(OBFSearchResponse.self, from: data)

            guard let obfProducts = searchResponse.products, !obfProducts.isEmpty else {
                print("🔍 ProductRepository: No products in search response")
                return []
            }

            let products = obfProducts.compactMap { obfProduct in
                try? convertToProduct(from: obfProduct)
            }

            print("🔍 ProductRepository: CGI search found \(products.count) products for query '\(query)'")

            // Cache the search results
            await cacheProducts(products)

            return products

        } catch {
            print("🔍 ProductRepository: Search error: \(error)")
            throw APIError.networkError(error)
        }
    }
    
    // MARK: - Barcode API
    
    func fetchByBarcode(_ barcode: String) async throws -> Product? {
        guard !barcode.isEmpty else { return nil }
        
        let url = URL(string: "\(baseURL)/product/\(barcode).json")!
        print("🔍 ProductRepository: Fetching barcode: \(barcode)")
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("🔍 ProductRepository: Invalid HTTP response")
                throw APIError.invalidResponse
            }
            
            print("🔍 ProductRepository: HTTP status: \(httpResponse.statusCode)")
            
            // Allow 200 (success) and 404 (not found) - both are valid responses
            guard httpResponse.statusCode == 200 || httpResponse.statusCode == 404 else {
                print("🔍 ProductRepository: Unexpected HTTP status: \(httpResponse.statusCode)")
                throw APIError.invalidResponse
            }
            
            print("🔍 ProductRepository: Barcode response size: \(data.count) bytes")
            
            let obfResponse = try JSONDecoder().decode(OBFProductResponse.self, from: data)
            
            guard obfResponse.status == 1, let obfProduct = obfResponse.product else {
                print("🔍 ProductRepository: Product not found for barcode: \(barcode)")
                return nil
            }
            
            let product = try convertToProduct(from: obfProduct)
            print("🔍 ProductRepository: Found product: \(product.name)")
            
            // Cache the product
            await cacheProduct(product)
            
            return product
            
        } catch {
            print("🔍 ProductRepository: Barcode fetch error: \(error)")
            throw APIError.networkError(error)
        }
    }
    
    // MARK: - Random Products
    
    func fetchRandomProducts(count: Int) async throws -> [Product] {
        // Use common beauty terms to get a variety of products
        let beautyTerms = ["cleanser", "moisturizer", "serum", "sunscreen", "shampoo", "conditioner", "lipstick", "foundation", "mascara", "toner"]
        
        // Pick a random term
        let randomTerm = beautyTerms.randomElement() ?? "beauty"
        
        print("🔍 ProductRepository: Fetching random products using term: '\(randomTerm)'")
        
        // Use the search method with a random beauty term
        return try await search(query: randomTerm, page: 1, pageSize: count)
    }
    
    // MARK: - Caching
    
    private func cacheProducts(_ products: [Product]) async {
        do {
            var cachedProducts = try store.loadProducts()
            
            for product in products {
                if !cachedProducts.contains(where: { $0.barcode == product.barcode }) {
                    cachedProducts.append(product)
                }
            }
            
            try store.save(products: cachedProducts)
            print("🔍 ProductRepository: Cached \(products.count) products")
        } catch {
            print("🔍 ProductRepository: Failed to cache products: \(error)")
        }
    }
    
    private func cacheProduct(_ product: Product) async {
        do {
            var cachedProducts = try store.loadProducts()
            
            if let index = cachedProducts.firstIndex(where: { $0.barcode == product.barcode }) {
                cachedProducts[index] = product
            } else {
                cachedProducts.append(product)
            }
            
            try store.save(products: cachedProducts)
            print("🔍 ProductRepository: Cached product: \(product.name)")
        } catch {
            print("🔍 ProductRepository: Failed to cache product: \(error)")
        }
    }
    
    // MARK: - Product Conversion
    
    private func generateProductName(from obfProduct: OBFProduct) -> String {
        // Try to generate a meaningful name from available fields
        var nameParts: [String] = []
        
        if let brands = obfProduct.brands, !brands.isEmpty {
            nameParts.append(brands)
        }
        
        if let categories = obfProduct.categories, !categories.isEmpty {
            // Extract meaningful category names
            let categoryName = categories.replacingOccurrences(of: "en:", with: "")
                .replacingOccurrences(of: "open-beauty-facts", with: "")
                .replacingOccurrences(of: "non-food-products", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !categoryName.isEmpty && categoryName != categories {
                nameParts.append(categoryName.capitalized)
            }
        }
        
        if let quantity = obfProduct.quantity, !quantity.isEmpty {
            nameParts.append(quantity)
        }
        
        if nameParts.isEmpty {
            return "Product \(obfProduct.code ?? "Unknown")"
        }
        
        return nameParts.joined(separator: " ")
    }
    
    private func convertToProduct(from obfProduct: OBFProduct) throws -> Product {
        // Generate name from available fields since product_name is often missing
        let name = obfProduct.productName ?? generateProductName(from: obfProduct)
        let brand = obfProduct.brands ?? "Unknown Brand"
        let category = extractCategory(from: obfProduct.categoriesTags ?? [])
        let barcode = obfProduct.code ?? ""
        
        // Parse ingredients
        let ingredients = parseIngredients(from: obfProduct.ingredientsText ?? obfProduct.ingredientsTextEn)
        
        // Extract concerns from categories and labels
        let concerns = extractConcerns(from: obfProduct.categoriesTags, labels: obfProduct.labelsTags)
        
        // Calculate rating based on nutrition grade and other factors
        let rating = calculateRating(from: obfProduct)
        
        // Parse dates
        let lastModified = parseDate(from: obfProduct.lastModifiedTime)
        let createdDate = parseDate(from: obfProduct.createdTime)
        
        return Product(
            name: name,
            brand: brand,
            category: category,
            assetName: "", // Will be set from imageURL
            concerns: concerns,
            ingredients: ingredients,
            barcode: barcode,
            rating: rating,
            imageURL: obfProduct.imageURL ?? obfProduct.imageSmallURL ?? obfProduct.imageFrontURL,
            quantity: obfProduct.quantity,
            productLabels: obfProduct.labelsTags,
            productCategories: obfProduct.categoriesTags,
            allergens: obfProduct.allergensTags,
            traces: obfProduct.tracesTags,
            additives: obfProduct.additivesTags,
            nutritionGrade: obfProduct.nutritionGrades,
            ingredientsText: obfProduct.ingredientsText ?? obfProduct.ingredientsTextEn,
            lastModified: lastModified,
            createdDate: createdDate,
            isFromOpenBeautyFacts: true
        )
    }
    
    // MARK: - Helper Methods
    
    private func extractCategory(from categoriesTags: [String]) -> String {
        // Look for common cosmetic categories in tags
        for tag in categoriesTags {
            let lowercased = tag.lowercased()
            if lowercased.contains("cleanser") || lowercased.contains("cleaning") || lowercased.contains("soap") {
                return "Cleanser"
            } else if lowercased.contains("moisturizer") || lowercased.contains("cream") || lowercased.contains("lotion") {
                return "Moisturizer"
            } else if lowercased.contains("serum") || lowercased.contains("treatment") || lowercased.contains("essence") {
                return "Treatment"
            } else if lowercased.contains("sunscreen") || lowercased.contains("spf") || lowercased.contains("sun") {
                return "Sunscreen"
            } else if lowercased.contains("toner") || lowercased.contains("astringent") {
                return "Toner"
            } else if lowercased.contains("mask") || lowercased.contains("pack") {
                return "Mask"
            } else if lowercased.contains("makeup") || lowercased.contains("cosmetic") {
                return "Makeup"
            } else if lowercased.contains("perfume") || lowercased.contains("fragrance") {
                return "Fragrance"
            } else if lowercased.contains("shampoo") || lowercased.contains("conditioner") {
                return "Hair Care"
            }
        }
        
        return "Personal Care"
    }
    
    private func calculateRating(from obfProduct: OBFProduct) -> Double? {
        var score: Double = 0.0
        var factors: Int = 0
        
        // Nutrition grade factor (A=5, B=4, C=3, D=2, E=1)
        if let nutritionGrade = obfProduct.nutritionGrades?.uppercased() {
            switch nutritionGrade {
            case "A": score += 5.0; factors += 1
            case "B": score += 4.0; factors += 1
            case "C": score += 3.0; factors += 1
            case "D": score += 2.0; factors += 1
            case "E": score += 1.0; factors += 1
            default: break
            }
        }
        
        // Eco-score factor (A=5, B=4, C=3, D=2, E=1)
        if let ecoscoreGrade = obfProduct.ecoscoreGrade?.uppercased() {
            switch ecoscoreGrade {
            case "A": score += 5.0; factors += 1
            case "B": score += 4.0; factors += 1
            case "C": score += 3.0; factors += 1
            case "D": score += 2.0; factors += 1
            case "E": score += 1.0; factors += 1
            default: break
            }
        }
        
        // NOVA group factor (1=5, 2=4, 3=3, 4=2)
        if let novaGroup = obfProduct.novaGroup {
            switch novaGroup {
            case 1: score += 5.0; factors += 1
            case 2: score += 4.0; factors += 1
            case 3: score += 3.0; factors += 1
            case 4: score += 2.0; factors += 1
            default: break
            }
        }
        
        // Ingredients completeness factor
        if let ingredientsText = obfProduct.ingredientsText, !ingredientsText.isEmpty {
            score += 3.0; factors += 1
        }
        
        // Image availability factor
        if obfProduct.imageURL != nil || obfProduct.imageFrontURL != nil {
            score += 2.0; factors += 1
        }
        
        // Calculate average rating (scale 1-5)
        guard factors > 0 else { return nil }
        let averageScore = score / Double(factors)
        
        // Normalize to 1-5 scale
        return min(5.0, max(1.0, averageScore))
    }
    
    private func parseIngredients(from ingredientsText: String?) -> [Ingredient] {
        guard let text = ingredientsText, !text.isEmpty else { return [] }
        
        // Simple ingredient parsing - split by common separators
        let ingredients = text.components(separatedBy: CharacterSet(charactersIn: ",;"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        return ingredients.map { ingredientText in
            Ingredient(
                inciName: ingredientText,
                commonName: ingredientText,
                role: "ingredient",
                note: "Ingredient from Open Beauty Facts"
            )
        }
    }
    
    private func extractConcerns(from categoriesTags: [String]?, labels: [String]?) -> [Concern] {
        var concerns: [Concern] = []
        
        let allTags = (categoriesTags ?? []) + (labels ?? [])
        
        for tag in allTags {
            let lowercased = tag.lowercased()
            if lowercased.contains("sensitive") || lowercased.contains("sensitivity") || lowercased.contains("hypoallergenic") {
                concerns.append(.sensitivity)
            } else if lowercased.contains("oily") || lowercased.contains("oiliness") || lowercased.contains("sebum") {
                concerns.append(.oiliness)
            } else if lowercased.contains("dry") || lowercased.contains("dryness") || lowercased.contains("moisturizing") {
                concerns.append(.dryness)
            } else if lowercased.contains("acne") || lowercased.contains("blemish") || lowercased.contains("anti-acne") {
                concerns.append(.acne)
            } else if lowercased.contains("aging") || lowercased.contains("wrinkle") || lowercased.contains("anti-aging") || lowercased.contains("anti-wrinkle") {
                concerns.append(.aging)
            } else if lowercased.contains("pigmentation") || lowercased.contains("dark spot") || lowercased.contains("brightening") || lowercased.contains("whitening") {
                concerns.append(.pigmentation)
            } else if lowercased.contains("redness") || lowercased.contains("irritation") {
                concerns.append(.redness)
            }
        }
        
        return Array(Set(concerns)) // Remove duplicates
    }
    
    private func parseDate(from timestamp: Int?) -> Date? {
        guard let timestamp = timestamp else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(timestamp))
    }
}

// MARK: - API Errors

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case networkError(Error)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}

