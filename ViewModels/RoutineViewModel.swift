import Foundation
import SwiftUI

/// Manages Morning and Evening routine products with drag-to-reorder and persistence
@MainActor
final class RoutineViewModel: ObservableObject {
    
    // MARK: - Published State
    @Published var morning: [Product] = []
    @Published var evening: [Product] = []
    @Published var isDragging: Bool = false
    @Published var draggingProduct: Product?
    
    // MARK: - Dependencies
    private let store: DataStore
    private let productRepository: ProductRepository?
    
    // MARK: - Init
    init(store: DataStore, productRepository: ProductRepository? = nil) {
        self.store = store
        self.productRepository = productRepository
        print("🔄 RoutineViewModel: Initialized")
    }
    
    // MARK: - Loading
    func load() async {
        print("🔄 RoutineViewModel: Loading routines...")
        
        // Load morning routine
        if let morningData = try? store.loadData(for: .morningRoutine),
           let morningProducts = try? JSONDecoder().decode([Product].self, from: morningData) {
            morning = morningProducts
            print("🔄 RoutineViewModel: Loaded \(morningProducts.count) morning products")
        }
        
        // Load evening routine
        if let eveningData = try? store.loadData(for: .eveningRoutine),
           let eveningProducts = try? JSONDecoder().decode([Product].self, from: eveningData) {
            evening = eveningProducts
            print("🔄 RoutineViewModel: Loaded \(eveningProducts.count) evening products")
        }
        
        print("🔄 RoutineViewModel: Load complete - Morning: \(morning.count), Evening: \(evening.count)")
    }
    
    // MARK: - Add Products
    func addToMorning(_ product: Product) {
        // Prevent duplicates
        guard !morning.contains(where: { $0.id == product.id }) else {
            print("🔄 RoutineViewModel: Product already in morning routine")
            return
        }
        
        morning.append(product)
        saveMorning()
        print("🔄 RoutineViewModel: Added '\(product.name)' to morning routine")
    }
    
    func addToEvening(_ product: Product) {
        // Prevent duplicates
        guard !evening.contains(where: { $0.id == product.id }) else {
            print("🔄 RoutineViewModel: Product already in evening routine")
            return
        }
        
        evening.append(product)
        saveEvening()
        print("🔄 RoutineViewModel: Added '\(product.name)' to evening routine")
    }
    
    // MARK: - Reorder Products
    func moveMorning(from source: IndexSet, to destination: Int) {
        var snapshot = morning
        // Filter out any invalid indices that might have been produced by gesture math
        let validSource = IndexSet(source.filter { $0 >= 0 && $0 < snapshot.count })
        guard !validSource.isEmpty else {
            print("🔄 RoutineViewModel: moveMorning skipped — empty/invalid source: \(source)")
            return
        }
        // Clamp destination to a valid insertion point [0...count]
        let clampedDestination = max(0, min(destination, snapshot.count))
        // Perform move on the snapshot first to avoid out-of-bounds on the live array
        snapshot.move(fromOffsets: validSource, toOffset: clampedDestination)
        morning = snapshot
        saveMorning()
        print("🔄 RoutineViewModel: Reordered morning routine (source: \(Array(validSource)), dest: \(clampedDestination))")
    }
    
    func moveEvening(from source: IndexSet, to destination: Int) {
        var snapshot = evening
        // Filter out any invalid indices that might have been produced by gesture math
        let validSource = IndexSet(source.filter { $0 >= 0 && $0 < snapshot.count })
        guard !validSource.isEmpty else {
            print("🔄 RoutineViewModel: moveEvening skipped — empty/invalid source: \(source)")
            return
        }
        // Clamp destination to a valid insertion point [0...count]
        let clampedDestination = max(0, min(destination, snapshot.count))
        // Perform move on the snapshot first to avoid out-of-bounds on the live array
        snapshot.move(fromOffsets: validSource, toOffset: clampedDestination)
        evening = snapshot
        saveEvening()
        print("🔄 RoutineViewModel: Reordered evening routine (source: \(Array(validSource)), dest: \(clampedDestination))")
    }
    
    // MARK: - Remove Products
    func removeFromMorning(_ product: Product) {
        morning.removeAll { $0.id == product.id }
        saveMorning()
        print("🔄 RoutineViewModel: Removed '\(product.name)' from morning routine")
    }
    
    func removeFromEvening(_ product: Product) {
        evening.removeAll { $0.id == product.id }
        saveEvening()
        print("🔄 RoutineViewModel: Removed '\(product.name)' from evening routine")
    }
    
    // MARK: - Drag State Management
    func startDragging(_ product: Product) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            draggingProduct = product
            isDragging = true
        }
        print("🔄 RoutineViewModel: Started dragging '\(product.name)'")
    }
    
    func endDragging() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
            draggingProduct = nil
            isDragging = false
        }
        print("🔄 RoutineViewModel: Ended dragging")
    }
    
    // MARK: - Persistence
    private func saveMorning() {
        do {
            let data = try JSONEncoder().encode(morning)
            try store.save(data: data, for: .morningRoutine)
        } catch {
            print("🔄 RoutineViewModel: Failed to save morning routine: \(error)")
        }
    }
    
    private func saveEvening() {
        do {
            let data = try JSONEncoder().encode(evening)
            try store.save(data: data, for: .eveningRoutine)
        } catch {
            print("🔄 RoutineViewModel: Failed to save evening routine: \(error)")
        }
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
}
