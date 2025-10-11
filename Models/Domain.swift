// Models/Domain.swift
// Defines the core domain models for the SkinSync app.
// Each struct/enum here represents a piece of the app’s data model,
// and most conform to `Codable` (for JSON persistence) and `Identifiable` (for SwiftUI lists).
// https://docs.swift.org/swift-book/documentation/the-swift-programming-language/enumerations/ - Zhen Xiao
// https://developer.apple.com/documentation/foundation/uuid
// Week 4 practical Note: JSONDECODER
import Foundation

// MARK: - User & Skin

/// Supported skin types
enum SkinType: String, Codable, CaseIterable, Identifiable {
    case normal, dry, oily, combination, sensitive
    var id: String { rawValue }
}

/// Goals a user might track for their skincare routine
enum SkinGoal: String, Codable, CaseIterable, Identifiable {
    case clearAcne = "Clear Acne"
    case reduceRedness = "Reduce Redness"
    case brighten = "Brighten"
    case antiAging = "Anti-aging"
    case oilControl = "Oil Control"
    case hydrate = "Hydrate"
    var id: String { rawValue }
}

/// Common skin concerns detected or tracked
enum Concern: String, Codable, CaseIterable, Identifiable, Hashable {
    case acne, redness, pigmentation, sensitivity, aging, dryness, oiliness, pores
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

/// User profile with basic demographic and skin information
struct Profile: Codable, Equatable {
    var nickname: String
    var yearOfBirthRange: String
    var email: String
    var phoneNumber: String
    var skinType: SkinType
    var allergies: [String]
    var goals: [SkinGoal]
    var profileIcon: String
}

// MARK: - Products

/// A skincare ingredient
struct Ingredient: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var inciName: String       // Scientific INCI name
    var commonName: String     // Common name shown to users
    var role: String           // Function (e.g., "hydrator", "exfoliant")
    var note: String?          // Safety or usage notes

    private enum CodingKeys: String, CodingKey { case inciName, commonName, role, note }

    init(inciName: String, commonName: String, role: String, note: String?) {
        self.inciName = inciName
        self.commonName = commonName
        self.role = role
        self.note = note
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.inciName = try c.decode(String.self, forKey: .inciName)
        self.commonName = try c.decode(String.self, forKey: .commonName)
        self.role = try c.decode(String.self, forKey: .role)
        self.note = try c.decodeIfPresent(String.self, forKey: .note)
        self.id = UUID() // new ID each decode to avoid collisions
    }
}

