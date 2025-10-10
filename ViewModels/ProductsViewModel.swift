import Foundation

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

    init(store: DataStore, productRepository: ProductRepository? = nil) { 
        self.store = store
        self.productRepository = productRepository
        print("📦 ProductsViewModel: Initialized with ProductRepository: \(productRepository != nil ? "YES" : "NO")")
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
            print("📦 ProductsViewModel: Clearing Documents cache...")
            try? store.deleteProducts()
            print("📦 ProductsViewModel: Documents cache cleared")
        }
    }

    /// Async-friendly loader ( for tests or future expansion).
    func loadAsync() async {
        print("📦 ProductsViewModel: Starting to load products...")
        
        // Load favorites first so hearts show immediately
        let favs = (try? store.loadFavoriteIDs()) ?? []
        favoriteIDs = Set(favs)
        print("📦 ProductsViewModel: Loaded \(favoriteIDs.count) favorites")

        // Load random products to populate the page
        await loadRandomProducts()
    }
    
    func loadRandomProducts() async {
        guard let repository = productRepository else {
            print("📦 ProductsViewModel: No ProductRepository available for random products")
            debugMessage = "No API available. Use search bar to find products."
            return
        }
        
        isLoading = true
        debugMessage = "Loading random products..."
        
        do {
            let randomProducts = try await repository.fetchRandomProducts(count: 20)
            products = randomProducts
            debugMessage = nil
            print("📦 ProductsViewModel: Loaded \(randomProducts.count) random products")
        } catch {
            print("📦 ProductsViewModel: Failed to load random products: \(error)")
            debugMessage = "Failed to load products. Use search bar to find products."
            products = []
        }
        
        isLoading = false
    }
    
    /// Load fallback products only when needed (API fails or no results)
    private func loadFallbackProducts() {
        print("📦 ProductsViewModel: Loading fallback products...")
        
        // Try bundle first
        if let url = Bundle.main.url(forResource: "products", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let items = try JSONDecoder().decode([Product].self, from: data)
                
                products = items
                debugMessage = "Loaded \(items.count) fallback products from bundle"
                print("📦 ProductsViewModel: Loaded \(items.count) fallback products from bundle")
                return
            } catch {
                print("📦 ProductsViewModel: Failed to decode fallback products from bundle: \(error)")
            }
        }
        
        // Try Documents cache as second fallback
        if let items = try? store.loadProducts(), !items.isEmpty {
            products = items
            debugMessage = "Loaded \(items.count) fallback products from Documents cache"
            print("📦 ProductsViewModel: Loaded \(items.count) fallback products from Documents cache")
            return
        }
        
        // Last resort: create test products
        products = createTestProducts()
        debugMessage = "Created \(products.count) test products as final fallback"
        print("📦 ProductsViewModel: Created \(products.count) test products as final fallback")
    }
    
    /// Force reload from bundle (clears Documents cache)
    func forceReloadFromBundleAsync() async {
        print("📦 ProductsViewModel: Force reloading from bundle...")
        
        // Load favorites first
        let favs = (try? store.loadFavoriteIDs()) ?? []
        favoriteIDs = Set(favs)
        print("📦 ProductsViewModel: Loaded \(favoriteIDs.count) favorites")

        // Clear Documents cache by deleting the products file
        try? store.deleteProducts()
        print("📦 ProductsViewModel: Cleared Documents cache")

        // Load from bundle
        if let url = Bundle.main.url(forResource: "products", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let items = try JSONDecoder().decode([Product].self, from: data)

                // Save to Documents
                try? store.save(products: items)

                products = items
                debugMessage = items.isEmpty ? "Loaded 0 products from bundle." : nil
                print("📦 ProductsViewModel: Force loaded \(items.count) products from bundle")
            } catch {
                products = []
                debugMessage = "Decode failed: \(error.localizedDescription)"
                print("📦 ProductsViewModel: Failed to decode products from bundle: \(error)")
            }
        } else {
            products = []
            debugMessage = "Bundle couldn't find products.json"
            print("📦 ProductsViewModel: No products.json found in bundle")
        }
        
        // Only create test products if bundle loading completely failed
        if products.isEmpty && debugMessage?.contains("Bundle couldn't find") == true {
            print("📦 ProductsViewModel: Bundle loading failed, creating test products...")
            products = createTestProducts()
            debugMessage = "Created \(products.count) test products for debugging"
        }
        
        print("📦 ProductsViewModel: Final product count: \(products.count)")
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
        print("🔍 Filtered called with query: '\(query)', products count: \(products.count), searchResults count: \(searchResults.count)")
        
        guard !query.isEmpty else { 
            print("🔍 Search: Empty query, returning \(products.count) random products")
            return products 
        }
        
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { 
            print("🔍 Search: Empty trimmed query, returning empty results")
            return [] 
        }
        
        // If we have search results from API, return them
        if !searchResults.isEmpty {
            print("🔍 Search: Returning \(searchResults.count) API search results")
            return searchResults
        }
        
        // Only load fallback products if API has failed
        if hasAPIFailed && products.isEmpty {
            print("🔍 Search: API failed and no local products, loading fallback products...")
            loadFallbackProducts()
        }
        
        // Fallback to local search only if we have products
        if !products.isEmpty {
            let results = products.filter {
                let nameMatch = $0.name.localizedCaseInsensitiveContains(q)
                let brandMatch = $0.brand.localizedCaseInsensitiveContains(q)
                let categoryMatch = $0.category.localizedCaseInsensitiveContains(q)
                let barcodeMatch = $0.barcode.localizedCaseInsensitiveContains(q)
                
                let matches = nameMatch || brandMatch || categoryMatch || barcodeMatch
                if matches {
                    print("🔍 Fallback match found: '\($0.name)' matches '\(q)'")
                }
                
                return matches
            }
            
            print("🔍 Search: '\(q)' found \(results.count) fallback results out of \(products.count) products")
            if results.isEmpty {
                print("🔍 Search: No fallback matches found. Sample product names: \(products.prefix(3).map { $0.name })")
            }
            
            return results
        }
        
        print("🔍 Search: No results found")
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
    
    // MARK: - Search API
    
    /// Search for products using Open Beauty Facts search API
    func searchOnline() async {
        print("🔍 ProductsViewModel: searchOnline() called with query: '\(query)'")
        
        guard let repository = productRepository else {
            print("🔍 ProductsViewModel: No ProductRepository available, using local search only")
            return
        }
        
        guard !query.isEmpty else {
            print("🔍 ProductsViewModel: Empty query, skipping API search")
            searchResults = []
            hasAPIFailed = false
            resetPagination()
            return
        }
        
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            print("🔍 ProductsViewModel: Empty trimmed query, skipping API search")
            searchResults = []
            hasAPIFailed = false
            resetPagination()
            return
        }
        
        // Reset pagination for new search
        resetPagination()
        
        isLoading = true
        hasAPIFailed = false
        print("🔍 ProductsViewModel: Searching API for '\(trimmedQuery)'...")
        
        do {
            let results = try await repository.search(query: trimmedQuery, page: 1, pageSize: 20)
            searchResults = results
            currentPage = 1
            totalResults = results.count
            hasMoreResults = results.count >= 20 // If we got 20 results, there might be more
            
            print("🔍 ProductsViewModel: Found \(results.count) products from API")
            
            if results.isEmpty {
                debugMessage = "No products found for '\(trimmedQuery)'"
                hasMoreResults = false
            } else {
                debugMessage = nil
            }
        } catch {
            print("🔍 ProductsViewModel: Search error: \(error)")
            debugMessage = "Search error: \(error.localizedDescription). Loading fallback products..."
            searchResults = []
            hasAPIFailed = true
            hasMoreResults = false
            
            // Load fallback products when API fails
            loadFallbackProducts()
        }
        
        isLoading = false
        print("🔍 ProductsViewModel: searchOnline() completed")
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
        
        print("🔍 ProductsViewModel: Loading page \(nextPage) for query '\(trimmedQuery)'")
        
        do {
            let results = try await repository.search(query: trimmedQuery, page: nextPage, pageSize: 20)
            
            if results.isEmpty {
                hasMoreResults = false
                print("🔍 ProductsViewModel: No more results available")
            } else {
                searchResults.append(contentsOf: results)
                currentPage = nextPage
                totalResults += results.count
                
                // If we got fewer than 20 results, there are no more pages
                if results.count < 20 {
                    hasMoreResults = false
                }
                
                print("🔍 ProductsViewModel: Loaded \(results.count) more products. Total: \(searchResults.count)")
            }
        } catch {
            print("🔍 ProductsViewModel: Error loading more results: \(error)")
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
        print("🔍 ProductsViewModel: Testing API connectivity...")
        
        guard let repository = productRepository else {
            print("🔍 ProductsViewModel: No ProductRepository available")
            debugMessage = "No ProductRepository available"
            return
        }
        
        print("🔍 ProductsViewModel: ProductRepository is available, testing with sample barcode...")
        
        do {
            // Test with a known barcode from Open Beauty Facts
            if let testProduct = try await repository.fetchByBarcode("737628064502") {
                print("🔍 ProductsViewModel: API test successful! Found: \(testProduct.name)")
                debugMessage = "API test successful: \(testProduct.name)"
            } else {
                print("🔍 ProductsViewModel: API test: No product found for test barcode")
                debugMessage = "API test: No product found"
            }
        } catch {
            print("🔍 ProductsViewModel: API test error: \(error)")
            debugMessage = "API test error: \(error.localizedDescription)"
        }
    }
    
    /// Test basic network connectivity
    func testNetworkConnectivity() async {
        print("🌐 ProductsViewModel: Testing basic network connectivity...")
        
        guard let url = URL(string: "https://world.openbeautyfacts.org") else {
            debugMessage = "Invalid URL"
            return
        }
        
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                print("🌐 ProductsViewModel: Network test - Status: \(httpResponse.statusCode)")
                debugMessage = "Network test - Status: \(httpResponse.statusCode)"
            } else {
                print("🌐 ProductsViewModel: Network test - Invalid response type")
                debugMessage = "Network test - Invalid response type"
            }
        } catch {
            print("🌐 ProductsViewModel: Network test error: \(error)")
            debugMessage = "Network test error: \(error.localizedDescription)"
        }
    }
}