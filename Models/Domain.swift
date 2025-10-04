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

    private enum CodingKeys: String, CodingKey {
        case id, name, brand, category, assetName, concerns, ingredients, barcode, rating
    }

    init(id: UUID = UUID(),
         name: String,
         brand: String,
         category: String,
         assetName: String,
         concerns: [Concern],
         ingredients: [Ingredient],
         barcode: String,
         rating: Double?) {
        self.id = id
        self.name = name
        self.brand = brand
        self.category = category
        self.assetName = assetName
        self.concerns = concerns
        self.ingredients = ingredients
        self.barcode = barcode
        self.rating = rating
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

// MARK: - Face Scan

/// Stores results of a face scan
struct FaceScanResult: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var timestamp: Date
    var concerns: [Concern]
    var notes: String?
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
