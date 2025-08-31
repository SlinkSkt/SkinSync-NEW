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
            icon: "heart",
            title: "No favourites yet",
            message: "Tap the heart on any product to add it here."
        )
        .padding()
        .accessibilityLabel("No favourites")
        .accessibilityHint("Tap the heart on any product to add it to your favourites.")
        .transition(.opacity.combined(with: .scale))
        .animation(.easeInOut, value: vm.favorites.isEmpty)
    }

    private var favoritesListView: some View {
        List {
            Section {
                Text("\(vm.favorites.count) favourite\(vm.favorites.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .accessibilityLabel("Total favourites: \(vm.favorites.count)")
            }
            ForEach(groupedFavorites, id: \.key) { group in
                Section(header:
                    Text(group.key)
                        .font(.headline)
                        .accessibilityLabel("\(group.key) category")
                ) {
                    ForEach(group.value) { p in
                        NavigationLink(destination: ProductDetailView(product: p, theme: theme)) {
                            ProductRow(product: p, theme: theme)
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel(p.name)
                                .accessibilityHint("Tap to view details. Swipe left to remove from favourites.")
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                withAnimation {
                                    vm.toggleFavorite(p)
                                }
                            } label: {
                                Label("Remove", systemImage: "heart.slash")
                            }
                            .accessibilityLabel("Remove \(p.name) from favourites")
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .animation(.easeInOut, value: vm.favorites)
    }

    private var sortButton: some View {
        Button {
            withAnimation { sortAscending.toggle() }
        } label: {
            Image(systemName: sortAscending ? "arrow.up" : "arrow.down")
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
