import Foundation
import SwiftUI
import FirebaseAuth

/// Manages Morning and Evening routine products with drag-to-reorder and persistence
@MainActor
final class RoutineViewModel: ObservableObject {
    
    // MARK: - Published State
    @Published var morning: [Product] = []
    @Published var evening: [Product] = []
    @Published var isDragging: Bool = false
    @Published var draggingProduct: Product?
    
    
    // MARK: - Dependencies
    let store: DataStore
    private let routineService: RoutineServicing
    let productRepository: ProductRepository?
    
    // MARK: - Init
    init(store: DataStore, productRepository: ProductRepository? = nil, routineService: RoutineServicing = RoutineService()) {
        self.store = store
        self.productRepository = productRepository
        self.routineService = routineService
        
        // Load from local storage first
        Task {
            await load()
        }
    }
    
    // MARK: - Loading
    func load() async {
        // Load morning routine
        if let morningData = try? store.loadData(for: .morningRoutine),
           let morningProducts = try? JSONDecoder().decode([Product].self, from: morningData) {
            morning = morningProducts
        }
        
        // Load evening routine
        if let eveningData = try? store.loadData(for: .eveningRoutine),
           let eveningProducts = try? JSONDecoder().decode([Product].self, from: eveningData) {
            evening = eveningProducts
        }
    }
    
    // MARK: - Add Products
    func addToMorning(_ product: Product) {
        // Prevent duplicates
        guard !morning.contains(where: { $0.id == product.id }) else {
            return
        }
        
        morning.append(product)
        saveMorning()
    }
    
    func addToEvening(_ product: Product) {
        // Prevent duplicates
        guard !evening.contains(where: { $0.id == product.id }) else {
            return
        }
        
        evening.append(product)
        saveEvening()
    }
    
    // MARK: - Reorder Products
    func moveMorning(from source: IndexSet, to destination: Int) {
        var snapshot = morning
        // Filter out any invalid indices that might have been produced by gesture math
        let validSource = IndexSet(source.filter { $0 >= 0 && $0 < snapshot.count })
        guard !validSource.isEmpty else {
            return
        }
        // Clamp destination to a valid insertion point [0...count]
        let clampedDestination = max(0, min(destination, snapshot.count))
        // Perform move on the snapshot first to avoid out-of-bounds on the live array
        snapshot.move(fromOffsets: validSource, toOffset: clampedDestination)
        morning = snapshot
        saveMorning()
    }
    
    func moveEvening(from source: IndexSet, to destination: Int) {
        var snapshot = evening
        // Filter out any invalid indices that might have been produced by gesture math
        let validSource = IndexSet(source.filter { $0 >= 0 && $0 < snapshot.count })
        guard !validSource.isEmpty else {
            return
        }
        // Clamp destination to a valid insertion point [0...count]
        let clampedDestination = max(0, min(destination, snapshot.count))
        // Perform move on the snapshot first to avoid out-of-bounds on the live array
        snapshot.move(fromOffsets: validSource, toOffset: clampedDestination)
        evening = snapshot
        saveEvening()
    }
    
    // MARK: - Remove Products
    func removeFromMorning(_ product: Product) {
        morning.removeAll { $0.id == product.id }
        saveMorning()
    }
    
    func removeFromEvening(_ product: Product) {
        evening.removeAll { $0.id == product.id }
        saveEvening()
    }
    
    // MARK: - Drag State Management
    func startDragging(_ product: Product) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            draggingProduct = product
            isDragging = true
        }
    }
    
    func endDragging() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
            draggingProduct = nil
            isDragging = false
        }
    }
    
    // MARK: - Persistence
    private func saveMorning() {
        do {
            let data = try JSONEncoder().encode(morning)
            try store.save(data: data, for: .morningRoutine)
            if Auth.auth().currentUser != nil {
                saveRoutineToCloud()
            }
        } catch { }
    }
    
    private func saveEvening() {
        do {
            let data = try JSONEncoder().encode(evening)
            try store.save(data: data, for: .eveningRoutine)
            
            if Auth.auth().currentUser != nil {
                saveRoutineToCloud() }
        } catch { }
    }
    
    // MARK: - Helper Methods
    func isProductInMorning(_ product: Product) -> Bool {
        morning.contains { $0.id == product.id }
    }
    
    func isProductInEvening(_ product: Product) -> Bool {
        evening.contains { $0.id == product.id }
    }
    
    func isProductInAnyRoutine(_ product: Product) -> Bool {
        isProductInMorning(product) || isProductInEvening(product)
    }
    // MARK: - Cloud Save
    func saveRoutineToCloud() {
        guard let user = Auth.auth().currentUser else {
            return
        }
        let payload = RoutinePayload(
            morning: morning.map { p in
                RoutineItemPayload(
                    id: p.id.uuidString,
                    name: p.name,
                    brand: p.brand,
                    category: p.category,
                    barcode: p.barcode
                )
            },
            evening: evening.map { p in
                RoutineItemPayload(
                    id: p.id.uuidString,
                    name: p.name,
                    brand: p.brand,
                    category: p.category,
                    barcode: p.barcode
                )
            },
            updatedAt: Date()
        )
        Task {
            do {
                try await routineService.save(userId: user.uid, payload: payload)
            } catch { }
        }
    }
    
    // MARK: - Cloud Load
    private func loadFromCloud(userId: String) async {
        do {
            guard let payload = try await routineService.load(userId: userId) else { return }
            let all = (try? store.loadProducts()) ?? []
            
            let am: [Product] = payload.morning.compactMap { item in
                guard let uuid = UUID(uuidString: item.id) else { return nil }
                return all.first { $0.id == uuid }
            }
            
            let pm: [Product] = payload.evening.compactMap { item in
                guard let uuid = UUID(uuidString: item.id) else { return nil }
                return all.first { $0.id == uuid }
            }
            
            await MainActor.run {
                self.morning = am
                self.evening = pm
            }
        } catch { }
    }
}
