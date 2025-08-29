import SwiftUI

struct ProductsScreen: View {
    @EnvironmentObject private var vm: ProductsViewModel
    let theme: AppTheme

    var body: some View {
        List(vm.filtered) { p in
            NavigationLink(value: p) {
                ProductRow(product: p, theme: theme)
            }
        }
        .listStyle(.plain)
        .searchable(text: $vm.query, prompt: "Search products or brands")
        .onAppear { vm.load() }
        .navigationDestination(for: Product.self) { p in
            ProductDetailView(product: p, theme: theme)
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
