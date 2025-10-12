import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var recommendations: [Product] = []

    private let store: DataStore
    init(store: DataStore) { self.store = store }

    func load() {
        Task {
            // Load products for recommendations
            let allProds = (try? self.store.loadProducts()) ?? []

            await MainActor.run {
                // Show first 5 products as recommendations
                self.recommendations = Array(allProds.prefix(5))
            }
        }
    }
}
