import Foundation

@MainActor
final class ProductsViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var query: String = ""
    @Published var debugMessage: String? = nil

    /// Favourites are stored as product UUIDs.
    @Published private(set) var favoriteIDs: Set<UUID> = []

    private let store: DataStore

    init(store: DataStore) { self.store = store }

    /// Convenience entry point for Views (non-async).
    func load() {
        Task { await loadAsync() }
    }

    /// Async-friendly loader ( for tests or future expansion).
    func loadAsync() async {
        // Load favorites first so hearts show immediately
        let favs = (try? store.loadFavoriteIDs()) ?? []
        favoriteIDs = Set(favs)

        // Load products from Documents or bundle
        if let items = try? store.loadProducts(), !items.isEmpty {
            products = items
            debugMessage = nil
            return
        }

        // Fallback: seed from bundle on first run
        if let url = Bundle.main.url(forResource: "products", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let items = try JSONDecoder().decode([Product].self, from: data)

                // Save to Documents so future loads come from the same place
                try? store.save(products: items)

                products = items
                debugMessage = items.isEmpty ? "Loaded 0 products from bundle." : nil
            } catch {
                products = []
                debugMessage = "Decode failed: \(error.localizedDescription)"
            }
        } else {
            products = []
            debugMessage = "Bundle couldn’t find products.json"
        }
    }

    // MARK: - Derived collections

    var filtered: [Product] {
        guard !query.isEmpty else { return products }
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return products }
        return products.filter {
            $0.name.localizedCaseInsensitiveContains(q) ||
            $0.brand.localizedCaseInsensitiveContains(q) ||
            $0.category.localizedCaseInsensitiveContains(q)
        }
    }

    var favorites: [Product] {
        products.filter { favoriteIDs.contains($0.id) }
    }

    // MARK: - Favourites

    func toggleFavorite(_ product: Product) {
        if favoriteIDs.contains(product.id) {
            favoriteIDs.remove(product.id)
        } else {
            favoriteIDs.insert(product.id)
        }
        persistFavorites()
    }

    func isFavorite(_ product: Product) -> Bool {
        favoriteIDs.contains(product.id)
    }

    private func persistFavorites() {
        do {
            try store.save(favoriteIDs: Array(favoriteIDs))
        } catch {
            // capture an error message for debugging
            debugMessage = "Failed to save favourites: \(error.localizedDescription)"
        }
    }
}