/// A skincare product in the catalog
struct Product: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var brand: String
    var category: String
    var assetName: String            // local asset name for product image
    var concerns: [Concern]
    var ingredients: [Ingredient]
    var barcode: String
    var rating: Double?
    
    // Open Beauty Facts enhanced fields
    var imageURL: String?             // Remote image URL from OBF
    var quantity: String?              // Product size/quantity
    var productLabels: [String]?       // Product labels (cruelty-free, vegan, etc.)
    var productCategories: [String]?   // Detailed categories
    var allergens: [String]?          // Known allergens
    var traces: [String]?             // Trace ingredients
    var additives: [String]?          // Food additives
    var nutritionGrade: String?       // Nutrition grade if available
    var ingredientsText: String?      // Raw ingredients text from OBF
    var lastModified: Date?           // Last modification date
    var createdDate: Date?            // Creation date
    var isFromOpenBeautyFacts: Bool = false  // Flag to indicate OBF source

    private enum CodingKeys: String, CodingKey {
        case id, name, brand, category, assetName, concerns, ingredients, barcode, rating
        case imageURL, quantity, productLabels, productCategories, allergens, traces, additives
        case nutritionGrade, ingredientsText, lastModified, createdDate, isFromOpenBeautyFacts
    }

    init(id: UUID = UUID(),
         name: String,
         brand: String,
         category: String,
         assetName: String,
         concerns: [Concern],
         ingredients: [Ingredient],
         barcode: String,
         rating: Double? = nil,
         imageURL: String? = nil,
         quantity: String? = nil,
         productLabels: [String]? = nil,
         productCategories: [String]? = nil,
         allergens: [String]? = nil,
         traces: [String]? = nil,
         additives: [String]? = nil,
         nutritionGrade: String? = nil,
         ingredientsText: String? = nil,
         lastModified: Date? = nil,
         createdDate: Date? = nil,
         isFromOpenBeautyFacts: Bool = false) {
        self.id = id
        self.name = name
        self.brand = brand
        self.category = category
        self.assetName = assetName
        self.concerns = concerns
        self.ingredients = ingredients
        self.barcode = barcode
        self.rating = rating
        self.imageURL = imageURL
        self.quantity = quantity
        self.productLabels = productLabels
        self.productCategories = productCategories
        self.allergens = allergens
        self.traces = traces
        self.additives = additives
        self.nutritionGrade = nutritionGrade
        self.ingredientsText = ingredientsText
        self.lastModified = lastModified
        self.createdDate = createdDate
        self.isFromOpenBeautyFacts = isFromOpenBeautyFacts
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id          = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID() // preserve or regenerate ID
        self.name        = try c.decode(String.self, forKey: .name)
        self.brand       = try c.decode(String.self, forKey: .brand)
        self.category    = try c.decode(String.self, forKey: .category)
        self.assetName   = try c.decode(String.self, forKey: .assetName)
        self.concerns    = try c.decode([Concern].self, forKey: .concerns)
        self.ingredients = try c.decode([Ingredient].self, forKey: .ingredients)
        self.barcode     = try c.decode(String.self, forKey: .barcode)
        self.rating      = try c.decodeIfPresent(Double.self, forKey: .rating)
        
        // Open Beauty Facts fields
        self.imageURL = try c.decodeIfPresent(String.self, forKey: .imageURL)
        self.quantity = try c.decodeIfPresent(String.self, forKey: .quantity)
        self.productLabels = try c.decodeIfPresent([String].self, forKey: .productLabels)
        self.productCategories = try c.decodeIfPresent([String].self, forKey: .productCategories)
        self.allergens = try c.decodeIfPresent([String].self, forKey: .allergens)
        self.traces = try c.decodeIfPresent([String].self, forKey: .traces)
        self.additives = try c.decodeIfPresent([String].self, forKey: .additives)
        self.nutritionGrade = try c.decodeIfPresent(String.self, forKey: .nutritionGrade)
        self.ingredientsText = try c.decodeIfPresent(String.self, forKey: .ingredientsText)
        self.lastModified = try c.decodeIfPresent(Date.self, forKey: .lastModified)
        self.createdDate = try c.decodeIfPresent(Date.self, forKey: .createdDate)
        self.isFromOpenBeautyFacts = try c.decodeIfPresent(Bool.self, forKey: .isFromOpenBeautyFacts) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(brand, forKey: .brand)
        try c.encode(category, forKey: .category)
        try c.encode(assetName, forKey: .assetName)
        try c.encode(concerns, forKey: .concerns)
        try c.encode(ingredients, forKey: .ingredients)
        try c.encode(barcode, forKey: .barcode)
        try c.encodeIfPresent(rating, forKey: .rating)
        
        // Open Beauty Facts fields
        try c.encodeIfPresent(imageURL, forKey: .imageURL)
        try c.encodeIfPresent(quantity, forKey: .quantity)
        try c.encodeIfPresent(productLabels, forKey: .productLabels)
        try c.encodeIfPresent(productCategories, forKey: .productCategories)
        try c.encodeIfPresent(allergens, forKey: .allergens)
        try c.encodeIfPresent(traces, forKey: .traces)
        try c.encodeIfPresent(additives, forKey: .additives)
        try c.encodeIfPresent(nutritionGrade, forKey: .nutritionGrade)
        try c.encodeIfPresent(ingredientsText, forKey: .ingredientsText)
        try c.encodeIfPresent(lastModified, forKey: .lastModified)
        try c.encodeIfPresent(createdDate, forKey: .createdDate)
        try c.encode(isFromOpenBeautyFacts, forKey: .isFromOpenBeautyFacts)
    }
    
    // MARK: - Hashable & Equatable Conformance
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(brand)
        hasher.combine(category)
        hasher.combine(barcode)
        hasher.combine(rating)
        hasher.combine(imageURL)
        hasher.combine(quantity)
        hasher.combine(productLabels)
        hasher.combine(productCategories)
        hasher.combine(allergens)
        hasher.combine(traces)
        hasher.combine(additives)
        hasher.combine(nutritionGrade)
        hasher.combine(ingredientsText)
        hasher.combine(lastModified)
        hasher.combine(createdDate)
        hasher.combine(isFromOpenBeautyFacts)
        hasher.combine(concerns)
        hasher.combine(ingredients)
    }
    
    static func == (lhs: Product, rhs: Product) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.brand == rhs.brand &&
               lhs.category == rhs.category &&
               lhs.barcode == rhs.barcode &&
               lhs.rating == rhs.rating &&
               lhs.imageURL == rhs.imageURL &&
               lhs.quantity == rhs.quantity &&
               lhs.productLabels == rhs.productLabels &&
               lhs.productCategories == rhs.productCategories &&
               lhs.allergens == rhs.allergens &&
               lhs.traces == rhs.traces &&
               lhs.additives == rhs.additives &&
               lhs.nutritionGrade == rhs.nutritionGrade &&
               lhs.ingredientsText == rhs.ingredientsText &&
               lhs.lastModified == rhs.lastModified &&
               lhs.createdDate == rhs.createdDate &&
               lhs.isFromOpenBeautyFacts == rhs.isFromOpenBeautyFacts &&
               lhs.concerns == rhs.concerns &&
               lhs.ingredients == rhs.ingredients
    }
}

// MARK: - Routines

/// A slot within a skincare routine (e.g., "Cleanser", "Moisturiser")
struct RoutineSlot: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var step: String
    var productID: UUID?   // optional link to a Product
}

/// A skincare routine (AM or PM) containing multiple slots
struct Routine: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String       // "AM" or "PM"
    var slots: [RoutineSlot]
}


// MARK: - Notifications

/// User’s reminder preferences
struct NotificationPrefs: Codable, Equatable {
    var enableAM: Bool
    var amHour: Int
    var amMinute: Int
    var enablePM: Bool
    var pmHour: Int
    var pmMinute: Int
}

// MARK: - Daily Log

/// Daily log of completed routine slots
struct DayLog: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var dateKey: String        // "yyyy-MM-dd"
    var completedSlotIDs: [UUID]
}

/// Helper to format a Date as a skinsync log key
extension Date {
    var skinsyncDateKey: String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_AU")
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: self)
    }
}
