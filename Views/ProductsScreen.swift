// Views/ProductsScreen.swift
import SwiftUI

struct ProductsScreen: View {
    @EnvironmentObject private var vm: ProductsViewModel
    let theme: AppTheme

    // Local UI-only state
    @State private var showOnlyFavourites = false
    @State private var sortMode: SortMode = .brand
    @State private var showingFavoritesScreen = false
    @State private var lastVisibleIndex: Int = 0

    enum SortMode: String, CaseIterable, Identifiable {
        case brand = "Brand", name = "Name", category = "Category"
        var id: String { rawValue }
        
        var iconName: String {
            switch self {
            case .brand: return "textformat.abc"
            case .name: return "textformat"
            case .category: return "folder"
            }
        }
    }

    // Derived list based on toggle + search + sort
    private var visibleProducts: [Product] {
        let base = showOnlyFavourites ? vm.favorites : vm.filtered
        let sorted = switch sortMode {
        case .brand:    base.sorted { $0.brand.localizedCaseInsensitiveCompare($1.brand) == .orderedAscending }
        case .name:     base.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .category: base.sorted { $0.category.localizedCaseInsensitiveCompare($1.category) == .orderedAscending }
        }
        
        print("📱 ProductsScreen: visibleProducts = \(sorted.count) (favorites: \(showOnlyFavourites), query: '\(vm.query)', total: \(vm.products.count))")
        return sorted
    }

    // Group for sectioned list when mixing categories
    private var groupedByCategory: [(key: String, value: [Product])] {
        Dictionary(grouping: visibleProducts, by: { $0.category })
            .sorted { $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending }
    }

