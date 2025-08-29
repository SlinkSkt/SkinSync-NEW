import Foundation

@MainActor
final class ProductsViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var query: String = ""
    @Published var debugMessage: String? = nil

    private let store: DataStore
    
    /// Use dependency injection in RootView, or call `ProductsViewModel(store: FileDataStore())`
    init(store: DataStore) { self.store = store }

    func load() {
        Task {
            // Try DataStore (which should check Documents and/or bundle)
            if let items = try? self.store.loadProducts() {
                self.products = items
                self.debugMessage = items.isEmpty ? "Loaded 0 products from DataStore." : nil
                return
            }

            // Fallback: read directly from bundle (helps first-run debugging)
            if let url = Bundle.main.url(forResource: "products", withExtension: "json") {
                do {
                    let data = try Data(contentsOf: url)
                    let items = try JSONDecoder().decode([Product].self, from: data)
                    self.products = items
                    self.debugMessage = items.isEmpty ? "Loaded 0 products from bundle." : nil
                } catch {
                    self.products = []
                    self.debugMessage = "Decode failed: \(error.localizedDescription)"
                }
            } else {
                self.products = []
                self.debugMessage = "Bundle couldn’t find products.json"
            }
        }
    }

    var filtered: [Product] {
        guard !query.isEmpty else { return products }
        return products.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.brand.localizedCaseInsensitiveContains(query) ||
            $0.category.localizedCaseInsensitiveContains(query)
        }
    }
}
