// ViewModels/ViewModels.swift
import Foundation
import UIKit

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var latestScan: FaceScanResult? = nil
    @Published var recommendations: [Product] = []
    private let store: DataStore
    init(store: DataStore) { self.store = store }
    func load() {
        do {
            let scans = try store.loadScans().sorted(by: { $0.timestamp > $1.timestamp })
            latestScan = scans.first
            try recomputeRecommendations()
        } catch {
            latestScan = nil; recommendations = []
        }
    }
    func recomputeRecommendations() throws {
        let products = try store.loadProducts()
        guard let concerns = latestScan?.concerns else { recommendations = []; return }
        recommendations = products.filter { !Set($0.concerns).isDisjoint(with: Set(concerns)) }
    }
}

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var profile: Profile
    private let store: DataStore
    init(store: DataStore) {
        self.store = store
        self.profile = (try? store.loadProfile()) ?? Profile(nickname: "Guest", yearOfBirthRange: "2001-2005",
                                                             skinType: .combination, allergies: [], goals: [.hydrate])
    }
    func save() { try? store.save(profile: profile) }
}

@MainActor
final class ProductsViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var query: String = ""
    private let store: DataStore
    init(store: DataStore) { self.store = store }
    func load() { products = (try? store.loadProducts()) ?? [] }
    var filtered: [Product] {
        guard !query.isEmpty else { return products }
        return products.filter { $0.name.localizedCaseInsensitiveContains(query) || $0.brand.localizedCaseInsensitiveContains(query) }
    }
}

@MainActor
final class RoutineViewModel: ObservableObject {
    @Published var routines: [Routine] = []
    @Published var productsByID: [UUID: Product] = [:]
    @Published var notif: NotificationPrefs
    private let store: DataStore
    private let scheduler: NotificationScheduler
    
    init(store: DataStore, scheduler: NotificationScheduler) {
        self.store = store
        self.scheduler = scheduler
        self.notif = (try? store.loadNotificationPrefs()) ?? NotificationPrefs(enableAM: false, amHour: 7, amMinute: 30, enablePM: false, pmHour: 21, pmMinute: 0)
    }
    func load() {
        do {
            let prods = try store.loadProducts()
            productsByID = Dictionary(uniqueKeysWithValues: prods.map { ($0.id, $0) })
            routines = try store.loadRoutines()
        } catch { routines = [] }
    }
    func save() { try? store.save(routines: routines) }
    func set(product: Product?, for routineID: UUID, slotID: UUID) {
        guard let rIndex = routines.firstIndex(where: { $0.id == routineID }),
              let sIndex = routines[rIndex].slots.firstIndex(where: { $0.id == slotID }) else { return }
        routines[rIndex].slots[sIndex].productID = product?.id
        save()
    }
    func applyNotificationPrefs(_ prefs: NotificationPrefs) async {
        self.notif = prefs
        try? store.save(notificationPrefs: prefs)
        let granted = await scheduler.requestAuth()
        guard granted else { return }
        if prefs.enableAM {
            try? await scheduler.scheduleDaily(identifier: "skinsync.am", hour: prefs.amHour, minute: prefs.amMinute, body: "Time for your AM routine.")
        } else { await scheduler.cancel(identifier: "skinsync.am") }
        if prefs.enablePM {
            try? await scheduler.scheduleDaily(identifier: "skinsync.pm", hour: prefs.pmHour, minute: prefs.pmMinute, body: "Time for your PM routine.")
        } else { await scheduler.cancel(identifier: "skinsync.pm") }
    }
}

@MainActor
final class ScanViewModel: ObservableObject {
    @Published var scannedProduct: Product? = nil
    @Published var analyzingFace: Bool = false
    @Published var lastFaceScan: FaceScanResult? = nil
    
    private let productAPI: ProductAPI
    private let faceAPI: FaceScanService
    private let store: DataStore
    
    init(productAPI: ProductAPI, faceAPI: FaceScanService, store: DataStore) {
        self.productAPI = productAPI
        self.faceAPI = faceAPI
        self.store = store
    }
    func onBarcode(_ code: String) {
        Task { self.scannedProduct = try await productAPI.product(byBarcode: code) }
    }
    func analyzeFace(image: UIImage) {
        Task {
            analyzingFace = true
            let concerns = try await faceAPI.analyze(image: image)
            let result = FaceScanResult(timestamp: Date(), concerns: concerns, notes: "Auto-detected concerns (demo)")
            var scans = (try? store.loadScans()) ?? []
            scans.insert(result, at: 0)
            try? store.save(scans: scans)
            self.lastFaceScan = result
            self.analyzingFace = false
        }
    }
}
