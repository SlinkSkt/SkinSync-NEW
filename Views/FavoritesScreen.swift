//  FavoritesScreen.swift
//  SkinSync
//
//  Created by Zhen Xiao on 24/8/2025.
//

import SwiftUI

struct FavoritesScreen: View {
    @EnvironmentObject private var vm: ProductsViewModel
    let theme: AppTheme
    @State private var sortAscending = true

    // MARK: - Grouped Favorites
    private var groupedFavorites: [(key: String, value: [Product])] {
        Dictionary(grouping: sortedFavorites, by: { $0.categoryName })
            .sorted { $0.key < $1.key }
    }

    // MARK: - Sorted Favorites
    private var sortedFavorites: [Product] {
        vm.favorites.sorted {
            sortAscending ? $0.name < $1.name : $0.name > $1.name
        }
    }

    // MARK: - Body
    var body: some View {
        Group {
            if vm.favorites.isEmpty {
                emptyStateView
            } else {
                favoritesListView
            }
        }
        .navigationTitle("Favourites")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                sortButton
            }
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Views
    private var emptyStateView: some View {
        ContentStateView(
            icon: "heart.fill",
            title: "No favourites yet",
            message: "Tap the heart on any product to add it here."
        )
        .padding(AppTheme.Spacing.screenEdge)
        .accessibilityLabel("No favourites")
        .accessibilityHint("Tap the heart on any product to add it to your favourites.")
        .transition(.opacity.combined(with: .scale))
        .animation(.easeInOut, value: vm.favorites.isEmpty)
    }

    private var favoritesListView: some View {
        List {
            favoritesCountSection
            ForEach(groupedFavorites, id: \.key) { group in
                favoritesGroupSection(group)
            }
        }
        .listStyle(.insetGrouped)
        .animation(.easeInOut(duration: 0.3), value: vm.favorites)
    }
    
    private var favoritesCountSection: some View {
        Section {
            Text("\(vm.favorites.count) favourite\(vm.favorites.count == 1 ? "" : "s")")
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(.secondary)
                .accessibilityLabel("Total favourites: \(vm.favorites.count)")
        }
    }
    
    private func favoritesGroupSection(_ group: (key: String, value: [Product])) -> some View {
        Section(header: groupHeader(group.key)) {
            ForEach(group.value) { product in
                favoriteProductRow(product)
            }
        }
    }
    
    private func groupHeader(_ category: String) -> some View {
        Text(category)
            .font(AppTheme.Typography.headline)
            .foregroundStyle(.primary)
            .accessibilityLabel("\(category) category")
    }
    
    private func favoriteProductRow(_ product: Product) -> some View {
        NavigationLink(destination: ProductDetailView(product: product, theme: theme, store: FileDataStore())
                        .environmentObject(vm)) {
            ProductRow(product: product, theme: theme)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(product.name)
                .accessibilityHint("Tap to view details. Swipe left to remove from favourites.")
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            removeFavoriteButton(for: product)
        }
    }
    
    private func removeFavoriteButton(for product: Product) -> some View {
        Button(role: .destructive) {
            withAnimation(.easeInOut(duration: 0.3)) {
                vm.toggleFavorite(product)
            }
        } label: {
            Label("Remove", systemImage: "heart.slash")
        }
        .accessibilityLabel("Remove \(product.name) from favourites")
    }

    private var sortButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { sortAscending.toggle() }
        } label: {
            Image(systemName: sortAscending ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .font(.title3)
                .foregroundStyle(theme.primary)
        }
        .accessibilityLabel(sortAscending ? "Sort A to Z" : "Sort Z to A")
        .accessibilityHint("Toggle sort order of your favourites.")
    }
}

// MARK: - Helpers
private extension Product {
    var categoryName: String {
        let c = category.trimmingCharacters(in: .whitespacesAndNewlines)
        return c.isEmpty ? "Other" : c
    }
}
