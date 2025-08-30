import Foundation

@MainActor
final class ProductsViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var query: String = ""
    @Published var debugMessage: String? = nil

    // favourites are stored as product UUIDs
    @Published private(set) var favoriteIDs: Set<UUID> = []

    private let store: DataStore

    init(store: DataStore) { self.store = store }

    func load() {
        Task {
            // 1) Load favorites first (so UI can instantly show hearts)
            let favs = (try? self.store.loadFavoriteIDs()) ?? []
            self.favoriteIDs = Set(favs)

            // 2) Load products from Documents or bundle
            if let items = try? self.store.loadProducts(), !items.isEmpty {
                self.products = items
                self.debugMessage = nil
                return
            }

            // Fallback: read directly from bundle (first run)
            if let url = Bundle.main.url(forResource: "products", withExtension: "json") {
                do {
                    let data = try Data(contentsOf: url)
                    let items = try JSONDecoder().decode([Product].self, from: data)

                    // Save to Documents so the file includes the persisted IDs
                    try? self.store.save(products: items)

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

    // MARK: Filtering
    var filtered: [Product] {
        guard !query.isEmpty else { return products }
        return products.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.brand.localizedCaseInsensitiveContains(query) ||
            $0.category.localizedCaseInsensitiveContains(query)
        }
    }

    var favorites: [Product] {
        products.filter { favoriteIDs.contains($0.id) }
    }

    // MARK: Favourites
    func toggleFavorite(_ product: Product) {
        if favoriteIDs.contains(product.id) {
            favoriteIDs.remove(product.id)
        } else {
            favoriteIDs.insert(product.id)
        }
        persistFavorites()
        objectWillChange.send()
    }

    func isFavorite(_ product: Product) -> Bool {
        favoriteIDs.contains(product.id)
    }

    private func persistFavorites() {
        try? store.save(favoriteIDs: Array(favoriteIDs))
    }
}
