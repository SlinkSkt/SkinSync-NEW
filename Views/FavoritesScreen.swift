//  FavoritesScreen.swift
//  SkinSync
//
//  Created by Zhen Xiao on 31/8/2025.
//

import SwiftUI

struct FavoritesScreen: View {
    @EnvironmentObject private var vm: ProductsViewModel
    let theme: AppTheme

    var body: some View {
        Group {
            if vm.favorites.isEmpty {
                ContentStateView(
                    icon: "heart",
                    title: "No favourites yet",
                    message: "Tap the heart on any product to add it here."
                )
                .padding()
            } else {
                List {
                    ForEach(vm.favorites) { p in
                        // ✅ Explicit destination avoids value-router glitches
                        NavigationLink {
                            ProductDetailView(product: p, theme: theme)
                        } label: {
                            ProductRow(product: p, theme: theme)
                        }
                        // ✅ Use swipe to avoid overlay tap conflicts with row
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                vm.toggleFavorite(p)
                            } label: {
                                Label("Remove", systemImage: "heart.slash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Favourites")
    }
}
