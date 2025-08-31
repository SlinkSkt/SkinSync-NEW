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
        
        var iconName: String {
            switch self {
            case .brand: return "textformat.abc"
            case .name: return "text.abc"
            case .category: return "folder"
            }
        }
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
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    showOnlyFavourites.toggle()
                } label: {
                    Image(systemName: showOnlyFavourites ? "heart.fill" : "heart")
                        .foregroundStyle(showOnlyFavourites ? .pink : .primary)
                }
                .accessibilityLabel(showOnlyFavourites ? "Showing favourites only" : "Show all products")
            }

            ToolbarItem(placement: .principal) {
                VStack(spacing: AppTheme.Spacing.xs) {
                    Text("Products")
                        .font(AppTheme.Typography.headline)
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
                    
                    NavigationLink {
                        FavoritesScreen(theme: theme)
                            .environmentObject(vm)
                    } label: {
                        Label("Favorites Screen", systemImage: "heart.text.square")
                    }
                } label: {
                    Image(systemName: "slider.horizontal.3")
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
                .font(.subheadline.weight(.medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(isOn ? .pink : .secondary)
                .padding(AppTheme.Spacing.sm)
                .background(.ultraThinMaterial, in: Capsule())
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .scaleEffect(isOn ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isOn)
        .accessibilityLabel(isOn ? "Remove from favourites" : "Add to favourites")
    }
}
