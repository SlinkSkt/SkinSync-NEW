// https://danielsaidi.com/blog/2023/04/01/group-and-sort-swift-collections-like-a-pro
import SwiftUI

struct ProductsScreen: View {
    @EnvironmentObject private var vm: ProductsViewModel
    let theme: AppTheme

    // Local UI-only state
    @State private var showOnlyFavourites = false
    @State private var sortMode: SortMode = .brand

    enum SortMode: String, CaseIterable, Identifiable {
        case brand = "Brand", name = "Name", category = "Category"
        var id: String { rawValue }
    }

    // Derived list based on toggle + search + sort
    private var visibleProducts: [Product] {
        let base = showOnlyFavourites ? vm.favorites : vm.filtered
        switch sortMode {
        case .brand:    return base.sorted { $0.brand.localizedCaseInsensitiveCompare($1.brand) == .orderedAscending }
        case .name:     return base.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .category: return base.sorted { $0.category.localizedCaseInsensitiveCompare($1.category) == .orderedAscending }
        }
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
                VStack(spacing: 12) {
                    ContentStateView(
                        icon: "shippingbox",
                        title: "No products to show",
                        message: showOnlyFavourites
                            ? "You haven’t added any favourites yet. Tap the heart on a product to favourite it."
                            : "Try adjusting search/filters, or ensure your bundled products.json is included in Copy Bundle Resources."
                    )
                    if let msg = vm.debugMessage {
                        Text(msg)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                // Section when multiple categories, flat when one
                List {
                    if Set(visibleProducts.map { $0.category }).count > 1 {
                        ForEach(groupedByCategory, id: \.key) { group in
                            Section(group.key) {
                                ForEach(group.value) { p in
                                    row(for: p)
                                }
                            }
                        }
                    } else {
                        ForEach(visibleProducts) { p in
                            row(for: p)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Products")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                // Quick toggle for Favourites
                Toggle(isOn: $showOnlyFavourites) {
                    Label("Favourites only", systemImage: showOnlyFavourites ? "heart.fill" : "heart")
                }
                .toggleStyle(.button)
                .accessibilityLabel(showOnlyFavourites ? "Showing favourites only" : "Show favourites only")
            }

            ToolbarItem(placement: .principal) {
                // Tiny count + sort inline
                HStack(spacing: 8) {
                    Text("Products")
                        .font(.headline)
                    Text("(\(visibleProducts.count))")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Sort by", selection: $sortMode) {
                        ForEach(SortMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    Divider()
                    NavigationLink {
                        // Favourites page stays, but the toggle above means
                        // users rarely need this—kept for parity with your UI.
                        FavoritesScreen(theme: theme)
                            .environmentObject(vm)
                    } label: {
                        Label("Open Favourites Page", systemImage: "heart")
                    }
                } label: {
                    Label("Options", systemImage: "slider.horizontal.3")
                }
            }
        }
        // Search stays the same (lives on the parent nav)
        .searchable(text: $vm.query, prompt: "Search products or brands")
        // Better than onAppear: won’t double-load when you come back from detail
        .task { if vm.products.isEmpty { vm.load() } }
        // Pull-to-refresh to re-read JSON if change it during dev
        .refreshable { vm.load() }
        // Subtle animation when filters/sort change
        .animation(.default, value: showOnlyFavourites)
        .animation(.default, value: sortMode)
        .animation(.default, value: vm.query)
        // Keep the iOS look tidy
        .scrollDismissesKeyboard(.immediately)
    }

    // MARK: - Row builder

    @ViewBuilder
    private func row(for p: Product) -> some View {
        NavigationLink(value: p) {
            ProductRow(product: p, theme: theme)
                .overlay(alignment: .topTrailing) {
                    FavoriteHeartButton(isOn: vm.isFavorite(p)) {
                        vm.toggleFavorite(p)
                    }
                    .padding(.top, 6)
                    .padding(.trailing, 8)
                }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                vm.toggleFavorite(p)
            } label: {
                Label(vm.isFavorite(p) ? "Unfavourite" : "Favourite",
                      systemImage: vm.isFavorite(p) ? "heart.slash" : "heart")
            }.tint(.pink)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(p.brand) \(p.name)")
        .accessibilityHint("Double tap to view details. Swipe to \(vm.isFavorite(p) ? "remove from" : "add to") favourites.")
    }
}

// Keep this tiny button here OR move it to its own file to share with Favorites
private struct FavoriteHeartButton: View {
    var isOn: Bool
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: isOn ? "heart.fill" : "heart")
                .imageScale(.medium)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(isOn ? .red : .secondary)
                .padding(6)
                .background(.ultraThinMaterial, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isOn ? "Remove from favourites" : "Add to favourites")
    }
}