    var body: some View {
        Group {
            if visibleProducts.isEmpty {
                // Empty/placeholder state
                VStack(spacing: AppTheme.Spacing.lg) {
                    ContentStateView(
                        icon: "shippingbox.fill",
                        title: "No products to show",
                        message: showOnlyFavourites
                            ? "You haven't added any favourites yet. Tap the heart on a product to favourite it."
                            : "Use the search bar to find products from Open Beauty Facts, or scan a barcode to get product details."
                    )
                    if let msg = vm.debugMessage {
                        Text(msg)
                            .font(AppTheme.Typography.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppTheme.Spacing.screenEdge)
                    }
                    
                    if vm.isLoading {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Searching API...")
                                .font(AppTheme.Typography.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .padding(AppTheme.Spacing.screenEdge)
                    }
                    
                    // Simple refresh button
                    Button("Refresh Products") {
                        vm.load()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, AppTheme.Spacing.md)
                }
                .padding(AppTheme.Spacing.screenEdge)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                // Section when multiple categories, flat when one
                List {
                    if Set(visibleProducts.map { $0.category }).count > 1 {
                        ForEach(groupedByCategory, id: \.key) { group in
                            Section(group.key) {
                                ForEach(Array(group.value.enumerated()), id: \.element.id) { index, p in
                                    NavigationLink(value: p) {
                                        productRow(for: p)
                                    }
                                    .onAppear {
                                        // Load more when user scrolls to the last few items in any section
                                        let totalIndex = visibleProducts.firstIndex(where: { $0.id == p.id }) ?? 0
                                        if totalIndex >= visibleProducts.count - 3 {
                                            loadMoreIfNeeded()
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        ForEach(Array(visibleProducts.enumerated()), id: \.element.id) { index, p in
                            NavigationLink(value: p) {
                                productRow(for: p)
                            }
                            .onAppear {
                                // Load more when user scrolls to the last few items
                                if index >= visibleProducts.count - 3 {
                                    loadMoreIfNeeded()
                                }
                            }
                        }
                    }
                    
                    // Infinite scroll loading indicator
                    if vm.isLoadingMore {
                        HStack {
                            Spacer()
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading more...")
                                .font(AppTheme.Typography.footnote)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.vertical, AppTheme.Spacing.md)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
                .onAppear {
                    // Load more results when the last item appears
                    if !visibleProducts.isEmpty && !vm.query.isEmpty {
                        loadMoreIfNeeded()
                    }
                }
            }
        }
        .navigationTitle("Products")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showOnlyFavourites.toggle()
                    }
                } label: {
                    Image(systemName: showOnlyFavourites ? "heart.fill" : "heart")
                        .font(.title3)
                        .foregroundStyle(showOnlyFavourites ? .pink : .primary)
                }
                .accessibilityLabel(showOnlyFavourites ? "Showing favourites only" : "Show all products")
                .accessibilityHint("Tap to toggle between all products and favourites only")
            }

            ToolbarItem(placement: .principal) {
                VStack(spacing: AppTheme.Spacing.xs) {
                    Text("Products")
                        .font(AppTheme.Typography.title3)
                        .foregroundStyle(.primary)
                    Text("\(visibleProducts.count) items")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(.secondary)
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Picker("Sort by", selection: $sortMode) {
                        ForEach(SortMode.allCases) { mode in
                            Label(mode.rawValue, systemImage: mode.iconName).tag(mode)
                        }
                    }
                    
                    Divider()
                    
                    Button {
                        showingFavoritesScreen = true
                    } label: {
                        Label("Favorites Screen", systemImage: "heart.text.square")
                    }
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title3)
                        .foregroundStyle(.primary)
                }
                .accessibilityLabel("Sort and filter options")
                .accessibilityHint("Tap to access sorting and filtering options")
            }
        }
        // Search stays the same (lives on the parent nav)
        .searchable(text: $vm.query, prompt: "Search products or brands")
        .onChange(of: vm.query) { oldValue, newValue in
            print("🔍 ProductsScreen: Search query changed from '\(oldValue)' to '\(newValue)'")
            // Trigger API search when query changes
            Task {
                await vm.searchOnline()
            }
        }
        // Better than onAppear: won't double-load when you come back from detail
        .task { if vm.products.isEmpty { vm.load() } }
        // Pull-to-refresh to re-read JSON if change it during dev
        .refreshable { vm.load() }
        // Subtle animation when filters/sort change
        .animation(.easeInOut(duration: 0.3), value: showOnlyFavourites)
        .animation(.easeInOut(duration: 0.3), value: sortMode)
        .animation(.easeInOut(duration: 0.3), value: vm.query)
        // Keep the iOS look tidy
        .scrollDismissesKeyboard(.immediately)
        .sheet(isPresented: $showingFavoritesScreen) {
            FavoritesScreen(theme: theme)
                .environmentObject(vm)
        }
    }

    // MARK: - Row builder

    @ViewBuilder
    private func productRow(for p: Product) -> some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Product image - handle both remote URLs and local assets
            Group {
                if let imageURL = p.imageURL, !imageURL.isEmpty {
                    AsyncImage(url: URL(string: imageURL)) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Spacing.sm))
                    } placeholder: {
                        ProgressView()
                            .frame(width: 60, height: 60)
                            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: AppTheme.Spacing.sm))
                    }
                } else if let imageName = p.imageName, !imageName.isEmpty {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Spacing.sm))
                } else {
                    Image(systemName: "cube.box.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundStyle(.secondary)
                        .frame(width: 60, height: 60)
                        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: AppTheme.Spacing.sm))
                }
            }
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)

            // Product info
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(p.name)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                Text(p.brand)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(p.category)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .background(Color(.systemGray5), in: Capsule())
            }
            
            Spacer()
            
            // Favorite button
            FavoriteHeartButton(isOn: vm.isFavorite(p)) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { 
                    vm.toggleFavorite(p) 
                }
            }
        }
        .padding(.vertical, AppTheme.Spacing.sm)
        .padding(.horizontal, AppTheme.Spacing.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(p.brand) \(p.name)")
        .accessibilityHint("Double tap to view details. Swipe to \(vm.isFavorite(p) ? "remove from" : "add to") favourites.")
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                withAnimation(.spring()) { vm.toggleFavorite(p) }
            } label: {
                Label(vm.isFavorite(p) ? "Unfavourite" : "Favourite",
                      systemImage: vm.isFavorite(p) ? "heart.slash" : "heart")
            }.tint(.pink)
        }
    }
    
    // MARK: - Infinite Scroll Functions
    
    private func loadMoreIfNeeded() {
        // Only load more if we're searching (not showing favorites or random products)
        guard !vm.query.isEmpty else { return }
        guard vm.hasMoreResults else { return }
        guard !vm.isLoadingMore else { return }
        
        // Load more results when user scrolls near the end
        Task {
            await vm.loadMoreResults()
        }
    }
}

// MARK: - Favorite Heart Button

struct FavoriteHeartButton: View {
    var isOn: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: isOn ? "heart.fill" : "heart")
                .font(.title3)
                .foregroundStyle(isOn ? .pink : .secondary)
                .symbolRenderingMode(.hierarchical)
        }
        .buttonStyle(.plain)
        .scaleEffect(isOn ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isOn)
        .accessibilityLabel(isOn ? "Remove from favourites" : "Add to favourites")
        .accessibilityHint("Tap to \(isOn ? "remove from" : "add to") your favourites")
    }
}