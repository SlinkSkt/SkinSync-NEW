import SwiftUI

struct ProductsScreen: View {
    @EnvironmentObject private var vm: ProductsViewModel
    let theme: AppTheme

    var body: some View {
        List(vm.filtered) { p in
            NavigationLink(value: p) {
                ProductRow(product: p, theme: theme)
                    .overlay(alignment: .topTrailing) {
                        FavoriteHeartButton(isOn: vm.isFavorite(p)) {
                            vm.toggleFavorite(p)
                        }
                        .padding(.top, 4)
                        .padding(.trailing, 8)
                    }
            }
        }
        .listStyle(.plain)
        .searchable(text: $vm.query, prompt: "Search products or brands")
        .onAppear { vm.load() }
        .toolbar {
            NavigationLink(destination: FavoritesScreen(theme: theme).environmentObject(vm)) {
                Label("Favourites", systemImage: "heart")
            }
        }
        .overlay {
            if vm.filtered.isEmpty {
                VStack(spacing: 10) {
                    ContentStateView(
                        icon: "shippingbox",
                        title: "No products",
                        message: "Make sure products.json is added to Copy Bundle Resources."
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
            }
        }
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
