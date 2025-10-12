import Foundation

// MARK: - DataStore protocol
/// Abstract store used by all view models. Implemented by FileDataStore.
protocol DataStore {
    // Products
    func loadProducts() throws -> [Product]
    func save(products: [Product]) throws
    func deleteProducts() throws

    // Routines
    func loadRoutines() throws -> [Routine]
    func save(routines: [Routine]) throws


    // Profile
    func loadProfile() throws -> Profile
    func save(profile: Profile) throws

    // Notification preferences
    func loadNotificationPrefs() throws -> NotificationPrefs
    func save(notificationPrefs: NotificationPrefs) throws

    // Daily logs (checkboxes done per day)
    func loadDayLogs() throws -> [DayLog]
    func save(dayLogs: [DayLog]) throws
    
    // DataStore.swift  (add to the protocol)
    func loadFavoriteIDs() throws -> [UUID]
    func save(favoriteIDs: [UUID]) throws
    
    // Routine data (for new RoutineViewModel)
    func loadData(for key: RoutineDataKey) throws -> Data?
    func save(data: Data, for key: RoutineDataKey) throws
}

// MARK: - Routine Data Keys
enum RoutineDataKey: String, CaseIterable {
    case morningRoutine = "morning_routine"
    case eveningRoutine = "evening_routine"
}

// MARK: - FileDataStore
/// JSON-backed store. Reads/writes to the app's Documents folder.
/// On first run, falls back to bundled JSON (Copy Bundle Resources).
final class FileDataStore: DataStore {

    // Filenames used for JSON payloads
    private enum FileName: String {
        case products   = "products.json"
        case routines   = "routines.json"
        case scans      = "scans.json"
        case profile    = "profile.json"
        case notif      = "notification_prefs.json"
        case daylogs    = "daylogs.json"
        case favorites  = "favorites.json"
        case morningRoutine = "morning_routine.json"
        case eveningRoutine = "evening_routine.json"
    }

    private let fm = FileManager.default
   
    // MARK: Public seeding (optional)
    /// Call once on launch to ensure sample JSON exists in Documents.
    /// - Copies bundled files if present
    /// - Or creates sensible defaults for routines/products
    func seedIfNeeded() {
        // Seed products
        do {
            let prodURL = try docURL(FileName.products.rawValue)
            if !fm.fileExists(atPath: prodURL.path) {
                if let src = bundledURL(FileName.products.rawValue) {
                    try fm.copyItem(at: src, to: prodURL)
                } else {
                    // If no bundle file, create empty array
                    try save(products: [])
                }
            }
        } catch { }

        // Seed routines
        do {
            let routinesURL = try docURL(FileName.routines.rawValue)
            if !fm.fileExists(atPath: routinesURL.path) {
                if let src = bundledURL(FileName.routines.rawValue) {
                    try fm.copyItem(at: src, to: routinesURL)
                } else {
                    // Create sensible defaults if nothing bundled
                    let defaultRoutines = [
                        Routine(
                            title: "AM",
                            slots: [
                                RoutineSlot(step: "Cleanser", productID: nil),
                                RoutineSlot(step: "Treatment", productID: nil),
                                RoutineSlot(step: "Moisturiser", productID: nil),
                                RoutineSlot(step: "Sunscreen", productID: nil)
                            ]
                        ),
                        Routine(
                            title: "PM",
                            slots: [
                                RoutineSlot(step: "Cleanser", productID: nil),
                                RoutineSlot(step: "Treatment", productID: nil),
                                RoutineSlot(step: "Moisturiser", productID: nil)
                            ]
                        )
                    ]
                    try save(routines: defaultRoutines)
                }
            }
        } catch { }

        // Other JSON files (scans, profile, notif, daylogs)
        for name in [FileName.scans, .profile, .notif, .daylogs] {
            do {
                let dst = try docURL(name.rawValue)
                guard !fm.fileExists(atPath: dst.path) else { continue }
                if let src = bundledURL(name.rawValue) {
                    try fm.copyItem(at: src, to: dst)
                }
            } catch { }
        }
        // Seed favourites (create empty file if none exists in bundle)
        do {
            let favURL = try docURL(FileName.favorites.rawValue)
            if !fm.fileExists(atPath: favURL.path) {
                if let src = bundledURL(FileName.favorites.rawValue) {
                    try fm.copyItem(at: src, to: favURL)
                } else {
                    try save(favoriteIDs: [])
                }
            }
        } catch { }
    }

    // MARK: - DataStore conformance

    // Products
    func loadProducts() throws -> [Product] {
        try loadArray([Product].self, name: .products)
    }
    func save(products: [Product]) throws {
        try saveEncodable(products, name: .products)
    }
    func deleteProducts() throws {
        try deleteFile(name: .products)
    }

