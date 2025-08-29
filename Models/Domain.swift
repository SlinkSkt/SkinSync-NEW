// Models/Domain.swift
import Foundation

// MARK: - User & Skin

enum SkinType: String, Codable, CaseIterable, Identifiable {
    case normal, dry, oily, combination, sensitive
    var id: String { rawValue }
}

enum SkinGoal: String, Codable, CaseIterable, Identifiable {
    case clearAcne = "Clear Acne"
    case reduceRedness = "Reduce Redness"
    case brighten = "Brighten"
    case antiAging = "Anti-aging"
    case oilControl = "Oil Control"
    case hydrate = "Hydrate"
    var id: String { rawValue }
}

// All strings used in your products.json are covered here.
enum Concern: String, Codable, CaseIterable, Identifiable, Hashable {
    case acne, redness, pigmentation, sensitivity, aging, dryness, oiliness, pores
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

struct Profile: Codable, Equatable {
    var nickname: String
    var yearOfBirthRange: String // e.g., "2001-2005"
    var skinType: SkinType
    var allergies: [String]
    var goals: [SkinGoal]
}

// MARK: - Products

struct Ingredient: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var inciName: String
    var commonName: String
    var role: String
    var note: String?

    private enum CodingKeys: String, CodingKey {
        case inciName, commonName, role, note
    }

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
        self.id = UUID()
    }
}

struct Product: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var brand: String
    var category: String
    var imageURL: String?
    var concerns: [Concern]
    var ingredients: [Ingredient]
    var barcode: String
    var rating: Double?

    private enum CodingKeys: String, CodingKey {
        case name, brand, category, imageURL, concerns, ingredients, barcode, rating
    }

    init(name: String, brand: String, category: String, imageURL: String?, concerns: [Concern],
         ingredients: [Ingredient], barcode: String, rating: Double?) {
        self.name = name
        self.brand = brand
        self.category = category
        self.imageURL = imageURL
        self.concerns = concerns
        self.ingredients = ingredients
        self.barcode = barcode
        self.rating = rating
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.name        = try c.decode(String.self, forKey: .name)
        self.brand       = try c.decode(String.self, forKey: .brand)
        self.category    = try c.decode(String.self, forKey: .category)
        self.imageURL    = try c.decodeIfPresent(String.self, forKey: .imageURL)
        self.concerns    = try c.decode([Concern].self, forKey: .concerns)
        self.ingredients = try c.decode([Ingredient].self, forKey: .ingredients)
        self.barcode     = try c.decode(String.self, forKey: .barcode)
        self.rating      = try c.decodeIfPresent(Double.self, forKey: .rating)
        self.id = UUID()
    }
}
// MARK: - Routines

struct RoutineSlot: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var step: String        // "Cleanser", "Treatment", "Moisturiser", "Sunscreen", etc.
    var productID: UUID?
}

struct Routine: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String       // "AM" or "PM"
    var slots: [RoutineSlot]
}

// MARK: - Face Scan

struct FaceScanResult: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var timestamp: Date
    var concerns: [Concern]
    var notes: String?
}

// MARK: - Notifications

struct NotificationPrefs: Codable, Equatable {
    var enableAM: Bool; var amHour: Int; var amMinute: Int
    var enablePM: Bool; var pmHour: Int; var pmMinute: Int
}

// MARK: - Daily Progress (no database)

struct DayLog: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    /// Date-only key in ISO format (YYYY-MM-DD)
    var dateKey: String
    /// Completed routine slot IDs for this day (AM/PM combined)
    var completedSlotIDs: [UUID]
}

// MARK: - Helpers

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
