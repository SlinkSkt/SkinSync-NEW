import Foundation
import FirebaseAuth

@MainActor
final class ProductsViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var query: String = ""
    @Published var debugMessage: String? = nil
    @Published var isLoading: Bool = false
    @Published var searchResults: [Product] = []
    @Published var hasAPIFailed: Bool = false
    
    // Pagination properties
    @Published var isLoadingMore: Bool = false
    @Published var hasMoreResults: Bool = true
    private var currentPage: Int = 1
    private var totalResults: Int = 0

    /// Favourites are stored as product UUIDs.
    @Published private(set) var favoriteIDs: Set<UUID> = []

    private let store: DataStore
    private let productRepository: ProductRepository?
    private let favoritesService: FavoritesService = FavoritesService()

    init(store: DataStore, productRepository: ProductRepository? = nil) { 
        self.store = store
        self.productRepository = productRepository

        if let user = Auth.auth().currentUser {
            Task { await loadFavoritesFromCloud(userId: user.uid) }
        }
    }

    /// Convenience entry point for Views (non-async).
    func load() {
        Task { await loadAsync() }
    }
    
    /// Force reload from bundle (clears Documents cache)
    func forceReloadFromBundle() {
        Task { await forceReloadFromBundleAsync() }
    }
    
    /// Clear Documents cache completely
    func clearDocumentsCache() {
        Task {
            try? store.deleteProducts()
        }
    }

    /// Async-friendly loader ( for tests or future expansion).
    func loadAsync() async {
        // Load favorites first so hearts show immediately
        let favs = (try? store.loadFavoriteIDs()) ?? []
        favoriteIDs = Set(favs)

        // Load random products to populate the page
        await loadRandomProducts()
    }
    
    func loadRandomProducts() async {
        guard let repository = productRepository else {
            debugMessage = "No API available. Use search bar to find products."
            return
        }
        
        isLoading = true
        debugMessage = "Loading random products..."
        
        do {
            let randomProducts = try await repository.fetchRandomProducts(count: 20)
            
            // Preserve favorited products when loading new random products
            let favoritedProducts = products.filter { favoriteIDs.contains($0.id) }
            let newProducts = randomProducts.filter { !favoriteIDs.contains($0.id) }
            
            products = favoritedProducts + newProducts
            debugMessage = nil
        } catch {
            debugMessage = "Failed to load products. Use search bar to find products."
            // Don't clear products array on error - preserve existing favorites
        }
        
        isLoading = false
    }
    
    /// Load fallback products only when needed (API fails or no results)
    private func loadFallbackProducts() {
        // Preserve favorited products
        let favoritedProducts = products.filter { favoriteIDs.contains($0.id) }
        
        // Try bundle first
        if let url = Bundle.main.url(forResource: "products", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let items = try JSONDecoder().decode([Product].self, from: data)
                
                // Combine favorited products with fallback products
                let newProducts = items.filter { !favoriteIDs.contains($0.id) }
                products = favoritedProducts + newProducts
                debugMessage = "Loaded \(items.count) fallback products from bundle"
                return
            } catch { }
        }
        
        // Try Documents cache as second fallback
        if let items = try? store.loadProducts(), !items.isEmpty {
            let newProducts = items.filter { !favoriteIDs.contains($0.id) }
            products = favoritedProducts + newProducts
            debugMessage = "Loaded \(items.count) fallback products from Documents cache"
            return
        }
        
        // Last resort: create test products
        let testProducts = createTestProducts()
        let newTestProducts = testProducts.filter { !favoriteIDs.contains($0.id) }
        products = favoritedProducts + newTestProducts
        debugMessage = "Created \(testProducts.count) test products as final fallback"
    }
    
    /// Force reload from bundle (clears Documents cache)
    func forceReloadFromBundleAsync() async {
        // Load favorites first
        let favs = (try? store.loadFavoriteIDs()) ?? []
        favoriteIDs = Set(favs)

        // Clear Documents cache by deleting the products file
        try? store.deleteProducts()

        // Load from bundle
        if let url = Bundle.main.url(forResource: "products", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let items = try JSONDecoder().decode([Product].self, from: data)

                // Save to Documents
                try? store.save(products: items)

                // Preserve favorited products when force reloading
                let favoritedProducts = products.filter { favoriteIDs.contains($0.id) }
                let newProducts = items.filter { !favoriteIDs.contains($0.id) }
                products = favoritedProducts + newProducts
                
                debugMessage = items.isEmpty ? "Loaded 0 products from bundle." : nil
            } catch {
                // Don't clear products array on error - preserve existing favorites
                debugMessage = "Decode failed: \(error.localizedDescription)"
            }
        } else {
            // Don't clear products array - preserve existing favorites
            debugMessage = "Bundle couldn't find products.json"
        }
        
        // Only create test products if bundle loading completely failed
        if products.isEmpty && debugMessage?.contains("Bundle couldn't find") == true {
            let testProducts = createTestProducts()
            let favoritedProducts = products.filter { favoriteIDs.contains($0.id) }
            let newTestProducts = testProducts.filter { !favoriteIDs.contains($0.id) }
            products = favoritedProducts + newTestProducts
            debugMessage = "Created \(testProducts.count) test products for debugging"
        }
    }
    private func loadFavoritesFromCloud(userId: String) async {
        do {
            let (idStrings, itemsData) = try await favoritesService.load(userId: userId)
            let ids = Set(idStrings.compactMap(UUID.init(uuidString:)))
            
            // Reconstruct Product objects from the items data
            var favoriteProducts: [Product] = []
            for itemDict in itemsData {
                guard let idString = itemDict["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let name = itemDict["name"] as? String,
                      let brand = itemDict["brand"] as? String,
                      let category = itemDict["category"] as? String,
                      let barcode = itemDict["barcode"] as? String else {
                    continue
                }
                
                let product = Product(
                    id: id,
                    name: name,
                    brand: brand,
                    category: category,
                    assetName: "",
                    concerns: [],
                    ingredients: [],
                    barcode: barcode
                )
                favoriteProducts.append(product)
            }
            
            await MainActor.run {
                self.favoriteIDs = ids
                // Add favorite products to the products array if they're not already there
                for product in favoriteProducts {
                    if !self.products.contains(where: { $0.id == product.id }) {
                        self.products.append(product)
                    }
                }
                
                // Save favorite IDs to local storage as well
                try? self.store.save(favoriteIDs: Array(ids))
            }
        } catch { }
    }


    // MARK: - Test Products (for debugging)
    
    private func createTestProducts() -> [Product] {
        return [
            Product(
                name: "Test Cleanser",
                brand: "Test Brand",
                category: "Cleanser",
                assetName: "anua",
                concerns: [.sensitivity],
                ingredients: [],
                barcode: "1234567890"
            ),
            Product(
                name: "Test Moisturizer",
                brand: "Test Brand",
                category: "Moisturizer",
                assetName: "anua",
                concerns: [.dryness],
                ingredients: [],
                barcode: "1234567891"
            ),
            Product(
                name: "Test Serum",
                brand: "Another Brand",
                category: "Treatment",
                assetName: "anua",
                concerns: [.acne],
                ingredients: [],
                barcode: "1234567892"
            )
        ]
    }

    // MARK: - Derived collections

    var filtered: [Product] {
        guard !query.isEmpty else { 
            return products 
        }
        
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { 
            return [] 
        }
        
        // If we have search results from API, return them
        if !searchResults.isEmpty {
            return searchResults
        }
        
        // Only load fallback products if API has failed
        if hasAPIFailed && products.isEmpty {
            loadFallbackProducts()
        }
        
        // Fallback to local search only if we have products
        if !products.isEmpty {
            let results = products.filter {
                let nameMatch = $0.name.localizedCaseInsensitiveContains(q)
                let brandMatch = $0.brand.localizedCaseInsensitiveContains(q)
                let categoryMatch = $0.category.localizedCaseInsensitiveContains(q)
                let barcodeMatch = $0.barcode.localizedCaseInsensitiveContains(q)
                
                return nameMatch || brandMatch || categoryMatch || barcodeMatch
            }
            
            return results
        }
        
        return []
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
            // Add the product to the products array if it's not already there
            // This ensures scanned products appear in favorites
            if !products.contains(where: { $0.id == product.id }) {
                products.append(product)
            }
        }
        persistFavorites()
    }

    func isFavorite(_ product: Product) -> Bool {
        favoriteIDs.contains(product.id)
    }

    private func persistFavorites() {
        do { try store.save(favoriteIDs: Array(favoriteIDs)) }
        catch { debugMessage = "Failed to save favourites: \(error.localizedDescription)" }

        guard let user = Auth.auth().currentUser else { return }
        let ids = favoriteIDs.map { $0.uuidString }

        let catalog = self.products
        let itemsPayload: [[String: Any]] = favoriteIDs.compactMap { id in
            guard let p = catalog.first(where: { $0.id == id }) else { return nil }
            return [
                "id": id.uuidString,
                "name": p.name,
                "brand": p.brand,
                "category": p.category,
                "barcode": p.barcode
            ]
        }

        Task {
            do { try await favoritesService.save(userId: user.uid, ids: ids, items: itemsPayload) }
            catch { }
        }
    }

    
    // MARK: - Search API
    
    /// Search for products using Open Beauty Facts search API
    func searchOnline() async {
        guard let repository = productRepository else {
            return
        }
        
        guard !query.isEmpty else {
            searchResults = []
            hasAPIFailed = false
            resetPagination()
            return
        }
        
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            searchResults = []
            hasAPIFailed = false
            resetPagination()
            return
        }
        
        // Reset pagination for new search
        resetPagination()
        
        isLoading = true
        hasAPIFailed = false
        
        do {
            let results = try await repository.search(query: trimmedQuery, page: 1, pageSize: 20)
            searchResults = results
            currentPage = 1
            totalResults = results.count
            hasMoreResults = results.count >= 20 // If we got 20 results, there might be more
            
            if results.isEmpty {
                debugMessage = "No products found for '\(trimmedQuery)'"
                hasMoreResults = false
            } else {
                debugMessage = nil
            }
        } catch {
            debugMessage = "Search error: \(error.localizedDescription). Loading fallback products..."
            searchResults = []
            hasAPIFailed = true
            hasMoreResults = false
            
            // Load fallback products when API fails
            loadFallbackProducts()
        }
        
        isLoading = false
    }
    
    func loadMoreResults() async {
        guard let repository = productRepository else { return }
        guard !query.isEmpty else { return }
        guard !isLoadingMore else { return }
        guard hasMoreResults else { return }
        
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return }
        
        isLoadingMore = true
        let nextPage = currentPage + 1
        
        do {
            let results = try await repository.search(query: trimmedQuery, page: nextPage, pageSize: 20)
            
            if results.isEmpty {
                hasMoreResults = false
            } else {
                searchResults.append(contentsOf: results)
                currentPage = nextPage
                totalResults += results.count
                
                // If we got fewer than 20 results, there are no more pages
                if results.count < 20 {
                    hasMoreResults = false
                }
            }
        } catch {
            hasMoreResults = false
        }
        
        isLoadingMore = false
    }
    
    private func resetPagination() {
        currentPage = 1
        totalResults = 0
        hasMoreResults = true
        isLoadingMore = false
    }
    
    /// Test API connectivity
    func testAPI() async {
        guard let repository = productRepository else {
            debugMessage = "No ProductRepository available"
            return
        }
        
        do {
            // Test with a known barcode from Open Beauty Facts
            if let testProduct = try await repository.fetchByBarcode("737628064502") {
                debugMessage = "API test successful: \(testProduct.name)"
            } else {
                debugMessage = "API test: No product found"
            }
        } catch {
            debugMessage = "API test error: \(error.localizedDescription)"
        }
    }
    
    /// Test basic network connectivity
    func testNetworkConnectivity() async {
        guard let url = URL(string: "https://world.openbeautyfacts.org") else {
            debugMessage = "Invalid URL"
            return
        }
        
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                debugMessage = "Network test - Status: \(httpResponse.statusCode)"
            } else {
                debugMessage = "Network test - Invalid response type"
            }
        } catch {
            debugMessage = "Network test error: \(error.localizedDescription)"
        }
    }
}