    // Routines
    func loadRoutines() throws -> [Routine] {
        try loadArray([Routine].self, name: .routines)
    }
    func save(routines: [Routine]) throws {
        try saveEncodable(routines, name: .routines)
    }


    // Profile
    func loadProfile() throws -> Profile {
        if let url = try? existingOrBundledURL(.profile) {
            return try decode(Profile.self, from: url)
        }
        // sensible empty default if nothing bundled
        return Profile(nickname: "", yearOfBirthRange: "", email: "", phoneNumber: "", skinType: .normal, allergies: [], goals: [], profileIcon: "person.fill")
    }
    func save(profile: Profile) throws {
        try saveEncodable(profile, name: .profile)
    }

    // Notification prefs
    func loadNotificationPrefs() throws -> NotificationPrefs {
        if let url = try? existingOrBundledURL(.notif) {
            return try decode(NotificationPrefs.self, from: url)
        }
        return NotificationPrefs(enableAM: false, amHour: 7, amMinute: 30,
                                 enablePM: false, pmHour: 21, pmMinute: 0)
    }
    func save(notificationPrefs: NotificationPrefs) throws {
        try saveEncodable(notificationPrefs, name: .notif)
    }

    // Day logs
    func loadDayLogs() throws -> [DayLog] {
        try loadArray([DayLog].self, name: .daylogs)
    }
    func save(dayLogs: [DayLog]) throws {
        try saveEncodable(dayLogs, name: .daylogs)
    }
    // FileDataStore
    func loadFavoriteIDs() throws -> [UUID] {
        // If not present yet, return empty
        if let url = try? existingOrBundledURL(.favorites) {
            return try decode([UUID].self, from: url)
        }
        return []
    }
    func save(favoriteIDs: [UUID]) throws {
        try saveEncodable(favoriteIDs, name: .favorites)
    }
    // MARK: - Generic helpers

    private func loadArray<T: Decodable>(_ type: T.Type, name: FileName) throws -> T {
        if let url = try? existingOrBundledURL(name) {
            return try decode(T.self, from: url)
        }
        // empty array default if neither docs nor bundle exists
        if T.self is [Any].Type { return [] as! T }
        throw NSError(domain: "FileDataStore", code: 404,
                      userInfo: [NSLocalizedDescriptionKey: "Missing \(name.rawValue)"])
    }

    private func saveEncodable<T: Encodable>(_ value: T, name: FileName) throws {
        let url = try docURL(name.rawValue)
        let data = try encoder.encode(value)
        try data.write(to: url, options: .atomic)
    }
    
    private func deleteFile(name: FileName) throws {
        let url = try docURL(name.rawValue)
        if fm.fileExists(atPath: url.path) {
            try fm.removeItem(at: url)
        }
    }

    private func existingOrBundledURL(_ name: FileName) throws -> URL {
        let docs = try docURL(name.rawValue)
        if fm.fileExists(atPath: docs.path) { return docs }
        if let bundled = bundledURL(name.rawValue) { return bundled }
        throw NSError(domain: "FileDataStore", code: 404,
                      userInfo: [NSLocalizedDescriptionKey: "File \(name.rawValue) not found"])
    }

    // MARK: Paths

    private func docURL(_ filename: String) throws -> URL {
        let dir = try fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return dir.appendingPathComponent(filename)
    }

    private func bundledURL(_ filename: String) -> URL? {
        let parts = filename.split(separator: ".", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return nil }
        return Bundle.main.url(forResource: parts[0], withExtension: parts[1])
    }

    // MARK: JSON codecs

    private var decoder: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }

    private var encoder: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }

    private func decode<T: Decodable>(_ type: T.Type, from url: URL) throws -> T {
        let data = try Data(contentsOf: url)
        return try decoder.decode(T.self, from: data)
    }
    
    // MARK: - Routine Data Methods
    func loadData(for key: RoutineDataKey) throws -> Data? {
        let fileName: FileName
        switch key {
        case .morningRoutine:
            fileName = .morningRoutine
        case .eveningRoutine:
            fileName = .eveningRoutine
        }
        
        let url = try docURL(fileName.rawValue)
        guard fm.fileExists(atPath: url.path) else { return nil }
        return try Data(contentsOf: url)
    }
    
    func save(data: Data, for key: RoutineDataKey) throws {
        let fileName: FileName
        switch key {
        case .morningRoutine:
            fileName = .morningRoutine
        case .eveningRoutine:
            fileName = .eveningRoutine
        }
        
        let url = try docURL(fileName.rawValue)
        try data.write(to: url)
    }
}
