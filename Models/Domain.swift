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

enum Concern: String, Codable, CaseIterable, Identifiable, Hashable {
    case acne, redness, pigmentation, sensitivity, aging, dryness, oiliness, pores
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

struct Profile: Codable, Equatable {
    var nickname: String
    var yearOfBirthRange: String
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
        self.id = UUID() // synthesize
    }
}

struct Product: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var brand: String
    var category: String
    var assetName: String            // assets-only image name
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
        self.id          = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()   //keep existing ID if present
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
        try c.encode(id, forKey: .id)                        // persist the UUID
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

struct RoutineSlot: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var step: String
    var productID: UUID?
}

struct Routine: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String   // "AM" or "PM"
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

// MARK: - Day Log

struct DayLog: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var dateKey: String
    var completedSlotIDs: [UUID]
}

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
